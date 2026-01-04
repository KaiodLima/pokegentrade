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
exports.NewsService = void 0;
const common_1 = require("@nestjs/common");
const redis_service_1 = require("../redis/redis.service");
const prisma_service_1 = require("../prisma/prisma.service");
const crypto_1 = require("crypto");
let NewsService = class NewsService {
    constructor(redis, prisma) {
        this.redis = redis;
        this.prisma = prisma;
        this.mem = new Map();
    }
    async list() {
        const out = [];
        if (this.redis.client) {
            try {
                const ids = await this.redis.smembers('news:ids');
                for (const id of ids) {
                    const raw = await this.redis.get(`news:item:${id}`);
                    if (raw) {
                        try {
                            out.push(JSON.parse(raw));
                        }
                        catch { }
                    }
                }
                out.sort((a, b) => (b.createdAt.localeCompare(a.createdAt)));
                return out;
            }
            catch { }
        }
        return Array.from(this.mem.values()).sort((a, b) => (b.createdAt.localeCompare(a.createdAt)));
    }
    async create(data) {
        var _a;
        const id = (0, crypto_1.randomUUID)();
        const item = { id, title: data.title, content: data.content, authorId: data.authorId, createdAt: new Date().toISOString(), attachments: ((_a = data.attachments) !== null && _a !== void 0 ? _a : []).filter((u) => typeof u === 'string') };
        if (this.redis.client) {
            try {
                await this.redis.sadd('news:ids', id);
                await this.redis.set(`news:item:${id}`, JSON.stringify(item));
                return item;
            }
            catch { }
        }
        this.mem.set(id, item);
        return item;
    }
    async update(id, data) {
        var _a, _b, _c, _d, _e, _f, _g, _h;
        if (this.redis.client) {
            try {
                const raw = await this.redis.get(`news:item:${id}`);
                if (!raw)
                    return null;
                const item = JSON.parse(raw);
                const updated = { ...item, title: ((_a = data.title) !== null && _a !== void 0 ? _a : item.title), content: ((_b = data.content) !== null && _b !== void 0 ? _b : item.content), attachments: ((_d = (_c = data.attachments) !== null && _c !== void 0 ? _c : item.attachments) !== null && _d !== void 0 ? _d : []) };
                await this.redis.set(`news:item:${id}`, JSON.stringify(updated));
                return updated;
            }
            catch { }
        }
        const current = this.mem.get(id);
        if (!current)
            return null;
        const updated = { ...current, title: ((_e = data.title) !== null && _e !== void 0 ? _e : current.title), content: ((_f = data.content) !== null && _f !== void 0 ? _f : current.content), attachments: ((_h = (_g = data.attachments) !== null && _g !== void 0 ? _g : current.attachments) !== null && _h !== void 0 ? _h : []) };
        this.mem.set(id, updated);
        return updated;
    }
    async remove(id) {
        if (this.redis.client) {
            try {
                await this.redis.srem('news:ids', id);
                await this.redis.set(`news:item:${id}`, '');
                return { message: 'deleted' };
            }
            catch { }
        }
        this.mem.delete(id);
        return { message: 'deleted' };
    }
};
exports.NewsService = NewsService;
exports.NewsService = NewsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [redis_service_1.RedisService, prisma_service_1.PrismaService])
], NewsService);
//# sourceMappingURL=news.service.js.map