import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/app_localizations.dart';
import 'dart:ui';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final height = isMobile ? 250.0 : 160.0;

    return ClipRect(
      // ✅ Prevents painter from drawing outside bounds
      child: GlassmorphicContainer(
        width: MediaQuery.of(context).size.width,
        height: height,
        borderRadius: 2,
        blur: 20,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.hPad(context),
            vertical: 16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: isAr
                    ? [
                        _SocialIcons(),
                        const Spacer(),
                        const Text('SkillSpace',
                            style: AppTextStyles.footerBrand),
                      ]
                    : [
                        const Text('SkillSpace',
                            style: AppTextStyles.footerBrandLight),
                        const Spacer(),
                        _SocialIcons(),
                      ],
              ),
              if (!isMobile) const SizedBox(height: 15),
              if (!isMobile) const Divider(color: Colors.white12, height: 1),
              if (!isMobile) const SizedBox(height: 12),
              Row(
                children: isAr
                    ? [
                        _FooterLink(l10n.footerContact),
                        const SizedBox(width: 20),
                        _FooterLink(l10n.footerTos),
                        const SizedBox(width: 20),
                        _FooterLink(l10n.footerPrivacy),
                        const Spacer(),
                        if (!isMobile)
                          Text(l10n.footerRights,
                              style: AppTextStyles.footerLinkLight),
                      ]
                    : [
                        if (!isMobile)
                          Text(l10n.footerRights,
                              style: AppTextStyles.footerLinkLight),
                        const Spacer(),
                        _FooterLink(l10n.footerPrivacy),
                        const SizedBox(width: 20),
                        _FooterLink(l10n.footerTos),
                        const SizedBox(width: 20),
                        _FooterLink(l10n.footerContact),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIcons extends StatelessWidget {
  void _showCard(BuildContext context, {required bool isEmail}) {
    final accentColor = isEmail ? AppColors.orange : const Color(0xFF0077B5);
    final icon = isEmail ? Icons.alternate_email_rounded : Icons.link_rounded;
    final title = isEmail ? 'Get in Touch' : 'LinkedIn Profile';
    final subtitle = isEmail
        ? 'We would love to hear from you'
        : 'Connect with our professional network';
    final value = isEmail
        ? 'skillspace2026@gmail.com'
        : 'linkedin.com/company/skillspace';
    final primaryActionText = isEmail ? 'Copy Email' : 'Visit Profile';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6), // Darker backdrop
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              elevation: 0,
              content: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Ambient Glow behind the card
                  Positioned(
                    top: -50,
                    left: -50,
                    right: -50,
                    bottom: -50,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.15),
                            blurRadius: 120,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // The Glass Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        width: 380,
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Glowing Icon
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor.withOpacity(0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: accentColor, size: 40),
                            ),
                            const SizedBox(height: 28),
                            // Typography
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                decoration: TextDecoration.none,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.7),
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 36),
                            // Data Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Text(
                                value,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _CardButton(
                                    text: 'Close',
                                    isPrimary: false,
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _CardButton(
                                    text: primaryActionText,
                                    isPrimary: true,
                                    color: accentColor,
                                    onPressed: () async {
                                      if (isEmail) {
                                        Clipboard.setData(const ClipboardData(
                                            text: 'skillspace2026@gmail.com'));
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                'Email copied successfully!'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: accentColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      } else {
                                        final url = Uri.parse(
                                            'https://www.linkedin.com/company/skillspace');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SocialIcon(
          icon: Icons.email_outlined,
          tooltip: 'Email',
          onTap: () => _showCard(context, isEmail: true),
        ),
        const SizedBox(width: 8),
        _SocialIcon(
          icon: Icons.link,
          tooltip: 'LinkedIn',
          onTap: () => _showCard(context, isEmail: false),
        ),
      ],
    );
  }
}

class _CardButton extends StatefulWidget {
  final String text;
  final bool isPrimary;
  final Color? color;
  final VoidCallback onPressed;

  const _CardButton({
    required this.text,
    required this.isPrimary,
    this.color,
    required this.onPressed,
  });

  @override
  State<_CardButton> createState() => _CardButtonState();
}

class _CardButtonState extends State<_CardButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (widget.color ?? AppColors.orange)
                    .withOpacity(_hovered ? 0.9 : 1.0)
                : Colors.white.withOpacity(_hovered ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(12),
            border: widget.isPrimary
                ? null
                : Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: widget.isPrimary && _hovered
                ? [
                    BoxShadow(
                      color:
                          (widget.color ?? AppColors.orange).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: TextDecoration.none,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _SocialIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _rotation = Tween<double>(begin: 0.0, end: 0.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.forward(from: 0).then((_) {
          if (!_hovered) _controller.reverse();
        });
        widget.onTap();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hovered = true);
          _controller.forward();
        },
        onExit: (_) {
          setState(() => _hovered = false);
          _controller.reverse();
        },
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.orange.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ScaleTransition(
              scale: _scale,
              child: RotationTransition(
                turns: _rotation,
                child: Icon(
                  widget.icon,
                  color: _hovered ? AppColors.orange : AppColors.textGray,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
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
          color: _hovered ? AppColors.orange : Colors.white70,
          fontSize: 13,
          fontFamily: 'Inter',
        ),
        child: Text(widget.text),
      ),
    );
  }
}
