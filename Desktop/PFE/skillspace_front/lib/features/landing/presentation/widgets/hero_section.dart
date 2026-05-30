import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
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
  final VoidCallback? onDiscoverTap;
  const HeroSection({super.key, this.onDiscoverTap});

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
                _HeroText(onDiscoverTap: onDiscoverTap),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, child: _HeroImage()),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    flex: 5, child: _HeroText(onDiscoverTap: onDiscoverTap)),
                const SizedBox(width: 48),
                Expanded(flex: 5, child: _HeroImage()),
              ],
            ),
    );
  }
}

// ─── Hero Text ────────────────────────────────────────────────────────────────
class _HeroText extends StatelessWidget {
  final VoidCallback? onDiscoverTap;
  const _HeroText({this.onDiscoverTap});

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
              style: AppTextStyles.heroTitleLight.copyWith(
                fontSize:
                    isMobile ? 36 : (Responsive.isTablet(context) ? 48 : 60),
              ),
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
            style: AppTextStyles.heroSubtitleLight,
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
                  onPressed: onDiscoverTap,
                  child: Text(l10n.btnDiscover),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AnimatedReveal(
          direction: RevealDirection.fromBottom,
          delay: const Duration(milliseconds: 550),
          child: Row(
            mainAxisAlignment: isMobile
                ? MainAxisAlignment.center
                : (isAr ? MainAxisAlignment.end : MainAxisAlignment.start),
            children: [
              _AnimatedStatBadge(
                label: l10n.statActiveCandidates,
                prefix: '500+',
              ),
              const SizedBox(width: 32),
              _AnimatedStatBadge(
                label: l10n.statCompanies,
                prefix: '50+',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedStatBadge extends StatefulWidget {
  final String label;
  final String prefix;
  const _AnimatedStatBadge({required this.label, required this.prefix});

  @override
  State<_AnimatedStatBadge> createState() => _AnimatedStatBadgeState();
}

class _AnimatedStatBadgeState extends State<_AnimatedStatBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.0).animate(
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
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.prefix} ${widget.label}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
            GlassmorphicContainer(
              width: double.infinity,
              height: 380,
              borderRadius: 24,
              blur: 20,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8815A).withValues(alpha: 0.2),
                  const Color(0xFF1B2D6B).withValues(alpha: 0.2),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/hero_image.png',
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => _HeroIllustration(),
                    ),
                    _FloatingElements(),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: -10,
              left: -10,
              child: _SatisfactionBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingElements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: 20,
          right: 20,
          child: _FloatingDot(delay: 0, color: Colors.white38),
        ),
        Positioned(
          top: 60,
          right: 60,
          child: _FloatingDot(delay: 400, color: Colors.white24),
        ),
        Positioned(
          bottom: 40,
          right: 30,
          child: _FloatingDot(delay: 800, color: Colors.white30),
        ),
      ],
    );
  }
}

class _FloatingDot extends StatefulWidget {
  final int delay;
  final Color color;
  const _FloatingDot({required this.delay, required this.color});

  @override
  State<_FloatingDot> createState() => _FloatingDotState();
}

class _FloatingDotState extends State<_FloatingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0, end: 1).animate(
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -8 * _anim.value),
        child: Opacity(opacity: 0.3 + 0.5 * _anim.value, child: child),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8815A), Color(0xFF1B2D6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch_rounded,
                color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              'SkillSpace',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
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
  Offset _runAwayOffset = Offset.zero;

  void _runAway() {
    setState(() {
      final random = math.Random();
      // Jump much further across the hero area
      _runAwayOffset = Offset(
        (random.nextDouble() - 0.5) * 350,
        (random.nextDouble() - 0.5) * 250,
      );
    });
  }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCount(87);
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
    return MouseRegion(
      onEnter: (_) => _runAway(),
      onExit: (_) => setState(() => _runAwayOffset = Offset.zero),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        transform:
            Matrix4.translationValues(_runAwayOffset.dx, _runAwayOffset.dy, 0),
        child: GlassmorphicContainer(
          width: 120,
          height: 80,
          borderRadius: 12,
          blur: 20,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
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
          child: AnimatedBuilder(
            animation: _count,
            builder: (_, __) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_count.value}%',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).statSatisfaction,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
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
