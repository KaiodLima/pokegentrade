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
Object.defineProperty(exports, "__esModule", { value: true });
exports.ModerationController = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const auth_guard_1 = require("../../common/auth.guard");
const role_guard_1 = require("../../common/role.guard");
let ModerationController = class ModerationController {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async muteUser(body) {
        const acao = body.scope === 'room' ? `mute_room_${body.roomId}` : 'mute_global';
        await this.prisma.moderationAction.create({
            data: { adminId: 'admin-stub', alvoTipo: 'user', alvoId: body.userId, acao, motivo: body.motivo },
        });
        if (body.scope !== 'room') {
            await this.prisma.user.update({ where: { id: body.userId }, data: { status: 'silenciada' } });
        }
        return { status: 'ok' };
    }
    async suspendUser(body) {
        await this.prisma.moderationAction.create({
            data: { adminId: 'admin-stub', alvoTipo: 'user', alvoId: body.userId, acao: 'suspend', motivo: body.motivo },
        });
        await this.prisma.user.update({ where: { id: body.userId }, data: { status: 'suspensa' } });
        return { status: 'ok' };
    }
    async listActions(_unused, req) {
        const q = req.query || {};
        const limit = Math.max(1, Math.min(200, parseInt((q.limit || '50').toString(), 10)));
        const offset = Math.max(0, parseInt((q.offset || '0').toString(), 10));
        const adminId = (q.adminId || '').toString();
        const alvoId = (q.alvoId || '').toString();
        const acao = (q.acao || '').toString();
        const where = {};
        if (adminId)
            where.adminId = adminId;
        if (alvoId)
            where.alvoId = alvoId;
        if (acao)
            where.acao = acao;
        try {
            const rows = await this.prisma.moderationAction.findMany({ where, orderBy: { createdAt: 'desc' }, take: limit, skip: offset });
            return rows.map(a => ({
                id: a.id,
                adminId: a.adminId,
                alvoTipo: a.alvoTipo,
                alvoId: a.alvoId,
                acao: a.acao,
                motivo: a.motivo || '',
                createdAt: a.createdAt ? a.createdAt.toISOString() : new Date().toISOString(),
            }));
        }
        catch {
            return [];
        }
    }
};
exports.ModerationController = ModerationController;
__decorate([
    (0, common_1.Post)('users/mute'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ModerationController.prototype, "muteUser", null);
__decorate([
    (0, common_1.Post)('users/suspend'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ModerationController.prototype, "suspendUser", null);
__decorate([
    (0, common_1.Get)('actions'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], ModerationController.prototype, "listActions", null);
exports.ModerationController = ModerationController = __decorate([
    (0, common_1.Controller)('moderation'),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ModerationController);
//# sourceMappingURL=moderation.controller.js.map