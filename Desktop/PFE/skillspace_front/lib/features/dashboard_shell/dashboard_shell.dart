import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:pfe/core/network/cookie_service.dart';
import 'package:skillspace/core/app_colors.dart';
import '../../shared/widgets/app_sidebar.dart';
import '../dashboard/cubit/dashboard_cubit.dart';
import '../dashboard/presentation/pages/dashboard_page.dart';
import '../profile/cubit/profile_cubit.dart';
import '../profile/presentation/pages/profile_page.dart';
import '../job_offers/cubit/job_offers_cubit.dart';
import '../job_offers/presentation/pages/job_offers_page.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import '../simulation/cubit/simulation_cubit.dart';
import '../simulation/presentation/pages/simulation_selection_page.dart';
import '../profile/presentation/pages/candidate_formations_page.dart';
import '../profile/cubit/formations_cubit.dart';

class DashboardShell extends StatefulWidget {
  final DashboardTab initialTab;
  final Map<String, dynamic>? initialUserData;
  final VoidCallback? onLogout;
  const DashboardShell({
    super.key,
    this.initialTab = DashboardTab.tableau,
    this.initialUserData,
    this.onLogout,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late DashboardTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadPersistedTab();

    // Safety: Ensure trainers and recruiters don't land on candidate dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = context.read<AuthCubit>().state.role;
      if ((role == UserRole.formateur || role == UserRole.recruteur) &&
          _activeTab == DashboardTab.tableau) {
        setState(() => _activeTab = DashboardTab.profil);
      }
    });
  }

  Future<void> _loadPersistedTab() async {
    try {
      final savedIndex = CookieService.getInt('active_tab_index');
      if (savedIndex != null && savedIndex < DashboardTab.values.length) {
        setState(() {
          _activeTab = DashboardTab.values[savedIndex];
        });
      }
    } catch (e) {
      debugPrint('Error loading persisted tab: $e');
    }
  }

  Future<void> _onTabChanged(DashboardTab tab) async {
    setState(() => _activeTab = tab);
    CookieService.setInt('active_tab_index', tab.index);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final isDark = ReactiveMode.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF5F3EF),
      body: isMobile
          // ─── Mobile Layout ─────────────────────────────────
          ? Column(
              children: [
                MobileTopBar(
                  activeTab: _activeTab,
                  onTabSelected: _onTabChanged,
                  onLogout: widget.onLogout,
                ),
                Container(
                    height: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFEAE8E3)),
                Expanded(child: _buildContent()),
              ],
            )
          // ─── Desktop Layout ────────────────────────────────
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSidebar(
                  activeTab: _activeTab,
                  onTabSelected: _onTabChanged,
                  onLogout: widget.onLogout,
                ),
                Container(
                    width: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFEAE8E3)),
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
          create: (_) => ProfileCubit(initialUserData: widget.initialUserData)
            ..loadProfile(),
          child: const ProfilePage(),
        );
      case DashboardTab.offres:
        return BlocProvider(
          create: (_) => JobOffersCubit()..loadOffers(),
          child: const JobOffersPage(),
        );
      case DashboardTab.simulation:
        return BlocProvider(
          create: (_) => SimulationCubit()..fetchAcceptedOffers(),
          child: const SimulationSelectionPage(),
        );
      case DashboardTab.formations:
        return BlocProvider(
          create: (_) => FormationsCubit()..fetchFormations(),
          child: const CandidateFormationsPage(),
        );
    }
  }
}
