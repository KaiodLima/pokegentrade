import { Body, Controller, Get, Param, Patch, Post, UseGuards, Req, Delete, NotFoundException, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { IsString, IsOptional, IsNumber, MinLength, IsIn, Min } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';
import { AuthGuard } from '../../common/auth.guard';
import { RoleGuard } from '../../common/role.guard';
import { RateLimitService } from '../rate-limit/rate-limit.service';
import { Client as MinioClient } from 'minio';
import { Counter } from 'prom-client';
import { metricsRegistry } from '../metrics/metrics.controller';

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
}

class UpdateAdDto {
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
  @IsString()
  @IsIn(['pendente','aprovado','concluido'])
  status!: string;
}

@Controller('marketplace/ads')
export class MarketplaceController {
  constructor(private readonly prisma: PrismaService, private readonly rl: RateLimitService) {}
  private readonly attachmentBlockedCounter = new Counter({ name: 'poketibia_attachment_blocked_total', help: 'Attachment blocked', labelNames: ['reason'], registers: [metricsRegistry] });

  @Get()
  list() {
    return this.prisma.ad.findMany({ where: { status: 'aprovado' }, orderBy: { createdAt: 'desc' }, include: { attachments: true } }).catch(() => []);
  }
  @Get('admin')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  adminList() {
    return this.prisma.ad.findMany({ orderBy: { createdAt: 'desc' }, include: { attachments: true } }).catch(() => []);
  }
  @Get(':id')
  detail(@Param('id') id: string) {
    return this.prisma.ad.findUnique({ where: { id }, include: { attachments: true } }).then((row) => {
      if (!row) throw new NotFoundException('ad_not_found');
      return row;
    }).catch((e) => { throw e instanceof NotFoundException ? e : new InternalServerErrorException('detail_failed'); });
  }

  @Post()
  @UseGuards(AuthGuard)
  async create(@Body() body: CreateAdDto, @Req() req: any) {
    const userId = (req.user?.sub || 'stub-user');
    const r = await (this.rl.checkUser('marketplace:create', userId, 30_000) as any);
    if (!r.allowed) return { status: 'blocked', remainingMs: r.remainingMs, scope: 'user' };
    try {
      return await this.prisma.ad.create({
        data: { type: body.type, title: body.title, description: body.description, price: body.price, authorId: userId },
      });
    } catch {
      throw new InternalServerErrorException('create_failed');
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
      throw new InternalServerErrorException('approve_failed');
    }
  }

  @Patch(':id/complete')
  @UseGuards(AuthGuard)
  async complete(@Param('id') id: string) {
    try {
      const ad = await this.prisma.ad.findUnique({ where: { id } });
      if (!ad) throw new NotFoundException('ad_not_found');
      return await this.prisma.ad.update({ where: { id }, data: { status: 'concluido' } });
    } catch (e) {
      throw e instanceof NotFoundException ? e : new InternalServerErrorException('complete_failed');
    }
  }
  @Patch(':id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async update(@Param('id') id: string, @Body() body: UpdateAdDto) {
    try {
      return await this.prisma.ad.update({
        where: { id },
        data: { type: body.type, title: body.title, description: body.description, price: body.price, status: body.status },
      });
    } catch (e) {
      throw new InternalServerErrorException('update_failed');
    }
  }
  @Delete(':id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async remove(@Param('id') id: string) {
    try {
      await this.prisma.ad.delete({ where: { id } });
      return { message: 'deleted' };
    } catch (e) {
      throw new InternalServerErrorException('delete_failed');
    }
  }

  @Post(':id/attachments')
  @UseGuards(AuthGuard)
  async attach(@Param('id') id: string, @Body() body: { url: string; type: string; meta?: any }) {
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
      const endpoint = process.env.S3_ENDPOINT || 'http://localhost:9000';
      const u = new URL(body.url || '');
      const eu = new URL(endpoint);
      const pathParts = (u.pathname || '').split('/').filter(Boolean);
      const bucket = pathParts[0] || (process.env.S3_BUCKET || 'uploads');
      const object = decodeURIComponent(pathParts.slice(1).join('/'));
      const client = new MinioClient({
        endPoint: eu.hostname,
        port: parseInt(eu.port || '80', 10),
        useSSL: eu.protocol === 'https:',
        accessKey: process.env.S3_ACCESS_KEY || '',
        secretKey: process.env.S3_SECRET_KEY || '',
      });
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
        try {
          await client.removeObject(bucket, object);
        } catch {}
        return { status: 'blocked', reason: 'file_too_large', maxBytes: max, size: st.size };
      }
    } catch {}
    try {
      return await this.prisma.adAttachment.create({ data: { adId: id, url: body.url, type: body.type, meta: body.meta || {} } });
    } catch {
      throw new InternalServerErrorException('attach_failed');
    }
  }
}
