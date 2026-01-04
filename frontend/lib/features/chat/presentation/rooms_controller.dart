import '../../chat/domain/usecases/get_room_messages.dart';
import '../../chat/domain/usecases/mark_room_read.dart';
import '../../chat/domain/usecases/send_room_message.dart';
import '../../../app/locator.dart';

class RoomsController {
  Future<List<Map<String, dynamic>>> loadMessages(String roomId) async {
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
  Future<bool> send(String roomId, String content) async {
    final r = await SendRoomMessageUseCase(Locator.chat)(roomId, content);
    return r.isOk;
  }
}
