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
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller?.dispose();
      _controller = VideoPlayerController.asset('assets/scrollvideo.mp4');
      await _controller!.initialize();
      if (!mounted) {
        _controller?.dispose();
        _controller = null;
        return;
      }

      await _controller!.setVolume(0.0);
      await _controller!.setLooping(true);
      await _controller!.play();

      if (!mounted) {
        _controller?.dispose();
        _controller = null;
        return;
      }

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Video initialization failed: $e');
      _controller?.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot-reload safety: dispose old controller and recreate
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isLoading = true;
    _error = null;
    _initVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Video Layer ───────────────────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.75, // was 0.4, raise it so video is more visible
              child: Container(
                color: Colors.black, // pure black base instead of navy bleed
                child: _isInitialized && _controller != null
                    ? ValueListenableBuilder(
                        valueListenable: _controller!,
                        builder: (context, VideoPlayerValue value, child) {
                          // Guard: video_player_web fires before size is ready
                          if (value.size.width == 0 || value.size.height == 0) {
                            return const SizedBox.shrink();
                          }
                          return FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: value.size.width,
                              height: value.size.height,
                              child: VideoPlayer(_controller!),
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
        ),

// ── Dark Overlay — much lighter now ──────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
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
