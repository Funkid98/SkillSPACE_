import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
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
  final String _userId = '507f1f77bcf86cd799439011';
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
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE9652B)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une formation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE9652B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    children: _formations.map((f) => FormationCard(
                      formation: f,
                      width: 380, // Slightly wider for a grid feel on desktop
                    )).toList(),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
