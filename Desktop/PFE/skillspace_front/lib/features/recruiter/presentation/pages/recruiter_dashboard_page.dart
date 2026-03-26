import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/recruiter_dashboard_cubit.dart';
import '../../data/models/recruiter_dashboard_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../core/l10n/app_localizations.dart';

class RecruiterDashboardPage extends StatelessWidget {
  const RecruiterDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecruiterDashboardCubit, RecruiterDashboardState>(
      builder: (context, state) {
        if (state is RecruiterDashboardLoading ||
            state is RecruiterDashboardInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.orange));
        }
        if (state is RecruiterDashboardError) {
          return Center(child: Text(state.message));
        }
        final data = (state as RecruiterDashboardLoaded).data;
        return _DashboardContent(data: data);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final RecruiterDashboardData data;
  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          Responsive.hPad(context), 24, Responsive.hPad(context), 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ─────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 100),
                    direction: RevealDirection.fromTop,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (data.logoUrl != null && data.logoUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data.logoUrl!,
                                height: 32,
                                width: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, _, __) => const Icon(Icons.business, size: 32, color: AppColors.textGray),
                              ),
                            ),
                          ),
                        Text(
                          '${l10n.welcome} ${data.companyName}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 200),
                    direction: RevealDirection.fromTop,
                    child: Text(
                      l10n.recruiterDashboard,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textGray,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ─── Stats Cards ─────────────────────────────────────
          _buildStatsGrid(context, isMobile, l10n),

          const SizedBox(height: 32),

          // ─── Recent Candidates + Active Offers ─────────────
          isMobile
              ? Column(
                  children: [
                    AnimatedReveal(
                      delay: const Duration(milliseconds: 500),
                      direction: RevealDirection.fromBottom,
                      child: _RecentCandidatesCard(
                          candidates: data.recentCandidates),
                    ),
                    const SizedBox(height: 20),
                    AnimatedReveal(
                      delay: const Duration(milliseconds: 600),
                      direction: RevealDirection.fromBottom,
                      child: _ActiveOffersCard(offers: data.activeOffers),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: AnimatedReveal(
                        delay: const Duration(milliseconds: 500),
                        direction: RevealDirection.fromBottom,
                        child: _RecentCandidatesCard(
                            candidates: data.recentCandidates),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: AnimatedReveal(
                        delay: const Duration(milliseconds: 600),
                        direction: RevealDirection.fromBottom,
                        child: _ActiveOffersCard(offers: data.activeOffers),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, bool isMobile, AppLocalizations l10n) {
    final stats = data.stats.asMap().entries.map((entry) {
      final index = entry.key;
      final s = entry.value;
      IconData icon;
      switch (s.iconKey) {
        case 'offres':
          icon = Icons.business_center_rounded;
          break;
        case 'candidatures':
          icon = Icons.people_alt_rounded;
          break;
        case 'vues':
          icon = Icons.visibility_rounded;
          break;
        case 'conversion':
          icon = Icons.trending_up_rounded;
          break;
        default:
          icon = Icons.insert_chart_rounded;
      }
      return _StatItem(
        icon: icon,
        label: _localizeStatLabel(s.iconKey, l10n),
        value: s.value,
        subtitle: s.change,
        delay: 300 + (index * 100),
      );
    }).toList();

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

  String _localizeStatLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'offres':
        return l10n.activeOffers;
      case 'candidatures':
        return l10n.receivedApplications;
      case 'vues':
        return l10n.offerViews;
      case 'conversion':
        return l10n.conversionRate;
      default:
        return key;
    }
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

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _RecentCandidatesCard extends StatelessWidget {
  final List<RecentCandidate> candidates;
  const _RecentCandidatesCard({required this.candidates});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
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
                l10n.recentCandidates,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  l10n.seeAll,
                  style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...candidates.map((c) => _CandidateRow(candidate: c)),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  final RecentCandidate candidate;
  const _CandidateRow({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.bg,
            child: Text(
              candidate.initials,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  candidate.role,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(status: candidate.status),
          const SizedBox(width: 16),
          Text(
            '${candidate.matchScore}%',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color bagdeColor;
    String label;

    if (status == 'Nouveau') {
      bagdeColor = AppColors.orange;
      label = l10n.newStatus;
    } else if (status == 'En revue') {
      bagdeColor = AppColors.navy;
      label = l10n.inReviewStatus;
    } else {
      bagdeColor = AppColors.success;
      label = l10n.interviewPlannedStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bagdeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bagdeColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ActiveOffersCard extends StatelessWidget {
  final List<RecruiterActiveOffer> offers;
  const _ActiveOffersCard({required this.offers});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.activeOffers,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...offers.map((o) => _OfferItem(offer: o)),
        ],
      ),
    );
  }
}

class _OfferItem extends StatelessWidget {
  final RecruiterActiveOffer offer;
  const _OfferItem({required this.offer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${offer.applicationCount} ${l10n.receivedApplications.toLowerCase()}',
                style: const TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
              const SizedBox(width: 8),
              Text(
                '· ${offer.viewCount} ${l10n.offerViews.toLowerCase()}',
                style: const TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
              const Spacer(),
              Text(
                offer.daysAgo,
                style: const TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
