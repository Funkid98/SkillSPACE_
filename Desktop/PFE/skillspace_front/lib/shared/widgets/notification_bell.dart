import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pfe/core/network/api_client.dart';
import 'package:reactive_theme/reactive_theme.dart';
import '../../../../core/app_colors.dart';
import 'scheduling_dialog.dart';

class NotificationBell extends StatefulWidget {
  final bool isRecruiter;

  const NotificationBell({super.key, required this.isRecruiter});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
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
      final client = ApiClient();
      final endpoint = widget.isRecruiter
          ? '/recruiter/notifications'
          : '/candidat/notifications';
      final response = await client.get(endpoint);

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
      final client = ApiClient();
      await client.post('/recruiter/notifications/decision', {
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
      final client = ApiClient();
      final endpoint = widget.isRecruiter
          ? '/recruiter/notifications/$id/read'
          : '/candidat/notifications/$id/read';
      await client.put(endpoint, {});
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final client = ApiClient();
      final endpoint = widget.isRecruiter
          ? '/recruiter/notifications/$id'
          : '/candidat/notifications/$id';
      await client.delete(endpoint);
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _clearAllNotifications() async {
    try {
      final client = ApiClient();
      final endpoint = widget.isRecruiter
          ? '/recruiter/notifications/clear/all'
          : '/candidat/notifications/clear/all';
      await client.delete(endpoint);
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
              Text('Utilisez ce lien pour rejoindre l\'appel à l\'heure prévue :',
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
                    content: Text('Lien copié dans le presse-papiers'),
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
                                color: isDark ? Colors.white30 : AppColors.textGray),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune notification',
                              style: TextStyle(
                                  color: isDark ? Colors.white60 : AppColors.textGray,
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
                                                  : type ==
                                                              'APPLICATION_REJECTED' ||
                                                          type == 'REJECTION'
                                                      ? Icons.cancel_outlined
                                                      : Icons.notifications,
                                          color: type == 'APPLICATION'
                                              ? AppColors.navy
                                              : type == 'INTERVIEW_SCHEDULED'
                                                  ? AppColors.success
                                                  : type ==
                                                              'APPLICATION_REJECTED' ||
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
                                          _showMeetLinkDialog(n['meetingLink'], isDark);
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
                                      widget.isRecruiter &&
                                      !isDecisionMade) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                _showRejectDialog(n['_id'], isDark),
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
                                            onPressed: () => _showAcceptDialog(
                                                n['_id'],
                                                n['senderName'] ?? 'Candidat',
                                                isDark),
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
