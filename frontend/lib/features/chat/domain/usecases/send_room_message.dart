import '../../domain/repositories/chat_repository.dart';
import '../../../../core/result.dart';

class SendRoomMessageUseCase {
  final ChatRepository repo;
  SendRoomMessageUseCase(this.repo);
  Future<Result<bool>> call(String roomId, String content) {
    return repo.sendRoomMessage(roomId, content);
  }
}
