import { WebSocketGateway, SubscribeMessage, MessageBody, ConnectedSocket } from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { JwtService } from '../../common/jwt.service';
import { DmService } from './dm.service';
import { WebSocketServer } from '@nestjs/websockets';
import { Server } from 'socket.io';
const prom = require('prom-client');
import { metricsRegistry } from '../metrics/metrics.controller';

function pairKey(a: string, b: string) {
  const s = [a, b].sort();
  return `dm:${s[0]}:${s[1]}`;
}

@WebSocketGateway({ cors: { origin: true } })
export class DmGateway {
  constructor(private readonly jwt: JwtService, private readonly dm: DmService) {}
  @WebSocketServer() server!: Server;
  private readonly dmMsgCounter = new prom.Counter({ name: 'poketibia_dm_messages_total', help: 'DM messages', labelNames: ['pair'], registers: [metricsRegistry] });
  private readonly dmTypingCounter = new prom.Counter({ name: 'poketibia_dm_typing_events_total', help: 'DM typing events', labelNames: ['pair'], registers: [metricsRegistry] });
  async handleConnection(client: Socket) {
    const token = (client.handshake.auth as any)?.token || (client.handshake.query as any)?.token;
    if (!token) return client.disconnect();
    const payload = this.jwt.verifyAccess(token);
    if (!payload || payload.status === 'suspensa') return client.disconnect();
    (client as any).userId = payload.sub;
    (client as any).displayName = (payload as any).name || '';
    client.join(`user:${(client as any).userId}`);
  }
  @SubscribeMessage('dm:join')
  async join(@MessageBody() data: { userId: string }, @ConnectedSocket() client: Socket) {
    const uid = (client as any).userId;
    if (!uid || !data.userId) return;
    client.join(pairKey(uid, data.userId));
  }
  @SubscribeMessage('dm:message:send')
  async send(@MessageBody() data: { userId: string; content: string }, @ConnectedSocket() client: Socket) {
    const uid = (client as any).userId;
    if (!uid || !data.userId || !data.content) return;
    const pair = pairKey(uid, data.userId);
    const createdAt = new Date().toISOString();
    const id = await this.dm.add({ from: uid, to: data.userId, content: data.content, createdAt, displayName: (client as any).displayName || '' });
    const payload = { id, from: uid, to: data.userId, content: data.content, createdAt, displayName: (client as any).displayName || '' };
    client.to(pair).emit('dm:message:new', payload);
    client.emit('dm:message:new', payload);
    this.dmMsgCounter.labels(pair).inc();
    try {
      const counts = await this.dm.unreadCounts(data.userId);
      this.server.to(`user:${data.userId}`).emit('dm:unread:update', counts);
    } catch {}
  }
  @SubscribeMessage('dm:typing')
  async typing(@MessageBody() data: { userId: string }, @ConnectedSocket() client: Socket) {
    const uid = (client as any).userId;
    if (!uid || !data.userId) return;
    const pair = pairKey(uid, data.userId);
    client.to(pair).emit('dm:typing', { displayName: (client as any).displayName || 'Usuário' });
    this.dmTypingCounter.labels(pair).inc();
  }
  @SubscribeMessage('dm:read')
  async read(@MessageBody() data: { userId: string }, @ConnectedSocket() client: Socket) {
    const uid = (client as any).userId;
    if (!uid || !data.userId) return;
    const when = new Date().toISOString();
    await this.dm.markRead(uid, data.userId);
    const pair = pairKey(uid, data.userId);
    this.server.to(pair).emit('dm:read', { userId: uid, at: when });
    try {
      const countsMe = await this.dm.unreadCounts(uid);
      const countsPeer = await this.dm.unreadCounts(data.userId);
      this.server.to(`user:${uid}`).emit('dm:unread:update', countsMe);
      this.server.to(`user:${data.userId}`).emit('dm:unread:update', countsPeer);
    } catch {}
  }
  @SubscribeMessage('dm:message:edit')
  async edit(@MessageBody() data: { userId: string; id: string; content: string }, @ConnectedSocket() client: Socket) {
    const uid = (client as any).userId;
    if (!uid || !data.userId || !data.id || !data.content) return;
    const ok = await this.dm.edit(uid, data.userId, data.id, data.content);
    if (!ok || (ok as any).ok !== true) return;
    const pair = pairKey(uid, data.userId);
    this.server.to(pair).emit('dm:message:edit', { id: data.id, content: data.content });
    client.emit('dm:message:edit', { id: data.id, content: data.content });
  }
  @SubscribeMessage('dm:message:delete')
  async remove(@MessageBody() data: { userId: string; id: string }, @ConnectedSocket() client: Socket) {
    const uid = (client as any).userId;
    if (!uid || !data.userId || !data.id) return;
    const ok = await this.dm.remove(uid, data.userId, data.id);
    if (!ok || (ok as any).ok !== true) return;
    const pair = pairKey(uid, data.userId);
    this.server.to(pair).emit('dm:message:delete', { id: data.id });
    client.emit('dm:message:delete', { id: data.id });
  }
}
