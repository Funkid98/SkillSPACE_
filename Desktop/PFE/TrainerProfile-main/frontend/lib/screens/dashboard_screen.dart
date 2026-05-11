import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pfe/core/app_colors.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../cubits/trainer_cubit.dart';
import '../cubits/trainer_state.dart';
import '../services/dashboard_service.dart';
import '../widgets/formation_card.dart';
import '../models/formation_model.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showBottomSection = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return BlocBuilder<TrainerCubit, TrainerState>(
      builder: (context, state) {
        if (state.status == TrainerStatus.loading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE9652B)));
        }

        if (state.status == TrainerStatus.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(state.errorMessage ?? 'Erreur lors du chargement.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final userId =
                        context.read<AuthCubit>().state.loggedInUser?['id'] ??
                            '';
                    context.read<TrainerCubit>().fetchAllData(userId);
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (state.dashboardData == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined,
                    color: Colors.grey, size: 48),
                const SizedBox(height: 16),
                const Text('Aucune donnée disponible.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final userId =
                        context.read<AuthCubit>().state.loggedInUser?['id'] ??
                            '';
                    context.read<TrainerCubit>().seedData(userId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE9652B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Initialiser les données de démo'),
                ),
              ],
            ),
          );
        }

        final dashboardData = state.dashboardData!;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: () async {
              final userId =
                  context.read<AuthCubit>().state.loggedInUser?['id'] ?? '';
              await context.read<TrainerCubit>().fetchAllData(userId);
            },
            color: const Color(0xFFE9652B),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(
                        duration: const Duration(milliseconds: 1200),
                        child: _buildHeader(dashboardData)),
                    const SizedBox(height: 32),
                    _buildStatCards(dashboardData),
                    const SizedBox(height: 32),
                    FadeIn(
                        delay: const Duration(milliseconds: 400),
                        child: _buildFormationsHeader()),
                    const SizedBox(height: 24),
                    _buildFormationsGrid(dashboardData),
                    if (dashboardData.formations.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      VisibilityDetector(
                        key: const Key('dashboard-bottom-section'),
                        onVisibilityChanged: (info) {
                          if (info.visibleFraction > 0.1 &&
                              !_showBottomSection) {
                            if (mounted) {
                              setState(() => _showBottomSection = true);
                            }
                          }
                        },
                        child: LayoutBuilder(builder: (context, constraints) {
                          if (constraints.maxWidth < 800) {
                            return Column(
                              children: [
                                FadeInUp(
                                    animate: _showBottomSection,
                                    child: _buildRecentParticipants(
                                        dashboardData)),
                                const SizedBox(height: 32),
                                FadeInUp(
                                    animate: _showBottomSection,
                                    delay: const Duration(milliseconds: 200),
                                    child: _buildGrowthChart(dashboardData)),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 1,
                                  child: FadeInLeft(
                                      animate: _showBottomSection,
                                      duration:
                                          const Duration(milliseconds: 1500),
                                      child: _buildRecentParticipants(
                                          dashboardData))),
                              const SizedBox(width: 32),
                              Expanded(
                                  flex: 2,
                                  child: FadeInRight(
                                      animate: _showBottomSection,
                                      duration:
                                          const Duration(milliseconds: 1500),
                                      child: _buildGrowthChart(dashboardData))),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      FadeInUp(
                          animate: _showBottomSection,
                          child: _buildTopSkills(dashboardData)),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(DashboardData dashboardData) {
    final f = dashboardData.formateur;
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600;
      final isDark = ReactiveMode.isDarkMode(context);

      return _buildGlassCard(
        child: isSmall
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: f.profilePicture.isNotEmpty
                        ? Image.memory(
                            base64Decode(f.profilePicture),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue[50],
                            child: Text(
                              '${(f.firstName.isNotEmpty ? f.firstName[0] : '')}${(f.lastName.isNotEmpty ? f.lastName[0] : '')}'
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${f.firstName} ${f.lastName}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1C1E),
                    ),
                  ),
                  Text(
                    f.jobTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat(
                          '${dashboardData.formations.length}', 'Formations',
                          isSmall: true),
                      _buildHeaderStat(
                          '${dashboardData.stats['totalStudents'] ?? 0}',
                          'Étudiants',
                          isSmall: true),
                      _buildHeaderStat(
                          '${dashboardData.stats['avgRating'] ?? 0.0}',
                          'Note moy.',
                          isRating: true,
                          isSmall: true),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: f.profilePicture.isNotEmpty
                        ? Image.memory(
                            base64Decode(f.profilePicture),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue[50],
                            child: Text(
                              '${(f.firstName.isNotEmpty ? f.firstName[0] : '')}${(f.lastName.isNotEmpty ? f.lastName[0] : '')}'
                                  .toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                          ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${f.firstName} ${f.lastName}',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1C1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          f.jobTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildHeaderStat(
                      '${dashboardData.formations.length}', 'Formations'),
                  _buildHeaderStat(
                      '${dashboardData.stats['totalStudents'] ?? 0}',
                      'Étudiants'),
                  _buildHeaderStat(
                      '${dashboardData.stats['avgRating'] ?? 0.0}', 'Note moy.',
                      isRating: true),
                ],
              ),
      );
    });
  }

  Widget _buildHeaderStat(String value, String label,
      {bool isRating = false, bool isSmall = false}) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Padding(
      padding: EdgeInsets.only(left: isSmall ? 0 : 40.0),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: isSmall ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1C1E),
                ),
              ),
              if (isRating) ...[
                const SizedBox(width: 4),
                Icon(Icons.star,
                    color: const Color(0xFFE9652B), size: isSmall ? 16 : 20),
              ]
            ],
          ),
          Text(label,
              style: TextStyle(
                  color: Colors.grey[500], fontSize: isSmall ? 11 : 13)),
        ],
      ),
    );
  }

  Widget _buildStatCards(DashboardData dashboardData) {
    final stats = dashboardData.stats;
    final realTotalStudents =
        dashboardData.formations.fold<int>(0, (sum, f) => sum + f.studentCount);

    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = (constraints.maxWidth - (24 * 3)) / 4;
      final bool useWrap = cardWidth < 180;

      if (useWrap) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard('Formations crées', '${stats['totalFormations']}',
                Icons.menu_book, const Color(0xFFE8F2FF), Colors.blue,
                width: (constraints.maxWidth - 16) / 2),
            _buildStatCard(
                'Étudiants inscrits',
                '$realTotalStudents',
                Icons.people_outline,
                const Color(0xFFFFF1EB),
                const Color(0xFFE9652B),
                width: (constraints.maxWidth - 16) / 2),
            _buildStatCard('Note moyenne', '${stats['avgRating']} / 5',
                Icons.star_border, const Color(0xFFFFF8E5), Colors.amber,
                width: (constraints.maxWidth - 16) / 2),
            _buildStatCard(
                'Inscriptions ce mois',
                '+${stats['monthlyInscriptions']}',
                Icons.trending_up,
                const Color(0xFFEBFAF2),
                Colors.green,
                width: (constraints.maxWidth - 16) / 2),
          ],
        );
      }

      return Row(
        children: [
          Expanded(
              child: FadeInLeft(
            delay: const Duration(milliseconds: 100),
            child: _buildStatCard(
                'Formations créées',
                '${stats['totalFormations']}',
                Icons.menu_book,
                const Color(0xFFE8F2FF),
                Colors.blue),
          )),
          const SizedBox(width: 24),
          Expanded(
              child: FadeInLeft(
            delay: const Duration(milliseconds: 200),
            child: _buildStatCard(
                'Étudiants inscrits',
                '$realTotalStudents',
                Icons.people_outline,
                const Color(0xFFFFF1EB),
                const Color(0xFFE9652B)),
          )),
          const SizedBox(width: 24),
          Expanded(
              child: FadeInLeft(
            delay: const Duration(milliseconds: 300),
            child: _buildStatCard('Note moyenne', '${stats['avgRating']} / 5',
                Icons.star_border, const Color(0xFFFFF8E5), Colors.amber),
          )),
          const SizedBox(width: 24),
          Expanded(
              child: FadeInLeft(
            delay: const Duration(milliseconds: 400),
            child: _buildStatCard(
                'Inscriptions ce mois',
                '+${stats['monthlyInscriptions']}',
                Icons.trending_up,
                const Color(0xFFEBFAF2),
                Colors.green),
          )),
        ],
      );
    });
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color bgColor, Color iconColor,
      {double? width}) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildFormationsHeader() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Mes formations',
            style:
                GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                final userId =
                    context.read<AuthCubit>().state.loggedInUser?['id'] ?? '';
                context.read<TrainerCubit>().seedData(userId);
              },
              icon:
                  const Icon(Icons.refresh, size: 20, color: Color(0xFF64748B)),
              label: const Text('Données Démo',
                  style: TextStyle(color: Color(0xFF64748B))),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showFormationDialog(null),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Créer une formation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE9652B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormationsGrid(DashboardData dashboardData) {
    final formations = dashboardData.formations;
    return AnimationLimiter(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => ScaleAnimation(
            scale: 0.9,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            if (formations.isEmpty) _buildEmptyFormationMessage(),
            ...formations.map((f) => FormationCard(
                  formation: f,
                  width: 380,
                  onEdit: () => _showFormationDialog(f),
                  onDelete: () => _confirmDelete(f),
                )),
            _buildNewFormationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewFormationCard() {
    final isDark = ReactiveMode.isDarkMode(context);
    return InkWell(
      onTap: () => _showFormationDialog(null),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 380,
        height: 480,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFF8FAFC).withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey[200]!, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFFE9652B), size: 32),
            ),
            const SizedBox(height: 16),
            Text('Nouvelle formation',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text('Partagez votre expertise avec\nles apprenants',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[500], fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFormationMessage() {
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      width: 380,
      height: 480,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey[100]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.amber[200]),
          const SizedBox(height: 24),
          Text(
            'Prêt à lancer votre première formation ?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Créez des contenus interactifs, suivez la progression de vos élèves et développez votre communauté d\'apprentissage.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showFormationDialog(FormationModel? formation) {
    final isEdit = formation != null;
    final titleController = TextEditingController(text: formation?.title ?? '');
    final descController =
        TextEditingController(text: formation?.description ?? '');
    final tagsController =
        TextEditingController(text: formation?.tags.join(', ') ?? '');
    final durationController = TextEditingController(
        text: (formation?.duration ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
    final meetLinkController =
        TextEditingController(text: formation?.meetLink ?? '');
    final dateController = TextEditingController(
        text: formation?.date != null
            ? DateFormat('dd/MM/yyyy').format(formation!.date!)
            : '');
    final timeController = TextEditingController(text: formation?.time ?? '');
    DateTime? selectedDate = formation?.date;
    String selectedLevel = formation?.level ?? 'Débutant';

    final trainerCubit = context.read<TrainerCubit>();
    final authCubit = context.read<AuthCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = ReactiveMode.isDarkMode(dialogContext);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Container(
                  width: 600,
                  padding: const EdgeInsets.all(32),
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE9652B)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.auto_awesome,
                                        color: Color(0xFFE9652B), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                      isEdit
                                          ? 'Modifier la formation'
                                          : 'Créer une nouvelle formation',
                                      style: GoogleFonts.outfit(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Partagez vos compétences avec la communauté SkillSpace.',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 14)),
                          const SizedBox(height: 32),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: _buildTextField(
                                      'Titre de la formation *',
                                      'Ex : React avancé & Performance',
                                      titleController)),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: IconButton(
                                  onPressed: () async {
                                    if (titleController.text.trim().isEmpty) {
                                      Fluttertoast.showToast(
                                          msg: "Entrez d'abord un titre.");
                                      return;
                                    }
                                    Fluttertoast.showToast(
                                        msg: "Génération en cours...");
                                    final content = await trainerCubit
                                        .generateFormationContent(
                                            titleController.text.trim());
                                    if (content != null) {
                                      setDialogState(() {
                                        descController.text =
                                            content['description'] ?? '';
                                        tagsController.text =
                                            (content['tags'] as List?)
                                                    ?.join(', ') ??
                                                '';
                                      });
                                      Fluttertoast.showToast(
                                          msg: "Contenu généré !");
                                    } else {
                                      Fluttertoast.showToast(
                                          msg: "Erreur lors de la génération.");
                                    }
                                  },
                                  icon: const Icon(Icons.auto_awesome,
                                      color: Color(0xFFE9652B)),
                                  tooltip: 'Améliorer avec l\'IA',
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFF7ED),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildTextField(
                              'Description',
                              'Décrivez en quelques phrases ce que les apprenants vont maîtriser...',
                              descController,
                              maxLines: 3),
                          _buildTextField(
                              'Compétences (séparées par des virgules) *',
                              'React, TypeScript, Performance',
                              tagsController),
                          Row(
                            children: [
                              Expanded(
                                  child: _buildTextField('Durée (en heures) *',
                                      'Ex : 12', durationController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ])),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Niveau',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey[200]!),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedLevel,
                                          isExpanded: true,
                                          items: [
                                            'Débutant',
                                            'Intermédiaire',
                                            'Avancé'
                                          ].map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setDialogState(
                                                () => selectedLevel = val!);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          _buildTextField(
                              'Lien de la réunion (Meet, Zoom...) *',
                              'Ex : https://meet.google.com/abc-defg-hij',
                              meetLinkController),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateTimePickerField(
                                  'Date de la formation *',
                                  dateController,
                                  Icons.calendar_today,
                                  () async {
                                    _showCalendarPickerDialog(
                                      dialogContext,
                                      selectedDate,
                                      (date) {
                                        setDialogState(() {
                                          selectedDate = date;
                                          dateController.text =
                                              DateFormat('dd/MM/yyyy')
                                                  .format(date);
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _buildDateTimePickerField(
                                  'Heure *',
                                  timeController,
                                  Icons.access_time,
                                  () async {
                                    final time = await showTimePicker(
                                      context: dialogContext,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setDialogState(() {
                                        timeController.text =
                                            time.format(dialogContext);
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 40),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler',
                                        style: TextStyle(
                                            color: Color(0xFF64748B))),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final title = titleController.text.trim();
                                      final duration =
                                          "${durationController.text.trim()} heures";
                                      final tagsString =
                                          tagsController.text.trim();

                                      if (title.isEmpty) {
                                        Fluttertoast.showToast(
                                            msg: "Le titre est requis.");
                                        return;
                                      }
                                      if (duration.isEmpty) {
                                        Fluttertoast.showToast(
                                            msg: "La durée est requise.");
                                        return;
                                      }
                                      if (tagsString.isEmpty) {
                                        Fluttertoast.showToast(
                                            msg:
                                                "Au moins une compétence est requise.");
                                        return;
                                      }

                                      if (meetLinkController.text
                                          .trim()
                                          .isEmpty) {
                                        Fluttertoast.showToast(
                                            msg:
                                                "Le lien de réunion est requis.");
                                        return;
                                      }

                                      // ── Meet/Zoom Validation ──────────────────────────────────
                                      final meetLink =
                                          meetLinkController.text.trim();
                                      final isMeetLink =
                                          meetLink.contains('meet.google.com');
                                      final isZoomLink =
                                          meetLink.contains('zoom.us');

                                      if (!isMeetLink && !isZoomLink) {
                                        Fluttertoast.showToast(
                                            msg:
                                                "Seuls les liens Google Meet ou Zoom sont acceptés.");
                                        return;
                                      }

                                      if (selectedDate == null) {
                                        Fluttertoast.showToast(
                                            msg: "La date est requise.");
                                        return;
                                      }
                                      if (timeController.text.trim().isEmpty) {
                                        Fluttertoast.showToast(
                                            msg: "L'heure est requise.");
                                        return;
                                      }

                                      // ── Duplicate Check ──────────────────────────────────────
                                      final currentDashboardData =
                                          trainerCubit.state.dashboardData;
                                      if (currentDashboardData == null) return;

                                      final tags = tagsString
                                          .split(',')
                                          .map((e) => e.trim())
                                          .where((e) => e.isNotEmpty)
                                          .toList();

                                      final isDuplicate = currentDashboardData
                                          .formations
                                          .any((f) {
                                        // Ignore current formation if editing
                                        if (isEdit && f.id == formation.id) {
                                          return false;
                                        }

                                        final sameTitle =
                                            f.title.trim().toLowerCase() ==
                                                title.trim().toLowerCase();
                                        final sameDate = f.date != null &&
                                            selectedDate != null &&
                                            f.date!.year ==
                                                selectedDate!.year &&
                                            f.date!.month ==
                                                selectedDate!.month &&
                                            f.date!.day == selectedDate!.day;
                                        final sameLink =
                                            f.meetLink!.trim() == meetLink;

                                        // Skills check
                                        final sameTags = f.tags.length ==
                                                tags.length &&
                                            f.tags
                                                .every((t) => tags.contains(t));

                                        return sameTitle &&
                                            sameDate &&
                                            sameLink &&
                                            sameTags;
                                      });

                                      if (isDuplicate) {
                                        Fluttertoast.showToast(
                                            msg:
                                                "Une formation identique existe déjà pour cette date.");
                                        return;
                                      }

                                      final userId =
                                          authCubit.state.loggedInUser?['id'] ??
                                              '';
                                      final newFData = FormationModel(
                                        id: formation?.id ?? '',
                                        trainerId:
                                            formation?.trainerId ?? userId,
                                        title: title,
                                        description: descController.text.trim(),
                                        tags: tagsString
                                            .split(',')
                                            .map((e) => e.trim())
                                            .where((e) => e.isNotEmpty)
                                            .toList(),
                                        duration: duration,
                                        level: selectedLevel,
                                        category:
                                            formation?.category ?? 'General',
                                        studentCount:
                                            formation?.studentCount ?? 0,
                                        rating: formation?.rating ?? 0.0,
                                        reviewCount:
                                            formation?.reviewCount ?? 0,
                                        price: formation?.price ?? 0.0,
                                        imageUrl: formation?.imageUrl ?? '',
                                        meetLink:
                                            meetLinkController.text.trim(),
                                        date: selectedDate,
                                        time: timeController.text.trim(),
                                      );

                                      bool success;
                                      if (isEdit) {
                                        success =
                                            await trainerCubit.editFormation(
                                                formation.id, newFData);
                                      } else {
                                        success = await trainerCubit
                                            .addFormation(userId, newFData);
                                      }

                                      if (success) {
                                        if (!dialogContext.mounted) return;
                                        Navigator.pop(dialogContext);
                                        Fluttertoast.showToast(
                                            msg: isEdit
                                                ? "Formation mise à jour !"
                                                : "Formation créée !");
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE9652B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: Text(isEdit
                                        ? 'Enregistrer'
                                        : 'Créer la formation'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ]),
                  ),
                ));
          },
        );
      },
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters}) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  fontSize: 14),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark ? AppColors.orange : const Color(0xFFE9652B),
                    width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePickerField(String label,
      TextEditingController controller, IconData icon, VoidCallback onTap) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black)),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: IgnorePointer(
              child: TextField(
                controller: controller,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Sélectionner',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey[400],
                      fontSize: 14),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF8FAFC),
                  prefixIcon:
                      Icon(icon, size: 20, color: const Color(0xFFE9652B)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.grey[200]!),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(FormationModel formation) {
    final trainerCubit = context.read<TrainerCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la formation ?'),
        content: Text(
            'Voulez-vous vraiment supprimer "${formation.title}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final success = await trainerCubit.removeFormation(formation.id);
              if (success) {
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                Fluttertoast.showToast(msg: "Formation supprimée");
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentParticipants(DashboardData dashboardData) {
    final isDark = ReactiveMode.isDarkMode(context);
    final rawStudents = (dashboardData.stats['recentStudents'] as List?) ?? [];

    // Filter: Only show students enrolled in the trainer's active formations
    final trainerFormations = dashboardData.formations
        .map((f) => f.title.trim().toLowerCase())
        .toList();

    final students = rawStudents.where((s) {
      final courseName = (s['course'] ?? '').toString().trim().toLowerCase();
      return trainerFormations.contains(courseName);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Participants récents',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 24),
          if (students.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.people_outline,
                        size: 48, color: Colors.grey[200]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun participant pour le moment',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Les nouveaux inscrits apparaîtront ici.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ...students.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            isDark ? Colors.white10 : Colors.blue[50],
                        child: Text(
                            (s['name'] != null &&
                                    s['name'].toString().isNotEmpty)
                                ? s['name'].toString()[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color:
                                    isDark ? AppColors.orange : Colors.blue)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name'] ?? 'Étudiant',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black)),
                          Text(s['course'] ?? '',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12)),
                        ],
                      )),
                      Text(s['time'],
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(DashboardData dashboardData) {
    final isDark = ReactiveMode.isDarkMode(context);
    final growth = dashboardData.stats['growthData'] as List;
    return SizedBox(
      height: 400,
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFFE9652B)),
                const SizedBox(width: 8),
                Text('Croissance des inscriptions',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: dashboardData.stats['totalStudents'] < 10
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insights,
                              size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Analyse de croissance bientôt disponible',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Revenez après votre premier mois d\'activité pour\nvisualiser votre progression détaillée.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (growth
                                    .map((e) => (e['count'] as num).toDouble())
                                    .reduce((a, b) => a > b ? a : b) *
                                1.2)
                            .clamp(20, 1000)
                            .toDouble()
                            .ceilToDouble(),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= growth.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(growth[value.toInt()]['month'],
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87)),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(value.toInt().toString(),
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey[600],
                                      fontSize: 12));
                            },
                            interval: (growth
                                        .map((e) =>
                                            (e['count'] as num).toDouble())
                                        .reduce((a, b) => a > b ? a : b) /
                                    4)
                                .clamp(5, 500)
                                .toDouble()
                                .ceilToDouble(),
                          )),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark ? Colors.white10 : Colors.grey[100],
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                            growth.length,
                            (i) => BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: _showBottomSection
                                          ? growth[i]['count'].toDouble()
                                          : 0,
                                      color: const Color(0xFFE9652B),
                                      width: 32,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6)),
                                    ),
                                  ],
                                )),
                      ),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutQuart,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSkills(DashboardData dashboardData) {
    final isDark = ReactiveMode.isDarkMode(context);
    final formations = dashboardData.stats['topSkills'] as List;
    final maxCount = formations.isNotEmpty
        ? (formations.first['count'] as num).toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Formations les plus suivies',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (formations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.auto_graph_outlined,
                        size: 48, color: Colors.grey[200]),
                    const SizedBox(height: 16),
                    Text(
                      'Données de performance bientôt disponibles',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...formations.map((f) => Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(f['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('${f['count']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutQuart,
                      tween: Tween<double>(
                        begin: 0,
                        end: _showBottomSection
                            ? (maxCount > 0
                                ? (f['count'] as num) / maxCount
                                : 0)
                            : 0,
                      ),
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor:
                              isDark ? Colors.white10 : Colors.blue[50],
                          color: isDark
                              ? AppColors.orange
                              : const Color(0xFF1A1C1E),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                )),
        ],
      ),
    );
  }

  void _showCalendarPickerDialog(BuildContext context, DateTime? initialDate,
      Function(DateTime) onSelected) async {
    final values = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        calendarType: CalendarDatePicker2Type.single,
        selectedDayHighlightColor: const Color(0xFFE9652B),
        okButtonTextStyle: const TextStyle(
          color: Color(0xFFE9652B),
          fontWeight: FontWeight.bold,
        ),
        cancelButtonTextStyle: const TextStyle(color: Colors.grey),
      ),
      dialogSize: const Size(325, 400),
      value: [initialDate ?? DateTime.now()],
      borderRadius: BorderRadius.circular(20),
      dialogBackgroundColor: Colors.white,
    );

    if (values != null && values.isNotEmpty && values[0] != null) {
      onSelected(values[0]!);
    }
  }

  Widget _buildGlassCard(
      {required Widget child, EdgeInsets? padding, double? height}) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.white.withOpacity(0.4),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(24),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      ),
    );
  }
}
