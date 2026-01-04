import '../repositories/dm_repository.dart';
import '../../../../core/result.dart';

class GetPeerMessagesUseCase {
  final DmRepository repo;
  GetPeerMessagesUseCase(this.repo);
  Future<Result<List<Map<String, dynamic>>>> call(String peerId, {int limit = 50, String? before}) {
    return repo.getPeerMessages(peerId, limit: limit, before: before);
  }
}
