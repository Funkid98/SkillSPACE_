import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../shared/widgets/hover_scale.dart';
import '../../cubit/landing_cubit.dart';
import '../../../dashboard_shell/dashboard_shell.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      color: AppColors.bg,
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
    final align = isMobile ? TextAlign.center : TextAlign.start;
    final cross =
        isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross, // ← responsive
      children: [
        AnimatedReveal(
          direction: RevealDirection.fromTop,
          delay: const Duration(milliseconds: 100),
          child: Text('PLATEFORME DE RECRUTEMENT INTELLIGENTE',
              textAlign: align, // ← responsive
              style: AppTextStyles.heroLabel),
        ),
        const SizedBox(height: 16),
        AnimatedReveal(
          direction: RevealDirection.fromLeft,
          delay: const Duration(milliseconds: 200),
          child: RichText(
            textAlign: align, // ← responsive
            text: const TextSpan(
              style: AppTextStyles.heroTitle,
              children: [
                TextSpan(text: 'Vos '),
                TextSpan(
                    text: 'compétences',
                    style: TextStyle(color: AppColors.orange)),
                TextSpan(text: '\nsont votre meilleur\natout'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedReveal(
          direction: RevealDirection.fade,
          delay: const Duration(milliseconds: 350),
          child: Text(
            'SkillSpace connecte les jeunes diplômés aux entreprises\n'
            'grâce à l\'IA. Fini le stress des entretiens — préparez-vous,\n'
            'matchez, décrochez.',
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
                ? WrapAlignment.center // ← center sur mobile
                : WrapAlignment.start, // ← start sur desktop
            children: [
              HoverScale(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DashboardShell(),
                    ),
                  ),
                  child: const Text('Commencer gratuitement'),
                ),
              ),
              HoverScale(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Découvrir la plateforme'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        BlocBuilder<LandingCubit, LandingState>(
          builder: (context, state) {
            if (state is LandingLoaded) {
              return AnimatedReveal(
                direction: RevealDirection.fromBottom,
                delay: const Duration(milliseconds: 550),
                child: Row(
                  mainAxisAlignment: isMobile
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    _StatBadge(
                        '${state.stats.candidatsCount} candidats actifs'),
                    const SizedBox(width: 24),
                    _StatBadge('${state.stats.entreprisesCount} entreprises'),
                  ],
                ),
              );
            }
            return const _StatsSkeleton();
          },
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

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [_bone(120), const SizedBox(width: 24), _bone(100)],
    );
  }

  Widget _bone(double w) => Container(
        width: w,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      );
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
      final state = context.read<LandingCubit>().state;
      if (state is LandingLoaded) {
        _startCount(state.stats.satisfactionRate);
      }
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
    return BlocConsumer<LandingCubit, LandingState>(
      listener: (context, state) {
        if (state is LandingLoaded) {
          _startCount(state.stats.satisfactionRate);
        }
      },
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                const Text(
                  'Taux de satisfaction',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
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
