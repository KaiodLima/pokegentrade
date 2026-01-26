import { Body, Controller, Get, Param, Post, Patch, Delete, Query, Req, UseGuards } from '@nestjs/common';
import { DmService } from './dm.service';
import { JwtService } from '../../common/jwt.service';
import { AuthGuard } from '../../common/auth.guard';

@Controller('dm')
export class DmController {
  constructor(private readonly dm: DmService, private readonly jwt: JwtService) {}
  @Get('inbox')
  @UseGuards(AuthGuard)
  inbox(@Req() req: any) {
    return this.dm.inbox(req.user?.sub || '');
  }
  @Get(':userId/messages')
  @UseGuards(AuthGuard)
  async messages(@Param('userId') userId: string, @Query('limit') limit: string, @Query('before') before: string, @Req() req: any) {
    const lim = Math.max(1, Math.min(200, parseInt(limit || '50', 10)));
    const hist = await this.dm.history((req.user?.sub || ''), userId, lim);
    if (before) {
      const d = new Date(before);
      if (!isNaN(d.getTime())) {
        return hist.filter((m: any) => new Date(m.createdAt).getTime() < d.getTime());
      }
    }
    return hist;
  }
  @Get('unread')
  @UseGuards(AuthGuard)
  async unread(@Req() req: any) {
    return this.dm.unreadCounts(req.user?.sub || '');
  }
  @Post(':userId/read')
  @UseGuards(AuthGuard)
  async markRead(@Param('userId') userId: string, @Req() req: any) {
    return this.dm.markRead(req.user?.sub || '', userId);
  }
  @Patch(':userId/messages/:id')
  @UseGuards(AuthGuard)
  async edit(@Param('userId') userId: string, @Param('id') id: string, @Body() body: any, @Req() req: any) {
    const content = (body?.content ?? '').toString();
    if (!content) return { ok: false };
    return this.dm.edit(req.user?.sub || '', userId, id, content);
  }
  @Delete(':userId/messages/:id')
  @UseGuards(AuthGuard)
  async remove(@Param('userId') userId: string, @Param('id') id: string, @Req() req: any) {
    return this.dm.remove(req.user?.sub || '', userId, id);
  }
}
