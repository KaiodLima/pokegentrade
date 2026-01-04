import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/result.dart';

class GetRoomMessagesUseCase {
  final ChatRepository repo;
  GetRoomMessagesUseCase(this.repo);
  Future<Result<List<ChatMessage>>> call(String roomId, {int limit = 50, String? before}) {
    return repo.getRoomMessages(roomId, limit: limit, before: before);
  }
}
