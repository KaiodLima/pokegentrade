import 'package:http/http.dart' as http;
import 'dart:convert';

class NetError {
  static bool isTimeout(http.Response res) {
    if (res.statusCode == 599) {
      try {
        final j = jsonDecode(res.body);
        return j is Map && (j['error'] ?? '') == 'timeout';
      } catch (_) {
        return false;
      }
    }
    return false;
  }
  static bool isNetwork(http.Response res) {
    if (res.statusCode == 599) {
      try {
        final j = jsonDecode(res.body);
        return j is Map && (j['error'] ?? '') == 'network_error';
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}
