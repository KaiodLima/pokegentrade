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
exports.PaymentsController = void 0;
const common_1 = require("@nestjs/common");
const class_validator_1 = require("class-validator");
const payments_service_1 = require("./payments.service");
const auth_guard_1 = require("../../common/auth.guard");
const role_guard_1 = require("../../common/role.guard");
class CreateIntentDto {
}
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateIntentDto.prototype, "adId", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], CreateIntentDto.prototype, "amount", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(3),
    __metadata("design:type", String)
], CreateIntentDto.prototype, "currency", void 0);
class ConfirmDto {
}
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(3),
    __metadata("design:type", String)
], ConfirmDto.prototype, "intentId", void 0);
let PaymentsController = class PaymentsController {
    constructor(payments) {
        this.payments = payments;
    }
    async intent(body, req) {
        var _a, _b;
        const userId = (((_a = req.user) === null || _a === void 0 ? void 0 : _a.sub) || 'stub-user-id');
        const createdAt = new Date().toISOString();
        const res = await this.payments.intent({ userId, adId: (_b = body.adId) !== null && _b !== void 0 ? _b : null, amount: body.amount, currency: body.currency, status: 'requires_payment', createdAt });
        return { intentId: res.id, clientSecret: res.clientSecret };
    }
    async confirm(body) {
        const res = await this.payments.confirm(body.intentId);
        return res;
    }
    async get(id) {
        var _a;
        return (_a = (await this.payments.get(id))) !== null && _a !== void 0 ? _a : { id, status: 'failed' };
    }
    async refund(id) {
        return await this.payments.refund(id);
    }
};
exports.PaymentsController = PaymentsController;
__decorate([
    (0, common_1.Post)('intent'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [CreateIntentDto, Object]),
    __metadata("design:returntype", Promise)
], PaymentsController.prototype, "intent", null);
__decorate([
    (0, common_1.Post)('confirm'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [ConfirmDto]),
    __metadata("design:returntype", Promise)
], PaymentsController.prototype, "confirm", null);
__decorate([
    (0, common_1.Get)(':id'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], PaymentsController.prototype, "get", null);
__decorate([
    (0, common_1.Post)(':id/refund'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], PaymentsController.prototype, "refund", null);
exports.PaymentsController = PaymentsController = __decorate([
    (0, common_1.Controller)('payments'),
    __metadata("design:paramtypes", [payments_service_1.PaymentsService])
], PaymentsController);
//# sourceMappingURL=payments.controller.js.map