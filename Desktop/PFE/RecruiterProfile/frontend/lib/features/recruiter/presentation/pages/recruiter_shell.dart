import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../recruiter_profile.dart';
import '../../data/repositories/recruiter_repository.dart';
import '../cubits/recruiter_dashboard_cubit.dart';
import '../cubits/recruiter_extra_cubits.dart';
import '../cubits/recruiter_profile_cubit.dart';
import '../../data/repositories/recruiter_job_repository.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../shared/widgets/notification_bell.dart';

class RecruiterShell extends StatefulWidget {
  final RecruiterTab initialTab;
  final VoidCallback? onLogout;
  final Locale? currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  const RecruiterShell({
    super.key,
    this.initialTab = RecruiterTab.dashboard,
    this.onLogout,
    this.currentLocale,
    this.onLocaleChanged,
  });

  @override
  State<RecruiterShell> createState() => _RecruiterShellState();
}

class _RecruiterShellState extends State<RecruiterShell> {
  late RecruiterTab _activeTab;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _restoreTab();
  }

  Future<void> _restoreTab() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('recruiter_active_tab');
    if (savedIndex != null &&
        savedIndex >= 0 &&
        savedIndex < RecruiterTab.values.length) {
      if (mounted) {
        setState(() {
          _activeTab = RecruiterTab.values[savedIndex];
          _loading = false;
        });
        return;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _onTabChanged(RecruiterTab tab, BuildContext context) async {
    setState(() => _activeTab = tab);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('recruiter_active_tab', tab.index);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: Colors.transparent);
    }

    final isMobile = MediaQuery.of(context).size.width < 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => RecruiterProfileCubit(
        repository: RecruiterRepository(apiClient: ApiClient()),
      )..loadProfile(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF5F3EF),
        body: Builder(
          builder: (context) => isMobile
              ? Column(
                  children: [
                    _RecruiterMobileTopBar(
                      activeTab: _activeTab,
                      onTabSelected: (tab) => _onTabChanged(tab, context),
                      onLogout: widget.onLogout,
                      currentLocale: widget.currentLocale,
                      onLocaleChanged: widget.onLocaleChanged,
                    ),
                    Container(
                        height: 1,
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFEAE8E3)),
                    Expanded(child: _buildContent(context)),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecruiterSidebar(
                      activeTab: _activeTab,
                      onTabSelected: (tab) => _onTabChanged(tab, context),
                      onLogout: widget.onLogout,
                      currentLocale: widget.currentLocale,
                      onLocaleChanged: widget.onLocaleChanged,
                    ),
                    Container(
                        width: 1,
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFEAE8E3)),
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
  final VoidCallback? onLogout;
  final Locale? currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  const _RecruiterMobileTopBar({
    required this.activeTab,
    required this.onTabSelected,
    this.onLogout,
    this.currentLocale,
    this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
            bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('SkillSpace',
              style: AppTextStyles.navBrand.copyWith(
                color: isDark ? Colors.white : AppColors.navy,
              )),
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
                      onLogout: onLogout,
                      currentLocale: currentLocale,
                      onLocaleChanged: onLocaleChanged,
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
                    color:
                        isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.menu_rounded,
                      color: isDark ? Colors.white : AppColors.navy, size: 24),
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
  final VoidCallback? onLogout;
  final Locale? currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  const _RecruiterMobileDrawer({
    required this.activeTab,
    required this.onTabSelected,
    this.onLogout,
    this.currentLocale,
    this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ThemeToggle(),
          ),
          const SizedBox(height: 16),
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
                          ? (isDark ? AppColors.orange : AppColors.textDark)
                          : (isDark ? Colors.white60 : AppColors.textGray),
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
          const Divider(height: 40),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded,
                color: AppColors.error, size: 22),
            title: const Text(
              'Déconnexion',
              style: TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              if (onLogout != null) {
                onLogout!();
              }
            },
          ),
        ],
      ),
    );
  }
}
