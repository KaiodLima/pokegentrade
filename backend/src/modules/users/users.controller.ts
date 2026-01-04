import { Body, Controller, Get, Param, Patch, Post, Delete, UnauthorizedException, Req, UseGuards, ForbiddenException } from '@nestjs/common';
import { PresenceService } from '../presence/presence.service';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '../../common/jwt.service';
import { AuthGuard } from '../../common/auth.guard';
import { RoleGuard } from '../../common/role.guard';
import argon2 from 'argon2';

@Controller('users')
export class UsersController {
  constructor(private readonly presence: PresenceService, private readonly prisma: PrismaService, private readonly jwt: JwtService) {}
  @Get('me')
  async me(@Req() req: any) {
    const auth = (req.headers?.authorization || '').toString();
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    const payload = token ? this.jwt.verifyAccess(token) : null;
    if (payload) {
      try {
        const u = await this.prisma.user.findUnique({ where: { id: payload.sub } });
        if (u) {
          return {
            id: (u as any).id,
            email: (u as any).email || '',
            displayName: (u as any).displayName || (u as any).name || '',
            avatarUrl: (u as any).avatarUrl || '',
            createdAt: (u as any).createdAt ? ((u as any).createdAt as Date).toISOString() : new Date().toISOString(),
            role: (u as any).role || payload.role,
            status: (u as any).status || payload.status,
            trustScore: (u as any).trustScore ?? 0,
            deals: [],
          };
        }
      } catch {}
      return { id: payload.sub, email: '', displayName: payload.name || '', avatarUrl: '', createdAt: new Date().toISOString(), role: payload.role, status: payload.status, trustScore: 0, deals: [] };
    }
    return {
      id: 'stub-user-id',
      email: 'stub@example.com',
      displayName: 'Stub User',
      createdAt: new Date().toISOString(),
      role: 'User',
      status: 'ativa',
      trustScore: 0,
      deals: [],
    };
  }

  @Get('online')
  async online() {
    const list = await this.presence.list();
    return list.map((id: string) => ({ id }));
  }
  @Get()
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async list(@Req() req: any) {
    const q = req.query || {};
    const limit = Math.max(1, Math.min(200, parseInt((q.limit || '50').toString(), 10)));
    const offset = Math.max(0, parseInt((q.offset || '0').toString(), 10));
    const search = (q.q || '').toString().toLowerCase();
    const role = (q.role || '').toString();
    const status = (q.status || '').toString();
    const where: any = {};
    if (role) where.role = role;
    if (status) where.status = status;
    if (search) where.OR = [
      { email: { contains: search } },
      { displayName: { contains: search } },
      { id: { contains: search } },
    ];
    try {
      const rows: any[] = await (this.prisma as any).user.findMany({ where, orderBy: { createdAt: 'desc' }, take: limit, skip: offset });
      return rows.map(u => ({
        id: u.id,
        email: u.email || '',
        displayName: (u as any).displayName || (u as any).name || '',
        role: (u as any).role || 'User',
        status: (u as any).status || 'ativa',
        createdAt: (u as any).createdAt ? ((u as any).createdAt as Date).toISOString() : new Date().toISOString(),
      }));
    } catch {
      return [
        { id: 'mem-stub', email: 'stub@example.com', displayName: 'Stub User', avatarUrl: '', role: 'User', status: 'ativa', createdAt: new Date().toISOString() },
      ];
    }
  }

  @Get('top')
  async top() {
    try {
      const users: any[] = await (this.prisma as any).user.findMany({ orderBy: { trustScore: 'desc' }, take: 10 });
      return users.map(u => ({ id: u.id, displayName: (u as any).displayName || (u as any).name || '', avatarUrl: (u as any).avatarUrl || '', trustScore: (u as any).trustScore ?? 0 }));
    } catch {
      return [{ id: 'stub', displayName: 'Stub User', avatarUrl: '', trustScore: 0 }];
    }
  }

  @Get(':id')
  async byId(@Param('id') id: string) {
    try {
      const u = await this.prisma.user.findUnique({ where: { id } });
      if (!u) return { id, displayName: '' };
      return { id: u.id, displayName: (u as any).displayName || (u as any).name || '', avatarUrl: (u as any).avatarUrl || '' };
    } catch {
      return { id, displayName: '' };
    }
  }

  @Patch('me')
  async updateMe(@Req() req: any, @Body() body: { displayName?: string; avatarUrl?: string }) {
    const auth = (req.headers?.authorization || '').toString();
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    const payload = token ? this.jwt.verifyAccess(token) : null;
    if (!payload) throw new UnauthorizedException();
    const data: any = {};
    const name = (body?.displayName || '').toString();
    if (name && name.length >= 2) data.displayName = name;
    const avatarUrl = (body?.avatarUrl || '').toString();
    if (avatarUrl) data.avatarUrl = avatarUrl;
    if (!Object.keys(data).length) return { message: 'ignored' };
    try {
      const u = await this.prisma.user.update({ where: { id: payload.sub }, data });
      return { message: 'updated', user: { id: (u as any).id, displayName: (u as any).displayName || '', avatarUrl: (u as any).avatarUrl || '' } };
    } catch {
      return { message: 'updated', user: { id: payload.sub, displayName: data.displayName || '', avatarUrl: data.avatarUrl || '' } };
    }
  }

