import '../../domain/entities/news_item.dart';
import '../../../../core/result.dart';

abstract class NewsRepository {
  Future<Result<List<NewsItem>>> getAll();
  Future<Result<NewsItem>> create({required String title, required String content, List<String>? attachments});
}
