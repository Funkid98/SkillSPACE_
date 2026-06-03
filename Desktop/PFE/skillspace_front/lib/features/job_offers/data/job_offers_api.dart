import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/core/network/api_client.dart';
import '../../../../core/api_constants.dart';

class JobOffersApi {
  static final ApiClient _apiClient = ApiClient();

  // ─── Fetch Matching Offers ─────────────────────────────────────────────────
  static Future<List<dynamic>> fetchMatchingOffers() async {
    final response = await _apiClient.get('/candidat/matching-offers');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load matching offers');
    }
  }

  // ─── Register View ──────────────────────────────────────────────────────────
  static Future<void> registerView(String offerId) async {
    final response = await _apiClient.put('/api/offers/$offerId/view', {});
    if (response.statusCode != 200) {
      throw Exception('Failed to register view');
    }
  }

  // ─── Apply to Offer ─────────────────────────────────────────────────────────
  static Future<void> applyToOffer({
    required String offerId,
    required String recruiterId,
    required String offerTitle,
  }) async {
    final response = await _apiClient.post('/candidat/apply', {
      'offerId': offerId,
      'recruiterId': recruiterId,
      'offerTitle': offerTitle,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to apply to offer');
    }
  }

  // ─── Fetch Formation Info ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchFormationItem(String formationId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/formateur/formations/item/$formationId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load formation item');
    }
  }

  static Future<List<dynamic>> fetchFormationsByQuery(String query) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/formateur/all-formations?query=${Uri.encodeComponent(query)}'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load formations by query');
    }
  }

  static Future<List<dynamic>> fetchAllFormations() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/formateur/all-formations'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load all formations');
    }
  }
}
