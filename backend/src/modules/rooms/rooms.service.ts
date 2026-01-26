import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

interface Room {
  id: string;
  name: string;
  description?: string;
  imageUrl?: string;
  rules: { intervalGlobalSeconds: number; perUserSeconds?: number; silenced?: boolean };
}

@Injectable()
export class RoomsService {
  constructor(private readonly prisma: PrismaService, private readonly redis: RedisService) {}
  async list() {
    try {
      return await this.prisma.room.findMany();
    } catch {
      return [];
    }
  }
  async listSummary() {
    const rooms: any[] = await this.list() as any[];
    const out: { id: string; name: string; lastContent: string; lastAt: string }[] = [];
    for (const r of rooms) {
        try {
          const last: any = await (this.prisma as any).message.findFirst({ where: { roomId: r.id }, orderBy: { createdAt: 'desc' } });
          out.push({
            id: r.id,
            name: r.name,
            lastContent: last?.content ?? '',
            lastAt: last?.createdAt ? ((last.createdAt as Date).toISOString()) : '',
          });
        } catch {
          out.push({ id: r.id, name: r.name, lastContent: '', lastAt: '' });
      }
    }
    return out;
  }
  async create(data: { name: string; description?: string; imageUrl?: string; rules: { intervalGlobalSeconds: number; perUserSeconds?: number; silenced?: boolean } }) {
    try {
      const created: any = await (this.prisma as any).room.create({
        data: { name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || null, rulesJson: data.rules as any, silenced: (data.rules?.silenced ?? false) === true },
      });
      return created;
    } catch {
      return { id: '', name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || '', rules: data.rules };
    }
  }
  async update(id: string, data: { name: string; description?: string; imageUrl?: string; rules: { intervalGlobalSeconds: number; perUserSeconds?: number; silenced?: boolean } }) {
    try {
      const updated: any = await (this.prisma as any).room.update({ where: { id }, data: { name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || undefined, rulesJson: data.rules as any, silenced: (data.rules?.silenced ?? false) === true } });
      return updated;
    } catch {
      return { id, name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || '', rules: data.rules };
    }
  }
  async remove(id: string) {
    try {
      await (this.prisma as any).room.delete({ where: { id } });
      return { message: 'deleted' };
    } catch {
      return { message: 'deleted' };
    }
  }
  async get(roomId: string) {
    try {
      const row: any = await (this.prisma as any).room.findUnique({ where: { id: roomId } });
      if (!row) return null;
      const rulesJson: any = row.rulesJson || {};
      return {
        id: row.id,
        name: row.name,
        description: row.description || '',
        rules: {
          intervalGlobalSeconds: Number(rulesJson.intervalGlobalSeconds ?? 3),
          perUserSeconds: Number(rulesJson.perUserSeconds ?? 0),
          silenced: (row.silenced === true) || (rulesJson.silenced === true),
        },
      };
    } catch {
      return null;
    }
  }
  async markRead(userId: string, roomId: string) {
    const at = new Date().toISOString();
    const key = `rooms:lastread:${userId}:${roomId}`;
    if (this.redis.client) {
      try { await this.redis.set(key, at); return { ok: true }; } catch {}
    }
    return { ok: false };
  }
  async unreadCounts(userId: string) {
    const rooms = await this.list();
    const out: { roomId: string; count: number }[] = [];
    for (const r of rooms as any[]) {
      const key = `${userId}:${r.id}`;
      let last: string | undefined = undefined;
      if (this.redis.client) {
        try { last = (await this.redis.get(`rooms:lastread:${key}`)) || last; } catch {}
      }
        try {
          const where: any = { roomId: r.id };
          if (last) where.createdAt = { gt: new Date(last) };
          const count = await (this.prisma as any).message.count({ where });
          out.push({ roomId: r.id, count });
        } catch {
          out.push({ roomId: r.id, count: 0 });
      }
    }
    return out;
  }
  async popular(limit: number = 10) {
    const rooms: any[] = await this.list() as any[];
    const stats: { id: string; name: string; count: number; lastAt: string }[] = [];
    for (const r of rooms) {
        try {
          const count = await (this.prisma as any).message.count({ where: { roomId: r.id } });
          const last: any = await (this.prisma as any).message.findFirst({ where: { roomId: r.id }, orderBy: { createdAt: 'desc' } });
          stats.push({ id: r.id, name: r.name, count, lastAt: last?.createdAt ? ((last.createdAt as Date).toISOString()) : '' });
        } catch {
          stats.push({ id: r.id, name: r.name, count: 0, lastAt: '' });
      }
    }
    stats.sort((a, b) => (b.count - a.count));
    return stats.slice(0, Math.max(1, Math.min(50, limit)));
  }
}
