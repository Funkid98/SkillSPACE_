import 'package:flutter/material.dart';
import 'package:skillspace/core/app_colors.dart';
import 'package:skillspace/core/theme/app_text_styles.dart';
import 'package:skillspace/core/utils/responsive.dart';
import 'package:skillspace/shared/widgets/animated_reveal.dart';
import 'package:skillspace/core/l10n/app_localizations.dart';
import 'package:pfe/features/auth/presentation/pages/auth_page.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:skillspace/features/auth/presentation/pages/field_selection_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillspace/features/dashboard_shell/dashboard_shell.dart';
import 'package:skillspace/shared/widgets/app_sidebar.dart';
import 'package:skillspace/features/recruiter/presentation/pages/recruiter_shell.dart';
import 'package:skillspace/features/recruiter/presentation/widgets/recruiter_sidebar.dart';
import '../pages/landing_page.dart';

class NavBar extends StatelessWidget {
  final void Function(GlobalKey) scrollTo;
  const NavBar({super.key, required this.scrollTo});

  void _scrollToSection(GlobalKey key) => scrollTo(key);

  void _goToAuth(BuildContext context, AuthTab tab) {
    final authCubit = context.read<AuthCubit>();
    authCubit.switchTab(tab);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (navContext) => AuthPage(
          onSuccess: () {
            final authState = authCubit.state;
            final role = authState.role;
            final userData = authState.loggedInUser;
            
            Navigator.of(navContext).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) {
                  if (role == UserRole.recruteur) {
                    return const RecruiterShell(initialTab: RecruiterTab.profile);
                  } else if (role == UserRole.formateur) {
                    return DashboardShell(
                      initialTab: DashboardTab.profil,
                      initialUserData: userData,
                    );
                  } else {
                    final sector = userData?['sector'];
                    if (sector == null || sector.isEmpty) {
                      return const FieldSelectionPage();
                    }
                    return DashboardShell(
                      initialTab: DashboardTab.profil,
                      initialUserData: userData,
                    );
                  }
                },
              ),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final l10n = AppLocalizations.of(context);

    return AnimatedReveal(
      duration: const Duration(milliseconds: 500),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 14,
        ),
        child: Row(
          children: [
            const Text('SkillSpace', style: AppTextStyles.navBrand),
            const Spacer(),
            if (!isMobile) ...[
              _NavLink(l10n.features,
                  onTap: () => _scrollToSection(SectionKeys.features)),
              const SizedBox(width: 28),
              _NavLink(l10n.howItWorks,
                  onTap: () => _scrollToSection(SectionKeys.steps)),
              const SizedBox(width: 28),
              _NavLink(l10n.forWhom,
                  onTap: () => _scrollToSection(SectionKeys.audience)),
              const SizedBox(width: 24),
              OutlinedButton(
                  onPressed: () => _goToAuth(context, AuthTab.login),
                  child: Text(l10n.login)),
              const SizedBox(width: 12),
              ElevatedButton(
                  onPressed: () => _goToAuth(context, AuthTab.register),
                  child: Text(l10n.register)),
            ] else
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: AppColors.navy),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Desktop nav link with hover effect
class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, {required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            color: _hovered ? AppColors.orange : AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

// ── Mobile Drawer ────────────────────────────────────────────────────────────
class NavDrawer extends StatelessWidget {
  final void Function(GlobalKey) scrollTo;
  const NavDrawer({super.key, required this.scrollTo});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: brand + close ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SkillSpace', style: AppTextStyles.navBrand),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.bg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textDark,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Nav links ────────────────────────────────────────
              _DrawerLink(
                label: l10n.features,
                onTap: () {
                  Navigator.pop(context);
                  scrollTo(SectionKeys.features);
                },
              ),
              const Divider(color: AppColors.border, height: 1),
              _DrawerLink(
                label: l10n.howItWorks,
                onTap: () {
                  Navigator.pop(context);
                  scrollTo(SectionKeys.steps);
                },
              ),
              const Divider(color: AppColors.border, height: 1),
              _DrawerLink(
                label: l10n.forWhom,
                onTap: () {
                  Navigator.pop(context);
                  scrollTo(SectionKeys.audience);
                },
              ),
              const Divider(color: AppColors.border, height: 1),

              const SizedBox(height: 32),

              const Spacer(),

              // ── Action buttons ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l10n.login),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l10n.register),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _DrawerLink({required this.label, required this.onTap});

  @override
  State<_DrawerLink> createState() => _DrawerLinkState();
}

class _DrawerLinkState extends State<_DrawerLink> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _pressed ? AppColors.navy.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _pressed ? AppColors.navy : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
