import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../shared/widgets/hover_scale.dart';

class CtaSection extends StatelessWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.hPad(context),
        vertical: 60,
      ),
      // الـ CTA box كامل يجي من تحت
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
              const AnimatedReveal(
                direction: RevealDirection.fromTop,
                delay: Duration(milliseconds: 200),
                child: Text(
                  'Prêt à lancer votre carrière ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),

              // subtitle fade
              const AnimatedReveal(
                direction: RevealDirection.fade,
                delay: Duration(milliseconds: 300),
                child: Text(
                  'Rejoignez des milliers de jeunes diplômés qui ont trouvé\nleur premier emploi grâce à SkillSpace.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70, fontSize: 15, height: 1.6),
                ),
              ),
              const SizedBox(height: 28),

              // bouton من تحت
              AnimatedReveal(
                direction: RevealDirection.fromBottom,
                delay: const Duration(milliseconds: 400),
                child: HoverScale(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: const Text(
                      'Créer mon profil gratuitement',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
