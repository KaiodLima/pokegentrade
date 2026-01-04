import 'dart:convert';
import '../../../core/http_client.dart';
import '../../../core/result.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/entities/user_summary.dart';

class UserRepositoryImpl implements UserRepository {
  final HttpClient http;
  UserRepositoryImpl(this.http);
  @override
  Future<Result<UserSummary>> getById(String id) async {
    final res = await http.get('/users/$id');
    if (res.statusCode == 200) {
      try {
        final j = jsonDecode(res.body);
        if (j is Map) {
          return Result.ok(UserSummary.fromMap(id, j));
        }
      } catch (_) {}
      return Result.err('Resposta inválida');
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<Map<String, dynamic>>> getMe() async {
    final res = await http.get('/users/me');
    if (res.statusCode == 200) {
      try {
        final j = jsonDecode(res.body);
        if (j is Map) {
          return Result.ok(Map<String, dynamic>.from(j));
        }
      } catch (_) {}
      return Result.err('Resposta inválida');
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> updateDisplayName(String name) async {
    final res = await http.patch('/users/me', {'displayName': name});
    if (res.statusCode == 200) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> updateAvatar(String avatarUrl) async {
    final res = await http.patch('/users/me', {'avatarUrl': avatarUrl});
    if (res.statusCode == 200) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<List<UserSummary>>> getOnline() async {
    final res = await http.get('/users/online');
    if (res.statusCode == 200) {
      try {
        final list = jsonDecode(res.body);
        if (list is List) {
          return Result.ok(list.map<UserSummary>((e) {
            final id = ((e as dynamic)['id'] ?? '').toString();
            return UserSummary.fromMap(id, e as Map);
          }).toList());
        }
      } catch (_) {}
      return const Result.ok(<UserSummary>[]);
    }
    return Result.err('Erro ${res.statusCode}');
  }
}
