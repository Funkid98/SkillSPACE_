import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/landing/presentation/pages/landing_page.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';
import '../../../../core/l10n/l10n_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';

enum DashboardTab { tableau, profil, offres, simulation, formations }

extension DashboardTabInfo on DashboardTab {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case DashboardTab.tableau:
        return l10n.dashboard;
      case DashboardTab.profil:
        return l10n.profile;
      case DashboardTab.offres:
        return l10n.jobs;
      case DashboardTab.simulation:
        return l10n.simulation;
      case DashboardTab.formations:
        return l10n.training;
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardTab.tableau:
        return Icons.dashboard_rounded;
      case DashboardTab.profil:
        return Icons.person_rounded;
      case DashboardTab.offres:
        return Icons.work_rounded;
      case DashboardTab.simulation:
        return Icons.chat_bubble_rounded;
      case DashboardTab.formations:
        return Icons.school_rounded;
    }
  }
}

// ─── Desktop Sidebar ──────────────────────────────────────────────────────────
class AppSidebar extends StatelessWidget {
  final DashboardTab activeTab;
  final ValueChanged<DashboardTab> onTabSelected;

  const AppSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: isRtl
              ? BorderSide.none
              : const BorderSide(color: AppColors.border, width: 1),
          left: isRtl
              ? const BorderSide(color: AppColors.border, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Row(
              children: [
                Text('SkillSpace', style: AppTextStyles.navBrand),
              ],
            ),
          ),
          ...DashboardTab.values.where((tab) {
            final role = context.read<AuthCubit>().state.role;
            if (role == UserRole.recruteur) {
              return tab == DashboardTab.tableau || tab == DashboardTab.profil;
            }
            return true;
          }).map(
            (tab) => _NavItem(
              tab: tab,
              isActive: tab == activeTab,
              onTap: () => onTabSelected(tab),
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _LanguageSelector(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: TextButton.icon(
              onPressed: () async {
                await context.read<AuthCubit>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LandingPage()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded,
                  size: 18, color: AppColors.textGray),
              label: Text(
                l10n.logout,
                style: const TextStyle(color: AppColors.textGray, fontSize: 14),
              ),
              style: TextButton.styleFrom(
                alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.watch<L10nCubit>().state;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LangBtn(
              label: 'FR',
              isActive: currentLocale.languageCode == 'fr',
              onTap: () =>
                  context.read<L10nCubit>().setLocale(const Locale('fr')),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _LangBtn(
              label: 'EN',
              isActive: currentLocale.languageCode == 'en',
              onTap: () =>
                  context.read<L10nCubit>().setLocale(const Locale('en')),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _LangBtn(
              label: 'AR',
              isActive: currentLocale.languageCode == 'ar',
              onTap: () =>
                  context.read<L10nCubit>().setLocale(const Locale('ar')),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LangBtn({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? AppColors.navy : AppColors.textGray,
          ),
        ),
      ),
    );
  }
}

// ─── Mobile Top Bar ───────────────────────────────────────────────────────────
class MobileTopBar extends StatelessWidget {
  final DashboardTab activeTab;
  final ValueChanged<DashboardTab> onTabSelected;

  const MobileTopBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  void _openDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MobileDrawer(
        activeTab: activeTab,
        onTabSelected: (tab) {
          Navigator.pop(context);
          onTabSelected(tab);
        },
      ),
    );
  }

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
          GestureDetector(
            onTap: () => _openDrawer(context),
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
    );
  }
}

// ─── Mobile Drawer ────────────────────────────────────────────────────────────
class _MobileDrawer extends StatelessWidget {
  final DashboardTab activeTab;
  final ValueChanged<DashboardTab> onTabSelected;

  const _MobileDrawer({
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          const Row(
            children: [
              Text('SkillSpace', style: AppTextStyles.navBrand),
            ],
          ),
          const SizedBox(height: 24),
          ...DashboardTab.values.map(
            (tab) => _DrawerItem(
              tab: tab,
              isActive: tab == activeTab,
              onTap: () => onTabSelected(tab),
            ),
          ),
          const SizedBox(height: 16),
          const _LanguageSelector(),
          const Divider(height: 40),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded,
                color: AppColors.error, size: 22),
            title: Text(
              l10n.logout,
              style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final DashboardTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? AppColors.iconBg : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                tab.icon,
                size: 22,
                color: isActive ? AppColors.orange : AppColors.textGray,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tab.label(context),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.textDark : AppColors.textGray,
                  ),
                ),
              ),
              if (isActive)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.orange, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item (Desktop) ───────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final DashboardTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.iconBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  size: 20,
                  color: isActive ? AppColors.orange : AppColors.textGray,
                ),
                const SizedBox(width: 12),
                Text(
                  tab.label(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.textDark : AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
