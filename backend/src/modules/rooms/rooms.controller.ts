import { Body, Controller, Get, Post, UseGuards, Req, Param, Patch, Delete } from '@nestjs/common';
import { RoomsService } from './rooms.service';
import { AuthGuard } from '../../common/auth.guard';
import { RoleGuard } from '../../common/role.guard';
import { IsBoolean, IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';

@Controller('rooms')
export class RoomsController {
  constructor(private readonly rooms: RoomsService) {}
  @Get()
  list() {
    return this.rooms.list();
  }
  @Get('summary')
  async summary() {
    return this.rooms.listSummary();
  }
  @Get('unread')
  @UseGuards(AuthGuard)
  async unread(@Req() req: any) {
    return this.rooms.unreadCounts((req.user?.sub || ''));
  }
  @Get('popular')
  async popular() {
    return this.rooms.popular(10);
  }
  @Post(':roomId/read')
  @UseGuards(AuthGuard)
  async markRead(@Param('roomId') roomId: string, @Req() req: any) {
    return this.rooms.markRead((req.user?.sub || ''), roomId);
  }
}

class CreateRoomDto {
  @IsString()
  @MinLength(2)
  name!: string;
  @IsString()
  @IsOptional()
  description?: string;
  @IsString()
  @IsOptional()
  imageUrl?: string;
  @IsInt()
  @Min(1)
  intervalGlobalSeconds!: number;
  @IsInt()
  @IsOptional()
  @Min(0)
  perUserSeconds?: number;
  @IsBoolean()
  @IsOptional()
  silenced?: boolean;
}

@Controller('rooms')
export class RoomsCreateController {
  constructor(private readonly rooms: RoomsService) {}
  @Post()
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async create(@Body() body: CreateRoomDto) {
    return this.rooms.create({
      name: body.name,
      description: body.description || '',
      imageUrl: body.imageUrl || '',
      rules: {
        intervalGlobalSeconds: body.intervalGlobalSeconds,
        perUserSeconds: body.perUserSeconds ?? 0,
        silenced: body.silenced ?? false,
      },
    });
  }
  @Patch(':id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async update(@Param('id') id: string, @Body() body: Partial<CreateRoomDto>) {
    return this.rooms.update(id, {
      name: (body.name || '').toString(),
      description: (body.description || '').toString(),
      imageUrl: (body.imageUrl || '').toString(),
      rules: {
        intervalGlobalSeconds: Math.max(1, Number(body.intervalGlobalSeconds || 3)),
        perUserSeconds: Math.max(0, Number(body.perUserSeconds || 0)),
        silenced: !!body.silenced,
      },
    });
  }
  @Delete(':id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async remove(@Param('id') id: string) {
    return this.rooms.remove(id);
  }
}
