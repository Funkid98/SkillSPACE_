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
  State<Scroll3DVideoBackground> createState() =>
      _Scroll3DVideoBackgroundState();
}

class _Scroll3DVideoBackgroundState extends State<Scroll3DVideoBackground> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _error;
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/scrollvideo.mp4');
      await _controller.initialize();
      if (!mounted) return;

      await _controller.setVolume(0.0);
      await _controller.setLooping(false);

      await _controller.play();
      await _controller.pause();
      await _controller.seekTo(Duration.zero);

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onScroll();
        widget.scrollController.addListener(_onScroll);
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

  void _onScroll() {
    if (!mounted || !_isInitialized || _isSeeking) return;
    if (!widget.scrollController.hasClients) return;

    final position = widget.scrollController.position;
    final offset = position.pixels;
    final maxScroll = position.maxScrollExtent;

    if (maxScroll <= 0) return;

    final double progress = (offset / maxScroll).clamp(0.0, 1.0);
    final totalMs = _controller.value.duration.inMilliseconds;
    final targetMs = (totalMs * progress).toInt();

    _isSeeking = true;
    _controller.seekTo(Duration(milliseconds: targetMs)).then((_) async {
      if (!mounted) return;
      await _controller.play();
      await _controller.pause();
      _isSeeking = false;
    });
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
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: const Color(0xFF001220),
              child: _isInitialized
                  ? ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, VideoPlayerValue value, child) {
                        return FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: value.size.width,
                            height: value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white24)
                          : _error != null
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'Video Error: $_error\nCheck assets/scrollvideo.mp4',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12),
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
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
        widget.child,
      ],
    );
  }
}
