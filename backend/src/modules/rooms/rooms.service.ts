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
  private fallbackRooms: Room[] = [
    { id: 'general', name: 'Geral', description: 'Sala pública geral', rules: { intervalGlobalSeconds: 3 } },
  ];
  constructor(private readonly prisma: PrismaService, private readonly redis: RedisService) {}
  private lastRead: Map<string, string> = new Map();
  async list() {
    if (!((this.prisma as any).available === true)) {
      return this.fallbackRooms;
    }
    try {
      return await this.prisma.room.findMany();
    } catch {
      return this.fallbackRooms;
    }
  }
  async listSummary() {
    const rooms: any[] = await this.list() as any[];
    const out: { id: string; name: string; lastContent: string; lastAt: string }[] = [];
    for (const r of rooms) {
      if (!((this.prisma as any).available === true)) {
        out.push({ id: r.id, name: r.name, lastContent: '', lastAt: '' });
      } else {
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
    }
    return out;
  }
  async create(data: { name: string; description?: string; imageUrl?: string; rules: { intervalGlobalSeconds: number; perUserSeconds?: number; silenced?: boolean } }) {
    if (!((this.prisma as any).available === true)) {
      const id = data.name.toLowerCase().replace(/[^a-z0-9_-]+/g, '-').replace(/^-+|-+$/g, '') || `room_${Math.random().toString(36).slice(2)}`;
      const r = { id, name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || '', rules: data.rules };
      this.fallbackRooms.push(r);
      return r;
    }
    try {
      const created: any = await (this.prisma as any).room.create({
        data: { name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || null, rulesJson: data.rules as any, silenced: (data.rules?.silenced ?? false) === true },
      });
      (this.prisma as any).available = true;
      return created;
    } catch {
      const id = data.name.toLowerCase().replace(/[^a-z0-9_-]+/g, '-').replace(/^-+|-+$/g, '') || `room_${Math.random().toString(36).slice(2)}`;
      const r = { id, name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || '', rules: data.rules };
      this.fallbackRooms.push(r);
      return r;
    }
  }
  async update(id: string, data: { name: string; description?: string; imageUrl?: string; rules: { intervalGlobalSeconds: number; perUserSeconds?: number; silenced?: boolean } }) {
    if (!((this.prisma as any).available === true)) {
      const idx = this.fallbackRooms.findIndex(r => r.id === id);
      if (idx >= 0) {
        this.fallbackRooms[idx] = { id, name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || (this.fallbackRooms[idx].imageUrl || ''), rules: data.rules };
        return this.fallbackRooms[idx];
      }
      return { id, name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || '', rules: data.rules };
    }
    try {
      const updated: any = await (this.prisma as any).room.update({ where: { id }, data: { name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || undefined, rulesJson: data.rules as any, silenced: (data.rules?.silenced ?? false) === true } });
      (this.prisma as any).available = true;
      return updated;
    } catch {
      const idx = this.fallbackRooms.findIndex(r => r.id === id);
      if (idx >= 0) {
        this.fallbackRooms[idx] = { id, name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || (this.fallbackRooms[idx].imageUrl || ''), rules: data.rules };
        return this.fallbackRooms[idx];
      }
      return { id, name: data.name, description: data.description ?? '', imageUrl: data.imageUrl || '', rules: data.rules };
    }
  }
  async remove(id: string) {
    if (!((this.prisma as any).available === true)) {
      const idx = this.fallbackRooms.findIndex(r => r.id === id);
      if (idx >= 0) this.fallbackRooms.splice(idx, 1);
      return { message: 'deleted' };
    }
    try {
      await (this.prisma as any).room.delete({ where: { id } });
      (this.prisma as any).available = true;
      return { message: 'deleted' };
    } catch {
      const idx = this.fallbackRooms.findIndex(r => r.id === id);
      if (idx >= 0) this.fallbackRooms.splice(idx, 1);
      return { message: 'deleted' };
    }
  }
  async get(roomId: string) {
    if (!((this.prisma as any).available === true)) {
      return this.fallbackRooms.find(r => r.id === roomId) || null;
    }
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
      return this.fallbackRooms.find(r => r.id === roomId) || null;
    }
  }
  async markRead(userId: string, roomId: string) {
    const at = new Date().toISOString();
    const key = `rooms:lastread:${userId}:${roomId}`;
    if (this.redis.client) {
      try { await this.redis.set(key, at); return { ok: true }; } catch {}
    }
    this.lastRead.set(`${userId}:${roomId}`, at);
    return { ok: true };
  }
  async unreadCounts(userId: string) {
    const rooms = await this.list();
    const out: { roomId: string; count: number }[] = [];
    for (const r of rooms as any[]) {
      const key = `${userId}:${r.id}`;
      let last = this.lastRead.get(key);
      if (this.redis.client) {
        try { last = (await this.redis.get(`rooms:lastread:${key}`)) || last; } catch {}
      }
      if (!((this.prisma as any).available === true)) {
        out.push({ roomId: r.id, count: 0 });
      } else {
        try {
          const where: any = { roomId: r.id };
          if (last) where.createdAt = { gt: new Date(last) };
          const count = await (this.prisma as any).message.count({ where });
          out.push({ roomId: r.id, count });
        } catch {
          out.push({ roomId: r.id, count: 0 });
        }
      }
    }
    return out;
  }
  async popular(limit: number = 10) {
    const rooms: any[] = await this.list() as any[];
    const stats: { id: string; name: string; count: number; lastAt: string }[] = [];
    for (const r of rooms) {
      if (!((this.prisma as any).available === true)) {
        stats.push({ id: r.id, name: r.name, count: 0, lastAt: '' });
      } else {
        try {
          const count = await (this.prisma as any).message.count({ where: { roomId: r.id } });
          const last: any = await (this.prisma as any).message.findFirst({ where: { roomId: r.id }, orderBy: { createdAt: 'desc' } });
          stats.push({ id: r.id, name: r.name, count, lastAt: last?.createdAt ? ((last.createdAt as Date).toISOString()) : '' });
        } catch {
          stats.push({ id: r.id, name: r.name, count: 0, lastAt: '' });
        }
      }
    }
    stats.sort((a, b) => (b.count - a.count));
    return stats.slice(0, Math.max(1, Math.min(50, limit)));
  }
}
