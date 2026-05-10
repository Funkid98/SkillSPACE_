import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class Scroll3DVideoBackground extends StatefulWidget {
  final ScrollController scrollController;

  const Scroll3DVideoBackground({
    super.key,
    required this.scrollController,
  });

  @override
  State<Scroll3DVideoBackground> createState() => _Scroll3DVideoBackgroundState();
}

class _Scroll3DVideoBackgroundState extends State<Scroll3DVideoBackground> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      // We use the most standard way to load the asset
      _controller = VideoPlayerController.asset('assets/scrollvideo.mp4');
      
      await _controller.initialize();
      await _controller.setVolume(0.0);
      await _controller.setLooping(false);
      
      // Essential: Seek to the first frame and "play/pause" to trigger rendering
      await _controller.play();
      await Future.delayed(const Duration(milliseconds: 100));
      await _controller.pause();

      if (mounted) {
        setState(() => _initialized = true);
        widget.scrollController.addListener(_onScroll);
        _onScroll(); // Initial sync
      }
    } catch (e) {
      debugPrint('❌ Video Background Error: $e');
      if (mounted) {
        setState(() => _error = true);
      }
    }
  }

  void _onScroll() {
    if (!_initialized || _error || !widget.scrollController.hasClients) return;

    final position = widget.scrollController.position;
    final progress = (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
    final duration = _controller.value.duration.inMilliseconds;
    
    // Smoothly seek to the position corresponding to scroll
    _controller.seekTo(Duration(milliseconds: (progress * duration).toInt()));
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(color: const Color(0xFF001220)); // Deep navy fallback
    }

    if (!_initialized) {
      return Container(color: const Color(0xFF001220)); // Loading fallback
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. The Video
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
        
        // 2. Dark/Gradient Overlays to ensure text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