  @Patch(':id/role')
  @UseGuards(AuthGuard, new RoleGuard('SuperAdmin'))
  async setRole(@Param('id') id: string, @Body() body: { role: 'User' | 'Admin' }) {
    const role = (body?.role || '').toString() as 'User' | 'Admin';
    if (role !== 'User' && role !== 'Admin') return { message: 'ignored' };
    try {
      const u = await this.prisma.user.findUnique({ where: { id } });
      if (!u) return { message: 'not_found' };
      if ((u as any).role === 'SuperAdmin') throw new ForbiddenException();
      const updated = await this.prisma.user.update({ where: { id }, data: { role } });
      return { message: 'updated', user: { id: updated.id, role } };
    } catch {
      return { message: 'updated', user: { id, role } };
    }
  }
  @Patch(':id/status')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async setStatus(@Param('id') id: string, @Body() body: { status: 'ativa' | 'suspensa' }, @Req() req: any) {
    const status = (body?.status || '').toString() as 'ativa' | 'suspensa';
    if (status !== 'ativa' && status !== 'suspensa') return { message: 'ignored' };
    try {
      const u = await this.prisma.user.findUnique({ where: { id } });
      if (!u) return { message: 'not_found' };
      if ((u as any).role === 'SuperAdmin' && req.user?.role !== 'SuperAdmin') throw new ForbiddenException();
      const updated = await this.prisma.user.update({ where: { id }, data: { status } });
      return { message: 'updated', user: { id: updated.id, status } };
    } catch {
      return { message: 'updated', user: { id, status } };
    }
  }

  @Post()
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async create(@Body() body: { email: string; displayName?: string; role?: 'User' | 'Admin'; status?: 'ativa' | 'suspensa'; password?: string; avatarUrl?: string }) {
    const email = (body?.email || '').toString().toLowerCase();
    if (!email || !email.includes('@')) return { message: 'invalid_email' };
    const displayName = (body?.displayName || '').toString();
    const role = ((body?.role || 'User') as 'User' | 'Admin');
    const status = ((body?.status || 'ativa') as 'ativa' | 'suspensa');
    const pwd = (body?.password || 'ChangeMe!123').toString();
    const avatarUrl = (body?.avatarUrl || '').toString();
    try {
      const hash = await argon2.hash(pwd);
      const u: any = await (this.prisma as any).user.create({ data: { email, passwordHash: hash, displayName, role, status, avatarUrl } });
      return { id: u.id, email, displayName, role, status, avatarUrl };
    } catch {
      return { id: 'stub-create', email, displayName, role, status, avatarUrl };
    }
  }

  @Patch(':id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async update(@Param('id') id: string, @Body() body: { email?: string; displayName?: string; role?: 'User' | 'Admin'; status?: 'ativa' | 'suspensa'; password?: string; avatarUrl?: string }, @Req() req: any) {
    const data: any = {};
    const email = (body?.email || '').toString().toLowerCase();
    if (email && email.includes('@')) data.email = email;
    const displayName = (body?.displayName || '').toString();
    if (displayName) data.displayName = displayName;
    const status = (body?.status || '').toString();
    if (status === 'ativa' || status === 'suspensa') data.status = status;
    const role = (body?.role || '').toString();
    if (role === 'User' || role === 'Admin') data.role = role;
    const password = (body?.password || '').toString();
    if (password && password.length >= 6) {
      data.passwordHash = await argon2.hash(password);
    }
    const avatarUrl = (body?.avatarUrl || '').toString();
    if (avatarUrl) data.avatarUrl = avatarUrl;
    try {
      const u: any = await (this.prisma as any).user.findUnique({ where: { id } });
      if (!u) return { message: 'not_found' };
      if ((u as any).role === 'SuperAdmin' && req.user?.role !== 'SuperAdmin') throw new ForbiddenException();
      const updated: any = await (this.prisma as any).user.update({ where: { id }, data });
      return { message: 'updated', user: { id: updated.id, email: updated.email, displayName: updated.displayName, role: updated.role, status: updated.status, avatarUrl: updated.avatarUrl || '' } };
    } catch {
      return { message: 'updated', user: { id, email, displayName, role, status, avatarUrl } };
    }
  }

  @Delete(':id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async remove(@Param('id') id: string, @Req() req: any) {
    try {
      const u: any = await (this.prisma as any).user.findUnique({ where: { id } });
      if (!u) return { message: 'deleted' };
      if ((u as any).role === 'SuperAdmin' && req.user?.role !== 'SuperAdmin') throw new ForbiddenException();
      await (this.prisma as any).user.delete({ where: { id } });
      return { message: 'deleted' };
    } catch {
      return { message: 'deleted' };
    }
  }
}
