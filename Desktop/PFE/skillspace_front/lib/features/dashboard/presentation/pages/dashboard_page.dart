import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_theme/reactive_theme.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../data/models/dashboard_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
        final DashboardData data;
        if (state is DashboardSaving) {
          data = state.data;
        } else {
          data = (state as DashboardLoaded).data;
        }
        return _DashboardContent(
            data: data, isSaving: state is DashboardSaving);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardData data;
  final bool isSaving;
  const _DashboardContent({required this.data, this.isSaving = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = ReactiveMode.isDarkMode(context);
    final isMobile = Responsive.isMobile(context);

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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textDark,
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

            // ─── Main Grid Layout (Staggered Columns) ────
            (Responsive.isMobile(context) || Responsive.isTablet(context))
                ? Column(
                    children: [
                      AnimatedReveal(
                          delay: const Duration(milliseconds: 700),
                          child: _RecentOffersCard(offers: data.recentOffers)),
                      const SizedBox(height: 20),
                      AnimatedReveal(
                          delay: const Duration(milliseconds: 800),
                          child: _SkillsCard(
                              skills: data.skills, isSaving: isSaving)),
                      const SizedBox(height: 20),
                      AnimatedReveal(
                          delay: const Duration(milliseconds: 900),
                          child: _UpcomingInterviewsCard(
                              interviews: data.upcomingInterviews)),
                      const SizedBox(height: 20),
                      AnimatedReveal(
                          delay: const Duration(milliseconds: 1000),
                          child: _AICoachCard(
                            advice: data.coachAdvice,
                          )),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Offers + Interviews (Flex 3)
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            AnimatedReveal(
                                delay: const Duration(milliseconds: 700),
                                child: _RecentOffersCard(
                                    offers: data.recentOffers)),
                            const SizedBox(height: 24),
                            AnimatedReveal(
                                delay: const Duration(milliseconds: 900),
                                child: _UpcomingInterviewsCard(
                                    interviews: data.upcomingInterviews)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Column: Skills + Visibility (Flex 2)
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            AnimatedReveal(
                                delay: const Duration(milliseconds: 800),
                                child: _SkillsCard(
                                    skills: data.skills, isSaving: isSaving)),
                            const SizedBox(height: 24),
                            AnimatedReveal(
                                delay: const Duration(milliseconds: 1000),
                                child: _AICoachCard(
                                  advice: data.coachAdvice,
                                )),
                          ],
                        ),
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
        icon: Icons.trending_up_rounded,
        label: l10n.simulatedInterviews,
        value: data.stats.entretiensSimules.toString(),
        subtitle: data.stats.entretiensSubtitle,
        delay: 600,
      ),
    ];

    if (isMobile || Responsive.isTablet(context)) {
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
    final isCompact =
        Responsive.isMobile(context) || Responsive.isTablet(context);
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 20, vertical: isCompact ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 20, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : AppColors.textGray,
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
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textDark,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.subtitle,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : AppColors.textGray,
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
    final isCompact =
        Responsive.isMobile(context) || Responsive.isTablet(context);
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 20 : 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentOffers,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
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
          if (offers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Aucune offre récente',
                    style: TextStyle(color: AppColors.textGray, fontSize: 14)),
              ),
            )
          else
            ...offers.map((o) => _OfferRow(offer: o)),
        ],
      ),
    );
  }
}

class _OfferRow extends StatefulWidget {
  final RecentOffer offer;
  const _OfferRow({required this.offer});

  @override
  State<_OfferRow> createState() => _OfferRowState();
}

class _OfferRowState extends State<_OfferRow> {
  bool _isVisible = false;

