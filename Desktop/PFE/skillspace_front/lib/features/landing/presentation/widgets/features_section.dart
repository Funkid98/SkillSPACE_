import 'package:flutter/material.dart';
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
    final l10n = AppLocalizations.of(context);
    final cols = isMobile ? 1 : 3;

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
              style: AppTextStyles.sectionTitle,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedReveal(
            direction: RevealDirection.fade,
            delay: const Duration(milliseconds: 200),
            child: Text(
              l10n.sectionFeaturesSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionSubtitle,
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? AppColors.orange.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? AppColors.orange.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _hovered ? 20 : 12,
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
            Text(widget.item.title, style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            Text(widget.item.desc, style: AppTextStyles.cardDesc),
          ],
        ),
      ),
    );
  }
}
