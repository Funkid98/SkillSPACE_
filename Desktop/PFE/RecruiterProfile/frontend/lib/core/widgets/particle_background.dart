import 'package:flutter/material.dart';
import '../app_colors.dart';

class ParticleBackground extends StatefulWidget {
  final Widget child;

  const ParticleBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _trail = [];
  Offset? _pointerPosition;

  final int _maxTrailLength = 50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 12), // Slightly slower cycle for landing
    )..addListener(_updateTrail);

    _controller.repeat();
  }

  void _updateTrail() {
    if (!mounted) return;

    if (_pointerPosition != null) {
      if (_trail.isNotEmpty) {
        Offset lastPoint = _trail.first;
        Offset newPoint = Offset(
          lastPoint.dx + (_pointerPosition!.dx - lastPoint.dx) * 0.5,
          lastPoint.dy + (_pointerPosition!.dy - lastPoint.dy) * 0.5,
        );
        _trail.insert(0, newPoint);
      } else {
        _trail.insert(0, _pointerPosition!);
      }

      if (_trail.length > _maxTrailLength) {
        _trail.removeLast();
      }
    } else {
      if (_trail.isNotEmpty) {
        _trail.removeLast();
        if (_trail.length > 2) {
          _trail.removeLast();
        }
      }
    }
  }

  void _updatePointerPosition(Offset pos) =>
      setState(() => _pointerPosition = pos);
  void _clearPointerPosition() => setState(() => _pointerPosition = null);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => _updatePointerPosition(event.localPosition),
      onExit: (_) => _clearPointerPosition(),
      hitTestBehavior: HitTestBehavior.translucent,
      child: Listener(
        onPointerMove: (event) => _updatePointerPosition(event.localPosition),
        onPointerDown: (event) => _updatePointerPosition(event.localPosition),
        onPointerUp: (_) => _clearPointerPosition(),
        onPointerCancel: (_) => _clearPointerPosition(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: AppColors.bg),
            ),
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _TrailPainter(
                          trail: _trail,
                          progress: _controller.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  final List<Offset> trail;
  final double progress;
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  _TrailPainter({required this.trail, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (trail.length < 2) return;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Cycling through brand-relevant colors
    final colors = [
      const Color(0xFF1E2B6B), // Navy
      const Color(0xFFE8622A), // Orange
      const Color(
          0xFF4CAF50), // Green (bringing back the brand green in the cycle)
      const Color(0xFF1E6B6B), // Teal
      const Color(0xFF1E2B6B), // Back to Navy
    ];

    int section = (progress * (colors.length - 1)).floor();
    double subProgress = (progress * (colors.length - 1)) - section;
    Color currentColor =
        Color.lerp(colors[section], colors[section + 1], subProgress)!;

    for (int i = trail.length - 2; i >= 0; i--) {
      double t = 1.0 - (i / trail.length);
      _paint.strokeWidth = 24.0 * t;
      _paint.color = currentColor.withOpacity(t);
      _paint.blendMode = BlendMode.src;

      canvas.drawLine(trail[i], trail[i + 1], _paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) => true;
}
