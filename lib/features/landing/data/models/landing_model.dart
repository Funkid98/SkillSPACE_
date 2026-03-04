class LandingStats {
  final String candidatsCount;
  final String entreprisesCount;
  final int satisfactionRate;

  const LandingStats({
    required this.candidatsCount,
    required this.entreprisesCount,
    required this.satisfactionRate,
  });

  // Simulation — remplace par API call plus tard
  static Future<LandingStats> fetch() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const LandingStats(
      candidatsCount: '+2 000',
      entreprisesCount: '150+',
      satisfactionRate: 93,
    );
  }
}
