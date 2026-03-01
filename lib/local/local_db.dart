import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'schemas/cached_trip.dart';
import 'schemas/cached_profile.dart';
import 'schemas/cached_trip_day.dart';
import 'schemas/cached_trip_place.dart';
import 'schemas/cached_gallery_photo.dart';
import 'schemas/cached_message.dart';
import 'schemas/cached_trip_link.dart';
import 'schemas/cached_poll.dart';
import 'schemas/pending_action.dart';

class LocalDb {
  static late Isar instance;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    instance = await Isar.open(
      [
        CachedTripSchema,
        CachedProfileSchema,
        CachedTripDaySchema,
        CachedTripPlaceSchema,
        CachedGalleryPhotoSchema,
        CachedMessageSchema,
        CachedTripLinkSchema,
        CachedPollSchema,
        PendingActionSchema,
      ],
      directory: dir.path,
    );
    _initialized = true;
  }

  /// Clear all cached data (e.g. on logout)
  static Future<void> clearAll() async {
    await instance.writeTxn(() async {
      await instance.clear();
    });
  }

  /// Prune old cached data older than [days] days to keep DB lean
  static Future<int> pruneOldCache({int days = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    int deleted = 0;

    await instance.writeTxn(() async {
      // Prune old messages
      final oldMessages = await instance.cachedMessages
          .filter()
          .lastSyncedLessThan(cutoff)
          .findAll();
      if (oldMessages.isNotEmpty) {
        await instance.cachedMessages.deleteAll(
            oldMessages.map((m) => m.isarId).toList());
        deleted += oldMessages.length;
      }

      // Prune old gallery photos
      final oldPhotos = await instance.cachedGalleryPhotos
          .filter()
          .lastSyncedLessThan(cutoff)
          .findAll();
      if (oldPhotos.isNotEmpty) {
        await instance.cachedGalleryPhotos.deleteAll(
            oldPhotos.map((p) => p.isarId).toList());
        deleted += oldPhotos.length;
      }

      // Prune old polls
      final oldPolls = await instance.cachedPolls
          .filter()
          .lastSyncedLessThan(cutoff)
          .findAll();
      if (oldPolls.isNotEmpty) {
        await instance.cachedPolls.deleteAll(
            oldPolls.map((p) => p.isarId).toList());
        deleted += oldPolls.length;
      }

      // Prune old links
      final oldLinks = await instance.cachedTripLinks
          .filter()
          .lastSyncedLessThan(cutoff)
          .findAll();
      if (oldLinks.isNotEmpty) {
        await instance.cachedTripLinks.deleteAll(
            oldLinks.map((l) => l.isarId).toList());
        deleted += oldLinks.length;
      }
    });

    return deleted;
  }
}
