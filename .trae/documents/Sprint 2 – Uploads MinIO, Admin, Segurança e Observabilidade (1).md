## Infraestrutura
- Subir `postgres`, `redis` e `minio` via Docker Compose.
- Executar `npx prisma generate` e `npx prisma db push`; aplicar seeds de desenvolvimento.

## Uploads MinIO (Pré‑assinadas reais)
- Substituir stub em `StorageController` por geração de URL pré‑assinada (PUT) via SDK do MinIO, com expiração e cabeçalhos corretos.
- Validar tipo/tamanho e registrar metadados; salvar anexos (`AdAttachment`).

## DMs e Salas (UX)
- Consolidar `readAt` com Prisma; validar contadores e marcação de lido.
- Paginação infinita em salas e indicadores de typing estáveis.
- Badges globais de não lidos no AppBar.

## Admin e Moderação
- Painel Admin completo: aprovação/filtragem de anúncios e visualização de anexos.
- Moderar salas: silenciar, suspender usuários; auditoria.

## Segurança
- Rate limit HTTP por rota/usuário; validação de payloads e CORS estrito.
- Refresh tokens com rotação/revogação; verificação de e‑mail.

## Observabilidade
- Logs estruturados (request‑id, user‑id), métricas Prometheus e tracing básico.

## Testes
- Unitários, integração e E2E para uploads, marketplace, DMs e salas.

Confirma que posso iniciar agora conforme este plano?