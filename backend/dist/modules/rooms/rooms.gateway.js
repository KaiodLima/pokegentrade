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
exports.RoomsGateway = void 0;
const common_1 = require("@nestjs/common");
const websockets_1 = require("@nestjs/websockets");
const socket_io_1 = require("socket.io");
const auth_guard_1 = require("../../common/auth.guard");
const rate_limit_service_1 = require("../rate-limit/rate-limit.service");
const rooms_service_1 = require("./rooms.service");
const prisma_service_1 = require("../prisma/prisma.service");
const jwt_service_1 = require("../../common/jwt.service");
const presence_service_1 = require("../presence/presence.service");
const prom = require('prom-client');
const metrics_controller_1 = require("../metrics/metrics.controller");
let RoomsGateway = class RoomsGateway {
    constructor(rl, rooms, jwt, presence, prisma) {
        this.rl = rl;
        this.rooms = rooms;
        this.jwt = jwt;
        this.presence = presence;
        this.prisma = prisma;
        this.msgCounter = new prom.Counter({ name: 'poketibia_socket_messages_total', help: 'Socket messages', labelNames: ['roomId'], registers: [metrics_controller_1.metricsRegistry] });
        this.rlErrorCounter = new prom.Counter({ name: 'poketibia_socket_rate_limit_errors_total', help: 'Socket rate limit errors', labelNames: ['roomId'], registers: [metrics_controller_1.metricsRegistry] });
    }
    async handleConnection(client) {
        var _a, _b;
        const token = ((_a = client.handshake.auth) === null || _a === void 0 ? void 0 : _a.token) || ((_b = client.handshake.query) === null || _b === void 0 ? void 0 : _b.token);
        if (!token)
            return client.disconnect();
        const payload = this.jwt.verifyAccess(token);
        if (!payload || payload.status === 'suspensa')
            return client.disconnect();
        client.userId = payload.sub;
        client.displayName = payload.name || '';
        this.presence.add(client.userId);
        client.join(`user:${client.userId}`);
    }
    async handleJoin(data, client) {
        const room = await this.rooms.get(data.roomId);
        if (!room || room.rules.silenced) {
            client.emit('rooms:rate_limit:error', { remaining_ms: 0 });
            return;
        }
        client.join(data.roomId);
        client.emit('rooms:joined', { roomId: data.roomId });
    }
    async handleMessage(data, client) {
        var _a, _b, _c;
        const room = await this.rooms.get(data.roomId);
        if (!room || room.rules.silenced)
            return;
        const globalIntervalMs = (room.rules.intervalGlobalSeconds || 3) * 1000;
        const perUserIntervalMs = (room.rules.perUserSeconds || 0) * 1000;
        const g = await this.rl.checkGlobal(data.roomId, globalIntervalMs);
        if (!g.allowed) {
            client.emit('rooms:rate_limit:error', { remaining_ms: g.remainingMs });
            this.rlErrorCounter.labels(data.roomId).inc();
            return;
        }
        if (perUserIntervalMs > 0) {
            const u = await this.rl.checkUser(data.roomId, client.userId || client.id, perUserIntervalMs);
            if (!u.allowed) {
                client.emit('rooms:rate_limit:error', { remaining_ms: u.remainingMs });
                this.rlErrorCounter.labels(data.roomId).inc();
                return;
            }
        }
        const createdAt = new Date();
        let id = '';
        try {
            const row = await this.prisma.message.create({
                data: { roomId: data.roomId, content: data.content, userId: (client.userId || null), createdAt },
            });
            id = (_c = (_b = (_a = row.id) === null || _a === void 0 ? void 0 : _a.toString) === null || _b === void 0 ? void 0 : _b.call(_a)) !== null && _c !== void 0 ? _c : '';
        }
        catch {
            id = `${createdAt.toISOString()}:${client.userId || client.id}`;
        }
        this.server.to(data.roomId).emit('rooms:message:new', {
            roomId: data.roomId,
            content: data.content,
            userId: client.userId || client.id,
            displayName: client.displayName || '',
            createdAt: createdAt.toISOString(),
            id,
        });
        this.msgCounter.labels(data.roomId).inc();
    }
    async handleTyping(data, client) {
        this.server.to(data.roomId).emit('rooms:typing', { displayName: client.displayName || 'Usuário' });
    }
    async handleEdit(data, client) {
        if (!data.roomId || !data.id || !data.content)
            return;
        const idx = data.id.lastIndexOf(':');
        const owner = idx >= 0 ? data.id.substring(idx + 1) : '';
        if (owner !== (client.userId || client.id))
            return;
        try {
            await this.prisma.message.update({ where: { id: data.id }, data: { content: data.content } });
        }
        catch { }
        this.server.to(data.roomId).emit('rooms:message:edit', { id: data.id, content: data.content });
        client.emit('rooms:message:edit', { id: data.id, content: data.content });
    }
    async handleDelete(data, client) {
        if (!data.roomId || !data.id)
            return;
        const idx = data.id.lastIndexOf(':');
        const owner = idx >= 0 ? data.id.substring(idx + 1) : '';
        if (owner !== (client.userId || client.id))
            return;
        try {
            await this.prisma.message.delete({ where: { id: data.id } });
        }
        catch { }
        this.server.to(data.roomId).emit('rooms:message:delete', { id: data.id });
        client.emit('rooms:message:delete', { id: data.id });
    }
    async handleRead(data, client) {
        try {
            await this.rooms.markRead(client.userId || client.id, data.roomId);
            const counts = await this.rooms.unreadCounts(client.userId || client.id);
            this.server.to(`user:${client.userId || client.id}`).emit('rooms:unread:update', counts);
        }
        catch { }
    }
    async handleDisconnect(client) {
        const uid = client.userId;
        if (uid)
            this.presence.remove(uid);
    }
};
exports.RoomsGateway = RoomsGateway;
__decorate([
    (0, websockets_1.WebSocketServer)(),
    __metadata("design:type", socket_io_1.Server)
], RoomsGateway.prototype, "server", void 0);
__decorate([
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    (0, websockets_1.SubscribeMessage)('rooms:join'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], RoomsGateway.prototype, "handleJoin", null);
__decorate([
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    (0, websockets_1.SubscribeMessage)('rooms:message:send'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], RoomsGateway.prototype, "handleMessage", null);
__decorate([
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    (0, websockets_1.SubscribeMessage)('rooms:typing'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], RoomsGateway.prototype, "handleTyping", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('rooms:message:edit'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], RoomsGateway.prototype, "handleEdit", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('rooms:message:delete'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], RoomsGateway.prototype, "handleDelete", null);
__decorate([
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    (0, websockets_1.SubscribeMessage)('rooms:read'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], RoomsGateway.prototype, "handleRead", null);
exports.RoomsGateway = RoomsGateway = __decorate([
    (0, websockets_1.WebSocketGateway)({ cors: { origin: true } }),
    __metadata("design:paramtypes", [rate_limit_service_1.RateLimitService, rooms_service_1.RoomsService, jwt_service_1.JwtService, presence_service_1.PresenceService, prisma_service_1.PrismaService])
], RoomsGateway);
//# sourceMappingURL=rooms.gateway.js.map