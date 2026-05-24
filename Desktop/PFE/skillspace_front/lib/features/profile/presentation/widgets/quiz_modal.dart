import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:reactive_theme/reactive_theme.dart';
import 'package:pfe/core/network/cookie_service.dart';
import '../../cubit/profile_cubit.dart';
import '../../data/models/profile_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import 'recommendations_modal.dart';

class QuizModal extends StatefulWidget {
  final ProfileSkill skill;
  final int skillIndex;
  final BuildContext parentContext;

  const QuizModal({
    super.key,
    required this.skill,
    required this.skillIndex,
    required this.parentContext,
  });

  @override
  State<QuizModal> createState() => _QuizModalState();
}

class _QuizModalState extends State<QuizModal> {
  int _step =
      0; // 0: Select Level, 1: Loading Quiz, 2: Answering, 3: Evaluating, 4: Result
  String _selectedLevel = 'Beginner';
  List<dynamic> _questions = [];
  final List<Map<String, String>> _qna = [];
  int _currentQuestionIndex = 0;
  String _evaluationFeedback = '';
  String _determinedLevel = '';
  List<dynamic> _answersAnalysis = [];
  int _finalScore = 0; // computed score after evaluation
  int _quizRawScore = 0; // raw 0-100 score for the specific quiz level

