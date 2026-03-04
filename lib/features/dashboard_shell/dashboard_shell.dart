import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../shared/widgets/app_sidebar.dart';
import '../dashboard/cubit/dashboard_cubit.dart';
import '../dashboard/presentation/pages/dashboard_page.dart';
import '../profile/cubit/profile_cubit.dart';
import '../profile/presentation/pages/profile_page.dart';
import '../job_offers/cubit/job_offers_cubit.dart';
import '../job_offers/presentation/pages/job_offers_page.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  DashboardTab _activeTab = DashboardTab.tableau;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: isMobile
          // ─── Mobile Layout ─────────────────────────────────
          ? Column(
              children: [
                MobileTopBar(
                  activeTab: _activeTab,
                  onTabSelected: (tab) => setState(() => _activeTab = tab),
                ),
                Container(height: 1, color: const Color(0xFFEAE8E3)),
                Expanded(child: _buildContent()),
              ],
            )
          // ─── Desktop Layout ────────────────────────────────
          : Row(
              children: [
                AppSidebar(
                  activeTab: _activeTab,
                  onTabSelected: (tab) => setState(() => _activeTab = tab),
                ),
                Container(width: 1, color: const Color(0xFFEAE8E3)),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildContent() {
    switch (_activeTab) {
      case DashboardTab.tableau:
        return BlocProvider(
          create: (_) => DashboardCubit()..loadDashboard(),
          child: const DashboardPage(),
        );
      case DashboardTab.profil:
        return BlocProvider(
          create: (_) => ProfileCubit()..loadProfile(),
          child: const ProfilePage(),
        );
      case DashboardTab.offres:
        return BlocProvider(
          create: (_) => JobOffersCubit()..loadOffers(),
          child: const JobOffersPage(),
        );
      case DashboardTab.simulation:
        return const _ComingSoon(label: 'Simulation entretien');
      case DashboardTab.formations:
        return const _ComingSoon(label: 'Formations');
    }
  }
}

class _ComingSoon extends StatelessWidget {
  final String label;
  const _ComingSoon({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_outlined,
              size: 48, color: Color(0xFF6B7280)),
          const SizedBox(height: 16),
          Text(
            '$label — Bientôt disponible',
            style: const TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
