import { Module } from '@nestjs/common';
import { MarketplaceController } from './marketplace.controller';
import { MarketplaceMetaController } from './marketplace.meta.controller';
import { RateLimitModule } from '../rate-limit/rate-limit.module';

@Module({
  imports: [RateLimitModule],
  controllers: [MarketplaceController, MarketplaceMetaController],
})
export class MarketplaceModule {}
