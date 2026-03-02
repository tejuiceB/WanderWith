import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import 'smart_notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Badge Definitions
// ─────────────────────────────────────────────────────────────────────────────

/// All achievable travel badges with their unlock conditions.
enum TravelBadge {
  firstTrip(
    'First Trip',
    '🎒',
    'Completed your first trip',
    'completed_trips',
    1,
  ),
  explorer(
    'Explorer',
    '🧭',
    'Completed 3 trips',
    'completed_trips',
    3,
  ),
  globetrotter(
    'Globetrotter',
    '🌍',
    'Completed 5 trips',
    'completed_trips',
    5,
  ),
  wanderlustLegend(
    'Wanderlust Legend',
    '✈️',
    'Completed 10 trips',
    'completed_trips',
    10,
  ),
  placeHopper(
    'Place Hopper',
    '🗺️',
    'Visited 5 unique destinations',
    'unique_destinations',
    5,
  ),
  crossCountry(
    'Cross-Country',
    '🏔️',
    'Visited 10 unique destinations',
    'unique_destinations',
    10,
  ),
  groupLeader(
    'Group Leader',
    '👥',
    'Created 5 trips',
    'trips_created',
    5,
  ),
  socialButterfly(
    'Social Butterfly',
    '🦋',
    'Traveled with 10+ unique people',
    'unique_co_travelers',
    10,
  ),
  budgetPro(
    'Budget Pro',
    '💰',
    'Tracked expenses on 3+ trips',
    'trips_with_expenses',
    3,
  ),
  memoryMaker(
    'Memory Maker',
    '📸',
    'Shared 10+ trip posts',
    'posts_count',
    10,
  ),
  earlyPlanner(
    'Early Planner',
    '🌅',
    'Planned a trip 30+ days ahead',
    'early_planned_trips',
    1,
  ),
  chatChampion(
    'Chat Champion',
    '💬',
    'Sent 100+ messages across trips',
    'messages_sent',
    100,
  );

  final String label;
  final String emoji;
  final String description;

  /// The stat key this badge checks against.
  final String statKey;

  /// The threshold value needed to unlock this badge.
  final int threshold;

  const TravelBadge(
      this.label, this.emoji, this.description, this.statKey, this.threshold);

