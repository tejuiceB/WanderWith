import 'package:supabase_flutter/supabase_flutter.dart';

enum ChatMessageType {
  text,
  image,
  location,
  link,
  system,
  planItem,
  expense,
  poll,
  document,
}

class ChatMessage {
  final String id;
  final String tripId;
  final String? senderId;
  final String? senderName;
  final ChatMessageType type;
  final String content;
  final Map<String, dynamic> metadata;
  final bool isEdited;
  final bool isPinned;
  final String status; // 'sent', 'delivered', 'read'
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatReaction> reactions;
  final List<String> deletedFor;
  final List<String> mentionedUserIds;

  ChatMessage({
    required this.id,
    required this.tripId,
    this.senderId,
    this.senderName,
    required this.type,
    required this.content,
    this.metadata = const {},
    this.isEdited = false,
    this.isPinned = false,
    this.status = 'sent',
    required this.createdAt,
    required this.updatedAt,
    this.reactions = const [],
    this.deletedFor = const [],
    this.mentionedUserIds = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {List<ChatReaction> reactions = const []}) {
    return ChatMessage(
      id: json['id'],
      tripId: json['trip_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      type: _parseType(json['type']),
      content: json['content'] ?? '',
      metadata: json['metadata'] ?? {},
      isEdited: json['is_edited'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      status: json['status'] ?? 'sent',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
      reactions: reactions,
      deletedFor: json['deleted_for'] != null ? List<String>.from(json['deleted_for']) : [],
      mentionedUserIds: json['mentioned_user_ids'] != null ? List<String>.from(json['mentioned_user_ids']) : [],
    );
  }

  static ChatMessageType _parseType(String? type) {
    switch (type) {
      case 'image': return ChatMessageType.image;
      case 'location': return ChatMessageType.location;
      case 'link': return ChatMessageType.link;
      case 'system': return ChatMessageType.system;
      case 'planItem': return ChatMessageType.planItem;
      case 'expense': return ChatMessageType.expense;
      case 'poll': return ChatMessageType.poll;
      case 'document': return ChatMessageType.document;
      default: return ChatMessageType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'sender_id': senderId,
      'sender_name': senderName,
      'type': type.name,
      'content': content,
      'metadata': metadata,
      'is_edited': isEdited,
      'status': status,
      'mentioned_user_ids': mentionedUserIds,
    };
  }
}

class ChatReaction {
  final String id;
  final String messageId;
  final String tripId;
  final String userId;
  final String reaction;
  final DateTime createdAt;

  ChatReaction({
    required this.id,
    required this.messageId,
    required this.tripId,
    required this.userId,
    required this.reaction,
    required this.createdAt,
  });

  factory ChatReaction.fromJson(Map<String, dynamic> json) {
    return ChatReaction(
      id: json['id'],
      messageId: json['message_id'],
      tripId: json['trip_id'] ?? '',
      userId: json['user_id'],
      reaction: json['reaction'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
