import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pfe/core/network/api_client.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/api_constants.dart';
import 'scheduling_dialog.dart';

class NotificationBell extends StatefulWidget {
  final bool isRecruiter;

  const NotificationBell({super.key, required this.isRecruiter});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final ApiClient _apiClient = ApiClient();
  Timer? _pollingTimer;
  int _unreadCount = 0;
  List<dynamic> _notifications = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _fetchNotifications();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    if (_loading) return;
    _loading = true;
    try {
      final endpoint = widget.isRecruiter
          ? '/recruiter/notifications'
          : '/candidat/notifications';
      final response = await _apiClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _notifications = data;
            _unreadCount = data.where((n) => n['read'] == false).length;
          });
        }
      }
    } catch (_) {}
    _loading = false;
  }

  Future<void> _handleDecision(String id, String decision,
      {String? date, String? time, String? link, String? reason}) async {
    try {
      await _apiClient.post('/recruiter/notifications/decision', {
        'notificationId': id,
        'decision': decision,
        'interviewDate': date,
        'interviewTime': time,
        'meetingLink': link,
        'rejectionReason': reason,
      });
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _markAsRead(String id) async {
    try {
      final endpoint = widget.isRecruiter
          ? '/recruiter/notifications/$id/read'
          : '/candidat/notifications/$id/read';
      await _apiClient.put(endpoint, {});
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final endpoint = widget.isRecruiter
          ? '/recruiter/notifications/$id'
          : '/candidat/notifications/$id';
      await _apiClient.delete(endpoint);
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _clearAllNotifications() async {
    try {
      final endpoint = widget.isRecruiter
          ? '/recruiter/notifications/clear/all'
          : '/candidat/notifications/clear/all';
      await _apiClient.delete(endpoint);
      _fetchNotifications();
    } catch (_) {}
  }

  void _showMeetLinkDialog(String link, bool isDarkGlobal) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = ReactiveMode.isDarkMode(ctx);
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.video_call_rounded,
                  color: isDark ? AppColors.orange : AppColors.navy),
              const SizedBox(width: 12),
              Text('Lien de l\'entretien',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Utilisez ce lien pour rejoindre l\'appel à l\'heure prévue :',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : AppColors.textGray)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border),
                ),
                child: SelectableText(
                  link,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: isDark ? AppColors.orange : AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lien copié'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copier le lien'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Candidate Profile & CV ────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _fetchCandidateProfile(String candidateId) async {
    try {
      final response = await _apiClient.get('/candidat/internal/$candidateId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  void _showCandidateProfileModal(String candidateId, String candidateName) {
    final isDark = ReactiveMode.isDarkMode(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            bool isLoadingProfile = true;
            Map<String, dynamic>? profile;

            // Load profile when modal opens
            Future.microtask(() async {
              final data = await _fetchCandidateProfile(candidateId);
              if (ctx2.mounted) {
                setModalState(() {
                  profile = data;
                  isLoadingProfile = false;
                });
              }
            });

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.92,
              minChildSize: 0.4,
              builder: (_, scrollCtrl) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.navy, AppColors.orange],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  candidateName.isNotEmpty
                                      ? candidateName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    candidateName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Profil du candidat',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx2),
                              icon: Icon(Icons.close_rounded,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.textGray),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Body
                      Expanded(
                        child: isLoadingProfile
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.orange))
                            : profile == null
                                ? Center(
                                    child: Text(
                                      'Impossible de charger le profil.',
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : AppColors.textGray),
                                    ),
                                  )
                                : ListView(
                                    controller: scrollCtrl,
                                    padding: const EdgeInsets.all(24),
                                    children: [
                                      // Job title & location
                                      if ((profile!['jobtitle'] ?? '').toString().isNotEmpty)
                                        _profileInfoRow(
                                          Icons.work_rounded,
                                          profile!['jobtitle'].toString(),
                                          isDark,
                                        ),
                                      if ((profile!['localisation'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        _profileInfoRow(
                                          Icons.location_on_rounded,
                                          profile!['localisation'].toString(),
                                          isDark,
                                        ),
                                      ],
                                      if ((profile!['telephone'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        _profileInfoRow(
                                          Icons.phone_rounded,
                                          profile!['telephone'].toString(),
                                          isDark,
                                        ),
                                      ],
                                      if ((profile!['senderEmail'] ?? profile!['email'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        _profileInfoRow(
                                          Icons.email_rounded,
                                          (profile!['senderEmail'] ?? profile!['email'] ?? '').toString(),
                                          isDark,
                                        ),
                                      ],
                                      // Bio
                                      if ((profile!['bio'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 20),
                                        Text(
                                          'À propos',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.05)
                                                : AppColors.bg,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: isDark
                                                    ? AppColors.borderDark
                                                    : AppColors.border),
                                          ),
                                          child: Text(
                                            profile!['bio'].toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.6,
                                              color: isDark
                                                  ? Colors.white70
                                                  : AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                      // Skills
                                      if ((profile!['skills'] as List?)?.isNotEmpty == true) ...[
                                        const SizedBox(height: 20),
                                        Text(
                                          'Compétences',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            for (final s in (profile!['skills'] as List))
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.orange
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                      color: AppColors.orange
                                                          .withValues(alpha: 0.3)),
                                                ),
                                                child: Text(
                                                  s is Map
                                                      ? (s['name'] ?? '').toString()
                                                      : s.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.orange,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                      // CV button
                                      const SizedBox(height: 28),
                                      if ((profile!['cv_path'] ?? '').toString().isNotEmpty)
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              final cvUrl =
                                                  '${ApiConstants.baseUrl}/candidat/internal/$candidateId/cv-file';
                                              final uri = Uri.parse(cvUrl);
                                              try {
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri,
                                                      mode: LaunchMode
                                                          .externalApplication);
                                                } else {
                                                  if (ctx2.mounted) {
                                                    ScaffoldMessenger.of(ctx2)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Impossible d\'ouvrir le CV.'),
                                                        behavior: SnackBarBehavior
                                                            .floating,
                                                      ),
                                                    );
                                                  }
                                                }
                                              } catch (_) {
                                                if (ctx2.mounted) {
                                                  ScaffoldMessenger.of(ctx2)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Erreur lors de l\'ouverture du CV.'),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            icon: const Icon(
                                                Icons.picture_as_pdf_rounded,
                                                size: 20),
                                            label:
                                                const Text('Ouvrir le CV (PDF)'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.navy,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14)),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.05)
                                                : AppColors.bg,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: isDark
                                                    ? AppColors.borderDark
                                                    : AppColors.border),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.info_outline_rounded,
                                                  size: 18,
                                                  color: isDark
                                                      ? Colors.white38
                                                      : AppColors.textGray),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Aucun CV téléchargé par le candidat',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.white38
                                                      : AppColors.textGray,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _profileInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.navy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  void _showAcceptDialog(String id, String candidateName, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => SchedulingDialog(
        candidateName: candidateName,
        isDark: isDark,
        onConfirm: (date, time, link) {
          _handleDecision(id, 'ACCEPT', date: date, time: time, link: link);
        },
      ),
    );
  }

  void _showRejectDialog(String id, bool isDarkGlobal) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = ReactiveMode.isDarkMode(ctx);
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Refuser la candidature',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : AppColors.textDark)),
            ],
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : AppColors.textDark),
            decoration: InputDecoration(
              labelText: 'Motif du refus',
              labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textGray),
              hintText: 'Expliquez brièvement pourquoi...',
              hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : AppColors.textGray),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler',
                    style: TextStyle(color: AppColors.textGray))),
            ElevatedButton(
              onPressed: () {
                _handleDecision(id, 'REJECT', reason: reasonController.text);
                Navigator.pop(ctx);
                Navigator.pop(context); // Close notifications menu
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Refuser'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationMenu() {
    final isDarkGlobal = ReactiveMode.isDarkMode(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = isDarkGlobal;
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.6,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          if (_unreadCount > 0) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$_unreadCount',
                                style: const TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_notifications.isNotEmpty)
                        TextButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog(
                                  backgroundColor: isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white,
                                  title: Text('Tout effacer ?',
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.textDark)),
                                  content: Text(
                                      'Voulez-vous vraiment supprimer toutes vos notifications ?',
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : AppColors.textGray)),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Annuler')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Tout effacer',
                                            style: TextStyle(
                                                color: AppColors.error))),
                                  ],
                                );
                              },
                            );
                            if (confirm == true) {
                              await _clearAllNotifications();
                              setSheetState(() {});
                            }
                          },
                          icon: const Icon(Icons.clear_all_rounded,
                              size: 18, color: AppColors.error),
                          label: const Text('Tout effacer',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_notifications.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 48,
                                color: isDark
                                    ? Colors.white30
                                    : AppColors.textGray),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune notification',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : AppColors.textGray,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          final isRead = n['read'] ?? false;
                          final type = n['type'] ?? '';
                          final isDecisionMade = n['decisionMade'] ?? false;

                          return InkWell(
                            onTap: () async {
                              if (!isRead) {
                                await _markAsRead(n['_id']);
                                setSheetState(() {});
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? (isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.white.withValues(alpha: 0.5))
                                    : (isDark
                                        ? AppColors.surfaceDark
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isRead
                                      ? (isDark
                                          ? AppColors.borderDark
                                          : AppColors.border)
                                      : AppColors.orange.withValues(alpha: 0.3),
                                  width: isRead ? 1 : 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: type == 'APPLICATION'
                                              ? AppColors.navy
                                                  .withValues(alpha: 0.1)
                                              : type == 'INTERVIEW_SCHEDULED'
                                                  ? AppColors.success
                                                      .withValues(alpha: 0.1)
                                                  : AppColors.bg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          type == 'APPLICATION'
                                              ? Icons.description_rounded
                                              : type == 'INTERVIEW_SCHEDULED'
                                                  ? Icons
                                                      .event_available_rounded
                                                  : type == 'APPLICATION_REJECTED' ||
                                                          type == 'REJECTION'
                                                      ? Icons.cancel_outlined
                                                      : Icons.notifications,
                                          color: type == 'APPLICATION'
                                              ? AppColors.navy
                                              : type == 'INTERVIEW_SCHEDULED'
                                                  ? AppColors.success
                                                  : type == 'APPLICATION_REJECTED' ||
                                                          type == 'REJECTION'
                                                      ? AppColors.error
                                                      : AppColors.textGray,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n['senderName'] ?? 'Système',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                  color: isDark
                                                      ? Colors.white
                                                      : AppColors.textDark),
                                            ),
                                            if (n['senderEmail'] != null)
                                              Text(
                                                n['senderEmail'],
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? Colors.white30
                                                        : AppColors.textGray),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                              color: AppColors.orange,
                                              shape: BoxShape.circle),
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () async {
                                          await _deleteNotification(n['_id']);
                                          setSheetState(() {});
                                        },
                                        icon: const Icon(Icons.close_rounded,
                                            size: 16,
                                            color: AppColors.textGray),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    n['message'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isRead
                                          ? (isDark
                                              ? Colors.white30
                                              : AppColors.textGray)
                                          : (isDark
                                              ? Colors.white
                                              : AppColors.textDark),
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                  if ((type == 'APPLICATION_REJECTED' ||
                                          type == 'REJECTION') &&
                                      n['rejectionReason'] != null &&
                                      n['rejectionReason']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.error.withOpacity(0.1)
                                            : AppColors.error.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.error
                                                .withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.format_quote_rounded,
                                                  size: 16,
                                                  color: AppColors.error),
                                              const SizedBox(width: 8),
                                              const Text('Message du recruteur',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.error)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            n['rejectionReason'],
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.white70
                                                    : AppColors.textDark,
                                                fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (type == 'INTERVIEW_SCHEDULED' &&
                                      n['meetingLink'] != null &&
                                      n['meetingLink']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          _showMeetLinkDialog(
                                              n['meetingLink'], isDark);
                                        },
                                        icon: const Icon(Icons.link_rounded,
                                            size: 18),
                                        label: const Text(
                                            'Voir le lien de l\'entretien'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.navy,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (type == 'APPLICATION' &&
                                      widget.isRecruiter) ...[
                                    const SizedBox(height: 16),
                                    // ── Voir le CV button ───────────────
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _showCandidateProfileModal(
                                          n['senderId'] ?? '',
                                          n['senderName'] ?? 'Candidat',
                                        ),
                                        icon: const Icon(
                                            Icons.description_rounded,
                                            size: 16),
                                        label: const Text('Voir le CV'),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: AppColors.navy, width: 1.5),
                                          foregroundColor: AppColors.navy,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                        ),
                                      ),
                                    ),
                                    if (!isDecisionMade) ...[
                                      const SizedBox(height: 10),
                                      // ── Accept / Reject row ─────────────
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  _showRejectDialog(
                                                      n['_id'], isDark),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: AppColors.error),
                                                foregroundColor: AppColors.error,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                              ),
                                              child: const Text('Refuser'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _showAcceptDialog(
                                                n['_id'],
                                                n['senderName'] ?? 'Candidat',
                                                isDark,
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.success,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                              ),
                                              child: const Text('Accepter'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _showNotificationMenu,
          icon: Icon(Icons.notifications_none_rounded,
              color: isDark ? Colors.white : AppColors.textDark),
          style: IconButton.styleFrom(
            backgroundColor:
                isDark ? Colors.white.withOpacity(0.05) : AppColors.bg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(8),
          ),
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
