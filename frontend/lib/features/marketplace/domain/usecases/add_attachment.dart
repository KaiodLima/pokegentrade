import '../repositories/marketplace_repository.dart';
import '../../../../core/result.dart';

class AddAttachmentUseCase {
  final MarketplaceRepository repo;
  AddAttachmentUseCase(this.repo);
  Future<Result<bool>> call(String adId, {required String url, required String type, Map<String, dynamic>? meta}) {
    return repo.addAttachment(adId, url: url, type: type, meta: meta);
  }
}
