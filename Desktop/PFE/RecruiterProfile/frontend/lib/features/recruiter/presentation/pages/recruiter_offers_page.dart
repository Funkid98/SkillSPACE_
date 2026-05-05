import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/recruiter_extra_cubits.dart';
import '../../data/models/recruiter_job_offer_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/widgets/animated_reveal.dart';

class RecruiterOffersPage extends StatelessWidget {
  const RecruiterOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = RecruiterLocalizations.of(context);

    return BlocBuilder<RecruiterOffersCubit, RecruiterOffersState>(
      builder: (context, state) {
        if (state is RecruiterOffersLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.orange));
        }
        if (state is RecruiterOffersError) {
          return Center(child: Text(state.message));
        }
        if (state is! RecruiterOffersLoaded) {
          return const Center(child: Text("Initialisation..."));
        }
        final offers = state.offers;

        return _buildContent(context, offers, l10n);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<RecruiterJobOffer> offers,
      RecruiterLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          Responsive.hPad(context), 24, Responsive.hPad(context), 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedReveal(
            direction: RevealDirection.fromTop,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myOffersTitle,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.myOffersSubtitle,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.textGray),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showNewOfferDialog(context, l10n),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.newOffer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (offers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text(
                  "Aucune offre n'est disponible.",
                  style: TextStyle(color: AppColors.textGray, fontSize: 16),
                ),
              ),
            ),
          ...offers.asMap().entries.map((entry) {
            final index = entry.key;
            final o = entry.value;
            return AnimatedReveal(
              delay: Duration(milliseconds: 200 + (index * 100)),
              child: _OfferCard(offer: o),
            );
          }),
        ],
      ),
    );
  }

  void _showNewOfferDialog(BuildContext context, RecruiterLocalizations l10n) {
    _showOfferForm(context, l10n);
  }

  void _showOfferForm(BuildContext context, RecruiterLocalizations l10n,
      {RecruiterJobOffer? existingOffer}) {
    final titleController = TextEditingController(text: existingOffer?.title);
    final locationController =
        TextEditingController(text: existingOffer?.location);
    final descController =
        TextEditingController(text: existingOffer?.description);
    final skillsController =
        TextEditingController(text: existingOffer?.requirements.join(', '));
    String selectedType = existingOffer?.type ?? 'Full-time';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Header ─────
              Container(
                padding: const EdgeInsets.fromLTRB(32, 28, 24, 20),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.business_center_rounded,
                          color: AppColors.orange, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            existingOffer == null
                                ? l10n.newOffer
                                : "Modifier l'offre",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            existingOffer == null
                                ? "Remplissez les détails pour publier une nouvelle opportunité"
                                : "Mettez à jour les informations de votre offre",
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textGray),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textGray),
                    ),
                  ],
                ),
              ),

              // ─── Body ───────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Détails de base"),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: titleController,
                        label: "Titre du poste",
                        hint: "ex: Développeur Fullstack Senior",
                        icon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: locationController,
                              label: "Localisation",
                              hint: "ex: Paris, Remote...",
                              icon: Icons.location_on_rounded,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildDropdown(
                              value: selectedType,
                              label: "Type de contrat",
                              items: [
                                'Full-time',
                                'Part-time',
                                'Contract',
                                'Freelance'
                              ],
                              onChanged: (v) => selectedType = v!,
                              icon: Icons.assignment_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle("Description & Missions"),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: descController,
                        label: "Description du poste",
                        hint: "Décrivez les missions et le profil recherché...",
                        icon: Icons.description_rounded,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle("Compétences requises"),
                      const SizedBox(height: 6),
                      const Text(
                        "Séparez les compétences par des virgules pour un meilleur affichage",
                        style:
                            TextStyle(fontSize: 12, color: AppColors.textGray),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: skillsController,
                        label: "Compétences clés",
                        hint: "ex: React, Flutter, Python, Docker...",
                        icon: Icons.psychology_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Footer ─────
              Container(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(28)),
                  border: Border(
                      top: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        foregroundColor: AppColors.textGray,
                      ),
                      child: const Text("Annuler",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isEmpty ||
                            locationController.text.isEmpty ||
                            descController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Veuillez remplir tous les champs obligatoires")),
                          );
                          return;
                        }

                        final requirements = skillsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        final jobPayload = RecruiterJobOffer(
                          id: existingOffer?.id ?? '',
                          recruiter: existingOffer?.recruiter ?? '',
                          title: titleController.text,
                          location: locationController.text,
                          type: selectedType,
                          status: 'Active',
                          description: descController.text,
                          requirements: requirements,
                          candidateCount: existingOffer?.candidateCount ?? 0,
                          viewCount: existingOffer?.viewCount ?? 0,
                        );

                        if (existingOffer == null) {
                          context
                              .read<RecruiterOffersCubit>()
                              .createOffer(jobPayload);
                        } else {
                          context
                              .read<RecruiterOffersCubit>()
                              .updateOffer(existingOffer.id, jobPayload);
                        }
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        existingOffer == null
                            ? "Publier l'offre"
                            : "Enregistrer les modifications",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 16, color: AppColors.orange.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: AppColors.textGray.withValues(alpha: 0.5)),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.orange, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 16, color: AppColors.orange.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(fontSize: 15, color: AppColors.textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.orange, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final RecruiterJobOffer offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final isCompact =
        Responsive.isMobile(context) || Responsive.isTablet(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isCompact ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
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
              Expanded(
                child: Text(
                  offer.title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
              ),
              _StatusBadge(status: offer.status),
              const SizedBox(width: 8),
              _TypeBadge(type: offer.type),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textGray),
              const SizedBox(width: 4),
              Text(
                offer.location,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            offer.description,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textGray, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (offer.requirements.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: offer.requirements
                  .map((req) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.orange.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          req,
                          style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 20),
          isCompact
              ? Column(
                  children: [
                    Row(
                      children: [
                        _buildStat(
                            Icons.people_rounded, '${offer.candidateCount}'),
                        const SizedBox(width: 16),
                        _buildStat(
                            Icons.visibility_rounded, '${offer.viewCount}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: _buildActions(context),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildStat(Icons.people_rounded, '${offer.candidateCount}'),
                    const SizedBox(width: 24),
                    _buildStat(Icons.visibility_rounded, '${offer.viewCount}'),
                    const Spacer(),
                    ..._buildActions(context),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textGray),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      _ActionButton(
        icon: Icons.edit_outlined,
        color: AppColors.textGray,
        onTap: () {
          final recruiterOffersPage =
              context.findAncestorWidgetOfExactType<RecruiterOffersPage>();
          if (recruiterOffersPage != null) {
            recruiterOffersPage._showOfferForm(
                context, RecruiterLocalizations.of(context),
                existingOffer: offer);
          }
        },
      ),
      const SizedBox(width: 8),
      _ActionButton(
        icon: Icons.delete_outline_rounded,
        color: AppColors.error,
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: const Text("Supprimer l'offre",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text(
                  "Voulez-vous vraiment supprimer cette offre ? Cette action est irréversible."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Annuler")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                    child: const Text("Supprimer")),
              ],
            ),
          );
          if (confirm == true) {
            context.read<RecruiterOffersCubit>().deleteOffer(offer.id);
          }
        },
      ),
    ];
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.orange : AppColors.textGray)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isActive ? AppColors.orange : AppColors.textGray,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        type,
        style: const TextStyle(
            color: AppColors.navy, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
