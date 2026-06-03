import 'dart:convert';
import 'package:pfe/core/network/api_client.dart';

class DashboardApi {
  static final ApiClient _apiClient = ApiClient();

  // ─── Profile ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _apiClient.get('/candidat/me');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Erreur de chargement du profil');
    }
  }

  static Future<void> saveSkills(List<Map<String, dynamic>> skills) async {
    await _apiClient.put('/candidat/me', {'skills': skills});
  }

  // ─── Matching Offers ────────────────────────────────────────────────────────
  static Future<List<dynamic>> fetchMatchingOffers() async {
    final response = await _apiClient.get('/candidat/matching-offers');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load matching offers');
    }
  }

  // ─── Accepted Offers (Interviews) ───────────────────────────────────────────
  static Future<List<dynamic>> fetchAcceptedOffers() async {
    final response = await _apiClient.get('/candidat/accepted-offers');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load accepted offers');
    }
  }

  // ─── Coach Advice ───────────────────────────────────────────────────────────
  static Future<String> fetchCoachAdvice() async {
    final fallback =
        'Analysez votre profil pour obtenir des conseils personnalisés.';
    try {
      final response = await _apiClient.get('/candidat/coach-advice');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['advice'] ?? fallback;
      }
    } catch (_) {}
    return fallback;
  }
}
