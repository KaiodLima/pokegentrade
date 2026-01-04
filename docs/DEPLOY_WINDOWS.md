# Guia de Deploy (Windows)

## Pré-requisitos
- Node.js 18+ e npm
- Flutter (para frontend)
- PostgreSQL (porta 5432) e um banco vazio `poketibia`
- Redis (porta 6379) para funções de presença e contadores (opcional mas recomendado)
- Storage S3/MinIO opcional para uploads (endpoint configurável)

## Backend (NestJS)
1. Configurar variáveis em `backend/.env`:
   - `DATABASE_URL=postgresql://<usuario>:<senha>@localhost:5432/poketibia`
   - `JWT_SECRET`, `JWT_REFRESH_SECRET` (defina valores seguros)
   - `REDIS_HOST=localhost`, `REDIS_PORT=6379`
   - `PORT=3000`
2. Instalar dependências:
   - `cd backend`
   - `npm install`
3. Gerar Prisma Client e sincronizar schema:
   - `npm exec prisma generate`
   - `npm exec prisma db push`
4. Iniciar servidor (dev):
   - `npm run start:dev`
   - Verifique saúde: `http://localhost:3000/health` deve retornar 200

## Banco de Dados PostgreSQL
- Se já instalado: garanta que o serviço está ativo e acessível em `localhost:5432`.
- Via Docker:
  - `docker run --name poketibia-pg -e POSTGRES_USER=poketibia -e POSTGRES_PASSWORD=changeme -e POSTGRES_DB=poketibia -p 5432:5432 -d postgres:15`
- Após subir, rode `npm exec prisma db push` no backend para aplicar o schema.

## Redis
- Via Docker:
  - `docker run --name poketibia-redis -p 6379:6379 -d redis:7`
- Opcional, mas recomendado para contadores de não lidas, presença e cache leve.

## Storage (MinIO opcional)
- Configure `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY` no ambiente se usar uploads com validação de objeto.
- Caso não use MinIO, uploads via URLs pré-assinadas continuam funcionando; ver endpoints `/uploads`.

## Frontend (Flutter)
1. Instalar dependências:
   - `cd frontend`
   - `flutter pub get`
2. Analisar e rodar:
   - `flutter analyze`
   - `flutter run -d chrome` (Web) ou `flutter run -d windows` (app desktop)
3. Ajuste de endpoint:
   - O socket DM usa `http://localhost:3000` por padrão; parametrizar se for outro host.

## Observações de Produção
- Habilitar CORS conforme necessário no backend.
- Usar segredos fortes e não versionar `.env`.
- Configurar logs e métricas (Prometheus em `/metrics`).
- Atualizar Prisma conforme versão (seguir guia de upgrade).

## Troubleshooting
- Porta 5432 inacessível: verifique serviço do PostgreSQL/Docker.
- Redis inativo: iniciar container ou serviço local.
- Erros de upload: confira tipos permitidos e tamanho máximo (5MB).
