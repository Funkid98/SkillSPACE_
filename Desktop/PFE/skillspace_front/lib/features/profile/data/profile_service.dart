import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/profile_model.dart';

class ProfileService {
  static const String _candidatBaseUrl = 'http://localhost:5000';
  static const String _recruiterBaseUrl = 'http://localhost:5002';

  static Future<ProfileData> getProfile(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    bool isRecruiter = false;
    if (userData != null) {
      final user = jsonDecode(userData);
      isRecruiter = user['role'] == 'recruteur' || user['role'] == 'recruiter';
    }

    final baseUrl = isRecruiter ? _recruiterBaseUrl : _candidatBaseUrl;
    final endpoint = isRecruiter ? '/recruiter/profile' : '/candidat/me';

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ProfileData.fromJson(data);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  static Future<void> updateProfile(String token, ProfileData profile) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    bool isRecruiter = false;
    if (userData != null) {
      final user = jsonDecode(userData);
      isRecruiter = user['role'] == 'recruteur' || user['role'] == 'recruiter';
    }

    final baseUrl = isRecruiter ? _recruiterBaseUrl : _candidatBaseUrl;
    final endpoint = isRecruiter ? '/recruiter/profile' : '/candidat/me';

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }
}
