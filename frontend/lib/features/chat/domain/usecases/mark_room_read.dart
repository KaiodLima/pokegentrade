import '../../domain/repositories/chat_repository.dart';
import '../../../../core/result.dart';

class MarkRoomReadUseCase {
  final ChatRepository repo;
  MarkRoomReadUseCase(this.repo);
  Future<Result<bool>> call(String roomId) {
    return repo.markRoomRead(roomId);
  }
}
