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
  final int percent;

  const UserSkill({required this.name, required this.percent});
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
    await Future.delayed(const Duration(milliseconds: 600));
    return DashboardData(
      userName: 'Jean',
      stats: const DashboardStats(
        offresMatchees: 24,
        offresMatcheesSubtitle: '+3 cette semaine',
        candidaturesEnvoyees: 8,
        candidaturesSubtitle: '2 en attente',
        scoreMoyenMatch: 78,
        scoreSubtitle: '+5% ce mois',
        entretiensSimules: 12,
        entretiensSubtitle: 'Dernier: 85/100',
      ),
      recentOffers: [
        const RecentOffer(
            title: 'Développeur Frontend React',
            company: 'TechCorp',
            city: 'Paris',
            compatibilityPercent: 92),
        const RecentOffer(
            title: 'Data Analyst Junior',
            company: 'DataFlow',
            city: 'Lyon',
            compatibilityPercent: 85),
        const RecentOffer(
            title: 'UX Designer',
            company: 'DesignStudio',
            city: 'Remote',
            compatibilityPercent: 78),
        const RecentOffer(
            title: 'Chef de projet IT',
            company: 'ConsultPro',
            city: 'Marseille',
            compatibilityPercent: 71),
      ],
      skills: [
        const UserSkill(name: 'React', percent: 85),
        const UserSkill(name: 'TypeScript', percent: 75),
        const UserSkill(name: 'Python', percent: 60),
        const UserSkill(name: 'SQL', percent: 70),
        const UserSkill(name: 'Communication', percent: 90),
      ],
      upcomingInterviews: [
        UpcomingInterview(
          role: 'Développeur Frontend React',
          company: 'TechCorp',
          date: DateTime.now().add(const Duration(days: 2, hours: 14)),
          format: 'En ligne',
        ),
        UpcomingInterview(
          role: 'Data Analyst Junior',
          company: 'DataFlow',
          date: DateTime.now().add(const Duration(days: 5, hours: 9)),
          format: 'Présentiel',
        ),
      ],
      profileViewsCount: 342,
      profileViewsPercentChange: 12,
    );
  }
}
