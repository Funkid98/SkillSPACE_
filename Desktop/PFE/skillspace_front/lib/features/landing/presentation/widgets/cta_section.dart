import 'package:flutter/material.dart';
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
import 'package:skillspace/features/recruiter/presentation/pages/recruiter_shell.dart';
import 'package:skillspace/features/recruiter/presentation/widgets/recruiter_sidebar.dart';

class CtaSection extends StatelessWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.hPad(context),
        vertical: 60,
      ),
      child: AnimatedReveal(
        direction: RevealDirection.fromBottom,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 60,
            vertical: isMobile ? 40 : 60,
          ),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(24),
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
                      context.read<AuthCubit>().switchTab(AuthTab.register);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctaContext) => AuthPage(
                            onSuccess: () {
                              final role = context.read<AuthCubit>().state.role;
                              final user = context.read<AuthCubit>().state.loggedInUser;
                              Navigator.pop(ctaContext);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => role == UserRole.recruteur
                                      ? const RecruiterShell(initialTab: RecruiterTab.profile)
                                      : DashboardShell(
                                          initialTab: DashboardTab.profil,
                                          initialUserData: user,
                                        ),
                                ),
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
    );
  }
}
