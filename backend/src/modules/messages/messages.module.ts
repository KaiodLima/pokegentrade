import { Module } from '@nestjs/common';
import { MessagesController } from './messages.controller';
import { RateLimitModule } from '../rate-limit/rate-limit.module';
import { RoomsModule } from '../rooms/rooms.module';

@Module({
  imports: [RateLimitModule, RoomsModule],
  controllers: [MessagesController],
})
export class MessagesModule {}
