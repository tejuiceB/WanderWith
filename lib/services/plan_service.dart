import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip_plan.dart';

class PlanService {
  final supabase = Supabase.instance.client;

  Future<List<TripDay>> fetchTripPlan(String tripId) async {
    final response = await supabase
        .from('trip_days')
        .select('*, trip_plan_places(*)')
        .eq('trip_id', tripId)
        .order('day_number', ascending: true);

    final data = response as List<dynamic>;
    // Sort places by order_index within each day
    return data.map((json) {
      final day = TripDay.fromJson(json);
      day.places.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return day;
    }).toList();
  }

  Future<void> saveTripPlan(String tripId, List<TripDay> days) async {
    // 1. Clear existing plan (simple approach: delete all days for this trip)
    // In production, might want 'upsert' or differential updates
    await supabase.from('trip_days').delete().eq('trip_id', tripId);

    for (var day in days) {
      // 2. Insert Day
      final dayRes = await supabase.from('trip_days').insert({
        'trip_id': tripId,
        'day_number': day.dayNumber,
        'date': day.date?.toIso8601String(),
        'summary': day.summary,
      }).select().single();

      final dayId = dayRes['id'];

      // 3. Insert Places
      final placesData = day.places.map((p) {
        var json = p.toJson();
        json['trip_day_id'] = dayId; // Link to the new day ID
        return json;
      }).toList();

      if (placesData.isNotEmpty) {
        await supabase.from('trip_plan_places').insert(placesData);
      }
    }
  }

  Future<void> updatePlaceOrder(String placeId, int newIndex) async {
    await supabase
        .from('trip_plan_places')
        .update({'order_index': newIndex})
        .eq('id', placeId);
  }

  Future<void> deletePlace(String placeId) async {
    await supabase.from('trip_plan_places').delete().eq('id', placeId);
  }

  Future<Map<String, dynamic>> addPlace(Map<String, dynamic> placeJson) async {
    return await supabase.from('trip_plan_places').insert(placeJson).select().single();
  }
}
