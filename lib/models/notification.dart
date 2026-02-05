enum NotificationType {
  dateChange,
  budgetChange,
  pollAdded,
  pollCreated, // Alias for pollAdded if needed, or separate
  message,
  feedbackRequest,
  system,
  joinRequest,
  joinResponse,
  tripUpdate
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
      case 'feedback_request': return NotificationType.feedbackRequest;
      case 'join_request': return NotificationType.joinRequest;
      case 'join_response': return NotificationType.joinResponse;
      case 'trip_update': return NotificationType.tripUpdate;
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
      case NotificationType.feedbackRequest: return 'feedback_request';
      case NotificationType.joinRequest: return 'join_request';
      case NotificationType.joinResponse: return 'join_response';
      case NotificationType.tripUpdate: return 'trip_update';
      default: return 'system';
    }
  }
}
