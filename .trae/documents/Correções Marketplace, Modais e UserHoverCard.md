## Visão Geral
- Endereçar 6 pontos: tamanho do UserHoverCard, filtro de anúncios aprovados no Marketplace, estabilidade da aprovação no admin, cancelamento na edição de usuário, editar via modal nos detalhes do anúncio, padronização de modais.
- Ajustes no frontend (Flutter) e backend (NestJS/Prisma), seguindo padrões existentes e sem alterar fluxos de domínio.

## UserHoverCard menor e responsivo
- Arquivo alvo: [user_hover_card.dart](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/frontend/lib/widgets/user_hover_card.dart).
- Tornar tamanho configurável: adicionar parâmetros opcionais `width`, `maxWidth` e remover `height` fixa para o conteúdo definir a altura.
- Aplicar `ConstrainedBox(BoxConstraints(maxWidth: ...))` e `mainAxisSize: MainAxisSize.min` para respeitar o tamanho.
- Revisar `offset` do `CompositedTransformFollower` para posicionamento consistente em diferentes densidades.
- Verificação: uso em [rooms.dart](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/frontend/lib/pages/rooms.dart#L592-L642) e [rooms.dart](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/frontend/lib/pages/rooms.dart#L658-L707) permanece inalterado; apenas se beneficiará do novo sizing.

## Marketplace: exibir apenas aprovados
- Frontend rápido: em [marketplace_list.dart](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/frontend/lib/pages/marketplace_list.dart#L31-L49), após mapear `ads`, filtrar por `status == 'aprovado'` antes de `setState`.
- Backend robusto: em [marketplace.controller.ts](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/backend/src/modules/marketplace/marketplace.controller.ts#L51-L58), alterar `list()` para aplicar `where: { status: 'aprovado' }` e `include: { attachments: true }`.
- Alternativa admin: criar endpoint `GET /marketplace/ads/admin` (guard Admin) retornando todos os statuses para moderação (mantendo lista pública filtrada).
- Verificação: lista pública mostra apenas cards aprovados; painel admin continua com visualização completa.

## Aprovação no admin: evitar “sucesso falso” e falhas
- Backend: revisar [approve](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/backend/src/modules/marketplace/marketplace.controller.ts#L81-L85).
  - Remover retorno “stub” no `catch`; usar `try/catch` e lançar `InternalServerErrorException` ou retornar 400/500.
  - Validar existência e estado: recusar se o anúncio não existir ou não estiver `pendente`.
  - Preencher `approvedBy` com `req.user.sub` em vez de `'admin-stub'`.
- Frontend: em [admin.dart:approve](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/frontend/lib/pages/admin.dart#L366-L404), manter feedback via status code, e adicionar desabilitação do botão durante a chamada para evitar cliques múltiplos.
- Verificação: após aprovar, `load()` reflete o novo status; em erro, banner informa falha e nada muda.

## Editar usuário: cancelar sem crash
- Fluxo atual em [admin.dart](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/frontend/lib/pages/admin.dart#L1180-L1250) já faz `ok = showDialog<bool>(...) ?? false` e retorna cedo.
- Endereços de instabilidade intermitente:
  - Tornar o diálogo não descartável por clique fora: `barrierDismissible: false` no `showDialog`.
  - Usar `Navigator.of(ctx).pop(...)` com o `ctx` do `StatefulBuilder` para garantir contexto correto.
  - Adicionar `if (!mounted) return;` e proteger `setState` após awaits para evitar `setState() after dispose`.
- Verificação: cancelar nunca dispara uploads/patch; nenhum crash ao cancelar repetidamente.

## Detalhes do anúncio: editar via modal
- Em [marketplace_detail.dart](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/frontend/lib/pages/marketplace_detail.dart#L104-L109), substituir `Navigator.push` por `showDialog` que renderiza um formulário de edição dentro de um modal padrão.
- Extrair o formulário de [marketplace_edit.dart](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/frontend/lib/pages/marketplace_edit.dart) para um widget reutilizável (`MarketplaceEditForm`) que funciona tanto em página quanto em modal.
- No salvar, fechar com `Navigator.pop(true)` e recarregar `load()` se `ok == true`.
- Verificação: clicar em “Editar” abre modal; salvar atualiza e fecha; cancelar fecha sem navegação.

## Padronização de modais (criação/edição)
- Criar `AppModal` em `frontend/lib/widgets/app_modal.dart`:
  - Título, conteúdo `Widget`, ações (cancelar/confirmar), largura máxima padrão (ex.: 600–720), padding consistente, `RoundedRectangleBorder` 16.
  - Aplicar em: modais de usuários em [admin.dart](file:///c:/Users/kaio_/OneDrive/Área%20de%20Trabalho/sistema%20poketibia/frontend/lib/pages/admin.dart), confirmação em admin, modal de edição em detalhes do marketplace e visualização de anexos quando aplicável.
  - Unificar botões (usar `TextButton`/`ElevatedButton` com tema; evitar `GestureDetector + Container`).
- Verificação: todos os modais compartilham aparência e tamanho consistentes em desktop e mobile.

## Testes e validação
- Frontend: navegar no Marketplace e confirmar que só há “aprovados”; testar editar anúncio via modal; testar cancelar edição de usuário várias vezes; verificar UserHoverCard menor.
- Backend: aprovar anúncio e confirmar persistência no BD; simular falha no Prisma (desligar BD) e garantir que o endpoint retorna erro em vez de “sucesso falso”.

## Impacto e riscos
- Mudança no endpoint público filtra itens; admin continua com acesso amplo via novo endpoint ou client-side.
- Padronização de modais melhora UX sem quebrar fluxos; extração de formulário reduz duplicação.
- Ajuste no HoverCard é backward-compatible, apenas refina tamanho.

Confirma que podemos aplicar estas alterações? Após sua confirmação, implemento e valido cada ponto em sequência.