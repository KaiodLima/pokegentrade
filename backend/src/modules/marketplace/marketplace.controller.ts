import { Body, Controller, Get, Param, Patch, Post, UseGuards, Req, Delete, NotFoundException, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { IsString, IsOptional, IsNumber, MinLength, IsIn, Min } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';
import { AuthGuard } from '../../common/auth.guard';
import { RoleGuard } from '../../common/role.guard';
import { RateLimitService } from '../rate-limit/rate-limit.service';
import { Client as MinioClient } from 'minio';
import { Counter } from 'prom-client';
import { metricsRegistry } from '../metrics/metrics.controller';
import { randomUUID } from 'crypto';
import settings from 'src/settings';

class CreateAdDto {
  @IsString()
  @IsIn(['venda','compra','troca'])
  type!: string;
  @IsString()
  @MinLength(1)
  title!: string;
  @IsString()
  @MinLength(1)
  description!: string;
  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;
  @IsOptional()
  @IsString()
  authorId?: string;
  @IsOptional()
  @IsString()
  categoryId?: string;
  @IsOptional()
  @IsString()
  serverId?: string;
}

class UpdateAdDto {
  @IsOptional()
  @IsString()
  @IsIn(['venda','compra','troca'])
  type?: string;
  @IsOptional()
  @IsString()
  @MinLength(1)
  title?: string;
  @IsOptional()
  @IsString()
  @MinLength(1)
  description?: string;
  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;
  @IsOptional()
  @IsString()
  @IsIn(['pendente','aprovado','concluido','pausado'])
  status?: string;
  @IsOptional()
  @IsString()
  categoryId?: string;
  @IsOptional()
  @IsString()
  serverId?: string;
}

@Controller('marketplace/ads')
export class MarketplaceController {
  constructor(private readonly prisma: PrismaService, private readonly rl: RateLimitService) {}
  private readonly attachmentBlockedCounter = new Counter({ name: 'poketibia_attachment_blocked_total', help: 'Attachment blocked', labelNames: ['reason'], registers: [metricsRegistry] });
  private memAds: any[] = [];
  private isAdmin(req: any): boolean {
    const role = (req?.user?.role || '').toString();
    return role === 'Admin' || role === 'SuperAdmin';
  }

  @Get()
  list(@Req() req: any) {
    const toPublic = (url: string) => {
      try {
        const endpoint = settings.S3_ENDPOINT;
        const u = new URL(url);
        const e = new URL(endpoint);
        if (u.hostname === e.hostname && u.port === e.port) {
          const key = (u.pathname || '').replace(/^\/+/, '');
          const base = `${(req.protocol || 'http')}://${(req.headers?.host || 'localhost:3000')}`;
          return `${base}/uploads/get?key=${encodeURIComponent(key)}`;
        }
      } catch {}
      return url;
    };
    return this.prisma.ad.findMany({ where: { status: 'aprovado' }, orderBy: [{ featured: 'desc' }, { createdAt: 'desc' }], include: { attachments: true, category: true, server: true } }).then(rows => {
      return rows.map(r => ({ ...r, attachments: Array.isArray((r as any).attachments) ? (r as any).attachments.map((att: any) => ({ ...att, url: toPublic((att?.url || '').toString()) })) : [] }));
    }).catch(() => {
      return this.memAds.filter(a => (a.status || 'pendente') === 'aprovado').map(r => ({
        ...r,
        attachments: Array.isArray((r as any).attachments) ? (r as any).attachments.map((att: any) => ({ ...att, url: toPublic((att?.url || '').toString()) })) : []
      })).sort((a, b) => {
        const fa = a.featured ? 1 : 0;
        const fb = b.featured ? 1 : 0;
        if (fb !== fa) return fb - fa;
        return (new Date(b.createdAt || new Date()).getTime() - new Date(a.createdAt || new Date()).getTime());
      });
    });
  }
  @Get('admin')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  adminList(@Req() req: any) {
    const toPublic = (url: string) => {
      try {
        const endpoint = settings.S3_ENDPOINT;
        const u = new URL(url);
        const e = new URL(endpoint);
        if (u.hostname === e.hostname && u.port === e.port) {
          const key = (u.pathname || '').replace(/^\/+/, '');
          const base = `${(req.protocol || 'http')}://${(req.headers?.host || 'localhost:3000')}`;
          return `${base}/uploads/get?key=${encodeURIComponent(key)}`;
        }
      } catch {}
      return url;
    };
    return this.prisma.ad.findMany({ orderBy: { createdAt: 'desc' }, include: { attachments: true, category: true, server: true } }).then(rows => {
      return rows.map(r => ({ ...r, attachments: Array.isArray((r as any).attachments) ? (r as any).attachments.map((att: any) => ({ ...att, url: toPublic((att?.url || '').toString()) })) : [] }));
    }).catch(() => {
      return this.memAds.map(r => ({
        ...r,
        attachments: Array.isArray((r as any).attachments) ? (r as any).attachments.map((att: any) => ({ ...att, url: toPublic((att?.url || '').toString()) })) : []
      })).sort((a, b) => (new Date(b.createdAt || new Date()).getTime() - new Date(a.createdAt || new Date()).getTime()));
    });
  }
  @Get('mine')
  @UseGuards(AuthGuard)
  async mine(@Req() req: any) {
    const userId = (req.user?.sub || '');
    try {
      const rows = await this.prisma.ad.findMany({ where: { authorId: userId }, orderBy: { createdAt: 'desc' }, include: { attachments: true, category: true, server: true } });
      const endpoint = settings.S3_ENDPOINT;
      const e = new URL(endpoint);
      const toPublic = (url: string) => {
        try {
          const u = new URL(url);
          if (u.hostname === e.hostname && u.port === e.port) {
            const key = (u.pathname || '').replace(/^\/+/, '');
            const base = `${(req.protocol || 'http')}://${(req.headers?.host || 'localhost:3000')}`;
            return `${base}/uploads/get?key=${encodeURIComponent(key)}`;
          }
        } catch {}
        return url;
      };
      return rows.map(r => ({ ...r, attachments: Array.isArray((r as any).attachments) ? (r as any).attachments.map((att: any) => ({ ...att, url: toPublic((att?.url || '').toString()) })) : [] }));
    } catch {
      const endpoint = settings.S3_ENDPOINT;
      const e = new URL(endpoint);
      const toPublic = (url: string) => {
        try {
          const u = new URL(url);
          if (u.hostname === e.hostname && u.port === e.port) {
            const key = (u.pathname || '').replace(/^\/+/, '');
            const base = `${(req.protocol || 'http')}://${(req.headers?.host || 'localhost:3000')}`;
            return `${base}/uploads/get?key=${encodeURIComponent(key)}`;
          }
        } catch {}
        return url;
      };
      return this.memAds.filter(a => (a.authorId || '') === userId).map(r => ({
        ...r,
        attachments: Array.isArray((r as any).attachments) ? (r as any).attachments.map((att: any) => ({ ...att, url: toPublic((att?.url || '').toString()) })) : []
      })).sort((a, b) => (new Date(b.createdAt || new Date()).getTime() - new Date(a.createdAt || new Date()).getTime()));
    }
  }
  @Get(':id')
  detail(@Param('id') id: string, @Req() req: any) {
    const toPublic = (url: string) => {
      try {
        const endpoint = settings.S3_ENDPOINT;
        const u = new URL(url);
        const e = new URL(endpoint);
        if (u.hostname === e.hostname && u.port === e.port) {
          const key = (u.pathname || '').replace(/^\/+/, '');
          const base = `${(req.protocol || 'http')}://${(req.headers?.host || 'localhost:3000')}`;
          return `${base}/uploads/get?key=${encodeURIComponent(key)}`;
        }
      } catch {}
      return url;
    };
    return this.prisma.ad.findUnique({ where: { id }, include: { attachments: { orderBy: { sortOrder: 'asc' } }, category: true, server: true } }).then((row: any) => {
      if (!row) throw new NotFoundException('ad_not_found');
      if (Array.isArray((row as any).attachments)) {
        (row as any).attachments = (row as any).attachments.map((att: any) => ({ ...att, url: toPublic((att?.url || '').toString()) }));
      }
      return row;
    }).catch((e: any) => {
      const mem = this.memAds.find(a => a.id === id);
      if (mem) {
        mem.attachments = Array.isArray((mem as any).attachments) ? (mem as any).attachments.map((att: any) => ({ ...att, url: toPublic((att?.url || '').toString()) })) : [];
        return mem;
      }
      throw e instanceof NotFoundException ? e : new InternalServerErrorException('detail_failed');
    });
  }

  @Post()
  @UseGuards(AuthGuard)
  async create(@Body() body: CreateAdDto, @Req() req: any) {
    const userId = (req.user?.sub || '');
    if (!userId) throw new BadRequestException('invalid_author');
    const r = await (this.rl.checkUser('marketplace:create', userId, 30_000) as any);
    if (!r.allowed) return { status: 'blocked', remainingMs: r.remainingMs, scope: 'user' };
    try {
      const authorId = this.isAdmin(req) && typeof body.authorId === 'string' && body.authorId ? body.authorId : userId;
      const role = (req.user?.role || '').toString();
      const initialStatus = role === 'SuperAdmin' ? 'aprovado' : 'pendente';
      return await this.prisma.ad.create({
        data: { type: body.type, title: body.title, description: body.description, price: body.price, authorId, status: initialStatus, categoryId: body.categoryId || null, serverId: body.serverId || null },
      });
    } catch {
      const authorId = this.isAdmin(req) && typeof body.authorId === 'string' && body.authorId ? body.authorId : userId;
      const role = (req.user?.role || '').toString();
      const initialStatus = role === 'SuperAdmin' ? 'aprovado' : 'pendente';
      const ad = { id: randomUUID(), authorId, type: body.type, title: body.title, description: body.description, price: body.price ?? null, status: initialStatus, createdAt: new Date(), attachments: [] as any[], categoryId: body.categoryId || null, serverId: body.serverId || null };
      this.memAds.push(ad);
      return ad;
    }
  }

  @Patch(':id/approve')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async approve(@Param('id') id: string, @Req() req: any) {
    const adminId = (req.user?.sub || null) as string | null;
    const ad = await this.prisma.ad.findUnique({ where: { id } });
    if (!ad) throw new NotFoundException('ad_not_found');
    if ((ad.status || 'pendente') !== 'pendente') throw new BadRequestException('invalid_state');
    try {
      return await this.prisma.ad.update({ where: { id }, data: { status: 'aprovado', approvedBy: adminId } });
    } catch (e) {
      const mem = this.memAds.find(a => a.id === id);
      if (mem) {
        mem.status = 'aprovado';
        mem.approvedBy = adminId || undefined;
        return mem;
      }
      throw new InternalServerErrorException('approve_failed');
    }
  }

  @Patch(':id/complete')
  @UseGuards(AuthGuard)
  async complete(@Param('id') id: string, @Req() req: any) {
    try {
      const ad = await this.prisma.ad.findUnique({ where: { id } });
      if (!ad) throw new NotFoundException('ad_not_found');
      const isOwner = (req.user?.sub || '') === (ad.authorId || '');
      if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
      return await this.prisma.ad.update({ where: { id }, data: { status: 'concluido' } });
    } catch (e) {
      const mem = this.memAds.find(a => a.id === id);
      if (mem) {
        const isOwner = (req.user?.sub || '') === (mem.authorId || '');
        if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
        mem.status = 'concluido';
        return mem;
      }
      throw e instanceof NotFoundException ? e : new InternalServerErrorException('complete_failed');
    }
  }
  @Patch(':id')
  @UseGuards(AuthGuard)
  async update(@Param('id') id: string, @Body() body: UpdateAdDto, @Req() req: any) {
    try {
      const ad = await this.prisma.ad.findUnique({ where: { id } });
      if (!ad) throw new NotFoundException('ad_not_found');
      const isOwner = (req.user?.sub || '') === (ad.authorId || '');
      if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
      return await this.prisma.ad.update({ where: { id }, data: { type: body.type ?? ad.type, title: body.title ?? ad.title, description: body.description ?? ad.description, price: body.price ?? ad.price, status: body.status ?? ad.status, categoryId: body.categoryId ?? ad.categoryId, serverId: body.serverId ?? ad.serverId } });
    } catch (e) {
      const idx = this.memAds.findIndex(a => a.id === id);
      if (idx >= 0) {
        const current = this.memAds[idx];
        const isOwner = (req.user?.sub || '') === (current.authorId || '');
        if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
        this.memAds[idx] = { ...current, type: body.type ?? current.type, title: body.title ?? current.title, description: body.description ?? current.description, price: (body.price ?? current.price ?? null), status: body.status ?? current.status, categoryId: body.categoryId ?? current.categoryId ?? null, serverId: body.serverId ?? current.serverId ?? null, featured: (typeof (body as any).featured === 'boolean' ? (body as any).featured : current.featured) };
        return this.memAds[idx];
      }
      throw new InternalServerErrorException('update_failed');
    }
  }
  @Patch(':id/feature')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async feature(@Param('id') id: string, @Body() body: { featured: boolean }) {
    try {
      const f = !!(body?.featured);
      return await this.prisma.ad.update({ where: { id }, data: { featured: f } });
    } catch (e) {
      const idx = this.memAds.findIndex(a => a.id === id);
      if (idx >= 0) {
        this.memAds[idx].featured = !!(body?.featured);
        return this.memAds[idx];
      }
      throw new InternalServerErrorException('feature_failed');
    }
  }
  @Delete(':id')
  @UseGuards(AuthGuard)
  async remove(@Param('id') id: string, @Req() req: any) {
    try {
      const ad = await this.prisma.ad.findUnique({ where: { id } });
      if (!ad) throw new NotFoundException('ad_not_found');
      const isOwner = (req.user?.sub || '') === (ad.authorId || '');
      if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
      await this.prisma.ad.delete({ where: { id } });
      return { message: 'deleted' };
    } catch (e) {
      const idx = this.memAds.findIndex(a => a.id === id);
      if (idx >= 0) {
        const current = this.memAds[idx];
        const isOwner = (req.user?.sub || '') === (current.authorId || '');
        if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
        this.memAds.splice(idx, 1);
        return { message: 'deleted' };
      }
      throw new InternalServerErrorException('delete_failed');
    }
  }
  @Get('categories')
  async listCategories() {
    return await this.prisma.category.findMany({ orderBy: { name: 'asc' } }).catch(() => []);
  }
  @Post('categories')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async createCategory(@Body() body: { name: string }) {
    const name = (body?.name || '').toString().trim();
    if (!name) throw new BadRequestException('invalid_name');
    try {
      return await this.prisma.category.create({ data: { name } });
    } catch {
      throw new InternalServerErrorException('category_create_failed');
    }
  }
  @Delete('categories/:id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async deleteCategory(@Param('id') id: string) {
    try { await this.prisma.category.delete({ where: { id } }); return { message: 'deleted' }; } catch { throw new InternalServerErrorException('category_delete_failed'); }
  }
  @Get('servers')
  async listServers() {
    return await this.prisma.server.findMany({ orderBy: { name: 'asc' } }).catch(() => []);
  }
  @Post('servers')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async createServer(@Body() body: { name: string }) {
    const name = (body?.name || '').toString().trim();
    if (!name) throw new BadRequestException('invalid_name');
    try {
      return await this.prisma.server.create({ data: { name } });
    } catch {
      throw new InternalServerErrorException('server_create_failed');
    }
  }
  @Delete('servers/:id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async deleteServer(@Param('id') id: string) {
    try { await this.prisma.server.delete({ where: { id } }); return { message: 'deleted' }; } catch { throw new InternalServerErrorException('server_delete_failed'); }
  }
  @Patch(':id/pause')
  @UseGuards(AuthGuard)
  async pause(@Param('id') id: string, @Req() req: any) {
    try {
      const ad = await this.prisma.ad.findUnique({ where: { id } });
      if (!ad) throw new NotFoundException('ad_not_found');
      const isOwner = (req.user?.sub || '') === (ad.authorId || '');
      if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
      return await this.prisma.ad.update({ where: { id }, data: { status: 'pausado' } });
    } catch {
      const mem = this.memAds.find(a => a.id === id);
      if (mem) {
        const isOwner = (req.user?.sub || '') === (mem.authorId || '');
        if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
        mem.status = 'pausado';
        return mem;
      }
      throw new InternalServerErrorException('pause_failed');
    }
  }
  @Patch(':id/resume')
  @UseGuards(AuthGuard)
  async resume(@Param('id') id: string, @Req() req: any) {
    try {
      const ad = await this.prisma.ad.findUnique({ where: { id } });
      if (!ad) throw new NotFoundException('ad_not_found');
      const isOwner = (req.user?.sub || '') === (ad.authorId || '');
      if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
      if ((ad.status || '') !== 'pausado') throw new BadRequestException('invalid_state');
      return await this.prisma.ad.update({ where: { id }, data: { status: 'aprovado' } });
    } catch (e) {
      const mem = this.memAds.find(a => a.id === id);
      if (mem) {
        const isOwner = (req.user?.sub || '') === (mem.authorId || '');
        if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
        if ((mem.status || '') !== 'pausado') throw new BadRequestException('invalid_state');
        mem.status = 'aprovado';
        return mem;
      }
      throw new InternalServerErrorException('resume_failed');
    }
  }

  @Post(':id/attachments')
  @UseGuards(AuthGuard)
  async attach(@Param('id') id: string, @Body() body: { url: string; type: string; meta?: any }, @Req() req: any) {
    let ad: any = await this.prisma.ad.findUnique({ where: { id } }).catch(() => null as any);
    let memAd: any = null;
    if (!ad) {
      memAd = this.memAds.find(a => a.id === id);
      if (!memAd) throw new NotFoundException('ad_not_found');
    }
    const role = (req.user?.role || '').toString();
    const isAdmin = role === 'Admin' || role === 'SuperAdmin';
    const userId = (req.user?.sub || '');
    const ownerId = (ad ? (ad.authorId || '') : (memAd?.authorId || ''));
    if (!isAdmin && userId !== ownerId) {
      return { status: 'blocked', reason: 'forbidden' };
    }
    const allowed = new Set(['image/png','image/jpeg','image/gif','image/webp','application/pdf','text/plain','application/octet-stream']);
    if (!allowed.has(body.type)) {
      this.attachmentBlockedCounter.labels('invalid_content_type').inc();
      return { status: 'blocked', reason: 'invalid_content_type' };
    }
    const max = 5 * 1024 * 1024;
    const size = typeof body.meta?.size === 'number' ? body.meta.size : 0;
    if (size > max) {
      this.attachmentBlockedCounter.labels('file_too_large').inc();
      return { status: 'blocked', reason: 'file_too_large', maxBytes: max, size };
    }
    try {
      const mode = settings.UPLOAD_MODE;
      const u = new URL(body.url || '');
      if (mode === 'localfs' && u.pathname.startsWith('/uploads/get')) {
        const fs = await import('fs');
        const path = await import('path');
        const key = (u.searchParams.get('key') || '').toString();
        const parts = key.split('/').filter(Boolean);
        if (parts.shift() !== 'files') {
          this.attachmentBlockedCounter.labels('object_missing').inc();
          return { status: 'blocked', reason: 'object_missing' };
        }
        const baseDir = settings.FILES_UPLOAD_DIR;
        const full = path.join(baseDir, ...parts);
        if (!fs.existsSync(full)) {
          this.attachmentBlockedCounter.labels('object_missing').inc();
          return { status: 'blocked', reason: 'object_missing' };
        }
        const stat = fs.statSync(full);
        if (stat.size > max) {
          this.attachmentBlockedCounter.labels('file_too_large').inc();
          return { status: 'blocked', reason: 'file_too_large', maxBytes: max, size: stat.size };
        }
      } else {
        const endpoint = settings.S3_ENDPOINT;
        const eu = new URL(endpoint);
        const pathParts = (u.pathname || '').split('/').filter(Boolean);
        const bucket = pathParts[0] || (settings.S3_BUCKET || 'uploads');
        const object = decodeURIComponent(pathParts.slice(1).join('/'));
        const client = new MinioClient({ endPoint: eu.hostname, port: parseInt(eu.port || '80', 10), useSSL: eu.protocol === 'https:', accessKey: settings.S3_ACCESS_KEY || '', secretKey: settings.S3_SECRET_KEY || '' });
        const st = await client.statObject(bucket, object).catch(() => null as any);
        if (!st || typeof st.size !== 'number') {
          this.attachmentBlockedCounter.labels('object_missing').inc();
          return { status: 'blocked', reason: 'object_missing' };
        }
        const actualCt = ((st as any).contentType || (st as any).metaData?.['content-type'] || (st as any).metaData?.contentType || '').toString();
        if (actualCt && actualCt !== body.type) {
          this.attachmentBlockedCounter.labels('content_type_mismatch').inc();
          return { status: 'blocked', reason: 'content_type_mismatch', expected: body.type, actual: actualCt };
        }
        if (st.size > max) {
          this.attachmentBlockedCounter.labels('file_too_large').inc();
          try { await client.removeObject(bucket, object); } catch {}
          return { status: 'blocked', reason: 'file_too_large', maxBytes: max, size: st.size };
        }
      }
    } catch {}
    if (ad) {
      try {
        const count = await this.prisma.adAttachment.count({ where: { adId: id, type: { startsWith: 'image/' } } });
        const row: any = await this.prisma.adAttachment.create({ data: { adId: id, url: body.url, type: body.type, meta: body.meta || {}, isCover: count === 0 && body.type.startsWith('image/'), sortOrder: count } });
        return row;
      } catch {
        // fallback to memory if DB write fails
        memAd = this.memAds.find(a => a.id === id);
      }
    }
    if (memAd) {
      const existingImages = Array.isArray(memAd.attachments) ? memAd.attachments.filter((x: any) => (x?.type || '').toString().startsWith('image/')) : [];
      const att = { id: randomUUID(), adId: id, url: body.url, type: body.type, meta: body.meta || {}, isCover: (existingImages.length === 0) && body.type.startsWith('image/'), sortOrder: existingImages.length };
      memAd.attachments = Array.isArray(memAd.attachments) ? memAd.attachments : [];
      memAd.attachments.push(att);
      return att as any;
    }
    throw new InternalServerErrorException('attach_failed');
  }
  @Patch(':id/attachments/:attId/cover')
  @UseGuards(AuthGuard)
  async setCover(@Param('id') id: string, @Param('attId') attId: string, @Req() req: any) {
    const ad = await this.prisma.ad.findUnique({ where: { id } }).catch(() => null as any);
    if (!ad) throw new NotFoundException('ad_not_found');
    const isOwner = (req.user?.sub || '') === (ad.authorId || '');
    if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
    await this.prisma.adAttachment.updateMany({ where: { adId: id }, data: { isCover: false } }).catch(() => {});
    return await this.prisma.adAttachment.update({ where: { id: attId }, data: { isCover: true } }).catch(() => {
      throw new InternalServerErrorException('cover_failed');
    });
  }
  @Delete(':id/attachments/:attId')
  @UseGuards(AuthGuard)
  async removeAttachment(@Param('id') id: string, @Param('attId') attId: string, @Req() req: any) {
    const ad = await this.prisma.ad.findUnique({ where: { id } }).catch(() => null as any);
    if (!ad) throw new NotFoundException('ad_not_found');
    const isOwner = (req.user?.sub || '') === (ad.authorId || '');
    if (!this.isAdmin(req) && !isOwner) return { status: 'blocked', reason: 'forbidden' };
    const att = await this.prisma.adAttachment.findUnique({ where: { id: attId } }).catch(() => null as any);
    if (!att || att.adId !== id) throw new NotFoundException('attachment_not_found');
    await this.prisma.adAttachment.delete({ where: { id: attId } }).catch(() => { throw new InternalServerErrorException('delete_failed'); });
    const hasCover = await this.prisma.adAttachment.count({ where: { adId: id, isCover: true } });
    if (hasCover === 0) {
      const first = await this.prisma.adAttachment.findFirst({ where: { adId: id, type: { startsWith: 'image/' } }, orderBy: { sortOrder: 'asc' } }).catch(() => null as any);
      if (first) await this.prisma.adAttachment.update({ where: { id: first.id }, data: { isCover: true } }).catch(() => {});
    }
    return { message: 'deleted' };
  }
}
