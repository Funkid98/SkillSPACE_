import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/job_offers_cubit.dart';
import '../../data/models/job_offer_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../core/utils/responsive.dart';

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
                  color: AppColors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.1)),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
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
                      _buildSearchField(cubit, l10n),
                      const SizedBox(height: 12),
                      _buildFilterDropdown(state, cubit, contracts),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildSearchField(cubit, l10n)),
                      const SizedBox(width: 16),
                      _buildFilterDropdown(state, cubit, contracts),
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

  Widget _buildSearchField(JobOffersCubit cubit, AppLocalizations l10n) {
    return TextField(
      onChanged: cubit.search,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppColors.textGray, size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
      JobOffersLoaded state, JobOffersCubit cubit, List<String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedContract ?? options.first,
          items: options
              .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600))))
              .toList(),
          onChanged: cubit.filterByContract,
          icon:
              const Icon(Icons.expand_more_rounded, color: AppColors.textGray),
          dropdownColor: Colors.white,
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

  Color get _compatColor {
    if (widget.offer.compatibilityPercent >= 85) return AppColors.orange;
    if (widget.offer.compatibilityPercent >= 70) return AppColors.orangeLight;
    return Colors.grey.shade500;
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final l10n = AppLocalizations.of(context);
    final isMobile = Responsive.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.business_rounded,
                      color: AppColors.navy, size: 28),
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
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
                            backgroundColor: AppColors.border,
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
                    decoration: const BoxDecoration(
                      color: AppColors.bg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textGray,
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
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
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
                              : AppColors.textDark,
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
                                    color: AppColors.success
                                        .withValues(alpha: 0.2)),
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
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          offer.recommendation.isNotEmpty
                                              ? offer.recommendation
                                              : 'Votre profil correspond parfaitement aux attentes de ce poste.',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textGray,
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
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textDark,
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
                                          onPressed: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'La page de formation n\'existe pas encore')),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.orange,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
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
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'La page de formation n\'existe pas encore')),
                                    );
                                  },
                                  icon: const Icon(Icons.explore_rounded,
                                      size: 16),
                                  label: const Text('Explorer les formations',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.orange,
                                    side: const BorderSide(
                                        color: AppColors.orange),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
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
                        : AppColors.bg,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(
                    offer.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color:
                        offer.isSaved ? AppColors.orange : AppColors.textGray,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (offer.compatibilityPercent < 80 || offer.status == 'ANALYSING') ? null : () async {
                      final cubit = context.read<JobOffersCubit>();
                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
                      );
                      final error = await cubit.applyToOffer(offer);
                      if (context.mounted) Navigator.of(context).pop(); // close loading
                      if (context.mounted) {
                        if (error == null) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: AppColors.orange.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_circle_rounded, color: AppColors.orange, size: 40),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Candidature envoyée !',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Votre candidature pour "${offer.title}" a été envoyée au recruteur. Bonne chance !',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.textGray, fontSize: 14, height: 1.5),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.orange,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: Colors.red.shade600),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (offer.compatibilityPercent < 80 || offer.status == 'ANALYSING') 
                          ? Colors.grey.shade400 
                          : AppColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      l10n.apply,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
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
