import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_env.dart';

/// Travel mood categories with display metadata.
enum TravelMood {
  adventure('Adventure', '🧗', 'You seek thrills, heights, and adrenaline.'),
  relaxation('Relaxation', '🏖', 'You\'re all about unwinding and de-stressing.'),
  party('Party', '🎉', 'You travel for nightlife, music, and vibes.'),
  cultural('Cultural', '🏛', 'You love history, art, and local traditions.'),
  nature('Nature', '🌿', 'Mountains, beaches, forests — you belong outdoors.'),
  romantic('Romantic', '💕', 'You love couples getaways and intimate trips.'),
  family('Family', '👨‍👩‍👧', 'You plan fun-for-all family adventures.'),
  solo('Solo Explorer', '🧘', 'You find yourself through solo journeys.'),
  foodie('Foodie', '🍜', 'You travel stomach-first — local food is the priority.'),
  luxury('Luxury', '💎', 'Five-star stays and premium experiences.');

  final String label;
  final String emoji;
  final String description;
  const TravelMood(this.label, this.emoji, this.description);

  static TravelMood? fromString(String? value) {
    if (value == null) return null;
    try {
      return TravelMood.values.firstWhere((m) => m.name == value);
    } catch (_) {
      return null;
    }
  }
}

/// Analyzes a user's travel history and behavior to determine their travel mood.
class TravelMoodService {
  final _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;
  String get _apiKey => AppEnv.geminiApiKey;

