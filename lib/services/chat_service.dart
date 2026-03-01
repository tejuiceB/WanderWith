import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for chat-level operations: read receipts, message status, etc.
class ChatService {
  ChatService._();
  static final ChatService _instance = ChatService._();
  static ChatService get instance => _instance;

  final _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Mark messages as read up to the latest message in a trip chat.
  /// Uses upsert so it creates or updates the receipt row.
  Future<void> markAsRead(String tripId, String messageId) async {
    final uid = _currentUserId;
    if (uid == null) return;

    try {
      await _supabase.from('message_read_receipts').upsert(
        {
          'trip_id': tripId,
          'user_id': uid,
          'last_read_message_id': messageId,
          'last_read_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'trip_id,user_id',
      );
    } catch (e) {
      // Silently fail — read receipts are non-critical
      print('ChatService.markAsRead error: $e');
    }
  }

  /// Stream of read receipts for a trip.
  /// Returns list of {user_id, last_read_message_id, last_read_at} maps.
  Stream<List<Map<String, dynamic>>> readReceiptsStream(String tripId) {
    return _supabase
        .from('message_read_receipts')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId);
  }

  /// Given a message and the read receipts list, determine the display status.
  /// - 'read' if all OTHER members have read past this message
  /// - 'delivered' if at least one other member has read past this message
  /// - 'sent' otherwise
  static String computeMessageStatus({
    required String messageId,
    required DateTime messageCreatedAt,
    required String senderId,
    required List<String> memberIds,
    required List<Map<String, dynamic>> readReceipts,
  }) {
    // Only compute for sender's own messages
    final otherMembers = memberIds.where((id) => id != senderId).toList();
    if (otherMembers.isEmpty) return 'sent';

    int readCount = 0;

    for (final memberId in otherMembers) {
      final receipt = readReceipts.firstWhere(
        (r) => r['user_id'] == memberId,
        orElse: () => {},
      );

      if (receipt.isNotEmpty && receipt['last_read_at'] != null) {
        final lastReadAt = DateTime.parse(receipt['last_read_at']);
        if (!lastReadAt.isBefore(messageCreatedAt)) {
          readCount++;
        }
      }
    }

    if (readCount >= otherMembers.length) return 'read';
    if (readCount > 0) return 'delivered';
    return 'sent';
  }
}
