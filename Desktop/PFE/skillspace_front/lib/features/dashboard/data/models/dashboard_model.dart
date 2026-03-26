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

  const RecentOffer({
    required this.title,
    required this.company,
    required this.city,
    required this.compatibilityPercent,
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
  final DateTime date;
  final String format;

  const UpcomingInterview({
    required this.role,
    required this.company,
    required this.date,
    required this.format,
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

  const DashboardData({
    required this.userName,
    required this.stats,
    required this.recentOffers,
    required this.skills,
    required this.upcomingInterviews,
    required this.profileViewsCount,
    required this.profileViewsPercentChange,
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
    final userName = prenom.isNotEmpty ? prenom : (nom.isNotEmpty ? nom : 'Candidat');
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

    // Stats derived from profile completion & skills count
    return DashboardData(
      userName: userName,
      stats: DashboardStats(
        offresMatchees: rawSkills.length * 4,
        offresMatcheesSubtitle: rawSkills.isEmpty
            ? 'Ajoutez des compétences'
            : '+${rawSkills.length} cette semaine',
        candidaturesEnvoyees: 0,
        candidaturesSubtitle: 'Aucune pour le moment',
        scoreMoyenMatch: completionPercent,
        scoreSubtitle: 'Profil complété à $completionPercent%',
        entretiensSimules: 0,
        entretiensSubtitle: 'Commencez un entretien',
      ),
      recentOffers: const [],
      skills: skills,
      upcomingInterviews: const [],
      profileViewsCount: 0,
      profileViewsPercentChange: 0,
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
