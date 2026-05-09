import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Scroll3DVideoBackground extends StatefulWidget {
  final ScrollController scrollController;
  final Widget child;

  const Scroll3DVideoBackground({
    super.key,
    required this.scrollController,
    required this.child,
  });

  @override
  State<Scroll3DVideoBackground> createState() => _Scroll3DVideoBackgroundState();
}

class _Scroll3DVideoBackgroundState extends State<Scroll3DVideoBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = widget.scrollController.offset;
    final maxScroll = widget.scrollController.position.maxScrollExtent > 0
        ? widget.scrollController.position.maxScrollExtent
        : 3000.0;
    double progress = (offset / maxScroll).clamp(0.0, 1.0);
    _lottieController.value = progress;
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Lottie.asset(
              'assets/network_animation.json',
              controller: _lottieController,
              onLoaded: (composition) {
                _lottieController.duration = composition.duration;
              },
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
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
        widget.child,
      ],
    );
  }
}
