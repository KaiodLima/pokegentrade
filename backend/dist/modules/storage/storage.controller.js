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
exports.StorageController = void 0;
const common_1 = require("@nestjs/common");
const auth_guard_1 = require("../../common/auth.guard");
const minio_1 = require("minio");
const rate_limit_service_1 = require("../rate-limit/rate-limit.service");
const prom = require('prom-client');
const metrics_controller_1 = require("../metrics/metrics.controller");
let StorageController = class StorageController {
    constructor(rl) {
        this.rl = rl;
        this.presignCounter = new prom.Counter({ name: 'poketibia_presign_requests_total', help: 'Presign requests', registers: [metrics_controller_1.metricsRegistry] });
        this.presignBlockedCounter = new prom.Counter({ name: 'poketibia_presign_blocked_total', help: 'Presign blocked', labelNames: ['reason'], registers: [metrics_controller_1.metricsRegistry] });
    }
    async getPresigned(body, req) {
        var _a;
        const allowed = new Set(['image/png', 'image/jpeg', 'image/gif', 'image/webp', 'application/pdf', 'text/plain', 'application/octet-stream']);
        const ct = allowed.has(body.contentType) ? body.contentType : 'application/octet-stream';
        const userId = (((_a = req.user) === null || _a === void 0 ? void 0 : _a.sub) || 'stub-user');
        const limit = await this.rl.checkUser('uploads:presign', userId, 5000);
        if (!limit.allowed) {
            this.presignBlockedCounter.labels('rate_limit').inc();
            return { status: 'blocked', remainingMs: limit.remainingMs, scope: 'user' };
        }
        const sanitized = (body.filename || 'upload')
            .replace(/[\\\/]+/g, '_')
            .replace(/[^A-Za-z0-9._-]/g, '_')
            .slice(0, 128);
        this.presignCounter.inc();
        try {
            const endpoint = process.env.S3_ENDPOINT || 'http://localhost:9000';
            const bucket = process.env.S3_BUCKET || 'uploads';
            const u = new URL(endpoint);
            const client = new minio_1.Client({
                endPoint: u.hostname,
                port: parseInt(u.port || '80', 10),
                useSSL: u.protocol === 'https:',
                accessKey: process.env.S3_ACCESS_KEY || '',
                secretKey: process.env.S3_SECRET_KEY || '',
            });
            return client.bucketExists(bucket).then(exists => {
                if (!exists)
                    return client.makeBucket(bucket, '');
            }).then(async () => {
                if ((process.env.UPLOAD_MODE || '').toLowerCase() === 'post') {
                    const policy = new minio_1.PostPolicy();
                    policy.setBucket(bucket);
                    policy.setKey(sanitized);
                    policy.setExpires(new Date(Date.now() + 10 * 60 * 1000));
                    policy.setContentType(ct);
                    policy.setContentLengthRange(1, 5 * 1024 * 1024);
                    const form = await client.presignedPostPolicy(policy);
                    const postUrl = `${endpoint}/${bucket}`;
                    return { method: 'POST', postUrl, fields: form, objectUrl: `${endpoint}/${bucket}/${encodeURIComponent(sanitized)}` };
                }
                else {
                    const p = await client.presignedPutObject(bucket, sanitized, 60 * 10);
                    return { uploadUrl: p, method: 'PUT', headers: { 'Content-Type': ct } };
                }
            }).catch(() => {
                const url = `${endpoint}/${bucket}/${encodeURIComponent(sanitized)}?content-type=${encodeURIComponent(ct)}&stub=true`;
                return { uploadUrl: url, method: 'PUT', headers: { 'Content-Type': ct } };
            });
        }
        catch {
            const endpoint = process.env.S3_ENDPOINT || 'http://localhost:9000';
            const bucket = process.env.S3_BUCKET || 'uploads';
            const url = `${endpoint}/${bucket}/${encodeURIComponent(sanitized)}?content-type=${encodeURIComponent(ct)}&stub=true`;
            return { uploadUrl: url, method: 'PUT', headers: { 'Content-Type': ct } };
        }
    }
};
exports.StorageController = StorageController;
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], StorageController.prototype, "getPresigned", null);
exports.StorageController = StorageController = __decorate([
    (0, common_1.Controller)('uploads'),
    __metadata("design:paramtypes", [rate_limit_service_1.RateLimitService])
], StorageController);
//# sourceMappingURL=storage.controller.js.map