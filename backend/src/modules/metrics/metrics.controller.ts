import { Controller, Get } from '@nestjs/common';
const prom = require('prom-client');

const registry = new prom.Registry();
export const metricsRegistry = registry;

@Controller('metrics')
export class MetricsController {
  @Get()
  async get() {
    return (await registry.metrics());
  }
}
