import 'dart:convert';
import '../services/api.dart';

class MeCache {
  static String? _name;
  static int? _ts;
  static Future<String> getName() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_name != null && _ts != null && (now - _ts!) < 5 * 60 * 1000) {
      return _name!;
    }
    final res = await Api.get('/users/me');
    if (res.statusCode == 200) {
      try {
        final j = jsonDecode(res.body);
        final n = (j['displayName'] ?? j['name'] ?? '').toString();
        _name = n;
        _ts = now;
        return n;
      } catch (_) {}
    }
    return _name ?? '';
  }
  static void setName(String name) {
    _name = name;
    _ts = DateTime.now().millisecondsSinceEpoch;
  }
}
