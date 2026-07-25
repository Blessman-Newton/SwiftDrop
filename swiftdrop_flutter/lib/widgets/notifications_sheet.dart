import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class NotificationsSheet extends ConsumerStatefulWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationsSheet(),
    ).then((_) {
      // Invalidate the provider so that count refreshes
      ref.invalidate(notificationsProvider);
    });
  }

  @override
  ConsumerState<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<NotificationsSheet> {
  final _service = NotificationService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Notifications',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      await _service.markAllRead();
                      setState(() {});
                    },
                    child: Text(
                      'Mark all as read',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // List
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _service.listNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Text(
                          'Failed to load notifications',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary(isDark).withOpacity(0.6),
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    final List notifications = data['notifications'] ?? [];
                    if (notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 48, color: isDark ? Colors.white38 : Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No notifications found',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white60 : Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index] as Map<String, dynamic>;
                        final isRead = notif['is_read'] ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isRead
                                ? (isDark ? Colors.white.withOpacity(0.02) : Colors.white)
                                : (isDark ? AppColors.primary.withOpacity(0.08) : const Color(0xFFF0FDF4)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? (isDark ? Colors.white10 : Colors.grey[200]!)
                                  : AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              notif['title'] ?? 'Notification',
                              style: GoogleFonts.inter(
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.textPrimary(isDark),
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                notif['body'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                            trailing: !isRead
                                ? IconButton(
                                    icon: const Icon(Icons.mark_email_read_outlined,
                                        color: AppColors.primary, size: 20),
                                    onPressed: () async {
                                      await _service.markRead(notif['id']);
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
