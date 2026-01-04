import { Injectable } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';

interface JwtPayload {
  sub: string;
  role: 'User' | 'Admin' | 'SuperAdmin';
  status: 'ativa' | 'silenciada' | 'suspensa';
  name?: string;
}

@Injectable()
export class JwtService {
  signAccess(payload: JwtPayload) {
    const secret = process.env.JWT_SECRET || 'changeme';
    return jwt.sign(payload, secret, { expiresIn: '15m' });
  }
  signRefresh(payload: JwtPayload) {
    const secret = process.env.JWT_REFRESH_SECRET || 'changeme';
    return jwt.sign(payload, secret, { expiresIn: '30d' });
  }
  verifyAccess(token: string): JwtPayload | null {
    const secret = process.env.JWT_SECRET || 'changeme';
    try {
      return jwt.verify(token, secret) as JwtPayload;
    } catch {
      return null;
    }
  }
}
