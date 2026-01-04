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
exports.DmGateway = void 0;
const websockets_1 = require("@nestjs/websockets");
const socket_io_1 = require("socket.io");
const jwt_service_1 = require("../../common/jwt.service");
const dm_service_1 = require("./dm.service");
const websockets_2 = require("@nestjs/websockets");
const socket_io_2 = require("socket.io");
const prom = require('prom-client');
const metrics_controller_1 = require("../metrics/metrics.controller");
function pairKey(a, b) {
    const s = [a, b].sort();
    return `dm:${s[0]}:${s[1]}`;
}
let DmGateway = class DmGateway {
    constructor(jwt, dm) {
        this.jwt = jwt;
        this.dm = dm;
        this.dmMsgCounter = new prom.Counter({ name: 'poketibia_dm_messages_total', help: 'DM messages', labelNames: ['pair'], registers: [metrics_controller_1.metricsRegistry] });
        this.dmTypingCounter = new prom.Counter({ name: 'poketibia_dm_typing_events_total', help: 'DM typing events', labelNames: ['pair'], registers: [metrics_controller_1.metricsRegistry] });
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
        client.join(`user:${client.userId}`);
    }
    async join(data, client) {
        const uid = client.userId;
        if (!uid || !data.userId)
            return;
        client.join(pairKey(uid, data.userId));
    }
    async send(data, client) {
        const uid = client.userId;
        if (!uid || !data.userId || !data.content)
            return;
        const pair = pairKey(uid, data.userId);
        const createdAt = new Date().toISOString();
        const id = await this.dm.add({ from: uid, to: data.userId, content: data.content, createdAt, displayName: client.displayName || '' });
        const payload = { id, from: uid, to: data.userId, content: data.content, createdAt, displayName: client.displayName || '' };
        client.to(pair).emit('dm:message:new', payload);
        client.emit('dm:message:new', payload);
        this.dmMsgCounter.labels(pair).inc();
        try {
            const counts = await this.dm.unreadCounts(data.userId);
            this.server.to(`user:${data.userId}`).emit('dm:unread:update', counts);
        }
        catch { }
    }
    async typing(data, client) {
        const uid = client.userId;
        if (!uid || !data.userId)
            return;
        const pair = pairKey(uid, data.userId);
        client.to(pair).emit('dm:typing', { displayName: client.displayName || 'Usuário' });
        this.dmTypingCounter.labels(pair).inc();
    }
    async read(data, client) {
        const uid = client.userId;
        if (!uid || !data.userId)
            return;
        const when = new Date().toISOString();
        await this.dm.markRead(uid, data.userId);
        const pair = pairKey(uid, data.userId);
        this.server.to(pair).emit('dm:read', { userId: uid, at: when });
        try {
            const countsMe = await this.dm.unreadCounts(uid);
            const countsPeer = await this.dm.unreadCounts(data.userId);
            this.server.to(`user:${uid}`).emit('dm:unread:update', countsMe);
            this.server.to(`user:${data.userId}`).emit('dm:unread:update', countsPeer);
        }
        catch { }
    }
    async edit(data, client) {
        const uid = client.userId;
        if (!uid || !data.userId || !data.id || !data.content)
            return;
        const ok = await this.dm.edit(uid, data.userId, data.id, data.content);
        if (!ok || ok.ok !== true)
            return;
        const pair = pairKey(uid, data.userId);
        this.server.to(pair).emit('dm:message:edit', { id: data.id, content: data.content });
        client.emit('dm:message:edit', { id: data.id, content: data.content });
    }
    async remove(data, client) {
        const uid = client.userId;
        if (!uid || !data.userId || !data.id)
            return;
        const ok = await this.dm.remove(uid, data.userId, data.id);
        if (!ok || ok.ok !== true)
            return;
        const pair = pairKey(uid, data.userId);
        this.server.to(pair).emit('dm:message:delete', { id: data.id });
        client.emit('dm:message:delete', { id: data.id });
    }
};
exports.DmGateway = DmGateway;
__decorate([
    (0, websockets_2.WebSocketServer)(),
    __metadata("design:type", socket_io_2.Server)
], DmGateway.prototype, "server", void 0);
__decorate([
    (0, websockets_1.SubscribeMessage)('dm:join'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], DmGateway.prototype, "join", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('dm:message:send'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], DmGateway.prototype, "send", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('dm:typing'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], DmGateway.prototype, "typing", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('dm:read'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], DmGateway.prototype, "read", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('dm:message:edit'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], DmGateway.prototype, "edit", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('dm:message:delete'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], DmGateway.prototype, "remove", null);
exports.DmGateway = DmGateway = __decorate([
    (0, websockets_1.WebSocketGateway)({ cors: { origin: true } }),
    __metadata("design:paramtypes", [jwt_service_1.JwtService, dm_service_1.DmService])
], DmGateway);
//# sourceMappingURL=dm.gateway.js.map