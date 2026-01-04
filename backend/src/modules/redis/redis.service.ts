import { Injectable, OnModuleInit } from '@nestjs/common';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit {
  client!: Redis | null;
  async onModuleInit() {
    const host = process.env.REDIS_HOST || 'localhost';
    const port = Number(process.env.REDIS_PORT || 6379);
    const client = new Redis({
      host,
      port,
      lazyConnect: true,
      enableOfflineQueue: false,
      maxRetriesPerRequest: 0,
      retryStrategy: () => null,
    });
    client.on('error', () => {});
    try {
      await client.connect();
      this.client = client;
    } catch {
      this.client = null;
    }
  }
  async set(key: string, value: string, ttlSeconds?: number) {
    if (!this.client) throw new Error('redis not ready');
    if (ttlSeconds) {
      await this.client.set(key, value, 'EX', ttlSeconds);
    } else {
      await this.client.set(key, value);
    }
  }
  async get(key: string) {
    if (!this.client) throw new Error('redis not ready');
    return this.client.get(key);
  }
  async incr(key: string) {
    if (!this.client) throw new Error('redis not ready');
    return this.client.incr(key);
  }
  async ttl(key: string) {
    if (!this.client) throw new Error('redis not ready');
    return this.client.ttl(key);
  }
  async sadd(key: string, member: string) {
    if (!this.client) throw new Error('redis not ready');
    await this.client.sadd(key, member);
  }
  async srem(key: string, member: string) {
    if (!this.client) throw new Error('redis not ready');
    await this.client.srem(key, member);
  }
  async smembers(key: string) {
    if (!this.client) throw new Error('redis not ready');
    return this.client.smembers(key);
  }
}
