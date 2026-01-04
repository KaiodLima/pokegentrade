import '../repositories/marketplace_repository.dart';
import '../entities/ad.dart';
import '../../../../core/result.dart';

class GetAdsUseCase {
  final MarketplaceRepository repo;
  GetAdsUseCase(this.repo);
  Future<Result<List<Ad>>> call() {
    return repo.getAds();
  }
}
