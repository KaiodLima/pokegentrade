**Visão Geral**

* Plataforma web independente para comunicação, anúncios e negociações, sem qualquer vínculo oficial com jogos.

* Perfis de usuário, reputação administrada, chats públicos e privados, marketplace moderado, auditoria.

* Papéis: `User` e `Admin`. Estados de conta: `ativa`, `silenciada`, `suspensa`.

**Arquitetura**

* Frontend: Flutter Web.

* Backend: NestJS (REST + WebSocket/Socket.IO).

* Banco: PostgreSQL.

* Cache/Rate limit: Redis.

* Armazenamento de arquivos: S3-compatible (MinIO/AWS S3).

* Autenticação: JWT Access + Refresh Token.

* Infra: Docker Compose para dev; implantação em VPS/Cloud com Nginx e TLS.

**Módulos Backend (NestJS)**

* `AuthModule`: registro, login, refresh, controle de papéis/estados.

* `UsersModule`: perfis, status, histórico de negociações e pontuação.

* `RoomsModule`: salas públicas (CRUD admin, silenciar, regras).

* `MessagesModule`: mensagens de sala, rate limit por sala/usuário.

* `PrivateChatModule`: conversas 1x1, histórico auditável.

* `MarketplaceModule`: anúncios, aprovação admin, fluxo de status.

* `TrustModule`: solicitações, validações, atribuição de pontuação.

* `ModerationModule`: ações admin em usuários/mensagens/salas.

* `StorageModule`: uploads (provas), integração S3.

* `AuditModule`: logs administrativos e trilhas de auditoria.

* `RateLimitModule`: políticas, chaves Redis, middleware/guard.

**Modelo de Dados (PostgreSQL)**

* `users`: id, email, hash\_senha, nome\_exibicao, data\_cadastro, papel, status, pontuacao\_confianca.

* `rooms`: id, nome, descricao, regras\_json, silenciada, created\_by.

* `room_user_rules`: room\_id, user\_id, intervalo\_segundos.

* `messages`: id, room\_id, user\_id, conteudo, criado\_em, apagado\_em, apagado\_por.

* `private_conversations`: id, user\_a\_id, user\_b\_id, criada\_em.

* `private_messages`: id, conversation\_id, sender\_id, conteudo, criada\_em, apagado\_em.

* `ads`: id, autor\_id, tipo, titulo, descricao, preço\_opcional, status, criado\_em, aprovado\_por.

* `ad_attachments`: id, ad\_id, url, tipo, meta.

* `trust_requests`: id, user\_id, status, justificativa, prova\_url, analisado\_por, criado\_em.

* `trust_scores_history`: id, user\_id, pontuacao\_delta, motivo, atribuido\_por, criado\_em.

* `moderation_actions`: id, admin\_id, alvo\_tipo, alvo\_id, ação, motivo, criado\_em.

* Índices por `room_id`, `user_id`, `created_at` em tabelas de mensagens e anúncios.

**API REST (principais endpoints)**

* `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`.

* `GET /users/me`, `PATCH /users/me`.

* `GET /rooms`, `POST /rooms` (admin), `PATCH /rooms/:id` (admin), `DELETE /rooms/:id` (admin).

* `GET /rooms/:id/messages?after=<cursor>`.

* `POST /moderation/users/:id/mute` (escopo global/sala), `POST /moderation/users/:id/suspend`.

* `GET /marketplace/ads`, `POST /marketplace/ads` (pendente), `PATCH /marketplace/ads/:id` (admin), `POST /marketplace/ads/:id/approve` (admin), `POST /marketplace/ads/:id/complete`.

* `POST /trust/requests`, `GET /trust/requests` (admin), `POST /trust/requests/:id/validate` (admin), `POST /trust/scores/:userId/apply` (admin).

* `POST /uploads` → retorna URL S3 assinada; consome via `PUT` direto no S3.

**WebSocket (Socket.IO) — Eventos**

* Conexão autenticada via `JWT` (handshake).

* Público: `rooms:list`, `rooms:join`, `rooms:leave`, `rooms:message:send`.

* Server → Client: `rooms:message:new`, `rooms:rate_limit:error {remaining_ms}`, `rooms:silenced`, `moderation:user_muted`.

* Privado: `pm:start`, `pm:message:send`, `pm:message:new`.

**Rate Limit**

* Estratégia: janela deslizante com Redis.

* Chaves: `rl:room:{roomId}:global`, `rl:room:{roomId}:user:{userId}`.

* Parametrização: por sala (global) e por usuário em sala.

* Guards: bloqueiam envio e retornam tempo restante; respeitam silenciar sala/usuário.

**Marketplace**

* Tipos: troca, venda, serviço.

* Fluxos: criação (pendente), aprovação admin, edição/suspensão/exclusão, conclusão.

* Anexos: comprovantes, imagens (validação de tipo/tamanho), armazenados no S3.

**Sistema de Confiança**

* Usuário abre solicitação com comprovação.

* Admin analisa, valida, aplica pontuação (delta) e registra em histórico.

* Pontuação influencia visibilidade (ex.: destaque em anúncios) e perfil público.

**Moderação e Auditoria**

* Silenciar sala (bloqueio total), silenciar usuário (global/sala), suspender/excluir contas.

* Excluir mensagens individuais ou limpar histórico de sala (opcional, controlado).

* Acesso a conversas privadas para auditoria; logs detalhados de ações admin.

**Segurança e Conformidade**

* Senhas com Argon2; JWT curto + refresh; revogação via blacklist Redis.

* Validação e sanitização de entradas; tamanho máximo de mensagem/anúncio; anti-spam.

* Não afiliação: aviso legal visível em `footer` e página de termos.

* Rate limit em HTTP e WS; CORS restrito; TLS em produção.

**Frontend (Flutter Web) — Páginas**

* Autenticação: Login, Cadastro.

* Salas: lista, chat, feedback de rate limit.

* Privado: inbox, conversa 1x1, histórico.

* Marketplace: listagem, filtros, detalhe, criação/edição.

* Perfil: dados, histórico de negociações, pontuação, status.

* Admin: gestão de salas, moderação, anúncios, confiança, auditoria.

**Implantação**

* `docker-compose` com `postgres`, `redis`, `minio`, `backend`, `frontend`.

* Reverse proxy `nginx` com `wss` e `tls`.

* Variáveis de ambiente segregadas; logs centralizados.

**Observabilidade**

* Logs estruturados (JSON), trilhas de auditoria, métricas básicas (rate limit hits, mensagens/minuto, erros).

* Alertas para picos de flood, falhas de autenticação e exceções.

**Roadmap de Entrega (Fases)**

* Fase 1: Autenticação, usuários, aviso legal, salas e mensagens básicas com rate limit global.

* Fase 2: Rate limit por usuário/sala, moderação de usuários/mensagens, audit logs.

* Fase 3: Marketplace com aprovação admin e anexos S3.

* Fase 4: Chat privado auditável e sistema de confiança.

* Fase 5: Painéis admin completos, métricas e hardening de segurança.

**Critérios de Aceite**

* Envio bloqueado e feedback de tempo restante conforme regras por sala/usuário.

* Aprovação obrigatória de anúncios de usuários; admins podem criar/auto-aprovar.

* Conversas privadas auditáveis; histórico preservado conforme política.

* Pontuação de confiança só atribuída por admin, com histórico rastreável.

* Aviso legal explícito e ausência de qualquer referência técnica/visual ao jogo.

**Próximo Passo**

* Após aprovação do plano, preparo dos templates de projeto (NestJS + Flutter), esquemas de base, e `docker-compose` para desenvolvimento.

