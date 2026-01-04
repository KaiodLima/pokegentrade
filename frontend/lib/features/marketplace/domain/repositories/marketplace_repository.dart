import '../../../../core/result.dart';
import '../entities/ad.dart';

abstract class MarketplaceRepository {
  Future<Result<List<Ad>>> getAds();
  Future<Result<Ad>> createAd({required String type, required String title, required String description, required double? price});
  Future<Result<bool>> addAttachment(String adId, {required String url, required String type, Map<String, dynamic>? meta});
  Future<Result<Ad>> getAdById(String adId);
  Future<Result<bool>> approve(String adId);
  Future<Result<bool>> complete(String adId);
  Future<Result<bool>> delete(String adId);
  Future<Result<bool>> suspendAuthor(String authorId, {required String motivo});
  Future<Result<bool>> updateAd(String adId, {String? title, String? description, double? price, String? type});
}
