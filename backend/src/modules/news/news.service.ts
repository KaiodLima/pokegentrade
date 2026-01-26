import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

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
  constructor(private readonly redis: RedisService, private readonly prisma: PrismaService) {}
  async list(): Promise<NewsItem[]> {
    const rows: any[] = await (this.prisma as any).news.findMany({ orderBy: { createdAt: 'desc' } }).catch(() => []);
    return rows.map(r => ({ id: r.id, title: r.title, content: r.content, createdAt: (r.createdAt as Date).toISOString(), authorId: r.authorId || undefined, attachments: Array.isArray(r.attachments) ? r.attachments : [] }));
  }
  async create(data: { title: string; content: string; authorId?: string; attachments?: string[] }): Promise<NewsItem> {
    const attachments = (data.attachments ?? []).filter((u) => typeof u === 'string');
    const row: any = await (this.prisma as any).news.create({ data: { title: data.title, content: data.content, authorId: data.authorId || null, attachments } });
    return { id: row.id, title: row.title, content: row.content, createdAt: (row.createdAt as Date).toISOString(), authorId: row.authorId || undefined, attachments: Array.isArray(row.attachments) ? row.attachments : [] };
  }
  async update(id: string, data: Partial<Pick<NewsItem, 'title'|'content'|'attachments'>>): Promise<NewsItem | null> {
    try {
      const row: any = await (this.prisma as any).news.update({ where: { id }, data: { title: data.title, content: data.content, attachments: data.attachments } });
      return { id: row.id, title: row.title, content: row.content, createdAt: (row.createdAt as Date).toISOString(), authorId: row.authorId || undefined, attachments: Array.isArray(row.attachments) ? row.attachments : [] };
    } catch {
      return null;
    }
  }
  async remove(id: string): Promise<{ message: string }> {
    try {
      await (this.prisma as any).news.delete({ where: { id } });
      return { message: 'deleted' };
    } catch {
      return { message: 'deleted' };
    }
  }
}
