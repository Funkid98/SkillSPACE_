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

import '../../../auth/presentation/pages/field_selection_page.dart';

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

                              Navigator.of(ctaContext).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) {
                                    if (role == UserRole.recruteur) {
                                      return const RecruiterShell(
                                          initialTab: RecruiterTab.profile);
                                    } else if (role == UserRole.formateur) {
                                      return DashboardShell(
                                        initialTab: DashboardTab.profil,
                                        initialUserData: user,
                                      );
                                    } else {
                                      final sector = user?['sector'];
                                      if (sector == null || sector.isEmpty) {
                                        return const FieldSelectionPage();
                                      }
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
    );
  }
}
