## Infraestrutura
- Subir `postgres`, `redis` e `minio` com Docker Compose.
- Executar `npx prisma generate` e `npx prisma db push`; criar seeds de desenvolvimento.
- Confirmar variáveis `.env` (DB/Redis/S3) e healthchecks.

## Uploads MinIO (Pré‑assinadas reais)
- Backend: substituir stub em `StorageController` por geração de URL pré‑assinada (PUT) via SDK do MinIO, com expiração e cabeçalhos corretos.
- Validações: tipo/tamanho permitido; rejeitar extensões perigosas; registrar metadados.
- Marketplace: ao criar anúncio, enviar arquivos para URL pré‑assinada e salvar anexos (`AdAttachment`); detalhe do anúncio lista anexos.

## DMs e Salas (UX)
- Consolidar `readAt` no Prisma e validar contadores/`markRead`.
- Salas: paginação infinita (carregar mais ao rolar) e indicadores de typing estáveis.
- Badges globais: centralizar cálculo de não lidos no AppBar.

## Admin e Moderação
- Painel Admin completo: aprovação/filtragem de anúncios e visualização de anexos.
- Moderar salas: silenciar, suspender usuários; logs de auditoria.
- Guards por papel (`User/Admin`) refletidos na UI/backend.

## Segurança
- Rate limit HTTP por rota/usuário; limites especiais em uploads e criação de anúncios.
- Validação de payloads (schemas), sanitização e CORS estrito; preparar TLS.
- Refresh tokens com rotação/revogação; verificação de e‑mail.

## Observabilidade
- Logs estruturados (request‑id, user‑id), métricas Prometheus e tracing básico.
- Telemetria de eventos de socket, latência de uploads e erros de API.

## Testes
- Unitários e integração: auth, salas, DMs (unread/markRead), marketplace e uploads.
- E2E: criação de anúncio com anexos, aprovação/Admin e consumo no Flutter.

Confirma que devo começar a implementação conforme este plano?