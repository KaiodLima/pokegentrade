import '../core/http_client.dart';
import '../features/news/domain/repositories/news_repository.dart';
import '../features/news/data/news_repository_impl.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/data/chat_repository_impl.dart';
import '../features/users/domain/repositories/user_repository.dart';
import '../features/users/data/user_repository_impl.dart';
import '../features/marketplace/domain/repositories/marketplace_repository.dart';
import '../features/marketplace/data/marketplace_repository_impl.dart';
import '../features/dm/domain/repositories/dm_repository.dart';
import '../features/dm/data/dm_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/data/auth_repository_impl.dart';

class Locator {
  static HttpClient http = ApiHttpClient();
  static NewsRepository news = NewsRepositoryImpl(http);
  static ChatRepository chat = ChatRepositoryImpl(http);
  static UserRepository users = UserRepositoryImpl(http);
  static MarketplaceRepository marketplace = MarketplaceRepositoryImpl(http);
  static DmRepository dm = DmRepositoryImpl(http);
  static AuthRepository auth = AuthRepositoryImpl(http);
}
