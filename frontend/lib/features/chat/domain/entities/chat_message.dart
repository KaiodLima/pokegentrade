class ChatMessage {
  final String id;
  final String content;
  final String createdAt;
  final String userId;
  final String displayName;
  ChatMessage({required this.id, required this.content, required this.createdAt, required this.userId, required this.displayName});
  factory ChatMessage.fromMap(Map m) {
    return ChatMessage(
      id: (m['id'] ?? '').toString(),
      content: (m['content'] ?? '').toString(),
      createdAt: (m['createdAt'] ?? '').toString(),
      userId: (m['userId'] ?? '').toString(),
      displayName: (m['displayName'] ?? '').toString(),
    );
  }
}
