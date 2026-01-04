import 'dart:convert';
import '../../../core/http_client.dart';
import '../../../core/result.dart';
import '../domain/repositories/marketplace_repository.dart';
import '../domain/entities/ad.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final HttpClient http;
  MarketplaceRepositoryImpl(this.http);
  @override
  Future<Result<List<Ad>>> getAds() async {
    final res = await http.get('/marketplace/ads');
    if (res.statusCode == 200) {
      try {
        final list = jsonDecode(res.body);
        if (list is List) {
          return Result.ok(list.map<Ad>((e) => Ad.fromMap(e as Map)).toList());
        }
      } catch (_) {}
      return const Result.ok(<Ad>[]);
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<Ad>> createAd({required String type, required String title, required String description, required double? price}) async {
    final res = await http.post('/marketplace/ads', {'type': type, 'title': title, 'description': description, 'price': price});
    if (res.statusCode == 201 || res.statusCode == 200) {
      try {
        final j = jsonDecode(res.body);
        if (j is Map) {
          return Result.ok(Ad.fromMap(j));
        }
      } catch (_) {}
      return Result.err('Resposta inválida');
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> addAttachment(String adId, {required String url, required String type, Map<String, dynamic>? meta}) async {
    final res = await http.post('/marketplace/ads/$adId/attachments', {'url': url, 'type': type, 'meta': meta ?? {}});
    if (res.statusCode == 200 || res.statusCode == 201) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<Ad>> getAdById(String adId) async {
    final res = await http.get('/marketplace/ads/$adId');
    if (res.statusCode == 200) {
      try {
        final j = jsonDecode(res.body);
        if (j is Map) {
          return Result.ok(Ad.fromMap(j));
        }
      } catch (_) {}
      return Result.err('Resposta inválida');
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> approve(String adId) async {
    final res = await http.patch('/marketplace/ads/$adId/approve', {});
    if (res.statusCode == 200) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> complete(String adId) async {
    final res = await http.patch('/marketplace/ads/$adId/complete', {});
    if (res.statusCode == 200) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> delete(String adId) async {
    final res = await http.delete('/marketplace/ads/$adId');
    if (res.statusCode == 200 || res.statusCode == 204) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> suspendAuthor(String authorId, {required String motivo}) async {
    final res = await http.post('/moderation/users/suspend', {'userId': authorId, 'motivo': motivo});
    if (res.statusCode == 200) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> updateAd(String adId, {String? title, String? description, double? price, String? type}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (type != null) body['type'] = type;
    final res = await http.patch('/marketplace/ads/$adId', body);
    if (res.statusCode == 200) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
}
