"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RedisService = void 0;
const common_1 = require("@nestjs/common");
const ioredis_1 = __importDefault(require("ioredis"));
let RedisService = class RedisService {
    async onModuleInit() {
        const host = process.env.REDIS_HOST || 'localhost';
        const port = Number(process.env.REDIS_PORT || 6379);
        const client = new ioredis_1.default({
            host,
            port,
            lazyConnect: true,
            enableOfflineQueue: false,
            maxRetriesPerRequest: 0,
            retryStrategy: () => null,
        });
        client.on('error', () => { });
        try {
            await client.connect();
            this.client = client;
        }
        catch {
            this.client = null;
        }
    }
    async set(key, value, ttlSeconds) {
        if (!this.client)
            throw new Error('redis not ready');
        if (ttlSeconds) {
            await this.client.set(key, value, 'EX', ttlSeconds);
        }
        else {
            await this.client.set(key, value);
        }
    }
    async get(key) {
        if (!this.client)
            throw new Error('redis not ready');
        return this.client.get(key);
    }
    async incr(key) {
        if (!this.client)
            throw new Error('redis not ready');
        return this.client.incr(key);
    }
    async ttl(key) {
        if (!this.client)
            throw new Error('redis not ready');
        return this.client.ttl(key);
    }
    async sadd(key, member) {
        if (!this.client)
            throw new Error('redis not ready');
        await this.client.sadd(key, member);
    }
    async srem(key, member) {
        if (!this.client)
            throw new Error('redis not ready');
        await this.client.srem(key, member);
    }
    async smembers(key) {
        if (!this.client)
            throw new Error('redis not ready');
        return this.client.smembers(key);
    }
};
exports.RedisService = RedisService;
exports.RedisService = RedisService = __decorate([
    (0, common_1.Injectable)()
], RedisService);
//# sourceMappingURL=redis.service.js.map