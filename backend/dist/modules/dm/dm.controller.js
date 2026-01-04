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
exports.DmController = void 0;
const common_1 = require("@nestjs/common");
const dm_service_1 = require("./dm.service");
const jwt_service_1 = require("../../common/jwt.service");
let DmController = class DmController {
    constructor(dm, jwt) {
        this.dm = dm;
        this.jwt = jwt;
    }
    inbox(req) {
        const auth = req.headers['authorization'] || '';
        const token = auth.split(' ')[1] || '';
        const payload = this.jwt.verifyAccess(token);
        if (!payload)
            return [];
        return this.dm.inbox(payload.sub);
    }
    async messages(userId, limit, before, req) {
        const auth = req.headers['authorization'] || '';
        const token = auth.split(' ')[1] || '';
        const payload = this.jwt.verifyAccess(token);
        if (!payload)
            return [];
        const lim = Math.max(1, Math.min(200, parseInt(limit || '50', 10)));
        const hist = await this.dm.history(payload.sub, userId, lim);
        if (before) {
            const d = new Date(before);
            if (!isNaN(d.getTime())) {
                return hist.filter((m) => new Date(m.createdAt).getTime() < d.getTime());
            }
        }
        return hist;
    }
    async unread(req) {
        const auth = req.headers['authorization'] || '';
        const token = auth.split(' ')[1] || '';
        const payload = this.jwt.verifyAccess(token);
        if (!payload)
            return [];
        return this.dm.unreadCounts(payload.sub);
    }
    async markRead(userId, req) {
        const auth = req.headers['authorization'] || '';
        const token = auth.split(' ')[1] || '';
        const payload = this.jwt.verifyAccess(token);
        if (!payload)
            return { ok: false };
        return this.dm.markRead(payload.sub, userId);
    }
    async edit(userId, id, body, req) {
        var _a;
        const auth = req.headers['authorization'] || '';
        const token = auth.split(' ')[1] || '';
        const payload = this.jwt.verifyAccess(token);
        if (!payload)
            return { ok: false };
        const content = ((_a = body === null || body === void 0 ? void 0 : body.content) !== null && _a !== void 0 ? _a : '').toString();
        if (!content)
            return { ok: false };
        return this.dm.edit(payload.sub, userId, id, content);
    }
    async remove(userId, id, req) {
        const auth = req.headers['authorization'] || '';
        const token = auth.split(' ')[1] || '';
        const payload = this.jwt.verifyAccess(token);
        if (!payload)
            return { ok: false };
        return this.dm.remove(payload.sub, userId, id);
    }
};
exports.DmController = DmController;
__decorate([
    (0, common_1.Get)('inbox'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], DmController.prototype, "inbox", null);
__decorate([
    (0, common_1.Get)(':userId/messages'),
    __param(0, (0, common_1.Param)('userId')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('before')),
    __param(3, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, Object]),
    __metadata("design:returntype", Promise)
], DmController.prototype, "messages", null);
__decorate([
    (0, common_1.Get)('unread'),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], DmController.prototype, "unread", null);
__decorate([
    (0, common_1.Post)(':userId/read'),
    __param(0, (0, common_1.Param)('userId')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], DmController.prototype, "markRead", null);
__decorate([
    (0, common_1.Patch)(':userId/messages/:id'),
    __param(0, (0, common_1.Param)('userId')),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __param(3, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object, Object]),
    __metadata("design:returntype", Promise)
], DmController.prototype, "edit", null);
__decorate([
    (0, common_1.Delete)(':userId/messages/:id'),
    __param(0, (0, common_1.Param)('userId')),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], DmController.prototype, "remove", null);
exports.DmController = DmController = __decorate([
    (0, common_1.Controller)('dm'),
    __metadata("design:paramtypes", [dm_service_1.DmService, jwt_service_1.JwtService])
], DmController);
//# sourceMappingURL=dm.controller.js.map