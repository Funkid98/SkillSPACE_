import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../cubit/formations_cubit.dart';

class CandidateFormationsPage extends StatelessWidget {
  const CandidateFormationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.hPad(context);
    final isDark = ReactiveMode.isDarkMode(context);

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () => context.read<FormationsCubit>().fetchFormations(),
          color: AppColors.orange,
          child: BlocBuilder<FormationsCubit, FormationsState>(
            builder: (context, state) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Formations',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gérez vos formations et suivez votre apprentissage.',
                      style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white60 : AppColors.textGray),
                    ),
                    const SizedBox(height: 32),
                    if (state is FormationsLoading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.orange))
                    else if (state is FormationsError)
                      Center(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else if (state is FormationsLoaded) ...[
                      if (state.formations.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 48),
                              Icon(Icons.school_outlined,
                                  size: 64,
                                  color: AppColors.textGray
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              const Text(
                                  'Vous n\'êtes inscrit à aucune formation.',
                                  style: TextStyle(
                                      color: AppColors.textGray, fontSize: 16)),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.formations.length,
                          itemBuilder: (context, index) {
                            final f = state.formations[index];
                            final title = f['title'] ?? 'Formation';
                            final trainer = f['trainerId'] != null
                                ? '${f['trainerId']['firstName'] ?? ''} ${f['trainerId']['lastName'] ?? ''}'
                                : 'Formatteur';
                            final aiReason = f['aiReason'] ?? '';

                            final status = f['status'] ?? 'ENROLLED';
                            final isCompleted = status == 'COMPLETED';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.1 : 0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : AppColors.navy
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                            isCompleted
                                                ? Icons.check_circle_outline
                                                : Icons.menu_book,
                                            color: isCompleted
                                                ? Colors.green
                                                : (isDark
                                                    ? Colors.white70
                                                    : AppColors.navy),
                                            size: 32),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(title,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: isDark
                                                        ? Colors.white
                                                        : AppColors.textDark)),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text('Par $trainer',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: isDark
                                                            ? Colors.white60
                                                            : AppColors
                                                                .textGray)),
                                                if (f['reviewCount'] != null &&
                                                    f['reviewCount'] > 0) ...[
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    height: 4,
                                                    width: 4,
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? Colors.white24
                                                          : Colors.black12,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Icon(Icons.star,
                                                      color: Colors.amber,
                                                      size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${(f['globalRating'] ?? 0.0).toStringAsFixed(1)} (${f['reviewCount']} avis)',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.white54
                                                          : Colors.grey[600],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: (isCompleted
                                                  ? Colors.green
                                                  : Colors.blue)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                            isCompleted
                                                ? 'Terminée'
                                                : 'En cours',
                                            style: TextStyle(
                                                color: isCompleted
                                                    ? Colors.green
                                                    : Colors.blue,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                  if (aiReason.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.orange
                                                .withValues(alpha: 0.1)
                                            : AppColors.orange
                                                .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: isDark
                                                ? AppColors.orange
                                                    .withValues(alpha: 0.3)
                                                : AppColors.orange
                                                    .withValues(alpha: 0.1)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.auto_awesome,
                                              color: AppColors.orange,
                                              size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Pourquoi cette formation ?',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.orange,
                                                      fontSize: 14),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  aiReason,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: isDark
                                                          ? Colors.white70
                                                          : AppColors.textDark,
                                                      height: 1.5),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (isCompleted) ...[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : AppColors.bg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.black
                                                    .withOpacity(0.05)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Votre note :',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14)),
                                          _CustomRatingBar(
                                            rating:
                                                (f['rating'] ?? 0).toDouble(),
                                            onRatingUpdate: (rating) {
                                              _submitRating(
                                                  context, f, rating.toInt());
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    // ── Session Info Block ─────────────────────
                                    _buildSessionInfoBlock(context, f, isDark),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _showLeaveDialog(context, f),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                              color: Colors.red),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        child: const Text('Se désinscrire',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                    ] else
                      const SizedBox.shrink(),
                  ],
                ),
              );
            },
          ),
        ));
  }

  void _submitRating(
      BuildContext context, dynamic formation, int rating) async {
    final success = await context.read<FormationsCubit>().submitReview(
        formation['_id'] ?? formation['id'].toString(),
        rating,
        formation['review'] ?? '');
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note mise à jour !')),
      );
    }
  }

  void _showLeaveDialog(BuildContext context, dynamic formation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se désinscrire ?'),
        content: Text(
            'Voulez-vous vraiment vous désinscrire de la formation "${formation['title']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<FormationsCubit>().leaveFormation(
                  formation['_id'] ?? formation['id'].toString());
              Navigator.pop(dialogContext);
            },
            child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoBlock(BuildContext context, dynamic f, bool isDark) {
    final rawDate = f['date'];
    final time = f['time'] ?? '';
    final duration = f['duration'] ?? '';
    final meetLink = f['meetLink'] ?? '';

    String formattedDate = '';
    if (rawDate != null) {
      try {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        formattedDate =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        formattedDate = rawDate.toString();
      }
    }

    // Only show this block if there's at least one piece of info
    final hasInfo = formattedDate.isNotEmpty ||
        time.isNotEmpty ||
        duration.isNotEmpty ||
        meetLink.isNotEmpty;
    if (!hasInfo) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.blueAccent.withOpacity(0.08)
                : Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.blueAccent.withOpacity(0.25)
                  : Colors.blue.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_note_rounded,
                      size: 16,
                      color: isDark ? Colors.blueAccent : Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Informations de la session',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.blueAccent : Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (formattedDate.isNotEmpty || time.isNotEmpty)
                _buildSessionRow(
                  Icons.calendar_today_rounded,
                  formattedDate.isNotEmpty && time.isNotEmpty
                      ? '$formattedDate à $time'
                      : formattedDate.isNotEmpty
                          ? formattedDate
                          : time,
                  isDark,
                ),
              if (duration.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildSessionRow(Icons.timer_outlined, duration, isDark),
              ],
              if (meetLink.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(meetLink),
                    icon: const Icon(Icons.videocam_rounded, size: 16),
                    label: const Text(
                      'Rejoindre la séance',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.blueAccent : Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon,
            size: 14, color: isDark ? Colors.white54 : AppColors.textGray),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _CustomRatingBar extends StatelessWidget {
  final double rating;
  final Function(double) onRatingUpdate;

  const _CustomRatingBar({
    required this.rating,
    required this.onRatingUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isSelected = index < rating;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              print('Rating updated: ${index + 1}');
              onRatingUpdate(index + 1.0);
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              child: Icon(
                Icons.star,
                color: isSelected ? Colors.amber : Colors.grey[300],
                size: 28,
              ),
            ),
          ),
        );
      }),
    );
  }
}
