import '../repositories/marketplace_repository.dart';
import '../../../../core/result.dart';

class ApproveAdUseCase {
  final MarketplaceRepository repo;
  ApproveAdUseCase(this.repo);
  Future<Result<bool>> call(String adId) {
    return repo.approve(adId);
  }
}
