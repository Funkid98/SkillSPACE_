import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pfe/core/network/api_client.dart';
import '../../../../core/app_colors.dart';

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

  void _showNotificationMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (_unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_unreadCount non lu${_unreadCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_notifications.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 48, color: AppColors.textGray),
                            SizedBox(height: 12),
                            Text(
                              'Aucune notification',
                              style: TextStyle(
                                  color: AppColors.textGray, fontSize: 15),
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

                          return InkWell(
                            onTap: () async {
                              if (!isRead) {
                                await _markAsRead(n['_id']);
                                setSheetState(() {});
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? Colors.transparent
                                    : AppColors.orange.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isRead
                                      ? AppColors.border
                                      : AppColors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: AppColors.bg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      widget.isRecruiter
                                          ? Icons.description_rounded
                                          : Icons.business_rounded,
                                      color: AppColors.navy,
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
                                          n['senderName'] ?? 'Utilisateur',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: AppColors.textDark),
                                        ),
                                        if (n['senderEmail'] != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            n['senderEmail'],
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textGray),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          n['message'] ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isRead
                                                ? AppColors.textGray
                                                : AppColors.textDark,
                                            fontWeight: isRead
                                                ? FontWeight.normal
                                                : FontWeight.w600,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isRead)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, top: 4),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
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
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _showNotificationMenu,
          icon: const Icon(Icons.notifications_none_rounded,
              color: AppColors.textDark),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.bg,
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
                border: Border.all(color: Colors.white, width: 1.5),
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
