import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/local_db.dart';
import '../local/schemas/pending_action.dart';
import 'network_service.dart';

/// Processes queued offline actions when connectivity is restored.
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _supabase = Supabase.instance.client;
  bool _isSyncing = false;

  /// Process all pending actions in order
  Future<void> syncPendingActions() async {
    if (_isSyncing || NetworkService.instance.isOffline) return;
    _isSyncing = true;

    try {
      final pending = await LocalDb.instance.pendingActions
          .where()
          .sortByCreatedAt()
          .findAll();

      debugPrint('SyncService: ${pending.length} pending actions to sync');

      for (final action in pending) {
        try {
          await _executeAction(action);
          // Success — remove from queue
          await LocalDb.instance.writeTxn(() async {
            await LocalDb.instance.pendingActions.delete(action.id);
          });
          debugPrint('SyncService: Synced ${action.actionType}');
        } catch (e) {
          // Increment retry, log error
          action.retryCount++;
          action.errorMessage = e.toString();
          await LocalDb.instance.writeTxn(() async {
            await LocalDb.instance.pendingActions.put(action);
          });
          debugPrint(
              'SyncService: Failed ${action.actionType} (retry ${action.retryCount}): $e');
          if (action.retryCount > 5) {
            debugPrint('SyncService: Giving up on ${action.actionType} after 5 retries');
            // Skip this action and continue with the next
            continue;
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _executeAction(PendingAction action) async {
    final payload = jsonDecode(action.payloadJson) as Map<String, dynamic>;
    switch (action.actionType) {
      case 'add_plan_place':
        await _supabase.from('trip_plan_places').insert(payload);
        break;

      case 'upload_photo':
        final localPath = payload['local_path'] as String?;
        if (localPath == null) break;
        final file = File(localPath);
        if (!file.existsSync()) {
          debugPrint('SyncService: Local file missing, skipping upload');
          break;
        }
        final storagePath =
            'trip_photos/${payload['trip_id']}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage
            .from('trip-photos')
            .upload(storagePath, file);
        final publicUrl = _supabase.storage
            .from('trip-photos')
            .getPublicUrl(storagePath);
        await _supabase.from('trip_photos').insert({
          'trip_id': payload['trip_id'],
          'photo_url': publicUrl,
          'uploader_id': payload['uploader_id'],
          if (payload['caption'] != null) 'caption': payload['caption'],
        });
        break;

      case 'add_expense':
        await _supabase.from('trip_expenses').insert(payload);
        break;

      case 'send_message':
        await _supabase.from('trip_messages').insert(payload);
        break;

      case 'toggle_reaction':
        final messageId = payload['message_id'] as String;
        final userId = payload['user_id'] as String;
        final emoji = payload['emoji'] as String;
        // Check if reaction already exists
        final existing = await _supabase
            .from('message_reactions')
            .select()
            .eq('message_id', messageId)
            .eq('user_id', userId)
            .eq('emoji', emoji)
            .maybeSingle();
        if (existing != null) {
          await _supabase
              .from('message_reactions')
              .delete()
              .eq('id', existing['id']);
        } else {
          await _supabase.from('message_reactions').insert({
            'message_id': messageId,
            'user_id': userId,
            'emoji': emoji,
          });
        }
        break;

      case 'update_checklist':
        await _supabase.from('trip_checklist').upsert(payload);
        break;

      default:
        debugPrint('SyncService: Unknown action type: ${action.actionType}');
    }
  }

  /// Queue an action for later sync
  Future<void> queueAction(
      String actionType, Map<String, dynamic> payload) async {
    await LocalDb.instance.writeTxn(() async {
      await LocalDb.instance.pendingActions.put(PendingAction()
        ..actionType = actionType
        ..payloadJson = jsonEncode(payload)
        ..createdAt = DateTime.now()
        ..retryCount = 0);
    });
    debugPrint('SyncService: Queued $actionType for later sync');
  }

  /// Get count of pending actions
  Future<int> getPendingCount() async {
    return await LocalDb.instance.pendingActions.count();
  }
}
