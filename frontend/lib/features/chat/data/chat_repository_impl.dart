import 'dart:convert';
import '../../../core/http_client.dart';
import '../../../core/result.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/entities/chat_message.dart';

class ChatRepositoryImpl implements ChatRepository {
  final HttpClient http;
  ChatRepositoryImpl(this.http);
  @override
  Future<Result<List<ChatMessage>>> getRoomMessages(String roomId, {int limit = 50, String? before}) async {
    final q = before != null && before.isNotEmpty ? '?limit=$limit&before=$before' : '?limit=$limit';
    final res = await http.get('/rooms/$roomId/messages$q');
    if (res.statusCode == 200) {
      try {
        final list = jsonDecode(res.body);
        if (list is List) {
          return Result.ok(list.reversed.map<ChatMessage>((e) => ChatMessage.fromMap(e as Map)).toList());
        }
      } catch (_) {}
      return const Result.ok(<ChatMessage>[]);
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> markRoomRead(String roomId) async {
    final res = await http.post('/rooms/$roomId/read', {});
    if (res.statusCode == 200 || res.statusCode == 204) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> sendRoomMessage(String roomId, String content) async {
    final res = await http.post('/rooms/$roomId/messages', {'roomId': roomId, 'content': content});
    if (res.statusCode == 200 || res.statusCode == 201) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
}
