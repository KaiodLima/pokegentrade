## Objetivos
- Persistir usuários/salas/mensagens no Postgres e remover stubs in-memory.
- Adicionar rate limit com Redis (global de sala e por usuário) com TTLs.
- Entregar telas iniciais em Flutter Web: Login, Cadastro, Lista de Salas e Chat com feedback de bloqueio.
- Implementar base do Marketplace (CRUD e aprovação admin) e primeiras ações de moderação.

## Backend — Persistência e Autenticação
- Integrar ORM (Prisma ou TypeORM) e configurar migrations a partir do schema (users, rooms, messages, ads, attachments, trust, moderation).
- Serviços: `UsersService`, `RoomsService`, `MessagesService` persistentes, com paginação (cursor por `created_at`).
- Autenticação: endpoint `POST /auth/refresh`, `POST /auth/logout` (revogação em Redis), guards de papel (`User`/`Admin`) e checagem de status (`ativa`, `silenciada`, `suspensa`).
- Atualizar `AuthGuard` para extrair usuário do banco e aplicar status dinamicamente.

## WebSocket — Handshake JWT e Eventos
- Autenticar handshake Socket.IO com JWT (validação no servidor).
- Eventos: `rooms:list`, `rooms:join`, `rooms:leave`, `rooms:message:send` (persistir mensagem e broadcast).
- Entregar histórico ao entrar na sala (últimas N mensagens via cursor).

## Rate Limit — Redis
- Implementar janela deslizante com chaves: `rl:room:{roomId}:global` e `rl:room:{roomId}:user:{userId}`.
- TTLs configuráveis, leitura das regras por sala do banco (`intervalGlobalSeconds`, `perUserSeconds`).
- Respeitar `silenced` por sala e silenciar usuário global/sala.

## Marketplace — API Inicial
- Tabelas: `ads` e `ad_attachments` (tipo: troca, venda, serviço; status: pendente/aprovado/suspenso/excluído/concluído).
- Endpoints: listar, criar (pendente), aprovar/suspender/excluir (admin), marcar como concluído.
- Uploads: geração de URL pré-assinada (S3/MinIO) e validação de tipo/tamanho.

## Moderação e Auditoria
- Endpoints: silenciar sala, silenciar usuário (global/sala), suspender/excluir contas; registrar em `moderation_actions`.
- Auditoria: logs estruturados das ações admin, acesso auditável a privado (base preparada, UI futura).

## Frontend — Flutter Web (Primeiros Fluxos)
- Páginas: Login/Cadastro, Lista de Salas, Chat; tema simples e aviso legal fixo.
- Integrações: REST para auth/salas/mensagens e Socket.IO para tempo real; mostrar feedback de bloqueio com contagem regressiva.
- Estrutura de navegação e gerenciamento de tokens (Access/Refresh) com renovação.

## Infra
- Ajustar `docker-compose` para subir backend com Node + hot reload e rede interna com Postgres/Redis/MinIO.
- Variáveis de ambiente e `.env` padronizados; preparar Nginx/TLS para produção (documentação).

## Validação
- Scripts de seed de desenvolvimento (usuários, salas, anúncios fictícios).
- Testes unitários de serviços (auth, rate limit, rooms) e testes de integração mínimos.
- Cenário E2E manual: autenticar → entrar na sala → enviar mensagens → observar bloqueios → criar anúncio pendente → aprovar como admin.

## Entregáveis
- API persistente para auth/salas/mensagens.
- Rate limit com Redis operacional.
- Gateway WebSocket com handshake JWT e broadcast de mensagens.
- Flutter Web com login, cadastro, lista de salas e chat funcional com feedback.
- Endpoints iniciais do marketplace e moderação disponíveis.