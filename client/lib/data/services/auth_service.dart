import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  static String? _token;
  static Map<String, dynamic>? _user;

  static String? get token => _token;
  static Map<String, dynamic>? get user => _user;
  static bool get isLoggedIn => _token != null;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) _user = jsonDecode(userJson);
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBase}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw data['error'] ?? 'Login failed';

    _token = data['token'];
    _user = data['user'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userKey, jsonEncode(_user));
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? companyName,
    String? companyAddress,
    String? phoneNumber,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiBase}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'companyName': companyName,
        'companyAddress': companyAddress,
        'phoneNumber': phoneNumber,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 201) throw data['error'] ?? 'Registration failed';

    _token = data['token'];
    _user = data['user'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userKey, jsonEncode(_user));
    return data;
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? companyName,
    String? companyAddress,
    String? phoneNumber,
  }) async {
    final res = await http.patch(
      Uri.parse('${AppConstants.apiBase}/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'name': name,
        'companyName': companyName,
        'companyAddress': companyAddress,
        'phoneNumber': phoneNumber,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw data['error'] ?? 'Profile update failed';

    _user = data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_user));
    return data;
  }

  static Future<void> updatePassword(String password) async {
    final res = await http.patch(
      Uri.parse('${AppConstants.apiBase}/auth/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw data['error'] ?? 'Password update failed';
  }

  static Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
