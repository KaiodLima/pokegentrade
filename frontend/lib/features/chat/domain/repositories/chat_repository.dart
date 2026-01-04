import '../../../../core/result.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<Result<List<ChatMessage>>> getRoomMessages(String roomId, {int limit = 50, String? before});
  Future<Result<bool>> markRoomRead(String roomId);
  Future<Result<bool>> sendRoomMessage(String roomId, String content);
}
