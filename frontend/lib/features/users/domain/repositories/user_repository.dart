import '../../../../core/result.dart';
import '../entities/user_summary.dart';

abstract class UserRepository {
  Future<Result<UserSummary>> getById(String id);
  Future<Result<Map<String, dynamic>>> getMe();
  Future<Result<bool>> updateDisplayName(String name);
  Future<Result<bool>> updateAvatar(String avatarUrl);
  Future<Result<List<UserSummary>>> getOnline();
}
