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
    if (!mounted) return;
    final offset = _scrollController.offset;

    NavSection newSection = NavSection.features;
    if (offset >= 1200) {
      newSection = NavSection.audience;
    } else if (offset >= 600) {
      newSection = NavSection.steps;
    }

    if (newSection != _activeSection) {
      setState(() => _activeSection = newSection);
    } else {
      final crossedThreshold =
          (offset > 400) != (_scrollController.offset - 1 > 400);
      if (crossedThreshold) setState(() {});
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    try {
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
    } catch (_) {}
    return KeyEventResult.ignored;
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

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      child: Scaffold(
        // Transparent so the DOM-injected video behind Flutter shows through
        backgroundColor: Colors.transparent,
        drawer: NavDrawer(scrollTo: _scrollTo),
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: Stack(
            children: [
              // ── Layer 1: Gradient overlay (video lives in DOM, not here) ───
              // Scroll3DVideoBackground no longer uses HtmlElementView.
              // It injects a fixed <div> directly into <body> and renders
              // only the gradient overlay as a Flutter widget.
              Positioned.fill(
                child: Scroll3DVideoBackground(
                  scrollController: _scrollController,
                ),
              ),

              // ── Layer 2: Scrollable page content ───────────────────────────
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      HeroSection(
                        onDiscoverTap: () => _scrollTo(SectionKeys.features),
                      ),
                      const _SectionDivider(),
                      FeaturesSection(key: SectionKeys.features),
                      const _SectionDivider(),
                      StepsSection(key: SectionKeys.steps),
                      const _SectionDivider(),
                      AudienceSection(key: SectionKeys.audience),
                      const _SectionDivider(),
                      const CtaSection(),
                      const AppFooter(),
                    ],
                  ),
                ),
              ),

              // ── Layer 3: NavBar (always on top) ────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: NavBar(
                  scrollTo: _scrollTo,
                  activeSection: _activeSection,
                ),
              ),

              // ── Layer 4: Scroll-to-top FAB ─────────────────────────────────
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

// ── Helpers ────────────────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

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
        color: Colors.transparent,
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
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
