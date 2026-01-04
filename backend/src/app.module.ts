import { Module } from '@nestjs/common';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { RoomsModule } from './modules/rooms/rooms.module';
import { MessagesModule } from './modules/messages/messages.module';
import { HealthController } from './modules/health.controller';
import { RateLimitModule } from './modules/rate-limit/rate-limit.module';
import { CommonModule } from './common/common.module';
import { PrismaModule } from './modules/prisma/prisma.module';
import { RedisModule } from './modules/redis/redis.module';
import { MarketplaceModule } from './modules/marketplace/marketplace.module';
import { ModerationModule } from './modules/moderation/moderation.module';
import { StorageModule } from './modules/storage/storage.module';
import { PresenceModule } from './modules/presence/presence.module';
import { MetricsModule } from './modules/metrics/metrics.module';
import { DmModule } from './modules/dm/dm.module';
import { AdminInitService } from './modules/admin/admin-init.service';
import { NewsModule } from './modules/news/news.module';
// import { PaymentsModule } from './modules/payments/payments.module';

@Module({
  imports: [CommonModule, PrismaModule, RedisModule, AuthModule, UsersModule, RoomsModule, MessagesModule, RateLimitModule, MarketplaceModule, ModerationModule, StorageModule, PresenceModule, DmModule, MetricsModule, NewsModule],
  controllers: [HealthController],
  providers: [AdminInitService],
})
export class AppModule {}