  /// Returns cached mood if available, otherwise triggers analysis.
  Future<TravelMood?> getCurrentMood() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('travel_mood')
          .eq('id', _userId)
          .single();
      final stored = data['travel_mood'] as String?;
      if (stored != null && stored.isNotEmpty) {
        return TravelMood.fromString(stored);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Analyzes trip history, interests, and behavior via Gemini AI,
  /// then stores the result in the user's profile.
  Future<TravelMood?> analyzeMood() async {
    try {
      // 1. Gather signals
      final signals = await _gatherSignals();
      if (signals['trip_count'] == 0 && (signals['interests'] as List).isEmpty) {
        return null; // Not enough data
      }

      // 2. Ask Gemini to classify
      final mood = await _classifyWithAI(signals);
      if (mood == null) return null;

      // 3. Store in profile
      await _supabase
          .from('profiles')
          .update({'travel_mood': mood.name})
          .eq('id', _userId);

      return mood;
    } catch (e) {
      debugPrint('TravelMoodService: analyzeMood error: $e');
      return null;
    }
  }

  /// Gather all available signals for mood classification.
  Future<Map<String, dynamic>> _gatherSignals() async {
    final uid = _userId;

    // Fetch in parallel
    final results = await Future.wait([
      _fetchTripTypes(uid),
      _fetchRecentChatKeywords(uid),
      _fetchUserProfile(uid),
      _fetchTripLocations(uid),
    ]);

    final tripTypeData = results[0] as Map<String, dynamic>;
    final chatKeywords = results[1] as List<String>;
    final profileData = results[2] as Map<String, dynamic>;
    final locations = results[3] as List<String>;

    return {
      'trip_count': tripTypeData['count'],
      'trip_types': tripTypeData['types'],
      'trip_type_counts': tripTypeData['type_counts'],
      'locations': locations,
      'interests': profileData['interests'] ?? [],
      'trip_vibe': profileData['trip_vibe'],
      'budget_style': profileData['budget_style'],
      'chat_keywords': chatKeywords,
    };
  }

  Future<Map<String, dynamic>> _fetchTripTypes(String uid) async {
    try {
      final data = await _supabase
          .from('trips')
          .select('id, metadata')
          .contains('member_ids', [uid]);

      final trips = data as List;
      final typeCounts = <String, int>{};
      for (final t in trips) {
        final meta = t['metadata'] != null ? Map<String, dynamic>.from(t['metadata'] as Map) : null;
        final type = meta?['trip_type'] as String?;
        if (type != null) {
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        }
      }
      return {
        'count': trips.length,
        'types': typeCounts.keys.toList(),
        'type_counts': typeCounts,
      };
    } catch (_) {
      return {'count': 0, 'types': <String>[], 'type_counts': <String, int>{}};
    }
  }

  Future<List<String>> _fetchRecentChatKeywords(String uid) async {
    try {
      // Fetch last 50 messages from user across all trips
      final data = await _supabase
          .from('trip_messages')
          .select('content')
          .eq('sender_id', uid)
          .order('created_at', ascending: false)
          .limit(50);

      final messages = (data as List).map((m) => m['content'] as String? ?? '').toList();
      // Extract travel-related keywords
      return _extractKeywords(messages);
    } catch (_) {
      return [];
    }
  }

  List<String> _extractKeywords(List<String> messages) {
    final travelWords = {
      'adventure', 'trek', 'hike', 'climb', 'dive', 'surf', 'raft', 'bungee',
      'beach', 'relax', 'spa', 'resort', 'chill', 'yoga', 'meditation',
      'party', 'club', 'nightlife', 'bar', 'music', 'festival', 'concert',
      'temple', 'museum', 'heritage', 'history', 'culture', 'art', 'ruins',
      'mountain', 'forest', 'lake', 'waterfall', 'wildlife', 'safari', 'camping',
      'romantic', 'couples', 'anniversary', 'honeymoon', 'date',
      'family', 'kids', 'children', 'amusement', 'theme park',
      'solo', 'alone', 'backpack', 'hostel', 'wander',
      'food', 'restaurant', 'cuisine', 'street food', 'café', 'taste',
      'luxury', 'five star', 'premium', 'first class', 'vip', 'boutique',
    };

    final found = <String>{};
    final combined = messages.join(' ').toLowerCase();
    for (final word in travelWords) {
      if (combined.contains(word)) found.add(word);
    }
    return found.toList();
  }

  Future<Map<String, dynamic>> _fetchUserProfile(String uid) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('interests, trip_vibe, budget_style')
          .eq('id', uid)
          .single();
      return data;
    } catch (_) {
      return {};
    }
  }

  Future<List<String>> _fetchTripLocations(String uid) async {
    try {
      final data = await _supabase
          .from('trips')
          .select('location')
          .contains('member_ids', [uid])
          .limit(20);
      return (data as List).map((t) => t['location'] as String? ?? '').where((l) => l.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// Use Gemini AI to classify travel mood from gathered signals.
  Future<TravelMood?> _classifyWithAI(Map<String, dynamic> signals) async {
    final prompt = """
You are a travel personality classifier. Based on the user's travel data below,
classify them into EXACTLY ONE of these moods:

Mood options (return only the key):
- adventure (thrills, treks, extreme sports)
- relaxation (beaches, spas, slow travel)
- party (nightlife, festivals, music)
- cultural (history, museums, heritage)
- nature (mountains, forests, wildlife)
- romantic (couple trips, honeymoons)
- family (family vacations, kids)
- solo (solo travel, backpacking)
- foodie (food tours, local cuisine)
- luxury (premium stays, VIP experiences)

USER DATA:
- Trip count: ${signals['trip_count']}
- Trip types used: ${jsonEncode(signals['trip_type_counts'])}
- Destinations: ${(signals['locations'] as List).take(10).join(', ')}
- Interests: ${(signals['interests'] as List).join(', ')}
- Preferred vibe: ${signals['trip_vibe'] ?? 'not set'}
- Budget style: ${signals['budget_style'] ?? 'not set'}
- Chat keywords: ${(signals['chat_keywords'] as List).join(', ')}

RESPOND WITH ONLY THE MOOD KEY (e.g., "adventure"). No explanation, no quotes.
""";

    try {
      final models = [
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-1.5-flash-latest',
      ];

      for (final model in models) {
        final uri = Uri.https(
          'generativelanguage.googleapis.com',
          '/v1/models/$model:generateContent',
          {'key': _apiKey},
        );

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = (data['candidates']?[0]['content']?['parts']?[0]['text'] as String?)
              ?.trim()
              .toLowerCase()
              .replaceAll('"', '')
              .replaceAll("'", '');
          if (text != null) {
            return TravelMood.fromString(text);
          }
        }

        if (response.statusCode == 404) continue;
      }
    } catch (e) {
      debugPrint('TravelMoodService: AI classification failed: $e');
    }

    // Fallback: heuristic-based classification
    return _heuristicClassify(signals);
  }

  /// Fallback classification without AI — uses simple signal matching.
  TravelMood? _heuristicClassify(Map<String, dynamic> signals) {
    final typeCounts = signals['trip_type_counts'] as Map<String, int>? ?? {};
    final keywords = signals['chat_keywords'] as List? ?? [];
    final vibe = signals['trip_vibe'] as String?;
    final budget = signals['budget_style'] as String?;
    final interests = signals['interests'] as List? ?? [];

    // Score each mood
    final scores = <TravelMood, double>{};
    for (final mood in TravelMood.values) {
      scores[mood] = 0;
    }

    // Trip type scoring
    for (final entry in typeCounts.entries) {
      switch (entry.key) {
        case 'adventure': scores[TravelMood.adventure] = scores[TravelMood.adventure]! + entry.value * 3;
        case 'backpacking': scores[TravelMood.adventure] = scores[TravelMood.adventure]! + entry.value * 2;
            scores[TravelMood.solo] = scores[TravelMood.solo]! + entry.value;
        case 'leisure': scores[TravelMood.relaxation] = scores[TravelMood.relaxation]! + entry.value * 2;
        case 'luxury': scores[TravelMood.luxury] = scores[TravelMood.luxury]! + entry.value * 3;
        case 'family': scores[TravelMood.family] = scores[TravelMood.family]! + entry.value * 3;
        case 'romantic': scores[TravelMood.romantic] = scores[TravelMood.romantic]! + entry.value * 3;
        case 'workation': scores[TravelMood.relaxation] = scores[TravelMood.relaxation]! + entry.value;
        case 'solo': scores[TravelMood.solo] = scores[TravelMood.solo]! + entry.value * 3;
      }
    }

    // Vibe scoring
    if (vibe == 'Adventure') scores[TravelMood.adventure] = scores[TravelMood.adventure]! + 2;
    if (vibe == 'Chill') scores[TravelMood.relaxation] = scores[TravelMood.relaxation]! + 2;
    if (vibe == 'Party') scores[TravelMood.party] = scores[TravelMood.party]! + 2;

    // Budget scoring
    if (budget == 'Luxury') scores[TravelMood.luxury] = scores[TravelMood.luxury]! + 2;
    if (budget == 'Budget') {
      scores[TravelMood.adventure] = scores[TravelMood.adventure]! + 1;
      scores[TravelMood.solo] = scores[TravelMood.solo]! + 1;
    }

    // Keyword scoring
    final keywordMoodMap = {
      TravelMood.adventure: ['trek', 'hike', 'climb', 'dive', 'surf', 'raft', 'bungee', 'adventure'],
      TravelMood.relaxation: ['beach', 'relax', 'spa', 'resort', 'chill', 'yoga', 'meditation'],
      TravelMood.party: ['party', 'club', 'nightlife', 'bar', 'music', 'festival', 'concert'],
      TravelMood.cultural: ['temple', 'museum', 'heritage', 'history', 'culture', 'art', 'ruins'],
      TravelMood.nature: ['mountain', 'forest', 'lake', 'waterfall', 'wildlife', 'safari', 'camping'],
      TravelMood.romantic: ['romantic', 'couples', 'anniversary', 'honeymoon', 'date'],
      TravelMood.family: ['family', 'kids', 'children', 'amusement', 'theme park'],
      TravelMood.solo: ['solo', 'alone', 'backpack', 'hostel', 'wander'],
      TravelMood.foodie: ['food', 'restaurant', 'cuisine', 'street food', 'café', 'taste'],
      TravelMood.luxury: ['luxury', 'five star', 'premium', 'first class', 'vip', 'boutique'],
    };

    for (final entry in keywordMoodMap.entries) {
      for (final kw in entry.value) {
        if (keywords.contains(kw)) {
          scores[entry.key] = scores[entry.key]! + 1;
        }
      }
    }

    // Interest scoring
    final interestMoodMap = {
      TravelMood.adventure: ['trekking', 'hiking', 'adventure', 'sports', 'extreme sports', 'scuba'],
      TravelMood.nature: ['nature', 'wildlife', 'camping', 'mountains', 'outdoors', 'photography'],
      TravelMood.cultural: ['history', 'culture', 'museums', 'art', 'heritage', 'architecture'],
      TravelMood.foodie: ['food', 'cooking', 'street food', 'local cuisine', 'wine', 'coffee'],
      TravelMood.party: ['nightlife', 'music', 'festivals', 'parties', 'EDM', 'concerts'],
      TravelMood.relaxation: ['yoga', 'wellness', 'spa', 'meditation', 'beaches'],
    };

    for (final entry in interestMoodMap.entries) {
      for (final interest in interests) {
        if (entry.value.any((i) => interest.toString().toLowerCase().contains(i))) {
          scores[entry.key] = scores[entry.key]! + 1.5;
        }
      }
    }

    // Find top mood
    var topMood = TravelMood.adventure;
    var topScore = 0.0;
    for (final entry in scores.entries) {
      if (entry.value > topScore) {
        topScore = entry.value;
        topMood = entry.key;
      }
    }

    return topScore > 0 ? topMood : null;
  }

  /// Get a mood-matched destination suggestion (for notification content).
  String getMoodSuggestion(TravelMood mood) {
    const suggestions = {
      TravelMood.adventure: [
        'Rishikesh is calling — rafting season is on! 🌊',
        'Ever tried paragliding in Bir Billing? 🪂',
        'Spiti Valley awaits the brave 🏔',
      ],
      TravelMood.relaxation: [
        'Udaipur\'s lakeside vibes are perfect right now 🌅',
        'How about a wellness retreat in Pondicherry? 🧘',
        'Alleppey houseboats for the soul 🚢',
      ],
      TravelMood.party: [
        'Goa beach fest season is here 🎶',
        'Kasol + New Year = Magic ✨',
        'Bangkok calling for the weekend? 🌃',
      ],
      TravelMood.cultural: [
        'Hampi\'s ruins are breathtaking this time of year 🏛',
        'Jaipur\'s heritage walk awaits you 🏰',
        'Varanasi — experience the oldest living city 🕉',
      ],
      TravelMood.nature: [
        'Munnar\'s tea estates are lush right now 🌿',
        'Coorg + misty mornings = perfection ☁',
        'Valley of Flowers is calling! 🌸',
      ],
      TravelMood.romantic: [
        'Santorini-style sunset in Udaipur? 💕',
        'Andaman for just the two of you 🏝',
        'Manali snow + hot chocolate = romance ❄',
      ],
      TravelMood.family: [
        'Jaipur is amazing with kids 🐘',
        'Kerala backwaters — fun for the whole family! 🚣',
        'Singapore trip perfect for families 🎢',
      ],
      TravelMood.solo: [
        'McLeodGanj — find yourself in the mountains 🧘',
        'Hampi is a solo traveler\'s paradise 🎒',
        'Pushkar has that magic for solo souls ✨',
      ],
      TravelMood.foodie: [
        'Lucknow\'s kebab trail is legendary 🍢',
        'Kolkata street food tour — start planning! 🍜',
        'Penang or Bangalore — which food capital? 🍛',
      ],
      TravelMood.luxury: [
        'Taj Lake Palace is running a special 💎',
        'Maldives overwater villa — you deserve it 🏝',
        'Oberoi Shimla for a royal getaway 🏔',
      ],
    };

    final list = suggestions[mood] ?? ['Time to plan your next trip! 🌍'];
    list.shuffle();
    return list.first;
  }
}
