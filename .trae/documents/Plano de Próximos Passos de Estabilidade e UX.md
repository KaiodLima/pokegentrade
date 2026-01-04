## Estado de Conexão
- Unificar exibição de estado com `StatusBanner` em todas as telas HTTP
- Adicionar contador de tentativas de reconexão e limite configurável
- Implementar backoff exponencial customizado para socket quando `reconnect_failed`

## UX de Envio & Rate Limit
- Padronizar guardas de envio em todas as telas com feedback de “Enviando…”
- Tratar `rate_limit` com retry e tempo de espera visível (ms → s com contagem regressiva)
- Desabilitar campos de texto durante bloqueio temporário

## Cache & Preferências
- Expandir `MeCache` e `UserCache` para avatar/status com TTLs distintos
- Invalidar cache por eventos (ex.: após salvar perfil ou receber mensagem nova)
- Persistir preferências (ordenação, filtros) em `SharedPreferences`

## Inbox & Contatos
- Toggle “Mostrar apenas não lidas” e ordenação escolhida pelo usuário
- Paginação incremental na Inbox para listas grandes
- Ação de marcar todas como lidas e feedback de sucesso

## Marketplace Uploads
- Retry com backoff e limite de tentativas por arquivo
- Indicador de progresso por arquivo e resumo final com erros/sucessos
- Validação de tipos e tamanhos antes de solicitar URL de upload

## API & Erros de Rede
- Padronizar códigos internos (ex.: 599) em um enum de erros de rede
- Requisições críticas com cancelamento e timeout ajustável por tela
- Reexecução segura pós-refresh com preservação de corpo e headers

## Telemetria & Logs
- Contadores de cache hits/misses, tempo de resposta e taxas de erro (dev-only)
- Logs mínimos e anônimos para reconexões e rate limits
- Painel simples de diagnóstico acessível via “Perfil → Diagnóstico”

## Testes & Validação
- Testes de unidade: `Api` timeouts/refresh; caches TTL e invalidação
- Testes de widget: banners, botões desabilitados, persistências
- Testes e2e (Flutter integration): reconexão socket, retry uploads, Inbox filtros

## Segurança
- Reduzir superfícies de logs; nunca logar tokens
- Sanitização de inputs (título/descrição marketplace, mensagens)

## Performance
- Debounces consistentes (typing, persistência de busca) e limites de taxa de polling
- Virtualização de listas quando necessário, com `ListView.builder` otimizado

Confirma este plano? Posso começar pela padronização de banners e enum de erros de rede, seguida de testes unitários para `Api` e caches.