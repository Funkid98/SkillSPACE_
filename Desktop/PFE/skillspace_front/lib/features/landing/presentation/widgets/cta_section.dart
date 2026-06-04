import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../shared/widgets/hover_scale.dart';

import 'package:pfe/features/auth/presentation/pages/auth_page.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skillspace/features/dashboard_shell/dashboard_shell.dart';

import '../../../../core/l10n/app_localizations.dart';
import 'package:skillspace/shared/widgets/app_sidebar.dart';
import 'package:recruiter_profile/recruiter_profile.dart';

class CtaSection extends StatefulWidget {
  const CtaSection({super.key});

  @override
  State<CtaSection> createState() => _CtaSectionState();
}

class _CtaSectionState extends State<CtaSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final l10n = AppLocalizations.of(context);

    return Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.hPad(context),
          vertical: 60,
        ),
        child: AnimatedReveal(
            direction: RevealDirection.fromBottom,
            child: AnimatedBuilder(
              animation: _glow,
              builder: (_, child) => GlassmorphicContainer(
                width: double.infinity,
                height: isMobile ? 350 : 320,
                borderRadius: 24,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.navy.withValues(alpha: 0.9),
                    AppColors.navy.withValues(alpha: 0.7),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 60,
                    vertical: isMobile ? 40 : 60,
                  ),
                  child: Column(
                    children: [
                      AnimatedReveal(
                        direction: RevealDirection.fromTop,
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          l10n.ctaTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedReveal(
                        direction: RevealDirection.fade,
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          l10n.ctaSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 15, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AnimatedReveal(
                        direction: RevealDirection.fromBottom,
                        delay: const Duration(milliseconds: 400),
                        child: HoverScale(
                          child: ElevatedButton(
                            onPressed: () {
                              final authCubit = context.read<AuthCubit>();
                              authCubit.switchTab(AuthTab.register);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctaContext) => AuthPage(
                                    onSuccess: () {
                                      final authState = authCubit.state;
                                      final role = authState.role;
                                      final user = authState.loggedInUser;

                                      Navigator.of(ctaContext)
                                          .pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (_) {
                                            if (role == UserRole.recruteur) {
                                              return const RecruiterShell(
                                                  initialTab:
                                                      RecruiterTab.profile);
                                            } else if (role ==
                                                UserRole.formateur) {
                                              return DashboardShell(
                                                initialTab: DashboardTab.profil,
                                                initialUserData: user,
                                              );
                                            } else {
                                              return DashboardShell(
                                                initialTab: DashboardTab.profil,
                                                initialUserData: user,
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
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                            ),
                            child: Text(
                              l10n.btnCreateProfile,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }
}
