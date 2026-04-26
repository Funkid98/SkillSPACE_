import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../cubit/profile_cubit.dart';
import '../../data/models/profile_model.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/app_toast.dart';

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

  Future<void> _generateQuiz() async {
    setState(() => _step = 1);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

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

        int rawScore = (data['score'] ?? 0).toInt();
        int score = 0;

        // Scale the raw score based on the selected difficulty level
        if (_selectedLevel == 'Beginner') {
          score = (rawScore * 0.35).round(); // Max 35
        } else if (_selectedLevel == 'Intermediate') {
          score = 40 + (rawScore * 0.35).round(); // Max 75
        } else {
          score = 80 + (rawScore * 0.20).round(); // Max 100
        }

        // Round score to nearest 5: 10, 15, 20 ...
        score = ((score / 5).round() * 5).clamp(0, 100);

        // Sanitize the level for UI display
        String displayLevel = 'Beginner';
        if (score >= 80)
          displayLevel = 'Advanced';
        else if (score >= 40) displayLevel = 'Intermediate';

        if (mounted) {
          widget.parentContext
              .read<ProfileCubit>()
              .updateSkillPercent(widget.skill.name, score);
          widget.parentContext.read<ProfileCubit>().saveProfile();
        }

        setState(() {
          _determinedLevel = displayLevel;
          _evaluationFeedback = data['feedback'] ?? '';

          if ((_selectedLevel == 'Beginner' ||
                  _selectedLevel == 'Intermediate') &&
              rawScore >= 95) {
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
    Widget content;

    if (_step == 0) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Quel niveau pensez-vous avoir ?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ...['Beginner', 'Intermediate', 'Advanced']
              .map((level) => RadioListTile(
                    title: Text(level),
                    value: level,
                    groupValue: _selectedLevel,
                    activeColor: AppColors.navy,
                    onChanged: (val) {
                      setState(() => _selectedLevel = val.toString());
                    },
                  )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white),
              onPressed: () => _generateQuiz(),
              child: const Text('Commencer le quiz'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Ensure it defaults to beginner and save
              widget.parentContext
                  .read<ProfileCubit>()
                  .updateSkillPercent(widget.skill.name, 33);
              widget.parentContext.read<ProfileCubit>().saveProfile();
              Navigator.of(context).pop();
            },
            child: const Text('Passer plus tard (Sauvegardé comme débutant)',
                style: TextStyle(color: AppColors.textGray, fontSize: 13)),
          ),
        ],
      );
    } else if (_step == 1) {
      content = const Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.orange),
            SizedBox(height: 16),
            Text('Génération du quiz AI...',
                style: TextStyle(color: AppColors.textGray)),
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
              style: const TextStyle(color: AppColors.textGray, fontSize: 13)),
          const SizedBox(height: 8),
          Text(q['question'] ?? 'No question text',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 16),
          ...(q['options'] as List<dynamic>).map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => _answerQuestion(opt.toString()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(opt.toString(),
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
              )),
        ],
      );
    } else if (_step == 3) {
      content = const Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.navy),
            SizedBox(height: 16),
            Text('Évaluation de vos capacités par l\'IA...',
                style: TextStyle(color: AppColors.textGray),
                textAlign: TextAlign.center),
          ],
        ),
      );
    } else if (_step == 4) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          const Text('Analyse Terminée',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Text('Niveau Déterminé: $_determinedLevel',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.navy)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.bgAlt, borderRadius: BorderRadius.circular(8)),
            child: Text(_evaluationFeedback,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              AppToast.showSuccess(context, 'Niveau mis à jour!');
            },
            child: const Text('Fermer et sauvegarder'),
          ),
        ],
      );
    } else {
      final isBeginner = _selectedLevel == 'Beginner';
      final nextLevel = isBeginner ? 'Intermediate' : 'Advanced';
      final currentLevelText = isBeginner ? 'débutant' : 'intermédiaire';
      final nextLevelText = isBeginner ? 'intermédiaire' : 'avancé';

      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 64),
          const SizedBox(height: 16),
          const Text('Excellent !',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Text(
              'Vous avez maîtrisé le test $currentLevelText. Voulez-vous passer le test $nextLevelText pour améliorer votre score ?',
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedLevel = nextLevel;
                  _qna.clear();
                  _currentQuestionIndex = 0;
                  _generateQuiz();
                });
              },
              child: Text('Passer le test $nextLevelText'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppToast.showSuccess(
                  context, 'Niveau $currentLevelText Sauvegardé!');
            },
            child: Text('Garder mon niveau $currentLevelText',
                style:
                    const TextStyle(color: AppColors.textGray, fontSize: 13)),
          ),
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: content,
      ),
    );
  }
}
