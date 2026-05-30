import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart' hide Animation;
import 'package:http/http.dart' as http;
import '../../../../core/api_constants.dart';
import 'package:reactive_theme/reactive_theme.dart';
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

class _SimulationLivePageState extends State<SimulationLivePage> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatHistory = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Audio Recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  String _selectedLanguage = 'fr'; // 'fr' or 'en'
  bool _isRecording = false;
  bool _isSending = false;

  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCamOn = true;

  // PiP Position
  double? _pipTop;
  double? _pipLeft;

  String _currentQuestion = "Génération de la question en cours...";
  String get _generatingText => _selectedLanguage == 'en'
      ? "Generating question..."
      : "Génération de la question en cours...";
  bool _isGenerating = true;
  bool _checkingPermissions = true;
  bool _hasPermissions = false;

  // Timer
  Timer? _timer;
  int _secondsRemaining = 90;
  static const int _maxResponseTime = 90;

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    setState(() {
      _checkingPermissions = true;
    });

    try {
      // 1. Check Microphone Permission
      final micPermission = await _audioRecorder.hasPermission();
      if (!micPermission) {
        setState(() {
          _hasPermissions = false;
          _checkingPermissions = false;
        });
        return;
      }

      // 2. Check Camera Permission
      _cameras = await availableCameras();

      setState(() {
        _hasPermissions = true;
        _checkingPermissions = false;
      });

      _initCamera();
      _startSimulationBackend();
    } catch (e) {
      print("Permission Check Error: $e");
      setState(() {
        _hasPermissions = false;
        _checkingPermissions = false;
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
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
        Uri.parse('${ApiConstants.baseUrl}/api/interview/start'),
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
            final Uint8List audioBytes = base64Decode(data['audioBase64']);
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

  Future<void> _recordAndSend() async {
    if (_isSending) return;

    try {
      if (await _audioRecorder.isRecording()) {
        // Stop recording and send the audio
        setState(() => _isRecording = false);
        await _sendAudioToBackend();
      } else {
        // Check permission
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
          path = '${directory.path}/audio_record.ogg';
        }

        const config = RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: 32000,
          sampleRate: 48000,
        );

        await _audioRecorder.start(config, path: path ?? '');
        setState(() => _isRecording = true);
      }
    } catch (e) {
      print("Mic Error: $e");
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur micro: $e')),
        );
      }
    }
  }

  Future<void> _sendAudioToBackend() async {
    final path = await _audioRecorder.stop();
    // Wait for file to finish writing to disk
    await Future.delayed(const Duration(milliseconds: 300));
    if (path == null) {
      setState(() => _isSending = false);
      return;
    }

    _stopTimer();
    setState(() => _isSending = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/api/interview/chat'),
      );

      if (kIsWeb) {
        final audioResponse = await http.get(Uri.parse(path));
        request.files.add(http.MultipartFile.fromBytes(
          'audio',
          audioResponse.bodyBytes,
          filename: 'audio.ogg',
          contentType: MediaType('audio', 'ogg'),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'audio',
          path,
          contentType: MediaType('audio', 'ogg'),
        ));
      }

      request.fields['language'] = _selectedLanguage;
      request.fields['roleTitle'] = widget.roleTitle;
      request.fields['history'] = jsonEncode(_chatHistory);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          final userText = data['userTranscript'] ?? '(Réponse vocale)';
          setState(() {
            _chatHistory.add({
              'isUser': true,
              'text': userText,
              'audioUrl': data['audioUrl'],
              'vocalMetrics': data['vocalMetrics']
            });
            _currentQuestion = data['reply'];
            _chatHistory.add({'isUser': false, 'text': _currentQuestion});
            _isSending = false;
          });

          if (data['audioBase64'] != null) {
            final Uint8List audioBytes = base64Decode(data['audioBase64']);
            _audioPlayer.play(BytesSource(audioBytes));
          }

          _startTimer();
          _scrollToBottom();
        }
      } else {
        print("Chat error: ${response.body}");
        if (mounted) _fallbackResponse();
        setState(() => _isSending = false);
      }
    } catch (e) {
      print("Error sending audio: $e");
      if (mounted) _fallbackResponse();
      setState(() => _isSending = false);
    }
  }

  void _fallbackResponse() {
    if (mounted) {
      setState(() {
        _currentQuestion = _selectedLanguage == 'en'
            ? 'Interesting. Could you elaborate a bit more?'
            : 'Intéressant. Pouvez-vous élaborer davantage ?';
        _chatHistory.add({'isUser': false, 'text': _currentQuestion});
        _isSending = false;
      });
      _startTimer();
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
    if (_checkingPermissions) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );
    }

    final isDark = ReactiveMode.isDarkMode(context);

    if (!_hasPermissions) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF5F3EF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off_outlined,
                    size: 80,
                    color: isDark
                        ? Colors.redAccent.withOpacity(0.8)
                        : Colors.redAccent),
                const SizedBox(height: 24),
                Text(
                  'Accès requis',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.navy),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pour commencer l\'entretien, nous avons besoin d\'accéder à votre caméra et à votre microphone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : AppColors.textGray),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _checkAllPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Autoriser l\'accès',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Retour',
                      style: TextStyle(
                          color: isDark ? Colors.white38 : AppColors.textGray)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF5F3EF),
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
                      color: isDark
                          ? AppColors.surfaceDark
                          : const Color(0xFFEBE9E4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.roleTitle.replaceAll(' ', '\n'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: Text('Quitter',
                        style: TextStyle(
                            color:
                                isDark ? Colors.white38 : AppColors.textGray)),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      final int userMessageCount = _chatHistory
                          .where((msg) => msg['isUser'] == true)
                          .length;
                      final bool canFinish = userMessageCount >= 2;

                      return ElevatedButton(
                        onPressed: canFinish ? _finishSimulation : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              isDark ? Colors.white12 : Colors.black12,
                          disabledForegroundColor:
                              isDark ? Colors.white38 : Colors.black38,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Terminer & Voir les résultats',
                            style: TextStyle(fontSize: 12)),
                      );
                    },
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
                          // 2.5D Animated Recruiter (Thomas Lefebvre)
                          Stack(
                            children: [
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isDark
                                          ? AppColors.surfaceDark
                                          : AppColors.navy.withOpacity(0.8),
                                      AppColors.navy,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(isDark ? 0.4 : 0.3),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : Colors.white.withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // The Static Recruiter Photo
                                    Image.asset(
                                      'assets/recruiter.png',
                                      width: 280,
                                      height: 280,
                                      fit: BoxFit.cover,
                                    ),

                                    // Subtle gradient overlay for depth
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            AppColors.navy.withOpacity(0.4),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00FF88),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF00FF88),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'EN DIRECT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Thomas Lefebvre',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : AppColors.navy,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: Colors.blue.shade400,
                              ),
                            ],
                          ),
                          Text(
                            'RECRUTEUR IA • SKILLSPACE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color:
                                  isDark ? Colors.white38 : AppColors.textGray,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Timer Display
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _secondsRemaining < 15
                                  ? Colors.red.withOpacity(0.1)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : AppColors.navy.withOpacity(0.05)),
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
                                      : (isDark
                                          ? Colors.white70
                                          : AppColors.navy),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatTime(_secondsRemaining),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _secondsRemaining < 15
                                        ? Colors.red
                                        : (isDark
                                            ? Colors.white70
                                            : AppColors.navy),
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
                                  return _buildChatBubble(msg['isUser'],
                                      msg['text'], msg['audioUrl']);
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
                  // Big Record Button
                  GestureDetector(
                    onTap: _recordAndSend,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? Colors.red
                            : (_isSending ? Colors.grey : AppColors.orange),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isRecording ? Colors.red : AppColors.orange)
                                    .withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isSending
                            ? const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isRecording ? Icons.stop : Icons.mic,
                                size: 36,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isRecording
                        ? 'Appuyez pour arrêter'
                        : (_isSending
                            ? 'Envoi en cours...'
                            : 'Appuyez pour enregistrer'),
                    style: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.textGray,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: _isCamOn ? Icons.videocam : Icons.videocam_off,
                        label: _isCamOn ? 'Caméra ON' : 'Caméra OFF',
                        isActive: _isCamOn,
                        onTap: _toggleCamera,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      // Language Selector
                      _buildLanguageButton(isDark),
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
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.orange : AppColors.navy)
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFEBE9E4)),
          borderRadius: BorderRadius.circular(24),
          border: isActive
              ? null
              : Border.all(
                  color: isDark ? AppColors.borderDark : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.navy),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.navy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(bool isDark) {
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
          color:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEBE9E4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.navy.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.language,
                size: 18, color: isDark ? Colors.white70 : AppColors.navy),
            const SizedBox(width: 8),
            Text(
              _selectedLanguage.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(bool isUser, String text, [String? audioUrl]) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.orange
              : (isDark ? AppColors.surfaceDark : const Color(0xFFEBE9E4)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: !isUser && isDark
              ? Border.all(color: AppColors.borderDark)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.navy),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (isUser && audioUrl != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _playRecording(audioUrl),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Réécouter',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _playRecording(String url) async {
    final fullUrl = '${ApiConstants.baseUrl}$url';
    try {
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        await _audioPlayer.play(BytesSource(response.bodyBytes));
      }
    } catch (e) {
      print("Error playing recording: $e");
    }
  }

  Widget _buildLoadingBubble() {
    final isDark = ReactiveMode.isDarkMode(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFEBE9E4),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: isDark ? Border.all(color: AppColors.borderDark) : null,
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
