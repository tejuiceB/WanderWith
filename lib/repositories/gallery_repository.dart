import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../local/local_db.dart';
import '../local/schemas/cached_gallery_photo.dart';
import '../services/network_service.dart';
import '../services/trip_service.dart';

/// Repository layer for gallery photos — serves cached URLs first, then syncs.
/// CachedNetworkImage handles actual image file caching automatically.
class GalleryRepository {
  final TripService _remote = TripService();

  // ────────── Conversion Helpers ──────────

  static CachedGalleryPhoto _toCached(Map<String, dynamic> photo) {
    return CachedGalleryPhoto()
      ..id = photo['id'] ?? ''
      ..tripId = photo['trip_id'] ?? ''
      ..url = photo['url'] ?? ''
      ..thumbnailUrl = photo['thumbnail_url']
      ..uploadedBy = photo['uploaded_by'] ?? ''
      ..caption = photo['caption']
      ..createdAt = photo['created_at'] != null
          ? DateTime.tryParse(photo['created_at'])
          : null
      ..lastSynced = DateTime.now();
  }

  static Map<String, dynamic> _fromCached(CachedGalleryPhoto cached) {
    return {
      'id': cached.id,
      'trip_id': cached.tripId,
      'url': cached.url,
      'thumbnail_url': cached.thumbnailUrl,
      'uploaded_by': cached.uploadedBy,
      'caption': cached.caption,
      'created_at': cached.createdAt?.toIso8601String(),
    };
  }

  // ────────── Read Operations ──────────

  /// Get gallery photos — cache first, then remote
  Future<List<Map<String, dynamic>>> getPhotos(String tripId) async {
    if (NetworkService.instance.isOnline) {
      try {
        // Use a one-time listen on the stream to get current photos
        final photos = await _remote.getPhotosStream(tripId).first;
        await _cachePhotos(tripId, photos);
        return photos;
      } catch (e) {
        debugPrint('GalleryRepository: Remote failed, using cache: $e');
      }
    }

    // Fallback to cache
    final cached = await LocalDb.instance.cachedGalleryPhotos
        .filter()
        .tripIdEqualTo(tripId)
        .findAll();
    return cached.map((c) => _fromCached(c)).toList();
  }

  // ────────── Cache Helpers ──────────

  Future<void> _cachePhotos(
      String tripId, List<Map<String, dynamic>> photos) async {
    try {
      await LocalDb.instance.writeTxn(() async {
        // Clear old cached photos for this trip
        final old = await LocalDb.instance.cachedGalleryPhotos
            .filter()
            .tripIdEqualTo(tripId)
            .findAll();
        await LocalDb.instance.cachedGalleryPhotos
            .deleteAll(old.map((p) => p.isarId).toList());

        // Write new
        for (final photo in photos) {
          await LocalDb.instance.cachedGalleryPhotos.put(_toCached(photo));
        }
      });
    } catch (e) {
      debugPrint('GalleryRepository: Cache write failed: $e');
    }
  }
}
