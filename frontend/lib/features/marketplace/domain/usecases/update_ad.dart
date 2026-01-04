import '../repositories/marketplace_repository.dart';
import '../../../../core/result.dart';

class UpdateAdUseCase {
  final MarketplaceRepository repo;
  UpdateAdUseCase(this.repo);
  Future<Result<bool>> call(String adId, {String? title, String? description, double? price, String? type}) {
    return repo.updateAd(adId, title: title, description: description, price: price, type: type);
  }
}
