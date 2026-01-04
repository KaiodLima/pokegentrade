import '../repositories/user_repository.dart';
import '../entities/user_summary.dart';
import '../../../../core/result.dart';

class GetOnlineUsersUseCase {
  final UserRepository repo;
  GetOnlineUsersUseCase(this.repo);
  Future<Result<List<UserSummary>>> call() {
    return repo.getOnline();
  }
}
