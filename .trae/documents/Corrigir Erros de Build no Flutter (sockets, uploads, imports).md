## Problemas Identificados
- `socket.dispose()` inexistente em `frontend/lib/pages/chat.dart:116` e `frontend/lib/pages/dm.dart:93`.
- Uso de `PlatformFile.mimeType` inexistente em `frontend/lib/pages/marketplace_new.dart:35,39,40`.
- Import duplicado de `dart:async` em `frontend/lib/pages/inbox.dart:1` e `:4`.
- Verificação rígida de `statusCode == 201` em `frontend/lib/pages/rooms.dart` pode falhar quando o backend retorna 200.

## Correções Propostas
- Trocar `socket?.dispose()` por `socket?.disconnect()` (opcionalmente `socket?.close()` se disponível) em `chat.dart` e `dm.dart`.
- Substituir `PlatformFile.mimeType` por função `contentTypeFor(name)` que infere MIME pelo sufixo (png, jpg, jpeg, gif, webp, pdf, txt); usar valor padrão `application/octet-stream`.
- Remover import duplicado `dart:async` em `inbox.dart`.
- Aceitar `200` ou `201` como sucesso no envio de mensagem em `rooms.dart`.

## Validação
- Executar `flutter pub get`, `flutter analyze`, e `flutter run -d chrome`.
- Navegar por Chat, DM, Inbox e Marketplace para garantir ausência de erros e funcionalidade de upload stub.

Confirma que posso aplicar estas correções agora?