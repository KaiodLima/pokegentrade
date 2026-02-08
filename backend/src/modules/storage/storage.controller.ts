import { Body, Controller, Post, UseGuards, Req, Get, Query, Res } from '@nestjs/common';
import { AuthGuard } from '../../common/auth.guard';
import { Client as MinioClient, PostPolicy } from 'minio';
import { RateLimitService } from '../rate-limit/rate-limit.service';
const prom = require('prom-client');
import { metricsRegistry } from '../metrics/metrics.controller';
import { Buffer } from 'buffer';
import settings from 'src/settings';

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
      const endpoint = settings.S3_ENDPOINT;
      const bucket = settings.S3_BUCKET;
      const u = new URL(endpoint);
      const client = new MinioClient({
        endPoint: u.hostname,
        port: parseInt(u.port || '80', 10),
        useSSL: u.protocol === 'https:',
        accessKey: settings.S3_ACCESS_KEY,
        secretKey: settings.S3_SECRET_KEY,
      });
      return client.bucketExists(bucket).then(exists => {
        if (!exists) return client.makeBucket(bucket, '');
      }).then(async () => {
        const mode = (settings.UPLOAD_MODE || '').toLowerCase();
        if (mode === 'proxy' || mode === 'localfs') {
          return { method: 'PROXY', endpoint: '/uploads/direct' };
        } else if (mode === 'post') {
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
        this.presignBlockedCounter.labels('storage_unavailable').inc();
        return { status: 'blocked', reason: 'storage_unavailable' };
      });
    } catch {
      this.presignBlockedCounter.labels('storage_unavailable').inc();
      return { status: 'blocked', reason: 'storage_unavailable' };
    }
  }
  @Post('direct')
  @UseGuards(AuthGuard)
  async directUpload(@Body() body: { filename: string; contentType: string; base64: string }, @Req() req: any) {
    const allowed = new Set(['image/png','image/jpeg','image/gif','image/webp','application/pdf','text/plain','application/octet-stream']);
    const ct = allowed.has(body.contentType) ? body.contentType : 'application/octet-stream';
    const sanitized = (body.filename || 'upload').replace(/[\\\/]+/g, '_').replace(/[^A-Za-z0-9._-]/g, '_').slice(0, 128);
    try {
      const buf = Buffer.from((body.base64 || ''), 'base64');
      if (buf.length === 0 || buf.length > (5 * 1024 * 1024)) return { status: 'blocked', reason: 'file_too_large' };
      const mode = settings.UPLOAD_MODE;
      if (mode === 'localfs') {
        const fs = await import('fs');
        const path = await import('path');
        const baseDir = settings.FILES_UPLOAD_DIR;
        const now = new Date();
        const sub = path.join(now.getFullYear().toString(), (now.getMonth()+1).toString().padStart(2,'0'), now.getDate().toString().padStart(2,'0'));
        const dir = path.join(baseDir, sub);
        fs.mkdirSync(dir, { recursive: true });
        const ext = (sanitized.split('.').pop() || '').toLowerCase();
        const name = `${Date.now()}-${Math.random().toString(36).slice(2)}${ext ? '.'+ext : ''}`;
        const full = path.join(dir, name);
        fs.writeFileSync(full, buf);
        const key = `files/${sub.replace(/\\\\/g,'/').replace(/\\/g,'/')}/${name}`;
        const base = `${(req.protocol || 'http')}://${(req.headers?.host || 'localhost:3000')}`;
        const objectUrl = `${base}/uploads/get?key=${encodeURIComponent(key)}`;
        return { objectUrl, contentType: ct, key };
      } else {
        const endpoint = settings.S3_ENDPOINT;
        const bucket = settings.S3_BUCKET;
        const u = new URL(endpoint);
        const client = new MinioClient({ endPoint: u.hostname, port: parseInt(u.port || '80', 10), useSSL: u.protocol === 'https:', accessKey: settings.S3_ACCESS_KEY, secretKey: settings.S3_SECRET_KEY });
        const exists = await client.bucketExists(bucket).catch(() => false);
        if (!exists) await client.makeBucket(bucket, '').catch(() => {});
        await client.putObject(bucket, sanitized, buf, { 'Content-Type': ct });
        const objectUrl = `${endpoint}/${bucket}/${encodeURIComponent(sanitized)}`;
        return { objectUrl, contentType: ct };
      }
    } catch {
      return { status: 'blocked', reason: 'storage_unavailable' };
    }
  }
  @Get('get')
  async getObject(@Query('key') key: string, @Res() res: any) {
    try {
      const normalized = decodeURIComponent(key || '').replace(/\\\\/g, '/').replace(/\\/g, '/');
      const parts = normalized.split('/').filter(Boolean);
      const mode = settings.UPLOAD_MODE;
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
      if (mode === 'localfs') {
        const fs = await import('fs');
        const path = await import('path');
        if (parts.shift() !== 'files') return res.status(400).json({ status: 'blocked', reason: 'invalid_key' });
        const baseDir = settings.FILES_UPLOAD_DIR;
        const full = path.join(baseDir, ...parts);
        if (!fs.existsSync(full)) return res.status(404).json({ status: 'blocked', reason: 'object_missing' });
        const lower = full.toLowerCase();
        const ct = lower.endsWith('.png') ? 'image/png' : (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) ? 'image/jpeg' : (lower.endsWith('.gif')) ? 'image/gif' : (lower.endsWith('.webp')) ? 'image/webp' : 'application/octet-stream';
        res.setHeader('Content-Type', ct);
        fs.createReadStream(full).pipe(res);
      } else {
        const endpoint = settings.S3_ENDPOINT;
        const u = new URL(endpoint);
        const client = new MinioClient({ endPoint: u.hostname, port: parseInt(u.port || '80', 10), useSSL: u.protocol === 'https:', accessKey: settings.S3_ACCESS_KEY, secretKey: settings.S3_SECRET_KEY });
        const bucket = parts.shift() || settings.S3_BUCKET;
        const object = decodeURIComponent(parts.join('/'));
        const st = await client.statObject(bucket, object).catch(() => null as any);
        if (!st) return res.status(404).json({ status: 'blocked', reason: 'object_missing' });
        const ct = ((st as any).contentType || (st as any).metaData?.['content-type'] || '').toString() || 'application/octet-stream';
        res.setHeader('Content-Type', ct);
        const stream = await client.getObject(bucket, object);
        stream.on('error', () => res.end());
        stream.pipe(res);
      }
    } catch {
      res.status(500).json({ status: 'blocked', reason: 'storage_unavailable' });
    }
  }
}
