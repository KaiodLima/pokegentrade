## Causa do Erro
- `DropdownButton<String>` espera `List<DropdownMenuItem<String>>`, mas o mapeamento infere `DropdownMenuItem<Object>` porque `r['id']` e `r['name']` são `dynamic`.

## Correções Propostas
1. Tipar `rooms` como `List<Map<String, dynamic>>` ao carregar JSON.
2. Definir `selectedRoom` como `String` usando `toString()`:
   - `selectedRoom = rooms.isNotEmpty ? rooms.first['id'].toString() : null;`
3. Tipar explicitamente os itens do dropdown:
   - `items: rooms.map<DropdownMenuItem<String>>((r) => DropdownMenuItem<String>(value: r['id'].toString(), child: Text(r['name'].toString()))).toList(),`
4. Manter `DropdownButton<String>` e `onChanged: (v) => setState(() => selectedRoom = v)`.

## Validação
- Executar `flutter analyze` para confirmar ausência de erros de tipo.
- Testar seleção de sala e navegação para Chat para garantir integração com `selectedRoom`. 

Posso aplicar essas alterações agora para resolver o erro de tipo?