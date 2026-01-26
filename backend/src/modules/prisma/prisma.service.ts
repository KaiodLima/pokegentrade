import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  available = false;
  async onModuleInit() {
    try {
      await this.$connect();
      this.available = true;
    } catch {
      this.available = false;
    }
  }
}
