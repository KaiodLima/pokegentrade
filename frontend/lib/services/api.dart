import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class Api {
  static const String baseUrl = 'http://localhost:8020';
  static String? _accessToken;
  static String? _refreshToken;
  static Timer? _refreshTimer;
  static String? _acceptLanguage;
  static int requestCount = 0;
  static int timeoutCount = 0;
  static int networkErrorCount = 0;
  static final List<void Function(String)> _tokenListeners = [];
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');
    _scheduleRefresh();
  }
  static Future<void> setTokens(String access, String? refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', access);
    _accessToken = access;
    if (refresh != null && refresh.isNotEmpty) {
      await prefs.setString('refreshToken', refresh);
      _refreshToken = refresh;
    }
    _scheduleRefresh();
    for (final fn in List.of(_tokenListeners)) {
      try { fn(access); } catch (_) {}
    }
  }
  static void setAcceptLanguage(String? lang) {
    _acceptLanguage = (lang == null || lang.isEmpty) ? null : lang;
  }
  static Map<String, String> _headers(Map<String, String>? headers) {
    final h = {'Content-Type': 'application/json', ...?headers};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_accessToken';
    }
    if (_acceptLanguage != null && _acceptLanguage!.isNotEmpty) {
      h['Accept-Language'] = _acceptLanguage!;
    }
    return h;
  }
  static Future<http.Response> get(String path, {Map<String, String>? headers, int? timeoutSeconds}) {
    return _request('GET', path, null, headers, timeoutSeconds: timeoutSeconds);
  }
  static Future<http.Response> post(String path, Object? body, {Map<String, String>? headers, int? timeoutSeconds}) {
    return _request('POST', path, body, headers, timeoutSeconds: timeoutSeconds);
  }
  static Future<http.Response> patch(String path, Object? body, {Map<String, String>? headers, int? timeoutSeconds}) {
    return _request('PATCH', path, body, headers, timeoutSeconds: timeoutSeconds);
  }
  static Future<http.Response> delete(String path, {Map<String, String>? headers, int? timeoutSeconds}) {
    return _request('DELETE', path, null, headers, timeoutSeconds: timeoutSeconds);
  }
  static Future<http.Response> _request(String method, String path, Object? body, Map<String, String>? headers, {int? timeoutSeconds}) async {
    final uri = Uri.parse('$baseUrl$path');
    final h = _headers(headers);
    http.Response res;
    try {
      switch (method) {
        case 'GET':
          res = await http.get(uri, headers: h).timeout(Duration(seconds: timeoutSeconds ?? 12));
          break;
        case 'POST':
          res = await http.post(uri, headers: h, body: body is String ? body : jsonEncode(body)).timeout(Duration(seconds: timeoutSeconds ?? 12));
          break;
        case 'PATCH':
          res = await http.patch(uri, headers: h, body: body is String ? body : jsonEncode(body)).timeout(Duration(seconds: timeoutSeconds ?? 12));
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: h).timeout(Duration(seconds: timeoutSeconds ?? 12));
          break;
        default:
          res = await http.get(uri, headers: h).timeout(Duration(seconds: timeoutSeconds ?? 12));
      }
      requestCount += 1;
    } on TimeoutException catch (_) {
      timeoutCount += 1;
      return http.Response('{"error":"timeout"}', 599);
    } catch (_) {
      networkErrorCount += 1;
      return http.Response('{"error":"network_error"}', 599);
    }
    if (res.statusCode == 401 && _refreshToken != null && _refreshToken!.isNotEmpty) {
      final ok = await _refreshAccessToken();
      if (ok) {
        final h2 = _headers(headers);
        try {
          switch (method) {
            case 'GET':
              return await http.get(uri, headers: h2).timeout(Duration(seconds: timeoutSeconds ?? 12));
            case 'POST':
              return await http.post(uri, headers: h2, body: body is String ? body : jsonEncode(body)).timeout(Duration(seconds: timeoutSeconds ?? 12));
            case 'PATCH':
              return await http.patch(uri, headers: h2, body: body is String ? body : jsonEncode(body)).timeout(Duration(seconds: timeoutSeconds ?? 12));
            default:
              return await http.get(uri, headers: h2).timeout(Duration(seconds: timeoutSeconds ?? 12));
          }
        } on TimeoutException catch (_) {
          timeoutCount += 1;
          return http.Response('{"error":"timeout"}', 599);
        } catch (_) {
          networkErrorCount += 1;
          return http.Response('{"error":"network_error"}', 599);
        }
      }
    }
    return res;
  }
  static Map<String, int> diagnostics() => {
    'requests': requestCount,
    'timeouts': timeoutCount,
    'networkErrors': networkErrorCount,
  };
  static Future<bool> _refreshAccessToken() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        final newAccess = json['accessToken'] ?? json['tokens']?['accessToken'];
        if (newAccess is String && newAccess.isNotEmpty) {
          await setTokens(newAccess, _refreshToken);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }
  static Future<bool> refresh() => _refreshAccessToken();
  static String? currentAccessToken() => _accessToken;
  static void addTokenListener(void Function(String) fn) {
    _tokenListeners.add(fn);
  }
  static void removeTokenListener(void Function(String) fn) {
    _tokenListeners.remove(fn);
  }
  static Future<void> logout() async {
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      try {
        await post('/auth/logout', {'refreshToken': _refreshToken});
      } catch (_) {}
    }
    await clearTokens();
  }
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    _accessToken = null;
    _refreshToken = null;
    _refreshTimer?.cancel();
  }
  static void _scheduleRefresh() {
    _refreshTimer?.cancel();
    final exp = _decodeExp(_accessToken);
    if (exp == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expMs = exp * 1000;
    final leadMs = 60000;
    var delay = expMs - nowMs - leadMs;
    if (delay < 0) delay = 0;
    _refreshTimer = Timer(Duration(milliseconds: delay), () {
      _refreshAccessToken();
    });
  }
  static int? _decodeExp(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'];
      if (exp is int) return exp;
      if (exp is double) return exp.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }
}
