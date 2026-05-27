import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/landing/presentation/pages/landing_page.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'notification_bell.dart';

import 'package:pfe/core/widgets/spline_robot.dart';

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
class AppSidebar extends StatefulWidget {
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
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final ValueNotifier<Offset?> _mouseNotifier = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _mouseNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return MouseRegion(
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPos = box.globalToLocal(event.position);
          _mouseNotifier.value = Offset(
            localPos.dx / box.size.width,
            localPos.dy / box.size.height,
          );
        }
      },
      onExit: (_) {
        _mouseNotifier.value = null;
      },
      child: Container(
        width: 240,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            right: isRtl
                ? BorderSide.none
                : const BorderSide(
                    color: Color(0x1AFFFFFF),
                    width: 1),
            left: isRtl
                ? const BorderSide(
                    color: Color(0x1AFFFFFF),
                    width: 1)
                : BorderSide.none,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: -4,
              offset: Offset(isRtl ? -10 : 10, 0),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // ── Spline 3D background (IgnorePointer so nav stays clickable) ──
                Positioned.fill(
                  child: IgnorePointer(
                    child: SplineRobot(
                      mouseNotifier: _mouseNotifier,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                  ),
                ),
                // ── Gradient overlay for readability ─────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.35, 0.65, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.88),
                          Colors.black.withValues(alpha: 0.62),
                          Colors.black.withValues(alpha: 0.70),
                          Colors.black.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Sidebar content ──────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Brand header ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0x1AFFFFFF),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Logo pill
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.navy, AppColors.orange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orange.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.bolt_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'SkillSpace',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
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
                    const SizedBox(height: 12),
                    // ── Nav section label ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Text(
                        'NAVIGATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // ── Nav items ─────────────────────────────────────────
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
                        isActive: tab == widget.activeTab,
                        onTap: () => widget.onTabSelected(tab),
                        forceDark: true,
                      ),
                    ),
                    const Spacer(),
                    // ── Bottom: theme toggle ──────────────────────────────
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: _ThemeToggle(),
                    ),
                    const SizedBox(height: 8),
                    // ── Logout button ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () =>
                              _showLogoutConfirmation(context, widget.onLogout),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.35),
                              ),
                              color: AppColors.error.withValues(alpha: 0.12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded,
                                    size: 17,
                                    color:
                                        AppColors.error.withValues(alpha: 0.9)),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.logout,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        AppColors.error.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
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

