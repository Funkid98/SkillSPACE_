import 'package:flutter/material.dart';
import 'package:skillspace/shared/widgets/app_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:skillspace/features/dashboard_shell/dashboard_shell.dart';

class FieldSelectionPage extends StatefulWidget {
  const FieldSelectionPage({super.key});

  @override
  State<FieldSelectionPage> createState() => _FieldSelectionPageState();
}

class _FieldSelectionPageState extends State<FieldSelectionPage> {
  String? _selectedSector;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _sectors = [
    {'id': 'Tech', 'name': 'Technologie & IT', 'icon': Icons.computer, 'color': Colors.blue},
    {'id': 'Finance', 'name': 'Finance & Banque', 'icon': Icons.account_balance, 'color': Colors.green},
    {'id': 'Healthcare', 'name': 'Santé & Médical', 'icon': Icons.medical_services, 'color': Colors.red},
    {'id': 'Education', 'name': 'Éducation & Formation', 'icon': Icons.school, 'color': Colors.orange},
    {'id': 'Marketing', 'name': 'Marketing & Comm', 'icon': Icons.campaign, 'color': Colors.purple},
    {'id': 'Art', 'name': 'Art & Design', 'icon': Icons.palette, 'color': Colors.pink},
  ];

  Future<void> _saveSector() async {
    if (_selectedSector == null) return;

    setState(() => _isLoading = true);

    try {
      // AuthCubit.updateSector now handles both backend persistence and local state/SharedPreferences
      await context.read<AuthCubit>().updateSector(_selectedSector!);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboardShell(initialTab: DashboardTab.profil),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 32,
                vertical: 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rocket_launch,
                    size: isMobile ? 48 : 64,
                    color: const Color(0xFFE85D22),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bienvenue sur SkillSpace !',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 24 : 32,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choisis ton domaine de prédilection pour personnaliser ton expérience.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: _sectors.map((sector) {
                      final isSelected = _selectedSector == sector['id'];
                      return InkWell(
                        onTap: () => setState(() => _selectedSector = sector['id']),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isMobile
                              ? (MediaQuery.of(context).size.width - 56) / (MediaQuery.of(context).size.width > 450 ? 2 : 1)
                              : 240,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFE85D22) : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isSelected ? 0.1 : 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (sector['color'] as Color).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  sector['icon'] as IconData,
                                  color: sector['color'] as Color,
                                  size: isMobile ? 24 : 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                sector['name'] as String,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 13 : 15,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: isMobile ? double.infinity : 300,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _selectedSector != null && !_isLoading ? _saveSector : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE85D22),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Continuer vers mon profil',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
