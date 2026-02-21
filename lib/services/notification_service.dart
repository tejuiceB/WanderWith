import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../models/trip.dart'; // Ensure models are imported correctly
import 'trip_service.dart'; // For fetching trip on click

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Navigation Callback
  static Function(String type, Map<String, dynamic> data)? _onNotificationClick;

  // Singleton pattern for easier init
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize Local Notifications
  Future<void> init(Function(String type, Map<String, dynamic> data) onNotificationClick) async {
    _onNotificationClick = onNotificationClick;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon'); // Ensure app icon exists
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
         if (response.payload != null) {
            final data = Map<String, dynamic>.from(jsonDecode(response.payload!));
            _onNotificationClick?.call(data['type'] ?? '', data);
         }
      }
    );

    _listenForNewNotifications();
  }

  /// Listen to Realtime inserts and trigger local notification
  void _listenForNewNotifications() {
     final uid = _supabase.auth.currentUser?.id;
     if (uid == null) return;

     _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .listen((List<Map<String, dynamic>> data) {
           // We need to identify *new* notifications. 
           // Since stream returns the whole list or updated list, this simple stream listener 
           // might re-trigger if not careful. 
           // Better approach: Listen to PostgreSQL changes channel (Inserts only)
        });
     
     // Correct Realtime Channel Subscription
     _supabase.channel('public:notifications:uid=$uid')
        .onPostgresChanges(
           event: PostgresChangeEvent.insert,
           schema: 'public',
           table: 'notifications',
           filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, 
              column: 'user_id', 
              value: uid
           ),
           callback: (payload) {
              final newNotif = AppNotification.fromJson(payload.newRecord);
              _showLocalNotification(newNotif);
           }
        )
        .subscribe();
  }

  Future<void> _showLocalNotification(AppNotification notif) async {
     const androidDetails = AndroidNotificationDetails(
        'wanderwith_channel', 
        'WanderWith Notifications',
        channelDescription: 'Trip updates and alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true
     );
     const iosDetails = DarwinNotificationDetails();
     const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

     await _localNotifications.show(
       notif.id.hashCode, 
       notif.title, 
       notif.body, 
       details,
       payload: jsonEncode({
         'type': AppNotification.typeToString(notif.type), 
         'tripId': notif.tripId,
         if (notif.metadata != null) ...notif.metadata!,
       })
     );
  }

  // Stream notifications for current user
  Stream<List<AppNotification>> getNotificationsStream() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => AppNotification.fromJson(json)).toList());
  }

  // Count unread
  Stream<int> getUnreadCountStream() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return Stream.value(0);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .map((data) => data.where((json) => (json['is_read'] as bool) == false).length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid);
  }

  // Send notification to a specific user
  Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    required NotificationType type,
    String? tripId,
    Map<String, dynamic>? metadata,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': toUserId,
      'trip_id': tripId,
      'title': title,
      'body': body,
      'type': AppNotification.typeToString(type),
      'metadata': metadata,
    });
  }

  // Notify all trip members (except sender)
  Future<void> notifyTripMembers({
    required String tripId,
    required String title,
    required String body,
    required NotificationType type,
    required String excludeUserId, // Sender
  }) async {
    try {
      // 1. Fetch trip members
      final resp = await _supabase
          .from('trips')
          .select('member_ids')
          .eq('id', tripId)
          .single();
          
      final memberIds = List<String>.from(resp['member_ids'] ?? []);

      // 2. Filter out sender
      final recipients = memberIds.where((id) => id != excludeUserId).toList();
      if (recipients.isEmpty) return;

      // 3. Batch insert notifications
      final notifications = recipients.map((uid) => {
        'user_id': uid,
        'trip_id': tripId,
        'title': title,
        'body': body,
        'type': AppNotification.typeToString(type),
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase.from('notifications').insert(notifications);
    } catch (e) {
      print("Error sending group notification: $e");
    }
  }

  // Check for trip completion and notify if needed
  Future<void> checkAndNotifyTripFeedback(Trip trip, String uid) async {
      // If trip is done and user hasn't reviewed yet
      if (trip.endDate != null && 
          trip.endDate!.isBefore(DateTime.now()) && 
          !trip.reviews.containsKey(uid)) {
          
          // Check if we already sent a notification for this recently? 
          // For simplicity, we query if there is any 'feedback_request' for this trip for this user
          final existing = await _supabase
              .from('notifications')
              .select()
              .eq('user_id', uid)
              .eq('trip_id', trip.id)
              .eq('type', 'feedback_request')
              .limit(1);
          
          bool alreadyNotified = (existing as List).isNotEmpty;

          if (!alreadyNotified) {
             await sendNotification(
               toUserId: uid,
               tripId: trip.id,
               title: "How was ${trip.location}?",
               body: "The trip has ended. Share your memories and rate the trip!",
               type: NotificationType.feedbackRequest
             );
          }
      }
  }
}
