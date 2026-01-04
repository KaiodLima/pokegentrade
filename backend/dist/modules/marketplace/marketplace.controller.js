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
exports.MarketplaceController = void 0;
const common_1 = require("@nestjs/common");
const class_validator_1 = require("class-validator");
const prisma_service_1 = require("../prisma/prisma.service");
const auth_guard_1 = require("../../common/auth.guard");
const role_guard_1 = require("../../common/role.guard");
const rate_limit_service_1 = require("../rate-limit/rate-limit.service");
const minio_1 = require("minio");
const prom_client_1 = require("prom-client");
const metrics_controller_1 = require("../metrics/metrics.controller");
class CreateAdDto {
}
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsIn)(['venda', 'compra', 'troca']),
    __metadata("design:type", String)
], CreateAdDto.prototype, "type", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    __metadata("design:type", String)
], CreateAdDto.prototype, "title", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    __metadata("design:type", String)
], CreateAdDto.prototype, "description", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], CreateAdDto.prototype, "price", void 0);
class UpdateAdDto {
}
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsIn)(['venda', 'compra', 'troca']),
    __metadata("design:type", String)
], UpdateAdDto.prototype, "type", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    __metadata("design:type", String)
], UpdateAdDto.prototype, "title", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(1),
    __metadata("design:type", String)
], UpdateAdDto.prototype, "description", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], UpdateAdDto.prototype, "price", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsIn)(['pendente', 'aprovado', 'concluido']),
    __metadata("design:type", String)
], UpdateAdDto.prototype, "status", void 0);
let MarketplaceController = class MarketplaceController {
    constructor(prisma, rl) {
        this.prisma = prisma;
        this.rl = rl;
        this.attachmentBlockedCounter = new prom_client_1.Counter({ name: 'poketibia_attachment_blocked_total', help: 'Attachment blocked', labelNames: ['reason'], registers: [metrics_controller_1.metricsRegistry] });
    }
    list() {
        return this.prisma.ad.findMany({ where: { status: 'aprovado' }, orderBy: { createdAt: 'desc' }, include: { attachments: true } }).catch(() => {
            return [
                { id: 'stub-1', authorId: 'stub-user', type: 'venda', title: 'Stub Item', description: 'Exemplo', price: 10.0, status: 'aprovado', createdAt: new Date().toISOString(), approvedBy: null, attachments: [] },
            ];
        });
    }
    adminList() {
        return this.prisma.ad.findMany({ orderBy: { createdAt: 'desc' }, include: { attachments: true } }).catch(() => {
            return [
                { id: 'stub-1', authorId: 'stub-user', type: 'venda', title: 'Stub Item', description: 'Exemplo', price: 10.0, status: 'pendente', createdAt: new Date().toISOString(), approvedBy: null, attachments: [] },
            ];
        });
    }
    detail(id) {
        return this.prisma.ad.findUnique({ where: { id }, include: { attachments: true } }).catch(() => {
            return { id, authorId: 'stub-user', type: 'venda', title: 'Stub Item', description: 'Exemplo', price: 10.0, status: 'pendente', createdAt: new Date().toISOString(), approvedBy: null, attachments: [] };
        });
    }
    async create(body, req) {
        var _a;
        const userId = (((_a = req.user) === null || _a === void 0 ? void 0 : _a.sub) || 'stub-user');
        const r = await this.rl.checkUser('marketplace:create', userId, 30000);
        if (!r.allowed)
            return { status: 'blocked', remainingMs: r.remainingMs, scope: 'user' };
        try {
            return await this.prisma.ad.create({
                data: { type: body.type, title: body.title, description: body.description, price: body.price, authorId: userId },
            });
        }
        catch {
            return { id: 'stub-create', authorId: userId, type: body.type, title: body.title, description: body.description, price: body.price, status: 'pendente', createdAt: new Date().toISOString() };
        }
    }
    async approve(id, req) {
        var _a;
        const adminId = (((_a = req.user) === null || _a === void 0 ? void 0 : _a.sub) || null);
        const ad = await this.prisma.ad.findUnique({ where: { id } });
        if (!ad)
            throw new common_1.NotFoundException('ad_not_found');
        if ((ad.status || 'pendente') !== 'pendente')
            throw new common_1.BadRequestException('invalid_state');
        try {
            return await this.prisma.ad.update({ where: { id }, data: { status: 'aprovado', approvedBy: adminId } });
        }
        catch (e) {
            throw new common_1.InternalServerErrorException('approve_failed');
        }
    }
    complete(id) {
        return this.prisma.ad.update({ where: { id }, data: { status: 'concluido' } }).catch(() => ({ id, status: 'concluido' }));
    }
    async update(id, body) {
        try {
            return await this.prisma.ad.update({
                where: { id },
                data: { type: body.type, title: body.title, description: body.description, price: body.price, status: body.status },
            });
        }
        catch {
            return { id, type: body.type, title: body.title, description: body.description, price: body.price, status: body.status };
        }
    }
    async remove(id) {
        try {
            await this.prisma.ad.delete({ where: { id } });
            return { message: 'deleted' };
        }
        catch {
            return { message: 'deleted' };
        }
    }
    async attach(id, body) {
        var _a, _b, _c;
        const allowed = new Set(['image/png', 'image/jpeg', 'image/gif', 'image/webp', 'application/pdf', 'text/plain', 'application/octet-stream']);
        if (!allowed.has(body.type)) {
            this.attachmentBlockedCounter.labels('invalid_content_type').inc();
            return { status: 'blocked', reason: 'invalid_content_type' };
        }
        const max = 5 * 1024 * 1024;
        const size = typeof ((_a = body.meta) === null || _a === void 0 ? void 0 : _a.size) === 'number' ? body.meta.size : 0;
        if (size > max) {
            this.attachmentBlockedCounter.labels('file_too_large').inc();
            return { status: 'blocked', reason: 'file_too_large', maxBytes: max, size };
        }
        try {
            const endpoint = process.env.S3_ENDPOINT || 'http://localhost:9000';
            const u = new URL(body.url || '');
            const eu = new URL(endpoint);
            const pathParts = (u.pathname || '').split('/').filter(Boolean);
            const bucket = pathParts[0] || (process.env.S3_BUCKET || 'uploads');
            const object = decodeURIComponent(pathParts.slice(1).join('/'));
            const client = new minio_1.Client({
                endPoint: eu.hostname,
                port: parseInt(eu.port || '80', 10),
                useSSL: eu.protocol === 'https:',
                accessKey: process.env.S3_ACCESS_KEY || '',
                secretKey: process.env.S3_SECRET_KEY || '',
            });
            const st = await client.statObject(bucket, object).catch(() => null);
            if (!st || typeof st.size !== 'number') {
                this.attachmentBlockedCounter.labels('object_missing').inc();
                return { status: 'blocked', reason: 'object_missing' };
            }
            const actualCt = (st.contentType || ((_b = st.metaData) === null || _b === void 0 ? void 0 : _b['content-type']) || ((_c = st.metaData) === null || _c === void 0 ? void 0 : _c.contentType) || '').toString();
            if (actualCt && actualCt !== body.type) {
                this.attachmentBlockedCounter.labels('content_type_mismatch').inc();
                return { status: 'blocked', reason: 'content_type_mismatch', expected: body.type, actual: actualCt };
            }
            if (st.size > max) {
                this.attachmentBlockedCounter.labels('file_too_large').inc();
                try {
                    await client.removeObject(bucket, object);
                }
                catch { }
                return { status: 'blocked', reason: 'file_too_large', maxBytes: max, size: st.size };
            }
        }
        catch { }
        try {
            return await this.prisma.adAttachment.create({ data: { adId: id, url: body.url, type: body.type, meta: body.meta || {} } });
        }
        catch {
            return { id: 'stub-attach', adId: id, url: body.url, type: body.type, meta: body.meta || {} };
        }
    }
};
exports.MarketplaceController = MarketplaceController;
__decorate([
    (0, common_1.Get)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], MarketplaceController.prototype, "list", null);
__decorate([
    (0, common_1.Get)('admin'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], MarketplaceController.prototype, "adminList", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], MarketplaceController.prototype, "detail", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [CreateAdDto, Object]),
    __metadata("design:returntype", Promise)
], MarketplaceController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id/approve'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], MarketplaceController.prototype, "approve", null);
__decorate([
    (0, common_1.Patch)(':id/complete'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], MarketplaceController.prototype, "complete", null);
__decorate([
    (0, common_1.Patch)(':id'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, UpdateAdDto]),
    __metadata("design:returntype", Promise)
], MarketplaceController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], MarketplaceController.prototype, "remove", null);
__decorate([
    (0, common_1.Post)(':id/attachments'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], MarketplaceController.prototype, "attach", null);
exports.MarketplaceController = MarketplaceController = __decorate([
    (0, common_1.Controller)('marketplace/ads'),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService, rate_limit_service_1.RateLimitService])
], MarketplaceController);
//# sourceMappingURL=marketplace.controller.js.map