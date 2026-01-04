import { Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';

type Key = string;

@Injectable()
export class RateLimitService {
  private lastGlobal: Map<Key, number> = new Map();
  private lastUser: Map<Key, number> = new Map();
  constructor(private readonly redis: RedisService) {}

  now() {
    return Date.now();
  }

  async checkGlobal(roomId: string, intervalMs: number) {
    const key = `rl:room:${roomId}:global`;
    try {
      // Redis approach: attempt to set with TTL only when not set
      return await this.checkWithRedis(key, intervalMs);
    } catch {
      const prev = this.lastGlobal.get(key) || 0;
      const delta = this.now() - prev;
      if (delta < intervalMs) return { allowed: false, remainingMs: intervalMs - delta };
      this.lastGlobal.set(key, this.now());
      return { allowed: true, remainingMs: 0 };
    }
  }

  async checkUser(roomId: string, userId: string, intervalMs: number) {
    const key = `rl:room:${roomId}:user:${userId}`;
    try {
      return await this.checkWithRedis(key, intervalMs);
    } catch {
      const prev = this.lastUser.get(key) || 0;
      const delta = this.now() - prev;
      if (delta < intervalMs) return { allowed: false, remainingMs: intervalMs - delta };
      this.lastUser.set(key, this.now());
      return { allowed: true, remainingMs: 0 };
    }
  }

  private async checkWithRedis(key: string, intervalMs: number) {
    const ttlSec = Math.ceil(intervalMs / 1000);
    // Use NX set to create key with TTL; if exists, compute remaining
    const client = this.redis.client;
    if (!client) throw new Error('redis not ready');
    const exists = await client.exists(key);
    if (exists) {
      const ttl = await client.ttl(key);
      const remainingMs = ttl > 0 ? ttl * 1000 : intervalMs;
      return { allowed: false, remainingMs };
    }
    await client.set(key, '1', 'EX', ttlSec);
    return { allowed: true, remainingMs: 0 };
  }
}
