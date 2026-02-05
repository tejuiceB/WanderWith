import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await NotificationService().markAllAsRead();
            },
            tooltip: "Mark all as read",
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<List<AppNotification>>(
          stream: NotificationService().getNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) => ListTile(
                    leading: const CircleAvatar(),
                    title: Container(height: 10, width: 100, color: Colors.grey),
                    subtitle: Container(height: 10, width: 200, color: Colors.grey),
                  ),
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text("No notifications yet", style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey))
                  ],
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification.isRead;

                return Container(
                  color: isRead ? null : Colors.blue.withOpacity(0.05),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getColorForType(notification.type).withOpacity(0.2),
                      child: Icon(_getIconForType(notification.type), color: _getColorForType(notification.type)),
                    ),
                    title: Text(
                      notification.title, 
                      style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.body),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(notification.createdAt),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        )
                      ],
                    ),
                    onTap: () async {
                      if (!isRead) {
                        await NotificationService().markAsRead(notification.id);
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat('MMM d').format(time);
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.message: return Icons.chat;
      case NotificationType.joinRequest: return Icons.person_add;
      case NotificationType.joinResponse: return Icons.verified_user;
      case NotificationType.dateChange: return Icons.calendar_month;
      case NotificationType.budgetChange: return Icons.attach_money;
      case NotificationType.tripUpdate: return Icons.info;
      case NotificationType.pollCreated: 
      case NotificationType.pollAdded: return Icons.poll;
      default: return Icons.notifications;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.message: return Colors.blue;
      case NotificationType.joinRequest: return Colors.orange;
      case NotificationType.joinResponse: return Colors.green;
      case NotificationType.dateChange: return Colors.purple;
      case NotificationType.budgetChange: return Colors.teal;
      case NotificationType.tripUpdate: return Colors.cyan;
      case NotificationType.pollCreated:
      case NotificationType.pollAdded: return Colors.indigo;
      default: return Colors.grey;
    }
  }
}
