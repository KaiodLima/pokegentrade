import 'dart:convert';
import '../../../core/http_client.dart';
import '../../../core/result.dart';
import '../domain/repositories/marketplace_repository.dart';
import '../domain/entities/ad.dart';
import '../../../services/api.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final HttpClient http;
  MarketplaceRepositoryImpl(this.http);
  @override
  Future<Result<List<Ad>>> getAds() async {
    final res = await http.get('/marketplace/ads');
    List<Ad> base = [];
    if (res.statusCode == 200) {
      try {
        final list = jsonDecode(res.body);
        if (list is List) base = list.map<Ad>((e) => Ad.fromMap(e as Map)).toList();
      } catch (_) {}
    } else {
      return Result.err('Erro ${res.statusCode}');
    }
    if ((Api.currentAccessToken() ?? '').isNotEmpty) {
      final mine = await http.get('/marketplace/ads/mine');
      if (mine.statusCode == 200) {
        try {
          final list = jsonDecode(mine.body);
          if (list is List) {
            final extra = list.map<Ad>((e) => Ad.fromMap(e as Map)).toList();
            final ids = <String>{...base.map((a) => a.id)};
            for (final a in extra) {
              if (!ids.contains(a.id)) base.add(a);
            }
          }
        } catch (_) {}
      }
    }
    return Result.ok(base);
  }
  @override
  Future<Result<Ad>> createAd({required String type, required String title, required String description, required double? price, String? categoryId, String? serverId}) async {
    final payload = {'type': type, 'title': title, 'description': description, 'price': price, if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId, if (serverId != null && serverId.isNotEmpty) 'serverId': serverId};
    final res = await http.post('/marketplace/ads', payload);
    if (res.statusCode == 201 || res.statusCode == 200) {
      try {
        final j = jsonDecode(res.body);
        if (j is Map) {
          if ((j['status'] ?? '') == 'blocked') {
            return Result.err(jsonEncode(j));
          }
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
