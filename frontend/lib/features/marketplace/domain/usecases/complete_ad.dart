import '../repositories/marketplace_repository.dart';
import '../../../../core/result.dart';

class CompleteAdUseCase {
  final MarketplaceRepository repo;
  CompleteAdUseCase(this.repo);
  Future<Result<bool>> call(String adId) {
    return repo.complete(adId);
  }
}
