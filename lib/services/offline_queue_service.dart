import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/local_db.dart';
import '../local/schemas/cached_message.dart';
import '../local/schemas/pending_action.dart';

/// Offline queue & message cache service for chat.
///
/// - Queues outgoing messages when offline (via [PendingAction]).
/// - Caches received messages per trip (via [CachedMessage]).
/// - Flushes pending queue automatically when connectivity restores.
class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _isOnline = true;
  bool _isFlushing = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Call once (e.g. in main.dart or first chat open)
  void init() {
    _connectivitySub ??= Connectivity().onConnectivityChanged.listen((result) {
      final online = result != ConnectivityResult.none;
      if (online && !_isOnline) {
        _isOnline = true;
        flushQueue(); // Network restored → flush pending messages
      }
      _isOnline = online;
    });
    // Set initial connectivity
    Connectivity().checkConnectivity().then((result) {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  bool get isOnline => _isOnline;

  // ---------------------------------------------------------------------------
  // Message Queue (PendingAction)
  // ---------------------------------------------------------------------------

  /// Enqueue a chat message for sending. Returns the PendingAction id.
  Future<int> queueMessage({
    required String tripId,
    required String senderId,
    required String senderName,
    required String content,
    required String type,
    Map<String, dynamic>? metadata,
    List<String>? mentionedUserIds,
  }) async {
    final isar = LocalDb.instance;
    final action = PendingAction()
      ..actionType = 'send_chat_message'
      ..payloadJson = jsonEncode({
          'trip_id': tripId,
          'sender_id': senderId,
          'sender_name': senderName,
          'content': content,
          'type': type,
          'metadata': metadata ?? {},
          'mentioned_user_ids': mentionedUserIds ?? [],
        })
      ..createdAt = DateTime.now()
      ..retryCount = 0;

    int id = 0;
    await isar.writeTxn(() async {
      id = await isar.pendingActions.put(action);
    });

    // Try sending immediately if online
    if (_isOnline) {
      flushQueue();
    }
    return id;
  }

  /// Get count of pending chat messages
  Future<int> pendingCount() async {
    return LocalDb.instance.pendingActions
        .filter()
        .actionTypeEqualTo('send_chat_message')
        .count();
  }

  /// Flush all pending chat messages in order (oldest first).
  Future<void> flushQueue() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      final isar = LocalDb.instance;
      final pending = await isar.pendingActions
          .filter()
          .actionTypeEqualTo('send_chat_message')
          .sortByCreatedAt()
          .findAll();

      for (final action in pending) {
        try {
          final payload = jsonDecode(action.payloadJson) as Map<String, dynamic>;
          await Supabase.instance.client.from('trip_messages').insert({
            'trip_id': payload['trip_id'],
            'sender_id': payload['sender_id'],
            'sender_name': payload['sender_name'],
            'content': payload['content'],
            'type': payload['type'],
            'metadata': payload['metadata'],
            'mentioned_user_ids': payload['mentioned_user_ids'],
          });
          // Success → remove from queue
          await isar.writeTxn(() async {
            await isar.pendingActions.delete(action.id);
          });
        } catch (e) {
          // Increment retry count, keep in queue
          await isar.writeTxn(() async {
            action.retryCount += 1;
            action.errorMessage = e.toString();
            await isar.pendingActions.put(action);
          });
          // If max retries exceeded, drop it
          if (action.retryCount > 5) {
            await isar.writeTxn(() async {
              await isar.pendingActions.delete(action.id);
            });
          }
          break; // Stop flushing on first failure to preserve order
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Message Cache (CachedMessage)
  // ---------------------------------------------------------------------------

  /// Cache a batch of messages for a trip (e.g. from a stream snapshot).
  /// Keeps only the most recent [limit] messages per trip.
  Future<void> cacheMessages(
    String tripId,
    List<Map<String, dynamic>> messages, {
    int limit = 100,
  }) async {
    final isar = LocalDb.instance;
    final now = DateTime.now();

    await isar.writeTxn(() async {
      for (final m in messages.take(limit)) {
        final cached = CachedMessage()
          ..id = m['id'] as String
          ..tripId = tripId
          ..senderId = (m['sender_id'] ?? '') as String
          ..senderName = (m['sender_name'] ?? '') as String
          ..text = (m['content'] ?? '') as String
          ..messageType = (m['type'] ?? 'text') as String
          ..imageUrl = m['metadata'] != null && m['metadata'] is Map
              ? (m['metadata']['image_url'] ?? m['metadata']['url']) as String?
              : null
          ..createdAt = m['created_at'] != null
              ? DateTime.tryParse(m['created_at'] as String)
              : null
          ..lastSynced = now;

        await isar.cachedMessages.putByIndex('id', cached);
      }
    });

    // Trim old messages beyond the limit
    final count = await isar.cachedMessages
        .filter()
        .tripIdEqualTo(tripId)
        .count();

    if (count > limit) {
      final oldMessages = await isar.cachedMessages
          .filter()
          .tripIdEqualTo(tripId)
          .sortByCreatedAt()
          .limit(count - limit)
          .findAll();

      await isar.writeTxn(() async {
        await isar.cachedMessages
            .deleteAll(oldMessages.map((m) => m.isarId).toList());
      });
    }
  }

  /// Get cached messages for a trip (newest first), up to [limit].
  Future<List<Map<String, dynamic>>> getCachedMessages(
    String tripId, {
    int limit = 100,
  }) async {
    final cached = await LocalDb.instance.cachedMessages
        .filter()
        .tripIdEqualTo(tripId)
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();

    return cached.map((c) => {
          'id': c.id,
          'trip_id': c.tripId,
          'sender_id': c.senderId,
          'sender_name': c.senderName,
          'content': c.text,
          'type': c.messageType,
          'metadata': c.imageUrl != null ? {'image_url': c.imageUrl} : {},
          'created_at': c.createdAt?.toIso8601String(),
          'is_pinned': false,
          'is_edited': false,
          'deleted_for': [],
          'mentioned_user_ids': [],
        }).toList();
  }

  /// Clear cached messages for a specific trip.
  Future<void> clearCache(String tripId) async {
    final isar = LocalDb.instance;
    final ids = await isar.cachedMessages
        .filter()
        .tripIdEqualTo(tripId)
        .isarIdProperty()
        .findAll();

    await isar.writeTxn(() async {
      await isar.cachedMessages.deleteAll(ids);
    });
  }
}
