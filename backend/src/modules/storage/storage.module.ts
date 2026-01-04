import { Module } from '@nestjs/common';
import { StorageController } from './storage.controller';
import { RateLimitModule } from '../rate-limit/rate-limit.module';

@Module({
  imports: [RateLimitModule],
  controllers: [StorageController],
})
export class StorageModule {}
