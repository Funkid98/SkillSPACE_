import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/app_colors.dart';
import '../widgets/scroll_3d_video_background.dart';
import '../widgets/nav_bar.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/steps_section.dart';
import '../widgets/audience_section.dart';
import '../widgets/cta_section.dart';
import '../widgets/app_footer.dart';

class SectionKeys {
  static final features = GlobalKey();
  static final steps = GlobalKey();
  static final audience = GlobalKey();
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  NavSection _activeSection = NavSection.features;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final offsets = <double, NavSection>{
      100: NavSection.features,
      700: NavSection.steps,
      1300: NavSection.audience,
    };
    NavSection newSection = NavSection.features;
    for (final entry in offsets.entries) {
      if (offset >= entry.key - 100) {
        newSection = entry.value;
      }
    }
    if (newSection != _activeSection) {
      setState(() => _activeSection = newSection);
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _scrollController.animateTo(
          _scrollController.offset + 100,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _scrollController.animateTo(
          _scrollController.offset - 100,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showScrollTop =
        _scrollController.hasClients && _scrollController.offset > 400;

    return Scroll3DVideoBackground(
      scrollController: _scrollController,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: NavDrawer(scrollTo: _scrollTo),
        body: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      HeroSection(
                        onDiscoverTap: () => _scrollTo(SectionKeys.features),
                      ),
                      _SectionDivider(),
                      FeaturesSection(key: SectionKeys.features),
                      _SectionDivider(),
                      StepsSection(key: SectionKeys.steps),
                      _SectionDivider(),
                      AudienceSection(key: SectionKeys.audience),
                      _SectionDivider(),
                      const CtaSection(),
                      const AppFooter(),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child:
                    NavBar(scrollTo: _scrollTo, activeSection: _activeSection),
              ),
              if (showScrollTop)
                Positioned(
                  bottom: 32,
                  right: 32,
                  child: _ScrollToTopButton(onTap: _scrollToTop),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.orange.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ScrollToTopButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ScrollToTopButton({required this.onTap});

  @override
  State<_ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<_ScrollToTopButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_upward_rounded,
                color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
