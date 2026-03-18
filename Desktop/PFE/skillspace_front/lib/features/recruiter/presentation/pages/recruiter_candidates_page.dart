import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/recruiter_extra_cubits.dart';
import '../../data/models/recruiter_job_offer_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/widgets/animated_reveal.dart';

class RecruiterCandidatesPage extends StatelessWidget {
  const RecruiterCandidatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<RecruiterCandidatesCubit, RecruiterCandidatesState>(
      builder: (context, state) {
        if (state is RecruiterCandidatesLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.orange));
        }
        if (state is RecruiterCandidatesError) {
          return Center(child: Text(state.message));
        }
        final candidates = (state as RecruiterCandidatesLoaded).candidates;

        return _buildContent(context, candidates, l10n);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<CandidateMatch> candidates,
      AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          Responsive.hPad(context), 0, Responsive.hPad(context), 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedReveal(
            direction: RevealDirection.fromTop,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.candidatesPageTitle,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.candidatesPageSubtitle,
                  style:
                      const TextStyle(fontSize: 15, color: AppColors.textGray),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AnimatedReveal(
            delay: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchCandidateHint,
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.textGray),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 20, color: AppColors.textGray),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.savedLabel} (2)',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ...candidates.asMap().entries.map((entry) {
            final index = entry.key;
            final c = entry.value;
            return AnimatedReveal(
              delay: Duration(milliseconds: 300 + (index * 100)),
              direction: RevealDirection.fromBottom,
              child: _CandidateMatchCard(candidate: c),
            );
          }),
        ],
      ),
    );
  }
}

class _CandidateMatchCard extends StatelessWidget {
  final CandidateMatch candidate;
  const _CandidateMatchCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.bg,
                child: Text(
                  candidate.initials,
                  style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          candidate.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                            candidate.isSaved
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: candidate.isSaved
                                ? AppColors.orange
                                : AppColors.textGray),
                        const SizedBox(width: 12),
                        _StatusBadge(status: candidate.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${candidate.role} · ${candidate.location} · ${candidate.experience}',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: candidate.skills
                          .map((s) => _SkillChip(label: s))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${candidate.matchScore}%',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.orange),
                  ),
                  Text(
                    l10n.matchLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.mail_outline_rounded, size: 16),
                    label: Text(l10n.contactCandidate),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: AppColors.navy),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bagdeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: bagdeColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: AppColors.navy, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
