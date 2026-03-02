import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/checklist_item.dart';
import '../models/trip.dart';
import '../config/app_env.dart';

class ChecklistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;
  String get _apiKey => AppEnv.geminiApiKey;

  /// Fetch checklist items for a trip (current user only)
  Future<List<ChecklistItem>> getChecklist(String tripId) async {
    final data = await _supabase
        .from('trip_checklist')
        .select()
        .eq('trip_id', tripId)
        .eq('user_id', _userId)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);
    return (data as List).map((e) => ChecklistItem.fromJson(e)).toList();
  }

  /// Toggle an item's checked state
  Future<void> toggleItem(String itemId, bool isChecked) async {
    await _supabase
        .from('trip_checklist')
        .update({'is_checked': isChecked})
        .eq('id', itemId);
  }

  /// Add a custom checklist item
  Future<ChecklistItem> addItem({
    required String tripId,
    required String itemText,
    String category = 'general',
  }) async {
    final row = await _supabase
        .from('trip_checklist')
        .insert({
          'trip_id': tripId,
          'user_id': _userId,
          'item_text': itemText,
          'category': category,
          'is_auto_generated': false,
        })
        .select()
        .single();
    return ChecklistItem.fromJson(row);
  }

  /// Delete a checklist item
  Future<void> deleteItem(String itemId) async {
    await _supabase.from('trip_checklist').delete().eq('id', itemId);
  }

  /// Generate default checklist items for a trip if none exist
  Future<List<ChecklistItem>> generateDefaults({
    required String tripId,
    required bool isInternational,
  }) async {
    // Check if user already has items for this trip
    final existing = await getChecklist(tripId);
    if (existing.isNotEmpty) return existing;

    final items = <Map<String, dynamic>>[];
    int order = 0;

    // Common items for all trips
    final common = [
      {'text': 'ID / Passport', 'category': 'documents'},
      {'text': 'Trip tickets / boarding passes', 'category': 'documents'},
      {'text': 'Hotel / accommodation booking', 'category': 'bookings'},
      {'text': 'Travel insurance', 'category': 'documents'},
      {'text': 'Phone charger & power bank', 'category': 'packing'},
      {'text': 'Medications / first aid', 'category': 'health'},
      {'text': 'Cash / cards', 'category': 'money'},
      {'text': 'Toiletries & personal items', 'category': 'packing'},
      {'text': 'Weather-appropriate clothing', 'category': 'packing'},
      {'text': 'Download offline maps', 'category': 'general'},
    ];

    for (final c in common) {
      items.add({
        'trip_id': tripId,
        'user_id': _userId,
        'item_text': c['text'],
        'category': c['category'],
        'is_auto_generated': true,
        'sort_order': order++,
      });
    }

    // International-specific items
    if (isInternational) {
      final intlItems = [
        {'text': 'Passport valid 6+ months', 'category': 'documents'},
        {'text': 'Visa approved / printed', 'category': 'documents'},
        {'text': 'Currency exchanged', 'category': 'money'},
        {'text': 'International SIM / eSIM', 'category': 'packing'},
        {'text': 'Embassy contact saved', 'category': 'documents'},
        {'text': 'Travel adapter / converter', 'category': 'packing'},
        {'text': 'Vaccination certificates', 'category': 'health'},
      ];
      for (final c in intlItems) {
        items.add({
          'trip_id': tripId,
          'user_id': _userId,
          'item_text': c['text'],
          'category': c['category'],
          'is_auto_generated': true,
          'sort_order': order++,
        });
      }
    }

    if (items.isNotEmpty) {
      await _supabase.from('trip_checklist').insert(items);
    }
    return getChecklist(tripId);
  }

  // ── AI Smart Checklist Generation ──

  /// Generate an AI-powered smart checklist tailored to the trip
  /// Falls back to [generateDefaults] on any failure.
  Future<List<ChecklistItem>> generateSmartChecklist({
    required Trip trip,
    required bool isInternational,
    bool regenerate = false,
  }) async {
    // If regenerating, clear old auto-generated items first
    if (regenerate) {
      await _supabase
          .from('trip_checklist')
          .delete()
          .eq('trip_id', trip.id)
          .eq('user_id', _userId)
          .eq('is_auto_generated', true);
    } else {
      // If user already has items, return them
      final existing = await getChecklist(trip.id);
      if (existing.isNotEmpty) return existing;
    }

    try {
      final aiItems = await _callGeminiForChecklist(trip, isInternational);
      if (aiItems.isNotEmpty) {
        await _supabase.from('trip_checklist').insert(aiItems);
        return getChecklist(trip.id);
      }
    } catch (e) {
      debugPrint('AI checklist generation failed, falling back to defaults: $e');
    }

    // Fallback to hardcoded defaults
    return generateDefaults(tripId: trip.id, isInternational: isInternational);
  }

  /// Call Gemini to produce categorized checklist items
  Future<List<Map<String, dynamic>>> _callGeminiForChecklist(
    Trip trip,
    bool isInternational,
  ) async {
    // Calculate trip context
    int durationDays = 3;
    if (trip.startDate != null && trip.endDate != null) {
      durationDays = trip.endDate!.difference(trip.startDate!).inDays + 1;
    } else {
      durationDays = trip.metadata?['days'] ?? 3;
    }

    final startMonth = trip.startDate != null
        ? _monthName(trip.startDate!.month)
        : 'unknown';

    final memberCount = trip.memberIds.length;
    final vibe = trip.metadata?['vibe'] ?? 'General';

    final prompt = """
You are a travel packing & preparation expert for the app 'WanderWith'.
Generate a personalized travel checklist based on the trip details below.

TRIP DETAILS:
- Destination: ${trip.location}
- Duration: $durationDays days
- Month: $startMonth
- International travel: $isInternational
- Group size: $memberCount people
- Trip vibe: $vibe

CATEGORIES (use ONLY these exact strings):
documents, packing, bookings, health, money, general

RULES:
1. Generate 15-25 items total, spread across relevant categories.
2. Tailor items to the destination, climate/season, and duration.
3. For international trips, include visa, currency exchange, adapter, etc.
4. For beach/tropical destinations, include sunscreen, swimwear, etc.
5. For cold/mountain destinations, include layers, thermals, etc.
6. For adventure/hiking vibes, include trekking gear.
7. Keep item text short (3-7 words each).
8. Do NOT include duplicate or overly generic items.

OUTPUT FORMAT (STRICT JSON ONLY):
{
  "items": [
    {"text": "Passport valid 6+ months", "category": "documents"},
    {"text": "Sunscreen SPF 50", "category": "packing"},
    {"text": "Hotel confirmation printout", "category": "bookings"}
  ]
}
""";

    final models = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash',
    ];

    for (final model in models) {
      try {
        final uri = Uri.https(
          'generativelanguage.googleapis.com',
          '/v1beta/models/$model:generateContent',
          {'key': _apiKey},
        );

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt}
                ]
              }
            ],
            "generationConfig": {
              "response_mime_type": "application/json",
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final contentText =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (contentText == null) continue;

          final cleanJson =
              contentText.replaceAll('```json', '').replaceAll('```', '').trim();
          final parsed = jsonDecode(cleanJson);

          final List rawItems = parsed['items'] ?? [];
          if (rawItems.isEmpty) continue;

          final validCategories = {
            'documents', 'packing', 'bookings', 'health', 'money', 'general'
          };

          int order = 0;
          final rows = <Map<String, dynamic>>[];
          for (final item in rawItems) {
            final text = (item['text'] ?? '').toString().trim();
            var cat = (item['category'] ?? 'general').toString().toLowerCase();
            if (!validCategories.contains(cat)) cat = 'general';
            if (text.isEmpty) continue;
            rows.add({
              'trip_id': trip.id,
              'user_id': _userId,
              'item_text': text,
              'category': cat,
              'is_auto_generated': true,
              'sort_order': order++,
            });
          }
          return rows;
        }

        // Model not found — try next
        if (response.statusCode == 404) continue;

        debugPrint('Gemini checklist error ($model): ${response.statusCode}');
      } catch (e) {
        debugPrint('Gemini model $model failed: $e');
        continue;
      }
    }

    return []; // All models failed → caller falls back to defaults
  }

  /// Assign a checklist item to a trip member
  Future<void> assignItem(String itemId, String? assignedToUserId) async {
    await _supabase
        .from('trip_checklist')
        .update({'assigned_to': assignedToUserId})
        .eq('id', itemId);
  }

  static String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}
