import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class VideoBackground extends StatefulWidget {
  final Widget child;
  final String assetPath;
  final double opacity;
  final double scale;
  final List<Color>? gradientColors;

  const VideoBackground({
    super.key,
    required this.child,
    this.assetPath = 'assets/scrollvideo.mp4',
    this.opacity = 0.75,
    this.gradientColors,
    this.scale = 1.0,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  // ignore: unused_field
  String? _error;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      String path = widget.assetPath;
      // On Web, the assets/ prefix is sometimes doubled by the player
      if (kIsWeb && path.startsWith('assets/')) {
        path = path.replaceFirst('assets/', '');
      }
      _controller = VideoPlayerController.asset(path);
      await _controller.initialize();
      if (!mounted) return;

      await _controller.setVolume(0.0);
      await _controller.setLooping(true);
      await _controller.play();

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Video initialization failed: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(VideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _controller.dispose();
      setState(() {
        _isInitialized = false;
        _isLoading = true;
      });
      _initVideo();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Video Layer ───────────────────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              curve: Curves.fastOutSlowIn,
              opacity: widget.opacity,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 800),
                curve: Curves.fastOutSlowIn,
                offset: widget.opacity == 0.0
                    ? const Offset(0.05, 0.0)
                    : Offset.zero, // Slides in from the right slightly
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.fastOutSlowIn,
                  scale: widget.opacity == 0.0
                      ? 1.05
                      : 1.0, // Slight shrink down to place
                  child: Container(
                    color: Colors.black,
                    child: _isInitialized
                        ? ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (context, VideoPlayerValue value, child) {
                              if (value.size.width == 0 ||
                                  value.size.height == 0) {
                                return const SizedBox.shrink();
                              }
                              return Transform.scale(
                                scale: widget.scale,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: value.size.width,
                                    height: value.size.height,
                                    child: VideoPlayer(_controller),
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white24)
                                : const SizedBox.shrink(),
                          ),
                  ), // closes Container
                ), // closes AnimatedScale
              ), // closes AnimatedSlide
            ), // closes AnimatedOpacity
          ), // closes IgnorePointer
        ), // closes Positioned.fill

        // ── Dark Overlay ─────────────────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              curve: Curves.fastOutSlowIn,
              opacity: widget.opacity > 0.0 ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.gradientColors ??
                        [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────────
        widget.child,
      ],
    );
  }
}
