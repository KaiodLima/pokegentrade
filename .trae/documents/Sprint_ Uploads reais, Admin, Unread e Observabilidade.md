## Infra e Prisma
- Subir Postgres/Redis/MinIO com Docker Compose.
- Executar `prisma generate` e `prisma db push`; aplicar seeds de desenvolvimento.

## Uploads (MinIO)
- Implementar pré-assinadas reais (PUT com expiração) via SDK do MinIO.
- Validar tipo/tamanho de arquivo e salvar metadados; anexar em `AdAttachment`.

## DMs e Salas
- Adicionar `readAt` e contadores de não lidos (unread) por par/sala.
- Expor endpoints para unread e marcação como lido.
- Flutter: badges globais e paginação com autocarregamento.

## Marketplace
- Página de detalhes do anúncio com anexos e ações (aprovar, concluir).
- Endpoint `GET /marketplace/ads/:id` com anexos.

## Painel Admin
- UI para moderação e aprovação: silenciar salas, suspender usuários, aprovar anúncios.
- Guards por papel (User/Admin) refletidos na UI e backend.

## Segurança
- Rate limit HTTP por rota/usuário; validação de payloads e sanitização.
- CORS estrito e configuração de TLS (quando aplicável).

## Observabilidade
- Logs estruturados; métricas Prometheus; tracing básico.
- Logs de requisições e eventos de socket.

## Testes
- Unitários e integração para auth, salas, DMs, marketplace e uploads.
- E2E: criar anúncio com anexos e fluxo de aprovação.

Confirma que posso iniciar a implementação deste sprint agora?