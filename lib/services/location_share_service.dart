import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to manage live location sharing in trips.
/// Handles starting/stopping background location updates and
/// streaming active shares for a trip.
class LocationShareService {
  LocationShareService._();
  static final instance = LocationShareService._();

  final _supabase = Supabase.instance.client;

  Timer? _updateTimer;
  String? _activeTripId;
  DateTime? _expiresAt;
  StreamSubscription<Position>? _positionSub;

  /// Whether we are currently sharing live location
  bool get isSharing => _activeTripId != null && (_expiresAt?.isAfter(DateTime.now()) ?? false);

  String? get activeTripId => _activeTripId;

  /// Start sharing live location for [duration].
  /// Updates the DB every ~10 seconds with the latest position.
  Future<void> startSharing(String tripId, Duration duration) async {
    // Ensure location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
    }

    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    _activeTripId = tripId;
    _expiresAt = DateTime.now().add(duration);

    // Get initial position
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // Upsert initial share row
    await _supabase.from('live_location_shares').upsert({
      'trip_id': tripId,
      'user_id': uid,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'accuracy': pos.accuracy,
      'heading': pos.heading,
      'speed': pos.speed,
      'expires_at': _expiresAt!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'trip_id,user_id');

    // Start periodic updates every 10 seconds
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) => _tickUpdate(tripId, uid));
  }

  Future<void> _tickUpdate(String tripId, String uid) async {
    // Check if expired
    if (_expiresAt != null && DateTime.now().isAfter(_expiresAt!)) {
      await stopSharing();
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _supabase.from('live_location_shares').upsert({
        'trip_id': tripId,
        'user_id': uid,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
        'heading': pos.heading,
        'speed': pos.speed,
        'expires_at': _expiresAt!.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'trip_id,user_id');
    } catch (_) {
      // Silently handle — will retry on next tick
    }
  }

  /// Stop sharing live location and remove the DB row
  Future<void> stopSharing() async {
    _updateTimer?.cancel();
    _updateTimer = null;
    _positionSub?.cancel();
    _positionSub = null;

    final uid = _supabase.auth.currentUser?.id;
    if (uid != null && _activeTripId != null) {
      try {
        await _supabase
            .from('live_location_shares')
            .delete()
            .eq('trip_id', _activeTripId!)
            .eq('user_id', uid);
      } catch (_) {}
    }
    _activeTripId = null;
    _expiresAt = null;
  }

  /// Stream of active live location shares for a trip.
  /// Only returns non-expired shares.
  Stream<List<Map<String, dynamic>>> activeSharesStream(String tripId) {
    return _supabase
        .from('live_location_shares')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .map((rows) {
          final now = DateTime.now();
          return rows.where((r) {
            final expires = DateTime.tryParse(r['expires_at'] ?? '');
            return expires != null && expires.isAfter(now);
          }).toList();
        });
  }

  /// One-time fetch of active shares for a trip
  Future<List<Map<String, dynamic>>> fetchActiveShares(String tripId) async {
    final rows = await _supabase
        .from('live_location_shares')
        .select()
        .eq('trip_id', tripId)
        .gt('expires_at', DateTime.now().toIso8601String());
    return List<Map<String, dynamic>>.from(rows);
  }
}
