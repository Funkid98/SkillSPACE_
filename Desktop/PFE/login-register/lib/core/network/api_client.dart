import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl =
      'http://127.0.0.1:5001'; // login-register backend
  static const String candidatBaseUrl =
      'http://127.0.0.1:5000'; // candidat-service backend
  static const String recruiterBaseUrl =
      'http://127.0.0.1:5002'; // recruiter-service backend
  static const String offerBaseUrl =
      'http://127.0.0.1:5003'; // offer-service backend
  static const String trainerBaseUrl =
      'http://127.0.0.1:5004'; // trainer-service backend

  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final currentBaseUrl = _getBaseUrl(endpoint);
    final url = Uri.parse('$currentBaseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final currentBaseUrl = _getBaseUrl(endpoint);
    final url = Uri.parse('$currentBaseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await _client.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> uploadFile(
      String endpoint, List<int> bytes, String filename,
      {String fieldName = 'file'}) async {
    final currentBaseUrl = _getBaseUrl(endpoint);
    final url = Uri.parse('$currentBaseUrl$endpoint');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    try {
      final request = http.MultipartRequest('POST', url);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
      ));

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('Erreur de téléchargement: $e');
    }
  }

  Future<http.Response> get(String endpoint) async {
    final currentBaseUrl = _getBaseUrl(endpoint);
    final url = Uri.parse('$currentBaseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await _client.get(
        url,
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  Future<http.Response> delete(String endpoint) async {
    final currentBaseUrl = _getBaseUrl(endpoint);
    final url = Uri.parse('$currentBaseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await _client.delete(
        url,
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion réseau: $e');
    }
  }

  String _getBaseUrl(String endpoint) {
    if (endpoint.startsWith('/candidat') || endpoint.startsWith('/cv')) {
      return candidatBaseUrl;
    } else if (endpoint.startsWith('/recruiter')) {
      return recruiterBaseUrl;
    } else if (endpoint.startsWith('/offers') ||
        endpoint.startsWith('/api/offers')) {
      return offerBaseUrl;
    } else if (endpoint.startsWith('/job')) {
      return offerBaseUrl;
    } else if (endpoint.startsWith('/formateur') ||
        endpoint.startsWith('/api/formateur')) {
      return trainerBaseUrl;
    } else {
      return baseUrl;
    }
  }

  Future<http.Response> signInWithGoogle(String idToken) async {
    final url = Uri.parse('$baseUrl/api/auth/google');
    final headers = await _getHeaders();
    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode({'idToken': idToken}),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion réseau Google: $e');
    }
  }

  Future<http.Response> signInWithGithub(String code) async {
    final url = Uri.parse('$baseUrl/api/auth/github');
    final headers = await _getHeaders();
    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode({'code': code}),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion réseau GitHub: $e');
    }
  }
}
