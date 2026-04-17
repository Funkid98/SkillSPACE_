import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/recruiter_sidebar.dart';
import '../cubits/recruiter_dashboard_cubit.dart';
import '../pages/recruiter_dashboard_page.dart';
import '../cubits/recruiter_profile_cubit.dart';
import '../pages/recruiter_profile_page.dart';
import '../../data/repositories/recruiter_repository.dart';
import 'package:pfe/core/network/api_client.dart';
import '../cubits/recruiter_extra_cubits.dart';
import '../../data/repositories/recruiter_job_repository.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';

import '../pages/recruiter_offers_page.dart';
import '../pages/recruiter_candidates_page.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../shared/widgets/notification_bell.dart';

class RecruiterShell extends StatefulWidget {
  final RecruiterTab initialTab;

  const RecruiterShell({
    super.key,
    this.initialTab = RecruiterTab.dashboard,
  });

  @override
  State<RecruiterShell> createState() => _RecruiterShellState();
}

class _RecruiterShellState extends State<RecruiterShell> {
  late RecruiterTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  Future<void> _onTabChanged(RecruiterTab tab, BuildContext context) async {
    setState(() => _activeTab = tab);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_tab_index', tab.index);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return BlocProvider(
      create: (context) => RecruiterProfileCubit(
        repository: RecruiterRepository(apiClient: ApiClient()),
      )..loadProfile(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F3EF),
        body: Builder(
          builder: (context) => isMobile
              ? Column(
                  children: [
                    _RecruiterMobileTopBar(
                      activeTab: _activeTab,
                      onTabSelected: (tab) => _onTabChanged(tab, context),
                    ),
                    Container(height: 1, color: const Color(0xFFEAE8E3)),
                    Expanded(child: _buildContent(context)),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecruiterSidebar(
                      activeTab: _activeTab,
                      onTabSelected: (tab) => _onTabChanged(tab, context),
                    ),
                    Container(width: 1, color: const Color(0xFFEAE8E3)),
                    Expanded(
                      child: _buildContent(context),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    Widget page;
    switch (_activeTab) {
      case RecruiterTab.dashboard:
        page = BlocProvider(
          key: const ValueKey('dashboard'),
          create: (_) => RecruiterDashboardCubit()..loadDashboard(),
          child: const RecruiterDashboardPage(),
        );
        break;
      case RecruiterTab.profile:
        page = const RecruiterProfilePage(key: ValueKey('profile'));
        break;
      case RecruiterTab.offers:
        final authState = context.read<AuthCubit>().state;
        final userId = authState.loggedInUser?['id']?.toString() ?? '';
        
        page = BlocProvider(
          key: const ValueKey('offers'),
          create: (_) => RecruiterOffersCubit(
            repository: RecruiterJobRepository(apiClient: ApiClient()),
            userId: userId,
          )..loadOffers(),
          child: const RecruiterOffersPage(),
        );
        break;
      case RecruiterTab.candidates:
        page = BlocProvider(
          key: const ValueKey('candidates'),
          create: (_) => RecruiterCandidatesCubit(
            repository: RecruiterRepository(apiClient: ApiClient()),
          )..loadCandidates(),
          child: const RecruiterCandidatesPage(),
        );
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: page,
    );
  }
}

class _RecruiterMobileTopBar extends StatelessWidget {
  final RecruiterTab activeTab;
  final ValueChanged<RecruiterTab> onTabSelected;

  const _RecruiterMobileTopBar({
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('SkillSpace', style: AppTextStyles.navBrand),
          Row(
            children: [
              const NotificationBell(isRecruiter: true),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => _RecruiterMobileDrawer(
                      activeTab: activeTab,
                      onTabSelected: (tab) {
                        Navigator.pop(context);
                        onTabSelected(tab);
                      },
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_rounded,
                      color: AppColors.navy, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecruiterMobileDrawer extends StatelessWidget {
  final RecruiterTab activeTab;
  final ValueChanged<RecruiterTab> onTabSelected;

  const _RecruiterMobileDrawer({
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          ...RecruiterTab.values.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final tab = entry.value;
              return AnimatedReveal(
                delay: Duration(milliseconds: 100 + (index * 100)),
                direction: RevealDirection.fromBottom,
                child: ListTile(
                  leading: Icon(tab.icon,
                      color: tab == activeTab
                          ? AppColors.orange
                          : AppColors.textGray),
                  title: Text(
                    tab.label(context),
                    style: TextStyle(
                      color: tab == activeTab
                          ? AppColors.textDark
                          : AppColors.textGray,
                      fontWeight: tab == activeTab
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () => onTabSelected(tab),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
