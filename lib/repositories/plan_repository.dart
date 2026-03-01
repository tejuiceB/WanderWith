import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../local/local_db.dart';
import '../local/schemas/cached_trip_day.dart';
import '../local/schemas/cached_trip_place.dart';
import '../models/trip_plan.dart';
import '../services/network_service.dart';
import '../services/plan_service.dart';
import '../services/sync_service.dart';

/// Repository layer for trip plans — serves cached data first, then syncs from remote.
class PlanRepository {
  final PlanService _remote = PlanService();

  // ────────── Conversion Helpers ──────────

  static CachedTripDay _dayToCached(TripDay day) {
    return CachedTripDay()
      ..id = day.id
      ..tripId = day.tripId
      ..dayNumber = day.dayNumber
      ..date = day.date
      ..summary = day.summary
      ..lastSynced = DateTime.now();
  }

  static CachedTripPlace _placeToCached(TripPlanPlace place) {
    return CachedTripPlace()
      ..id = place.id
      ..tripDayId = place.tripDayId
      ..googlePlaceId = place.googlePlaceId
      ..name = place.name
      ..type = place.type
      ..latitude = place.latitude
      ..longitude = place.longitude
      ..imageUrl = place.imageUrl
      ..arrivalTime = place.arrivalTime
      ..orderIndex = place.orderIndex
      ..description = place.description
      ..rating = place.rating
      ..aiInsight = place.aiInsight
      ..lastSynced = DateTime.now();
  }

  static TripDay _dayFromCached(CachedTripDay cached, List<TripPlanPlace> places) {
    return TripDay(
      id: cached.id,
      tripId: cached.tripId,
      dayNumber: cached.dayNumber,
      date: cached.date,
      summary: cached.summary,
      places: places,
    );
  }

  static TripPlanPlace _placeFromCached(CachedTripPlace cached) {
    return TripPlanPlace(
      id: cached.id,
      tripDayId: cached.tripDayId,
      googlePlaceId: cached.googlePlaceId,
      name: cached.name,
      type: cached.type,
      latitude: cached.latitude,
      longitude: cached.longitude,
      imageUrl: cached.imageUrl,
      arrivalTime: cached.arrivalTime,
      orderIndex: cached.orderIndex,
      description: cached.description,
      rating: cached.rating,
      aiInsight: cached.aiInsight,
    );
  }

  // ────────── Read Operations ──────────

  /// Get trip plan — tries remote first, falls back to cache
  Future<List<TripDay>> getTripPlan(String tripId) async {
    if (NetworkService.instance.isOnline) {
      try {
        final days = await _remote.fetchTripPlan(tripId);
        await _cachePlan(tripId, days);
        return days;
      } catch (e) {
        debugPrint('PlanRepository: Remote fetch failed, trying cache: $e');
      }
    }

    // Fallback to cache
    return _getCachedPlan(tripId);
  }

  Future<List<TripDay>> _getCachedPlan(String tripId) async {
    final cachedDays = await LocalDb.instance.cachedTripDays
        .filter()
        .tripIdEqualTo(tripId)
        .sortByDayNumber()
        .findAll();

    final days = <TripDay>[];
    for (final day in cachedDays) {
      final cachedPlaces = await LocalDb.instance.cachedTripPlaces
          .filter()
          .tripDayIdEqualTo(day.id)
          .sortByOrderIndex()
          .findAll();
      final places = cachedPlaces.map((p) => _placeFromCached(p)).toList();
      days.add(_dayFromCached(day, places));
    }
    return days;
  }

  // ────────── Write Operations ──────────

  /// Add a place — goes remote if online, queues if offline
  Future<void> addPlace(TripPlanPlace place) async {
    if (NetworkService.instance.isOnline) {
      await _remote.addPlace(place.toJson());
    } else {
      await SyncService.instance.queueAction('add_plan_place', place.toJson());
    }
  }

  // ────────── Cache Helpers ──────────

  Future<void> _cachePlan(String tripId, List<TripDay> days) async {
    try {
      await LocalDb.instance.writeTxn(() async {
        // Clear old cached days/places for this trip
        final oldDays = await LocalDb.instance.cachedTripDays
            .filter()
            .tripIdEqualTo(tripId)
            .findAll();
        for (final day in oldDays) {
          final oldPlaces = await LocalDb.instance.cachedTripPlaces
              .filter()
              .tripDayIdEqualTo(day.id)
              .findAll();
          await LocalDb.instance.cachedTripPlaces
              .deleteAll(oldPlaces.map((p) => p.isarId).toList());
        }
        await LocalDb.instance.cachedTripDays
            .deleteAll(oldDays.map((d) => d.isarId).toList());

        // Write new data
        for (final day in days) {
          await LocalDb.instance.cachedTripDays.put(_dayToCached(day));
          for (final place in day.places) {
            await LocalDb.instance.cachedTripPlaces.put(_placeToCached(place));
          }
        }
      });
    } catch (e) {
      debugPrint('PlanRepository: Cache write failed: $e');
    }
  }
}
