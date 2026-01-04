import '../repositories/dm_repository.dart';
import '../entities/inbox_item.dart';
import '../../../../core/result.dart';

class GetInboxUseCase {
  final DmRepository repo;
  GetInboxUseCase(this.repo);
  Future<Result<List<InboxItem>>> call() {
    return repo.getInbox();
  }
}
