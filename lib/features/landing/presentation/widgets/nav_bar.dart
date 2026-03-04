import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../pages/landing_page.dart';

class NavBar extends StatelessWidget {
  final void Function(GlobalKey) scrollTo;
  const NavBar({super.key, required this.scrollTo});

  void _scrollToSection(GlobalKey key) => scrollTo(key);

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AnimatedReveal(
      duration: const Duration(milliseconds: 500),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 48,
          vertical: 14,
        ),
        child: Row(
          children: [
            const Text('SkillSpace', style: AppTextStyles.navBrand),
            const Spacer(),
            if (!isMobile) ...[
              _NavLink('Fonctionnalités',
                  onTap: () => _scrollToSection(SectionKeys.features)),
              const SizedBox(width: 28),
              _NavLink('Comment ça marche',
                  onTap: () => _scrollToSection(SectionKeys.steps)),
              const SizedBox(width: 28),
              _NavLink('Pour qui',
                  onTap: () => _scrollToSection(SectionKeys.audience)),
              const SizedBox(width: 24),
              OutlinedButton(
                  onPressed: () {}, child: const Text('Se connecter')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () {}, child: const Text("S'inscrire")),
            ] else
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.navy),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Desktop nav link with hover effect
class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, {required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            color: _hovered ? AppColors.orange : AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto',
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

// ── Mobile Drawer ────────────────────────────────────────────────────────────
class NavDrawer extends StatelessWidget {
  final void Function(GlobalKey) scrollTo;
  const NavDrawer({super.key, required this.scrollTo});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF9F7F4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: brand + close ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SkillSpace', style: AppTextStyles.navBrand),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textDark,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Nav links ────────────────────────────────────────
              _DrawerLink(
                label: 'Fonctionnalités',
                onTap: () {
                  Navigator.pop(context);
                  scrollTo(SectionKeys.features);
                },
              ),
              const Divider(color: Color(0xFFE8E4DE), height: 1),
              _DrawerLink(
                label: 'Comment ça marche',
                onTap: () {
                  Navigator.pop(context);
                  scrollTo(SectionKeys.steps);
                },
              ),
              const Divider(color: Color(0xFFE8E4DE), height: 1),
              _DrawerLink(
                label: 'Pour qui',
                onTap: () {
                  Navigator.pop(context);
                  scrollTo(SectionKeys.audience);
                },
              ),
              const Divider(color: Color(0xFFE8E4DE), height: 1),

              const SizedBox(height: 32),

              // ── Action buttons ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  child: const Text('Se connecter'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  child: const Text("S'inscrire"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _DrawerLink({required this.label, required this.onTap});

  @override
  State<_DrawerLink> createState() => _DrawerLinkState();
}

class _DrawerLinkState extends State<_DrawerLink> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _pressed ? AppColors.navy.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _pressed ? AppColors.navy : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
