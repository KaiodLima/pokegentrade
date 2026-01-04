class InboxItem {
  final String peerId;
  final String peerName;
  final String lastContent;
  final String lastAt;
  final int unread;
  InboxItem({required this.peerId, required this.peerName, required this.lastContent, required this.lastAt, required this.unread});
  factory InboxItem.fromMap(Map m, int unread) {
    return InboxItem(
      peerId: (m['peerId'] ?? '').toString(),
      peerName: (m['peerName'] ?? '').toString(),
      lastContent: (m['last']?['content'] ?? '').toString(),
      lastAt: (m['last']?['createdAt'] ?? '').toString(),
      unread: unread,
    );
  }
}
