import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type Msg = { id?: string; from: string; to: string; content: string; createdAt: string; readAt?: string | null; displayName?: string };

@Injectable()
export class DmService {
  private store = new Map<string, Msg[]>();
  private lastRead = new Map<string, string>(); // key: dm:<me>:<peer> -> ISO date
  private nameCache = new Map<string, string>();
  constructor(private readonly prisma: PrismaService) {}
  key(a: string, b: string) {
    const s = [a, b].sort();
    return `dm:${s[0]}:${s[1]}`;
  }
  async add(m: Msg): Promise<string> {
    try {
      const row: any = await (this.prisma as any).directMessage.create({ data: { fromId: m.from, toId: m.to, content: m.content, createdAt: new Date(m.createdAt) } });
      return row.id?.toString?.() ?? '';
    } catch {
      const k = this.key(m.from, m.to);
      const arr = this.store.get(k) || [];
      const id = m.id ?? `${m.createdAt}:${m.from}`;
      arr.push({ ...m, id });
      if (arr.length > 200) arr.shift();
      this.store.set(k, arr);
      return id;
    }
  }
  async history(a: string, b: string, limit = 50) {
    try {
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
      try {
        const users: any[] = await (this.prisma as any).user.findMany({ where: { id: { in: ids } } });
        names = new Map<string, string>(users.map(u => [u.id, (u.displayName || u.name || '')]));
        for (const [k, v] of names.entries()) this.nameCache.set(k, v);
      } catch {
        names = new Map<string, string>(ids.map(id => [id, this.nameCache.get(id) || '']));
      }
      return rows.map((r: any) => ({ id: r.id?.toString?.() ?? undefined, from: r.fromId, to: r.toId, content: r.content, createdAt: r.createdAt.toISOString(), readAt: r.readAt ? r.readAt.toISOString() : null, displayName: names.get(r.fromId) || '' }));
    } catch {
      const k = this.key(a, b);
      const arr = this.store.get(k) || [];
      return arr.slice(Math.max(0, arr.length - limit)).map(m => ({ ...m, id: m.id ?? `${m.createdAt}:${m.from}`, readAt: null }));
    }
  }
  async inbox(me: string) {
    try {
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
      try {
        const users: any[] = await (this.prisma as any).user.findMany({ where: { id: { in: lastAuthors } } });
        names = new Map<string, string>(users.map(u => [u.id, (u.displayName || u.name || '')]));
        for (const [k, v] of names.entries()) this.nameCache.set(k, v);
      } catch {
        names = new Map<string, string>(lastAuthors.map(id => [id, this.nameCache.get(id) || '']));
      }
      const peers = Array.from(map.keys());
      let peerNames = new Map<string, string>();
      try {
        const pRows: any[] = await (this.prisma as any).user.findMany({ where: { id: { in: peers } } });
        peerNames = new Map<string, string>(pRows.map(u => [u.id, (u.displayName || u.name || '')]));
        for (const [k, v] of peerNames.entries()) this.nameCache.set(k, v);
      } catch {
        peerNames = new Map<string, string>(peers.map(id => [id, this.nameCache.get(id) || '']));
      }
      return Array.from(map.entries()).map(([peerId, last]) => ({ peerId, peerName: peerNames.get(peerId) || '', last: { ...last, displayName: names.get(last.from) || '' } }));
    } catch {
      const out: { peerId: string; last: Msg | null }[] = [];
      for (const [k, arr] of this.store.entries()) {
        if (!k.startsWith('dm:')) continue;
        const parts = k.split(':');
        const u1 = parts[1];
        const u2 = parts[2];
        if (u1 !== me && u2 !== me) continue;
        const peer = u1 === me ? u2 : u1;
        out.push({ peerId: peer, last: arr.length ? arr[arr.length - 1] : null });
      }
      return out.map(e => ({ ...e, peerName: this.nameCache.get(e.peerId) || '' })) as any;
    }
  }
  async unreadCounts(me: string) {
    try {
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
    } catch {
      const out: { peerId: string; count: number }[] = [];
      for (const [k, arr] of this.store.entries()) {
        if (!k.startsWith('dm:')) continue;
        const parts = k.split(':');
        const a = parts[1];
        const b = parts[2];
        const peer = a === me ? b : (b === me ? a : null);
        if (!peer) continue;
        const key = `dm:${me}:${peer}`;
        const cutoff = this.lastRead.get(key);
        const cutoffMs = cutoff ? new Date(cutoff).getTime() : 0;
        const count = arr.filter(m => m.to === me && new Date(m.createdAt).getTime() > cutoffMs).length;
        if (count > 0) out.push({ peerId: peer, count });
      }
      return out;
    }
  }
  async markRead(me: string, peer: string) {
    try {
      await (this.prisma as any).directMessage.updateMany({
        where: { toId: me, fromId: peer, readAt: null },
        data: { readAt: new Date() },
      });
    } catch {
      const key = `dm:${me}:${peer}`;
      this.lastRead.set(key, new Date().toISOString());
    }
    return { ok: true };
  }
  async edit(me: string, peer: string, id: string, content: string) {
    try {
      const row: any = await (this.prisma as any).directMessage.update({
        where: { id },
        data: { content },
      });
      if (row.fromId !== me || (row.toId !== peer && row.fromId !== peer)) throw new Error('forbidden');
      return { ok: true };
    } catch {
      const k = this.key(me, peer);
      const arr = this.store.get(k) || [];
      const idx = arr.findIndex(m => (m.id ?? `${m.createdAt}:${m.from}`) === id && m.from === me);
      if (idx >= 0) {
        arr[idx].content = content;
        this.store.set(k, arr);
        return { ok: true };
      }
      return { ok: false };
    }
  }
  async remove(me: string, peer: string, id: string) {
    try {
      const row: any = await (this.prisma as any).directMessage.delete({
        where: { id },
      });
      if (row.fromId !== me || (row.toId !== peer && row.fromId !== peer)) throw new Error('forbidden');
      return { ok: true };
    } catch {
      const k = this.key(me, peer);
      const arr = this.store.get(k) || [];
      const idx = arr.findIndex(m => (m.id ?? `${m.createdAt}:${m.from}`) === id && m.from === me);
      if (idx >= 0) {
        arr.splice(idx, 1);
        this.store.set(k, arr);
        return { ok: true };
      }
      return { ok: false };
    }
  }
}
