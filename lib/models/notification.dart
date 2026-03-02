enum NotificationType {
  dateChange,
  budgetChange,
  pollAdded,
  pollCreated, // Alias for pollAdded if needed, or separate
  message,
  chatMention,   // @mentioned in chat
  chatReply,     // Someone replied to your message
  chatReaction,  // Someone reacted to your message
  feedbackRequest,
  system,
  joinRequest,
  joinResponse,
  tripUpdate,
  like,
  comment,
  followRequest,
  followAccepted,
  adminPromoted,     // Promoted to trip admin
  removedFromTrip,   // Kicked from a trip
  tripReminder,      // Smart lifecycle reminders (packing, departure, checklist)
  weatherAlert,      // Weather-triggered alerts
  festivalAlert,     // Festival/seasonal travel suggestions
  travelInspiration, // AI-generated engagement nudges
  memoryAnniversary, // Trip anniversary nostalgia
}

class AppNotification {
  final String id;
  final String userId;
  final String? tripId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.userId,
    this.tripId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      tripId: json['trip_id'],
      title: json['title'],
      body: json['body'],
      type: _parseType(json['type']),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      metadata: json['metadata'],
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'date_change': return NotificationType.dateChange;
      case 'budget_change': return NotificationType.budgetChange;
      case 'poll_added': return NotificationType.pollAdded;
      case 'poll_created': return NotificationType.pollCreated;
      case 'message': return NotificationType.message;
      case 'chat_mention': return NotificationType.chatMention;
      case 'chat_reply': return NotificationType.chatReply;
      case 'chat_reaction': return NotificationType.chatReaction;
      case 'feedback_request': return NotificationType.feedbackRequest;
      case 'join_request': return NotificationType.joinRequest;
      case 'join_response': return NotificationType.joinResponse;
      case 'trip_update': return NotificationType.tripUpdate;
      case 'like': return NotificationType.like;
      case 'comment': return NotificationType.comment;
      case 'follow_request': return NotificationType.followRequest;
      case 'follow_accepted': return NotificationType.followAccepted;
      case 'admin_promoted': return NotificationType.adminPromoted;
      case 'removed_from_trip': return NotificationType.removedFromTrip;
      case 'trip_reminder': return NotificationType.tripReminder;
      case 'weather_alert': return NotificationType.weatherAlert;
      case 'festival_alert': return NotificationType.festivalAlert;
      case 'travel_inspiration': return NotificationType.travelInspiration;
      case 'memory_anniversary': return NotificationType.memoryAnniversary;
      default: return NotificationType.system;
    }
  }

  static String typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.dateChange: return 'date_change';
      case NotificationType.budgetChange: return 'budget_change';
      case NotificationType.pollAdded: return 'poll_added';
      case NotificationType.pollCreated: return 'poll_created';
      case NotificationType.message: return 'message';
      case NotificationType.chatMention: return 'chat_mention';
      case NotificationType.chatReply: return 'chat_reply';
      case NotificationType.chatReaction: return 'chat_reaction';
      case NotificationType.feedbackRequest: return 'feedback_request';
      case NotificationType.joinRequest: return 'join_request';
      case NotificationType.joinResponse: return 'join_response';
      case NotificationType.tripUpdate: return 'trip_update';
      case NotificationType.like: return 'like';
      case NotificationType.comment: return 'comment';
      case NotificationType.followRequest: return 'follow_request';
      case NotificationType.followAccepted: return 'follow_accepted';
      case NotificationType.adminPromoted: return 'admin_promoted';
      case NotificationType.removedFromTrip: return 'removed_from_trip';
      case NotificationType.tripReminder: return 'trip_reminder';
      case NotificationType.weatherAlert: return 'weather_alert';
      case NotificationType.festivalAlert: return 'festival_alert';
      case NotificationType.travelInspiration: return 'travel_inspiration';
      case NotificationType.memoryAnniversary: return 'memory_anniversary';
      default: return 'system';
    }
  }
}
