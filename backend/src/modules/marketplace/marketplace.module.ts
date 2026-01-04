import { Module } from '@nestjs/common';
import { MarketplaceController } from './marketplace.controller';
import { RateLimitModule } from '../rate-limit/rate-limit.module';

@Module({
  imports: [RateLimitModule],
  controllers: [MarketplaceController],
})
export class MarketplaceModule {}
