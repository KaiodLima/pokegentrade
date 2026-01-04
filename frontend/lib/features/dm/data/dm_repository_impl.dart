import 'dart:convert';
import '../../../core/http_client.dart';
import '../../../core/result.dart';
import '../domain/repositories/dm_repository.dart';
import '../domain/entities/inbox_item.dart';

class DmRepositoryImpl implements DmRepository {
  final HttpClient http;
  DmRepositoryImpl(this.http);
  @override
  Future<Result<List<InboxItem>>> getInbox() async {
    final res = await http.get('/dm/inbox');
    if (res.statusCode == 200) {
      try {
        final list = jsonDecode(res.body);
        if (list is List) {
          final unreadRes = await http.get('/dm/unread');
          final unreadList = (unreadRes.statusCode == 200) ? (jsonDecode(unreadRes.body) as List) : <dynamic>[];
          return Result.ok(list.map<InboxItem>((e) {
            final count = unreadList.firstWhere((u) => (u as dynamic)['peerId'] == (e as dynamic)['peerId'], orElse: () => {'count': 0})['count'] ?? 0;
            return InboxItem.fromMap(e as Map, (count ?? 0) as int);
          }).toList());
        }
      } catch (_) {}
      return const Result.ok(<InboxItem>[]);
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<List<Map<String, dynamic>>>> getUnreadCounts() async {
    final res = await http.get('/dm/unread');
    if (res.statusCode == 200) {
      try {
        final list = jsonDecode(res.body);
        if (list is List) {
          return Result.ok(list.map<Map<String, dynamic>>((e) => {'peerId': (e['peerId'] ?? '').toString(), 'count': (e['count'] ?? 0)}).toList());
        }
      } catch (_) {}
      return const Result.ok(<Map<String, dynamic>>[]);
    }
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<bool>> markPeerRead(String peerId) async {
    final res = await http.post('/dm/$peerId/read', {});
    if (res.statusCode == 200 || res.statusCode == 204) return const Result.ok(true);
    return Result.err('Erro ${res.statusCode}');
  }
  @override
  Future<Result<List<Map<String, dynamic>>>> getPeerMessages(String peerId, {int limit = 50, String? before}) async {
    final q = before != null && before.isNotEmpty ? '?limit=$limit&before=$before' : '?limit=$limit';
    final res = await http.get('/dm/$peerId/messages$q');
    if (res.statusCode == 200) {
      try {
        final list = jsonDecode(res.body);
        if (list is List) {
          return Result.ok(list.map<Map<String, dynamic>>((e) => {
            'id': (e['id'] ?? '').toString(),
            'content': (e['content'] ?? '').toString(),
            'createdAt': (e['createdAt'] ?? '').toString(),
            'from': (e['from'] ?? '').toString(),
            'displayName': (e['displayName'] ?? '').toString(),
            'readAt': e['readAt'],
          }).toList());
        }
      } catch (_) {}
      return const Result.ok(<Map<String, dynamic>>[]);
    }
    return Result.err('Erro ${res.statusCode}');
  }
}
