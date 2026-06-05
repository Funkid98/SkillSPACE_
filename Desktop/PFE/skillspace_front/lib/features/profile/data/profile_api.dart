import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api_constants.dart';
import 'package:pfe/core/network/api_client.dart';
import 'package:pfe/core/network/cookie_service.dart';
import 'models/profile_model.dart';

/* ProfileApi now uses ApiClient exclusively so the HttpOnly cookie is
 automatically sent with every request via BrowserClient.withCredentials.
No manual token reading or Authorization headers are needed. */
class AlreadyEnrolledException implements Exception {
  const AlreadyEnrolledException();
  @override
  String toString() => 'Vous êtes déjà inscrit à cette formation.';
}

class ProfileApi {
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

  // ── Formations ─────────────────────────────────────────────────────────────
  static Future<List<dynamic>> fetchFormations() async {
    final response = await _apiClient.get('/candidat/formations');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Non authentifié');
    } else {
      throw Exception('Impossible de charger vos formations');
    }
  }

  static Future<void> completeFormation(String formationId) async {
    final response =
        await _apiClient.post('/candidat/complete/$formationId', {});
    if (response.statusCode != 200) {
      throw Exception('Failed to complete formation');
    }
  }

  static Future<void> leaveFormation(String formationId) async {
    final response = await _apiClient.post('/candidat/leave/$formationId', {});
    if (response.statusCode != 200) {
      throw Exception('Failed to leave formation');
    }
  }

  static Future<bool> submitReview(
      String formationId, int rating, String review) async {
    final response = await _apiClient.post('/candidat/review/$formationId', {
      'rating': rating,
      'review': review,
    });
    return response.statusCode == 200;
  }

  static Future<bool> enrollInFormation(String formationId) async {
    final response = await _apiClient.post('/candidat/enroll/$formationId', {});
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 409) {
      // Already enrolled
      throw const AlreadyEnrolledException();
    } else {
      try {
        final body = jsonDecode(response.body);
        if (body['error'] != null) {
          throw Exception(body['error']);
        }
      } catch (e) {
        if (e is Exception && e.toString() != 'Exception: null') rethrow;
      }
      return false;
    }
  }

  // ── Quizzes ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> generateQuiz(
      String skill, String level) async {
    final response = await _apiClient.post('/quiz/generate', {
      'skill': skill,
      'level': level,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate quiz');
    }
  }

  static Future<Map<String, dynamic>> evaluateQuiz(
      String skill, String claimedLevel, List<Map<String, String>> qna) async {
    final response = await _apiClient.post('/quiz/evaluate', {
      'skill': skill,
      'claimedLevel': claimedLevel,
      'qna': qna,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to evaluate quiz');
    }
  }

  static Future<Map<String, dynamic>> getRecommendations({
    required String skill,
    required int score,
    String? claimedLevel,
    List<dynamic>? answersAnalysis,
  }) async {
    final response = await _apiClient.post('/quiz/recommend', {
      'skill': skill,
      'score': score,
      if (claimedLevel != null) 'claimedLevel': claimedLevel,
      if (answersAnalysis != null) 'answersAnalysis': answersAnalysis,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load recommendations');
    }
  }

  // ── Interviews ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getInterviewHistory(
      String candidateId) async {
    final response =
        await _apiClient.get('/api/interview/history/$candidateId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load history');
    }
  }

  static Future<Map<String, dynamic>> getTrainerPublicProfile(
      String trainerId) async {
    final response =
        await _apiClient.get('/api/formateur/public-profile/$trainerId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load trainer profile');
    }
  }

  // ── Password / OTP ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updatePassword(
      String email, String newPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
    );
    return jsonDecode(response.body);
  }
}
