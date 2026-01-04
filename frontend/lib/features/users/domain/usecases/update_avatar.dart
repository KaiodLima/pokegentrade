import '../repositories/user_repository.dart';
import '../../../../core/result.dart';

class UpdateAvatarUseCase {
  final UserRepository repo;
  UpdateAvatarUseCase(this.repo);
  Future<Result<bool>> call(String avatarUrl) {
    return repo.updateAvatar(avatarUrl);
  }
}
