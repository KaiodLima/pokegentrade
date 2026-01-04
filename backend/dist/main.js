"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("reflect-metadata");
require("dotenv/config");
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const app_module_1 = require("./app.module");
const prom = require('prom-client');
const metrics_controller_1 = require("./modules/metrics/metrics.controller");
const crypto_1 = require("crypto");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    app.useGlobalPipes(new common_1.ValidationPipe({ whitelist: true, transform: true }));
    const corsOrigin = process.env.CORS_ORIGIN ? (process.env.CORS_ORIGIN === 'true' ? true : process.env.CORS_ORIGIN) : true;
    app.enableCors({ origin: corsOrigin, credentials: true });
    prom.collectDefaultMetrics({ register: metrics_controller_1.metricsRegistry, prefix: 'poketibia_' });
    const httpReqCounter = new prom.Counter({ name: 'poketibia_http_requests_total', help: 'HTTP requests', labelNames: ['method', 'path', 'status'], registers: [metrics_controller_1.metricsRegistry] });
    app.use((req, res, next) => {
        const reqId = req.headers['x-request-id'] || (0, crypto_1.randomUUID)();
        res.setHeader('x-request-id', reqId);
        const start = Date.now();
        res.on('finish', () => {
            const ms = Date.now() - start;
            const path = req.originalUrl || req.url;
            const method = req.method;
            httpReqCounter.labels(method, path, String(res.statusCode)).inc();
            console.log(`${method} ${path} ${res.statusCode} ${ms}ms ${reqId}`);
        });
        next();
    });
    const port = process.env.PORT ? Number(process.env.PORT) : 3000;
    await app.listen(port);
    console.log(`http://localhost:${port}/health`);
}
bootstrap();
//# sourceMappingURL=main.js.map