// ─── Mobile Top Bar ─────────────────────────────────────────────────────
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
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark.withValues(alpha: 0.95) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'SkillSpace',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
          const Spacer(),
          NotificationBell(isRecruiter: isRecruiter),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openDrawer(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : AppColors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.orange.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                Icons.menu_rounded,
                color: isDark ? Colors.white : AppColors.navy,
                size: 20,
              ),
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle pill
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Header row
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.navy, AppColors.orange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SkillSpace',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Spline Robot (mobile drawer) ──────────────────────────
                Builder(builder: (context) {
                  final drawerMouseNotifier = ValueNotifier<Offset?>(null);
                  return MouseRegion(
                    onHover: (event) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final localPos = box.globalToLocal(event.position);
                        drawerMouseNotifier.value = Offset(
                          localPos.dx / box.size.width,
                          localPos.dy / box.size.height,
                        );
                      }
                    },
                    onExit: (_) => drawerMouseNotifier.value = null,
                    child: SplineRobot(
                      mouseNotifier: drawerMouseNotifier,
                      width: double.infinity,
                      height: 140,
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Divider(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  height: 1,
                ),
                const SizedBox(height: 10),
                // Nav items
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
                const SizedBox(height: 8),
                Divider(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  height: 1,
                ),
                const SizedBox(height: 8),
                // Logout row
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmation(context, onLogout);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.logout_rounded,
                              color: AppColors.error.withValues(alpha: 0.85),
                              size: 18),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          l10n.logout,
                          style: TextStyle(
                            color: AppColors.error.withValues(alpha: 0.85),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                    ? AppColors.orange.withValues(alpha: 0.12)
                    : AppColors.orange.withValues(alpha: 0.07))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Left accent bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 3,
                height: isActive ? 22 : 0,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.orange.withValues(alpha: 0.45),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isActive ? 10 : 6,
              ),
              // Icon pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark
                          ? AppColors.orange.withValues(alpha: 0.2)
                          : AppColors.orange.withValues(alpha: 0.1))
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  tab.icon,
                  size: 20,
                  color: isActive
                      ? AppColors.orange
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.45)
                          : AppColors.textGray),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  tab.label(context),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? (isDark ? Colors.white : AppColors.textDark)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppColors.textGray),
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.5),
                        blurRadius: 6,
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item (Desktop) ───────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final DashboardTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final bool forceDark;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    this.forceDark = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.isActive || _hovered;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              // Liquid glass base
              color: widget.isActive
                  ? AppColors.orange.withValues(alpha: 0.13)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              // Glowing glass border
              border: Border.all(
                color: widget.isActive
                    ? AppColors.orange.withValues(alpha: 0.50)
                    : _hovered
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.06),
                width: widget.isActive ? 1.5 : 1.0,
              ),
              // Outer glow for active state
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.22),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : _hovered
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.04),
                            blurRadius: 12,
                          )
                        ]
                      : null,
            ),
            child: Row(
              children: [
                // Glowing left accent bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 3,
                  height: widget.isActive ? 22 : 0,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.orange, Color(0xFFFF6B35)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.75),
                              blurRadius: 10,
                              spreadRadius: 0,
                            )
                          ]
                        : null,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: widget.isActive ? 10 : 6,
                ),
                // Frosted glass icon pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? AppColors.orange.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: highlighted
                          ? AppColors.orange.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.10),
                      width: 1,
                    ),
                    boxShadow: highlighted
                        ? [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.30),
                              blurRadius: 12,
                              spreadRadius: -2,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    widget.tab.icon,
                    size: 18,
                    color: highlighted
                        ? AppColors.orange
                        : Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.tab.label(context),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: widget.isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: widget.isActive
                          ? Colors.white
                          : _hovered
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.48),
                      letterSpacing: widget.isActive ? 0.1 : 0,
                    ),
                  ),
                ),
                // Active glow dot
                if (widget.isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.80),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
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

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) => const SizedBox(),
    transitionBuilder: (dialogCtx, anim1, anim2, child) {
      final curve = Curves.easeOutBack.transform(anim1.value);
      return Transform.scale(
        scale: curve,
        child: Opacity(
          opacity: anim1.value.clamp(0.0, 1.0),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 380,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withOpacity(0.9)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.05),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Floating Icon with glow
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.orange.withOpacity(0.2),
                                AppColors.orange.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: AppColors.orange.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: AppColors.orange,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          l10n.logout,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.navy,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Voulez-vous vraiment vous déconnecter de SkillSpace ?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.textGray,
                            fontSize: 15,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Row(
                          children: [
                            Expanded(
                              child: _LogoutButton(
                                label: l10n.cancel.toUpperCase(),
                                isPrimary: false,
                                isDark: isDark,
                                onTap: () => Navigator.of(dialogCtx).pop(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _LogoutButton(
                                label: l10n.logout.toUpperCase(),
                                isPrimary: true,
                                isDark: isDark,
                                onTap: () async {
                                  Navigator.of(dialogCtx).pop();
                                  await context.read<AuthCubit>().logout();
                                  if (context.mounted) {
                                    if (onLogout != null) {
                                      onLogout();
                                    } else {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const LandingPage()),
                                        (route) => false,
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _LogoutButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isDark;
  final VoidCallback onTap;

  const _LogoutButton({
    required this.label,
    required this.isPrimary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
                  color:
                      isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                  width: 1.5,
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textDark),
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
