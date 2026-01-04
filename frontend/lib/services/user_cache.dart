import 'dart:convert';
import 'api.dart';

class UserCache {
  static final Map<String, Map<String, dynamic>> _names = {};
  static const int _ttlMs = 10 * 60 * 1000;
  static Future<String> getName(String id) async {
    final cached = _names[id];
    final now = DateTime.now().millisecondsSinceEpoch;
    if (cached != null) {
      final ts = (cached['ts'] ?? 0) as int;
      final name = (cached['name'] ?? '').toString();
      if (name.isNotEmpty && (now - ts) < _ttlMs) return name;
    }
    final res = await Api.get('/users/$id');
    if (res.statusCode == 200) {
      try {
        final j = jsonDecode(res.body);
        final name = (j['displayName'] ?? '').toString();
        if (name.isNotEmpty) {
          _names[id] = {'name': name, 'ts': now};
          return name;
        }
      } catch (_) {}
    }
    return cached?['name']?.toString() ?? '';
  }
  static void setName(String id, String name) {
    _names[id] = {'name': name, 'ts': DateTime.now().millisecondsSinceEpoch};
  }
}
