class NewsItem {
  final String id;
  final String title;
  final String content;
  final String createdAt;
  final List<String> attachments;
  NewsItem({required this.id, required this.title, required this.content, required this.createdAt, required this.attachments});
  factory NewsItem.fromMap(Map m) {
    return NewsItem(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      content: (m['content'] ?? '').toString(),
      createdAt: (m['createdAt'] ?? '').toString(),
      attachments: (m['attachments'] is List) ? (m['attachments'] as List).map((e) => e.toString()).toList() : <String>[],
    );
  }
}
