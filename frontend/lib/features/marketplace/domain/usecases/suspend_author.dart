import '../repositories/marketplace_repository.dart';
import '../../../../core/result.dart';

class SuspendAuthorUseCase {
  final MarketplaceRepository repo;
  SuspendAuthorUseCase(this.repo);
  Future<Result<bool>> call(String authorId, {required String motivo}) {
    return repo.suspendAuthor(authorId, motivo: motivo);
  }
}
