import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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

class _Scroll3DVideoBackgroundState extends State<Scroll3DVideoBackground> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/scrollvideo.mp4')
      ..initialize().then((_) {
        if (mounted) {
          _controller.setVolume(0.0);
          _controller.setLooping(true); // Enable internal looping just in case
          setState(() {
            _isInitialized = true;
          });
          _onScroll(); // Set initial position
        }
      });
    widget.scrollController.addListener(_onScroll);
  }

  double _lastProgress = -1.0;

  void _onScroll() {
    if (!mounted || !_isInitialized) return;

    final offset = widget.scrollController.offset;
    
    // Define how many pixels of scroll correspond to one full video loop
    // 2000px is a good balance for a smooth experience
    const double pixelsPerLoop = 2000.0;
    
    // Use modulo to create a looping progress value (0.0 to 1.0)
    // This handles both forward and reverse scroll naturally
    double progress = (offset / pixelsPerLoop) % 1.0;
    if (progress < 0) progress = 1.0 + progress; // Handle negative offset (bouncing)

    // Only seek if progress has changed enough to be noticeable
    if ((progress - _lastProgress).abs() < 0.0005) return;
    _lastProgress = progress;
    
    // Calculate target duration
    final totalDuration = _controller.value.duration;
    final targetDuration = Duration(
      milliseconds: (totalDuration.inMilliseconds * progress).toInt(),
    );
    
    // Seek to the calculated position
    _controller.seekTo(targetDuration);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Video
        Positioned.fill(
          child: IgnorePointer(
            child: _isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : Container(
                    color: const Color(0xFF001220), // Dark fallback color
                  ),
          ),
        ),
        
        // Dark overlay for better text readability
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
        
        // The actual content
        widget.child,
      ],
    );
  }
}
