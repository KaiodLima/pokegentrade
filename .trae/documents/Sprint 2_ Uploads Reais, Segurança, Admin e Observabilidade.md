## Infraestrutura
- Subir `postgres`, `redis`, `minio` com Docker Compose e healthchecks.
- Executar `npx prisma generate` e `npx prisma db push`; criar seeds de desenvolvimento.

## Uploads MinIO (Pré-assinadas reais)
- Backend (`backend/src/modules/storage/storage.controller.ts`): substituir stub por geração de URL pré-assinada (PUT) usando SDK do MinIO, com expiração e cabeçalhos corretos.
- Validações: tipo/tamanho permitidos; rejeitar extensões perigosas; registrar metadados.
- Marketplace: anexos gravados em `AdAttachment` e exibidos em detalhe.

## DMs e Salas (UX e Estado)
- Consolidar `readAt` no Prisma para DMs e confirmar contadores/markRead.
- Salas: paginação infinita (carregar mais ao rolar) e indicadores de typing.
- Badges globais de não lidos na AppBar e nas entradas de navegação.

## Admin e Moderação
- Painel Admin completo: aprovação de anúncios, visualização de anexos, filtros por status.
- Moderar salas: silenciar, suspender usuários; logs de auditoria.
- Guards por papel (`User/Admin`) refletidos na UI e no backend.

## Segurança
- Rate limit HTTP por rota/usuário; limites específicos em uploads e criação de anúncios.
- Validação de payloads (schemas), sanitização e CORS estrito; preparar TLS.
- Refresh tokens com rotação e revogação; verificação de e-mail e reset de senha básico.

## Observabilidade
- Logs estruturados (request-id, user-id), métricas Prometheus e tracing básico.
- Telemetria para eventos de socket e latência de uploads.

## Testes
- Unitários e integração: auth, salas, DMs (unread/markRead), marketplace, uploads.
- E2E: fluxo completo de criação de anúncio com anexos, aprovação/Admin e consumo no Flutter.

## Entregáveis
- Backend com uploads reais, segurança endurecida e métricas.
- Flutter com páginas Admin, detalhe de anúncio, badges globais, paginação e UX de upload.
- Scripts de validação (`scripts/test-*.js`) e documentação rápida de uso.

## Validação
- `flutter analyze` sem erros; navegação completa: Login → Salas/DM/Inbox → Marketplace (lista/detalhe/anexos) → Admin.
- Testes de backend passam; endpoints de uploads retornam URLs válidas e PUT funciona no MinIO.

Posso iniciar a implementação conforme este plano?