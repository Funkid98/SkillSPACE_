import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_theme/reactive_theme.dart';
import '../../../profile/presentation/pages/candidate_formation_details_page.dart';
import '../../cubit/job_offers_cubit.dart';
import '../../data/models/job_offer_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../core/utils/responsive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class JobOffersPage extends StatelessWidget {
  const JobOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobOffersCubit, JobOffersState>(
      builder: (context, state) {
        if (state is JobOffersLoading || state is JobOffersInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.orange));
        }
        if (state is JobOffersError) {
          return Center(child: Text(state.message));
        }
        final loaded = state as JobOffersLoaded;
        return _JobOffersContent(state: loaded);
      },
    );
  }
}

class _JobOffersContent extends StatelessWidget {
  final JobOffersLoaded state;
  const _JobOffersContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JobOffersCubit>();
    final l10n = AppLocalizations.of(context);
    final hPad = Responsive.hPad(context);
    final isMobile = Responsive.isMobile(context);

    final contracts = [l10n.all, 'CDI', 'CDD', 'Freelance', 'Stage'];

    final highMatch =
        state.filteredOffers.where((o) => o.compatibilityPercent >= 80).length;

    final isDark = ReactiveMode.isDarkMode(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          AnimatedReveal(
            delay: const Duration(milliseconds: 100),
            direction: RevealDirection.fromTop,
            child: Text(
              l10n.jobs,
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
              l10n.findJobs,
              style: const TextStyle(fontSize: 15, color: AppColors.textGray),
            ),
          ),

          const SizedBox(height: 32),

          // AI match banner
          if (highMatch > 0)
            AnimatedReveal(
              delay: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.orange.withValues(alpha: 0.1)
                      : AppColors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? AppColors.orange.withValues(alpha: 0.3)
                          : AppColors.orange.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '$highMatch ${l10n.aiMatchHint}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Search + filter
          AnimatedReveal(
            delay: const Duration(milliseconds: 400),
            child: isMobile
                ? Column(
                    children: [
                      _buildSearchField(context, cubit, l10n),
                      const SizedBox(height: 12),
                      _buildFilterDropdown(context, state, cubit, contracts),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildSearchField(context, cubit, l10n)),
                      const SizedBox(width: 16),
                      _buildFilterDropdown(context, state, cubit, contracts),
                    ],
                  ),
          ),

          const SizedBox(height: 32),

          // Offers list
          if (state.filteredOffers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noJobsFound,
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.filteredOffers.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: AnimatedReveal(
                      delay: Duration(milliseconds: 500 + (entry.key * 100)),
                      child: _JobCard(offer: entry.value),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
      BuildContext context, JobOffersCubit cubit, AppLocalizations l10n) {
    final isDark = ReactiveMode.isDarkMode(context);
    return TextField(
      onChanged: cubit.search,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textDark),
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.textGray, size: 22),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context, JobOffersLoaded state,
      JobOffersCubit cubit, List<String> options) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedContract ?? options.first,
          items: options
              .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textDark))))
              .toList(),
          onChanged: cubit.filterByContract,
          icon:
              const Icon(Icons.expand_more_rounded, color: AppColors.textGray),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ─── Job Card ──────────────────────────────────────────────────────────────
class _JobCard extends StatefulWidget {
  final JobOffer offer;
  const _JobCard({required this.offer});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _expanded = false;
  bool _viewTracked = false;
  bool _isLoadingFormation = false;

