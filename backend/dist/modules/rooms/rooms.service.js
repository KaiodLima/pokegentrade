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
exports.RoomsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const redis_service_1 = require("../redis/redis.service");
let RoomsService = class RoomsService {
    constructor(prisma, redis) {
        this.prisma = prisma;
        this.redis = redis;
        this.fallbackRooms = [
            { id: 'general', name: 'Geral', description: 'Sala pública geral', rules: { intervalGlobalSeconds: 3 } },
        ];
        this.lastRead = new Map();
    }
    async list() {
        if (!(this.prisma.available === true)) {
            return this.fallbackRooms;
        }
        try {
            return await this.prisma.room.findMany();
        }
        catch {
            return this.fallbackRooms;
        }
    }
    async listSummary() {
        var _a;
        const rooms = await this.list();
        const out = [];
        for (const r of rooms) {
            if (!(this.prisma.available === true)) {
                out.push({ id: r.id, name: r.name, lastContent: '', lastAt: '' });
            }
            else {
                try {
                    const last = await this.prisma.message.findFirst({ where: { roomId: r.id }, orderBy: { createdAt: 'desc' } });
                    out.push({
                        id: r.id,
                        name: r.name,
                        lastContent: (_a = last === null || last === void 0 ? void 0 : last.content) !== null && _a !== void 0 ? _a : '',
                        lastAt: (last === null || last === void 0 ? void 0 : last.createdAt) ? (last.createdAt.toISOString()) : '',
                    });
                }
                catch {
                    out.push({ id: r.id, name: r.name, lastContent: '', lastAt: '' });
                }
            }
        }
        return out;
    }
    async create(data) {
        var _a, _b, _c, _d, _e;
        if (!(this.prisma.available === true)) {
            const id = data.name.toLowerCase().replace(/[^a-z0-9_-]+/g, '-').replace(/^-+|-+$/g, '') || `room_${Math.random().toString(36).slice(2)}`;
            const r = { id, name: data.name, description: (_a = data.description) !== null && _a !== void 0 ? _a : '', imageUrl: data.imageUrl || '', rules: data.rules };
            this.fallbackRooms.push(r);
            return r;
        }
        try {
            const created = await this.prisma.room.create({
                data: { name: data.name, description: (_b = data.description) !== null && _b !== void 0 ? _b : '', imageUrl: data.imageUrl || null, rulesJson: data.rules, silenced: ((_d = (_c = data.rules) === null || _c === void 0 ? void 0 : _c.silenced) !== null && _d !== void 0 ? _d : false) === true },
            });
            this.prisma.available = true;
            return created;
        }
        catch {
            const id = data.name.toLowerCase().replace(/[^a-z0-9_-]+/g, '-').replace(/^-+|-+$/g, '') || `room_${Math.random().toString(36).slice(2)}`;
            const r = { id, name: data.name, description: (_e = data.description) !== null && _e !== void 0 ? _e : '', imageUrl: data.imageUrl || '', rules: data.rules };
            this.fallbackRooms.push(r);
            return r;
        }
    }
    async update(id, data) {
        var _a, _b, _c, _d, _e, _f, _g;
        if (!(this.prisma.available === true)) {
            const idx = this.fallbackRooms.findIndex(r => r.id === id);
            if (idx >= 0) {
                this.fallbackRooms[idx] = { id, name: data.name, description: (_a = data.description) !== null && _a !== void 0 ? _a : '', imageUrl: data.imageUrl || (this.fallbackRooms[idx].imageUrl || ''), rules: data.rules };
                return this.fallbackRooms[idx];
            }
            return { id, name: data.name, description: (_b = data.description) !== null && _b !== void 0 ? _b : '', imageUrl: data.imageUrl || '', rules: data.rules };
        }
        try {
            const updated = await this.prisma.room.update({ where: { id }, data: { name: data.name, description: (_c = data.description) !== null && _c !== void 0 ? _c : '', imageUrl: data.imageUrl || undefined, rulesJson: data.rules, silenced: ((_e = (_d = data.rules) === null || _d === void 0 ? void 0 : _d.silenced) !== null && _e !== void 0 ? _e : false) === true } });
            this.prisma.available = true;
            return updated;
        }
        catch {
            const idx = this.fallbackRooms.findIndex(r => r.id === id);
            if (idx >= 0) {
                this.fallbackRooms[idx] = { id, name: data.name, description: (_f = data.description) !== null && _f !== void 0 ? _f : '', imageUrl: data.imageUrl || (this.fallbackRooms[idx].imageUrl || ''), rules: data.rules };
                return this.fallbackRooms[idx];
            }
            return { id, name: data.name, description: (_g = data.description) !== null && _g !== void 0 ? _g : '', imageUrl: data.imageUrl || '', rules: data.rules };
        }
    }
    async remove(id) {
        if (!(this.prisma.available === true)) {
            const idx = this.fallbackRooms.findIndex(r => r.id === id);
            if (idx >= 0)
                this.fallbackRooms.splice(idx, 1);
            return { message: 'deleted' };
        }
        try {
            await this.prisma.room.delete({ where: { id } });
            this.prisma.available = true;
            return { message: 'deleted' };
        }
        catch {
            const idx = this.fallbackRooms.findIndex(r => r.id === id);
            if (idx >= 0)
                this.fallbackRooms.splice(idx, 1);
            return { message: 'deleted' };
        }
    }
    async get(roomId) {
        var _a, _b;
        if (!(this.prisma.available === true)) {
            return this.fallbackRooms.find(r => r.id === roomId) || null;
        }
        try {
            const row = await this.prisma.room.findUnique({ where: { id: roomId } });
            if (!row)
                return null;
            const rulesJson = row.rulesJson || {};
            return {
                id: row.id,
                name: row.name,
                description: row.description || '',
                rules: {
                    intervalGlobalSeconds: Number((_a = rulesJson.intervalGlobalSeconds) !== null && _a !== void 0 ? _a : 3),
                    perUserSeconds: Number((_b = rulesJson.perUserSeconds) !== null && _b !== void 0 ? _b : 0),
                    silenced: (row.silenced === true) || (rulesJson.silenced === true),
                },
            };
        }
        catch {
            return this.fallbackRooms.find(r => r.id === roomId) || null;
        }
    }
    async markRead(userId, roomId) {
        const at = new Date().toISOString();
        const key = `rooms:lastread:${userId}:${roomId}`;
        if (this.redis.client) {
            try {
                await this.redis.set(key, at);
                return { ok: true };
            }
            catch { }
        }
        this.lastRead.set(`${userId}:${roomId}`, at);
        return { ok: true };
    }
    async unreadCounts(userId) {
        const rooms = await this.list();
        const out = [];
        for (const r of rooms) {
            const key = `${userId}:${r.id}`;
            let last = this.lastRead.get(key);
            if (this.redis.client) {
                try {
                    last = (await this.redis.get(`rooms:lastread:${key}`)) || last;
                }
                catch { }
            }
            if (!(this.prisma.available === true)) {
                out.push({ roomId: r.id, count: 0 });
            }
            else {
                try {
                    const where = { roomId: r.id };
                    if (last)
                        where.createdAt = { gt: new Date(last) };
                    const count = await this.prisma.message.count({ where });
                    out.push({ roomId: r.id, count });
                }
                catch {
                    out.push({ roomId: r.id, count: 0 });
                }
            }
        }
        return out;
    }
    async popular(limit = 10) {
        const rooms = await this.list();
        const stats = [];
        for (const r of rooms) {
            if (!(this.prisma.available === true)) {
                stats.push({ id: r.id, name: r.name, count: 0, lastAt: '' });
            }
            else {
                try {
                    const count = await this.prisma.message.count({ where: { roomId: r.id } });
                    const last = await this.prisma.message.findFirst({ where: { roomId: r.id }, orderBy: { createdAt: 'desc' } });
                    stats.push({ id: r.id, name: r.name, count, lastAt: (last === null || last === void 0 ? void 0 : last.createdAt) ? (last.createdAt.toISOString()) : '' });
                }
                catch {
                    stats.push({ id: r.id, name: r.name, count: 0, lastAt: '' });
                }
            }
        }
        stats.sort((a, b) => (b.count - a.count));
        return stats.slice(0, Math.max(1, Math.min(50, limit)));
    }
};
exports.RoomsService = RoomsService;
exports.RoomsService = RoomsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService, redis_service_1.RedisService])
], RoomsService);
//# sourceMappingURL=rooms.service.js.map