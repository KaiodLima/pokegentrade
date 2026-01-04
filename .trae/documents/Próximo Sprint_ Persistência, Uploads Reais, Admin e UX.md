## Objetivos
- Consolidar persistência real (Postgres/Prisma) e uploads pré-assinados (MinIO).
- Ampliar UX: detalhes de Marketplace, anexos, badges de não lidos e paginação.
- Painel Admin para moderação e aprovação de anúncios.
- Segurança e observabilidade para ambiente de produção.

## Infraestrutura
- Subir `postgres`, `redis`, `minio` via Docker Compose.
- Executar `prisma generate` e `prisma db push`; adicionar seeds de desenvolvimento.
- Ajustar mensagens de erro quando `redis` estiver offline (já com fallback) e healthchecks.

## Persistência e APIs
- Mensagens de salas: confirmar gravação com `userId`, índices e paginação por `before/limit` (já iniciado).
- DMs: consolidar `DirectMessage` com paginação, unread count e marcação `readAt`.
- Marketplace: endpoints de detalhe (`GET /marketplace/ads/:id`) e anexos listados.

## Uploads Reais
- Implementar pré-assinadas via MinIO SDK em `StorageController` (PUT com expiração e cabeçalhos corretos).
- Validação de tipo/tamanho e metadados; salvar anexos com `AdAttachment`.

## UX Flutter
- Página de detalhes do anúncio com lista de anexos e ações (aprovar, concluir).
- Badges de não lidos na Inbox e em um AppBar global; contadores por sala/DM.
- Paginação em Chat/DM com “Carregar mais” e autocarregamento ao rolar.

## Admin e Moderação
- Painel Admin web: aprovar anúncios, silenciar salas, suspender usuários, audit log.
- Guards por papel (`User/Admin`) refletidos na UI.

## Segurança
- Rate limit HTTP por rota/usuário.
- Validação de payloads (schemas), sanitização e CORS estrito.
- Refresh tokens com rotação e revogação; verificação de e-mail.

## Observabilidade
- Logger estruturado; métricas Prometheus; tracing básico.
- Logs de requisições e eventos de socket.

## Testes
- Unitários e integração (auth, salas, DMs, marketplace, uploads).
- E2E: fluxo completo de criar anúncio com anexos e aprovar.

Confirma que sigo com este plano para implementar as próximas funcionalidades e melhorias?