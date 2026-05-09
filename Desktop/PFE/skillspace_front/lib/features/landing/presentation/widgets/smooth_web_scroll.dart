import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SmoothWebScroll extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  const SmoothWebScroll({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<SmoothWebScroll> createState() => _SmoothWebScrollState();
}

class _SmoothWebScrollState extends State<SmoothWebScroll> {
  double _targetScroll = 0.0;

  @override
  void initState() {
    super.initState();
    _targetScroll = widget.controller.initialScrollOffset;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final double scrollDelta = event.scrollDelta.dy;
      // Multiply the delta for a faster, more responsive feel
      _targetScroll += scrollDelta * 2.5;

      final double maxScroll = widget.controller.position.maxScrollExtent;
      final double minScroll = widget.controller.position.minScrollExtent;

      _targetScroll = _targetScroll.clamp(minScroll, maxScroll);

      widget.controller.animateTo(
        _targetScroll,
        duration: const Duration(milliseconds: 800), // Luxurious, long ease
        curve: Curves.easeOutQuart, // Buttery deceleration (Apple style)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: widget.child,
    );
  }
}