  Color get _barColor {
    if (widget.offer.compatibilityPercent >= 85) return AppColors.orange;
    if (widget.offer.compatibilityPercent >= 70) return AppColors.orangeLight;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return VisibilityDetector(
      key: Key('offer_${widget.offer.title}_${widget.offer.company}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_isVisible) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.business_rounded,
                  color: isDark ? Colors.white70 : AppColors.navy, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.offer.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.offer.company} · ${widget.offer.city}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : AppColors.textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                  begin: 0,
                  end: _isVisible
                      ? widget.offer.compatibilityPercent.toDouble()
                      : 0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${value.toInt()}%',
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
                          value: value / 100,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skills Card ───────────────────────────────────────────────────────────
class _SkillsCard extends StatefulWidget {
  final List<UserSkill> skills;
  final bool isSaving;
  const _SkillsCard({required this.skills, this.isSaving = false});

  @override
  State<_SkillsCard> createState() => _SkillsCardState();
}

class _SkillsCardState extends State<_SkillsCard> {
  void _showSkillsModal() {
    final cubit = context.read<DashboardCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: const _SkillsModalContent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCompact =
        Responsive.isMobile(context) || Responsive.isTablet(context);

    // Sort skills by percentage descending
    final sortedSkills = List<UserSkill>.from(widget.skills)
      ..sort((a, b) => b.percent.compareTo(a.percent));

    final displaySkills = sortedSkills.take(4).toList();
    final hasMore = sortedSkills.length > 4;

    final isDark = ReactiveMode.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 20 : 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.skills,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.skills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    const Text('Aucune compétence ajoutée',
                        style:
                            TextStyle(color: AppColors.textGray, fontSize: 14)),
                  ],
                ),
              ),
            )
          else ...[
            ...displaySkills.asMap().entries.map((entry) => _SkillRow(
                  skill: entry.value,
                  index: widget.skills.indexOf(entry.value),
                  editing: false,
                )),
            if (hasMore) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _showSkillsModal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Voir les ${widget.skills.length - 4} autres',
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: AppColors.textGray),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SkillsModalContent extends StatelessWidget {
  const _SkillsModalContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final data = state is DashboardLoaded
            ? state.data
            : (state is DashboardSaving ? state.data : null);
        final isSaving = state is DashboardSaving;

        if (data == null) return const SizedBox.shrink();

        final isDark = ReactiveMode.isDarkMode(context);

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            top: 32,
            left: 28,
            right: 28,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).skills,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : AppColors.bg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: data.skills
                        .asMap()
                        .entries
                        .map((entry) => _SkillRow(
                              skill: entry.value,
                              index: entry.key,
                              editing: false,
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _SkillRow extends StatefulWidget {
  final UserSkill skill;
  final int index;
  final bool editing;
  const _SkillRow(
      {required this.skill, required this.index, required this.editing});

  @override
  State<_SkillRow> createState() => _SkillRowState();
}

class _SkillRowState extends State<_SkillRow> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('skill_${widget.skill.name}_${widget.index}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_isVisible) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
              begin: 0, end: _isVisible ? widget.skill.percent.toDouble() : 0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final isDark = ReactiveMode.isDarkMode(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.skill.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${value.toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.orange : AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? AppColors.borderDark : AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? AppColors.orange : AppColors.navy),
                  ),
                ),
              ],
            );
          },
        ),
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
    final isCompact =
        Responsive.isMobile(context) || Responsive.isTablet(context);
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 20 : 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.upcomingInterviews,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
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
    final isDark = ReactiveMode.isDarkMode(context);
    final dateStr = '${interview.rawDate} à ${interview.rawTime}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : AppColors.iconBg,
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${interview.company} · $dateStr',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (interview.meetingLink != null &&
              interview.meetingLink!.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.only(left: 14, right: 4, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      interview.meetingLink!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppColors.textGray,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.copy_rounded,
                          size: 16,
                          color: isDark ? Colors.white : AppColors.navy),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: interview.meetingLink!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Lien copié dans le presse-papiers')),
                        );
                      },
                      tooltip: 'Copier le lien',
                    ),
                  ),
                ],
              ),
            )
          else
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

// ─── AI Coach Card ────────────────────────────────────────────────────────
class _AICoachCard extends StatelessWidget {
  final String advice;

  const _AICoachCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.surfaceDark, AppColors.surfaceDark.withOpacity(0.8)]
              : [AppColors.navy, AppColors.navy.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: AppColors.borderDark) : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : AppColors.navy.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: AppColors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Coach IA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'CONSEIL DU JOUR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            advice,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}


