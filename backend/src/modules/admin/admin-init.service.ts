import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import argon2 from 'argon2';
/**
 * Inicializa o usuário SuperAdmin na primeira execução.
 * Usa variáveis de ambiente ADMIN_EMAIL, ADMIN_PASSWORD e ADMIN_NAME.
 * Caso o banco não esteja disponível, ignora silenciosamente.
 */
@Injectable()
export class AdminInitService implements OnModuleInit {
  constructor(private readonly prisma: PrismaService) {}
  async onModuleInit() {
    const email = process.env.ADMIN_EMAIL || 'admin@poketibia.local';
    const password = process.env.ADMIN_PASSWORD || 'ChangeMe!123';
    const name = process.env.ADMIN_NAME || 'Super Admin';
    try {
      const existing = await (this.prisma as any).user.findUnique({ where: { email } });
      (this.prisma as any).available = true;
      if (existing) {
        if ((existing as any).role !== 'SuperAdmin') {
          await (this.prisma as any).user.update({ where: { id: existing.id }, data: { role: 'SuperAdmin' } });
        }
        return;
      }
      const hash = await argon2.hash(password);
      await (this.prisma as any).user.create({ data: { email, passwordHash: hash, displayName: name, role: 'SuperAdmin', status: 'ativa' } });
      (this.prisma as any).available = true;
    } catch {
      // sem prisma/banco, não cria
    }
  }
}
