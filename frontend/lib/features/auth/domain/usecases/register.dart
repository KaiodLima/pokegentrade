import '../repositories/auth_repository.dart';
import '../../../../core/result.dart';
import '../entities/tokens.dart';

class RegisterUseCase {
  final AuthRepository repo;
  RegisterUseCase(this.repo);
  Future<Result<Tokens>> call({required String displayName, required String email, required String password}) {
    return repo.register(displayName: displayName, email: email, password: password);
  }
}
