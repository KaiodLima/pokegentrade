import '../repositories/dm_repository.dart';
import '../../../../core/result.dart';

class MarkPeerReadUseCase {
  final DmRepository repo;
  MarkPeerReadUseCase(this.repo);
  Future<Result<bool>> call(String peerId) {
    return repo.markPeerRead(peerId);
  }
}
