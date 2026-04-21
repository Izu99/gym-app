import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import 'auth_service.dart';

class ApiService {
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AuthService.token != null)
      'Authorization': 'Bearer ${AuthService.token}',
  };

  static Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse(
      '${AppConstants.apiBase}$path',
    ).replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers);
    return _handle(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBase}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<dynamic> patch(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final res = await http.patch(
      Uri.parse('${AppConstants.apiBase}$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  static Future<dynamic> delete(String path) async {
    final res = await http.delete(
      Uri.parse('${AppConstants.apiBase}$path'),
      headers: _headers,
    );
    return _handle(res);
  }

  static dynamic _handle(http.Response res) {
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) throw data['error'] ?? 'Request failed';
    return data;
  }
}
