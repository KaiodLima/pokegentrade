import '../repositories/marketplace_repository.dart';
import '../../../../core/result.dart';

class DeleteAdUseCase {
  final MarketplaceRepository repo;
  DeleteAdUseCase(this.repo);
  Future<Result<bool>> call(String adId) {
    return repo.delete(adId);
  }
}
