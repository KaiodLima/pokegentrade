import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';

@Injectable()
export class RoleGuard implements CanActivate {
  constructor(private readonly role: 'SuperAdmin' | 'Admin' | 'User') {}
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const user = req.user;
    if (!user) throw new ForbiddenException();
    if (this.role === 'SuperAdmin' && user.role !== 'SuperAdmin') throw new ForbiddenException();
    if (this.role === 'Admin' && !(user.role === 'Admin' || user.role === 'SuperAdmin')) throw new ForbiddenException();
    return true;
  }
}
