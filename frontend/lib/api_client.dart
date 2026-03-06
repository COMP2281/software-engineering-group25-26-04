import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'login_page.dart';

/// Authenticated HTTP wrapper.
///
/// Automatically injects the Authorization header from [AuthService] and
/// redirects to [LoginPage] on HTTP 401. Pass [context] from any widget
/// to enable the redirect; omit it for background/initState calls where
/// navigation is not possible.
class ApiClient {
  ApiClient._();

  static Future<http.Response> get(
    String url, {
    BuildContext? context,
  }) async {
    final headers = await AuthService.getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);
    _handleUnauthorized(response, context);
    return response;
  }

  static Future<http.Response> post(
    String url, {
    required Map<String, dynamic> body,
    BuildContext? context,
  }) async {
    final headers = await AuthService.getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    _handleUnauthorized(response, context);
    return response;
  }

  static Future<http.Response> put(
    String url, {
    required Map<String, dynamic> body,
    BuildContext? context,
  }) async {
    final headers = await AuthService.getHeaders();
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    _handleUnauthorized(response, context);
    return response;
  }

  static Future<http.Response> delete(
    String url, {
    BuildContext? context,
  }) async {
    final headers = await AuthService.getHeaders();
    final response = await http.delete(Uri.parse(url), headers: headers);
    _handleUnauthorized(response, context);
    return response;
  }

  static void _handleUnauthorized(
    http.Response response,
    BuildContext? context,
  ) {
    if (response.statusCode == 401 && context != null && context.mounted) {
      AuthService.logout().then((_) {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      });
    }
  }
}
