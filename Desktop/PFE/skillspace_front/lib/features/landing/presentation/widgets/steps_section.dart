import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';

import '../../../../core/l10n/app_localizations.dart';

class _StepItem {
  final String number;
  final String title;
  final String desc;
  const _StepItem(this.number, this.title, this.desc);
}

class StepsSection extends StatelessWidget {
  const StepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final steps = [
      _StepItem('01', l10n.step1Title, l10n.step1Desc),
      _StepItem('02', l10n.step2Title, l10n.step2Desc),
      _StepItem('03', l10n.step3Title, l10n.step3Desc),
      _StepItem('04', l10n.step4Title, l10n.step4Desc),
      _StepItem('05', l10n.step5Title, l10n.step5Desc),
    ];

    final directions = isAr
        ? [
            RevealDirection.fromRight,
            RevealDirection.fromBottom,
            RevealDirection.fromBottom,
            RevealDirection.fromBottom,
            RevealDirection.fromLeft,
          ]
        : [
            RevealDirection.fromLeft,
            RevealDirection.fromBottom,
            RevealDirection.fromBottom,
            RevealDirection.fromBottom,
            RevealDirection.fromRight,
          ];

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.hPad(context),
        vertical: 80,
      ),
      child: Column(
        children: [
          AnimatedReveal(
            direction: RevealDirection.fromTop,
            child: Text(
              l10n.sectionStepsTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
          ),
          const SizedBox(height: 48),
          isMobile
              ? Column(
                  children: [
                    for (int i = 0; i < steps.length; i++) ...[
                      _HighTech3DReveal(
                        index: i,
                        delay: Duration(milliseconds: 200 * i),
                        child: _StepCard(index: i, step: steps[i]),
                      ),
                      if (i < steps.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: _EnergyConnector(isMobile: true),
                        ),
                    ]
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: isAr
                      ? [
                          for (int i = 0; i < steps.length; i++) ...[
                            if (i > 0)
                              const Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: _EnergyConnector(isMobile: false),
                              ),
                            Expanded(
                              child: _HighTech3DReveal(
                                index: i,
                                delay: Duration(milliseconds: 200 * i),
                                child: _StepCard(index: i, step: steps[i]),
                              ),
                            ),
                          ],
                        ]
                      : [
                          for (int i = 0; i < steps.length; i++) ...[
                            Expanded(
                              child: _HighTech3DReveal(
                                index: i,
                                delay: Duration(milliseconds: 200 * i),
                                child: _StepCard(index: i, step: steps[i]),
                              ),
                            ),
                            if (i < steps.length - 1)
                              const Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: _EnergyConnector(isMobile: false),
                              ),
                          ],
                        ],
                ),
        ],
      ),
    );
  }
}

class _EnergyConnector extends StatefulWidget {
  final bool isMobile;
  const _EnergyConnector({required this.isMobile});

  @override
  State<_EnergyConnector> createState() => _EnergyConnectorState();
}

class _EnergyConnectorState extends State<_EnergyConnector>
    with SingleTickerProviderStateMixin {
  bool _triggered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: UniqueKey(),
      onVisibilityChanged: (info) {
        if (!_triggered && info.visibleFraction > 0.1) {
          _triggered = true;
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _ctrl.forward();
          });
        }
      },
      child: widget.isMobile
          ? Container(
              height: 40,
              width: 2,
              color: Colors.white.withValues(alpha: 0.1),
              alignment: Alignment.topCenter,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (_, __) => FractionallySizedBox(
                  heightFactor: _progress.value,
                  alignment: Alignment.topCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.5),
                          blurRadius: 8,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
          : SizedBox(
              width: 60,
              height: 2,
              child: Container(
                color: Colors.white.withValues(alpha: 0.1),
                alignment: Alignment.centerLeft,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => FractionallySizedBox(
                    widthFactor: _progress.value,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withValues(alpha: 0.5),
                            blurRadius: 8,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _StepCard extends StatefulWidget {
  final int index;
  final _StepItem step;
  const _StepCard({required this.index, required this.step});

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  double _x = 0;
  double _y = 0;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _x = 0;
        _y = 0;
      }),
      onHover: (e) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final size = box.size;
          setState(() {
            _x = (e.localPosition.dx / size.width - 0.5) * 2;
            _y = (e.localPosition.dy / size.height - 0.5) * 2;
          });
        }
      },
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: _isHovered ? 1.0 : 0.0),
        builder: (context, hoverVal, child) {
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(-_y * hoverVal * 0.15)
            ..rotateY(_x * hoverVal * 0.15)
            ..scale(1.0 + hoverVal * 0.03);

          return Transform(
            transform: transform,
            alignment: FractionalOffset.center,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02 + hoverVal * 0.02),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color:
                        Colors.white.withValues(alpha: 0.05 + hoverVal * 0.1)),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: Offset(-_x * 10, -_y * 10 + 10),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.orange,
                          AppColors.orange.withValues(alpha: 0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange
                              .withValues(alpha: 0.3 + hoverVal * 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _AnimatedStepNumber(number: widget.index + 1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(widget.step.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
                  const SizedBox(height: 12),
                  Text(widget.step.desc,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardDesc.copyWith(fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedStepNumber extends StatelessWidget {
  final int number;
  const _AnimatedStepNumber({required this.number});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: number.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        int displayNum = value.toInt();
        return Text(
          displayNum < 10 ? '0$displayNum' : '$displayNum',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        );
      },
    );
  }
}

class _HighTech3DReveal extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const _HighTech3DReveal({
    super.key,
    required this.child,
    required this.index,
    this.delay = Duration.zero,
  });

  @override
  State<_HighTech3DReveal> createState() => _HighTech3DRevealState();
}

class _HighTech3DRevealState extends State<_HighTech3DReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _flipY;
  late final Animation<double> _scale;
  bool _triggered = false;
  late final Key _visibilityKey;

  @override
  void initState() {
    super.initState();
    _visibilityKey = widget.key ?? UniqueKey();

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _fade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.8, curve: Curves.easeIn));

    // Flip from 90 degrees (invisible) to 0
    _flipY = Tween<double>(begin: math.pi / 2, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_triggered && info.visibleFraction > 0.05) {
      _triggered = true;
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.002) // perspective
            ..rotateY(_flipY.value)
            ..scale(_scale.value);

          return Opacity(
            opacity: _fade.value.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: transform,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
