/// Model for a scheduled notification that will be sent at an optimal time.
///
/// Stored in the `scheduled_notifications` table. The smart-notifications
/// Edge Function picks up pending rows and delivers them.
class ScheduledNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;       // e.g. 'engagement', 'marketing', 'festival', 'lifecycle'
  final String? subtype;   // e.g. 'trip_starting_3d', 'weather_rain'
  final String? tripId;
  final String? deepLink;
  final String? imageUrl;
  final String language;
  final DateTime scheduledFor;
  final bool sent;
  final DateTime? sentAt;
  final DateTime createdAt;

  ScheduledNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.subtype,
    this.tripId,
    this.deepLink,
    this.imageUrl,
    this.language = 'en',
    required this.scheduledFor,
    this.sent = false,
    this.sentAt,
    required this.createdAt,
  });

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      subtype: json['subtype'] as String?,
      tripId: json['trip_id'] as String?,
      deepLink: json['deep_link'] as String?,
      imageUrl: json['image_url'] as String?,
      language: json['language'] as String? ?? 'en',
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      sent: json['sent'] as bool? ?? false,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'subtype': subtype,
      'trip_id': tripId,
      'deep_link': deepLink,
      'image_url': imageUrl,
      'language': language,
      'scheduled_for': scheduledFor.toIso8601String(),
    };
  }
}
