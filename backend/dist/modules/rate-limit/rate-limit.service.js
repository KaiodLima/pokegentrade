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
exports.RateLimitService = void 0;
const common_1 = require("@nestjs/common");
const redis_service_1 = require("../redis/redis.service");
let RateLimitService = class RateLimitService {
    constructor(redis) {
        this.redis = redis;
        this.lastGlobal = new Map();
        this.lastUser = new Map();
    }
    now() {
        return Date.now();
    }
    async checkGlobal(roomId, intervalMs) {
        const key = `rl:room:${roomId}:global`;
        try {
            return await this.checkWithRedis(key, intervalMs);
        }
        catch {
            const prev = this.lastGlobal.get(key) || 0;
            const delta = this.now() - prev;
            if (delta < intervalMs)
                return { allowed: false, remainingMs: intervalMs - delta };
            this.lastGlobal.set(key, this.now());
            return { allowed: true, remainingMs: 0 };
        }
    }
    async checkUser(roomId, userId, intervalMs) {
        const key = `rl:room:${roomId}:user:${userId}`;
        try {
            return await this.checkWithRedis(key, intervalMs);
        }
        catch {
            const prev = this.lastUser.get(key) || 0;
            const delta = this.now() - prev;
            if (delta < intervalMs)
                return { allowed: false, remainingMs: intervalMs - delta };
            this.lastUser.set(key, this.now());
            return { allowed: true, remainingMs: 0 };
        }
    }
    async checkWithRedis(key, intervalMs) {
        const ttlSec = Math.ceil(intervalMs / 1000);
        const client = this.redis.client;
        if (!client)
            throw new Error('redis not ready');
        const exists = await client.exists(key);
        if (exists) {
            const ttl = await client.ttl(key);
            const remainingMs = ttl > 0 ? ttl * 1000 : intervalMs;
            return { allowed: false, remainingMs };
        }
        await client.set(key, '1', 'EX', ttlSec);
        return { allowed: true, remainingMs: 0 };
    }
};
exports.RateLimitService = RateLimitService;
exports.RateLimitService = RateLimitService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [redis_service_1.RedisService])
], RateLimitService);
//# sourceMappingURL=rate-limit.service.js.map