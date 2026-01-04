import '../../../../core/result.dart';
import '../entities/tokens.dart';

abstract class AuthRepository {
  Future<Result<Tokens>> login(String email, String password);
  Future<Result<Tokens>> register({required String displayName, required String email, required String password});
  Future<Result<String>> forgot(String email);
  Future<Result<bool>> reset({required String token, required String newPassword});
}
