import '../../chat/domain/usecases/get_room_messages.dart';
import '../../chat/domain/usecases/mark_room_read.dart';
import '../../../app/locator.dart';

class ChatController {
  Future<List<Map<String, dynamic>>> loadHistory(String roomId) async {
    final r = await GetRoomMessagesUseCase(Locator.chat)(roomId, limit: 50);
    if (!r.isOk) return <Map<String, dynamic>>[];
    return (r.data ?? []).map<Map<String, dynamic>>((e) => {
      'id': e.id,
      'content': e.content,
      'createdAt': e.createdAt,
      'userId': e.userId,
      'displayName': e.displayName,
    }).toList();
  }
  Future<bool> markRead(String roomId) async {
    final r = await MarkRoomReadUseCase(Locator.chat)(roomId);
    return r.isOk;
  }
}
