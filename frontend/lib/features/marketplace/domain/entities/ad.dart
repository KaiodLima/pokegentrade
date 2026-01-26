import 'attachment.dart';

class Ad {
  final String id;
  final String title;
  final String type;
  final String price;
  final String status;
  final String createdAt;
  final String description;
  final String authorId;
  final List<Attachment> attachments;
  final String? categoryId;
  final String? categoryName;
  final String? serverId;
  final String? serverName;
  final bool featured;
  Ad({required this.id, required this.title, required this.type, required this.price, required this.status, required this.createdAt, required this.description, required this.authorId, required this.attachments, this.categoryId, this.categoryName, this.serverId, this.serverName, this.featured = false});
  factory Ad.fromMap(Map m) {
    final atts = (m['attachments'] is List) ? (m['attachments'] as List).whereType<Map>().map((e) => Attachment.fromMap(e)).toList() : <Attachment>[];
    return Ad(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      price: (m['price']?.toString() ?? ''),
      status: (m['status'] ?? '').toString(),
      createdAt: (m['createdAt'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      authorId: (m['authorId'] ?? '').toString(),
      attachments: atts,
      categoryId: (m['category'] is Map) ? ((m['category'] as Map)['id']?.toString() ?? '') : ((m['categoryId'] ?? '')?.toString()),
      categoryName: (m['category'] is Map) ? ((m['category'] as Map)['name']?.toString() ?? '') : null,
      serverId: (m['server'] is Map) ? ((m['server'] as Map)['id']?.toString() ?? '') : ((m['serverId'] ?? '')?.toString()),
      serverName: (m['server'] is Map) ? ((m['server'] as Map)['name']?.toString() ?? '') : null,
      featured: ((m['featured'] ?? false) == true),
    );
  }
}
