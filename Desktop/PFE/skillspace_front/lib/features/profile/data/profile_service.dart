import 'dart:convert';
import 'package:pfe/core/network/api_client.dart';
import 'package:pfe/core/network/cookie_service.dart';
import 'models/profile_model.dart';

// ProfileService now uses ApiClient exclusively so the HttpOnly cookie is
// automatically sent with every request via BrowserClient.withCredentials.
// No manual token reading or Authorization headers are needed.
class ProfileService {
  static final ApiClient _apiClient = ApiClient();

  static bool _isRecruiter() {
    final userData = CookieService.getString('user_data');
    if (userData == null) return false;
    final user = jsonDecode(userData);
    return user['role'] == 'recruteur' || user['role'] == 'recruiter';
  }

  static String get _profileEndpoint =>
      _isRecruiter() ? '/recruiter/profile' : '/candidat/me';

  // ── Get profile ─────────────────────────────────────────────────────────────
  static Future<ProfileData> getProfile() async {
    final response = await _apiClient.get(_profileEndpoint);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ProfileData.fromJson(data);
    } else {
      throw Exception('Failed to load profile (${response.statusCode})');
    }
  }

  // ── Update profile ──────────────────────────────────────────────────────────
  static Future<void> updateProfile(ProfileData profile) async {
    final response = await _apiClient.put(_profileEndpoint, profile.toJson());

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile (${response.statusCode})');
    }
  }

  // ── Remove CV ───────────────────────────────────────────────────────────────
  static Future<void> removeCv() async {
    final response = await _apiClient.delete('/cv');

    if (response.statusCode != 200) {
      throw Exception('Failed to remove CV (${response.statusCode})');
    }
  }

  // ── Delete account ──────────────────────────────────────────────────────────
  static Future<void> deleteAccount({
    String? password,
    String? googleToken,
    String? googleAccessToken,
  }) async {
    final endpoint = _isRecruiter()
        ? '/recruiter/profile/delete'
        : '/candidat/profile/delete';

    final requestBody = <String, dynamic>{};
    if (password != null) requestBody['password'] = password;
    if (googleToken != null) requestBody['googleToken'] = googleToken;
    if (googleAccessToken != null) {
      requestBody['googleAccessToken'] = googleAccessToken;
    }

    final response = await _apiClient.delete(endpoint, body: requestBody);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(
          body['message'] ?? body['error'] ?? 'Failed to delete account');
    }
  }
}
