import { CanActivate, ExecutionContext, Injectable, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { JwtService } from './jwt.service';

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}
  canActivate(context: ExecutionContext): boolean {
    if (context.getType() === 'ws') {
      const client: any = context.switchToWs().getClient();
      const token = (client?.handshake?.auth?.token) || (client?.handshake?.query?.token) || null;
      if (!token) throw new UnauthorizedException();
      const payload = this.jwt.verifyAccess(token);
      if (!payload) throw new UnauthorizedException();
      if (payload.status === 'suspensa') throw new ForbiddenException();
      client.user = payload;
      return true;
    } else {
      const req = context.switchToHttp().getRequest();
      const header = req.headers['authorization'] || '';
      const token = typeof header === 'string' && header.startsWith('Bearer ') ? header.slice(7) : null;
      if (!token) throw new UnauthorizedException();
      const payload = this.jwt.verifyAccess(token);
      if (!payload) throw new UnauthorizedException();
      if (payload.status === 'suspensa') throw new ForbiddenException();
      req.user = payload;
      return true;
    }
    }
}
