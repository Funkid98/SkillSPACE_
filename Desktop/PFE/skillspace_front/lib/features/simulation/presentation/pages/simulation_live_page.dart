import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import '../../../../core/app_colors.dart';
import 'simulation_result_page.dart';

class SimulationLivePage extends StatefulWidget {
  final String roleTitle;

  const SimulationLivePage({super.key, required this.roleTitle});

  @override
  State<SimulationLivePage> createState() => _SimulationLivePageState();
}

class _SimulationLivePageState extends State<SimulationLivePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatHistory = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Audio Recording (Whisper)
  final AudioRecorder _audioRecorder = AudioRecorder();
  String _selectedLanguage = 'fr'; // 'fr' or 'en'
  bool _isTranscribing = false;

  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isMicOn = false;
  bool _isCamOn = true;
  final bool _isScreenOn = false;

  // PiP Position
  double? _pipTop;
  double? _pipLeft;

  String _currentQuestion = "Génération de la question en cours...";
  String get _generatingText => _selectedLanguage == 'en'
      ? "Generating question..."
      : "Génération de la question en cours...";
  bool _isGenerating = true;

  // Timer
  Timer? _timer;
  int _secondsRemaining = 90; // 90 seconds per answer
  static const int _maxResponseTime = 90;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.8, end: 1.2).animate(_pulseController);

    _initSpeech();
    _initCamera();
    _startSimulationBackend();
  }

  Future<void> _initSpeech() async {
    // Check for permissions
    if (await _audioRecorder.hasPermission()) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use the front camera if available
        final frontCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras!.first);

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Camera Error: $e');
      if (mounted) setState(() => _isCamOn = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _maxResponseTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        // Optionnel: Auto-envoyer ou alerter l'utilisateur
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _startSimulationBackend() async {
    setState(() {
      _currentQuestion = _generatingText;
      _isGenerating = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5005/api/interview/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': widget.roleTitle,
          'language': _selectedLanguage,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentQuestion = data['initialMessage'];
            _chatHistory.add({'isUser': false, 'text': _currentQuestion});
            _isGenerating = false;
          });

          if (data['audioBase64'] != null) {
            Uint8List audioBytes = base64Decode(data['audioBase64']);
            _audioPlayer.play(BytesSource(audioBytes));
          }

          _startTimer();
          _scrollToBottom();
        }
      } else {
        if (mounted) _fallbackStart();
      }
    } catch (e) {
      if (mounted) _fallbackStart();
    }
  }

  void _fallbackStart() {
    setState(() {
      _currentQuestion = _selectedLanguage == 'en'
          ? "Hello! Tell me about a project you are proud of."
          : "Bonjour ! Parlez-moi d'un projet dont vous êtes fier.";
      _chatHistory.add({'isUser': false, 'text': _currentQuestion});
      _isGenerating = false;
    });
    _startTimer();
  }

  Future<void> _sendAnswerToBackend() async {
    final answer = _textController.text.trim();
    if (answer.isEmpty) return;

    _stopTimer();

    setState(() {
      _chatHistory.add({'isUser': true, 'text': answer});
      _isGenerating = true;
      _textController.clear();
      _isMicOn = false;
    });
    _scrollToBottom();

    _stopAndTranscribe();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5005/api/interview/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': answer,
          'roleTitle': widget.roleTitle,
          'history': _chatHistory,
          'language': _selectedLanguage,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentQuestion = data['reply'];
            _chatHistory.add({'isUser': false, 'text': _currentQuestion});
            _isGenerating = false;
          });

          if (data['audioBase64'] != null) {
            Uint8List audioBytes = base64Decode(data['audioBase64']);
            _audioPlayer.play(BytesSource(audioBytes));
          }

          _startTimer();
          _scrollToBottom();
        }
      } else {
        _fallbackResponse();
      }
    } catch (e) {
      _fallbackResponse();
    }
  }

  void _fallbackResponse() {
    if (mounted) {
      setState(() {
        _currentQuestion = "Intéressant. Pouvez-vous élaborer davantage ?";
        _chatHistory.add({'isUser': false, 'text': _currentQuestion});
        _isGenerating = false;
      });
      _startTimer();
    }
  }

  Future<void> _toggleMicrophone() async {
    if (_isTranscribing) return;

    try {
      if (await _audioRecorder.isRecording()) {
        setState(() {
          _isMicOn = false;
          _isTranscribing = true;
        });
        await _stopAndTranscribe();
      } else {
        // Explicitly check and request permission
        final hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Permission micro refusée. Veuillez l\'autoriser.')),
            );
          }
          return;
        }

        // Start recording
        String? path;
        if (!kIsWeb) {
          final directory = await getTemporaryDirectory();
          path = '${directory.path}/audio_record.m4a';
        }

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: path ?? '');
        setState(() {
          _isMicOn = true;
        });
      }
    } catch (e) {
      print("Mic Toggle Error: $e");
      if (mounted) {
        setState(() {
          _isMicOn = false;
          _isTranscribing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur micro: $e')),
        );
      }
    }
  }

  Future<void> _stopAndTranscribe() async {
    final path = await _audioRecorder.stop();
    if (path == null) {
      setState(() => _isTranscribing = false);
      return;
    }

    setState(() => _isTranscribing = true);

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://localhost:5005/api/interview/transcribe'));

      if (kIsWeb) {
        // On web, stop() returns a blob URL. Fetch bytes first.
        final audioResponse = await http.get(Uri.parse(path));
        request.files.add(http.MultipartFile.fromBytes(
          'audio',
          audioResponse.bodyBytes,
          filename: 'audio.m4a',
          contentType: MediaType('audio', 'm4a'),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'audio',
          path,
          contentType: MediaType('audio', 'm4a'),
        ));
      }

      request.fields['language'] = _selectedLanguage;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _textController.text = data['text'];
            _isTranscribing = false;
          });
          // Auto-send if it's a significant transcription?
          // For now let the user review and click send
        }
      } else {
        print("Transcription failed: ${response.body}");
        setState(() => _isTranscribing = false);
      }
    } catch (e) {
      print("Error transcribing: $e");
      setState(() => _isTranscribing = false);
    }
  }

  void _toggleCamera() {
    setState(() {
      _isCamOn = !_isCamOn;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _cameraController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _finishSimulation() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => SimulationResultPage(
                chatHistory: _chatHistory,
                roleTitle: widget.roleTitle,
                language: _selectedLanguage,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBE9E4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.roleTitle.replaceAll(' ', '\n'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('Quitter',
                        style: TextStyle(color: AppColors.textGray)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _finishSimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Terminer & Voir les résultats',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  )
                ],
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Video Container (AI Recruiter)
                          Stack(
                            children: [
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(24),
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=400'),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ScaleTransition(
                                        scale: _pulseAnimation,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'EN DIRECT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sophie Martin',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy),
                          ),
                          const Text(
                            'Recruteuse IA',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textGray),
                          ),
                          const SizedBox(height: 12),
                          // Timer Display
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _secondsRemaining < 15
                                  ? Colors.red.withOpacity(0.1)
                                  : AppColors.navy.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: _secondsRemaining < 15
                                      ? Colors.red
                                      : AppColors.navy,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatTime(_secondsRemaining),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _secondsRemaining < 15
                                        ? Colors.red
                                        : AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Real-time Conversation Flow
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 400),
                              child: ListView.builder(
                                controller: _scrollController,
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _chatHistory.length +
                                    (_isGenerating ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _chatHistory.length &&
                                      _isGenerating) {
                                    return _buildLoadingBubble();
                                  }
                                  final msg = _chatHistory[index];
                                  return _buildChatBubble(
                                      msg['isUser'], msg['text']);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Candidate Camera PiP (Draggable)
                  if (_isCamOn &&
                      _cameraController != null &&
                      _cameraController!.value.isInitialized)
                    Positioned(
                      top: _pipTop,
                      left: _pipLeft,
                      right: _pipLeft == null ? 32 : null,
                      bottom: _pipTop == null ? 20 : null,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            // Initialize position if null (start from bottom right)
                            _pipLeft ??=
                                MediaQuery.of(context).size.width - 150 - 32;
                            _pipTop ??= MediaQuery.of(context).size.height -
                                200 -
                                150; // Adjust for bottom area

                            _pipLeft = _pipLeft! + details.delta.dx;
                            _pipTop = _pipTop! + details.delta.dy;
                          });
                        },
                        child: Container(
                          width: 160,
                          height:
                              120, // Changed to a more natural landscape/webcam ratio
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2), width: 1),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Stack(
                            children: [
                              Transform.scale(
                                scale: 1.1, // Slight zoom to ensure fill
                                child: Center(
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                              // Gradient Overlay for better contrast
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.1),
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.4),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.drag_indicator,
                                      color: Colors.white.withOpacity(0.9),
                                      size: 16),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'VOUS',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Area
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _isMicOn
                              ? AppColors.orange
                              : (_isTranscribing
                                  ? Colors.blue
                                  : const Color(0xFFEBE9E4)),
                          width: 2),
                    ),
                    child: Row(
                      children: [
                        if (_isMicOn)
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Icon(Icons.mic, color: AppColors.orange),
                          ),
                        if (_isTranscribing)
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.blue)),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: _isMicOn
                                  ? 'Enregistrement en cours (Whisper)...'
                                  : (_isTranscribing
                                      ? 'Transcription par Whisper...'
                                      : 'Tapez votre réponse ou utilisez le micro...'),
                              hintStyle:
                                  const TextStyle(color: AppColors.textGray),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                            ),
                            onSubmitted: (_) => _sendAnswerToBackend(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            onPressed: _sendAnswerToBackend,
                            icon: const Icon(Icons.send_rounded,
                                color: Colors.white, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppColors.orange.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: _isMicOn ? Icons.mic : Icons.mic_off,
                        label: _isMicOn ? 'Micro ON' : 'Micro OFF',
                        isActive: _isMicOn,
                        onTap: _toggleMicrophone,
                      ),
                      const SizedBox(width: 16),
                      _buildControlButton(
                        icon: _isCamOn ? Icons.videocam : Icons.videocam_off,
                        label: _isCamOn ? 'Caméra ON' : 'Caméra OFF',
                        isActive: _isCamOn,
                        onTap: _toggleCamera,
                      ),
                      const SizedBox(width: 16),
                      // Language Selector
                      _buildLanguageButton(),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navy : const Color(0xFFEBE9E4),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : AppColors.navy,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLanguage = _selectedLanguage == 'fr' ? 'en' : 'fr';

          // If we haven't started talking yet, or if we want to restart with new language
          if (_chatHistory.length <= 1) {
            _chatHistory.clear();
            _isGenerating = true;
            _startSimulationBackend();
          }
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEBE9E4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.navy.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.language, size: 18, color: AppColors.navy),
            const SizedBox(width: 8),
            Text(
              _selectedLanguage.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppColors.orange : const Color(0xFFEBE9E4),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 450),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.navy,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFEBE9E4),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.orange),
        ),
      ),
    );
  }
}
