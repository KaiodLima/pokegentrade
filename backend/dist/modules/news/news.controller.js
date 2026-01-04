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
exports.NewsController = void 0;
const common_1 = require("@nestjs/common");
const news_service_1 = require("./news.service");
const auth_guard_1 = require("../../common/auth.guard");
const role_guard_1 = require("../../common/role.guard");
let NewsController = class NewsController {
    constructor(news) {
        this.news = news;
    }
    async list() {
        return this.news.list();
    }
    async create(req, body) {
        var _a;
        const title = ((body === null || body === void 0 ? void 0 : body.title) || '').toString();
        const content = ((body === null || body === void 0 ? void 0 : body.content) || '').toString();
        if (!title || !content)
            return { message: 'invalid' };
        const atts = Array.isArray(body === null || body === void 0 ? void 0 : body.attachments) ? body.attachments.filter((x) => typeof x === 'string') : [];
        return this.news.create({ title, content, authorId: (((_a = req.user) === null || _a === void 0 ? void 0 : _a.sub) || ''), attachments: atts });
    }
    async update(id, body) {
        const atts = Array.isArray(body === null || body === void 0 ? void 0 : body.attachments) ? body.attachments.filter((x) => typeof x === 'string') : undefined;
        const updated = await this.news.update(id, { title: ((body === null || body === void 0 ? void 0 : body.title) || undefined), content: ((body === null || body === void 0 ? void 0 : body.content) || undefined), attachments: atts });
        return updated !== null && updated !== void 0 ? updated : { message: 'not_found' };
    }
    async remove(id) {
        return this.news.remove(id);
    }
};
exports.NewsController = NewsController;
__decorate([
    (0, common_1.Get)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], NewsController.prototype, "list", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], NewsController.prototype, "create", null);
__decorate([
    (0, common_1.Patch)(':id'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], NewsController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard, new role_guard_1.RoleGuard('Admin')),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], NewsController.prototype, "remove", null);
exports.NewsController = NewsController = __decorate([
    (0, common_1.Controller)('news'),
    __metadata("design:paramtypes", [news_service_1.NewsService])
], NewsController);
//# sourceMappingURL=news.controller.js.map