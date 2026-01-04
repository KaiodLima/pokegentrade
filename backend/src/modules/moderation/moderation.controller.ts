import { Body, Controller, Post, UseGuards, Get, Req } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthGuard } from '../../common/auth.guard';
import { RoleGuard } from '../../common/role.guard';

@Controller('moderation')
export class ModerationController {
  constructor(private readonly prisma: PrismaService) {}

  @Post('users/mute')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async muteUser(@Body() body: { userId: string; scope?: 'global' | 'room'; roomId?: string; motivo?: string }) {
    const acao = body.scope === 'room' ? `mute_room_${body.roomId}` : 'mute_global';
    await this.prisma.moderationAction.create({
      data: { adminId: 'admin-stub', alvoTipo: 'user', alvoId: body.userId, acao, motivo: body.motivo },
    });
    if (body.scope !== 'room') {
      await this.prisma.user.update({ where: { id: body.userId }, data: { status: 'silenciada' } });
    }
    return { status: 'ok' };
  }

  @Post('users/suspend')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async suspendUser(@Body() body: { userId: string; motivo?: string }) {
    await this.prisma.moderationAction.create({
      data: { adminId: 'admin-stub', alvoTipo: 'user', alvoId: body.userId, acao: 'suspend', motivo: body.motivo },
    });
    await this.prisma.user.update({ where: { id: body.userId }, data: { status: 'suspensa' } });
    return { status: 'ok' };
  }
  @Get('actions')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async listActions(@Body() _unused: any, @Req() req: any) {
    const q = req.query || {};
    const limit = Math.max(1, Math.min(200, parseInt((q.limit || '50').toString(), 10)));
    const offset = Math.max(0, parseInt((q.offset || '0').toString(), 10));
    const adminId = (q.adminId || '').toString();
    const alvoId = (q.alvoId || '').toString();
    const acao = (q.acao || '').toString();
    const where: any = {};
    if (adminId) where.adminId = adminId;
    if (alvoId) where.alvoId = alvoId;
    if (acao) where.acao = acao;
    try {
      const rows: any[] = await (this.prisma as any).moderationAction.findMany({ where, orderBy: { createdAt: 'desc' }, take: limit, skip: offset });
      return rows.map(a => ({
        id: a.id,
        adminId: a.adminId,
        alvoTipo: a.alvoTipo,
        alvoId: a.alvoId,
        acao: a.acao,
        motivo: a.motivo || '',
        createdAt: (a as any).createdAt ? ((a as any).createdAt as Date).toISOString() : new Date().toISOString(),
      }));
    } catch {
      return [];
    }
  }
}
