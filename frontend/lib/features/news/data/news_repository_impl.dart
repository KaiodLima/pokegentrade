import 'dart:convert';
import '../../../core/http_client.dart';
import '../domain/repositories/news_repository.dart';
import '../domain/entities/news_item.dart';
import '../../../core/result.dart';

class NewsRepositoryImpl implements NewsRepository {
  final HttpClient http;
  NewsRepositoryImpl(this.http);
  @override
  Future<Result<List<NewsItem>>> getAll() async {
    final res = await http.get('/news');
    if (res.statusCode == 200) {
      try {
        final list = jsonDecode(res.body);
        if (list is List) {
          final items = list.map<NewsItem>((e) => NewsItem.fromMap(e as Map)).toList();
          return Result.ok(items);
        }
      } catch (_) {}
      return const Result.ok(<NewsItem>[]);
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<NewsItem>> create({required String title, required String content, List<String>? attachments}) async {
    final res = await http.post('/news', {'title': title, 'content': content, 'attachments': attachments ?? []});
    if (res.statusCode == 200 || res.statusCode == 201) {
      try {
        final j = jsonDecode(res.body);
        if (j is Map) {
          return Result.ok(NewsItem.fromMap(j));
        }
      } catch (_) {}
      return Result.err('Resposta inválida');
    }
    return Result.err('Erro ${res.statusCode}');
  }
}
