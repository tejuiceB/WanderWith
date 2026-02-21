import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:timeago/timeago.dart' as timeago; // For better natural time if imported, otherwise I will keep standard format
import '../services/notification_service.dart';
import '../services/trip_service.dart';
import '../models/notification.dart';
import 'post_detail_screen.dart';
import 'trip_dashboard_screen.dart';
import 'profile_screen.dart';
import 'follow_requests_screen.dart';

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

                return InkWell(
                  onTap: () async {
                    // Mark as read immediately
                    if (!isRead) {
                      await NotificationService().markAsRead(notification.id);
                    }
                    
                    if (!context.mounted) return;

                    // Routing Logic
                    final type = notification.type;
                    final metadata = notification.metadata ?? {};
                    final tripId = notification.tripId;
                    
                    if (type == NotificationType.like || type == NotificationType.comment) {
                       final postId = metadata['postId'] as String?;
                       if (postId != null && postId.isNotEmpty) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)));
                       }
                    } else if (type == NotificationType.followRequest) {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowRequestsScreen()));
                    } else if (type == NotificationType.followAccepted) {
                       final senderId = metadata['senderId'] as String?;
                       if (senderId != null && senderId.isNotEmpty) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: senderId)));
                       }
                    } else if (tripId != null && tripId.isNotEmpty) {
                       try {
                          // Optionally show a loading dialog here if trip fetch is slow
                          final trip = await TripService().getTrip(tripId);
                          if (context.mounted) {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: trip)));
                          }
                       } catch (e) {
                          print("Failed to navigate from in-app notification: $e");
                       }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.04),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Unread Dot Indicator
                        Container(
                          margin: const EdgeInsets.only(top: 18, right: 12),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isRead ? Colors.transparent : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Icon Avatar
                        Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            color: _getColorForType(notification.type).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(_getIconForType(notification.type), 
                               color: _getColorForType(notification.type), size: 22),
                          ),
                        ),
                        // Text Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title, 
                                style: GoogleFonts.outfit(
                                   fontSize: 15,
                                   fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                   color: Colors.black87
                                )
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.body,
                                style: GoogleFonts.inter(
                                   fontSize: 13,
                                   color: isRead ? Colors.grey.shade600 : Colors.black87,
                                   height: 1.3
                                )
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatTime(notification.createdAt),
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
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
      case NotificationType.message: return Icons.chat_bubble_outline;
      case NotificationType.joinRequest: return Icons.person_add_alt_1;
      case NotificationType.joinResponse: return Icons.how_to_reg;
      case NotificationType.dateChange: return Icons.calendar_today;
      case NotificationType.budgetChange: return Icons.payments_outlined;
      case NotificationType.tripUpdate: return Icons.info_outline;
      case NotificationType.pollCreated: 
      case NotificationType.pollAdded: return Icons.poll_outlined;
      case NotificationType.like: return Icons.favorite_border;
      case NotificationType.comment: return Icons.mode_comment_outlined;
      case NotificationType.followRequest: return Icons.person_add_outlined;
      case NotificationType.followAccepted: return Icons.check_circle_outline;
      default: return Icons.notifications_none;
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
      case NotificationType.like: return Colors.redAccent;
      case NotificationType.comment: return Colors.blueAccent;
      case NotificationType.followRequest: return Colors.orangeAccent;
      case NotificationType.followAccepted: return Colors.green;
      default: return Colors.grey;
    }
  }
}
