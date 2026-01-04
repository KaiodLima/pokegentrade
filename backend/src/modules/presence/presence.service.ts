import { Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';

@Injectable()
export class PresenceService {
  constructor(private readonly redis: RedisService) {}
  private online: Set<string> = new Set();
  private key = 'presence:online';
  async add(userId: string) {
    if (!userId) return;
    if (this.redis.client) {
      try { await this.redis.sadd(this.key, userId); return; } catch {}
    }
    this.online.add(userId);
  }
  async remove(userId: string) {
    if (!userId) return;
    if (this.redis.client) {
      try { await this.redis.srem(this.key, userId); return; } catch {}
    }
    this.online.delete(userId);
  }
  async list() {
    if (this.redis.client) {
      try { return await this.redis.smembers(this.key); } catch {}
    }
    return Array.from(this.online.values());
  }
}
