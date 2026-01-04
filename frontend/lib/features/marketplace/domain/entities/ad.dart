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
  Ad({required this.id, required this.title, required this.type, required this.price, required this.status, required this.createdAt, required this.description, required this.authorId, required this.attachments});
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
    );
  }
}
