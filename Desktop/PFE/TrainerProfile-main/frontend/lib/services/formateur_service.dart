import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/formateur_model.dart';

class FormateurService {
  final String baseUrl = 'http://localhost:5004/api/formateur';

  Future<FormateurModel?> getProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile/$userId'));
      if (response.statusCode == 200) {
        return FormateurModel.fromJson(json.decode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<FormateurModel?> updateProfile(
      String userId, FormateurModel profileData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profileData.toJson()),
      );
      if (response.statusCode == 200) {
        return FormateurModel.fromJson(json.decode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      print('Error updating profile: $e');
      return null;
    }
  }

  Future<List<String>> suggestExpertise(
      String query, List<String> existing) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/suggest-expertise'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query, 'existing': existing}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['suggestions'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  Future<String?> generateBio(
      String name, String jobTitle, List<String> expertise) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-bio'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'jobTitle': jobTitle,
          'expertise': expertise,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['bio'] as String?;
      }
      return null;
    } catch (e) {
      print('Error generating bio: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> validateUrl(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate-url'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'isValid': true, 'reason': ''};
    } catch (e) {
      print('Error validating URL: $e');
      return {'isValid': true, 'reason': ''};
    }
  }
}
