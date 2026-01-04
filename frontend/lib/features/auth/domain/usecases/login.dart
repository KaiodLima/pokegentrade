import '../repositories/auth_repository.dart';
import '../../../../core/result.dart';
import '../entities/tokens.dart';

class LoginUseCase {
  final AuthRepository repo;
  LoginUseCase(this.repo);
  Future<Result<Tokens>> call(String email, String password) {
    return repo.login(email, password);
  }
}
