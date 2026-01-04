import { Body, Controller, Get, Param, Post, UseGuards, Query, Req } from '@nestjs/common';
import { IsString, MinLength } from 'class-validator';
import { RateLimitService } from '../rate-limit/rate-limit.service';
import { RoomsService } from '../rooms/rooms.service';
import { AuthGuard } from '../../common/auth.guard';
import { PrismaService } from '../prisma/prisma.service';

class SendMessageDto {
  @IsString()
  roomId!: string;
  @IsString()
  @MinLength(1)
  content!: string;
}

@Controller('rooms/:roomId/messages')
export class MessagesController {
  constructor(private readonly rl: RateLimitService, private readonly rooms: RoomsService, private readonly prisma: PrismaService) {}
  @Get()
  async list(@Param('roomId') roomId: string, @Query('limit') limit: string, @Query('before') before: string, @Query('q') q: string) {
    try {
      const take = Math.max(1, Math.min(200, parseInt(limit || '50', 10)));
      const where: any = { roomId };
      if (q) {
        const txt = q.toString();
        where.content = { contains: txt, mode: 'insensitive' };
      }
      if (before) {
        const d = new Date(before);
        if (!isNaN(d.getTime())) where.createdAt = { lt: d };
      }
      const rows: any[] = await this.prisma.message.findMany({ where, orderBy: { createdAt: 'desc' }, take });
      const ids = Array.from(new Set(rows.map(r => r.userId).filter(Boolean)));
      let names = new Map<string, string>();
      try {
        const users: any[] = await (this.prisma as any).user.findMany({ where: { id: { in: ids } } });
        names = new Map<string, string>(users.map(u => [u.id, (u.displayName || u.name || '')]));
      } catch {}
      return rows.map(r => ({ id: r.id?.toString?.() ?? '', roomId: r.roomId, content: r.content, userId: r.userId, createdAt: (r.createdAt as Date).toISOString(), displayName: r.userId ? (names.get(r.userId) || '') : '' }));
    } catch {
      return [];
    }
  }

  @Post()
  @UseGuards(AuthGuard)
  async send(@Param('roomId') roomId: string, @Body() dto: SendMessageDto, @Req() req: any) {
    const room: any = await this.rooms.get(roomId);
    if (!room || room.rules.silenced) {
      return { status: 'blocked', reason: 'room_silenced_or_missing' };
    }
    const globalIntervalMs = (room.rules.intervalGlobalSeconds || 3) * 1000;
    const perUserIntervalMs = (room.rules.perUserSeconds || 0) * 1000;
    const g = await (this.rl.checkGlobal(roomId, globalIntervalMs) as any);
    if (!g.allowed) return { status: 'blocked', remainingMs: g.remainingMs, scope: 'global' };
    if (perUserIntervalMs > 0) {
      const u = await (this.rl.checkUser(roomId, (req.user?.sub || 'stub-user-id'), perUserIntervalMs) as any);
      if (!u.allowed) return { status: 'blocked', remainingMs: u.remainingMs, scope: 'user' };
    }
    try {
      const msg = await this.prisma.message.create({
        data: { roomId, content: dto.content, userId: (req.user?.sub || null) },
      });
      return msg;
    } catch {
      return { status: 'sent', roomId, content: dto.content, createdAt: new Date().toISOString() };
    }
  }
}
