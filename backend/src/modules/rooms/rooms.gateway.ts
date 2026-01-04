import { UseGuards } from '@nestjs/common';
import { WebSocketGateway, SubscribeMessage, MessageBody, ConnectedSocket, WebSocketServer } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { AuthGuard } from '../../common/auth.guard';
import { RateLimitService } from '../rate-limit/rate-limit.service';
import { RoomsService } from './rooms.service';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '../../common/jwt.service';
import { PresenceService } from '../presence/presence.service';
const prom = require('prom-client');
import { metricsRegistry } from '../metrics/metrics.controller';

@WebSocketGateway({ cors: { origin: true } })
export class RoomsGateway {
  @WebSocketServer() server!: Server;
  constructor(private readonly rl: RateLimitService, private readonly rooms: RoomsService, private readonly jwt: JwtService, private readonly presence: PresenceService, private readonly prisma: PrismaService) {}
  private readonly msgCounter = new prom.Counter({ name: 'poketibia_socket_messages_total', help: 'Socket messages', labelNames: ['roomId'], registers: [metricsRegistry] });
  private readonly rlErrorCounter = new prom.Counter({ name: 'poketibia_socket_rate_limit_errors_total', help: 'Socket rate limit errors', labelNames: ['roomId'], registers: [metricsRegistry] });

  async handleConnection(client: Socket) {
    const token = (client.handshake.auth as any)?.token || (client.handshake.query as any)?.token;
    if (!token) return client.disconnect();
    const payload = this.jwt.verifyAccess(token);
    if (!payload || payload.status === 'suspensa') return client.disconnect();
    (client as any).userId = payload.sub;
    (client as any).displayName = (payload as any).name || '';
    this.presence.add((client as any).userId);
    client.join(`user:${(client as any).userId}`);
  }

  @UseGuards(AuthGuard)
  @SubscribeMessage('rooms:join')
  async handleJoin(@MessageBody() data: { roomId: string }, @ConnectedSocket() client: Socket) {
    const room = await this.rooms.get(data.roomId);
    if (!room || room.rules.silenced) {
      client.emit('rooms:rate_limit:error', { remaining_ms: 0 });
      return;
    }
    client.join(data.roomId);
    client.emit('rooms:joined', { roomId: data.roomId });
  }

  @UseGuards(AuthGuard)
  @SubscribeMessage('rooms:message:send')
  async handleMessage(@MessageBody() data: { roomId: string; content: string }, @ConnectedSocket() client: Socket) {
    const room = await this.rooms.get(data.roomId);
    if (!room || room.rules.silenced) return;
    const globalIntervalMs = (room.rules.intervalGlobalSeconds || 3) * 1000;
    const perUserIntervalMs = (room.rules.perUserSeconds || 0) * 1000;
    const g = await this.rl.checkGlobal(data.roomId, globalIntervalMs);
    if (!g.allowed) {
      client.emit('rooms:rate_limit:error', { remaining_ms: g.remainingMs });
      this.rlErrorCounter.labels(data.roomId).inc();
      return;
    }
    if (perUserIntervalMs > 0) {
      const u = await this.rl.checkUser(data.roomId, (client as any).userId || client.id, perUserIntervalMs);
      if (!u.allowed) {
        client.emit('rooms:rate_limit:error', { remaining_ms: u.remainingMs });
        this.rlErrorCounter.labels(data.roomId).inc();
        return;
      }
    }
    const createdAt = new Date();
    let id: string = '';
    try {
      const row: any = await (this.prisma as any).message.create({
        data: { roomId: data.roomId, content: data.content, userId: ((client as any).userId || null), createdAt },
      });
      id = row.id?.toString?.() ?? '';
    } catch {
      id = `${createdAt.toISOString()}:${(client as any).userId || client.id}`;
    }
    this.server.to(data.roomId).emit('rooms:message:new', {
      roomId: data.roomId,
      content: data.content,
      userId: (client as any).userId || client.id,
      displayName: (client as any).displayName || '',
      createdAt: createdAt.toISOString(),
      id,
    });
    this.msgCounter.labels(data.roomId).inc();
  }

  @UseGuards(AuthGuard)
  @SubscribeMessage('rooms:typing')
  async handleTyping(@MessageBody() data: { roomId: string }, @ConnectedSocket() client: Socket) {
    this.server.to(data.roomId).emit('rooms:typing', { displayName: (client as any).displayName || 'Usuário' });
  }
  @SubscribeMessage('rooms:message:edit')
  async handleEdit(@MessageBody() data: { roomId: string; id: string; content: string }, @ConnectedSocket() client: Socket) {
    if (!data.roomId || !data.id || !data.content) return;
    const idx = data.id.lastIndexOf(':');
    const owner = idx >= 0 ? data.id.substring(idx + 1) : '';
    if (owner !== ((client as any).userId || client.id)) return;
    try {
      await (this.prisma as any).message.update({ where: { id: data.id }, data: { content: data.content } });
    } catch {}
    this.server.to(data.roomId).emit('rooms:message:edit', { id: data.id, content: data.content });
    client.emit('rooms:message:edit', { id: data.id, content: data.content });
  }
  @SubscribeMessage('rooms:message:delete')
  async handleDelete(@MessageBody() data: { roomId: string; id: string }, @ConnectedSocket() client: Socket) {
    if (!data.roomId || !data.id) return;
    const idx = data.id.lastIndexOf(':');
    const owner = idx >= 0 ? data.id.substring(idx + 1) : '';
    if (owner !== ((client as any).userId || client.id)) return;
    try {
      await (this.prisma as any).message.delete({ where: { id: data.id } });
    } catch {}
    this.server.to(data.roomId).emit('rooms:message:delete', { id: data.id });
    client.emit('rooms:message:delete', { id: data.id });
  }
  @UseGuards(AuthGuard)
  @SubscribeMessage('rooms:read')
  async handleRead(@MessageBody() data: { roomId: string }, @ConnectedSocket() client: Socket) {
    try {
      await (this.rooms as any).markRead((client as any).userId || client.id, data.roomId);
      const counts = await (this.rooms as any).unreadCounts((client as any).userId || client.id);
      this.server.to(`user:${(client as any).userId || client.id}`).emit('rooms:unread:update', counts);
    } catch {}
  }

  async handleDisconnect(client: Socket) {
    const uid = (client as any).userId;
    if (uid) this.presence.remove(uid);
  }
}
