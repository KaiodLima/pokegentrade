import 'api.dart';

class Sanitize {
  static bool isSafeUrl(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return false;
    final scheme = (u.scheme).toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }
  static String sanitizeImageUrl(String url) {
    if (url.isEmpty) return '';
    if (!isSafeUrl(url)) return '';
    final u = Uri.parse(url);
    final host = (u.host).toLowerCase();
    final port = (u.hasPort ? u.port : (u.scheme == 'https' ? 443 : 80));
    if ((host == 'localhost' || host == '127.0.0.1' || host == 'minio' || port == 9000)) {
      final key = u.path.replaceFirst(RegExp(r'^/'), '');
      final base = Api.baseUrl;
      return '$base/uploads/get?key=${Uri.encodeComponent(key)}';
    }
    return url;
  }
}
