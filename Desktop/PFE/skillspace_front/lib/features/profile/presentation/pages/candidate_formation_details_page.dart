import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_toast.dart';
import '../../cubit/formations_cubit.dart';
import '../../data/profile_api.dart';
import 'package:reactive_theme/reactive_theme.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import 'trainer_public_profile_page.dart';

class CandidateFormationDetailsPage extends StatelessWidget {
  final dynamic formation;
  final String? aiReason;

  const CandidateFormationDetailsPage({
    super.key,
    required this.formation,
    this.aiReason,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FormationsCubit(),
      child: _CandidateFormationDetailsView(
        formation: formation,
        aiReason: aiReason,
      ),
    );
  }
}

class _CandidateFormationDetailsView extends StatefulWidget {
  final dynamic formation;
  final String? aiReason;

  const _CandidateFormationDetailsView({
    required this.formation,
    this.aiReason,
  });

  @override
  State<_CandidateFormationDetailsView> createState() =>
      _CandidateFormationDetailsViewState();
}

class _CandidateFormationDetailsViewState
    extends State<_CandidateFormationDetailsView> {
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    // Ensure we have the latest enrolled formations list so the button
    // correctly reflects enrollment status even on first open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<FormationsCubit>();
      if (cubit.state is FormationsInitial) {
        cubit.fetchFormations();
      }
    });
  }

  Future<void> _enrollInFormation() async {
    setState(() => _isEnrolling = true);
    try {
      final formationId = widget.formation['_id'] ?? widget.formation['id'];
      if (formationId == null) throw Exception("ID de formation manquant.");

      final success = await ProfileApi.enrollInFormation(formationId);

      if (success) {
        if (mounted) {
          AppToast.showSuccess(
              context, "Vous êtes maintenant inscrit à cette formation !");
          context.read<FormationsCubit>().fetchFormations();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          AppToast.showError(
              context, "Impossible de s'inscrire à cette formation.");
        }
      }
    } on AlreadyEnrolledException {
      // Already enrolled — refresh the list so the BlocBuilder disables the button
      if (mounted) {
        context.read<FormationsCubit>().fetchFormations();
        AppToast.showError(context, "Vous êtes déjà inscrit à cette formation.");
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = "Erreur réseau. Veuillez vérifier votre connexion.";
        if (e is Exception && e.toString().startsWith('Exception: ')) {
          errorMsg = e.toString().substring(11);
        }
        AppToast.showError(context, errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.formation;
    final isDark = ReactiveMode.isDarkMode(context);
    final title = f['title'] ?? 'Formation';
    final description = f['description'] ??
        'Aucune description disponible pour cette formation.';
    final trainerId = f['trainerId'] != null
        ? (f['trainerId']['_id'] ?? f['trainerId']['id'])
        : null;
    final trainer = f['trainerId'] != null
        ? '${f['trainerId']['firstName'] ?? ''} ${f['trainerId']['lastName'] ?? ''}'
            .trim()
        : 'Formateur';
    final category = f['category'] ?? 'Général';
    final level = f['level'] ?? 'Tous niveaux';
    final duration =
        f['duration'] != null ? '${f['duration']}' : 'Non spécifié';
    final hPad = Responsive.hPad(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        iconTheme:
            IconThemeData(color: isDark ? Colors.white : AppColors.textDark),
        title: Text('Détails de la formation',
            style: TextStyle(
                color: isDark ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(category,
                            style: const TextStyle(
                                color: AppColors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(level,
                            style: TextStyle(
                                color: isDark ? Colors.white70 : AppColors.navy,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(title,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.textDark)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: trainerId != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TrainerPublicProfilePage(
                                            trainerId: trainerId),
                                  ),
                                );
                              }
                            : null,
                        child: Row(
                          children: [
                            Icon(Icons.person,
                                size: 18,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textGray),
                            const SizedBox(width: 8),
                            Text('Par $trainer',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: trainerId != null
                                        ? AppColors.orange
                                        : (isDark
                                            ? Colors.white70
                                            : AppColors.textGray),
                                    fontWeight: FontWeight.w600,
                                    decoration: trainerId != null
                                        ? TextDecoration.underline
                                        : null,
                                    decorationColor: AppColors.orange)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                          width: 1,
                          height: 16,
                          color: isDark ? Colors.white24 : AppColors.border),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < (f['rating'] ?? 0).floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${f['rating'] ?? 0} (${f['reviewCount'] ?? 0} avis)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.white60 : AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.timer,
                          size: 18,
                          color: isDark ? Colors.white60 : AppColors.textGray),
                      const SizedBox(width: 8),
                      Text('$duration heures',
                          style: TextStyle(
                              fontSize: 15,
                              color:
                                  isDark ? Colors.white70 : AppColors.textGray,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('Description',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark)),
                  const SizedBox(height: 12),
                  Text(description,
                      style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white60 : AppColors.textGray,
                          height: 1.6)),
                  if (widget.aiReason != null) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : AppColors.navy.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.navy.withOpacity(0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: isDark ? AppColors.orange : AppColors.navy,
                              size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pourquoi cette formation ?',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.orange
                                            : AppColors.navy,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(widget.aiReason!,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white70
                                            : AppColors.textDark,
                                        height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: BlocBuilder<FormationsCubit, FormationsState>(
                      builder: (context, state) {
                        bool isAlreadyEnrolled = false;
                        if (state is FormationsLoaded) {
                          final formationId = f['_id'] ?? f['id'];
                          isAlreadyEnrolled = state.formations.any((enrolledF) => 
                            (enrolledF['_id'] ?? enrolledF['id']) == formationId
                          );
                        }

                        if (isAlreadyEnrolled) {
                          return ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textGray.withOpacity(0.2),
                              foregroundColor: isDark ? Colors.white60 : AppColors.textGray,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Déjà inscrit à cette formation',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          );
                        }

                        return ElevatedButton(
                          onPressed: _isEnrolling ? null : _enrollInFormation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isEnrolling
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('S\'inscrire à la formation',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
