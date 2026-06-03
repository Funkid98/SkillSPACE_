import 'dart:convert';
import 'package:pfe/core/network/api_client.dart';
import 'models/recruiter_dashboard_model.dart';
import 'models/recruiter_job_offer_model.dart';

class RecruiterService {
  final ApiClient _apiClient;

  RecruiterService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<String?> generateJobDescription(
      String title, String location, String type) async {
    final response = await _apiClient.post('/api/offers/generate-description', {
      'title': title,
      'location': location,
      'type': type,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['description'];
    }
    return null;
  }

  Future<RecruiterDashboardData> getDashboardData() async {
    final profileResponse = await _apiClient.get('/recruiter/profile');
    final jobsResponse = await _apiClient.get('/api/offers');
    final statsResponse = await _apiClient.get('/candidat/applications/stats');

    if (profileResponse.statusCode == 200 && jobsResponse.statusCode == 200) {
      final profileData = jsonDecode(profileResponse.body);
      final List jobsData = jsonDecode(jobsResponse.body);
      Map applicationStats = {};

      if (statsResponse.statusCode == 200) {
        applicationStats = jsonDecode(statsResponse.body);
      }

      // Get candidates by recruiter sector
      final recruiterSector = profileData['secteur'] ?? 'all';
      final candidatesResponse =
          await _apiClient.get('/candidat/recent/$recruiterSector');
      List recentCandidatesData = [];
      if (candidatesResponse.statusCode == 200) {
        recentCandidatesData = jsonDecode(candidatesResponse.body);
      }

      final String recruiterId = profileData['_id'] ?? profileData['id'] ?? '';
      final myJobs =
          jobsData.where((job) => job['recruiter'] == recruiterId).toList();

      int totalApplications = 0;
      List<RecruiterActiveOffer> activeOffers = [];

      for (var job in myJobs) {
        final id = job['_id'] ?? job['id'];
        final count = applicationStats[id] ?? 0;
        totalApplications += (count as int);

        activeOffers.add(RecruiterActiveOffer(
          title: job['title'] ?? 'Sans titre',
          applicationCount: count,
          viewCount: job['viewCount'] is int
              ? job['viewCount']
              : (int.tryParse(job['viewCount']?.toString() ?? '0') ?? 0),
          daysAgo: 'Récemment',
        ));
      }

      int activeOffersCount = myJobs.length;
      int candidatesCount = recentCandidatesData.length;

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
            label: 'Candidats postulés',
            value: totalApplications.toString(),
            change: '+0 cette semaine',
            isPositive: true,
            iconKey:
                'vues', // Keeping 'vues' icon for continuity but changing label
          ),
          RecruiterStat(
            label: 'Taux de conversion',
            value: totalApplications > 0
                ? '${((totalApplications / activeOffersCount) * 10).toStringAsFixed(1)}%'
                : '0%',
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
                  matchScore: (c['matchScore'] as num?)?.round() ?? 85,
                  matchingAnalysis: c['matchingAnalysis'] ?? '',
                  recommendation: c['recommendation'] ?? '',
                  initials: c['initials'] ?? '??',
                ))
            .toList(),
        activeOffers: activeOffers,
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

  Future<void> contactCandidate({
    required String candidateId,
    required String candidateName,
    required String offerId,
    required String offerTitle,
    String? interviewDate,
    String? interviewTime,
    String? meetingLink,
    String? rejectionReason,
    required String type,
  }) async {
    final response = await _apiClient.post('/recruiter/contact', {
      'candidateId': candidateId,
      'candidateName': candidateName,
      'offerId': offerId,
      'offerTitle': offerTitle,
      if (interviewDate != null) 'interviewDate': interviewDate,
      if (interviewTime != null) 'interviewTime': interviewTime,
      if (meetingLink != null) 'meetingLink': meetingLink,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'type': type,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to contact candidate: ${response.statusCode}');
    }
  }

  Future<void> forgotPassword(String apiUrl, String email) async {
    final response = await _apiClient.post('$apiUrl/forgot-password', {'email': email});
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Erreur lors de l\'envoi du code');
    }
  }

  Future<void> verifyOtp(String apiUrl, String email, String otp) async {
    final response = await _apiClient.post('$apiUrl/verify-otp', {
      'email': email,
      'otp': otp,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Code invalide ou expiré');
    }
  }

  Future<void> resetPassword(String apiUrl, String email, String otp, String newPassword) async {
    final response = await _apiClient.post('$apiUrl/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Erreur lors de la mise à jour');
    }
  }
}
