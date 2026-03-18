import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../data/models/dashboard_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../core/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);

    return MediaQuery.removePadding(
      removeTop: true,
      context: context,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            Responsive.hPad(context), 24, Responsive.hPad(context), 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ─────
            AnimatedReveal(
              delay: const Duration(milliseconds: 100),
              direction: RevealDirection.fromTop,
              child: Text(
                '${l10n.welcome}, ${data.userName}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedReveal(
              delay: const Duration(milliseconds: 200),
              direction: RevealDirection.fromTop,
              child: Text(
                l10n.summary,
                style: const TextStyle(fontSize: 15, color: AppColors.textGray),
              ),
            ),
            const SizedBox(height: 32),

            // ─── Stats Cards ─────────────────────────────────────
            _buildStatsGrid(context, isMobile, l10n),

            const SizedBox(height: 32),

            // ─── Offres + Compétences ────────────────────────────
            isMobile
                ? Column(
                    children: [
                      AnimatedReveal(
                          delay: const Duration(milliseconds: 700),
                          child: _RecentOffersCard(offers: data.recentOffers)),
                      const SizedBox(height: 20),
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
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: AnimatedReveal(
                            delay: const Duration(milliseconds: 800),
                            child: _SkillsCard(skills: data.skills)),
                      ),
                    ],
                  ),

            const SizedBox(height: 32),

            // ─── Entretiens + Visibilité ────
            isMobile
                ? Column(
                    children: [
                      AnimatedReveal(
                          delay: const Duration(milliseconds: 900),
                          child: _UpcomingInterviewsCard(
                              interviews: data.upcomingInterviews)),
                      const SizedBox(height: 20),
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
                      const SizedBox(width: 24),
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

  Widget _buildStatsGrid(
      BuildContext context, bool isMobile, AppLocalizations l10n) {
    final stats = [
      _StatItem(
        icon: Icons.business_center_rounded,
        label: l10n.matchedOffers,
        value: data.stats.offresMatchees.toString(),
        subtitle: data.stats.offresMatcheesSubtitle,
        delay: 300,
      ),
      _StatItem(
        icon: Icons.description_rounded,
        label: l10n.sentApplications,
        value: data.stats.candidaturesEnvoyees.toString(),
        subtitle: data.stats.candidaturesSubtitle,
        delay: 400,
      ),
      _StatItem(
        icon: Icons.track_changes_rounded,
        label: l10n.avgMatchScore,
        value: '${data.stats.scoreMoyenMatch}%',
        subtitle: data.stats.scoreSubtitle,
        delay: 500,
      ),
      _StatItem(
        icon: Icons.trending_up_rounded,
        label: l10n.simulatedInterviews,
        value: data.stats.entretiensSimules.toString(),
        subtitle: data.stats.entretiensSubtitle,
        delay: 600,
      ),
    ];

    if (isMobile) {
      return Column(
        children: stats
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AnimatedReveal(
                    delay: Duration(milliseconds: s.delay),
                    child: _StatCard(item: s),
                  ),
                ))
            .toList(),
      );
    }

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: s == stats.last ? 0 : 16,
                  ),
                  child: AnimatedReveal(
                    delay: Duration(milliseconds: s.delay),
                    child: _StatCard(item: s),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final int delay;

  _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.delay,
  });
}

// ─── Stat Card ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 20, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.subtitle,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
                fontWeight: FontWeight.w500),
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
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentOffers,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: [
                    Text(
                      l10n.seeAll,
                      style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppColors.orange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.business_rounded,
                color: AppColors.navy, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${offer.company} · ${offer.city}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${offer.compatibilityPercent}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _barColor,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 70,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: offer.compatibilityPercent / 100,
                    backgroundColor: AppColors.border,
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
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.skills,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  l10n.edit,
                  style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skill.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${skill.percent}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: skill.percent / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
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
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.upcomingInterviews,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: [
                    Text(
                      l10n.agenda,
                      style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppColors.orange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (interviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noInterviews,
                      style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.videocam_rounded,
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${interview.company} · $dateStr',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              interview.format,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
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
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_rounded,
                  size: 20, color: AppColors.textGray),
              const SizedBox(width: 12),
              Text(
                l10n.profileVisibility,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                viewsCount.toString(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  height: 0.8,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l10n.viewsThisMonth,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${percentChange.abs()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.vsLastMonth,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
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
