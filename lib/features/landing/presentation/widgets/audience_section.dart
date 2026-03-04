import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../shared/widgets/hover_scale.dart';

class _CardItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
  final bool highlighted;
  const _CardItem(this.icon, this.title, this.subtitle, this.features,
      {this.highlighted = false});
}

const _cards = [
  _CardItem(
    Icons.business_center_outlined,
    'Recruteur',
    'Entreprise',
    [
      'Publication d\'offres ciblées',
      'Tri automatique des candidats',
      'Score de compatibilité',
      'Gain de temps considérable',
    ],
  ),
  _CardItem(
      Icons.person_outline,
      'Candidat',
      'Jeune diplômé',
      [
        'Profil basé sur les compétences',
        'Matching intelligent avec les offres',
        'Simulation d\'entretien IA',
        'Formations recommandées',
      ],
      highlighted: true),
  _CardItem(Icons.menu_book_outlined, 'Formateur', 'Organisme de formation', [
    'Visibilité auprès des candidats',
    'Recommandations IA ciblées',
    'Suivi des inscriptions',
    'Alignement marché du travail',
  ]),
];

// كل card جهة مختلفة
const _cardDirections = [
  RevealDirection.fromLeft,
  RevealDirection.fromBottom,
  RevealDirection.fromRight,
];

class AudienceSection extends StatelessWidget {
  const AudienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
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
            child: Text('POUR QUI ?', style: AppTextStyles.sectionLabel),
          ),
          const SizedBox(height: 12),

          // titre من فوق
          const AnimatedReveal(
            direction: RevealDirection.fromTop,
            delay: Duration(milliseconds: 100),
            child: Text(
              'Une plateforme pour chaque acteur',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
          ),
          const SizedBox(height: 48),

          isMobile
              ? Column(
                  children: [
                    for (int i = 0; i < _cards.length; i++) ...[
                      AnimatedReveal(
                        direction: _cardDirections[i],
                        delay: Duration(milliseconds: 120 * i),
                        child:
                            HoverScale(child: _AudienceCard(data: _cards[i])),
                      ),
                      if (i < _cards.length - 1) const SizedBox(height: 16),
                    ]
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _cards.length; i++) ...[
                      Expanded(
                        child: AnimatedReveal(
                          direction: _cardDirections[i],
                          delay: Duration(milliseconds: 120 * i),
                          child:
                              HoverScale(child: _AudienceCard(data: _cards[i])),
                        ),
                      ),
                      if (i < _cards.length - 1) const SizedBox(width: 16),
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
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: hl ? AppColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
              color: hl ? Colors.white.withOpacity(0.15) : AppColors.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon,
                color: hl ? Colors.white : AppColors.orange, size: 22),
          ),
          const SizedBox(height: 16),
          Text(data.title,
              style: AppTextStyles.cardTitle
                  .copyWith(color: hl ? Colors.white : null, fontSize: 18)),
          Text(data.subtitle,
              style: TextStyle(
                  color:
                      hl ? Colors.white.withOpacity(0.7) : AppColors.textGray,
                  fontSize: 13)),
          const SizedBox(height: 20),
          ...data.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.orange, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(f,
                      style: TextStyle(
                          color: hl
                              ? Colors.white.withOpacity(0.9)
                              : AppColors.textDark,
                          fontSize: 13,
                          height: 1.4)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: hl
                ? ElevatedButton(
                    onPressed: () {}, child: const Text('Commencer'))
                : OutlinedButton(
                    onPressed: () {}, child: const Text('En savoir plus')),
          ),
        ],
      ),
    );
  }
}
