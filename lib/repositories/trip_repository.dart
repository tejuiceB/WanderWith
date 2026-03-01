import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../local/local_db.dart';
import '../local/schemas/cached_trip.dart';
import '../models/trip.dart';
import '../services/network_service.dart';
import '../services/trip_service.dart';

/// Repository layer for trips — serves cached data first, then syncs from remote.
/// All screens should use TripRepository instead of TripService directly for reads.
class TripRepository {
  final TripService _remote = TripService();

  // ────────── Conversion Helpers ──────────

  static CachedTrip _toCached(Trip trip) {
    return CachedTrip()
      ..id = trip.id
      ..name = trip.name
      ..location = trip.location
      ..startDate = trip.startDate
      ..endDate = trip.endDate
      ..isDateDecided = trip.isDateDecided
      ..createdBy = trip.createdBy
      ..memberIds = trip.memberIds
      ..adminIds = trip.adminIds
      ..metadataJson =
          trip.metadata != null ? jsonEncode(trip.metadata) : null
      ..budgetCurrency = trip.budgetCurrency
      ..budgetOptionsJson =
          trip.budgetOptions != null ? jsonEncode(trip.budgetOptions) : null
      ..budgetVotesJson =
          trip.budgetVotes != null ? jsonEncode(trip.budgetVotes) : null
      ..coverImageUrl = trip.coverImageUrl
      ..visibility = trip.visibility
      ..joinCode = trip.joinCode
      ..lastSynced = DateTime.now();
  }

  static Trip _fromCached(CachedTrip cached) {
    return Trip(
      id: cached.id,
      name: cached.name,
      location: cached.location,
      startDate: cached.startDate,
      endDate: cached.endDate,
      isDateDecided: cached.isDateDecided,
      createdBy: cached.createdBy,
      memberIds: cached.memberIds,
      adminIds: cached.adminIds,
      metadata: cached.metadataJson != null
          ? jsonDecode(cached.metadataJson!) as Map<String, dynamic>
          : null,
      budgetCurrency: cached.budgetCurrency,
      budgetOptions: cached.budgetOptionsJson != null
          ? Map<String, String>.from(jsonDecode(cached.budgetOptionsJson!))
          : null,
      budgetVotes: cached.budgetVotesJson != null
          ? Map<String, String>.from(jsonDecode(cached.budgetVotesJson!))
          : null,
      coverImageUrl: cached.coverImageUrl,
      visibility: cached.visibility,
      joinCode: cached.joinCode,
    );
  }

  // ────────── Read Operations ──────────

  /// Get a single trip — tries remote first, falls back to cache
  Future<Trip> getTrip(String tripId) async {
    if (NetworkService.instance.isOnline) {
      try {
        final trip = await _remote.getTrip(tripId);
        // Cache it
        await _cacheTrip(trip);
        return trip;
      } catch (e) {
        debugPrint('TripRepository: Remote fetch failed, trying cache: $e');
      }
    }
    // Fallback to cache
    final cached = await LocalDb.instance.cachedTrips
        .filter()
        .idEqualTo(tripId)
        .findFirst();
    if (cached != null) return _fromCached(cached);
    throw Exception('Trip not found (offline)');
  }

  /// Get all trips for a user — yields cached first, then fresh data
  Stream<List<Trip>> getUserTrips(String userId) async* {
    // 1. Yield cached data immediately
    final cached = await LocalDb.instance.cachedTrips
        .filter()
        .memberIdsElementContains(userId)
        .findAll();
    if (cached.isNotEmpty) {
      yield cached.map((c) => _fromCached(c)).toList();
    }

    // 2. If online, fetch fresh data
    if (NetworkService.instance.isOnline) {
      try {
        await for (final trips in _remote.getUserTrips(userId)) {
          // Update cache
          await LocalDb.instance.writeTxn(() async {
            for (final trip in trips) {
              await LocalDb.instance.cachedTrips.put(_toCached(trip));
            }
          });
          yield trips;
        }
      } catch (e) {
        debugPrint('TripRepository: Remote stream failed: $e');
      }
    }
  }

  // ────────── Cache Helpers ──────────

  Future<void> _cacheTrip(Trip trip) async {
    try {
      await LocalDb.instance.writeTxn(() async {
        await LocalDb.instance.cachedTrips.put(_toCached(trip));
      });
    } catch (e) {
      debugPrint('TripRepository: Cache write failed: $e');
    }
  }

  /// Pre-cache trip data when user opens a trip (for offline access later)
  Future<void> preCacheTripData(Trip trip) async {
    await _cacheTrip(trip);
  }

  /// Clear cached trips (e.g. on logout)
  Future<void> clearCache() async {
    await LocalDb.instance.writeTxn(() async {
      await LocalDb.instance.cachedTrips.clear();
    });
  }
}
