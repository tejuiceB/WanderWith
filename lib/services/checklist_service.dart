import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/checklist_item.dart';

class ChecklistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

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
}
