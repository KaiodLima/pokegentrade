# Continuação da Implementação

## Objetivo Imediato
- Transformar stubs em funcionalidades reais: autenticação JWT/Refresh com Argon2, persistência em PostgreSQL, gateways WebSocket com regras de rate limit em Redis e primeiros fluxos de frontend (Flutter Web) para login/salas.

## Autenticação (JWT + Refresh + Argon2)
- Implementar cadastro e login persistidos (hash de senha com Argon2).
- Gerar `accessToken` curto e `refreshToken` longo; endpoints `POST /auth/refresh` e `POST /auth/logout` com revogação de refresh via Redis blacklist.
- Middleware/guard de autorização (papéis `User`/`Admin`) e checagem de status de conta (`ativa`, `silenciada`, `suspensa`).
- Critérios de aceite:
  - Login/cadastro funcionam com tokens válidos.
  - Rotas protegidas negam acesso sem token ou com conta suspensa.

## Persistência (PostgreSQL)
- Integrar ORM (Prisma ou TypeORM) ao NestJS.
- Mapear e migrar tabelas: `users`, `rooms`, `messages` (já no schema inicial), expandindo com relações e validações.
- Reescrever controladores para usar serviços que persistem/consultam dados.
- Critérios de aceite:
  - `GET /rooms` e `GET /rooms/:id/messages` retornam dados do banco.
  - `POST /auth/register` cria usuário real; `POST /auth/login` autentica contra hash.

## WebSocket (Socket.IO) e Salas Públicas
- Criar `RoomsGateway` com autenticação via JWT no handshake.
- Eventos: `rooms:list`, `rooms:join`, `rooms:leave`, `rooms:message:send`; broadcast `rooms:message:new`.
- Persistir mensagens recebidas e entregar histórico incremental por cursor.
- Critérios de aceite:
  - Usuário conectado recebe mensagens em tempo real e histórico ao entrar na sala.

## Rate Limit (Redis)
- Implementar guard de rate limit com chaves `rl:room:{roomId}:global` e `rl:room:{roomId}:user:{userId}`.
- Parametrização por sala e por usuário; bloqueio retorna `remaining_ms` via evento/HTTP.
- Considerar estado de sala `silenciada` e usuário `silenciado` global ou por sala.
- Critérios de aceite:
  - Tentativas fora do tempo são bloqueadas com feedback claro.

## Frontend (Flutter Web) — Primeiros Fluxos
- Configurar projeto Flutter Web e tema básico.
- Páginas: Login/Cadastro, Lista de Salas, Chat de Sala com feedback de bloqueio.
- Integração com REST e Socket.IO (via pacote JS bridge ou lib compatível).
- Critérios de aceite:
  - Usuário consegue autenticar, ver salas e enviar mensagens respeitando rate limit.

## Marketplace (Estrutura Inicial)
- Definir modelo `ads` e `ad_attachments`; endpoints de criação (pendente), listagem e aprovação admin.
- Sem UI ainda; validar fluxo API (pendente → aprovado/suspenso/excluído).
- Critérios de aceite:
  - Anúncios de usuários comuns ficam pendentes; admins aprovam.

## Moderação e Auditoria (Primeiros Controles)
- Endpoints para silenciar sala, silenciar usuário (global/sala), suspender/excluir contas.
- Registrar `moderation_actions` e trilha de auditoria.
- Critérios de aceite:
  - Ações de moderação persistem e impactam envio de mensagens.

## Sistema de Confiança (Base)
- Modelos `trust_requests` e `trust_scores_history`.
- Endpoints para solicitação de avaliação, validação admin e aplicação de pontuação.
- Critérios de aceite:
  - Somente admin consegue atribuir pontuação; histórico registrado.

## Legal e Segurança
- Aviso de não afiliação no frontend (footer) e rota de termos.
- Sanitização/validação global; limites de tamanho de mensagens/anúncios.
- CORS restrito e preparo para TLS em produção.

## Observabilidade
- Logs estruturados e métricas mínimas (rate limit hits, mensagens/minuto, falhas de login).

## Validação
- Testes manuais: fluxo de autenticação, envio de mensagens e bloqueios.
- Testes automatizados prioritários: serviços de auth, rate limit e rooms.

## Entregáveis da Próxima Iteração
- Auth real, persistência de usuários/salas/mensagens, WebSocket em produção de dev, Rate Limit funcional, UI Flutter para login/salas.

## Riscos e Mitigações
- Integração Flutter com Socket.IO: avaliar pacote e fallback via canal JS.
- Escalabilidade de rate limit: usar janela deslizante e ajustar TTLs no Redis.
- Auditoria de privado: definir políticas de retenção e acesso admin explícito.