import { Body, Controller, Post } from '@nestjs/common';
import { IsEmail, IsString, MinLength } from 'class-validator';
import { AuthService } from './auth.service';

class RegisterDto {
  @IsEmail()
  email!: string;
  @IsString()
  @MinLength(6)
  password!: string;
  @IsString()
  displayName!: string;
}

class LoginDto {
  @IsEmail()
  email!: string;
  @IsString()
  @MinLength(6)
  password!: string;
}

class ForgotDto {
  @IsEmail()
  email!: string;
}

class ResetDto {
  @IsString()
  token!: string;
  @IsString()
  @MinLength(6)
  newPassword!: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post('login')
  async login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Post('refresh')
  async refresh(@Body() body: { refreshToken: string }) {
    return this.auth.refresh(body.refreshToken);
  }

  @Post('logout')
  async logout(@Body() body: { refreshToken: string }) {
    return this.auth.logout(body.refreshToken);
  }

  @Post('forgot')
  async forgot(@Body() dto: ForgotDto) {
    return this.auth.forgot(dto.email);
  }

  @Post('reset')
  async reset(@Body() dto: ResetDto) {
    return this.auth.reset(dto.token, dto.newPassword);
  }
}

