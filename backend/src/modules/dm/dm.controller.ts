import { Body, Controller, Get, Param, Post, Patch, Delete, Query, Req } from '@nestjs/common';
import { DmService } from './dm.service';
import { JwtService } from '../../common/jwt.service';

@Controller('dm')
export class DmController {
  constructor(private readonly dm: DmService, private readonly jwt: JwtService) {}
  @Get('inbox')
  inbox(@Req() req: any) {
    const auth = req.headers['authorization'] || '';
    const token = auth.split(' ')[1] || '';
    const payload = this.jwt.verifyAccess(token);
    if (!payload) return [];
    return this.dm.inbox(payload.sub);
  }
  @Get(':userId/messages')
  async messages(@Param('userId') userId: string, @Query('limit') limit: string, @Query('before') before: string, @Req() req: any) {
    const auth = req.headers['authorization'] || '';
    const token = auth.split(' ')[1] || '';
    const payload = this.jwt.verifyAccess(token);
    if (!payload) return [];
    const lim = Math.max(1, Math.min(200, parseInt(limit || '50', 10)));
    const hist = await this.dm.history(payload.sub, userId, lim);
    if (before) {
      const d = new Date(before);
      if (!isNaN(d.getTime())) {
        return hist.filter((m: any) => new Date(m.createdAt).getTime() < d.getTime());
      }
    }
    return hist;
  }
  @Get('unread')
  async unread(@Req() req: any) {
    const auth = req.headers['authorization'] || '';
    const token = auth.split(' ')[1] || '';
    const payload = this.jwt.verifyAccess(token);
    if (!payload) return [];
    return this.dm.unreadCounts(payload.sub);
  }
  @Post(':userId/read')
  async markRead(@Param('userId') userId: string, @Req() req: any) {
    const auth = req.headers['authorization'] || '';
    const token = auth.split(' ')[1] || '';
    const payload = this.jwt.verifyAccess(token);
    if (!payload) return { ok: false };
    return this.dm.markRead(payload.sub, userId);
  }
  @Patch(':userId/messages/:id')
  async edit(@Param('userId') userId: string, @Param('id') id: string, @Body() body: any, @Req() req: any) {
    const auth = req.headers['authorization'] || '';
    const token = auth.split(' ')[1] || '';
    const payload = this.jwt.verifyAccess(token);
    if (!payload) return { ok: false };
    const content = (body?.content ?? '').toString();
    if (!content) return { ok: false };
    return this.dm.edit(payload.sub, userId, id, content);
  }
  @Delete(':userId/messages/:id')
  async remove(@Param('userId') userId: string, @Param('id') id: string, @Req() req: any) {
    const auth = req.headers['authorization'] || '';
    const token = auth.split(' ')[1] || '';
    const payload = this.jwt.verifyAccess(token);
    if (!payload) return { ok: false };
    return this.dm.remove(payload.sub, userId, id);
  }
}
