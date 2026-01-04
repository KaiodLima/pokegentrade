import { Body, Controller, Post, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '../../common/auth.guard';
import { Client as MinioClient, PostPolicy } from 'minio';
import { RateLimitService } from '../rate-limit/rate-limit.service';
const prom = require('prom-client');
import { metricsRegistry } from '../metrics/metrics.controller';

@Controller('uploads')
export class StorageController {
  constructor(private readonly rl: RateLimitService) {}
  private readonly presignCounter = new prom.Counter({ name: 'poketibia_presign_requests_total', help: 'Presign requests', registers: [metricsRegistry] });
  private readonly presignBlockedCounter = new prom.Counter({ name: 'poketibia_presign_blocked_total', help: 'Presign blocked', labelNames: ['reason'], registers: [metricsRegistry] });
  @Post()
  @UseGuards(AuthGuard)
  async getPresigned(@Body() body: { filename: string; contentType: string }, @Req() req: any) {
    const allowed = new Set(['image/png','image/jpeg','image/gif','image/webp','application/pdf','text/plain','application/octet-stream']);
    const ct = allowed.has(body.contentType) ? body.contentType : 'application/octet-stream';
    const userId = (req.user?.sub || 'stub-user');
    const limit = await (this.rl.checkUser('uploads:presign', userId, 5_000) as any);
    if (!limit.allowed) {
      this.presignBlockedCounter.labels('rate_limit').inc();
      return { status: 'blocked', remainingMs: limit.remainingMs, scope: 'user' };
    }
    const sanitized = (body.filename || 'upload')
      .replace(/[\\\/]+/g, '_')
      .replace(/[^A-Za-z0-9._-]/g, '_')
      .slice(0, 128);
    this.presignCounter.inc();
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
      return client.bucketExists(bucket).then(exists => {
        if (!exists) return client.makeBucket(bucket, '');
      }).then(async () => {
        if ((process.env.UPLOAD_MODE || '').toLowerCase() === 'post') {
          const policy = new PostPolicy();
          policy.setBucket(bucket);
          policy.setKey(sanitized);
          policy.setExpires(new Date(Date.now() + 10 * 60 * 1000));
          policy.setContentType(ct);
          policy.setContentLengthRange(1, 5 * 1024 * 1024);
          const form = await client.presignedPostPolicy(policy);
          const postUrl = `${endpoint}/${bucket}`;
          return { method: 'POST', postUrl, fields: form, objectUrl: `${endpoint}/${bucket}/${encodeURIComponent(sanitized)}` };
        } else {
          const p = await client.presignedPutObject(bucket, sanitized, 60 * 10);
          return { uploadUrl: p, method: 'PUT', headers: { 'Content-Type': ct } };
        }
      }).catch(() => {
        const url = `${endpoint}/${bucket}/${encodeURIComponent(sanitized)}?content-type=${encodeURIComponent(ct)}&stub=true`;
        return { uploadUrl: url, method: 'PUT', headers: { 'Content-Type': ct } };
      });
    } catch {
      const endpoint = process.env.S3_ENDPOINT || 'http://localhost:9000';
      const bucket = process.env.S3_BUCKET || 'uploads';
      const url = `${endpoint}/${bucket}/${encodeURIComponent(sanitized)}?content-type=${encodeURIComponent(ct)}&stub=true`;
      return { uploadUrl: url, method: 'PUT', headers: { 'Content-Type': ct } };
    }
  }
}
