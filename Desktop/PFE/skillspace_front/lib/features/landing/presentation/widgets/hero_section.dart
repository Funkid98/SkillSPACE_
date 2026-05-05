import 'package:flutter/material.dart';
import 'package:skillspace/core/app_colors.dart';
import 'package:skillspace/core/theme/app_text_styles.dart';
import 'package:skillspace/core/utils/responsive.dart';
import 'package:skillspace/shared/widgets/animated_reveal.dart';
import 'package:skillspace/shared/widgets/hover_scale.dart';
import 'package:skillspace/core/l10n/app_localizations.dart';
import 'package:skillspace/features/dashboard_shell/dashboard_shell.dart';
import 'package:skillspace/shared/widgets/app_sidebar.dart';
import 'package:recruiter_profile/recruiter_profile.dart';
import 'package:pfe/features/auth/presentation/pages/auth_page.dart';
import 'package:skillspace/features/auth/presentation/pages/field_selection_page.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.hPad(context),
        vertical: isMobile ? 40 : 80,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroText(),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, child: _HeroImage()),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(flex: 5, child: _HeroText()),
                const SizedBox(width: 48),
                Expanded(flex: 5, child: _HeroImage()),
              ],
            ),
    );
  }
}

// ─── Hero Text ────────────────────────────────────────────────────────────────
class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final align =
        isMobile ? TextAlign.center : (isAr ? TextAlign.right : TextAlign.left);
    final cross = isMobile
        ? CrossAxisAlignment.center
        : (isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start);

    return Column(
      crossAxisAlignment: cross,
      children: [
        AnimatedReveal(
          direction: RevealDirection.fromTop,
          delay: const Duration(milliseconds: 100),
          child: Text(l10n.heroLabel,
              textAlign: align, style: AppTextStyles.heroLabel),
        ),
        const SizedBox(height: 16),
        AnimatedReveal(
          direction:
              isAr ? RevealDirection.fromRight : RevealDirection.fromLeft,
          delay: const Duration(milliseconds: 200),
          child: RichText(
            textAlign: align,
            text: TextSpan(
              style: AppTextStyles.heroTitle,
              children: [
                TextSpan(text: l10n.heroTitle1),
                TextSpan(
                    text: l10n.heroTitle2,
                    style: const TextStyle(color: AppColors.orange)),
                TextSpan(text: l10n.heroTitle3),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedReveal(
          direction: RevealDirection.fade,
          delay: const Duration(milliseconds: 350),
          child: Text(
            l10n.heroSubtitle,
            textAlign: align,
            style: AppTextStyles.heroSubtitle,
          ),
        ),
        const SizedBox(height: 32),
        AnimatedReveal(
          direction: RevealDirection.fromBottom,
          delay: const Duration(milliseconds: 450),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: isMobile
                ? WrapAlignment.center
                : (isAr ? WrapAlignment.end : WrapAlignment.start),
            children: [
              HoverScale(
                child: ElevatedButton(
                  onPressed: () {
                    final authState = context.read<AuthCubit>().state;
                    final role = authState.role;

                    if (authState.loggedInUser != null) {
                      final user = authState.loggedInUser;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => role == UserRole.recruteur
                              ? const RecruiterShell(
                                  initialTab: RecruiterTab.profile,
                                )
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
                      final authCubit = context.read<AuthCubit>();
                      authCubit.switchTab(AuthTab.register);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (heroContext) => AuthPage(
                            onSuccess: () {
                              final authState = authCubit.state;
                              final role = authState.role;
                              final user = authState.loggedInUser;

                              Navigator.of(heroContext).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) {
                                    if (role == UserRole.recruteur) {
                                      return const RecruiterShell(
                                        initialTab: RecruiterTab.profile,
                                      );
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
                    }
                  },
                  child: Text(l10n.btnStartFree),
                ),
              ),
              HoverScale(
                child: OutlinedButton(
                  onPressed: () {},
                  child: Text(l10n.btnDiscover),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AnimatedReveal(
          direction: RevealDirection.fromBottom,
          delay: const Duration(milliseconds: 550),
          child: Row(
            mainAxisAlignment: isMobile
                ? MainAxisAlignment.center
                : (isAr ? MainAxisAlignment.end : MainAxisAlignment.start),
            children: [
              _StatBadge('500+ ${l10n.statActiveCandidates}'),
              const SizedBox(width: 24),
              _StatBadge('50+ ${l10n.statCompanies}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String text;
  const _StatBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
              color: AppColors.navy, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Hero Image ───────────────────────────────────────────────────────────────
class _HeroImage extends StatefulWidget {
  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _float = Tween<double>(begin: -6, end: 6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الصورة تجي من اليمين
    return AnimatedReveal(
      direction: RevealDirection.fromRight,
      delay: const Duration(milliseconds: 300),
      child: AnimatedBuilder(
        animation: _float,
        builder: (_, child) =>
            Transform.translate(offset: Offset(0, _float.value), child: child),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 340,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8815A), Color(0xFF1B2D6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/hero_image.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Positioned(
              bottom: 20,
              left: 20,
              child: _SatisfactionBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SatisfactionBadge extends StatefulWidget {
  const _SatisfactionBadge();

  @override
  State<_SatisfactionBadge> createState() => _SatisfactionBadgeState();
}

class _SatisfactionBadgeState extends State<_SatisfactionBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<int> _count;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _count = IntTween(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    // يقرا الـ state بعد أول frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCount(87); // static satisfaction rate
    });
  }

  void _startCount(int target) {
    _count = IntTween(
      begin: 0,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
      ),
    );

    _ctrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _count,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_count.value}%',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).statSatisfaction,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
