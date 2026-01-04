class Attachment {
  final String url;
  final String type;
  final Map<String, dynamic> meta;
  Attachment({required this.url, required this.type, required this.meta});
  factory Attachment.fromMap(Map m) {
    return Attachment(
      url: (m['url'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      meta: (m['meta'] is Map) ? Map<String, dynamic>.from(m['meta'] as Map) : <String, dynamic>{},
    );
  }
  Map<String, dynamic> toMap() => {'url': url, 'type': type, 'meta': meta};
}
