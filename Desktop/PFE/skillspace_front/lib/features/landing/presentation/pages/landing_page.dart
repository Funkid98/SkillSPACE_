import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
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
  bool _showScrollTop = false;

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

    final shouldShowScrollTop = offset > 400;

    if (newSection != _activeSection || shouldShowScrollTop != _showScrollTop) {
      setState(() {
        _activeSection = newSection;
        _showScrollTop = shouldShowScrollTop;
      });
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    try {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _scrollController.animateTo(
          _scrollController.offset + 120,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _scrollController.animateTo(
          _scrollController.offset - 120,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
        _scrollController.animateTo(
          _scrollController.offset + 600,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
        _scrollController.animateTo(
          _scrollController.offset - 600,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.end) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.home) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {}
    return KeyEventResult.handled;
  }

  /// Handles mouse wheel scroll events and maps them to the ScrollController
  void _handleMouseScroll(PointerScrollEvent event) {
    if (!_scrollController.hasClients) return;
    final double delta = event.scrollDelta.dy;
    final double newOffset = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(newOffset);
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
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
        cardColor: Colors.transparent,
        dialogBackgroundColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: NavDrawer(scrollTo: _scrollTo),
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          // ── Listener captures mouse wheel before ScrollView consumes it ──────
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _handleMouseScroll(event);
              }
            },
            child: Stack(
              children: [
                // ── Layer 1: 3D Video Background ──────────────────────────────
                Positioned.fill(
                  child: IgnorePointer(
                    child: Scroll3DVideoBackground(
                      scrollController: _scrollController,
                      child: const SizedBox.shrink(),
                    ),
                  ),
                ),

                // ── Layer 2: Gradient overlay ─────────────────────────────────
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: ScrollConfiguration(
                    behavior: _NoScrollbarBehavior(),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 80),
                          HeroSection(
                            onDiscoverTap: () =>
                                _scrollTo(SectionKeys.features),
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
                ),

                // ── Layer 4: NavBar ───────────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: NavBar(
                    scrollTo: _scrollTo,
                    activeSection: _activeSection,
                  ),
                ),

                // ── Layer 5: Scroll-to-top FAB ────────────────────────────────
                if (_showScrollTop)
                  Positioned(
                    bottom: 32,
                    right: 32,
                    child: _ScrollToTopButton(onTap: _scrollToTop),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Removes default scrollbar and overscroll glow so our custom
// Listener is the sole input driver.
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        // intentionally exclude mouse — handled by Listener
      };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
