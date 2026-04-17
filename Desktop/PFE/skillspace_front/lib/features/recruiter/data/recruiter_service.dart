import 'dart:convert';
import 'package:pfe/core/network/api_client.dart';
import 'models/recruiter_dashboard_model.dart';
import 'models/recruiter_job_offer_model.dart';

class RecruiterService {
  final ApiClient _apiClient;

  RecruiterService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

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
      final candidatesResponse =
          await _apiClient.get('/candidat/recent/$recruiterSector');
      List recentCandidatesData = [];
      if (candidatesResponse.statusCode == 200) {
        recentCandidatesData = jsonDecode(candidatesResponse.body);
      }

      // Ensure recruiterId is correctly extracted
      final String recruiterId = profileData['_id'] ?? profileData['id'] ?? '';

      // Filter active offers to only the recruiter's own
      final myJobs =
          jobsData.where((job) => job['recruiter'] == recruiterId).toList();

      // Calculate total views from the real db counts
      int totalViews = 0;
      for (var job in myJobs) {
        final viewCount = job['viewCount'] ?? 0;
        if (viewCount is int) {
          totalViews += viewCount;
        } else if (viewCount is String) {
          totalViews += int.tryParse(viewCount) ?? 0;
        }
      }

      int activeOffersCount = myJobs.length;
      int candidatesCount = recentCandidatesData.length;

      String conversionRate = '0%';
      if (totalViews > 0) {
        final rate = (candidatesCount / totalViews) * 100;
        conversionRate = '${rate.toStringAsFixed(1)}%';
        if (conversionRate.endsWith('.0%')) {
          conversionRate = '${rate.toInt()}%';
        }
      }

      // Map to RecruiterDashboardData
      return RecruiterDashboardData(
        companyName: profileData['entreprise'] ?? 'Non spécifié',
        stats: [
          RecruiterStat(
            label: 'Offres actives',
            value: activeOffersCount.toString(),
            change: '+0 ce mois',
            isPositive: true,
            iconKey: 'offres',
          ),
          RecruiterStat(
            label: 'Candidatures reçues',
            value: candidatesCount.toString(),
            change: '+0 cette semaine',
            isPositive: true,
            iconKey: 'candidatures',
          ),
          RecruiterStat(
            label: 'Vues des offres',
            value: totalViews.toString(),
            change: '+0 cette semaine',
            isPositive: true,
            iconKey: 'vues',
          ),
          RecruiterStat(
            label: 'Taux de conversion',
            value: conversionRate,
            change: '+0% ce mois',
            isPositive: true,
            iconKey: 'conversion',
          ),
        ],
        recentCandidates: recentCandidatesData
            .map((c) => RecentCandidate(
                  name: c['name'] ?? 'Inconnu',
                  role: c['role'] ?? 'Candidat',
                  status: c['status'] ?? 'Nouveau',
                  matchScore: c['matchScore'] ?? 85,
                  matchingAnalysis: c['matchingAnalysis'] ?? '',
                  recommendation: c['recommendation'] ?? '',
                  initials: c['initials'] ?? '??',
                ))
            .toList(),
        activeOffers: myJobs
            .map((job) => RecruiterActiveOffer(
                  title: job['title'] ?? 'Sans titre',
                  applicationCount: 0,
                  viewCount: job['viewCount'] is int
                      ? job['viewCount']
                      : (int.tryParse(job['viewCount']?.toString() ?? '0') ??
                          0),
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
    final response = await _apiClient
        .uploadFile('/recruiter/upload', bytes, filename, fieldName: 'logo');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['url'];
    }
    throw Exception('Failed to upload logo');
  }
}
