import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reactive_theme/reactive_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_colors.dart';
import '../pages/candidate_formation_details_page.dart';

class RecommendationsModal extends StatefulWidget {
  final String skill;
  final int score;

  /// The level the user self-declared before the quiz (Beginner/Intermediate/Advanced)
  final String? claimedLevel;

  /// Raw answers_analysis from the quiz evaluation (to extract wrong topics)
  final List<dynamic>? answersAnalysis;

  const RecommendationsModal({
    super.key,
    required this.skill,
    required this.score,
    this.claimedLevel,
    this.answersAnalysis,
  });

  @override
  State<RecommendationsModal> createState() => _RecommendationsModalState();
}

class _RecommendationsModalState extends State<RecommendationsModal> {
  bool _isLoading = true;
  String _levelDetermined = '';
  List<dynamic> _internalFormations = [];
  List<dynamic> _externalFormations = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/quiz/recommend'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'skill': widget.skill,
          'score': widget.score,
          // Pass context for personalized AI recommendations
          if (widget.claimedLevel != null) 'claimedLevel': widget.claimedLevel,
          if (widget.answersAnalysis != null)
            'answersAnalysis': widget.answersAnalysis,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _levelDetermined = data['level_determined'] ?? '';
            _internalFormations = data['internal_formations'] ?? [];
            _externalFormations = data['external_formations'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load recommendations';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred';
          _isLoading = false;
        });
      }
    }
  }

  String _mapLevelToFrench(String level) {
    switch (level) {
      case 'Beginner':
        return 'Débutant';
      case 'Intermediate':
        return 'Intermédiaire';
      case 'Advanced':
        return 'Avancé';
      default:
        return level;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    final isDark = ReactiveMode.isDarkMode(context);
    if (_isLoading) {
      content = Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.orange),
            const SizedBox(height: 16),
            Text('Recherche de formations adaptées...',
                style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.textGray)),
          ],
        ),
      );
    } else if (_error.isNotEmpty) {
      content = Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            )
          ],
        ),
      );
    } else {
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school,
                    color: isDark ? AppColors.orange : AppColors.navy,
                    size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Formations recommandées pour ${widget.skill}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Basé sur votre score de ${widget.score}% (Niveau ${_mapLevelToFrench(_levelDetermined)})',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : AppColors.textGray),
            ),
            const SizedBox(height: 24),
            if (_internalFormations.isNotEmpty) ...[
              Text(
                'Dans notre plateforme',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark),
              ),
              const SizedBox(height: 12),
              ..._internalFormations.map((f) => _buildInternalCard(f)),
              const SizedBox(height: 24),
            ],
            if (_externalFormations.isNotEmpty) ...[
              Text(
                'Ressources externes',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark),
              ),
              const SizedBox(height: 12),
              ..._externalFormations.map((f) => _buildExternalCard(f)),
            ],
            if (_internalFormations.isEmpty && _externalFormations.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Aucune formation trouvée pour ce niveau.',
                      style: TextStyle(
                          color: isDark ? Colors.white38 : AppColors.textGray)),
                ),
              )
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: content,
      ),
    );
  }

  Widget _buildInternalCard(dynamic f) {
    final title = f['title'] ?? 'Formation';
    final trainer = f['trainerId'] != null
        ? '${f['trainerId']['firstName'] ?? ''} ${f['trainerId']['lastName'] ?? ''}'
        : 'Formatteur';
    final formationId = f['_id'] ?? f['id'];

    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
        border:
            Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppColors.textDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < (f['rating'] ?? 0).floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${(f['reviewCount'] ?? 0)})',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.white54 : AppColors.textGray),
                        ),
                        const SizedBox(width: 8),
                        Text('· Par $trainer',
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textGray)),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  if (formationId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CandidateFormationDetailsPage(
                          formation: f,
                          aiReason: f['ai_reason'],
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Voir', style: TextStyle(fontSize: 12)),
              )
            ],
          ),
          if (f['ai_reason'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.orange.withOpacity(0.1)
                    : AppColors.navy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isDark
                        ? AppColors.orange.withOpacity(0.2)
                        : AppColors.navy.withOpacity(0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome,
                      color: isDark ? AppColors.orange : AppColors.navy,
                      size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f['ai_reason'],
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : AppColors.textDark,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildExternalCard(dynamic f) {
    final title = f['title'] ?? 'Formation Externe';
    final platform = f['platform'] ?? 'Web';
    final url = f['url'] ?? '';
    final isDark = ReactiveMode.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bgAlt,
        border:
            Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.language, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.textDark)),
                const SizedBox(height: 4),
                Text(platform,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : AppColors.textGray)),
              ],
            ),
          ),
          if (url.isNotEmpty)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : AppColors.navy,
                side: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : AppColors.navy),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => _launchUrl(url),
              child: const Text('Visiter', style: TextStyle(fontSize: 12)),
            )
        ],
      ),
    );
  }
}
