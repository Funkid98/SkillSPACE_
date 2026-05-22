import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/core/network/api_client.dart';
import 'package:reactive_theme/reactive_theme.dart';
import '../cubits/recruiter_extra_cubits.dart';
import '../../data/models/recruiter_job_offer_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../shared/widgets/scheduling_dialog.dart';

class RecruiterCandidatesPage extends StatelessWidget {
  const RecruiterCandidatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = RecruiterLocalizations.of(context);
    final isDark = ReactiveMode.isDarkMode(context);

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
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.candidatesPageSubtitle,
                  style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white60 : AppColors.textGray),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AnimatedReveal(
            delay: const Duration(milliseconds: 200),
            child:
                (Responsive.isMobile(context) || Responsive.isTablet(context))
                    ? Column(
                        children: [
                          _buildSearchField(context, l10n),
                          const SizedBox(height: 16),
                          _buildSavedButton(context, l10n),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildSearchField(context, l10n)),
                          const SizedBox(width: 20),
                          _buildSavedButton(context, l10n),
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
                if (state.groupedMatches.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Text('Aucune offre ou candidat trouvé'),
                    ),
                  );
                }
                return Column(
                  children: state.groupedMatches.map((group) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.work_outline_rounded,
                                  color: AppColors.navy, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                group.offer.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.navy,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : AppColors.bg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${group.candidates.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white60
                                        : AppColors.textGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (group.candidates.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 32, bottom: 24),
                            child: Text(
                              'Aucun match pour cette offre',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white38
                                      : AppColors.textGray,
                                  fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          ...group.candidates.map((c) {
                            return _CandidateMatchCard(
                              candidate: c,
                              offerId: group.offer.id,
                              offerTitle: group.offer.title,
                            );
                          }),
                        const SizedBox(height: 16),
                      ],
                    );
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

  Widget _buildSearchField(BuildContext context, RecruiterLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      key: const ValueKey('candidate_search_field'),
      onChanged: (value) =>
          context.read<RecruiterCandidatesCubit>().filterCandidates(value),
      decoration: InputDecoration(
        hintText: l10n.searchCandidateHint,
        hintStyle: TextStyle(
            color: isDark
                ? Colors.white24
                : AppColors.textGray.withValues(alpha: 0.5)),
        prefixIcon: Icon(Icons.search_rounded,
            size: 22, color: isDark ? Colors.white38 : AppColors.textGray),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
      ),
    );
  }

  Widget _buildSavedButton(BuildContext context, RecruiterLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<RecruiterCandidatesCubit, RecruiterCandidatesState>(
      builder: (context, state) {
        final cubit = context.read<RecruiterCandidatesCubit>();
        final isSavedFilterActive = cubit.isShowingSavedOnly;
        final savedCount = cubit.savedCount;

        return InkWell(
          onTap: () => cubit.toggleSavedFilter(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isSavedFilterActive ? AppColors.navy : (isDark ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isSavedFilterActive ? AppColors.navy : (isDark ? AppColors.borderDark : AppColors.border), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 22, color: isSavedFilterActive ? AppColors.orange : AppColors.textGray),
                const SizedBox(width: 10),
                Text(
                  '${l10n.savedLabel} ($savedCount)',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSavedFilterActive ? Colors.white : (isDark ? Colors.white : AppColors.textDark)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CandidateMatchCard extends StatelessWidget {
  final CandidateMatch candidate;
  final String offerId;
  final String offerTitle;
  const _CandidateMatchCard({
    required this.candidate,
    required this.offerId,
    required this.offerTitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = RecruiterLocalizations.of(context);

    // Layout switch for mobile
    final isCompact =
        Responsive.isMobile(context) || Responsive.isTablet(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isCompact ? 20 : 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border, width: 1),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(context),
                    const SizedBox(width: 16),
                    Expanded(child: _buildMainInfo(context)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildScoreAndAction(context, isCompact),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(context),
                const SizedBox(width: 24),
                Expanded(child: _buildMainInfo(context)),
                const SizedBox(width: 24),
                _buildScoreAndAction(context, isCompact),
              ],
            ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        candidate.initials,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.navy,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMainInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                candidate.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                context.read<RecruiterCandidatesCubit>().toggleSaveCandidate(offerId, candidate.id);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  candidate.isSaved
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 22,
                  color: candidate.isSaved ? AppColors.orange : AppColors.textGray,
                ),
              ),
            ),
            if (!Responsive.isMobile(context)) ...[
              const SizedBox(width: 12),
              _StatusBadge(status: candidate.status),
            ],
          ],
        ),
        if (Responsive.isMobile(context)) ...[
          const SizedBox(height: 4),
          _StatusBadge(status: candidate.status),
        ],
        const SizedBox(height: 6),
        Text(
          '${candidate.role} · ${candidate.location} · ${candidate.experience}',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : AppColors.textGray,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: candidate.skills.map((s) => _SkillChip(label: s)).toList(),
        ),
      ],
    );
  }

  Widget _buildScoreAndAction(BuildContext context, bool isCompact) {
    final l10n = RecruiterLocalizations.of(context);
    return isCompact
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScore(context, l10n),
              _buildActionButton(context, l10n),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildScore(context, l10n),
              const SizedBox(height: 24),
              _buildActionButton(context, l10n),
            ],
          );
  }

  Widget _buildScore(BuildContext context, RecruiterLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (candidate.matchScore == 0 || candidate.status == 'ANALYSING') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.orange),
              ),
              SizedBox(width: 12),
              Text(
                'Analyse...',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.orange,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (candidate.matchScore >= 100) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRÊT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
            Text(
              '${candidate.matchScore}%',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: candidate.matchScore >= 100
                    ? AppColors.success
                    : candidate.matchScore >= 70
                        ? AppColors.success
                        : candidate.matchScore >= 40
                            ? AppColors.warning
                            : AppColors.error,
                height: 1,
              ),
            ),
          ],
        ),
        Text(
          l10n.matchLabel,
          style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : AppColors.textGray,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, RecruiterLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Builder(
      builder: (context) => OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => SchedulingDialog(
              candidateName: candidate.name,
              onConfirm: (date, time, link) {
                _submitContact(context, l10n,
                    date: date, time: time, link: link);
              },
            ),
          );
        },
        icon: const Icon(Icons.mail_outline_rounded, size: 16),
        label: Text(l10n.contactCandidate),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : AppColors.navy,
          side: BorderSide(
              color: isDark ? Colors.white38 : AppColors.navy, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _submitContact(BuildContext context, RecruiterLocalizations l10n,
      {String? date,
      String? time,
      String? link,
      String? rejectionReason}) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      ),
    );

    try {
      final client = ApiClient();
      final response = await client.post('/recruiter/contact', {
        'candidateId': candidate.id,
        'candidateName': candidate.name,
        'offerId': offerId,
        'offerTitle': offerTitle,
        'interviewDate': date,
        'interviewTime': time,
        'meetingLink': link,
        'rejectionReason': rejectionReason,
        'type': rejectionReason != null
            ? 'REJECTION'
            : (date != null ? 'INTERVIEW' : 'CONTACT'),
      });

      if (context.mounted) Navigator.of(context).pop(); // close loading

      if (context.mounted) {
        if (response.statusCode == 200) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    rejectionReason != null
                        ? 'Candidature refusée'
                        : (date != null
                            ? 'Entretien proposé !'
                            : 'Contact envoyé !'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 17),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rejectionReason != null
                        ? 'Le candidat a été informé de votre décision.'
                        : (date != null
                            ? 'Le candidat a été notifié de l\'entretien prévu le $date à $time.'
                            : '${candidate.name} recevra une notification que vous souhaitez le contacter.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textGray, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Fermer',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur (${response.statusCode})'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur réseau. Veuillez réessayer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = RecruiterLocalizations.of(context);
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
        color: bagdeColor.withValues(alpha: 0.1),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
