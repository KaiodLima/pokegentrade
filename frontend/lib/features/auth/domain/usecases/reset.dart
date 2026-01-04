import '../repositories/auth_repository.dart';
import '../../../../core/result.dart';

class ResetUseCase {
  final AuthRepository repo;
  ResetUseCase(this.repo);
  Future<Result<bool>> call({required String token, required String newPassword}) {
    return repo.reset(token: token, newPassword: newPassword);
  }
}
