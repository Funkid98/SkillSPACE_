import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

enum RevealDirection { fromBottom, fromTop, fromLeft, fromRight, fade }

class AnimatedReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final RevealDirection direction;

  const AnimatedReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.direction = RevealDirection.fromBottom,
  });

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _triggered = false;

  late final Key _visibilityKey;

  Offset _getBeginOffset() {
    switch (widget.direction) {
      case RevealDirection.fromBottom:
        return const Offset(0, 0.08);
      case RevealDirection.fromTop:
        return const Offset(0, -0.08);
      case RevealDirection.fromLeft:
        return const Offset(-0.08, 0);
      case RevealDirection.fromRight:
        return const Offset(0.08, 0);
      case RevealDirection.fade:
        return Offset.zero;
    }
  }

  @override
  void initState() {
    super.initState();
    _visibilityKey = widget.key ?? UniqueKey();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: _getBeginOffset(), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_triggered && info.visibleFraction > 0.1) {
      _triggered = true;
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}
