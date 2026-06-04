import 'dart:convert';
// BrowserClient lives in package:http/browser_client.dart and is the only
// http.Client implementation that exposes withCredentials on Flutter Web.
// This file is only ever compiled for the web target (dart.library.html).
import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // Empty string = relative URL → resolved against Nginx origin (port 80).
  // In debug mode (flutter run), it connects directly to the local API gateway.
  static const String baseUrl = kDebugMode ? 'http://localhost:8088' : '';

  // BrowserClient is required so the browser automatically attaches the
  // HttpOnly 'skillspace_token' cookie on every cross-origin request.
  // withCredentials = true  ↔  XMLHttpRequest.withCredentials = true
  final BrowserClient _client = BrowserClient()..withCredentials = true;

  static void Function()? onUnauthorized;

  // ── Shared headers ─────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ── HTTP verbs ─────────────────────────────────────────────────────────────

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client
          .post(url, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client
          .put(url, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await _client
          .delete(url,
              headers: _headers,
              body: body != null ? jsonEncode(body) : null)
          .timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  // Multipart upload — BrowserClient supports this natively via XHR
  Future<http.Response> uploadFile(
    String endpoint,
    List<int> bytes,
    String filename, {
    String fieldName = 'file',
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final request = http.MultipartRequest('POST', url)
        ..files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));

      final streamedResponse =
          await _client.send(request).timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de téléchargement: $e');
    }
  }

  // ── OAuth convenience wrappers ─────────────────────────────────────────────

  Future<http.Response> signInWithGoogle(String idToken) {
    return post('/api/auth/google', {'idToken': idToken});
  }

  Future<http.Response> signInWithGithub(String code) {
    return post('/api/auth/github', {'code': code});
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
    } else {
      try {
        final body = jsonDecode(response.body);
        if (body is Map &&
            (body['error']?.toString().contains('Invalid token') == true ||
                body['message']?.toString().contains('Invalid token') == true ||
                body['error']?.toString().contains('Token invalide') == true)) {
          onUnauthorized?.call();
        }
      } catch (_) {}
    }
    return response;
  }
}
