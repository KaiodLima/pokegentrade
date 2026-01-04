import { Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import { PrismaService } from '../prisma/prisma.service';
import { randomUUID } from 'crypto';

export interface NewsItem {
  id: string;
  title: string;
  content: string;
  createdAt: string;
  authorId?: string;
  attachments: string[];
}

@Injectable()
export class NewsService {
  private mem: Map<string, NewsItem> = new Map();
  constructor(private readonly redis: RedisService, private readonly prisma: PrismaService) {}
  async list(): Promise<NewsItem[]> {
    const out: NewsItem[] = [];
    if (this.redis.client) {
      try {
        const ids = await this.redis.smembers('news:ids');
        for (const id of ids) {
          const raw = await this.redis.get(`news:item:${id}`);
          if (raw) {
            try { out.push(JSON.parse(raw)); } catch {}
          }
        }
        out.sort((a, b) => (b.createdAt.localeCompare(a.createdAt)));
        return out;
      } catch {}
    }
    return Array.from(this.mem.values()).sort((a, b) => (b.createdAt.localeCompare(a.createdAt)));
  }
  async create(data: { title: string; content: string; authorId?: string; attachments?: string[] }): Promise<NewsItem> {
    const id = randomUUID();
    const item: NewsItem = { id, title: data.title, content: data.content, authorId: data.authorId, createdAt: new Date().toISOString(), attachments: (data.attachments ?? []).filter((u) => typeof u === 'string') };
    if (this.redis.client) {
      try {
        await this.redis.sadd('news:ids', id);
        await this.redis.set(`news:item:${id}`, JSON.stringify(item));
        return item;
      } catch {}
    }
    this.mem.set(id, item);
    return item;
  }
  async update(id: string, data: Partial<Pick<NewsItem, 'title'|'content'|'attachments'>>): Promise<NewsItem | null> {
    if (this.redis.client) {
      try {
        const raw = await this.redis.get(`news:item:${id}`);
        if (!raw) return null;
        const item: NewsItem = JSON.parse(raw);
        const updated: NewsItem = { ...item, title: (data.title ?? item.title), content: (data.content ?? item.content), attachments: (data.attachments ?? item.attachments ?? []) };
        await this.redis.set(`news:item:${id}`, JSON.stringify(updated));
        return updated;
      } catch {}
    }
    const current = this.mem.get(id);
    if (!current) return null;
    const updated: NewsItem = { ...current, title: (data.title ?? current.title), content: (data.content ?? current.content), attachments: (data.attachments ?? current.attachments ?? []) };
    this.mem.set(id, updated);
    return updated;
  }
  async remove(id: string): Promise<{ message: string }> {
    if (this.redis.client) {
      try {
        await this.redis.srem('news:ids', id);
        await this.redis.set(`news:item:${id}`, '');
        return { message: 'deleted' };
      } catch {}
    }
    this.mem.delete(id);
    return { message: 'deleted' };
  }
}
