import 'package:supabase_flutter/supabase_flutter.dart';

enum ChatMessageType {
  text,
  image,
  location,
  link,
  system
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
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatReaction> reactions;
  final List<String> deletedFor;

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
    required this.createdAt,
    required this.updatedAt,
    this.reactions = const [],
    this.deletedFor = const [],
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
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
      reactions: reactions,
      deletedFor: json['deleted_for'] != null ? List<String>.from(json['deleted_for']) : [],
    );
  }

  static ChatMessageType _parseType(String? type) {
    switch (type) {
      case 'image': return ChatMessageType.image;
      case 'location': return ChatMessageType.location;
      case 'link': return ChatMessageType.link;
      case 'system': return ChatMessageType.system;
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
