import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip.dart';
import '../models/trip_template.dart';
import 'plan_service.dart';
import 'checklist_service.dart';

class TemplateService {
  final _supabase = Supabase.instance.client;
  final _planService = PlanService();
  final _checklistService = ChecklistService();

  String get _userId => _supabase.auth.currentUser!.id;

  // ── Fetch templates ──────────────────────────────────────────────

  /// Get current user's saved templates
  Future<List<TripTemplate>> getMyTemplates() async {
    final data = await _supabase
        .from('trip_templates')
        .select()
        .eq('created_by', _userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => TripTemplate.fromJson(e)).toList();
  }

  /// Get public templates (community)
  Future<List<TripTemplate>> getPublicTemplates({String? location}) async {
    var query = _supabase
        .from('trip_templates')
        .select()
        .eq('is_public', true);
    if (location != null && location.isNotEmpty) {
      query = query.ilike('location', '%$location%');
    }
    final data = await query.order('use_count', ascending: false).limit(30);
    return (data as List).map((e) => TripTemplate.fromJson(e)).toList();
  }

  // ── Save trip as template ────────────────────────────────────────

  /// Extract a reusable template from an existing trip
  Future<TripTemplate> saveFromTrip({
    required Trip trip,
    required String templateName,
    String? description,
    bool isPublic = false,
  }) async {
    // 1. Gather checklist items (strip user-specific data)
    final checklist = await _checklistService.getChecklist(trip.id);
    final checklistData = checklist.map((item) => {
          'text': item.itemText,
          'category': item.category,
        }).toList();

    // 2. Gather itinerary structure (strip IDs, keep structure)
    final days = await _planService.fetchTripPlan(trip.id);
    final itineraryData = days.map((day) => {
          'day_number': day.dayNumber,
          'summary': day.summary ?? '',
          'places': day.places
              .map((p) => {
                    'name': p.name,
                    'type': p.type,
                    'description': p.description ?? '',
                    'arrival_time': p.arrivalTime ?? '',
                  })
              .toList(),
        }).toList();

    // 3. Compute duration
    int duration = 3;
    if (trip.startDate != null && trip.endDate != null) {
      duration = trip.endDate!.difference(trip.startDate!).inDays + 1;
    } else if (days.isNotEmpty) {
      duration = days.length;
    }

    // 4. Extract budget allocations
    final budgetAllocations = trip.budgetAllocations;

    // 5. Get trip type from metadata
    final tripType =
        (trip.metadata?['trip_type'] as String?) ?? 'leisure';

    final template = TripTemplate(
      id: '', // will be assigned by DB
      createdBy: _userId,
      name: templateName,
      description: description,
      location: trip.location,
      tripType: tripType,
      durationDays: duration,
      budgetCurrency: trip.budgetCurrency,
      estimatedCost: trip.estimatedCost,
      budgetAllocations: budgetAllocations,
      checklistItems: checklistData,
      itinerary: itineraryData,
      coverImageUrl: trip.coverImageUrl,
      isPublic: isPublic,
      sourceTripId: trip.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final row = await _supabase
        .from('trip_templates')
        .insert(template.toInsertJson())
        .select()
        .single();

    return TripTemplate.fromJson(row);
  }

  // ── Apply template to new trip ───────────────────────────────────

  /// Create checklist items from a template for a given trip
  Future<void> applyChecklistFromTemplate(
      TripTemplate template, String tripId) async {
    if (template.checklistItems.isEmpty) return;

    final items = template.checklistItems.map((item) => {
          'trip_id': tripId,
          'user_id': _userId,
          'item_text': item['text'] ?? '',
          'category': item['category'] ?? 'general',
          'is_auto_generated': true,
          'sort_order': template.checklistItems.indexOf(item),
        }).toList();

    await _supabase.from('trip_checklist').insert(items);
  }

  /// Create itinerary days + places from a template for a given trip
  Future<void> applyItineraryFromTemplate(
      TripTemplate template, String tripId) async {
    if (template.itinerary.isEmpty) return;

    for (final dayData in template.itinerary) {
      final dayRow = await _supabase.from('trip_days').insert({
        'trip_id': tripId,
        'day_number': dayData['day_number'] ?? 1,
        'summary': dayData['summary'] ?? '',
      }).select().single();

      final dayId = dayRow['id'];
      final places = dayData['places'] as List<dynamic>? ?? [];
      if (places.isNotEmpty) {
        final placesData = places.asMap().entries.map((entry) => {
              'trip_day_id': dayId,
              'google_place_id': '', // Will need to be resolved later
              'name': entry.value['name'] ?? '',
              'type': entry.value['type'] ?? 'Place',
              'latitude': 0.0,
              'longitude': 0.0,
              'description': entry.value['description'] ?? '',
              'arrival_time': entry.value['arrival_time'] ?? '',
              'order_index': entry.key,
            }).toList();
        await _supabase.from('trip_plan_places').insert(placesData);
      }
    }
  }

  /// Increment usage counter when a template is used
  Future<void> incrementUseCount(String templateId) async {
    await _supabase.rpc('increment_counter', params: {
      'row_id': templateId,
      'table_name': 'trip_templates',
      'column_name': 'use_count',
    }).catchError((_) async {
      // Fallback: simple update if RPC doesn't exist
      try {
        final current = await _supabase
            .from('trip_templates')
            .select('use_count')
            .eq('id', templateId)
            .single();
        await _supabase.from('trip_templates').update({
          'use_count': (current['use_count'] ?? 0) + 1,
        }).eq('id', templateId);
      } catch (_) {}
    });
  }

  /// Delete a template
  Future<void> deleteTemplate(String templateId) async {
    await _supabase
        .from('trip_templates')
        .delete()
        .eq('id', templateId)
        .eq('created_by', _userId);
  }
}
