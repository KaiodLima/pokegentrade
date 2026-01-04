"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const argon2_1 = __importDefault(require("argon2"));
const jwt_service_1 = require("../../common/jwt.service");
const prisma_service_1 = require("../prisma/prisma.service");
const redis_service_1 = require("../redis/redis.service");
const jwt = __importStar(require("jsonwebtoken"));
const crypto_1 = require("crypto");
let AuthService = class AuthService {
    constructor(jwt, prisma, redis) {
        this.jwt = jwt;
        this.prisma = prisma;
        this.redis = redis;
        this.memUsers = new Map();
        this.resetTokens = new Map();
    }
    async onModuleInit() {
        const email = process.env.ADMIN_EMAIL || 'admin@poketibia.local';
        const password = process.env.ADMIN_PASSWORD || 'ChangeMe!123';
        const name = process.env.ADMIN_NAME || 'Super Admin';
        try {
            const existing = await this.prisma.user.findUnique({ where: { email } });
            if (existing && existing.role !== 'SuperAdmin') {
                await this.prisma.user.update({ where: { id: existing.id }, data: { role: 'SuperAdmin' } });
            }
        }
        catch {
            if (!this.memUsers.has(email)) {
                const hash = await argon2_1.default.hash(password);
                const id = `mem-${Math.random().toString(36).slice(2)}`;
                this.memUsers.set(email, { id, email, displayName: name, passwordHash: hash, role: 'SuperAdmin', status: 'ativa', trustScore: 0 });
            }
        }
    }
    async register(input) {
        const passwordHash = await argon2_1.default.hash(input.password);
        let user;
        try {
            user = await this.prisma.user.create({
                data: {
                    email: input.email,
                    passwordHash,
                    displayName: input.displayName,
                },
            });
        }
        catch {
            const id = `mem-${Math.random().toString(36).slice(2)}`;
            user = { id, email: input.email, passwordHash, displayName: input.displayName, createdAt: new Date(), role: 'User', status: 'ativa', trustScore: 0 };
            this.memUsers.set(user.email, { id: user.id, email: user.email, displayName: user.displayName, passwordHash, role: 'User', status: 'ativa', trustScore: 0 });
        }
        const payload = { sub: user.id, role: user.role, status: user.status, name: user.displayName || user.name };
        return {
            message: 'registered',
            user,
            tokens: { accessToken: this.jwt.signAccess(payload), refreshToken: this.jwt.signRefresh(payload) },
        };
    }
    async login(input) {
        let record = null;
        try {
            record = await this.prisma.user.findUnique({ where: { email: input.email } });
        }
        catch {
            record = this.memUsers.get(input.email) || null;
        }
        if (!record) {
            record = this.memUsers.get(input.email) || null;
        }
        if (!record)
            throw new common_1.UnauthorizedException();
        const ok = await argon2_1.default.verify(record.passwordHash, input.password);
        if (!ok)
            throw new common_1.UnauthorizedException();
        const user = record;
        const payload = { sub: user.id, role: user.role, status: user.status, name: user.displayName || user.name };
        return {
            message: 'logged-in',
            user,
            tokens: { accessToken: this.jwt.signAccess(payload), refreshToken: this.jwt.signRefresh(payload) },
        };
    }
    async refresh(refreshToken) {
        const secret = process.env.JWT_REFRESH_SECRET || 'changeme';
        let payload;
        try {
            payload = jwt.verify(refreshToken, secret);
        }
        catch {
            throw new common_1.UnauthorizedException();
        }
        try {
            const blacklisted = await this.redis.get(`rt:blacklist:${refreshToken}`);
            if (blacklisted)
                throw new common_1.UnauthorizedException();
        }
        catch {
        }
        let user = null;
        try {
            user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
        }
        catch {
            for (const u of this.memUsers.values()) {
                if (u.id === payload.sub) {
                    user = u;
                    break;
                }
            }
        }
        if (!user)
            throw new common_1.UnauthorizedException();
        const newPayload = { sub: user.id, role: user.role, status: user.status, name: user.displayName || user.name };
        return {
            accessToken: this.jwt.signAccess(newPayload),
        };
    }
    async logout(refreshToken) {
        try {
            await this.redis.set(`rt:blacklist:${refreshToken}`, '1', 60 * 60 * 24 * 30);
        }
        catch {
        }
        return { message: 'logged-out' };
    }
    async forgot(email) {
        let userId = null;
        try {
            const u = await this.prisma.user.findUnique({ where: { email } });
            if (u)
                userId = u.id;
        }
        catch {
            const mem = this.memUsers.get(email);
            if (mem)
                userId = mem.id;
        }
        if (!userId)
            throw new common_1.NotFoundException();
        const token = (0, crypto_1.randomBytes)(24).toString('hex');
        try {
            await this.redis.set(`pwdreset:${token}`, userId, 60 * 15);
        }
        catch {
            this.resetTokens.set(token, userId);
            setTimeout(() => this.resetTokens.delete(token), 60 * 15 * 1000);
        }
        return { message: 'reset-token-issued', token };
    }
    async reset(token, newPassword) {
        var _a, _b, _c;
        let userId = null;
        try {
            userId = await this.redis.get(`pwdreset:${token}`);
        }
        catch {
            userId = this.resetTokens.get(token) || null;
        }
        if (!userId)
            throw new common_1.UnauthorizedException();
        const passwordHash = await argon2_1.default.hash(newPassword);
        let updated = null;
        try {
            updated = await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
        }
        catch {
            for (const [email, u] of this.memUsers.entries()) {
                if (u.id === userId) {
                    this.memUsers.set(email, { ...u, passwordHash });
                    updated = { id: u.id, email, displayName: u.displayName, role: u.role, status: u.status };
                    break;
                }
            }
        }
        const payload = { sub: userId, role: ((_a = updated === null || updated === void 0 ? void 0 : updated.role) !== null && _a !== void 0 ? _a : 'User'), status: ((_b = updated === null || updated === void 0 ? void 0 : updated.status) !== null && _b !== void 0 ? _b : 'ativa'), name: ((_c = updated === null || updated === void 0 ? void 0 : updated.displayName) !== null && _c !== void 0 ? _c : updated === null || updated === void 0 ? void 0 : updated.name) };
        return { message: 'password-reset', tokens: { accessToken: this.jwt.signAccess(payload), refreshToken: this.jwt.signRefresh(payload) } };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [jwt_service_1.JwtService, prisma_service_1.PrismaService, redis_service_1.RedisService])
], AuthService);
//# sourceMappingURL=auth.service.js.map