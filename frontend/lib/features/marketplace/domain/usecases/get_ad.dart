import '../repositories/marketplace_repository.dart';
import '../entities/ad.dart';
import '../../../../core/result.dart';

class GetAdUseCase {
  final MarketplaceRepository repo;
  GetAdUseCase(this.repo);
  Future<Result<Ad>> call(String adId) {
    return repo.getAdById(adId);
  }
}