  Future<void> _navigateToFormation(String formationId) async {
    setState(() => _isLoadingFormation = true);
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5004/api/formateur/formations/item/$formationId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CandidateFormationDetailsPage(
                formation: data,
                aiReason: widget.offer.recommendation,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Impossible de charger les détails de la formation.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur de connexion au service de formation.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingFormation = false);
    }
  }

  Future<void> _navigateToFormationByName(String skillName) async {
    setState(() => _isLoadingFormation = true);
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5004/api/formateur/all-formations?query=${Uri.encodeComponent(skillName)}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final formation = data.first;
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CandidateFormationDetailsPage(
                  formation: formation,
                  aiReason:
                      'Formation recommandée pour combler votre lacune en $skillName.',
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Aucune formation pour "$skillName" n\'est disponible actuellement.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de charger les formations.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de connexion au service de formation.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingFormation = false);
    }
  }

  Future<void> _exploreAllFormations() async {
    setState(() => _isLoadingFormation = true);
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5004/api/formateur/all-formations'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> formations = jsonDecode(response.body);
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                _AllFormationsModalContent(formations: formations),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de charger les formations.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de connexion au service de formation.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingFormation = false);
    }
  }

  Color get _compatColor {
    if (widget.offer.compatibilityPercent >= 85) return AppColors.orange;
    if (widget.offer.compatibilityPercent >= 70) return AppColors.orangeLight;
    return Colors.grey.shade500;
  }

  String _getApplyButtonLabel(JobOffer offer, AppLocalizations l10n) {
    if (offer.applicationStatus == 'PENDING') {
      return 'Candidature envoyée';
    } else if (offer.applicationStatus == 'ACCEPTED') {
      return 'Candidature acceptée';
    } else if (offer.applicationStatus == 'INTERVIEW_PLANNED') {
      return 'Entretien planifié';
    } else if (offer.applicationStatus == 'REJECTED') {
      return l10n.apply;
    }
    return l10n.apply;
  }

  Color _getApplyButtonColor(JobOffer offer) {
    if (offer.applicationStatus == 'PENDING') {
      return AppColors.navy;
    } else if (offer.applicationStatus == 'ACCEPTED') {
      return AppColors.success;
    } else if (offer.applicationStatus == 'INTERVIEW_PLANNED') {
      return Colors.indigoAccent;
    } else if (offer.compatibilityPercent < 80 || offer.status == 'ANALYSING') {
      return Colors.grey.shade400; // Slightly darker for white text contrast
    }
    return AppColors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final l10n = AppLocalizations.of(context);
    final isMobile = Responsive.isMobile(context);

    final isDark = ReactiveMode.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.business_rounded,
                      color: isDark ? Colors.white70 : AppColors.navy,
                      size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color:
                                    isDark ? Colors.white : AppColors.textDark,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (!isMobile) _buildCompatBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _ContractBadge(type: offer.contractType),
                            const SizedBox(width: 12),
                            _buildInfoItem(
                                Icons.location_on_rounded, offer.city),
                            const SizedBox(width: 12),
                            _buildInfoItem(
                                Icons.business_rounded, offer.company),
                            const SizedBox(width: 12),
                            _buildInfoItem(Icons.access_time_filled_rounded,
                                offer.postedAgo),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: 20),
              _buildCompatBadge(),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (offer.status == 'ANALYSING')
                        const Text(
                          '( Wait the system finish his analyse )',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        )
                      else ...[
                        Text(
                          '${offer.matchingSkills}/${offer.totalSkills} ${l10n.matchingSkills}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: offer.compatibilityPercent / 100,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : AppColors.border,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_compatColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    if (!_expanded && !_viewTracked) {
                      context
                          .read<JobOffersCubit>()
                          .registerView(widget.offer.id);
                      _viewTracked = true;
                    }
                    setState(() => _expanded = !_expanded);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : AppColors.bg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: isDark ? Colors.white60 : AppColors.textGray,
                    ),
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 20),

              // AI Match Insights
              if (offer.matchingAnalysis.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.white.withOpacity(0.03) : AppColors.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            isDark ? AppColors.borderDark : AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (offer.status == 'ANALYSING')
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.orange),
                            )
                          else
                            const Icon(Icons.psychology_alt_rounded,
                                color: AppColors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            offer.status == 'ANALYSING'
                                ? 'Analyse IA en cours...'
                                : 'Analyse de l\'Intelligence Artificielle',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        offer.matchingAnalysis,
                        style: TextStyle(
                          fontSize: 14,
                          color: offer.status == 'ANALYSING'
                              ? AppColors.orange
                              : (isDark ? Colors.white70 : AppColors.textDark),
                          height: 1.6,
                          fontWeight: offer.status == 'ANALYSING'
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (offer.status != 'ANALYSING') ...[
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 16),
                        if (offer.compatibilityPercent >= 100) ...[
                          // ── Ready Message ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppColors.success.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: AppColors.success, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Vous êtes prêt !',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        offer.recommendation.isNotEmpty
                                            ? offer.recommendation
                                            : 'Votre profil correspond parfaitement aux attentes de ce poste.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white60
                                              : AppColors.textGray,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // ── Formations Recommandées ──
                          const Row(
                            children: [
                              Icon(Icons.school_rounded,
                                  color: AppColors.orange, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Formations Recommandées',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            offer.recommendation.isNotEmpty &&
                                    offer.recommendation != 'N/A'
                                ? offer.recommendation
                                : 'Complétez vos compétences manquantes grâce aux formations ci-dessous.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGray,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (offer.internalFormationId != null) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingFormation
                                    ? null
                                    : () => _navigateToFormation(
                                        offer.internalFormationId!),
                                icon: _isLoadingFormation
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.play_circle_outline,
                                        size: 18),
                                label:
                                    const Text('Voir la formation recommandée'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.orange,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 16),
                          ],
                          if (offer.missingSkills.isNotEmpty)
                            ...offer.missingSkills.map(
                              (skill) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange
                                        .withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.orange
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.orange
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.menu_book_rounded,
                                            size: 16,
                                            color: AppColors.orange),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Formation : $skill',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Combler cette lacune pour ce poste',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textGray,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _isLoadingFormation
                                            ? null
                                            : () => _navigateToFormationByName(
                                                skill),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.orange,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Voir →',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isLoadingFormation
                                    ? null
                                    : _exploreAllFormations,
                                icon:
                                    const Icon(Icons.explore_rounded, size: 16),
                                label: const Text('Explorer les formations',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.orange,
                                  side:
                                      const BorderSide(color: AppColors.orange),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Job Description
              Text(
                l10n.aboutJob,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                offer.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Recommendations moved inside AI Analysis container.
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      context.read<JobOffersCubit>().toggleSave(offer.id),
                  style: IconButton.styleFrom(
                    backgroundColor: offer.isSaved
                        ? AppColors.orange.withValues(alpha: 0.1)
                        : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.bg),
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(
                    offer.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: offer.isSaved
                        ? AppColors.orange
                        : (isDark ? Colors.white38 : AppColors.textGray),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _HoverGradientButton(
                    baseColor: _getApplyButtonColor(offer),
                    label: _getApplyButtonLabel(offer, l10n),
                    onPressed: (offer.compatibilityPercent < 80 ||
                            offer.status == 'ANALYSING' ||
                            (offer.applicationStatus != null &&
                                offer.applicationStatus != 'REJECTED'))
                        ? null
                        : () async {
                            final cubit = context.read<JobOffersCubit>();
                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.orange)),
                            );
                            final error = await cubit.applyToOffer(offer);
                            if (context.mounted) {
                              Navigator.of(context).pop(); // close loading
                            }
                            if (context.mounted) {
                              if (error == null) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: AppColors.orange
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.check_circle_rounded,
                                              color: AppColors.orange,
                                              size: 40),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Candidature envoyée !',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 17),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Votre candidature pour "${offer.title}" a été envoyée au recruteur. Bonne chance !',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: isDark
                                                  ? Colors.white60
                                                  : AppColors.textGray,
                                              fontSize: 14,
                                              height: 1.5),
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.orange,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                            ),
                                            child: const Text('Fermer',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(error),
                                      backgroundColor: Colors.red.shade600),
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textGray),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCompatBadge() {
    final l10n = AppLocalizations.of(context);
    if (widget.offer.status == 'ANALYSING') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.orange,
              ),
            ),
            SizedBox(width: 10),
            Text(
              '( Wait the system finish his analyse )',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.orange,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _compatColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.offer.compatibilityPercent}%',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: _compatColor),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.compatibility,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: _compatColor),
          ),
        ],
      ),
    );
  }
}

