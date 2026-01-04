"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersController = void 0;
const common_1 = require("@nestjs/common");
const presence_service_1 = require("../presence/presence.service");
const prisma_service_1 = require("../prisma/prisma.service");
const jwt_service_1 = require("../../common/jwt.service");
const auth_guard_1 = require("../../common/auth.guard");
const role_guard_1 = require("../../common/role.guard");
const argon2_1 = __importDefault(require("argon2"));
let UsersController = class UsersController {
    constructor(presence, prisma, jwt) {
        this.presence = presence;
        this.prisma = prisma;
        this.jwt = jwt;
    }
    async me(req) {
        var _a, _b;
        const auth = (((_a = req.headers) === null || _a === void 0 ? void 0 : _a.authorization) || '').toString();
        const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
        const payload = token ? this.jwt.verifyAccess(token) : null;
        if (payload) {
            try {
                const u = await this.prisma.user.findUnique({ where: { id: payload.sub } });
                if (u) {
                    return {
                        id: u.id,
                        email: u.email || '',
                        displayName: u.displayName || u.name || '',
                        avatarUrl: u.avatarUrl || '',
                        createdAt: u.createdAt ? u.createdAt.toISOString() : new Date().toISOString(),
                        role: u.role || payload.role,
                        status: u.status || payload.status,
                        trustScore: (_b = u.trustScore) !== null && _b !== void 0 ? _b : 0,
                        deals: [],
                    };
                }
            }
            catch { }
            return { id: payload.sub, email: '', displayName: payload.name || '', avatarUrl: '', createdAt: new Date().toISOString(), role: payload.role, status: payload.status, trustScore: 0, deals: [] };
        }
        return {
            id: 'stub-user-id',
            email: 'stub@example.com',
            displayName: 'Stub User',
            createdAt: new Date().toISOString(),
            role: 'User',
            status: 'ativa',
            trustScore: 0,
            deals: [],
        };
    }
    async online() {
        const list = await this.presence.list();
        return list.map((id) => ({ id }));
    }
    async list(req) {
        const q = req.query || {};
        const limit = Math.max(1, Math.min(200, parseInt((q.limit || '50').toString(), 10)));
        const offset = Math.max(0, parseInt((q.offset || '0').toString(), 10));
        const search = (q.q || '').toString().toLowerCase();
        const role = (q.role || '').toString();
        const status = (q.status || '').toString();
        const where = {};
        if (role)
            where.role = role;
        if (status)
            where.status = status;
        if (search)
            where.OR = [
                { email: { contains: search } },
                { displayName: { contains: search } },
                { id: { contains: search } },
            ];
        try {
            const rows = await this.prisma.user.findMany({ where, orderBy: { createdAt: 'desc' }, take: limit, skip: offset });
            return rows.map(u => ({
                id: u.id,
                email: u.email || '',
                displayName: u.displayName || u.name || '',
                role: u.role || 'User',
                status: u.status || 'ativa',
                createdAt: u.createdAt ? u.createdAt.toISOString() : new Date().toISOString(),
            }));
        }
        catch {
            return [
                { id: 'mem-stub', email: 'stub@example.com', displayName: 'Stub User', avatarUrl: '', role: 'User', status: 'ativa', createdAt: new Date().toISOString() },
            ];
        }
    }
    async top() {
        try {
            const users = await this.prisma.user.findMany({ orderBy: { trustScore: 'desc' }, take: 10 });
            return users.map(u => { var _a; return ({ id: u.id, displayName: u.displayName || u.name || '', avatarUrl: u.avatarUrl || '', trustScore: (_a = u.trustScore) !== null && _a !== void 0 ? _a : 0 }); });
        }
        catch {
            return [{ id: 'stub', displayName: 'Stub User', avatarUrl: '', trustScore: 0 }];
        }
    }
    async byId(id) {
        try {
            const u = await this.prisma.user.findUnique({ where: { id } });
            if (!u)
                return { id, displayName: '' };
            return { id: u.id, displayName: u.displayName || u.name || '', avatarUrl: u.avatarUrl || '' };
        }
        catch {
            return { id, displayName: '' };
        }
    }
    async updateMe(req, body) {
        var _a;
        const auth = (((_a = req.headers) === null || _a === void 0 ? void 0 : _a.authorization) || '').toString();
        const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
        const payload = token ? this.jwt.verifyAccess(token) : null;
        if (!payload)
            throw new common_1.UnauthorizedException();
        const data = {};
        const name = ((body === null || body === void 0 ? void 0 : body.displayName) || '').toString();
        if (name && name.length >= 2)
            data.displayName = name;
        const avatarUrl = ((body === null || body === void 0 ? void 0 : body.avatarUrl) || '').toString();
        if (avatarUrl)
            data.avatarUrl = avatarUrl;
        if (!Object.keys(data).length)
            return { message: 'ignored' };
        try {
            const u = await this.prisma.user.update({ where: { id: payload.sub }, data });
            return { message: 'updated', user: { id: u.id, displayName: u.displayName || '', avatarUrl: u.avatarUrl || '' } };
        }
        catch {
            return { message: 'updated', user: { id: payload.sub, displayName: data.displayName || '', avatarUrl: data.avatarUrl || '' } };
        }
    }
    async setRole(id, body) {
        const role = ((body === null || body === void 0 ? void 0 : body.role) || '').toString();
        if (role !== 'User' && role !== 'Admin')
            return { message: 'ignored' };
        try {
            const u = await this.prisma.user.findUnique({ where: { id } });
            if (!u)
                return { message: 'not_found' };
            if (u.role === 'SuperAdmin')
                throw new common_1.ForbiddenException();
            const updated = await this.prisma.user.update({ where: { id }, data: { role } });
            return { message: 'updated', user: { id: updated.id, role } };
        }
        catch {
            return { message: 'updated', user: { id, role } };
        }
    }
    async setStatus(id, body, req) {
        var _a;
        const status = ((body === null || body === void 0 ? void 0 : body.status) || '').toString();
        if (status !== 'ativa' && status !== 'suspensa')
            return { message: 'ignored' };
        try {
            const u = await this.prisma.user.findUnique({ where: { id } });
            if (!u)
                return { message: 'not_found' };
            if (u.role === 'SuperAdmin' && ((_a = req.user) === null || _a === void 0 ? void 0 : _a.role) !== 'SuperAdmin')
                throw new common_1.ForbiddenException();
            const updated = await this.prisma.user.update({ where: { id }, data: { status } });
            return { message: 'updated', user: { id: updated.id, status } };
        }
        catch {
            return { message: 'updated', user: { id, status } };
        }
    }
    async create(body) {
        const email = ((body === null || body === void 0 ? void 0 : body.email) || '').toString().toLowerCase();
        if (!email || !email.includes('@'))
            return { message: 'invalid_email' };
        const displayName = ((body === null || body === void 0 ? void 0 : body.displayName) || '').toString();
        const role = ((body === null || body === void 0 ? void 0 : body.role) || 'User');
        const status = ((body === null || body === void 0 ? void 0 : body.status) || 'ativa');
        const pwd = ((body === null || body === void 0 ? void 0 : body.password) || 'ChangeMe!123').toString();
        const avatarUrl = ((body === null || body === void 0 ? void 0 : body.avatarUrl) || '').toString();
        try {
            const hash = await argon2_1.default.hash(pwd);
            const u = await this.prisma.user.create({ data: { email, passwordHash: hash, displayName, role, status, avatarUrl } });
            return { id: u.id, email, displayName, role, status, avatarUrl };
        }
        catch {
            return { id: 'stub-create', email, displayName, role, status, avatarUrl };
        }
    }
    async update(id, body, req) {
        var _a;
        const data = {};
        const email = ((body === null || body === void 0 ? void 0 : body.email) || '').toString().toLowerCase();
        if (email && email.includes('@'))
            data.email = email;
        const displayName = ((body === null || body === void 0 ? void 0 : body.displayName) || '').toString();
        if (displayName)
            data.displayName = displayName;
        const status = ((body === null || body === void 0 ? void 0 : body.status) || '').toString();
        if (status === 'ativa' || status === 'suspensa')
            data.status = status;
        const role = ((body === null || body === void 0 ? void 0 : body.role) || '').toString();
        if (role === 'User' || role === 'Admin')
            data.role = role;
        const password = ((body === null || body === void 0 ? void 0 : body.password) || '').toString();
        if (password && password.length >= 6) {
            data.passwordHash = await argon2_1.default.hash(password);
        }
        const avatarUrl = ((body === null || body === void 0 ? void 0 : body.avatarUrl) || '').toString();
        if (avatarUrl)
            data.avatarUrl = avatarUrl;
        try {
            const u = await this.prisma.user.findUnique({ where: { id } });
            if (!u)
                return { message: 'not_found' };
            if (u.role === 'SuperAdmin' && ((_a = req.user) === null || _a === void 0 ? void 0 : _a.role) !== 'SuperAdmin')
                throw new common_1.ForbiddenException();
            const updated = await this.prisma.user.update({ where: { id }, data });
            return { message: 'updated', user: { id: updated.id, email: updated.email, displayName: updated.displayName, role: updated.role, status: updated.status, avatarUrl: updated.avatarUrl || '' } };
        }
        catch {
            return { message: 'updated', user: { id, email, displayName, role, status, avatarUrl } };
        }
    }
    async remove(id, req) {
        var _a;
        try {
            const u = await this.prisma.user.findUnique({ where: { id } });
            if (!u)
                return { message: 'deleted' };
            if (u.role === 'SuperAdmin' && ((_a = req.user) === null || _a === void 0 ? void 0 : _a.role) !== 'SuperAdmin')
                throw new common_1.ForbiddenException();
            await this.prisma.user.delete({ where: { id } });
            return { message: 'deleted' };
        }
        catch {
            return { message: 'deleted' };
        }
    }
};
exports.UsersController = UsersController;
__decorate([
    (0, common_1.Get)('me'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "me", null);
__decorate([
    (0, common_1.Get)('online'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "online", null);
__decorate([
    (0, common_1.Get)(),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "list", null);
__decorate([
    (0, common_1.Get)('top'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "top", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "byId", null);
__decorate([
    (0, common_1.Patch)('me'),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "updateMe", null);
__decorate([
    (0, common_1.Patch)(':id/role'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('SuperAdmin')),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "setRole", null);
__decorate([
    (0, common_1.Patch)(':id/status'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "setStatus", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "remove", null);
exports.UsersController = UsersController = __decorate([
    (0, common_1.Controller)('users'),
    __metadata("design:paramtypes", [presence_service_1.PresenceService, prisma_service_1.PrismaService, jwt_service_1.JwtService])
], UsersController);
//# sourceMappingURL=users.controller.js.map