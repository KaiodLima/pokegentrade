## Estado Atual
- Autenticação: login/refresh/logout via JWT; recuperação de senha; RBAC HTTP (RoleGuard). WebSocket autenticado no RoomsGateway.
- Chat: salas públicas com histórico REST, socket em tempo real, rate-limit e contadores de não lidas (persistência em memória).
- DM: histórico REST, socket em tempo real, leitura/edição/remoção, rate-limit.
- Marketplace: criação de anúncios, listagem em grid, anexos via upload presign e pagamento simulado (memória/DB) com estados básicos.
- Admin: gestão de usuários (papéis/estado), auditoria com filtros; métricas Prometheus.

## Lacunas Principais
- Autenticação e Contas
  - Verificação de e-mail e entrega real (SMTP), bloqueio por tentativas, políticas de senha.
  - RBAC em WebSocket (equivalente ao RoleGuard) e escopo por sala.
  - Expiração/Revogação de refresh tokens e rotação de chaves JWT.
- Salas (Chat Público)
  - Persistir lastRead e presença em banco/Redis (atual: Map em memória) — backend/src/modules/rooms/rooms.service.ts.
  - Lista de salas com último trecho e timestamp; menções, pin e moderação avançada (silenciar sala/usuário, razões/auditoria).
  - Paginação e busca no histórico; anexos básicos (imagem); anti-spam por conteúdo.
- DM
  - Paginação “before” mais robusta, busca entre DMs, indicadores de entrega/leitura persistentes.
  - Lista de contatos com status online/último visto a partir de PresenceService (persistente/distribuído).
- Marketplace
  - Integração de pagamento real (ex.: Stripe/Pagar.me) com webhooks; antifraude; recibos/notas.
  - Ciclo de vida completo do anúncio (pendente→aprovado→ativo→concluído/suspenso), filtros avançados e paginação.
  - Uploads: redimensionamento/thumb, validação de MIME real, antivírus; remoção do modo stub; credenciais seguras — backend/src/modules/storage/storage.controller.ts.
- Observabilidade e Ops
  - Logs estruturados (correlação de requisições), tracing (OpenTelemetry), dashboards e alertas.
  - Docker Compose (API + DB + MinIO), CI/CD, migrações Prisma, seeds.
- Segurança
  - CORS/CSP refinados, CSRF (para endpoints sensíveis), sanitização extra de entradas, auditoria de permissões.
- Internacionalização e UX
  - Completar chaves i18n e estados vazios; acessibilidade (labels, contraste, navegação por teclado).
- Testes
  - Backend: unit e integração (auth, uploads, marketplace, sockets). Frontend: widget/e2e (Navegação, Chat, Marketplace). 
- Documentação
  - OpenAPI/Swagger, guias de contribuição, configuração de ambientes.

## Plano de Entrega (Resumo)
- Persistência: mover prontuários em memória (presence, lastRead, payments fallback) para Postgres/Redis.
- Marketplace: integrar gateway de pagamento e webhooks; concluir ciclo de vida e filtros; thumbnails nos uploads.
- Chat/DM: lista de salas, busca, anexos, moderação e presença distribuída; métricas de entrega/leitura.
- Segurança/Observabilidade: CORS/CSP, logging/tracing, dashboards de métricas.
- DevOps: Docker Compose, CI/CD, migrações, seeds.
- Testes/Docs: cobertura essencial e documentação navegável.

## Referências de Código
- PaymentsController: backend/src/modules/payments/payments.controller.ts
- PaymentsService (fallback em memória): backend/src/modules/payments/payments.service.ts
- StorageController (uploads presign e stub): backend/src/modules/storage/storage.controller.ts
- RoleGuard (HTTP apenas): backend/src/common/role.guard.ts
- PresenceService (memória): backend/src/modules/presence/presence.service.ts
- Rooms lastRead (memória): backend/src/modules/rooms/rooms.service.ts