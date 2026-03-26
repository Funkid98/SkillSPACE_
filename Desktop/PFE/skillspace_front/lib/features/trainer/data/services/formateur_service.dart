import 'dart:convert';
import 'package:pfe/core/network/api_client.dart';
import 'package:skillspace/features/trainer/data/models/formateur_model.dart';

class FormateurService {
  final ApiClient _apiClient = ApiClient();

  Future<FormateurModel?> getProfile(String userId) async {
    try {
      final response = await _apiClient.get('/api/formateur/profile/$userId');

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
      final response = await _apiClient.put(
        '/api/formateur/profile/$userId',
        profileData.toJson(),
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
