import 'dart:convert';
import 'package:pfe/core/network/api_client.dart';
import 'models/recruiter_dashboard_model.dart';
import 'models/recruiter_job_offer_model.dart';

class RecruiterService {
  final ApiClient _apiClient;

  RecruiterService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<RecruiterDashboardData> getDashboardData() async {
    // In a real app, these would be multiple calls or a single aggregated endpoint
    // For now, we'll fetch profile and jobs to populate the dashboard
    final profileResponse = await _apiClient.get('/recruiter/profile');
    final jobsResponse = await _apiClient.get('/api/offers');

    if (profileResponse.statusCode == 200 && jobsResponse.statusCode == 200) {
      final profileData = jsonDecode(profileResponse.body);
      final List jobsData = jsonDecode(jobsResponse.body);

      // Get candidates by recruiter sector
      final recruiterSector = profileData['secteur'] ?? 'all';
      final candidatesResponse = await _apiClient.get('/candidat/recent/$recruiterSector');
      List recentCandidatesData = [];
      if (candidatesResponse.statusCode == 200) {
        recentCandidatesData = jsonDecode(candidatesResponse.body);
      }

      // Map to RecruiterDashboardData
      return RecruiterDashboardData(
        companyName: profileData['entreprise'] ?? 'Non spécifié',
        stats: [
          RecruiterStat(
            label: 'Offres actives',
            value: jobsData.length.toString(),
            change: '+0 ce mois',
            isPositive: true,
            iconKey: 'offres',
          ),
          RecruiterStat(
            label: 'Candidatures reçues',
            value: '0',
            change: '+0 cette semaine',
            isPositive: true,
            iconKey: 'candidatures',
          ),
          RecruiterStat(
            label: 'Vues des offres',
            value: '0',
            change: '+0 cette semaine',
            isPositive: true,
            iconKey: 'vues',
          ),
          RecruiterStat(
            label: 'Taux de conversion',
            value: '0%',
            change: '+0% ce mois',
            isPositive: true,
            iconKey: 'conversion',
          ),
        ],
        recentCandidates: recentCandidatesData.map((c) => RecentCandidate(
              name: c['name'] ?? 'Inconnu',
              role: c['role'] ?? 'Candidat',
              status: c['status'] ?? 'Nouveau',
              matchScore: c['matchScore'] ?? 85,
              initials: c['initials'] ?? '??',
            )).toList(),
        activeOffers: jobsData
            .map((job) => RecruiterActiveOffer(
                  title: job['title'] ?? 'Sans titre',
                  applicationCount: 0,
                  viewCount: 0,
                  daysAgo: 'Récemment',
                ))
            .toList(),
      );
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  Future<List<RecruiterJobOffer>> getJobs() async {
    final response = await _apiClient.get('/api/offers');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => RecruiterJobOffer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load job offers');
    }
  }

  Future<String> uploadLogo(List<int> bytes, String filename) async {
    final response = await _apiClient.uploadFile('/recruiter/upload', bytes, filename, fieldName: 'logo');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['url'];
    }
    throw Exception('Failed to upload logo');
  }
}
