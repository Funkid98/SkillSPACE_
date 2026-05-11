import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../../../../shared/widgets/hover_scale.dart';

import '../../../../core/l10n/app_localizations.dart';

class _FeatureItem {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureItem(this.icon, this.title, this.desc);
}

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final l10n = AppLocalizations.of(context);
    final cols = isMobile ? 1 : (isTablet ? 2 : 3);

    final items = [
      _FeatureItem(Icons.description_outlined, l10n.feat1Title, l10n.feat1Desc),
      _FeatureItem(
          Icons.track_changes_outlined, l10n.feat2Title, l10n.feat2Desc),
      _FeatureItem(Icons.school_outlined, l10n.feat3Title, l10n.feat3Desc),
      _FeatureItem(Icons.chat_bubble_outline, l10n.feat4Title, l10n.feat4Desc),
      _FeatureItem(Icons.psychology_outlined, l10n.feat5Title, l10n.feat5Desc),
      _FeatureItem(Icons.trending_up_outlined, l10n.feat6Title, l10n.feat6Desc),
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
            child: Text(l10n.sectionFeaturesLabel,
                style: AppTextStyles.sectionLabel),
          ),
          const SizedBox(height: 12),
          AnimatedReveal(
            direction: RevealDirection.fromTop,
            delay: const Duration(milliseconds: 100),
            child: Text(
              l10n.sectionFeaturesTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitleLight,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedReveal(
            direction: RevealDirection.fade,
            delay: const Duration(milliseconds: 200),
            child: Text(
              l10n.sectionFeaturesSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionSubtitleLight,
            ),
          ),
          const SizedBox(height: 48),
          _buildGrid(cols, items),
        ],
      ),
    );
  }

  Widget _buildGrid(int cols, List<_FeatureItem> items) {
    const directions = [
      RevealDirection.fromLeft,
      RevealDirection.fromBottom,
      RevealDirection.fromRight,
      RevealDirection.fromLeft,
      RevealDirection.fromBottom,
      RevealDirection.fromRight,
    ];

    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += cols) {
      final batch = items.skip(i).take(cols).toList();
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
      if (i + cols < items.length) rows.add(const SizedBox(height: 16));
    }
    return Column(children: rows);
  }
}

class _FeatureCard extends StatefulWidget {
  final _FeatureItem item;
  const _FeatureCard({required this.item});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _rotation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: _hovered
            ? (Matrix4.identity()..translate(0, -4))
            : Matrix4.identity(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GlassmorphicContainer(
              width: constraints.maxWidth,
              height: 350,
              borderRadius: 24,
              blur: 25,
              alignment: Alignment.center,
              border: 1.5,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.05),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _hovered
                            ? AppColors.orange.withValues(alpha: 0.12)
                            : AppColors.iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ScaleTransition(
                        scale: _scale,
                        child: RotationTransition(
                          turns: _rotation,
                          child: Icon(widget.item.icon,
                              color: AppColors.orange, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.item.title,
                        style: AppTextStyles.cardTitleLight),
                    const SizedBox(height: 8),
                    Text(widget.item.desc, style: AppTextStyles.cardDescLight),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
