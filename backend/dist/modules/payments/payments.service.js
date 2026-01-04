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
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let PaymentsService = class PaymentsService {
    constructor(prisma) {
        this.prisma = prisma;
        this.mem = new Map();
    }
    async intent(p) {
        var _a, _b, _c, _d, _e, _f, _g;
        try {
            const row = await this.prisma.payment.create({
                data: { userId: p.userId, adId: (_a = p.adId) !== null && _a !== void 0 ? _a : null, amount: p.amount, currency: p.currency, status: p.status, createdAt: new Date(p.createdAt) },
            });
            return { id: (_d = (_c = (_b = row.id) === null || _b === void 0 ? void 0 : _b.toString) === null || _c === void 0 ? void 0 : _c.call(_b)) !== null && _d !== void 0 ? _d : '', clientSecret: `sec_${(_g = (_f = (_e = row.id) === null || _e === void 0 ? void 0 : _e.toString) === null || _f === void 0 ? void 0 : _f.call(_e)) !== null && _g !== void 0 ? _g : ''}` };
        }
        catch {
            const id = `pay_${Math.random().toString(36).slice(2)}`;
            const created = { ...p, id };
            this.mem.set(id, created);
            return { id, clientSecret: `sec_${id}` };
        }
    }
    async confirm(intentId) {
        var _a, _b, _c;
        try {
            const updated = await this.prisma.payment.update({ where: { id: intentId }, data: { status: 'succeeded' } });
            return { id: (_c = (_b = (_a = updated.id) === null || _a === void 0 ? void 0 : _a.toString) === null || _b === void 0 ? void 0 : _b.call(_a)) !== null && _c !== void 0 ? _c : intentId, status: 'succeeded' };
        }
        catch {
            const p = this.mem.get(intentId);
            if (!p)
                return { id: intentId, status: 'failed' };
            p.status = 'succeeded';
            this.mem.set(intentId, p);
            return { id: intentId, status: 'succeeded' };
        }
    }
    async get(id) {
        var _a, _b, _c;
        try {
            const row = await this.prisma.payment.findUnique({ where: { id } });
            if (!row)
                return null;
            return { id: (_c = (_b = (_a = row.id) === null || _a === void 0 ? void 0 : _a.toString) === null || _b === void 0 ? void 0 : _b.call(_a)) !== null && _c !== void 0 ? _c : '', userId: row.userId, adId: row.adId, amount: row.amount, currency: row.currency, status: row.status, createdAt: row.createdAt.toISOString() };
        }
        catch {
            return this.mem.get(id) || null;
        }
    }
    async refund(id) {
        var _a, _b, _c;
        try {
            const updated = await this.prisma.payment.update({ where: { id }, data: { status: 'refunded' } });
            return { id: (_c = (_b = (_a = updated.id) === null || _a === void 0 ? void 0 : _a.toString) === null || _b === void 0 ? void 0 : _b.call(_a)) !== null && _c !== void 0 ? _c : id, status: 'refunded' };
        }
        catch {
            const p = this.mem.get(id);
            if (!p)
                return { id, status: 'failed' };
            p.status = 'refunded';
            this.mem.set(id, p);
            return { id, status: 'refunded' };
        }
    }
};
exports.PaymentsService = PaymentsService;
exports.PaymentsService = PaymentsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PaymentsService);
//# sourceMappingURL=payments.service.js.map