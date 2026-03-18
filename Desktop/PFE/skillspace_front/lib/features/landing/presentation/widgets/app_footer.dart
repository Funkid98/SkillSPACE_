import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';

import '../../../../core/l10n/app_localizations.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.hPad(context),
        vertical: 28,
      ),
      child: Row(
        children: isAr
            ? [
                _FooterLink(l10n.footerContact),
                const SizedBox(width: 20),
                _FooterLink(l10n.footerTos),
                const SizedBox(width: 20),
                _FooterLink(l10n.footerPrivacy),
                const Spacer(),
                if (!isMobile) ...[
                  Text(l10n.footerRights, style: AppTextStyles.footerLink),
                  const Spacer(),
                ],
                const Text('SkillSpace', style: AppTextStyles.footerBrand),
              ]
            : [
                const Text('SkillSpace', style: AppTextStyles.footerBrand),
                const Spacer(),
                if (!isMobile) ...[
                  Text(l10n.footerRights, style: AppTextStyles.footerLink),
                  const Spacer(),
                ],
                _FooterLink(l10n.footerPrivacy),
                const SizedBox(width: 20),
                _FooterLink(l10n.footerTos),
                const SizedBox(width: 20),
                _FooterLink(l10n.footerContact),
              ],
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String text;
  const _FooterLink(this.text);

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 150),
        style: TextStyle(
          color: _hovered ? AppColors.orange : AppColors.textGray,
          fontSize: 13,
          fontFamily: 'Roboto',
        ),
        child: Text(widget.text),
      ),
    );
  }
}
