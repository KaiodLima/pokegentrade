import { PrismaClient } from '@prisma/client'
import argon2 from 'argon2'

async function run() {
  const prisma = new PrismaClient()
  await prisma.$connect()
  const email = process.env.ADMIN_EMAIL || 'admin@poketibia.local'
  const password = process.env.ADMIN_PASSWORD || 'ChangeMe!123'
  const name = process.env.ADMIN_NAME || 'Super Admin'
  const existing = await prisma.user.findUnique({ where: { email } })
  if (!existing) {
    const hash = await argon2.hash(password)
    await prisma.user.create({ data: { email, passwordHash: hash, displayName: name, role: 'SuperAdmin', status: 'ativa' } })
    console.log('Seeded SuperAdmin', email)
  } else {
    if ((existing as any).role !== 'SuperAdmin') {
      await prisma.user.update({ where: { id: existing.id }, data: { role: 'SuperAdmin' } })
      console.log('Elevated existing admin to SuperAdmin', email)
    }
  }
  const general = await prisma.room.findFirst({ where: { name: 'Geral' } })
  if (!general) {
    await prisma.room.create({ data: { name: 'Geral', description: 'Sala pública geral', rulesJson: { intervalGlobalSeconds: 3, perUserSeconds: 0, silenced: false } as any, silenced: false } })
    console.log('Seeded room Geral')
  }
  const firstNews = await prisma.news.findFirst()
  if (!firstNews) {
    await prisma.news.create({ data: { title: 'Bem-vindo à comunidade', content: 'Este é o mural de notícias da plataforma Poketibia.', authorId: (existing?.id || null), attachments: [] } })
    console.log('Seeded initial news')
  }
  await prisma.$disconnect()
}

run().catch(e => { console.error(e); process.exit(1) })
