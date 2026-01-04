import '../repositories/user_repository.dart';
import '../../../../core/result.dart';

class UpdateDisplayNameUseCase {
  final UserRepository repo;
  UpdateDisplayNameUseCase(this.repo);
  Future<Result<bool>> call(String name) {
    return repo.updateDisplayName(name);
  }
}
