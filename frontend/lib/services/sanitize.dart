class Sanitize {
  static bool isSafeUrl(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return false;
    final scheme = (u.scheme).toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }
  static String sanitizeImageUrl(String url) {
    if (url.isEmpty) return '';
    return isSafeUrl(url) ? url : '';
  }
}
