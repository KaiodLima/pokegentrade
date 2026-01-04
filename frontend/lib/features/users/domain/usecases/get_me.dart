import '../repositories/user_repository.dart';
import '../../../../core/result.dart';

class GetMeUseCase {
  final UserRepository repo;
  GetMeUseCase(this.repo);
  Future<Result<Map<String, dynamic>>> call() {
    return repo.getMe();
  }
}
