import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized service for posting system/context messages to trip chat.
/// 
/// Use this to insert system events (member joined, expense added, etc.)
/// as messages with type='system' so they appear inline in chat.
class ChatEventService {
  ChatEventService._();
  static final ChatEventService instance = ChatEventService._();

  final _supabase = Supabase.instance.client;

  /// Post a system event message into the trip chat.
  /// 
  /// [tripId] — the trip to post into
  /// [content] — human-readable event text (e.g. "Tejas joined the trip 🎉")
  /// [event] — machine-readable event type (e.g. 'member_joined')
  /// [extraMetadata] — optional extra metadata (e.g. {'user_id': '...', 'place_name': '...'})
  Future<void> postSystemMessage({
    required String tripId,
    required String content,
    required String event,
    Map<String, dynamic>? extraMetadata,
  }) async {
    try {
      final metadata = <String, dynamic>{
        'event': event,
        ...?extraMetadata,
      };

      await _supabase.from('trip_messages').insert({
        'trip_id': tripId,
        'sender_id': null,
        'sender_name': 'System',
        'content': content,
        'type': 'system',
        'metadata': metadata,
      });
    } catch (e) {
      // System messages are non-critical — don't let them break the main flow
      print('ChatEventService: Failed to post system message: $e');
    }
  }

  // ── Convenience methods ──────────────────────────────────────────

  Future<void> memberJoined(String tripId, String userName) =>
      postSystemMessage(tripId: tripId, content: '$userName joined the trip 🎉', event: 'member_joined');

  Future<void> memberLeft(String tripId, String userName) =>
      postSystemMessage(tripId: tripId, content: '$userName left the trip', event: 'member_left');

  Future<void> memberRemoved(String tripId, String userName) =>
      postSystemMessage(tripId: tripId, content: '$userName was removed from the trip', event: 'member_removed');

  Future<void> expenseAdded(String tripId, String userName, String title, double amount, String currency) =>
      postSystemMessage(
        tripId: tripId,
        content: '$userName added expense: $currency ${amount.toStringAsFixed(0)} for $title',
        event: 'expense_added',
        extraMetadata: {'title': title, 'amount': amount, 'currency': currency},
      );

  Future<void> placeAdded(String tripId, String userName, String placeName, int dayNumber) =>
      postSystemMessage(
        tripId: tripId,
        content: '$userName added $placeName to Day $dayNumber 📍',
        event: 'place_added',
        extraMetadata: {'place_name': placeName, 'day_number': dayNumber},
      );

  Future<void> tripDatesChanged(String tripId, String dateRange) =>
      postSystemMessage(tripId: tripId, content: 'Trip dates updated: $dateRange 📅', event: 'trip_dates_changed');
}
