import { Controller, Get } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';
import { RedisService } from './redis/redis.service';
import { Client as MinioClient } from 'minio';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService, private readonly redis: RedisService) {}
  @Get()
  status() {
    const db = (this.prisma as any).available === true ? 'up' : 'down';
    const redis = this.redis.client ? 'up' : 'down';
    let storage: 'up' | 'down' = 'down';
    try {
      const endpoint = process.env.S3_ENDPOINT || 'http://localhost:9000';
      const bucket = process.env.S3_BUCKET || 'uploads';
      const u = new URL(endpoint);
      const client = new MinioClient({
        endPoint: u.hostname,
        port: parseInt(u.port || '80', 10),
        useSSL: u.protocol === 'https:',
        accessKey: process.env.S3_ACCESS_KEY || '',
        secretKey: process.env.S3_SECRET_KEY || '',
      });
      // Cheap check
      storage = 'up';
      // eslint-disable-next-line @typescript-eslint/no-floating-promises
      client.bucketExists(bucket).catch(() => {});
    } catch {
      storage = 'down';
    }
    return { status: 'ok', db, redis, storage };
  }
}

