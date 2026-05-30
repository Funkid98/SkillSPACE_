import 'dart:convert';
// BrowserClient lives in package:http/browser_client.dart and is the only
// http.Client implementation that exposes withCredentials on Flutter Web.
// This file is only ever compiled for the web target (dart.library.html).
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // Empty string = relative URL → resolved against Nginx origin (port 80).
  // Nginx routes /api/*, /recruiter/*, /candidat/*, etc. to api-gateway:8080.
  // Do NOT use 'http://localhost:8088' — that bypasses Nginx and fails in Docker.
  static const String baseUrl         = '';
  static const String candidatBaseUrl = '';
  static const String recruiterBaseUrl= '';
  static const String offerBaseUrl    = '';
  static const String trainerBaseUrl  = '';

  // BrowserClient is required so the browser automatically attaches the
  // HttpOnly 'skillspace_token' cookie on every cross-origin request.
  // withCredentials = true  ↔  XMLHttpRequest.withCredentials = true
  final BrowserClient _client = BrowserClient()..withCredentials = true;

  static void Function()? onUnauthorized;

  // ── Shared headers ─────────────────────────────────────────────────────────
  // Token is NO LONGER read from CookieService / stored in JS-land.
  // The browser manages the HttpOnly cookie transparently.
  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
  };

  // ── HTTP verbs ─────────────────────────────────────────────────────────────

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${_getBaseUrl(endpoint)}$endpoint');
    try {
      final response = await _client.post(url, headers: _headers(), body: jsonEncode(body)).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${_getBaseUrl(endpoint)}$endpoint');
    try {
      final response = await _client.put(url, headers: _headers(), body: jsonEncode(body)).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${_getBaseUrl(endpoint)}$endpoint');
    try {
      final response = await _client.get(url, headers: _headers()).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${_getBaseUrl(endpoint)}$endpoint');
    try {
      final response = await _client.delete(url, headers: _headers(), body: body != null ? jsonEncode(body) : null).timeout(const Duration(seconds: 10));
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
    final url = Uri.parse('${_getBaseUrl(endpoint)}$endpoint');
    try {
      final request = http.MultipartRequest('POST', url)
        // No Authorization header needed — cookie is sent automatically
        ..files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));

      // Re-use withCredentials by sending through BrowserClient
      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de téléchargement: $e');
    }
  }

  // ── OAuth convenience wrappers ─────────────────────────────────────────────

  Future<http.Response> signInWithGoogle(String idToken) async {
    final url = Uri.parse('$baseUrl/api/auth/google');
    try {
      final response = await _client.post(url, headers: _headers(), body: jsonEncode({'idToken': idToken}));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau Google: $e');
    }
  }

  Future<http.Response> signInWithGithub(String code) async {
    final url = Uri.parse('$baseUrl/api/auth/github');
    try {
      final response = await _client.post(url, headers: _headers(), body: jsonEncode({'code': code}));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau GitHub: $e');
    }
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  String _getBaseUrl(String endpoint) {
    if (endpoint.startsWith('/candidat') || endpoint.startsWith('/cv')) return candidatBaseUrl;
    if (endpoint.startsWith('/recruiter')) return recruiterBaseUrl;
    if (endpoint.startsWith('/offers') || endpoint.startsWith('/api/offers')) return offerBaseUrl;
    if (endpoint.startsWith('/job')) return offerBaseUrl;
    if (endpoint.startsWith('/formateur') || endpoint.startsWith('/api/formateur')) return trainerBaseUrl;
    if (endpoint.startsWith('/quiz') || endpoint.startsWith('/recommend')) return candidatBaseUrl;
    return baseUrl;
  }

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
