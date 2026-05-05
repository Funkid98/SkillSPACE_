import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class CandidateFormationDetailsPage extends StatefulWidget {
  final dynamic formation;
  final String? aiReason;

  const CandidateFormationDetailsPage({
    super.key,
    required this.formation,
    this.aiReason,
  });

  @override
  State<CandidateFormationDetailsPage> createState() =>
      _CandidateFormationDetailsPageState();
}

class _CandidateFormationDetailsPageState
    extends State<CandidateFormationDetailsPage> {
  bool _isEnrolling = false;

  Future<void> _enrollInFormation() async {
    final formationId = widget.formation['_id'] ?? widget.formation['id'];
    if (formationId == null) return;

    setState(() => _isEnrolling = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/candidat/enroll/$formationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: widget.aiReason != null
            ? '{"aiReason": "${widget.aiReason!.replaceAll('"', '\\"')}"}'
            : '{}',
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Inscription réussie ! Vous pouvez la consulter dans "Formations".')),
          );
          Navigator.of(context).pop(); // Go back after enroll
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Erreur: Vous êtes peut-être déjà inscrit.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Une erreur est survenue lors de l\'inscription.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnrolling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.formation;
    final title = f['title'] ?? 'Formation';
    final description = f['description'] ??
        'Aucune description disponible pour cette formation.';
    final trainer = f['trainerId'] != null
        ? '${f['trainerId']['firstName'] ?? ''} ${f['trainerId']['lastName'] ?? ''}'
        : 'Formatteur';
    final category = f['category'] ?? 'Général';
    final level = f['level'] ?? 'Tous niveaux';
    final duration =
        f['duration'] != null ? '${f['duration']} heures' : 'Non spécifié';
    final hPad = Responsive.hPad(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text('Détails de la formation',
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(category,
                            style: const TextStyle(
                                color: AppColors.orange,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(level,
                            style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person,
                          size: 18, color: AppColors.textGray),
                      const SizedBox(width: 8),
                      Text('Par $trainer',
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 24),
                      const Icon(Icons.timer,
                          size: 18, color: AppColors.textGray),
                      const SizedBox(width: 8),
                      Text(duration,
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textGray,
                          height: 1.6)),
                  if (widget.aiReason != null) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.navy.withOpacity(0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppColors.navy, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pourquoi cette formation ?',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navy,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(widget.aiReason!,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textDark,
                                        height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isEnrolling ? null : _enrollInFormation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isEnrolling
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('S\'inscrire à la formation',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
