import { PrismaClient } from '@prisma/client';

async function run() {
  const prisma = new PrismaClient();
  await prisma.$connect();
  const room = await prisma.room.upsert({
    where: { id: 'general' },
    update: {},
    create: { id: 'general', name: 'Geral', description: 'Sala pública geral', rulesJson: { intervalGlobalSeconds: 3 }, silenced: false },
  });
  console.log('Seeded room', room);
  await prisma.$disconnect();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});

