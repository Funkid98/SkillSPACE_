import 'dart:convert';
import 'package:pfe/core/network/api_client.dart';

class DashboardStats {
  final int offresMatchees;
  final String offresMatcheesSubtitle;
  final int candidaturesEnvoyees;
  final String candidaturesSubtitle;
  final int scoreMoyenMatch;
  final String scoreSubtitle;
  final int entretiensSimules;
  final String entretiensSubtitle;

  const DashboardStats({
    required this.offresMatchees,
    required this.offresMatcheesSubtitle,
    required this.candidaturesEnvoyees,
    required this.candidaturesSubtitle,
    required this.scoreMoyenMatch,
    required this.scoreSubtitle,
    required this.entretiensSimules,
    required this.entretiensSubtitle,
  });
}

class RecentOffer {
  final String title;
  final String company;
  final String city;
  final int compatibilityPercent;
  final String status;

  const RecentOffer({
    required this.title,
    required this.company,
    required this.city,
    required this.compatibilityPercent,
    required this.status,
  });
}

class UserSkill {
  final String name;
  int percent;

  UserSkill({required this.name, required this.percent});

  Map<String, dynamic> toJson() => {'name': name, 'percent': percent};
}

class UpcomingInterview {
  final String role;
  final String company;
  final String rawDate;
  final String rawTime;
  final String format;
  final String? meetingLink;
  final String applicationStatus;

  const UpcomingInterview({
    required this.role,
    required this.company,
    required this.rawDate,
    required this.rawTime,
    required this.format,
    this.meetingLink,
    this.applicationStatus = 'ACCEPTED',
  });
}

class DashboardData {
  final String userName;
  final DashboardStats stats;
  final List<RecentOffer> recentOffers;
  final List<UserSkill> skills;
  final List<UpcomingInterview> upcomingInterviews;
  final int profileViewsCount;
  final int profileViewsPercentChange;
  final String coachAdvice;

  const DashboardData({
    required this.userName,
    required this.stats,
    required this.recentOffers,
    required this.skills,
    required this.upcomingInterviews,
    required this.profileViewsCount,
    required this.profileViewsPercentChange,
    required this.coachAdvice,
  });

  static Future<DashboardData> fetch() async {
    final apiClient = ApiClient();

    // Fetch candidate profile
    final response = await apiClient.get('/candidat/me');
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Erreur de chargement du profil');
    }

    // Extract real user data
    final prenom = data['prenom'] ?? '';
    final nom = data['nom'] ?? '';
    final userName =
        prenom.isNotEmpty ? prenom : (nom.isNotEmpty ? nom : 'Candidat');
    final completionPercent = data['completion_percent'] ?? 30;

    // Map skills from backend ({name, percent} objects)
    final List<dynamic> rawSkills = data['skills'] ?? [];
    final List<UserSkill> skills = rawSkills.map((s) {
      if (s is Map<String, dynamic>) {
        return UserSkill(
          name: s['name'] ?? '',
          percent: (s['percent'] ?? 50).toInt().clamp(0, 100),
        );
      }
      // Backward compatibility: if skill is just a string
      return UserSkill(name: s.toString(), percent: 50);
    }).toList();

    // Fetch matching offers for recent offers and real stats
    int offresMatcheesReal = 0;
    List<RecentOffer> realOffers = [];
    bool hasAnalysing = false;

    try {
      final offersRes = await apiClient.get('/candidat/matching-offers');
      if (offersRes.statusCode == 200) {
        final List offersData = jsonDecode(offersRes.body);

        final highMatchOffers = offersData
            .where((o) =>
                ((o['compatibilityPercent'] as num?)?.round() ?? 0) >= 80)
            .toList();
        offresMatcheesReal = highMatchOffers.length;

        hasAnalysing = offersData.any((o) => o['status'] == 'ANALYSING');

        // Sort by match score descending to show best offers first
        offersData.sort((a, b) =>
            ((b['compatibilityPercent'] as num?)?.round() ?? 0)
                .compareTo((a['compatibilityPercent'] as num?)?.round() ?? 0));

        realOffers = offersData
            .take(4)
            .map((o) => RecentOffer(
                  title: o['title'] ?? 'Sans titre',
                  company: o['company'] ?? 'Non spécifié',
                  city: o['location'] ?? 'Remote',
                  compatibilityPercent:
                      (o['compatibilityPercent'] as num?)?.round() ?? 0,
                  status: o['status'] ?? 'COMPLETED',
                ))
            .toList();
      }
    } catch (_) {}

    // Fetch upcoming interviews (accepted offers)
    List<UpcomingInterview> realInterviews = [];
    try {
      final interviewsRes = await apiClient.get('/candidat/accepted-offers');
      if (interviewsRes.statusCode == 200) {
        final List interviewsData = jsonDecode(interviewsRes.body);
        realInterviews = interviewsData.map((i) {
          final status = i['applicationStatus'] ?? 'ACCEPTED';
          return UpcomingInterview(
            role: i['title'] ?? 'Entretien',
            company: i['company'] ?? 'Entreprise',
            rawDate: i['interviewDate'] ?? 'Date à définir',
            rawTime: i['interviewTime'] ?? 'Heure à définir',
            format: status == 'INTERVIEW_PLANNED'
                ? 'Entretien en direct'
                : 'Simulation IA',
            meetingLink: i['meetingLink'],
            applicationStatus: status,
          );
        }).toList();
      }
    } catch (_) {}

    // Fetch Coach Advice
    String realCoachAdvice =
        'Analysez votre profil pour obtenir des conseils personnalisés.';

    try {
      final coachRes = await apiClient.get('/candidat/coach-advice');
      if (coachRes.statusCode == 200) {
        final coachData = jsonDecode(coachRes.body);
        realCoachAdvice = coachData['advice'] ?? realCoachAdvice;
      }
    } catch (_) {}

    // Stats derived from profile completion & real offers count
    return DashboardData(
      userName: userName,
      stats: DashboardStats(
        offresMatchees: offresMatcheesReal,
        offresMatcheesSubtitle: offresMatcheesReal == 0
            ? 'Aucun match > 80%'
            : 'Forte compatibilité',
        candidaturesEnvoyees: realInterviews.length,
        candidaturesSubtitle: 'Candidatures acceptées',
        scoreMoyenMatch: completionPercent,
        scoreSubtitle: 'Profil complété à $completionPercent%',
        entretiensSimules: realInterviews.length,
        entretiensSubtitle: 'Prêts pour la simulation',
      ),
      recentOffers: realOffers,
      skills: skills,
      upcomingInterviews: realInterviews,
      profileViewsCount: hasAnalysing
          ? -1
          : 0, // Hack to pass analysing state to Cubit without rewriting whole model
      profileViewsPercentChange: 0,
      coachAdvice: realCoachAdvice,
    );
  }

  /// Save updated skill percentages to the backend
  static Future<void> saveSkills(List<UserSkill> skills) async {
    final apiClient = ApiClient();
    await apiClient.put('/candidat/me', {
      'skills': skills.map((s) => s.toJson()).toList(),
    });
  }
}