  static TravelBadge? fromString(String? value) {
    if (value == null) return null;
    try {
      return TravelBadge.values.firstWhere((b) => b.name == value);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Milestone Progress Model
// ─────────────────────────────────────────────────────────────────────────────

class MilestoneProgress {
  final TravelBadge badge;
  final int currentValue;
  final double progress; // 0.0 – 1.0

  const MilestoneProgress({
    required this.badge,
    required this.currentValue,
    required this.progress,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Gamification Service
// ─────────────────────────────────────────────────────────────────────────────

/// Computes travel stats, awards badges, and sends gamified notifications.
class GamificationService {
  final _supabase = Supabase.instance.client;

  // ── Singleton ────────────────────────────────────────────────────
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  String get _userId => _supabase.auth.currentUser!.id;

  // ── Public API ───────────────────────────────────────────────────

  /// Returns the user's earned badges (from cached profile data).
  List<Map<String, dynamic>> getEarnedBadges(dynamic badgesJson) {
    if (badgesJson == null) return [];
    if (badgesJson is List) {
      return badgesJson.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Parse earned badges from the raw profile field.
  List<Map<String, dynamic>> parseBadgesFromProfile(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (_) {}
    }
    return [];
  }

  /// Get earned badge keys as a Set for quick lookup.
  Set<String> earnedBadgeKeys(dynamic raw) {
    final badges = parseBadgesFromProfile(raw);
    return badges.map((b) => b['badge'] as String).toSet();
  }

  /// Fetch current gamification stats from profile cache.
  Future<Map<String, dynamic>> getCachedStats() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('gamification_stats, badges_earned')
          .eq('id', _userId)
          .single();
      return {
        'stats': data['gamification_stats'] ?? {},
        'badges': data['badges_earned'] ?? [],
      };
    } catch (_) {
      return {'stats': {}, 'badges': []};
    }
  }

  /// Full analysis: compute live stats → check badges → award new ones → notify.
  /// Returns the list of newly awarded badge keys.
  Future<List<TravelBadge>> analyzeAndUpdate() async {
    try {
      final uid = _userId;

      // 1. Compute fresh stats from real data
      final stats = await _computeStats(uid);

      // 2. Get currently earned badges
      final profileData = await _supabase
          .from('profiles')
          .select('badges_earned')
          .eq('id', uid)
          .single();
      final earned = earnedBadgeKeys(profileData['badges_earned']);

      // 3. Evaluate which new badges are unlocked
      final newBadges = <TravelBadge>[];
      for (final badge in TravelBadge.values) {
        if (earned.contains(badge.name)) continue;
        final statValue = stats[badge.statKey] as int? ?? 0;
        if (statValue >= badge.threshold) {
          newBadges.add(badge);
        }
      }

      // 4. Award new badges atomically
      for (final badge in newBadges) {
        try {
          await _supabase.rpc('award_badge', params: {
            'p_user_id': uid,
            'p_badge_key': badge.name,
          });
        } catch (e) {
          // Fallback: direct update if RPC not yet deployed
          debugPrint('GamificationService: RPC fallback for ${badge.name}: $e');
          await _awardBadgeFallback(uid, badge);
        }
      }

      // 5. Update cached stats
      stats['last_analyzed_at'] = DateTime.now().toIso8601String();
      await _supabase
          .from('profiles')
          .update({'gamification_stats': stats}).eq('id', uid);

      // 6. Send notifications for new badges
      for (final badge in newBadges) {
        await _notifyBadgeEarned(uid, badge);
      }

      return newBadges;
    } catch (e) {
      debugPrint('GamificationService: analyzeAndUpdate error: $e');
      return [];
    }
  }

  /// Returns the closest un-earned badge and progress toward it.
  List<MilestoneProgress> getNextMilestones(
      Map<String, dynamic> stats, Set<String> earned) {
    final milestones = <MilestoneProgress>[];

    for (final badge in TravelBadge.values) {
      if (earned.contains(badge.name)) continue;
      final current = (stats[badge.statKey] as num?)?.toInt() ?? 0;
      final progress = (current / badge.threshold).clamp(0.0, 1.0);

      // Only show milestones with some progress (> 0%) and not yet earned
      if (progress > 0.0) {
        milestones.add(MilestoneProgress(
          badge: badge,
          currentValue: current,
          progress: progress,
        ));
      }
    }

    // Sort by closest to completion
    milestones.sort((a, b) => b.progress.compareTo(a.progress));
    return milestones.take(3).toList();
  }

  // ── Private — Stats Computation ──────────────────────────────────

  Future<Map<String, dynamic>> _computeStats(String uid) async {
    final results = await Future.wait([
      _countCompletedTrips(uid),
      _countUniqueDestinations(uid),
      _countTripsCreated(uid),
      _countUniqueCoTravelers(uid),
      _countTripsWithExpenses(uid),
      _countMessagesSent(uid),
      _countEarlyPlannedTrips(uid),
      _fetchPostsCount(uid),
    ]);

    return {
      'completed_trips': results[0],
      'unique_destinations': results[1],
      'trips_created': results[2],
      'unique_co_travelers': results[3],
      'trips_with_expenses': results[4],
      'messages_sent': results[5],
      'early_planned_trips': results[6],
      'posts_count': results[7],
    };
  }

  Future<int> _countCompletedTrips(String uid) async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await _supabase
          .from('trips')
          .select('id, end_date')
          .contains('member_ids', [uid])
          .not('end_date', 'is', null)
          .lte('end_date', now);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countUniqueDestinations(String uid) async {
    try {
      final data = await _supabase
          .from('trips')
          .select('location')
          .contains('member_ids', [uid]);
      final locations = (data as List)
          .map((t) => (t['location'] as String?)?.toLowerCase().trim())
          .where((l) => l != null && l.isNotEmpty)
          .toSet();
      return locations.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countTripsCreated(String uid) async {
    try {
      final data = await _supabase
          .from('trips')
          .select('id')
          .eq('created_by', uid);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countUniqueCoTravelers(String uid) async {
    try {
      final data = await _supabase
          .from('trips')
          .select('member_ids')
          .contains('member_ids', [uid]);
      final coTravelers = <String>{};
      for (final trip in (data as List)) {
        final members = List<String>.from(trip['member_ids'] ?? []);
        coTravelers.addAll(members.where((m) => m != uid));
      }
      return coTravelers.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countTripsWithExpenses(String uid) async {
    try {
      final data = await _supabase
          .from('trip_expenses')
          .select('trip_id')
          .eq('paid_by', uid);
      final tripIds =
          (data as List).map((e) => e['trip_id'] as String).toSet();
      return tripIds.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countMessagesSent(String uid) async {
    try {
      final data = await _supabase
          .from('trip_messages')
          .select('id')
          .eq('sender_id', uid);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countEarlyPlannedTrips(String uid) async {
    try {
      final data = await _supabase
          .from('trips')
          .select('created_at, start_date')
          .eq('created_by', uid)
          .not('start_date', 'is', null);
      int count = 0;
      for (final trip in (data as List)) {
        final created = DateTime.tryParse(trip['created_at'] ?? '');
        final start = DateTime.tryParse(trip['start_date'] ?? '');
        if (created != null && start != null) {
          if (start.difference(created).inDays >= 30) count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _fetchPostsCount(String uid) async {
    try {
      final data = await _supabase
          .from('posts')
          .select('id')
          .eq('user_id', uid);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ── Private — Badge Award ────────────────────────────────────────

  Future<void> _awardBadgeFallback(String uid, TravelBadge badge) async {
    try {
      // Fetch current badges
      final data = await _supabase
          .from('profiles')
          .select('badges_earned')
          .eq('id', uid)
          .single();

      final current = parseBadgesFromProfile(data['badges_earned']);
      final alreadyEarned = current.any((b) => b['badge'] == badge.name);
      if (alreadyEarned) return;

      current.add({
        'badge': badge.name,
        'earned_at': DateTime.now().toIso8601String(),
      });

      await _supabase
          .from('profiles')
          .update({'badges_earned': current}).eq('id', uid);
    } catch (e) {
      debugPrint('GamificationService: fallback award error: $e');
    }
  }

  // ── Private — Notifications ──────────────────────────────────────

  Future<void> _notifyBadgeEarned(String uid, TravelBadge badge) async {
    try {
      await SmartNotificationService().send(
        toUserId: uid,
        title: 'Badge Unlocked! ${badge.emoji}',
        body: '${badge.label} — ${badge.description}',
        type: NotificationType.travelInspiration,
        subtype: 'badge_earned_${badge.name}',
        deepLink: '/profile/$uid',
      );
    } catch (e) {
      debugPrint('GamificationService: notify error: $e');
    }
  }

  /// Generate a milestone reached notification message.
  static String milestoneMessage(TravelBadge badge, int current) {
    switch (badge.statKey) {
      case 'completed_trips':
        return 'You\'ve completed $current trips this year 🏆';
      case 'unique_destinations':
        return 'You\'ve visited $current unique destinations — next milestone: ${badge.threshold}!';
      case 'trips_created':
        return 'You\'ve planned $current trips — keep exploring! 🗺️';
      case 'unique_co_travelers':
        return 'You\'ve traveled with $current unique people — Social Butterfly incoming! 🦋';
      case 'messages_sent':
        return 'You\'ve sent $current messages — chat game strong! 💬';
      default:
        return 'Keep going! You\'re $current/${badge.threshold} toward ${badge.label} ${badge.emoji}';
    }
  }
}
