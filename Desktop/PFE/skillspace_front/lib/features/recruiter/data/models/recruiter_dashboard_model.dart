class RecruiterDashboardData {
  final String companyName;
  final String? logoUrl;
  final List<RecruiterStat> stats;
  final List<RecentCandidate> recentCandidates;
  final List<RecruiterActiveOffer> activeOffers;

  RecruiterDashboardData({
    required this.companyName,
    this.logoUrl,
    required this.stats,
    required this.recentCandidates,
    required this.activeOffers,
  });
}

class RecruiterStat {
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final String iconKey;

  RecruiterStat({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.iconKey,
  });
}

class RecentCandidate {
  final String name;
  final String role;
  final String status;
  final int matchScore;
  final String initials;

  RecentCandidate({
    required this.name,
    required this.role,
    required this.status,
    required this.matchScore,
    required this.initials,
  });
}

class RecruiterActiveOffer {
  final String title;
  final int applicationCount;
  final int viewCount;
  final String daysAgo;

  RecruiterActiveOffer({
    required this.title,
    required this.applicationCount,
    required this.viewCount,
    required this.daysAgo,
  });
}
