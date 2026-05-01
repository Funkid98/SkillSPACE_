import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:camera/camera.dart';
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
  final List<Map<String, dynamic>> _chatHistory = [];

  // Speech to Text
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;

  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isMicOn = false;
  bool _isCamOn = true;
  bool _isScreenOn = false;

  String _currentQuestion = "Génération de la question en cours...";
  bool _isGenerating = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(_pulseController);

    _initSpeech();
    _initCamera();
    _startSimulationBackend();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _isMicOn) {
          if (mounted) setState(() => _isMicOn = false);
        }
      },
      onError: (errorNotification) {
        if (mounted) setState(() => _isMicOn = false);
      },
    );
    if (mounted) {
      setState(() {});
      if (_speechEnabled) {
        _toggleMicrophone(); // Auto-start the microphone
      }
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

  Future<void> _startSimulationBackend() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5005/api/interview/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': widget.roleTitle}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentQuestion = data['initialMessage'];
            _chatHistory.add({'isUser': false, 'text': _currentQuestion});
            _isGenerating = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentQuestion = "Bonjour ! Parlez-moi d'un projet dont vous êtes fier.";
            _chatHistory.add({'isUser': false, 'text': _currentQuestion});
            _isGenerating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentQuestion = "Bonjour ! Parlez-moi d'un projet dont vous êtes fier.";
          _chatHistory.add({'isUser': false, 'text': _currentQuestion});
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _sendAnswerToBackend() async {
    final answer = _textController.text.trim();
    if (answer.isEmpty) return;

    setState(() {
      _chatHistory.add({'isUser': true, 'text': answer});
      _isGenerating = true;
      _textController.clear();
      _isMicOn = false; // Stop listening when sending
    });
    _speechToText.stop();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5005/api/interview/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': answer,
          'roleTitle': widget.roleTitle,
          'history': _chatHistory,
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
    }
  }

  void _toggleMicrophone() {
    if (!_speechEnabled) return;
    
    setState(() {
      _isMicOn = !_isMicOn;
    });

    if (_isMicOn) {
      // Start listening
      _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          }
        },
        localeId: 'fr_FR',
      );
    } else {
      // Stop listening
      _speechToText.stop();
    }
  }

  void _toggleCamera() {
    setState(() {
      _isCamOn = !_isCamOn;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _speechToText.stop();
    _cameraController?.dispose();
    super.dispose();
  }

  void _finishSimulation() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SimulationResultPage(
        chatHistory: _chatHistory,
        roleTitle: widget.roleTitle,
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
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    child: const Text('Quitter', style: TextStyle(color: AppColors.textGray)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _finishSimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Terminer & Voir les résultats', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                                    image: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=400'),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                          const Text(
                            'Recruteuse IA',
                            style: TextStyle(fontSize: 14, color: AppColors.textGray),
                          ),
                          const SizedBox(height: 32),
                          
                          // AI Question Bubble
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBE9E4),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: _isGenerating
                                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange))
                                      : Text(
                                          _currentQuestion,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: AppColors.navy,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                  ),
                                  Positioned(
                                    top: -12,
                                    left: 24,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Text(
                                        '?',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Candidate Camera PiP (Bottom Right)
                  if (_isCamOn && _cameraController != null && _cameraController!.value.isInitialized)
                    Positioned(
                      bottom: 20,
                      right: 32,
                      child: Container(
                        width: 150,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: CameraPreview(_cameraController!),
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
                        color: _isMicOn ? AppColors.orange : const Color(0xFFEBE9E4), 
                        width: 2
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_isMicOn) 
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Icon(Icons.mic, color: AppColors.orange),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: _isMicOn ? 'Écoute en cours...' : 'Tapez votre réponse ou utilisez le micro...',
                              hintStyle: const TextStyle(color: AppColors.textGray),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            onSubmitted: (_) => _sendAnswerToBackend(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            onPressed: _sendAnswerToBackend,
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.orange.withOpacity(0.8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      _buildControlButton(
                        icon: Icons.monitor,
                        label: 'Écran',
                        isActive: _isScreenOn,
                        onTap: () => setState(() => _isScreenOn = !_isScreenOn),
                      ),
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
}
