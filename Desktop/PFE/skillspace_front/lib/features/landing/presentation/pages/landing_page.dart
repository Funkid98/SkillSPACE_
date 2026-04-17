import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/nav_bar.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/steps_section.dart';
import '../widgets/audience_section.dart';
import '../widgets/cta_section.dart';
import '../widgets/app_footer.dart';
import '../../../../shared/widgets/floating_language_switcher.dart';

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

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavDrawer(scrollTo: _scrollTo),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: _handleKey,
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 80), // Padding for fixed navbar
                    const HeroSection(),
                    FeaturesSection(key: SectionKeys.features),
                    StepsSection(key: SectionKeys.steps),
                    AudienceSection(key: SectionKeys.audience),
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
              child: NavBar(scrollTo: _scrollTo),
            ),
            const FloatingLanguageSwitcher(),
          ],
        ),
      ),
    );
  }
}
