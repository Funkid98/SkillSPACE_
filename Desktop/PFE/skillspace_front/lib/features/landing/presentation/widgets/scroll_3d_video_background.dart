import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

class Scroll3DVideoBackground extends StatefulWidget {
  final ScrollController scrollController;

  const Scroll3DVideoBackground({
    super.key,
    required this.scrollController,
  });

  @override
  State<Scroll3DVideoBackground> createState() =>
      _Scroll3DVideoBackgroundState();
}

class _Scroll3DVideoBackgroundState extends State<Scroll3DVideoBackground>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  late Ticker _ticker;
  double _targetMs = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/scrollvideo.mp4');
      await _controller.initialize();
      if (!mounted) return;
      await _controller.setVolume(0.0);
      await _controller.setLooping(false);
      await _controller.pause();

      if (mounted) {
        setState(() => _isInitialized = true);
        widget.scrollController.addListener(_onScroll);
        _onScroll(); // Initial sync
      }
    } catch (e) {
      debugPrint('❌ Video error: $e');
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_isInitialized || _isDisposed) return;
    
    final currentMs = _controller.value.position.inMilliseconds.toDouble();
    final diff = (_targetMs - currentMs).abs();

    // Only seek if the difference is meaningful (at least one frame)
    if (diff > 16) {
      // Direct seek is the most reliable way to scrub in both directions
      _controller.seekTo(Duration(milliseconds: _targetMs.toInt()));
    }
  }

  void _onScroll() {
    if (!mounted || !_isInitialized) return;
    if (!widget.scrollController.hasClients) return;

    final position = widget.scrollController.position;
    final offset = position.pixels;
    final maxScroll = position.maxScrollExtent;

    if (maxScroll <= 0) return;

    final double progress = (offset / maxScroll).clamp(0.0, 1.0);
    final totalMs = _controller.value.duration.inMilliseconds.toDouble();
    _targetMs = progress * totalMs;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ticker.dispose();
    widget.scrollController.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (!_isInitialized) {
      return Container(color: const Color(0xFF001220));
    }

    return Stack(
      children: [
        // ✅ Full screen responsive video
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              final videoW = _controller.value.size.width;
              final videoH = _controller.value.size.height;

              if (videoW == 0 || videoH == 0) {
                return Container(color: const Color(0xFF001220));
              }

              // ✅ Cover fit — scale video so it fills screen in both dimensions
              final scaleW = screenW / videoW;
              final scaleH = screenH / videoH;
              final scale = scaleW > scaleH ? scaleW : scaleH;

              final displayW = videoW * scale;
              final displayH = videoH * scale;

              // ✅ Center the video
              final offsetX = (screenW - displayW) / 2;
              final offsetY = (screenH - displayH) / 2;

              return Stack(
                children: [
                  Positioned(
                    left: offsetX,
                    top: offsetY,
                    width: displayW,
                    height: displayH,
                    child: VideoPlayer(_controller),
                  ),
                ],
              );
            },
          ),
        ),

        // Dark gradient overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
