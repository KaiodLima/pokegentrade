import { Injectable } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import settings from 'src/settings';

interface JwtPayload {
  sub: string;
  role: 'User' | 'Admin' | 'SuperAdmin';
  status: 'ativa' | 'silenciada' | 'suspensa';
  name?: string;
}

@Injectable()
export class JwtService {
  signAccess(payload: JwtPayload) {
    const secret = settings.JWT_SECRET;
    return jwt.sign(payload, secret, { expiresIn: '15m' });
  }
  signRefresh(payload: JwtPayload) {
    const secret = settings.JWT_REFRESH_SECRET;
    return jwt.sign(payload, secret, { expiresIn: '30d' });
  }
  verifyAccess(token: string): JwtPayload | null {
    const secret = settings.JWT_SECRET;
    try {
      return jwt.verify(token, secret) as JwtPayload;
    } catch {
      return null;
    }
  }
}
