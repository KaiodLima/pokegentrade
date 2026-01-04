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
exports.PresenceService = void 0;
const common_1 = require("@nestjs/common");
const redis_service_1 = require("../redis/redis.service");
let PresenceService = class PresenceService {
    constructor(redis) {
        this.redis = redis;
        this.online = new Set();
        this.key = 'presence:online';
    }
    async add(userId) {
        if (!userId)
            return;
        if (this.redis.client) {
            try {
                await this.redis.sadd(this.key, userId);
                return;
            }
            catch { }
        }
        this.online.add(userId);
    }
    async remove(userId) {
        if (!userId)
            return;
        if (this.redis.client) {
            try {
                await this.redis.srem(this.key, userId);
                return;
            }
            catch { }
        }
        this.online.delete(userId);
    }
    async list() {
        if (this.redis.client) {
            try {
                return await this.redis.smembers(this.key);
            }
            catch { }
        }
        return Array.from(this.online.values());
    }
};
exports.PresenceService = PresenceService;
exports.PresenceService = PresenceService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [redis_service_1.RedisService])
], PresenceService);
//# sourceMappingURL=presence.service.js.map