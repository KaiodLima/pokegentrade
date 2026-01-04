import '../repositories/news_repository.dart';
import '../entities/news_item.dart';
import '../../../../core/result.dart';

class CreateNewsUseCase {
  final NewsRepository repo;
  CreateNewsUseCase(this.repo);
  Future<Result<NewsItem>> call({required String title, required String content, List<String>? attachments}) {
    return repo.create(title: title, content: content, attachments: attachments);
  }
}
