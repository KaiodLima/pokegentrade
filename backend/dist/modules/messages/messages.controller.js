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
exports.MessagesController = void 0;
const common_1 = require("@nestjs/common");
const class_validator_1 = require("class-validator");
const rate_limit_service_1 = require("../rate-limit/rate-limit.service");
const rooms_service_1 = require("../rooms/rooms.service");
const auth_guard_1 = require("../../common/auth.guard");
const prisma_service_1 = require("../prisma/prisma.service");
class SendMessageDto {
}
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], SendMessageDto.prototype, "roomId", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    __metadata("design:type", String)
], SendMessageDto.prototype, "content", void 0);
let MessagesController = class MessagesController {
    constructor(rl, rooms, prisma) {
        this.rl = rl;
        this.rooms = rooms;
        this.prisma = prisma;
    }
    async list(roomId, limit, before, q) {
        try {
            const take = Math.max(1, Math.min(200, parseInt(limit || '50', 10)));
            const where = { roomId };
            if (q) {
                const txt = q.toString();
                where.content = { contains: txt, mode: 'insensitive' };
            }
            if (before) {
                const d = new Date(before);
                if (!isNaN(d.getTime()))
                    where.createdAt = { lt: d };
            }
            const rows = await this.prisma.message.findMany({ where, orderBy: { createdAt: 'desc' }, take });
            const ids = Array.from(new Set(rows.map(r => r.userId).filter(Boolean)));
            let names = new Map();
            try {
                const users = await this.prisma.user.findMany({ where: { id: { in: ids } } });
                names = new Map(users.map(u => [u.id, (u.displayName || u.name || '')]));
            }
            catch { }
            return rows.map(r => { var _a, _b, _c; return ({ id: (_c = (_b = (_a = r.id) === null || _a === void 0 ? void 0 : _a.toString) === null || _b === void 0 ? void 0 : _b.call(_a)) !== null && _c !== void 0 ? _c : '', roomId: r.roomId, content: r.content, userId: r.userId, createdAt: r.createdAt.toISOString(), displayName: r.userId ? (names.get(r.userId) || '') : '' }); });
        }
        catch {
            return [];
        }
    }
    async send(roomId, dto, req) {
        var _a, _b;
        const room = await this.rooms.get(roomId);
        if (!room || room.rules.silenced) {
            return { status: 'blocked', reason: 'room_silenced_or_missing' };
        }
        const globalIntervalMs = (room.rules.intervalGlobalSeconds || 3) * 1000;
        const perUserIntervalMs = (room.rules.perUserSeconds || 0) * 1000;
        const g = await this.rl.checkGlobal(roomId, globalIntervalMs);
        if (!g.allowed)
            return { status: 'blocked', remainingMs: g.remainingMs, scope: 'global' };
        if (perUserIntervalMs > 0) {
            const u = await this.rl.checkUser(roomId, (((_a = req.user) === null || _a === void 0 ? void 0 : _a.sub) || 'stub-user-id'), perUserIntervalMs);
            if (!u.allowed)
                return { status: 'blocked', remainingMs: u.remainingMs, scope: 'user' };
        }
        try {
            const msg = await this.prisma.message.create({
                data: { roomId, content: dto.content, userId: (((_b = req.user) === null || _b === void 0 ? void 0 : _b.sub) || null) },
            });
            return msg;
        }
        catch {
            return { status: 'sent', roomId, content: dto.content, createdAt: new Date().toISOString() };
        }
    }
};
exports.MessagesController = MessagesController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Param)('roomId')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('before')),
    __param(3, (0, common_1.Query)('q')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], MessagesController.prototype, "list", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Param)('roomId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, SendMessageDto, Object]),
    __metadata("design:returntype", Promise)
], MessagesController.prototype, "send", null);
exports.MessagesController = MessagesController = __decorate([
    (0, common_1.Controller)('rooms/:roomId/messages'),
    __metadata("design:paramtypes", [rate_limit_service_1.RateLimitService, rooms_service_1.RoomsService, prisma_service_1.PrismaService])
], MessagesController);
//# sourceMappingURL=messages.controller.js.map