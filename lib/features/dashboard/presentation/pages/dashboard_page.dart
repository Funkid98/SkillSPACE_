import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../data/models/dashboard_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.orange));
        }
        if (state is DashboardError) {
          return Center(child: Text(state.message));
        }
        final data = (state as DashboardLoaded).data;
        return _DashboardContent(data: data);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardData data;
  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return MediaQuery.removePadding(
      removeTop: true,
      context: context,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            Responsive.hPad(context), 32, Responsive.hPad(context), 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ─────
            AnimatedReveal(
              delay: const Duration(milliseconds: 100),
              direction: RevealDirection.fromTop,
              child: Text(
                'Bonjour, ${data.userName}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const AnimatedReveal(
              delay: Duration(milliseconds: 200),
              direction: RevealDirection.fromTop,
              child: Text(
                'Voici un résumé de votre activité',
                style: TextStyle(fontSize: 14, color: AppColors.textGray),
              ),
            ),
            const SizedBox(height: 28),

            // ─── Stats Cards ─────────────────────────────────────
            isMobile
                ? Column(
                    children: [
                      AnimatedReveal(
                        delay: const Duration(milliseconds: 300),
                        child: _StatCard(
                          icon: Icons.business_center_outlined,
                          label: 'Offres matchées',
                          value: data.stats.offresMatchees.toString(),
                          subtitle: data.stats.offresMatcheesSubtitle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedReveal(
                        delay: const Duration(milliseconds: 400),
                        child: _StatCard(
                          icon: Icons.description_outlined,
                          label: 'Candidatures envoyées',
                          value: data.stats.candidaturesEnvoyees.toString(),
                          subtitle: data.stats.candidaturesSubtitle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedReveal(
                        delay: const Duration(milliseconds: 500),
                        child: _StatCard(
                          icon: Icons.track_changes_outlined,
                          label: 'Score moyen de match',
                          value: '${data.stats.scoreMoyenMatch}%',
                          subtitle: data.stats.scoreSubtitle,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedReveal(
                        delay: const Duration(milliseconds: 600),
                        child: _StatCard(
                          icon: Icons.trending_up_outlined,
                          label: 'Entretiens simulés',
                          value: data.stats.entretiensSimules.toString(),
                          subtitle: data.stats.entretiensSubtitle,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AnimatedReveal(
                          delay: const Duration(milliseconds: 300),
                          child: _StatCard(
                            icon: Icons.business_center_outlined,
                            label: 'Offres matchées',
                            value: data.stats.offresMatchees.toString(),
                            subtitle: data.stats.offresMatcheesSubtitle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimatedReveal(
                          delay: const Duration(milliseconds: 400),
                          child: _StatCard(
                            icon: Icons.description_outlined,
                            label: 'Candidatures envoyées',
                            value: data.stats.candidaturesEnvoyees.toString(),
                            subtitle: data.stats.candidaturesSubtitle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimatedReveal(
                          delay: const Duration(milliseconds: 500),
                          child: _StatCard(
                            icon: Icons.track_changes_outlined,
                            label: 'Score moyen de match',
                            value: '${data.stats.scoreMoyenMatch}%',
                            subtitle: data.stats.scoreSubtitle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimatedReveal(
                          delay: const Duration(milliseconds: 600),
                          child: _StatCard(
                            icon: Icons.trending_up_outlined,
                            label: 'Entretiens simulés',
                            value: data.stats.entretiensSimules.toString(),
                            subtitle: data.stats.entretiensSubtitle,
                          ),
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 28),

            // ─── Offres + Compétences ────────────────────────────
            isMobile
                ? Column(
                    children: [
                      AnimatedReveal(
                          delay: const Duration(milliseconds: 700),
                          child: _RecentOffersCard(offers: data.recentOffers)),
                      const SizedBox(height: 16),
                      AnimatedReveal(
                          delay: const Duration(milliseconds: 800),
                          child: _SkillsCard(skills: data.skills)),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: AnimatedReveal(
                            delay: const Duration(milliseconds: 700),
                            child:
                                _RecentOffersCard(offers: data.recentOffers)),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: AnimatedReveal(
                            delay: const Duration(milliseconds: 800),
                            child: _SkillsCard(skills: data.skills)),
                      ),
                    ],
                  ),

            const SizedBox(height: 28),

            // ─── Entretiens + Visibilité ────
            isMobile
                ? Column(
                    children: [
                      AnimatedReveal(
                          delay: const Duration(milliseconds: 900),
                          child: _UpcomingInterviewsCard(
                              interviews: data.upcomingInterviews)),
                      const SizedBox(height: 16),
                      AnimatedReveal(
                          delay: const Duration(milliseconds: 1000),
                          child: _ProfileVisibilityCard(
                              viewsCount: data.profileViewsCount,
                              percentChange: data.profileViewsPercentChange)),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: AnimatedReveal(
                            delay: const Duration(milliseconds: 900),
                            child: _UpcomingInterviewsCard(
                                interviews: data.upcomingInterviews)),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: AnimatedReveal(
                            delay: const Duration(milliseconds: 1000),
                            child: _ProfileVisibilityCard(
                                viewsCount: data.profileViewsCount,
                                percentChange: data.profileViewsPercentChange)),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Offers Card ────────────────────────────────────────────────────
class _RecentOffersCard extends StatelessWidget {
  final List<RecentOffer> offers;
  const _RecentOffersCard({required this.offers});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Offres récentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [
                    Text(
                      'Tout voir',
                      style: TextStyle(color: AppColors.orange, fontSize: 13),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward,
                        size: 14, color: AppColors.orange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...offers.map((o) => _OfferRow(offer: o)),
        ],
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  final RecentOffer offer;
  const _OfferRow({required this.offer});

  Color get _barColor {
    if (offer.compatibilityPercent >= 85) return AppColors.orange;
    if (offer.compatibilityPercent >= 70) return AppColors.orangeLight;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${offer.company} · ${offer.city}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Text(
                '${offer.compatibilityPercent}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _barColor,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                height: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: offer.compatibilityPercent / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Skills Card ───────────────────────────────────────────────────────────
class _SkillsCard extends StatelessWidget {
  final List<UserSkill> skills;
  const _SkillsCard({required this.skills});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Compétences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Modifier',
                  style: TextStyle(color: AppColors.orange, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...skills.map((s) => _SkillRow(skill: s)),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final UserSkill skill;
  const _SkillRow({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skill.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${skill.percent}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: skill.percent / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming Interviews Card ──────────────────────────────────────────────
class _UpcomingInterviewsCard extends StatelessWidget {
  final List<UpcomingInterview> interviews;
  const _UpcomingInterviewsCard({required this.interviews});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Entretiens à venir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [
                    Text(
                      'Agenda',
                      style: TextStyle(color: AppColors.orange, fontSize: 13),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.calendar_today,
                        size: 14, color: AppColors.orange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (interviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Aucun entretien programmé',
                  style: TextStyle(color: AppColors.textGray, fontSize: 14),
                ),
              ),
            )
          else
            ...interviews.map((i) => _InterviewRow(interview: i)),
        ],
      ),
    );
  }
}

class _InterviewRow extends StatelessWidget {
  final UpcomingInterview interview;
  const _InterviewRow({required this.interview});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${interview.date.day.toString().padLeft(2, '0')}/${interview.date.month.toString().padLeft(2, '0')} à ${interview.date.hour.toString().padLeft(2, '0')}h${interview.date.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.videocam_outlined,
                size: 24, color: AppColors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interview.role,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${interview.company} · $dateStr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              interview.format,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Visibility Card ───────────────────────────────────────────────
class _ProfileVisibilityCard extends StatelessWidget {
  final int viewsCount;
  final int percentChange;

  const _ProfileVisibilityCard({
    required this.viewsCount,
    required this.percentChange,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percentChange >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility_outlined,
                  size: 20, color: AppColors.textGray),
              SizedBox(width: 8),
              Text(
                'Visibilité du profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                viewsCount.toString(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'vues ce mois',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${percentChange.abs()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'par rapport au mois dernier',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
