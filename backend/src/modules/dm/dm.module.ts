import { Module } from '@nestjs/common';
import { DmGateway } from './dm.gateway';
import { JwtService } from '../../common/jwt.service';
import { DmService } from './dm.service';
import { DmController } from './dm.controller';

@Module({
  providers: [DmGateway, JwtService, DmService],
  controllers: [DmController],
})
export class DmModule {}
