import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import '../cubits/trainer_cubit.dart';
import '../models/formation_model.dart';
import '../services/dashboard_service.dart';
import '../widgets/formation_card.dart';

class FormationsScreen extends StatefulWidget {
  const FormationsScreen({super.key});

  @override
  State<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends State<FormationsScreen> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  List<FormationModel> _formations = [];

  @override
  void initState() {
    super.initState();
    _loadFormations();
  }

  Future<void> _loadFormations() async {
    final userId = context.read<AuthCubit>().state.loggedInUser?['id'] ?? '';
    if (userId.isEmpty) return;

    setState(() => _isLoading = true);
    final data = await _dashboardService.getDashboardData(userId);
    if (data != null) {
      setState(() {
        _formations = data.formations;
        // Sort: active (0) > fermée (1) > terminé (2)
        _formations.sort((a, b) {
          int rankA = a.status == 'active' ? 0 : (a.status == 'fermée' ? 1 : 2);
          int rankB = b.status == 'active' ? 0 : (b.status == 'fermée' ? 1 : 2);
          return rankA.compareTo(rankB);
        });
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE9652B)));
    }

    // Read profile completeness from the shared TrainerCubit
    final profileCompleteness =
        context.watch<TrainerCubit>().state.profileData?.profileCompleteness ??
            0;
    final isProfileComplete = profileCompleteness >= 80;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Incomplete Banner ────────────────────────────────
            if (!isProfileComplete)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFE65100), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profil incomplet',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complétez votre profil à 80% minimum pour créer des formations. Progression actuelle\u00a0: $profileCompleteness%',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF8D4A00),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: profileCompleteness / 100,
                              minHeight: 7,
                              backgroundColor: Colors.orange.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE65100)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── Header Row ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes formations',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                Tooltip(
                  message: isProfileComplete
                      ? ''
                      : 'Complétez votre profil à 80% pour créer une formation',
                  child: ElevatedButton.icon(
                    onPressed: isProfileComplete ? () {} : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une formation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isProfileComplete
                          ? const Color(0xFFE9652B)
                          : Colors.grey.shade300,
                      foregroundColor:
                          isProfileComplete ? Colors.white : Colors.grey,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _formations.isEmpty
                ? const Center(child: Text('Aucune formation trouvée.'))
                : Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: _formations
                        .map((f) => FormationCard(
                              formation: f,
                              width: 380,
                              onEdit: () {},
                              onDelete: () async {
                                final success = await _dashboardService
                                    .deleteFormation(f.id!);
                                if (success) _loadFormations();
                              },
                              onClose: () async {
                                final updated = await _dashboardService
                                    .closeFormation(f.id!);
                                if (updated != null) _loadFormations();
                              },
                              onTerminate: () async {
                                final updated = await _dashboardService
                                    .terminateFormation(f.id!);
                                if (updated != null) _loadFormations();
                              },
                            ))
                        .toList(),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
