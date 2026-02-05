import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart'; // Add uuid package if needed for temp IDs or rely on Supabase
import '../models/trip.dart';
import '../models/trip_plan.dart';
import '../services/gemini_service.dart';
import '../services/plan_service.dart';
import '../services/google_places_service.dart';

class PlanProvider with ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final PlanService _planService = PlanService();
  final GooglePlacesService _placesService = GooglePlacesService();

  List<TripDay> _days = [];
  bool _isLoading = false;
  String _loadingStatus = "Loading...";
  int _selectedDayIndex = 0;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  List<TripDay> get days => _days;
  bool get isLoading => _isLoading;
  String get loadingStatus => _loadingStatus;
  int get selectedDayIndex => _selectedDayIndex;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;

  // Add getters for current day view
  TripDay? get currentDay => _days.isNotEmpty && _selectedDayIndex < _days.length ? _days[_selectedDayIndex] : null;

  Future<void> loadPlan(String tripId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _days = await _planService.fetchTripPlan(tripId);
      if (_days.isNotEmpty) {
         // Reset selected index if out of bounds, or keep 0
        if (_selectedDayIndex >= _days.length) _selectedDayIndex = 0;
        _updateMap();
      }
    } catch (e) {
      print("Error loading plan: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDay(int index) {
    if (index < 0 || index >= _days.length) return;
    _selectedDayIndex = index;
    _updateMap();
    notifyListeners();
  }

  void _updateMap() {
    _markers.clear();
    _polylines.clear();
    if (_days.isEmpty) return;
    
    final currentTripDay = _days[_selectedDayIndex];
    
    List<LatLng> points = [];
    
    for (int i=0; i < currentTripDay.places.length; i++) {
      final place = currentTripDay.places[i];
      points.add(place.latLng);
      
      _markers.add(
        Marker(
          markerId: MarkerId(place.googlePlaceId.isNotEmpty ? place.googlePlaceId : place.name),
          position: place.latLng,
          infoWindow: InfoWindow(title: place.name, snippet: "Stop ${i + 1}"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }
    
    if (points.length > 1) {
      _polylines.add(Polyline(
        polylineId: const PolylineId("day_route"),
        points: points,
        color: const Color(0xFF6C63FF),
        width: 4,
        geodesic: true,
      ));
    }
  }

  // Reorder Logic
  Future<void> reorderPlace(int dayIndex, int oldIndex, int newIndex) async {
    if (dayIndex < 0 || dayIndex >= _days.length) return;
    
    var day = _days[dayIndex];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = day.places.removeAt(oldIndex);
    day.places.insert(newIndex, item);
    _updateMap(); // Update polyline route
    notifyListeners(); // Update UI immediately

    // Update backend
    // scalable way: update all indices for this day
    for (int i = 0; i < day.places.length; i++) {
      await _planService.updatePlaceOrder(day.places[i].id, i);
    }
  }

  Future<void> deletePlace(int dayIndex, int placeIndex) async {
    if (dayIndex < 0 || dayIndex >= _days.length) return;
    var day = _days[dayIndex];
    if (placeIndex < 0 || placeIndex >= day.places.length) return;

    final place = day.places[placeIndex];
    
    // Optimistic Update
    day.places.removeAt(placeIndex);
    _updateMap();
    notifyListeners();

    try {
      await _planService.deletePlace(place.id);
    } catch (e) {
      // Revert if failed
      day.places.insert(placeIndex, place);
      _updateMap();
      notifyListeners();
      print("Delete failed: $e");
      rethrow;
    }
  }

  // Add Place Manually
  Future<void> addPlace(String dayId, String query) async {
    // 1. Find the day in local state
    final dayIndex = _days.indexWhere((d) => d.id == dayId);
    if (dayIndex == -1) return;
    
    // Optimistic loading state could be handled here if we had a specific loader for "adding"
    // For now we might just let the UI show a loader or just wait.
    
    try {
      // 2. Search Google Places for details
      final placeDetails = await _placesService.searchPlace(query);
      if (placeDetails == null) {
        throw Exception("Could not find place '$query'");
      }

      // 3. Construct new place object
      // We need to determine the orderIndex. Let's put it at the end.
      int newOrderIndex = _days[dayIndex].places.length;
      
      final loc = placeDetails['location']; 
      
      // We need to construct a map similar to what we send to DB
      final newPlaceData = {
        'trip_day_id': dayId,
        'name': placeDetails['name'],
        'type': 'Custom', // or infer from types
        'order_index': newOrderIndex,
        'arrival_time': '12:00', // Default or ask user?
        'latitude': loc['latitude'],
        'longitude': loc['longitude'],
        'google_place_id': placeDetails['place_id'],
        'address': placeDetails['address'],
        'rating': placeDetails['rating'],
        'image_url': placeDetails['image_url'],
        'description': "Manually added place",
      };

      // 4. Save to DB and get back the full object with ID
      final savedPlaceRaw = await _planService.addPlace(newPlaceData);
      
      // 5. Convert to TripPlanPlace
      final newPlace = TripPlanPlace.fromJson(savedPlaceRaw);

      // 6. Update Local State
      _days[dayIndex].places.add(newPlace);
      
      // 7. Update Map
      _updateMap();
      notifyListeners();

    } catch (e) {
      print("Error adding place: $e");
      rethrow;
    }
  }

  // Generate Plan (The "Magic" Button)
  Future<void> generatePlan(Trip trip) async {
    _isLoading = true;
    _loadingStatus = "Consulting AI Travel Expert...";
    notifyListeners();

    try {
      // 1. AI Logic
      final jsonPlan = await _geminiService.generateTripPlan(trip);
      if (jsonPlan['day_plans'] == null) throw Exception("Invalid AI Response");
      
      _loadingStatus = "Processing Itinerary & Locations...";
      notifyListeners();

      final rawDays = jsonPlan['day_plans'] as List;

      List<TripDay> newDays = [];

      // 2. Enrich & Store
      int totalDays = rawDays.length;
      for (int i = 0; i < totalDays; i++) {
        var dayData = rawDays[i];
        
        _loadingStatus = "Designing Day ${i + 1} of $totalDays...";
        notifyListeners();

        final dayNum = dayData['day_number'];
        final dateStr = dayData['date']; // YYYY-MM-DD
        final summary = dayData['summary'];
        final activities = dayData['activities'] as List;

        List<TripPlanPlace> places = [];
        int index = 0;

        for (var act in activities) {
            String query = act['query_name'] ?? act['name'];
            String type = act['type'] ?? 'Place';
            String arrivalTime = act['start_time'] ?? '09:00';
            
            // Enrich with Google Places
            final placeDetails = await _placesService.searchPlace(query);
            
            if (placeDetails != null) {
                final loc = placeDetails['location']; // {latitude: ..., longitude: ...}
                double lat = loc['latitude'];
                double lng = loc['longitude'];
                String googleId = placeDetails['place_id'] ?? ''; // Fixed to use 'place_id' consistently
                String name = placeDetails['name'] ?? act['name'];
                
                String? photoUrl = placeDetails['image_url'];
                
                // Construct a better description from real data
                String specificDesc = "";
                if (placeDetails['type'] != null && placeDetails['type'].toString().isNotEmpty) {
                   String t = placeDetails['type'].toString().replaceAll('_', ' ').toUpperCase();
                   specificDesc += "$t\n";
                }
                if (placeDetails['address'] != null) {
                   specificDesc += placeDetails['address'];
                }
                // Fallback to day summary only if we got nothing from Google
                if (specificDesc.isEmpty) specificDesc = summary;

                places.add(TripPlanPlace(
                    id: const Uuid().v4(), 
                    tripDayId: '', 
                    googlePlaceId: googleId,
                    name: name,
                    type: type,
                    latitude: lat,
                    longitude: lng,
                    imageUrl: photoUrl,
                    arrivalTime: arrivalTime,
                    orderIndex: index++,
                    rating: (placeDetails['rating'] as num?)?.toDouble(),
                    description: specificDesc
                ));
            }
        }
        
        newDays.add(TripDay(
             id: const Uuid().v4(), 
             tripId: trip.id,
             dayNumber: dayNum,
             date: DateTime.tryParse(dateStr),
             summary: summary,
             places: places
        ));
      }

      _loadingStatus = "Finalizing & Saving Trip...";
      notifyListeners();

      // 3. Save to Supabase (Replaces old plan)
      await _planService.saveTripPlan(trip.id, newDays);
      
      // 4. Reload to get proper IDs from DB
      await loadPlan(trip.id);

    } catch (e) {
      print("Error generating plan: $e");
      rethrow;
    } finally {
      // stop loading status
      _isLoading = false;
      notifyListeners();
    }
  }
}
