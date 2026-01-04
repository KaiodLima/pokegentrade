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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminInitService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const argon2_1 = __importDefault(require("argon2"));
let AdminInitService = class AdminInitService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async onModuleInit() {
        const email = process.env.ADMIN_EMAIL || 'admin@poketibia.local';
        const password = process.env.ADMIN_PASSWORD || 'ChangeMe!123';
        const name = process.env.ADMIN_NAME || 'Super Admin';
        try {
            const existing = await this.prisma.user.findUnique({ where: { email } });
            this.prisma.available = true;
            if (existing) {
                if (existing.role !== 'SuperAdmin') {
                    await this.prisma.user.update({ where: { id: existing.id }, data: { role: 'SuperAdmin' } });
                }
                return;
            }
            const hash = await argon2_1.default.hash(password);
            await this.prisma.user.create({ data: { email, passwordHash: hash, displayName: name, role: 'SuperAdmin', status: 'ativa' } });
            this.prisma.available = true;
        }
        catch {
        }
    }
};
exports.AdminInitService = AdminInitService;
exports.AdminInitService = AdminInitService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AdminInitService);
//# sourceMappingURL=admin-init.service.js.map