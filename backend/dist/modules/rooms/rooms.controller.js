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
exports.RoomsCreateController = exports.RoomsController = void 0;
const common_1 = require("@nestjs/common");
const rooms_service_1 = require("./rooms.service");
const auth_guard_1 = require("../../common/auth.guard");
const role_guard_1 = require("../../common/role.guard");
const class_validator_1 = require("class-validator");
let RoomsController = class RoomsController {
    constructor(rooms) {
        this.rooms = rooms;
    }
    list() {
        return this.rooms.list();
    }
    async summary() {
        return this.rooms.listSummary();
    }
    async unread(req) {
        var _a;
        return this.rooms.unreadCounts((((_a = req.user) === null || _a === void 0 ? void 0 : _a.sub) || ''));
    }
    async popular() {
        return this.rooms.popular(10);
    }
    async markRead(roomId, req) {
        var _a;
        return this.rooms.markRead((((_a = req.user) === null || _a === void 0 ? void 0 : _a.sub) || ''), roomId);
    }
};
exports.RoomsController = RoomsController;
__decorate([
    (0, common_1.Get)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], RoomsController.prototype, "list", null);
__decorate([
    (0, common_1.Get)('summary'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], RoomsController.prototype, "summary", null);
__decorate([
    (0, common_1.Get)('unread'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], RoomsController.prototype, "unread", null);
__decorate([
    (0, common_1.Get)('popular'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], RoomsController.prototype, "popular", null);
__decorate([
    (0, common_1.Post)(':roomId/read'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Param)('roomId')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], RoomsController.prototype, "markRead", null);
exports.RoomsController = RoomsController = __decorate([
    (0, common_1.Controller)('rooms'),
    __metadata("design:paramtypes", [rooms_service_1.RoomsService])
], RoomsController);
class CreateRoomDto {
}
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(2),
    __metadata("design:type", String)
], CreateRoomDto.prototype, "name", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateRoomDto.prototype, "description", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateRoomDto.prototype, "imageUrl", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], CreateRoomDto.prototype, "intervalGlobalSeconds", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateRoomDto.prototype, "perUserSeconds", void 0);
__decorate([
    (0, class_validator_1.IsBoolean)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Boolean)
], CreateRoomDto.prototype, "silenced", void 0);
let RoomsCreateController = class RoomsCreateController {
    constructor(rooms) {
        this.rooms = rooms;
    }
    async create(body) {
        var _a, _b;
        return this.rooms.create({
            name: body.name,
            description: body.description || '',
            imageUrl: body.imageUrl || '',
            rules: {
                intervalGlobalSeconds: body.intervalGlobalSeconds,
                perUserSeconds: (_a = body.perUserSeconds) !== null && _a !== void 0 ? _a : 0,
                silenced: (_b = body.silenced) !== null && _b !== void 0 ? _b : false,
            },
        });
    }
    async update(id, body) {
        return this.rooms.update(id, {
            name: (body.name || '').toString(),
            description: (body.description || '').toString(),
            imageUrl: (body.imageUrl || '').toString(),
            rules: {
                intervalGlobalSeconds: Math.max(1, Number(body.intervalGlobalSeconds || 3)),
                perUserSeconds: Math.max(0, Number(body.perUserSeconds || 0)),
                silenced: !!body.silenced,
            },
        });
    }
    async remove(id) {
        return this.rooms.remove(id);
    }
};
exports.RoomsCreateController = RoomsCreateController;
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [CreateRoomDto]),
    __metadata("design:returntype", Promise)
], RoomsCreateController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], RoomsCreateController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], RoomsCreateController.prototype, "remove", null);
exports.RoomsCreateController = RoomsCreateController = __decorate([
    (0, common_1.Controller)('rooms'),
    __metadata("design:paramtypes", [rooms_service_1.RoomsService])
], RoomsCreateController);
//# sourceMappingURL=rooms.controller.js.map