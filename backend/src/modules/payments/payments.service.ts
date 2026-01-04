import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type Payment = {
  id?: string;
  userId: string;
  adId?: string | null;
  amount: number;
  currency: string;
  status: 'requires_payment' | 'processing' | 'succeeded' | 'refunded' | 'failed';
  createdAt: string;
};

@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService) {}
  private mem = new Map<string, Payment>();
  async intent(p: Payment) {
    try {
      const row: any = await (this.prisma as any).payment.create({
        data: { userId: p.userId, adId: p.adId ?? null, amount: p.amount, currency: p.currency, status: p.status, createdAt: new Date(p.createdAt) },
      });
      return { id: row.id?.toString?.() ?? '', clientSecret: `sec_${row.id?.toString?.() ?? ''}` };
    } catch {
      const id = `pay_${Math.random().toString(36).slice(2)}`;
      const created = { ...p, id };
      this.mem.set(id, created);
      return { id, clientSecret: `sec_${id}` };
    }
  }
  async confirm(intentId: string) {
    try {
      const updated: any = await (this.prisma as any).payment.update({ where: { id: intentId }, data: { status: 'succeeded' } });
      return { id: updated.id?.toString?.() ?? intentId, status: 'succeeded' as const };
    } catch {
      const p = this.mem.get(intentId);
      if (!p) return { id: intentId, status: 'failed' as const };
      p.status = 'succeeded';
      this.mem.set(intentId, p);
      return { id: intentId, status: 'succeeded' as const };
    }
  }
  async get(id: string) {
    try {
      const row: any = await (this.prisma as any).payment.findUnique({ where: { id } });
      if (!row) return null;
      return { id: row.id?.toString?.() ?? '', userId: row.userId, adId: row.adId, amount: row.amount, currency: row.currency, status: row.status, createdAt: (row.createdAt as Date).toISOString() } as Payment;
    } catch {
      return this.mem.get(id) || null;
    }
  }
  async refund(id: string) {
    try {
      const updated: any = await (this.prisma as any).payment.update({ where: { id }, data: { status: 'refunded' } });
      return { id: updated.id?.toString?.() ?? id, status: 'refunded' as const };
    } catch {
      const p = this.mem.get(id);
      if (!p) return { id, status: 'failed' as const };
      p.status = 'refunded';
      this.mem.set(id, p);
      return { id, status: 'refunded' as const };
    }
  }
}
