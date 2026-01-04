import { Body, Controller, Get, Param, Post, UseGuards, Req } from '@nestjs/common';
import { IsInt, IsString, Min, MinLength } from 'class-validator';
import { PaymentsService } from './payments.service';
import { AuthGuard } from '../../common/auth.guard';
import { RoleGuard } from '../../common/role.guard';

class CreateIntentDto {
  @IsString()
  adId?: string;
  @IsInt()
  @Min(1)
  amount!: number;
  @IsString()
  @MinLength(3)
  currency!: string;
}
class ConfirmDto {
  @IsString()
  @MinLength(3)
  intentId!: string;
}

@Controller('payments')
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}
  @Post('intent')
  @UseGuards(AuthGuard)
  async intent(@Body() body: CreateIntentDto, @Req() req: any) {
    const userId = (req.user?.sub || 'stub-user-id');
    const createdAt = new Date().toISOString();
    const res = await this.payments.intent({ userId, adId: body.adId ?? null, amount: body.amount, currency: body.currency, status: 'requires_payment', createdAt });
    return { intentId: res.id, clientSecret: res.clientSecret };
  }
  @Post('confirm')
  @UseGuards(AuthGuard)
  async confirm(@Body() body: ConfirmDto) {
    const res = await this.payments.confirm(body.intentId);
    return res;
  }
  @Get(':id')
  @UseGuards(AuthGuard)
  async get(@Param('id') id: string) {
    return (await this.payments.get(id)) ?? { id, status: 'failed' };
  }
  @Post(':id/refund')
  @UseGuards(AuthGuard, new RoleGuard('Admin'))
  async refund(@Param('id') id: string) {
    return await this.payments.refund(id);
  }
}
