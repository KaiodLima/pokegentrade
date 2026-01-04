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
exports.AuthGuard = void 0;
const common_1 = require("@nestjs/common");
const jwt_service_1 = require("./jwt.service");
let AuthGuard = class AuthGuard {
    constructor(jwt) {
        this.jwt = jwt;
    }
    canActivate(context) {
        var _a, _b, _c, _d;
        if (context.getType() === 'ws') {
            const client = context.switchToWs().getClient();
            const token = ((_b = (_a = client === null || client === void 0 ? void 0 : client.handshake) === null || _a === void 0 ? void 0 : _a.auth) === null || _b === void 0 ? void 0 : _b.token) || ((_d = (_c = client === null || client === void 0 ? void 0 : client.handshake) === null || _c === void 0 ? void 0 : _c.query) === null || _d === void 0 ? void 0 : _d.token) || null;
            if (!token)
                throw new common_1.UnauthorizedException();
            const payload = this.jwt.verifyAccess(token);
            if (!payload)
                throw new common_1.UnauthorizedException();
            if (payload.status === 'suspensa')
                throw new common_1.ForbiddenException();
            client.user = payload;
            return true;
        }
        else {
            const req = context.switchToHttp().getRequest();
            const header = req.headers['authorization'] || '';
            const token = typeof header === 'string' && header.startsWith('Bearer ') ? header.slice(7) : null;
            if (!token)
                throw new common_1.UnauthorizedException();
            const payload = this.jwt.verifyAccess(token);
            if (!payload)
                throw new common_1.UnauthorizedException();
            if (payload.status === 'suspensa')
                throw new common_1.ForbiddenException();
            req.user = payload;
            return true;
        }
    }
};
exports.AuthGuard = AuthGuard;
exports.AuthGuard = AuthGuard = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [jwt_service_1.JwtService])
], AuthGuard);
//# sourceMappingURL=auth.guard.js.map