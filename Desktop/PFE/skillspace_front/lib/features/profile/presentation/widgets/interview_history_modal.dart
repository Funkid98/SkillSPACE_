import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:reactive_theme/reactive_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/app_colors.dart';
import '../../../simulation/presentation/pages/simulation_result_page.dart';

class InterviewHistoryModal extends StatefulWidget {
  const InterviewHistoryModal({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Historique des entretiens',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const InterviewHistoryModal();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  @override
  State<InterviewHistoryModal> createState() => _InterviewHistoryModalState();
}

class _InterviewHistoryModalState extends State<InterviewHistoryModal> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) {
        throw Exception("Utilisateur non connecté");
      }
      final user = jsonDecode(userDataStr);
      final candidateId = user['id'] ?? user['_id'];
      print('InterviewHistoryModal: Fetching history for candidateId = $candidateId');

      final response = await http.get(
        Uri.parse('http://localhost:5005/api/interview/history/$candidateId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('InterviewHistoryModal: Received response: success=${data['success']}');
        if (data['success']) {
          if (mounted) {
            setState(() {
              _history = data['history'] ?? [];
              _isLoading = false;
            });
            print('InterviewHistoryModal: Loaded ${_history.length} history items.');
          }
        } else {
          throw Exception("Failed to load history");
        }
      } else {
        throw Exception("Server error");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Une erreur est survenue lors de la récupération de l'historique.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isDark ? Border.all(color: AppColors.borderDark) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, color: AppColors.orange),
                        const SizedBox(width: 12),
                        Text(
                          'Historique des entretiens',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: isDark ? Colors.white54 : AppColors.textGray),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content
              Flexible(
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.orange)),
                      )
                    : _error.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Center(
                                child: Text(_error,
                                    style: const TextStyle(color: Colors.red))),
                          )
                        : _history.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(48.0),
                                child: Center(
                                  child: Text(
                                    "Vous n'avez pas encore passé d'entretien de simulation.",
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : AppColors.textGray),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(24.0),
                                shrinkWrap: true,
                                itemCount: _history.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final item = _history[index];
                                  return _buildHistoryCard(item, isDark);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, bool isDark) {
    final title = item['roleTitle'] ?? 'Développeur';
    final score = item['globalScore'] ?? 0;
    final emotion = item['emotionalState'] ?? 'Neutre';
    final dateStr = item['createdAt'];
    DateTime date = DateTime.now();
    if (dateStr != null) {
      date = DateTime.tryParse(dateStr) ?? DateTime.now();
    }
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bgAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Score: $score/100',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: isDark ? Colors.white54 : AppColors.textGray),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : AppColors.textGray,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.psychology, size: 14, color: isDark ? Colors.white54 : AppColors.textGray),
              const SizedBox(width: 6),
              Text(
                emotion,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the modal
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 400),
                    reverseTransitionDuration: const Duration(milliseconds: 400),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        SimulationResultPage(
                      chatHistory: const [],
                      roleTitle: title,
                      preloadedData: item['analysis'],
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      var curve = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                        reverseCurve: Curves.easeInCubic,
                      );
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.2), // Slide up slightly
                          end: Offset.zero,
                        ).animate(curve),
                        child: FadeTransition(
                          opacity: curve,
                          child: child,
                        ),
                      );
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white10 : AppColors.bg,
                foregroundColor: isDark ? Colors.white : AppColors.navy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Voir l\'analyse',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
