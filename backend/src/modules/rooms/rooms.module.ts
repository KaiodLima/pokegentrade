import { Module } from '@nestjs/common';
import { RoomsController } from './rooms.controller';
import { RoomsCreateController } from './rooms.controller';
import { RoomsService } from './rooms.service';
import { RoomsGateway } from './rooms.gateway';

@Module({
  controllers: [RoomsController, RoomsCreateController],
  providers: [RoomsService],
  exports: [RoomsService],
})
export class RoomsModule {}
