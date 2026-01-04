import 'package:http/http.dart' as http;
import '../services/api.dart';

abstract class HttpClient {
  Future<http.Response> get(String path);
  Future<http.Response> post(String path, Object? body);
  Future<http.Response> patch(String path, Object? body);
  Future<http.Response> delete(String path);
}

class ApiHttpClient implements HttpClient {
  @override
  Future<http.Response> get(String path) async {
    await Api.init();
    return await Api.get(path);
  }
  @override
  Future<http.Response> post(String path, Object? body) async {
    await Api.init();
    return await Api.post(path, body);
  }
  @override
  Future<http.Response> patch(String path, Object? body) async {
    await Api.init();
    return await Api.patch(path, body);
  }
  @override
  Future<http.Response> delete(String path) async {
    await Api.init();
    return await Api.delete(path);
  }
}
