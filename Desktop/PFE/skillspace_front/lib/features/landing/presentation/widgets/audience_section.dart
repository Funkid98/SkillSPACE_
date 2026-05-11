import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../shared/widgets/hover_scale.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../features/dashboard_shell/dashboard_shell.dart';
import '../../../../shared/widgets/app_sidebar.dart';
import 'package:recruiter_profile/recruiter_profile.dart';
import 'package:pfe/features/auth/presentation/pages/auth_page.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/pages/field_selection_page.dart';

class _CardItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
  final bool highlighted;
  final VoidCallback onTap;
  const _CardItem(this.icon, this.title, this.subtitle, this.features,
      {this.highlighted = false, required this.onTap});
}

class AudienceSection extends StatelessWidget {
  const AudienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 1000;
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final cards = [
      _CardItem(
        Icons.business_center_outlined,
        l10n.roleRecruiter,
        l10n.roleRecruiterSub,
        [
          l10n.recruiterFeat1,
          l10n.recruiterFeat2,
          l10n.recruiterFeat3,
          l10n.recruiterFeat4,
        ],
        onTap: () {
          final authCubit = context.read<AuthCubit>();
          final authState = authCubit.state;
          if (authState.loggedInUser != null) {
            final user = authState.loggedInUser;
            final role = authState.role;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => role == UserRole.recruteur
                    ? const RecruiterShell(initialTab: RecruiterTab.profile)
                    : (user?['sector'] == null ||
                            user!['sector'].toString().isEmpty)
                        ? const FieldSelectionPage()
                        : DashboardShell(
                            initialTab: DashboardTab.profil,
                            initialUserData: user,
                          ),
              ),
            );
          } else {
            // Need to change role before opening AuthPage
            authCubit.selectRole(UserRole.recruteur);
            authCubit.switchTab(AuthTab.register);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (audContext) => AuthPage(
                  onSuccess: () {
                    final currentAuthState = authCubit.state;
                    final role = currentAuthState.role;
                    final user = currentAuthState.loggedInUser;

                    Navigator.of(audContext).pushAndRemoveUntil(
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
                            if (sector == null || sector.toString().isEmpty) {
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
          }
        },
      ),
      _CardItem(
          Icons.person_outline,
          l10n.roleCandidate,
          l10n.roleCandidateSub,
          [
            l10n.candidateFeat1,
            l10n.candidateFeat2,
            l10n.candidateFeat3,
            l10n.candidateFeat4,
          ],
          highlighted: true, onTap: () {
        final authCubit = context.read<AuthCubit>();
        final authState = authCubit.state;

        if (authState.loggedInUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                final user = authState.loggedInUser;
                final sector = user?['sector'];
                if (sector == null || sector.toString().isEmpty) {
                  return const FieldSelectionPage();
                }
                return DashboardShell(
                  initialTab: DashboardTab.profil,
                  initialUserData: user,
                );
              },
            ),
          );
        } else {
          authCubit.switchTab(AuthTab.register);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (audContext) => AuthPage(
                onSuccess: () {
                  final currentAuthState = authCubit.state;

                  Navigator.of(audContext).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) {
                        final user = currentAuthState.loggedInUser;
                        final sector = user?['sector'];
                        if (sector == null || sector.toString().isEmpty) {
                          return const FieldSelectionPage();
                        }
                        return DashboardShell(
                          initialTab: DashboardTab.profil,
                          initialUserData: user,
                        );
                      },
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
          );
        }
      }),
      _CardItem(
        Icons.menu_book_outlined,
        l10n.roleTrainer,
        l10n.roleTrainerSub,
        [
          l10n.trainerFeat1,
          l10n.trainerFeat2,
          l10n.trainerFeat3,
          l10n.trainerFeat4,
        ],
        onTap: () {
          final authCubit = context.read<AuthCubit>();
          final authState = authCubit.state;
          if (authState.loggedInUser != null) {
            final user = authState.loggedInUser;
            final role = authState.role;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => role == UserRole.recruteur
                    ? const RecruiterShell(initialTab: RecruiterTab.profile)
                    : role == UserRole.formateur
                        ? DashboardShell(
                            initialTab: DashboardTab.profil,
                            initialUserData: user,
                          )
                        : (user?['sector'] == null ||
                                user!['sector'].toString().isEmpty)
                            ? const FieldSelectionPage()
                            : DashboardShell(
                                initialTab: DashboardTab.profil,
                                initialUserData: user,
                              ),
              ),
            );
          } else {
            authCubit.selectRole(UserRole.formateur);
            authCubit.switchTab(AuthTab.register);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (audContext) => AuthPage(
                  onSuccess: () {
                    final currentAuthState = authCubit.state;
                    final role = currentAuthState.role;
                    final user = currentAuthState.loggedInUser;
                    Navigator.pop(audContext);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          if (role == UserRole.formateur) {
                            return DashboardShell(
                              initialTab: DashboardTab.profil,
                              initialUserData: user,
                            );
                          } else if (role == UserRole.recruteur) {
                            return const RecruiterShell(
                                initialTab: RecruiterTab.profile);
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
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    ];

    final directions = isAr
        ? [
            RevealDirection.fromRight,
            RevealDirection.fromBottom,
            RevealDirection.fromLeft,
          ]
        : [
            RevealDirection.fromLeft,
            RevealDirection.fromBottom,
            RevealDirection.fromRight,
          ];

    return Container(
      color: Colors.black.withValues(alpha: 0.02),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.hPad(context),
        vertical: 80,
      ),
      child: Column(
        children: [
          AnimatedReveal(
            direction: RevealDirection.fromTop,
            child: Text(l10n.sectionAudienceLabel,
                style: AppTextStyles.sectionLabel),
          ),
          const SizedBox(height: 12),
          AnimatedReveal(
            direction: RevealDirection.fromTop,
            delay: const Duration(milliseconds: 100),
            child: Text(
              l10n.sectionAudienceTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitleLight,
            ),
          ),
          const SizedBox(height: 48),
          isCompact
              ? Column(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      AnimatedReveal(
                        direction: directions[i],
                        delay: Duration(milliseconds: 120 * i),
                        child: HoverScale(child: _AudienceCard(data: cards[i])),
                      ),
                      if (i < cards.length - 1) const SizedBox(height: 16),
                    ]
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      Expanded(
                        child: AnimatedReveal(
                          direction: directions[i],
                          delay: Duration(milliseconds: 120 * i),
                          child:
                              HoverScale(child: _AudienceCard(data: cards[i])),
                        ),
                      ),
                      if (i < cards.length - 1) const SizedBox(width: 16),
                    ],
                  ],
                ),
        ],
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  final _CardItem data;
  const _AudienceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final hl = data.highlighted;
    final isMobile = Responsive.isMobile(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GlassmorphicContainer(
          width: constraints.maxWidth,
          height: isMobile ? 480 : 540,
          borderRadius: 24,
          blur: 25,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hl
                ? [
                    AppColors.navy.withValues(alpha: 0.9),
                    AppColors.navy.withValues(alpha: 0.7),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hl
                ? [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.1),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hl
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(data.icon,
                      color: hl ? Colors.white : AppColors.orange, size: 22),
                ),
                const SizedBox(height: 16),
                Text(data.title,
                    style: AppTextStyles.cardTitleLight
                        .copyWith(color: Colors.white, fontSize: 18)),
                Text(data.subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13)),
                const SizedBox(height: 20),
                ...data.features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hl ? Colors.white70 : AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(f,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: HoverScale(
                    child: hl
                        ? ElevatedButton(
                            onPressed: data.onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orange,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor:
                                  AppColors.orange.withValues(alpha: 0.5),
                            ),
                            child: Text(AppLocalizations.of(context).btnStart),
                          )
                        : OutlinedButton(
                            onPressed: data.onTap,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Colors.white, width: 1.5),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.05),
                            ),
                            child:
                                Text(AppLocalizations.of(context).btnLearnMore),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
