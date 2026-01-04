import '../repositories/news_repository.dart';
import '../entities/news_item.dart';
import '../../../../core/result.dart';

class GetNewsUseCase {
  final NewsRepository repo;
  GetNewsUseCase(this.repo);
  Future<Result<List<NewsItem>>> call() {
    return repo.getAll();
  }
}
