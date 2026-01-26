import { Body, Controller, Delete, Get, Param, Post, UseGuards, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthGuard } from '../../common/auth.guard';
import { RoleGuard } from '../../common/role.guard';
import { IsString, MinLength } from 'class-validator';

class CreateNameDto {
  @IsString()
  @MinLength(1)
  name!: string;
}

@Controller('marketplace')
export class MarketplaceMetaController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('categories')
  async listCategories() {
    return await this.prisma.category.findMany({ orderBy: { name: 'asc' } }).catch(() => []);
  }
  @Post('categories')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async createCategory(@Body() body: CreateNameDto) {
    const name = (body?.name || '').toString().trim();
    if (!name) throw new BadRequestException('invalid_name');
    try {
      return await this.prisma.category.create({ data: { name } });
    } catch {
      throw new InternalServerErrorException('category_create_failed');
    }
  }
  @Delete('categories/:id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async deleteCategory(@Param('id') id: string) {
    try { await this.prisma.category.delete({ where: { id } }); return { message: 'deleted' }; } catch { throw new InternalServerErrorException('category_delete_failed'); }
  }

  @Get('servers')
  async listServers() {
    return await this.prisma.server.findMany({ orderBy: { name: 'asc' } }).catch(() => []);
  }
  @Post('servers')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async createServer(@Body() body: CreateNameDto) {
    const name = (body?.name || '').toString().trim();
    if (!name) throw new BadRequestException('invalid_name');
    try {
      return await this.prisma.server.create({ data: { name } });
    } catch {
      throw new InternalServerErrorException('server_create_failed');
    }
  }
  @Delete('servers/:id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async deleteServer(@Param('id') id: string) {
    try { await this.prisma.server.delete({ where: { id } }); return { message: 'deleted' }; } catch { throw new InternalServerErrorException('server_delete_failed'); }
  }
}
