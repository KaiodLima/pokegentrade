import 'reflect-metadata';
import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
const prom = require('prom-client');
import { metricsRegistry } from './modules/metrics/metrics.controller';
import { randomUUID } from 'crypto';
import settings from './settings';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  const corsOrigin = settings.CORS_ORIGIN;
  app.enableCors({ origin: corsOrigin, credentials: true });
  prom.collectDefaultMetrics({ register: metricsRegistry, prefix: 'poketibia_' });
  const httpReqCounter = new prom.Counter({ name: 'poketibia_http_requests_total', help: 'HTTP requests', labelNames: ['method', 'path', 'status'], registers: [metricsRegistry] });
  app.use((req: any, res: any, next: any) => {
    const reqId = req.headers['x-request-id'] || randomUUID();
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

  const port = settings.PORT;
  await app.listen(port);
  // Log explícito para pré-visualização
  console.log(`http://localhost:${port}/health`);
}
bootstrap();
