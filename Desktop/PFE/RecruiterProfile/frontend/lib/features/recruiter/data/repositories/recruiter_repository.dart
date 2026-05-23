import 'dart:convert';
import 'package:pfe/core/network/api_client.dart';
import '../models/company_profile_model.dart';
import '../models/recruiter_job_offer_model.dart';

class RecruiterRepository {
  final ApiClient apiClient;

  RecruiterRepository({required this.apiClient});

  Future<CompanyProfile> getProfile() async {
    final response = await apiClient.get('/recruiter/profile');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyProfile.fromJson(data);
    } else {
      throw Exception('Failed to load recruiter profile: ${response.statusCode}');
    }
  }

  Future<CompanyProfile> updateProfile(CompanyProfile profile) async {
    final response = await apiClient.put('/recruiter/profile', profile.toJson());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CompanyProfile.fromJson(data);
    } else {
      throw Exception('Failed to update recruiter profile: ${response.body}');
    }
  }

  Future<String> uploadLogo(List<int> bytes, String filename) async {
    final response = await apiClient.uploadFile('/recruiter/upload', bytes, filename, fieldName: 'logo');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    } else {
      throw Exception('Failed to upload logo: ${response.body}');
    }
  }

  Future<List<RecruiterOfferWithCandidates>> getGroupedMatchingCandidates() async {
    final response = await apiClient.get('/candidat/grouped-matches');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => RecruiterOfferWithCandidates.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load matching candidates: ${response.statusCode}');
    }
  }

  Future<void> deleteAccount({String? password, String? googleToken}) async {
    final requestBody = <String, dynamic>{};
    if (password != null) requestBody['password'] = password;
    if (googleToken != null) requestBody['googleToken'] = googleToken;

    final response = await apiClient.delete('/recruiter/profile/delete', body: requestBody);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? body['error'] ?? 'Failed to delete recruiter account');
    }
  }
}
