"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const auth_module_1 = require("./modules/auth/auth.module");
const users_module_1 = require("./modules/users/users.module");
const rooms_module_1 = require("./modules/rooms/rooms.module");
const messages_module_1 = require("./modules/messages/messages.module");
const health_controller_1 = require("./modules/health.controller");
const rate_limit_module_1 = require("./modules/rate-limit/rate-limit.module");
const common_module_1 = require("./common/common.module");
const prisma_module_1 = require("./modules/prisma/prisma.module");
const redis_module_1 = require("./modules/redis/redis.module");
const marketplace_module_1 = require("./modules/marketplace/marketplace.module");
const moderation_module_1 = require("./modules/moderation/moderation.module");
const storage_module_1 = require("./modules/storage/storage.module");
const presence_module_1 = require("./modules/presence/presence.module");
const metrics_module_1 = require("./modules/metrics/metrics.module");
const dm_module_1 = require("./modules/dm/dm.module");
const admin_init_service_1 = require("./modules/admin/admin-init.service");
const news_module_1 = require("./modules/news/news.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [common_module_1.CommonModule, prisma_module_1.PrismaModule, redis_module_1.RedisModule, auth_module_1.AuthModule, users_module_1.UsersModule, rooms_module_1.RoomsModule, messages_module_1.MessagesModule, rate_limit_module_1.RateLimitModule, marketplace_module_1.MarketplaceModule, moderation_module_1.ModerationModule, storage_module_1.StorageModule, presence_module_1.PresenceModule, dm_module_1.DmModule, metrics_module_1.MetricsModule, news_module_1.NewsModule],
        controllers: [health_controller_1.HealthController],
        providers: [admin_init_service_1.AdminInitService],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map