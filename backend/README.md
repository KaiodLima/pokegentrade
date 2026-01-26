# Backend (NestJS)

- Servidor NestJS básico com módulos de autenticação, usuários, salas e mensagens (stubs).
- Validação global habilitada e CORS liberado para desenvolvimento.
- Ajuste variáveis em `.env` (baseado em `.env.example`).

## Scripts

- `npm run start:dev` — desenvolvimento com recarga.
- `npm run build` — compila para `dist/`.
- `npm start` — executa build.
 - `npm run seed:db` — executa seed do Prisma (SuperAdmin + sala “Geral”).
 - `npm run test:rooms` — teste e2e básico de envio/lista em salas.
 - `npm run test:dmdb` — teste e2e básico de inbox/unread em DMs.
 - `..\scripts\dev-up.ps1` — setup completo (compose + prisma + seed + api dev).
 - `..\scripts\dev-down.ps1` — encerra serviços.
 - `..\scripts\dev-test.ps1` — executa a bateria de testes E2E.

## Ambiente

- Variáveis principais (ver `.env.example`):
  - DATABASE_URL (Postgres)
  - REDIS_HOST/REDIS_PORT
  - S3_ENDPOINT/S3_ACCESS_KEY/S3_SECRET_KEY/S3_BUCKET
  - JWT_SECRET/JWT_REFRESH_SECRET
  - ADMIN_EMAIL/ADMIN_PASSWORD/ADMIN_NAME

## Health

- `GET /health` retorna `{ status, db, redis, storage }`.

## Sem Docker Compose (fallback)

- Se `docker-compose` não estiver disponível:
  - Suba containers individualmente com Docker:
    - Postgres: `docker run -d --name poketibia-db -e POSTGRES_DB=poketibia -e POSTGRES_USER=poketibia -e POSTGRES_PASSWORD=changeme -p 5420:5432 postgres:16-alpine`
    - Redis: `docker run -d --name poketibia-redis -p 6379:6379 redis:7-alpine`
    - MinIO: `docker run -d --name poketibia-minio -e MINIO_ROOT_USER=changeme -e MINIO_ROOT_PASSWORD=changeme123 -p 9000:9000 -p 9001:9001 minio/minio server /data`
  - Prepare Prisma:
    - `npx prisma generate`
    - `npx prisma db push`
    - `npm run seed:db`
  - API dev:
    - `npm run start:dev`

## Scripts auxiliares

- `..\scripts\prisma-migrate.ps1` — executa `prisma generate`, `prisma migrate dev` e seed.
- `..\scripts\setup-db.ps1` — cria banco/usuário no Postgres local (sem Docker).
- `..\scripts\psql-bootstrap.sql` — script SQL usado pelo setup-db.

## Postgres local sem Docker

1. Instale PostgreSQL 16 (x64) pelo instalador oficial (EDB).
2. Verifique o caminho do psql (ex.: `C:\Program Files\PostgreSQL\16\bin\psql.exe`).
3. Rode:
   - `..\scripts\setup-db.ps1` (informe senha do usuário postgres)
   - Edite `backend/.env` com `DATABASE_URL=postgresql://poketibia:changeme@localhost:5432/poketibia?schema=public`
   - `npx prisma generate` e `npx prisma db push`
   - `npm run seed:db` e `npm run start:dev`
