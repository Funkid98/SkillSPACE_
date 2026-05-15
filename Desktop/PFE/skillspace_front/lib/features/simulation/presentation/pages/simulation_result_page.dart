import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reactive_theme/reactive_theme.dart';
import '../../../../core/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimulationResultPage extends StatefulWidget {
  final List<Map<String, dynamic>> chatHistory;
  final String roleTitle;
  final String language;
  final Map<String, dynamic>? preloadedData;

  const SimulationResultPage({
    super.key,
    required this.chatHistory,
    required this.roleTitle,
    this.language = 'fr',
    this.preloadedData,
  });

  @override
  State<SimulationResultPage> createState() => _SimulationResultPageState();
}

class _SimulationResultPageState extends State<SimulationResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = true;
  String _error = '';

  Map<String, dynamic>? _evaluationData;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.preloadedData != null) {
      _evaluationData = widget.preloadedData;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.forward();
      });
    } else {
      _fetchEvaluation();
    }
  }

  Future<void> _fetchEvaluation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      String? candidateId;
      if (userDataStr != null) {
        final user = jsonDecode(userDataStr);
        candidateId = user['id'] ?? user['_id'];
        print('SimulationResultPage: Found candidateId = $candidateId');
      } else {
        print('SimulationResultPage: userDataStr is null! Cannot get candidateId');
      }

      print('SimulationResultPage: Sending /finish request with candidateId = $candidateId');
      final response = await http.post(
        Uri.parse('http://localhost:5005/api/interview/finish'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'history': widget.chatHistory,
          'roleTitle': widget.roleTitle,
          'language': widget.language,
          if (candidateId != null) 'candidateId': candidateId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          if (mounted) {
            setState(() {
              _evaluationData = data;
              _isLoading = false;
            });
            _controller.forward();
          }
          return;
        }
      }
      throw Exception("Failed to fetch evaluation");
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Une erreur est survenue lors de l'évaluation.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF5F3EF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.orange),
              const SizedBox(height: 24),
              Text(
                widget.language == 'en'
                    ? 'Analyzing interview...'
                    : 'Analyse de l\'entretien en cours...',
                style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white : AppColors.navy,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.language == 'en'
                    ? 'Our AI is generating your results and recommendations...'
                    : 'Notre IA génère vos résultats et recommandations...',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white38
                        : AppColors.textGray.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty || _evaluationData == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF5F3EF),
        body: Center(
            child: Text(_error, style: const TextStyle(color: Colors.red))),
      );
    }

    final score = _evaluationData!['score'] ?? 0;
    final scoreRatio = score / 100.0;
    final emoState = _evaluationData!['emotionalState'] ?? 'Neutre';
    final analysis = _evaluationData!['analysis'] ?? {};
    final skills = _evaluationData!['skills'] ?? {};
    final improvements = _evaluationData!['improvements'] as List? ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF5F3EF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  // Top Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : const Color(0xFFEBE9E4),
                      borderRadius: BorderRadius.circular(12),
                      border: isDark
                          ? Border.all(color: AppColors.borderDark)
                          : null,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.orange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pré-entraînement terminé',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.navy)),
                              const SizedBox(height: 4),
                              Text(
                                'Voici votre évaluation détaillée basée sur la méthode STAR.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textGray),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Score Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : const Color(0xFFEBE9E4),
                      borderRadius: BorderRadius.circular(24),
                      border: isDark
                          ? Border.all(color: AppColors.borderDark)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: scoreRatio),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 8,
                                    backgroundColor:
                                        isDark ? Colors.white10 : Colors.white,
                                    color: AppColors.orange,
                                  );
                                },
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$score',
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.orange),
                                ),
                                Text(
                                  '/100',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white38
                                          : AppColors.textGray,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Simulation terminée ! ',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.navy),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Voici votre analyse comportementale et de performance',
                          style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDark ? Colors.white70 : AppColors.textGray),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'État émotionnel : $emoState',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Emotion Analysis Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : const Color(0xFFEBE9E4),
                      borderRadius: BorderRadius.circular(24),
                      border: isDark
                          ? Border.all(color: AppColors.borderDark)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_outlined,
                                color: AppColors.orange),
                            const SizedBox(width: 8),
                            Text('Analyse émotionnelle',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.navy)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                                child: _buildProgressRow(
                                    context,
                                    'Niveau de stress',
                                    (analysis['stressLevel'] ?? 0) / 100.0,
                                    Icons.favorite_border,
                                    Colors.red)),
                            const SizedBox(width: 32),
                            Expanded(
                                child: _buildProgressRow(
                                    context,
                                    'Confiance en soi',
                                    (analysis['selfConfidence'] ?? 0) / 100.0,
                                    Icons.star_border,
                                    Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                                child: _buildProgressRow(
                                    context,
                                    'Clarté du discours',
                                    (analysis['clarity'] ?? 0) / 100.0,
                                    Icons.show_chart,
                                    Colors.blue)),
                            const SizedBox(width: 32),
                            Expanded(
                                child: _buildProgressRow(
                                    context,
                                    'Engagement',
                                    (analysis['engagement'] ?? 0) / 100.0,
                                    Icons.auto_awesome,
                                    AppColors.orange)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3 Mini Cards
                  Row(
                    children: [
                      Expanded(
                          child: _buildMiniCard(
                              context,
                              'Clarté',
                              (skills['clarity'] ?? 0) / 100.0,
                              Icons.star_border,
                              AppColors.orange)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildMiniCard(
                              context,
                              'Pertinence',
                              (skills['relevance'] ?? 0) / 100.0,
                              Icons.trending_up,
                              Colors.green)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildMiniCard(
                              context,
                              'Structure',
                              (skills['structure'] ?? 0) / 100.0,
                              Icons.warning_amber,
                              Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Improvements Section
                  if (improvements.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : const Color(0xFFEBE9E4),
                        borderRadius: BorderRadius.circular(24),
                        border: isDark
                            ? Border.all(color: AppColors.borderDark)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_forward,
                                  color: AppColors.orange, size: 18),
                              const SizedBox(width: 8),
                              Text('À améliorer pour le vrai entretien',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.navy)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...improvements.map((imp) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildImprovementItem(
                                    context,
                                    imp['title'] ?? 'Amélioration',
                                    imp['description'] ?? '',
                                    Icons.auto_awesome,
                                    AppColors.orange),
                              )),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.preloadedData == null) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          icon: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text('Refaire',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC65D3B),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        icon: Icon(
                          Icons.exit_to_app,
                          size: 18,
                          color: isDark ? Colors.white70 : AppColors.textGray,
                        ),
                        label: Text('Quitter',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textGray,
                                fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context, String label, double value,
      IconData icon, Color color) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : AppColors.textGray)),
              ],
            ),
            Text('${(value * 100).toInt()}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.navy)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: isDark ? Colors.white10 : Colors.white,
          valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white70 : AppColors.navy),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildMiniCard(BuildContext context, String label, double value,
      IconData icon, Color iconColor) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFEBE9E4),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppColors.borderDark) : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.navy)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            backgroundColor: isDark ? Colors.white10 : Colors.white,
            valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white70 : AppColors.navy),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 8),
          Text('${(value * 100).toInt()}%',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.navy)),
        ],
      ),
    );
  }

  Widget _buildImprovementItem(BuildContext context, String title, String desc,
      IconData icon, Color color) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.navy)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : AppColors.textGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
      BuildContext context, String label, String value, IconData icon) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: AppColors.borderDark) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.orange),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white38 : AppColors.textGray),
            ),
          ],
        ),
      ),
    );
  }
}
