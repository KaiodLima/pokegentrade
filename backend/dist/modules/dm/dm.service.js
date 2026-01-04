"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DmService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let DmService = class DmService {
    constructor(prisma) {
        this.prisma = prisma;
        this.store = new Map();
        this.lastRead = new Map();
        this.nameCache = new Map();
    }
    key(a, b) {
        const s = [a, b].sort();
        return `dm:${s[0]}:${s[1]}`;
    }
    async add(m) {
        var _a, _b, _c, _d;
        try {
            const row = await this.prisma.directMessage.create({ data: { fromId: m.from, toId: m.to, content: m.content, createdAt: new Date(m.createdAt) } });
            return (_c = (_b = (_a = row.id) === null || _a === void 0 ? void 0 : _a.toString) === null || _b === void 0 ? void 0 : _b.call(_a)) !== null && _c !== void 0 ? _c : '';
        }
        catch {
            const k = this.key(m.from, m.to);
            const arr = this.store.get(k) || [];
            const id = (_d = m.id) !== null && _d !== void 0 ? _d : `${m.createdAt}:${m.from}`;
            arr.push({ ...m, id });
            if (arr.length > 200)
                arr.shift();
            this.store.set(k, arr);
            return id;
        }
    }
    async history(a, b, limit = 50) {
        try {
            const rows = await this.prisma.directMessage.findMany({
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
            let names = new Map();
            try {
                const users = await this.prisma.user.findMany({ where: { id: { in: ids } } });
                names = new Map(users.map(u => [u.id, (u.displayName || u.name || '')]));
                for (const [k, v] of names.entries())
                    this.nameCache.set(k, v);
            }
            catch {
                names = new Map(ids.map(id => [id, this.nameCache.get(id) || '']));
            }
            return rows.map((r) => { var _a, _b, _c; return ({ id: (_c = (_b = (_a = r.id) === null || _a === void 0 ? void 0 : _a.toString) === null || _b === void 0 ? void 0 : _b.call(_a)) !== null && _c !== void 0 ? _c : undefined, from: r.fromId, to: r.toId, content: r.content, createdAt: r.createdAt.toISOString(), readAt: r.readAt ? r.readAt.toISOString() : null, displayName: names.get(r.fromId) || '' }); });
        }
        catch {
            const k = this.key(a, b);
            const arr = this.store.get(k) || [];
            return arr.slice(Math.max(0, arr.length - limit)).map(m => { var _a; return ({ ...m, id: (_a = m.id) !== null && _a !== void 0 ? _a : `${m.createdAt}:${m.from}`, readAt: null }); });
        }
    }
    async inbox(me) {
        try {
            const rows = await this.prisma.directMessage.findMany({
                where: { OR: [{ fromId: me }, { toId: me }] },
                orderBy: { createdAt: 'desc' },
                take: 100,
            });
            const map = new Map();
            for (const r of rows) {
                const peer = r.fromId === me ? r.toId : r.fromId;
                if (!map.has(peer)) {
                    map.set(peer, { from: r.fromId, to: r.toId, content: r.content, createdAt: r.createdAt.toISOString() });
                }
            }
            const lastAuthors = Array.from(map.values()).map(m => m.from);
            let names = new Map();
            try {
                const users = await this.prisma.user.findMany({ where: { id: { in: lastAuthors } } });
                names = new Map(users.map(u => [u.id, (u.displayName || u.name || '')]));
                for (const [k, v] of names.entries())
                    this.nameCache.set(k, v);
            }
            catch {
                names = new Map(lastAuthors.map(id => [id, this.nameCache.get(id) || '']));
            }
            const peers = Array.from(map.keys());
            let peerNames = new Map();
            try {
                const pRows = await this.prisma.user.findMany({ where: { id: { in: peers } } });
                peerNames = new Map(pRows.map(u => [u.id, (u.displayName || u.name || '')]));
                for (const [k, v] of peerNames.entries())
                    this.nameCache.set(k, v);
            }
            catch {
                peerNames = new Map(peers.map(id => [id, this.nameCache.get(id) || '']));
            }
            return Array.from(map.entries()).map(([peerId, last]) => ({ peerId, peerName: peerNames.get(peerId) || '', last: { ...last, displayName: names.get(last.from) || '' } }));
        }
        catch {
            const out = [];
            for (const [k, arr] of this.store.entries()) {
                if (!k.startsWith('dm:'))
                    continue;
                const parts = k.split(':');
                const u1 = parts[1];
                const u2 = parts[2];
                if (u1 !== me && u2 !== me)
                    continue;
                const peer = u1 === me ? u2 : u1;
                out.push({ peerId: peer, last: arr.length ? arr[arr.length - 1] : null });
            }
            return out.map(e => ({ ...e, peerName: this.nameCache.get(e.peerId) || '' }));
        }
    }
    async unreadCounts(me) {
        try {
            const rows = await this.prisma.directMessage.findMany({
                where: { toId: me, readAt: null },
                orderBy: { createdAt: 'desc' },
                take: 1000,
            });
            const map = new Map();
            for (const r of rows) {
                map.set(r.fromId, (map.get(r.fromId) || 0) + 1);
            }
            return Array.from(map.entries()).map(([peerId, count]) => ({ peerId, count }));
        }
        catch {
            const out = [];
            for (const [k, arr] of this.store.entries()) {
                if (!k.startsWith('dm:'))
                    continue;
                const parts = k.split(':');
                const a = parts[1];
                const b = parts[2];
                const peer = a === me ? b : (b === me ? a : null);
                if (!peer)
                    continue;
                const key = `dm:${me}:${peer}`;
                const cutoff = this.lastRead.get(key);
                const cutoffMs = cutoff ? new Date(cutoff).getTime() : 0;
                const count = arr.filter(m => m.to === me && new Date(m.createdAt).getTime() > cutoffMs).length;
                if (count > 0)
                    out.push({ peerId: peer, count });
            }
            return out;
        }
    }
    async markRead(me, peer) {
        try {
            await this.prisma.directMessage.updateMany({
                where: { toId: me, fromId: peer, readAt: null },
                data: { readAt: new Date() },
            });
        }
        catch {
            const key = `dm:${me}:${peer}`;
            this.lastRead.set(key, new Date().toISOString());
        }
        return { ok: true };
    }
    async edit(me, peer, id, content) {
        try {
            const row = await this.prisma.directMessage.update({
                where: { id },
                data: { content },
            });
            if (row.fromId !== me || (row.toId !== peer && row.fromId !== peer))
                throw new Error('forbidden');
            return { ok: true };
        }
        catch {
            const k = this.key(me, peer);
            const arr = this.store.get(k) || [];
            const idx = arr.findIndex(m => { var _a; return ((_a = m.id) !== null && _a !== void 0 ? _a : `${m.createdAt}:${m.from}`) === id && m.from === me; });
            if (idx >= 0) {
                arr[idx].content = content;
                this.store.set(k, arr);
                return { ok: true };
            }
            return { ok: false };
        }
    }
    async remove(me, peer, id) {
        try {
            const row = await this.prisma.directMessage.delete({
                where: { id },
            });
            if (row.fromId !== me || (row.toId !== peer && row.fromId !== peer))
                throw new Error('forbidden');
            return { ok: true };
        }
        catch {
            const k = this.key(me, peer);
            const arr = this.store.get(k) || [];
            const idx = arr.findIndex(m => { var _a; return ((_a = m.id) !== null && _a !== void 0 ? _a : `${m.createdAt}:${m.from}`) === id && m.from === me; });
            if (idx >= 0) {
                arr.splice(idx, 1);
                this.store.set(k, arr);
                return { ok: true };
            }
            return { ok: false };
        }
    }
};
exports.DmService = DmService;
exports.DmService = DmService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], DmService);
//# sourceMappingURL=dm.service.js.map