import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/formateur_model.dart';

class FormateurService {
  final String baseUrl = 'http://localhost:5000/api/formateur';

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

  Future<FormateurModel?> updateProfile(String userId, FormateurModel profileData) async {
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
}