class _ContractBadge extends StatelessWidget {
  final ContractType type;
  const _ContractBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (type) {
      case ContractType.cdi:
        color = const Color(0xFF1B2D6B);
        break;
      case ContractType.cdd:
        color = const Color(0xFF0B7A5E);
        break;
      case ContractType.freelance:
        color = const Color(0xFF6B3FA0);
        break;
      case ContractType.stage:
        color = const Color(0xFFB45309);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label(context),
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _HoverGradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color baseColor;

  const _HoverGradientButton({
    required this.onPressed,
    required this.label,
    required this.baseColor,
  });

  @override
  State<_HoverGradientButton> createState() => _HoverGradientButtonState();
}

class _HoverGradientButtonState extends State<_HoverGradientButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: !_isHovered
              ? LinearGradient(colors: [widget.baseColor, widget.baseColor])
              : LinearGradient(
                  colors: [
                    widget.baseColor,
                    widget.baseColor.withValues(alpha: 0.85),
                    widget.baseColor
                        .withBlue(255)
                        .withRed(100)
                        .withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: _isHovered && !isDisabled
              ? [
                  BoxShadow(
                    color: widget.baseColor.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _AllFormationsModalContent extends StatefulWidget {
  final List<dynamic> formations;
  const _AllFormationsModalContent({required this.formations});

  @override
  State<_AllFormationsModalContent> createState() =>
      _AllFormationsModalContentState();
}

class _AllFormationsModalContentState
    extends State<_AllFormationsModalContent> {
  late List<dynamic> _filtered;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.formations;
  }

  void _onSearch(String val) {
    setState(() {
      if (val.trim().isEmpty) {
        _filtered = widget.formations;
      } else {
        final query = val.toLowerCase();
        _filtered = widget.formations.where((f) {
          final title = (f['title'] ?? '').toString().toLowerCase();
          final desc = (f['description'] ?? '').toString().toLowerCase();
          final category = (f['category'] ?? '').toString().toLowerCase();
          final List<dynamic> tags = f['tags'] ?? [];
          final hasTag =
              tags.any((tag) => tag.toString().toLowerCase().contains(query));
          return title.contains(query) ||
              desc.contains(query) ||
              category.contains(query) ||
              hasTag;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
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
                  'Explorer les formations',
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
                  backgroundColor:
                      isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Rechercher une formation (ex: Python, React...)',
              hintStyle:
                  const TextStyle(color: AppColors.textGray, fontSize: 14),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.textGray),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.03) : AppColors.bg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.orange),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined,
                              size: 48,
                              color: AppColors.textGray.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune formation trouvée.',
                            style: TextStyle(
                              color: AppColors.textGray,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final f = _filtered[index];
                      final title = f['title'] ?? 'Formation';
                      final category = f['category'] ?? 'Général';
                      final duration = f['duration'] ?? 'N/A';
                      final rating = (f['rating'] ?? 0.0).toDouble();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.02)
                              : AppColors.bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : AppColors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            color: AppColors.orange,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.star,
                                          color: Colors.amber, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white70
                                              : AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$duration',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CandidateFormationDetailsPage(
                                      formation: f,
                                      aiReason:
                                          'Formation disponible sur la plateforme pour acquérir de nouvelles compétences.',
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.orange,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              child: const Text(
                                'Voir →',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
