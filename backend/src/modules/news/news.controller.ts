import { Body, Controller, Get, Post, Patch, Delete, Param, Req, UseGuards } from '@nestjs/common';
import { NewsService } from './news.service';
import { AuthGuard } from '../../common/auth.guard';
import { RoleGuard } from '../../common/role.guard';

@Controller('news')
export class NewsController {
  constructor(private readonly news: NewsService) {}
  @Get()
  async list() {
    return this.news.list();
  }
  @Post()
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async create(@Req() req: any, @Body() body: { title: string; content: string; attachments?: any }) {
    const title = (body?.title || '').toString();
    const content = (body?.content || '').toString();
    if (!title || !content) return { message: 'invalid' };
    const atts = Array.isArray(body?.attachments) ? body.attachments.filter((x: any) => typeof x === 'string') : [];
    return this.news.create({ title, content, authorId: (req.user?.sub || ''), attachments: atts });
  }
  @Patch(':id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async update(@Param('id') id: string, @Body() body: { title?: string; content?: string; attachments?: any }) {
    const atts = Array.isArray(body?.attachments) ? body.attachments.filter((x: any) => typeof x === 'string') : undefined;
    const updated = await this.news.update(id, { title: (body?.title || undefined), content: (body?.content || undefined), attachments: atts });
    return updated ?? { message: 'not_found' };
  }
  @Delete(':id')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async remove(@Param('id') id: string) {
    return this.news.remove(id);
  }
}
