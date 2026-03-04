import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../shared/widgets/hover_scale.dart';

class _FeatureItem {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureItem(this.icon, this.title, this.desc);
}

const _items = [
  _FeatureItem(Icons.description_outlined, 'Analyse de CV par IA',
      'Importez votre CV et laissez l\'IA extraire vos compétences automatiquement.'),
  _FeatureItem(Icons.track_changes_outlined, 'Matching intelligent',
      'Score de compatibilité calculé entre votre profil et les offres disponibles.'),
  _FeatureItem(Icons.school_outlined, 'Formations recommandées',
      'Comblez vos lacunes avec des formations ciblées selon le marché.'),
  _FeatureItem(Icons.chat_bubble_outline, 'Simulation d\'entretien',
      'Entraînez-vous avec un chatbot IA qui s\'adapte au poste visé.'),
  _FeatureItem(Icons.psychology_outlined, 'IA qui apprend',
      'Le système s\'améliore continuellement grâce aux données collectées.'),
  _FeatureItem(Icons.trending_up_outlined, 'Tendances du marché',
      'Restez informé des compétences les plus demandées dans votre secteur.'),
];

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final cols = isMobile ? 1 : 3;

    return Container(
      color: AppColors.bgAlt,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.hPad(context),
        vertical: 80,
      ),
      child: Column(
        children: [
          // label من فوق
          const AnimatedReveal(
            direction: RevealDirection.fromTop,
            child: Text('FONCTIONNALITÉS', style: AppTextStyles.sectionLabel),
          ),
          const SizedBox(height: 12),

          // titre من فوق مع delay
          const AnimatedReveal(
            direction: RevealDirection.fromTop,
            delay: Duration(milliseconds: 100),
            child: Text(
              'Tout ce qu\'il faut pour décrocher\nvotre premier emploi',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
          ),
          const SizedBox(height: 16),

          // subtitle fade
          const AnimatedReveal(
            direction: RevealDirection.fade,
            delay: Duration(milliseconds: 200),
            child: Text(
              'SkillSpace combine l\'intelligence artificielle et le coaching\npour maximiser vos chances d\'insertion professionnelle.',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionSubtitle,
            ),
          ),
          const SizedBox(height: 48),
          _buildGrid(cols),
        ],
      ),
    );
  }

  Widget _buildGrid(int cols) {
    // directions تتبدل بين اليسار واليمين وتحت
    const directions = [
      RevealDirection.fromLeft,
      RevealDirection.fromBottom,
      RevealDirection.fromRight,
      RevealDirection.fromLeft,
      RevealDirection.fromBottom,
      RevealDirection.fromRight,
    ];

    final rows = <Widget>[];
    for (int i = 0; i < _items.length; i += cols) {
      final batch = _items.skip(i).take(cols).toList();
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int j = 0; j < batch.length; j++) ...[
            Expanded(
              child: AnimatedReveal(
                direction: directions[(i + j) % directions.length],
                delay: Duration(milliseconds: 80 * (i + j)),
                child: HoverScale(child: _FeatureCard(item: batch[j])),
              ),
            ),
            if (j < batch.length - 1) const SizedBox(width: 16),
          ],
          for (int k = batch.length; k < cols; k++) ...[
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ],
      ));
      if (i + cols < _items.length) rows.add(const SizedBox(height: 16));
    }
    return Column(children: rows);
  }
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;
  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: AppColors.orange, size: 22),
          ),
          const SizedBox(height: 16),
          Text(item.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Text(item.desc, style: AppTextStyles.cardDesc),
        ],
      ),
    );
  }
}
