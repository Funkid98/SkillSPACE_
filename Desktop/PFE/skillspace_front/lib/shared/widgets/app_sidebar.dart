import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/landing/presentation/pages/landing_page.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';
import '../../../../core/l10n/l10n_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'notification_bell.dart';
import 'video_background.dart';

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
  final VoidCallback? onLogout;

  const AppSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      width: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white,
        border: Border(
          right: isRtl
              ? BorderSide.none
              : BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.5),
          left: isRtl
              ? BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.5)
              : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isDark ? 30 : 15,
            spreadRadius: -5,
            offset: Offset(isRtl ? -10 : 10, 0),
          ),
        ],
      ),
      child: VideoBackground(
        assetPath: 'assets/sidebar-video.mp4',
        opacity: isDark ? 0.75 : 0.0,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SkillSpace', style: AppTextStyles.navBrand),
                      Builder(
                        builder: (ctx) {
                          final role = ctx.watch<AuthCubit>().state.role;
                          final isRecruiter = role == UserRole.recruteur;
                          return NotificationBell(isRecruiter: isRecruiter);
                        },
                      ),
                    ],
                  ),
                ),
                ...DashboardTab.values.where((tab) {
                  final role = context.read<AuthCubit>().state.role;
                  if (role == UserRole.recruteur) {
                    return tab == DashboardTab.tableau ||
                        tab == DashboardTab.profil;
                  }
                  if (role == UserRole.formateur) {
                    return tab == DashboardTab.tableau ||
                        tab == DashboardTab.profil ||
                        tab == DashboardTab.formations;
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
                  child: _ThemeToggle(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: TextButton.icon(
                    onPressed: () => _showLogoutConfirmation(context, onLogout),
                    icon: const Icon(Icons.logout_rounded,
                        size: 18, color: AppColors.textGray),
                    label: Text(
                      l10n.logout,
                      style: const TextStyle(
                          color: AppColors.textGray, fontSize: 14),
                    ),
                    style: TextButton.styleFrom(
                      alignment:
                          isRtl ? Alignment.centerRight : Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
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



class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: (isDark ? Colors.white : AppColors.border).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ReactiveThemeBtn.fromScratch(
              onTap: () {},
              child: _ThemeBtn(
                icon: Icons.light_mode_rounded,
                label: 'Clair',
                isActive: !isDark,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ReactiveThemeBtn.fromScratch(
              onTap: () {},
              child: _ThemeBtn(
                icon: Icons.dark_mode_rounded,
                label: 'Sombre',
                isActive: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _ThemeBtn({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AppColors.orange : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isActive && !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 14,
              color: isActive
                  ? (isDark ? Colors.white : AppColors.orange)
                  : (isDark ? Colors.white60 : AppColors.textGray)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive
                  ? (isDark ? Colors.white : AppColors.navy)
                  : (isDark ? Colors.white60 : AppColors.textGray),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile Top Bar ───────────────────────────────────────────────────────────
class MobileTopBar extends StatelessWidget {
  final DashboardTab activeTab;
  final ValueChanged<DashboardTab> onTabSelected;
  final VoidCallback? onLogout;

  const MobileTopBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.onLogout,
  });

  void _openDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MobileDrawer(
        activeTab: activeTab,
        onLogout: onLogout,
        onTabSelected: (tab) {
          Navigator.pop(context);
          onTabSelected(tab);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthCubit>().state.role;
    final isRecruiter = role == UserRole.recruteur;
    final isDark = ReactiveMode.isDarkMode(context);
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
          const Text('SkillSpace', style: AppTextStyles.navBrand),
          Row(
            children: [
              NotificationBell(isRecruiter: isRecruiter),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openDrawer(context),
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

// ─── Mobile Drawer ────────────────────────────────────────────────────────────
class _MobileDrawer extends StatelessWidget {
  final DashboardTab activeTab;
  final ValueChanged<DashboardTab> onTabSelected;
  final VoidCallback? onLogout;

  const _MobileDrawer({
    required this.activeTab,
    required this.onTabSelected,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: VideoBackground(
          assetPath: 'assets/sidebar-video.mp4',
          opacity: isDark ? 0.8 : 0.0,
          child: Padding(
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
                ...DashboardTab.values.where((tab) {
                  final role = context.read<AuthCubit>().state.role;
                  if (role == UserRole.recruteur) {
                    return tab == DashboardTab.tableau ||
                        tab == DashboardTab.profil;
                  }
                  if (role == UserRole.formateur) {
                    return tab == DashboardTab.tableau ||
                        tab == DashboardTab.profil ||
                        tab == DashboardTab.formations;
                  }
                  return true;
                }).map(
                  (tab) => _DrawerItem(
                    tab: tab,
                    isActive: tab == activeTab,
                    onTap: () => onTabSelected(tab),
                  ),
                ),
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
                    Navigator.pop(context); // Close drawer
                    _showLogoutConfirmation(context, onLogout);
                  },
                ),
              ],
            ),
          ),
        ),
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
    final isDark = ReactiveMode.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.7))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive
                ? Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.5),
                    width: 1.5)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.15),
                      blurRadius: 15,
                      spreadRadius: -2,
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                tab.icon,
                size: 22,
                color: isActive
                    ? AppColors.orange
                    : (isDark ? Colors.white60 : AppColors.textGray),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tab.label(context),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? (isDark ? Colors.white : AppColors.textDark)
                        : (isDark ? Colors.white60 : AppColors.textGray),
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
    final isDark = ReactiveMode.isDarkMode(context);
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
              color: isActive
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.6))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.4),
                      width: 1)
                  : null,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: -2,
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  size: 20,
                  color: isActive
                      ? AppColors.orange
                      : (isDark ? Colors.white60 : AppColors.textGray),
                ),
                const SizedBox(width: 12),
                Text(
                  tab.label(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? (isDark ? Colors.white : AppColors.textDark)
                        : (isDark ? Colors.white60 : AppColors.textGray),
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

void _showLogoutConfirmation(BuildContext context, [VoidCallback? onLogout]) {
  final l10n = AppLocalizations.of(context);
  final isDark = ReactiveMode.isDarkMode(context);
  showDialog(
    context: context,
    builder: (dialogCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.error.withValues(alpha: 0.1)
                    : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded,
                  color: isDark ? AppColors.error : const Color(0xFFEF4444),
                  size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.logout,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Voulez-vous vraiment vous déconnecter de SkillSpace ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textGray,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(l10n.cancel,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogCtx).pop();
                      await context.read<AuthCubit>().logout();
                      if (context.mounted) {
                        if (onLogout != null) {
                          onLogout();
                        } else {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LandingPage()),
                            (route) => false,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(l10n.logout,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
