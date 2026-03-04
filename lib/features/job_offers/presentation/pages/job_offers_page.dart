import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/job_offers_cubit.dart';
import '../../data/models/job_offer_model.dart';
import '../../../../core/app_colors.dart';

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

  static const _contracts = ['Tous', 'CDI', 'CDD', 'Freelance', 'Stage'];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JobOffersCubit>();
    final highMatch =
        state.filteredOffers.where((o) => o.compatibilityPercent >= 80).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(36, 32, 36, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Offres d\'emploi',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Trouvez les offres qui correspondent à vos compétences',
            style: TextStyle(fontSize: 14, color: AppColors.textGray),
          ),

          const SizedBox(height: 20),

          // AI match banner
          if (highMatch > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4EE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF5D5C8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up,
                      size: 18, color: AppColors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$highMatch offres avec une compatibilité supérieure à 80% — basé sur l\'analyse de votre CV et compétences.',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Search + filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: cubit.search,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par titre ou entreprise...',
                    hintStyle: const TextStyle(
                        color: AppColors.textGray, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textGray, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDDD8D0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.navy, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDD8D0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedContract ?? 'Tous',
                    items: _contracts
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child:
                                Text(c, style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: cubit.filterByContract,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textGray),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Offers list
          if (state.filteredOffers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Aucune offre trouvée',
                  style: TextStyle(color: AppColors.textGray, fontSize: 15),
                ),
              ),
            )
          else
            ...state.filteredOffers.map(
              (offer) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _JobCard(offer: offer),
              ),
            ),
        ],
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

  Color get _compatColor {
    if (widget.offer.compatibilityPercent >= 85) return AppColors.orange;
    if (widget.offer.compatibilityPercent >= 70) return AppColors.orangeLight;
    return Colors.grey.shade500;
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: job info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            offer.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ContractBadge(type: offer.contractType),
                          const SizedBox(width: 8),
                          Text(
                            offer.salaryRange,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textGray),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.business_outlined,
                              size: 14, color: AppColors.textGray),
                          const SizedBox(width: 4),
                          Text(offer.company,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textGray)),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.textGray),
                          const SizedBox(width: 4),
                          Text(offer.city,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textGray)),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time,
                              size: 14, color: AppColors.textGray),
                          const SizedBox(width: 4),
                          Text(offer.postedAgo,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textGray)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right: compatibility + actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${offer.compatibilityPercent}%',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _compatColor,
                      ),
                    ),
                    const Text(
                      'compatibilité',
                      style: TextStyle(fontSize: 11, color: AppColors.textGray),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Skills bar row
            Row(
              children: [
                Text(
                  '${offer.matchingSkills}/${offer.totalSkills} compétences correspondantes',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: [
                      Text(
                        _expanded ? 'Masquer' : 'Détails',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGray),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.textGray,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: offer.compatibilityPercent / 100,
                minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_compatColor),
              ),
            ),

            // Actions row
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bookmark
                IconButton(
                  onPressed: () =>
                      context.read<JobOffersCubit>().toggleSave(offer.id),
                  icon: Icon(
                    offer.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color:
                        offer.isSaved ? AppColors.orange : AppColors.textGray,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Postuler',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
              ],
            ),

            // Expanded details
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFEAE8E3)),
              const SizedBox(height: 10),
              const Text(
                'À propos du poste',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Ce poste est une excellente opportunité pour rejoindre une équipe dynamique chez ${offer.company}. '
                'Basé à ${offer.city}, vous travaillerez sur des projets innovants avec une équipe talentueuse.',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textGray, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContractBadge extends StatelessWidget {
  final ContractType type;
  const _ContractBadge({required this.type});

  Color get _color {
    switch (type) {
      case ContractType.cdi:
        return const Color(0xFF1B2D6B);
      case ContractType.cdd:
        return const Color(0xFF0B7A5E);
      case ContractType.freelance:
        return const Color(0xFF6B3FA0);
      case ContractType.stage:
        return const Color(0xFFB45309);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
      ),
    );
  }
}
