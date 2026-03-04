import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';

class _StepItem {
  final String number;
  final String title;
  final String desc;
  const _StepItem(this.number, this.title, this.desc);
}

const _steps = [
  _StepItem('01', 'Créez votre profil',
      'Inscrivez-vous et importez votre CV. L\'IA analyse vos compétences en quelques secondes.'),
  _StepItem('02', 'Recevez des matchs',
      'Notre algorithme vous propose les offres les plus adaptées avec un score de compatibilité.'),
  _StepItem('03', 'Préparez-vous',
      'Simulez des entretiens avec l\'IA et suivez des formations pour combler vos lacunes.'),
  _StepItem('04', 'Décrochez le poste',
      'Postulez en toute confiance avec un profil optimisé et une préparation solide.'),
];

// كل step تجي من جهة مختلفة
const _stepDirections = [
  RevealDirection.fromLeft,
  RevealDirection.fromBottom,
  RevealDirection.fromBottom,
  RevealDirection.fromRight,
];

class StepsSection extends StatelessWidget {
  const StepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.hPad(context),
        vertical: 80,
      ),
      child: Column(
        children: [
          // titre من فوق
          const AnimatedReveal(
            direction: RevealDirection.fromTop,
            child: Text(
              '4 étapes vers votre premier emploi',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
          ),
          const SizedBox(height: 48),
          isMobile
              ? Column(
                  children: [
                    for (int i = 0; i < _steps.length; i++) ...[
                      AnimatedReveal(
                        direction: _stepDirections[i],
                        delay: Duration(milliseconds: 100 * i),
                        child: _StepCard(step: _steps[i]),
                      ),
                      if (i < _steps.length - 1) const SizedBox(height: 24),
                    ]
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _steps.length; i++) ...[
                      Expanded(
                        child: AnimatedReveal(
                          direction: _stepDirections[i],
                          delay: Duration(milliseconds: 120 * i),
                          child: _StepCard(step: _steps[i]),
                        ),
                      ),
                      if (i < _steps.length - 1) _DotDivider(),
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
              color: AppColors.orange.withOpacity(0.35),
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
            color: AppColors.orange.withOpacity(0.22),
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
