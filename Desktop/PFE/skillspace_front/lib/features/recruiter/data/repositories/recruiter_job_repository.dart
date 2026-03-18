import 'dart:convert';
import 'package:pfe/core/network/api_client.dart';
import '../models/recruiter_job_offer_model.dart';

class RecruiterJobRepository {
  final ApiClient apiClient;

  RecruiterJobRepository({required this.apiClient});

  Future<List<RecruiterJobOffer>> getJobs() async {
    final response = await apiClient.get('/job');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => RecruiterJobOffer.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load job offers: ${response.statusCode}');
    }
  }

  Future<RecruiterJobOffer> createJob(RecruiterJobOffer job) async {
    final response = await apiClient.post('/job', job.toJson());
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return RecruiterJobOffer.fromJson(data);
    } else {
      throw Exception('Failed to create job offer: ${response.body}');
    }
  }

  Future<RecruiterJobOffer> updateJob(String id, RecruiterJobOffer job) async {
    final response = await apiClient.put('/job/$id', job.toJson());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RecruiterJobOffer.fromJson(data);
    } else {
      throw Exception('Failed to update job offer: ${response.body}');
    }
  }

  Future<void> deleteJob(String id) async {
    final response = await apiClient.delete('/job/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete job offer: ${response.body}');
    }
  }
}