  Future<void> _generateQuiz() async {
    setState(() => _step = 1);
    try {
      final token = CookieService.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/quiz/generate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'skill': widget.skill.name,
          'level': _selectedLevel,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _questions = data is List ? data : (data['questions'] ?? []);
          _step = 2;
        });
      } else {
        throw Exception('Failed to generate quiz');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, "Erreur de génération du quiz. Réessayez.");
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _evaluateQuiz() async {
    setState(() => _step = 3);
    try {
      final token = CookieService.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/quiz/evaluate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'skill': widget.skill.name,
          'claimedLevel': _selectedLevel,
          'qna': _qna,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Use the strictly calculated score from the backend
        int score = (data['updated_score'] ?? data['score'] ?? 0).toInt();
        int rawScore = (data['score'] ?? 0).toInt();

        // Use the determined_level from backend (Dreyfus enforcement)
        String displayLevel = data['determined_level'] ?? 'Beginner';

        if (mounted) {
          widget.parentContext
              .read<ProfileCubit>()
              .updateSkillPercent(widget.skill.name, score);
          widget.parentContext.read<ProfileCubit>().saveProfile();
        }

        setState(() {
          _finalScore = score;
          _quizRawScore = rawScore;
          _determinedLevel = displayLevel;
          _evaluationFeedback = data['feedback'] ?? '';
          _answersAnalysis = data['answers_analysis'] ?? [];

          // Only suggest next level on a perfect 100/100 score
          if ((_selectedLevel == 'Beginner' ||
                  _selectedLevel == 'Intermediate') &&
              rawScore == 100) {
            _step = 5; // Go to "Suggest Next Level" step
          } else {
            _step = 4; // Final Result
          }
        });
      } else {
        throw Exception('Failed to evaluate quiz');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, "Erreur lors de l'évaluation.");
        Navigator.of(context).pop();
      }
    }
  }

  void _answerQuestion(String answer) {
    _qna.add({
      'question': _questions[_currentQuestionIndex]['question'],
      'answer': answer,
    });

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      _evaluateQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const SizedBox.shrink();

    final isDark = ReactiveMode.isDarkMode(context);
    if (_step == 0) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Évaluation de compétence',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                      color: AppColors.orange)),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
              'Quel niveau pensez-vous avoir pour la compétence ${widget.skill.name} ?',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 8),
          Text(
              'L\'IA va générer un quiz personnalisé pour valider votre niveau.',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : AppColors.textGray)),
          const SizedBox(height: 20),
          ...{
            'Beginner': 'Débutant',
            'Intermediate': 'Intermédiaire',
            'Advanced': 'Avancé'
          }.entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _selectedLevel == entry.key
                      ? AppColors.orange.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedLevel == entry.key
                        ? AppColors.orange
                        : (isDark ? Colors.white10 : Colors.black12),
                  ),
                ),
                child: RadioListTile(
                  title: Text(entry.value,
                      style: TextStyle(
                          fontWeight: _selectedLevel == entry.key
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isDark ? Colors.white : AppColors.textDark)),
                  value: entry.key,
                  groupValue: _selectedLevel,
                  activeColor: AppColors.orange,
                  onChanged: (val) {
                    setState(() => _selectedLevel = val.toString());
                  },
                ),
              )),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white70 : AppColors.textGray,
                    side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Plus tard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _generateQuiz(),
                  child: const Text('Commencer',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_step == 1) {
      content = Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.orange),
            const SizedBox(height: 16),
            Text('Génération du quiz AI...',
                style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.textGray)),
          ],
        ),
      );
    } else if (_step == 2) {
      final q = _questions[_currentQuestionIndex];
      final isLast = _currentQuestionIndex == _questions.length - 1;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Scénario de Résolution de Problème',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          Text('Question ${_currentQuestionIndex + 1}/${_questions.length}',
              style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.textGray,
                  fontSize: 13)),
          const SizedBox(height: 8),
          Text(q['question'] ?? 'No question text',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 16),
          ...(q['options'] as List<dynamic>).map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => _answerQuestion(opt.toString()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color:
                              isDark ? AppColors.borderDark : AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    child: Text(opt.toString(),
                        style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark ? Colors.white70 : AppColors.textDark)),
                  ),
                ),
              )),
        ],
      );
    } else if (_step == 3) {
      content = Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.navy),
            const SizedBox(height: 16),
            Text('Évaluation de vos capacités par l\'IA...',
                style: TextStyle(
                    color: isDark ? Colors.white60 : AppColors.textGray),
                textAlign: TextAlign.center),
          ],
        ),
      );
    } else if (_step == 4) {
      content = SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('Analyse Terminée',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 16),
            Text('Niveau Déterminé: ${_mapLevelToFrench(_determinedLevel)}',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? AppColors.orange : AppColors.navy)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.orange.withOpacity(0.1)
                    : AppColors.navy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Score Brut: $_quizRawScore/100',
                style: TextStyle(
                    color: isDark ? AppColors.orange : AppColors.navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                  color:
                      isDark ? Colors.white.withOpacity(0.05) : AppColors.bgAlt,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_evaluationFeedback,
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppColors.textDark),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            Text('Détails des Réponses',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 12),
            ..._answersAnalysis.map((analysis) {
              final bool isCorrect = analysis['is_correct'] ?? false;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isCorrect
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                  color: isCorrect
                      ? Colors.green.withOpacity(isDark ? 0.1 : 0.05)
                      : Colors.red.withOpacity(isDark ? 0.1 : 0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(analysis['question'] ?? '',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textDark)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCorrect ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCorrect
                                ? '+${_answersAnalysis.indexOf(analysis) < 4 ? 15 : 40} pts'
                                : '0 pts',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(isCorrect ? Icons.check : Icons.close,
                            size: 16,
                            color: isCorrect ? Colors.green : Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                              'Votre réponse: ${analysis['user_answer']}',
                              style: TextStyle(
                                  color: isCorrect ? Colors.green : Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 4),
                      Text('Réponse correcte: ${analysis['correct_answer']}',
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            // ── Action Buttons ──────────────────────────────────────
            Row(
              children: [
                // Save button
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Sauvegarder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : AppColors.navy,
                      side: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : AppColors.navy,
                          width: 1.5),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      AppToast.showSuccess(context, 'Niveau mis à jour !');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // See Formations button
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.school_rounded, size: 18),
                    label: const Text('Voir formations',
                        style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Open recommendations modal with full quiz context
                      showDialog(
                        context: widget.parentContext,
                        builder: (_) => RecommendationsModal(
                          skill: widget.skill.name,
                          score: _finalScore,
                          claimedLevel: _selectedLevel,
                          answersAnalysis: _answersAnalysis,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_step == 5) {
      final nextLevelFr =
          _selectedLevel == 'Beginner' ? 'Intermédiaire' : 'Avancé';
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.orange, size: 64),
          ),
          const SizedBox(height: 24),
          Text('Performance Exceptionnelle !',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 12),
          Text(
            'Vous avez maîtrisé le niveau ${_mapLevelToFrench(_selectedLevel)} avec un score parfait de 100%.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : AppColors.textGray),
          ),
          const SizedBox(height: 32),
          Text('Voulez-vous tenter le niveau $nextLevelFr immédiatement ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _step = 4),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white60 : AppColors.textGray,
                  ),
                  child: const Text('Voir mes résultats'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedLevel = _selectedLevel == 'Beginner'
                          ? 'Intermediate'
                          : 'Advanced';
                      _currentQuestionIndex = 0;
                      _qna.clear();
                      _step = 1;
                    });
                    _generateQuiz();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Passer au niveau suivant',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: content,
      ),
    );
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
}
