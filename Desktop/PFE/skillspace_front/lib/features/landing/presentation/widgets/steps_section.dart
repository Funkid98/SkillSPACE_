import 'package:flutter/material.dart';
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
    ];

    final directions = isAr
        ? [
            RevealDirection.fromRight,
            RevealDirection.fromBottom,
            RevealDirection.fromBottom,
            RevealDirection.fromLeft,
          ]
        : [
            RevealDirection.fromLeft,
            RevealDirection.fromBottom,
            RevealDirection.fromBottom,
            RevealDirection.fromRight,
          ];

    return Container(
      color: AppColors.bg,
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
                      AnimatedReveal(
                        direction: directions[i],
                        delay: Duration(milliseconds: 100 * i),
                        child: _StepCard(step: steps[i]),
                      ),
                      if (i < steps.length - 1) const SizedBox(height: 24),
                    ]
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: isAr
                      ? [
                          for (int i = 0; i < steps.length; i++) ...[
                            if (i > 0) _DotDivider(),
                            Expanded(
                              child: AnimatedReveal(
                                direction: directions[i],
                                delay: Duration(milliseconds: 120 * i),
                                child: _StepCard(step: steps[i]),
                              ),
                            ),
                          ],
                        ]
                      : [
                          for (int i = 0; i < steps.length; i++) ...[
                            Expanded(
                              child: AnimatedReveal(
                                direction: directions[i],
                                delay: Duration(milliseconds: 120 * i),
                                child: _StepCard(step: steps[i]),
                              ),
                            ),
                            if (i < steps.length - 1) _DotDivider(),
                          ],
                        ],
                ),
        ],
      ),
    );
  }
}

class _DotDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Row(
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 6,
              height: 2,
              color: AppColors.orange.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _StepItem step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          step.number,
          style: AppTextStyles.stepNumber.copyWith(
            color: AppColors.orange.withValues(alpha: 0.22),
          ),
        ),
        const SizedBox(height: 8),
        Text(step.title,
            textAlign: TextAlign.center, style: AppTextStyles.cardTitle),
        const SizedBox(height: 8),
        Text(step.desc,
            textAlign: TextAlign.center, style: AppTextStyles.cardDesc),
      ],
    );
  }
}
