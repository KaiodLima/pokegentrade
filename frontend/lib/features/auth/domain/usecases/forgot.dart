import '../repositories/auth_repository.dart';
import '../../../../core/result.dart';

class ForgotUseCase {
  final AuthRepository repo;
  ForgotUseCase(this.repo);
  Future<Result<String>> call(String email) {
    return repo.forgot(email);
  }
}
