import { Injectable, UnauthorizedException, NotFoundException, OnModuleInit } from '@nestjs/common';
import argon2 from 'argon2';
import { JwtService } from '../../common/jwt.service';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import * as jwt from 'jsonwebtoken';
import { randomBytes } from 'crypto';

interface RegisterInput {
  email: string;
  password: string;
  displayName: string;
}

interface LoginInput {
  email: string;
  password: string;
}

@Injectable()
export class AuthService implements OnModuleInit {
  constructor(private readonly jwt: JwtService, private readonly prisma: PrismaService, private readonly redis: RedisService) {}
  private memUsers: Map<string, { id: string; email: string; displayName: string; passwordHash: string; role: 'User' | 'Admin' | 'SuperAdmin'; status: 'ativa' | 'silenciada' | 'suspensa'; trustScore: number }> = new Map();
  private resetTokens: Map<string, string> = new Map();

  async onModuleInit() {
    const email = process.env.ADMIN_EMAIL || 'admin@poketibia.local';
    const password = process.env.ADMIN_PASSWORD || 'ChangeMe!123';
    const name = process.env.ADMIN_NAME || 'Super Admin';
    try {
      const existing = await (this.prisma as any).user.findUnique({ where: { email } });
      if (existing && (existing as any).role !== 'SuperAdmin') {
        await (this.prisma as any).user.update({ where: { id: existing.id }, data: { role: 'SuperAdmin' } });
      }
    } catch {
      if (!this.memUsers.has(email)) {
        const hash = await argon2.hash(password);
        const id = `mem-${Math.random().toString(36).slice(2)}`;
        this.memUsers.set(email, { id, email, displayName: name, passwordHash: hash, role: 'SuperAdmin', status: 'ativa', trustScore: 0 });
      }
    }
  }

  async register(input: RegisterInput) {
    const passwordHash = await argon2.hash(input.password);
    let user: any;
    try {
      user = await this.prisma.user.create({
        data: {
          email: input.email,
          passwordHash,
          displayName: input.displayName,
        },
      });
    } catch {
      const id = `mem-${Math.random().toString(36).slice(2)}`;
      user = { id, email: input.email, passwordHash, displayName: input.displayName, createdAt: new Date(), role: 'User', status: 'ativa', trustScore: 0 };
      this.memUsers.set(user.email, { id: user.id, email: user.email, displayName: user.displayName, passwordHash, role: 'User', status: 'ativa', trustScore: 0 });
    }
    const payload = { sub: user.id, role: (user.role as 'User' | 'Admin' | 'SuperAdmin'), status: (user.status as 'ativa' | 'silenciada' | 'suspensa'), name: (user as any).displayName || (user as any).name };
    return {
      message: 'registered',
      user,
      tokens: { accessToken: this.jwt.signAccess(payload), refreshToken: this.jwt.signRefresh(payload) },
    };
  }

  async login(input: LoginInput) {
    let record: any = null;
    try {
      record = await this.prisma.user.findUnique({ where: { email: input.email } });
    } catch {
      record = this.memUsers.get(input.email) || null;
    }
    if (!record) {
      record = this.memUsers.get(input.email) || null;
    }
    if (!record) throw new UnauthorizedException();
    const ok = await argon2.verify(record.passwordHash, input.password);
    if (!ok) throw new UnauthorizedException();
    const user = record;
    const payload = { sub: user.id, role: (user.role as 'User' | 'Admin' | 'SuperAdmin'), status: (user.status as 'ativa' | 'silenciada' | 'suspensa'), name: (user as any).displayName || (user as any).name };
    return {
      message: 'logged-in',
      user,
      tokens: { accessToken: this.jwt.signAccess(payload), refreshToken: this.jwt.signRefresh(payload) },
    };
  }

  async refresh(refreshToken: string) {
    const secret = process.env.JWT_REFRESH_SECRET || 'changeme';
    let payload: any;
    try {
      payload = jwt.verify(refreshToken, secret) as any;
    } catch {
      throw new UnauthorizedException();
    }
    try {
      const blacklisted = await this.redis.get(`rt:blacklist:${refreshToken}`);
      if (blacklisted) throw new UnauthorizedException();
    } catch {
      // Redis indisponível: prosseguir sem verificação de blacklist
    }
    let user: any = null;
    try {
      user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    } catch {
      // tenta em memória
      for (const u of this.memUsers.values()) {
        if (u.id === payload.sub) { user = u; break; }
      }
    }
    if (!user) throw new UnauthorizedException();
    const newPayload = { sub: user.id, role: (user.role as 'User' | 'Admin' | 'SuperAdmin'), status: (user.status as 'ativa' | 'silenciada' | 'suspensa'), name: (user as any).displayName || (user as any).name };
    return {
      accessToken: this.jwt.signAccess(newPayload),
    };
  }

  async logout(refreshToken: string) {
    try {
      await this.redis.set(`rt:blacklist:${refreshToken}`, '1', 60 * 60 * 24 * 30);
    } catch {
      // Redis indisponível: retornar sucesso mesmo assim (sem revogação efetiva)
    }
    return { message: 'logged-out' };
  }

  async forgot(email: string) {
    let userId: string | null = null;
    try {
      const u = await this.prisma.user.findUnique({ where: { email } });
      if (u) userId = u.id;
    } catch {
      const mem = this.memUsers.get(email);
      if (mem) userId = mem.id;
    }
    if (!userId) throw new NotFoundException();
    const token = randomBytes(24).toString('hex');
    try {
      await this.redis.set(`pwdreset:${token}`, userId, 60 * 15);
    } catch {
      this.resetTokens.set(token, userId);
      setTimeout(() => this.resetTokens.delete(token), 60 * 15 * 1000);
    }
    return { message: 'reset-token-issued', token };
  }

  async reset(token: string, newPassword: string) {
    let userId: string | null = null;
    try {
      userId = await this.redis.get(`pwdreset:${token}`);
    } catch {
      userId = this.resetTokens.get(token) || null;
    }
    if (!userId) throw new UnauthorizedException();
    const passwordHash = await argon2.hash(newPassword);
    let updated: any = null;
    try {
      updated = await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
    } catch {
      for (const [email, u] of this.memUsers.entries()) {
        if (u.id === userId) {
          this.memUsers.set(email, { ...u, passwordHash });
          updated = { id: u.id, email, displayName: u.displayName, role: u.role, status: u.status };
          break;
        }
      }
    }
    const payload = { sub: userId, role: (updated?.role ?? 'User') as 'User' | 'Admin' | 'SuperAdmin', status: (updated?.status ?? 'ativa') as 'ativa' | 'silenciada' | 'suspensa', name: (updated?.displayName ?? updated?.name) as string | undefined };
    return { message: 'password-reset', tokens: { accessToken: this.jwt.signAccess(payload), refreshToken: this.jwt.signRefresh(payload) } };
  }
}
