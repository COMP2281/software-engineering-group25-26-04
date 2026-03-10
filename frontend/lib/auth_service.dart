import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

class AuthService {
  AuthService._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';

  /// POST /auth/login as application/x-www-form-urlencoded.
  /// OAuth2PasswordRequestForm requires 'username' (not 'email') as the field name.
  /// Returns true on success, false on 401, throws on network error.
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email.toLowerCase().trim(), 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: _tokenKey, value: token);
        return true;
      }
    }
    return false;
  }

  /// Delete the stored token. Call before navigating to LoginPage.
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
  }

  /// Returns the raw JWT string, or null if not logged in.
  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  /// Returns headers for all authenticated API calls.
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Returns the stored user role, or null if not logged in.
  static Future<String?> getRole() async {
    return _storage.read(key: _roleKey);
  }

  /// Fetch current user info from backend and update stored role.
  static Future<void> updateUserRole() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/auth/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final role = data['role'] as String?;
        if (role != null && role.isNotEmpty) {
          await _storage.write(key: _roleKey, value: role);
        }
      }
    } catch (e) {
      // Silently fail if role update doesn't work
    }
  }
}
