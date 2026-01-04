import '../repositories/marketplace_repository.dart';
import '../entities/ad.dart';
import '../../../../core/result.dart';

class CreateAdUseCase {
  final MarketplaceRepository repo;
  CreateAdUseCase(this.repo);
  Future<Result<Ad>> call({required String type, required String title, required String description, required double? price}) {
    return repo.createAd(type: type, title: title, description: description, price: price);
  }
}
