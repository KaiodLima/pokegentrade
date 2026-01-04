"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DmModule = void 0;
const common_1 = require("@nestjs/common");
const dm_gateway_1 = require("./dm.gateway");
const jwt_service_1 = require("../../common/jwt.service");
const dm_service_1 = require("./dm.service");
const dm_controller_1 = require("./dm.controller");
let DmModule = class DmModule {
};
exports.DmModule = DmModule;
exports.DmModule = DmModule = __decorate([
    (0, common_1.Module)({
        providers: [dm_gateway_1.DmGateway, jwt_service_1.JwtService, dm_service_1.DmService],
        controllers: [dm_controller_1.DmController],
    })
], DmModule);
//# sourceMappingURL=dm.module.js.map