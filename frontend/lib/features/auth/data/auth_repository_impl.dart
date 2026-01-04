import 'dart:convert';
import '../../../core/http_client.dart';
import '../../../core/result.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../../auth/domain/entities/tokens.dart';
import '../../../services/api.dart';

class AuthRepositoryImpl implements AuthRepository {
  final HttpClient http;
  AuthRepositoryImpl(this.http);
  @override
  Future<Result<Tokens>> login(String email, String password) async {
    final res = await http.post('/auth/login', {'email': email, 'password': password});
    if (res.statusCode == 200 || res.statusCode == 201) {
      try {
        final j = jsonDecode(res.body);
        final access = (j['tokens']?['accessToken'] ?? '').toString();
        final refresh = (j['tokens']?['refreshToken']).toString();
        await Api.setTokens(access, refresh.isEmpty ? null : refresh);
        return Result.ok(Tokens(accessToken: access, refreshToken: refresh.isEmpty ? null : refresh));
      } catch (_) {}
      return Result.err('Resposta inválida');
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<Tokens>> register({required String displayName, required String email, required String password}) async {
    final res = await http.post('/auth/register', {'email': email, 'password': password, 'displayName': displayName});
    if (res.statusCode == 200 || res.statusCode == 201) {
      try {
        final j = jsonDecode(res.body);
        final access = (j['tokens']?['accessToken'] ?? '').toString();
        final refresh = (j['tokens']?['refreshToken']).toString();
        await Api.setTokens(access, refresh.isEmpty ? null : refresh);
        return Result.ok(Tokens(accessToken: access, refreshToken: refresh.isEmpty ? null : refresh));
      } catch (_) {}
      return Result.err('Resposta inválida');
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<String>> forgot(String email) async {
    final res = await http.post('/auth/forgot', {'email': email});
    if (res.statusCode == 200 || res.statusCode == 201) {
      try {
        final j = jsonDecode(res.body);
        final token = (j['token'] ?? '').toString();
        return Result.ok(token);
      } catch (_) {}
      return Result.err('Resposta inválida');
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> reset({required String token, required String newPassword}) async {
    final res = await http.post('/auth/reset', {'token': token, 'newPassword': newPassword});
    if (res.statusCode == 200 || res.statusCode == 201) {
      return const Result.ok(true);
    }
    return Result.err('Erro ${res.statusCode}');
  }
}
