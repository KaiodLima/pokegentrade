class UserSummary {
  final String id;
  final String displayName;
  final String avatarUrl;
  UserSummary({required this.id, required this.displayName, required this.avatarUrl});
  factory UserSummary.fromMap(String id, Map m) {
    return UserSummary(
      id: id,
      displayName: (m['displayName'] ?? '').toString(),
      avatarUrl: (m['avatarUrl'] ?? '').toString(),
    );
  }
}
