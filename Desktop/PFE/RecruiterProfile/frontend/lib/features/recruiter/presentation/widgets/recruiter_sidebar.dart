import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../../../shared/widgets/animated_reveal.dart';
import '../cubits/recruiter_profile_cubit.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../shared/widgets/notification_bell.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:pfe/core/widgets/spline_robot.dart';

enum RecruiterTab { dashboard, profile, offers, candidates }

extension RecruiterTabInfo on RecruiterTab {
  String label(BuildContext context) {
    final l10n = RecruiterLocalizations.of(context);
    switch (this) {
      case RecruiterTab.dashboard:
        return l10n.dashboard;
      case RecruiterTab.profile:
        return l10n.profile;
      case RecruiterTab.offers:
        return l10n.jobs;
      case RecruiterTab.candidates:
        return l10n.candidatesPageTitle;
    }
  }

  IconData get icon {
    switch (this) {
      case RecruiterTab.dashboard:
        return Icons.dashboard_rounded;
      case RecruiterTab.profile:
        return Icons.person_rounded;
      case RecruiterTab.offers:
        return Icons.work_rounded;
      case RecruiterTab.candidates:
        return Icons.people_rounded;
    }
  }
}

class RecruiterSidebar extends StatefulWidget {
  final RecruiterTab activeTab;
  final ValueChanged<RecruiterTab> onTabSelected;
  final VoidCallback? onLogout;
  final Locale? currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  const RecruiterSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.onLogout,
    this.currentLocale,
    this.onLocaleChanged,
  });

  @override
  State<RecruiterSidebar> createState() => _RecruiterSidebarState();
}

class _RecruiterSidebarState extends State<RecruiterSidebar> {
  final ValueNotifier<Offset?> _mouseNotifier = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    _mouseNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = RecruiterLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: isDark ? Colors.transparent : Colors.white,
            border: Border(
              right: isRtl
                  ? BorderSide.none
                  : BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.08),
                      width: 1.5),
              left: isRtl
                  ? BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.08),
                      width: 1.5)
                  : BorderSide.none,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isDark ? 30 : 15,
                spreadRadius: -5,
                offset: Offset(isRtl ? -10 : 10, 0),
              ),
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : Colors.white.withOpacity(0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 12, 40),
                    child: BlocBuilder<RecruiterProfileCubit,
                        RecruiterProfileState>(
                      builder: (context, state) {
                        Widget nameWidget;
                        if (state is RecruiterProfileLoaded) {
                          final profile = state.profile;
                          nameWidget = Row(
                            children: [
                              if (profile.logoUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      profile.logoUrl,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, _, __) =>
                                          const Icon(Icons.business,
                                              size: 32,
                                              color: AppColors.textGray),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  profile.entreprise.isNotEmpty
                                      ? profile.entreprise
                                      : 'SkillSpace',
                                  style: AppTextStyles.navBrand.copyWith(
                                    fontSize: 18,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.navy,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        } else {
                          nameWidget = Text('SkillSpace',
                              style: AppTextStyles.navBrand.copyWith(
                                color: isDark ? Colors.white : AppColors.navy,
                              ));
                        }
                        return Row(
                          children: [
                            Expanded(child: nameWidget),
                            const NotificationBell(isRecruiter: true),
                          ],
                        );
                      },
                    ),
                  ),
                  // ── Spline Robot 3D Assistant ────────────────────────────────
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange
                                .withOpacity(isDark ? 0.08 : 0.03),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SplineRobot(
                        mouseNotifier: _mouseNotifier,
                        width: 210,
                        height: 160,
                      ),
                    ),
                  ),
                  ...RecruiterTab.values.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      return AnimatedReveal(
                        delay: Duration(milliseconds: 100 + (index * 100)),
                        direction: RevealDirection.fromLeft,
                        child: _NavItem(
                          tab: tab,
                          isActive: tab == widget.activeTab,
                          onTap: () => widget.onTabSelected(tab),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ThemeToggle(),
                  ),
                  const SizedBox(height: 12),
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
                              color: isDark
                                  ? AppColors.error.withOpacity(0.2)
                                  : AppColors.error.withOpacity(0.15),
                            ),
                            color: AppColors.error.withOpacity(0.05),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded,
                                  size: 17,
                                  color: AppColors.error.withOpacity(0.8)),
                              const SizedBox(width: 10),
                              Text(
                                l10n.logout,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error.withOpacity(0.8),
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
            ),
          ),
        ));
  }

  void _showLogoutConfirmation(BuildContext context, [VoidCallback? onLogout]) {
    final l10n = RecruiterLocalizations.of(context);
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
                          const Text(
                            'Voulez-vous vraiment vous déconnecter de SkillSpace ?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
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
                                      if (widget.onLogout != null) {
                                        widget.onLogout!();
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

class _NavItem extends StatelessWidget {
  final RecruiterTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      ? AppColors.orange.withOpacity(0.1)
                      : AppColors.iconBg)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
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
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? (isDark ? AppColors.orange : AppColors.textDark)
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

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

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
            child: isDark
                ? ReactiveThemeBtn.fromScratch(
                    onTap: () {},
                    child: const ThemeBtn(
                      icon: Icons.light_mode_rounded,
                      label: 'Clair',
                      isActive: false,
                      onTap: null,
                    ),
                  )
                : const ThemeBtn(
                    icon: Icons.light_mode_rounded,
                    label: 'Clair',
                    isActive: true,
                    onTap: null,
                  ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: !isDark
                ? ReactiveThemeBtn.fromScratch(
                    onTap: () {},
                    child: const ThemeBtn(
                      icon: Icons.dark_mode_rounded,
                      label: 'Sombre',
                      isActive: false,
                      onTap: null,
                    ),
                  )
                : const ThemeBtn(
                    icon: Icons.dark_mode_rounded,
                    label: 'Sombre',
                    isActive: true,
                    onTap: null,
                  ),
          ),
        ],
      ),
    );
  }
}

class ThemeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const ThemeBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
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
      ),
    );
  }
}
