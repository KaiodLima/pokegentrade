import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type Msg = { id?: string; from: string; to: string; content: string; createdAt: string; readAt?: string | null; displayName?: string };

@Injectable()
export class DmService {
  private nameCache = new Map<string, string>();
  constructor(private readonly prisma: PrismaService) {}
  key(a: string, b: string) {
    const s = [a, b].sort();
    return `dm:${s[0]}:${s[1]}`;
  }
  async add(m: Msg): Promise<string> {
      const row: any = await (this.prisma as any).directMessage.create({ data: { fromId: m.from, toId: m.to, content: m.content, createdAt: new Date(m.createdAt) } });
      return row.id?.toString?.() ?? '';
  }
  async history(a: string, b: string, limit = 50) {
      const rows: any[] = await (this.prisma as any).directMessage.findMany({
        where: {
          OR: [
            { fromId: a, toId: b },
            { fromId: b, toId: a },
          ],
        },
        orderBy: { createdAt: 'asc' },
        take: limit,
      });
      const ids = Array.from(new Set(rows.map(r => r.fromId)));
      let names = new Map<string, string>();
        const users: any[] = await (this.prisma as any).user.findMany({ where: { id: { in: ids } } });
        names = new Map<string, string>(users.map(u => [u.id, (u.displayName || u.name || '')]));
        for (const [k, v] of names.entries()) this.nameCache.set(k, v);
      return rows.map((r: any) => ({ id: r.id?.toString?.() ?? undefined, from: r.fromId, to: r.toId, content: r.content, createdAt: r.createdAt.toISOString(), readAt: r.readAt ? r.readAt.toISOString() : null, displayName: names.get(r.fromId) || '' }));
  }
  async inbox(me: string) {
      const rows: any[] = await (this.prisma as any).directMessage.findMany({
        where: { OR: [{ fromId: me }, { toId: me }] },
        orderBy: { createdAt: 'desc' },
        take: 100,
      });
      const map = new Map<string, Msg>();
      for (const r of rows) {
        const peer = r.fromId === me ? r.toId : r.fromId;
        if (!map.has(peer)) {
          map.set(peer, { from: r.fromId, to: r.toId, content: r.content, createdAt: r.createdAt.toISOString() });
        }
      }
      const lastAuthors = Array.from(map.values()).map(m => m.from);
      let names = new Map<string, string>();
        const users: any[] = await (this.prisma as any).user.findMany({ where: { id: { in: lastAuthors } } });
        names = new Map<string, string>(users.map(u => [u.id, (u.displayName || u.name || '')]));
        for (const [k, v] of names.entries()) this.nameCache.set(k, v);
      const peers = Array.from(map.keys());
      let peerNames = new Map<string, string>();
        const pRows: any[] = await (this.prisma as any).user.findMany({ where: { id: { in: peers } } });
        peerNames = new Map<string, string>(pRows.map(u => [u.id, (u.displayName || u.name || '')]));
        for (const [k, v] of peerNames.entries()) this.nameCache.set(k, v);
      return Array.from(map.entries()).map(([peerId, last]) => ({ peerId, peerName: peerNames.get(peerId) || '', last: { ...last, displayName: names.get(last.from) || '' } }));
  }
  async unreadCounts(me: string) {
      const rows: any[] = await (this.prisma as any).directMessage.findMany({
        where: { toId: me, readAt: null },
        orderBy: { createdAt: 'desc' },
        take: 1000,
      });
      const map = new Map<string, number>();
      for (const r of rows) {
        map.set(r.fromId, (map.get(r.fromId) || 0) + 1);
      }
      return Array.from(map.entries()).map(([peerId, count]) => ({ peerId, count }));
  }
  async markRead(me: string, peer: string) {
      await (this.prisma as any).directMessage.updateMany({
        where: { toId: me, fromId: peer, readAt: null },
        data: { readAt: new Date() },
      });
    return { ok: true };
  }
  async edit(me: string, peer: string, id: string, content: string) {
      const row: any = await (this.prisma as any).directMessage.update({
        where: { id },
        data: { content },
      });
      if (row.fromId !== me || (row.toId !== peer && row.fromId !== peer)) throw new Error('forbidden');
      return { ok: true };
  }
  async remove(me: string, peer: string, id: string) {
      const row: any = await (this.prisma as any).directMessage.delete({
        where: { id },
      });
      if (row.fromId !== me || (row.toId !== peer && row.fromId !== peer)) throw new Error('forbidden');
      return { ok: true };
  }
}
