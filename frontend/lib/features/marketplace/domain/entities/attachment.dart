class Attachment {
  final String id;
  final String url;
  final String type;
  final Map<String, dynamic> meta;
  final bool isCover;
  Attachment({required this.id, required this.url, required this.type, required this.meta, this.isCover = false});
  factory Attachment.fromMap(Map m) {
    return Attachment(
      id: (m['id'] ?? '').toString(),
      url: (m['url'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      meta: (m['meta'] is Map) ? Map<String, dynamic>.from(m['meta'] as Map) : <String, dynamic>{},
      isCover: ((m['isCover'] ?? false) == true),
    );
  }
  Map<String, dynamic> toMap() => {'id': id, 'url': url, 'type': type, 'meta': meta, 'isCover': isCover};
}
