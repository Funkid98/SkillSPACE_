import 'dart:convert';
// BrowserClient lives in package:http/browser_client.dart and is the only
// http.Client implementation that exposes withCredentials on Flutter Web.
// This file is only ever compiled for the web target (dart.library.html).
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl         = 'http://localhost:5001';
  static const String candidatBaseUrl = 'http://localhost:5000';
  static const String recruiterBaseUrl= 'http://localhost:5002';
  static const String offerBaseUrl    = 'http://localhost:5003';
  static const String trainerBaseUrl  = 'http://localhost:5004';

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
      final response = await _client.post(url, headers: _headers(), body: jsonEncode(body));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${_getBaseUrl(endpoint)}$endpoint');
    try {
      final response = await _client.put(url, headers: _headers(), body: jsonEncode(body));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${_getBaseUrl(endpoint)}$endpoint');
    try {
      final response = await _client.get(url, headers: _headers());
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${_getBaseUrl(endpoint)}$endpoint');
    try {
      final response = await _client.delete(url, headers: _headers(), body: body != null ? jsonEncode(body) : null);
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
      final streamedResponse = await _client.send(request);
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
