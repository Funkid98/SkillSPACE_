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
                    key: const ValueKey('candidate_search_field'),
                    onChanged: (value) => context
                        .read<RecruiterCandidatesCubit>()
                        .filterCandidates(value),
                    decoration: InputDecoration(
                      hintText: l10n.searchCandidateHint,
                      hintStyle:
                          TextStyle(color: AppColors.textGray.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 22, color: AppColors.textGray),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.border, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.orange, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  height: 60, // Match search bar height
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 22, color: AppColors.textGray),
                      const SizedBox(width: 10),
                      Text(
                        '${l10n.savedLabel} (2)',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          BlocBuilder<RecruiterCandidatesCubit, RecruiterCandidatesState>(
            builder: (context, state) {
              if (state is RecruiterCandidatesLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                );
              }
              if (state is RecruiterCandidatesError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Text(state.message),
                  ),
                );
              }
              if (state is RecruiterCandidatesLoaded) {
                if (state.candidates.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Text('Aucun candidat trouvé'),
                    ),
                  );
                }
                return Column(
                  children: state.candidates.map((c) {
                    return _CandidateMatchCard(candidate: c);
                  }).toList(),
                );
              }
              return Container();
            },
          ),
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Initials circle
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.bg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              candidate.initials,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      candidate.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      candidate.isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 20,
                      color: candidate.isSaved ? AppColors.orange : AppColors.textGray,
                    ),
                    const SizedBox(width: 12),
                    _StatusBadge(status: candidate.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${candidate.role} · ${candidate.location} · ${candidate.experience}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidate.skills.map((s) => _SkillChip(label: s)).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Match Score & Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${candidate.matchScore}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.orange,
                  height: 1,
                ),
              ),
              Text(
                l10n.matchLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                label: Text(l10n.contactCandidate),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
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
    } else if (status == 'Entretien planifié') {
      bagdeColor = AppColors.success;
      label = l10n.interviewPlannedStatus;
    } else {
      bagdeColor = AppColors.success;
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bagdeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
