import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart'; // Add uuid package if needed for temp IDs or rely on Supabase
import '../models/trip.dart';
import '../models/trip_plan.dart';
import '../services/gemini_service.dart';
import '../services/plan_service.dart';
import '../services/google_places_service.dart';
import '../services/directions_service.dart';

class PlanProvider with ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final PlanService _planService = PlanService();
  final GooglePlacesService _placesService = GooglePlacesService();
  final DirectionsService _directionsService = DirectionsService();

  List<TripDay> _days = [];
  bool _isLoading = false;
  String _loadingStatus = "Loading...";
  int _selectedDayIndex = 0;
  int? _selectedPlaceIndex;
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
    _selectedPlaceIndex = null;
    _updateMap();
    notifyListeners();
  }

  void selectPlace(int? index) {
    _selectedPlaceIndex = index;
    _updateMap();
    notifyListeners();
  }

  Future<void> _updateMap() async {
    _markers.clear();
    _polylines.clear();
    if (_days.isEmpty) return;
    
    final currentTripDay = _days[_selectedDayIndex];
    if (currentTripDay.places.isEmpty) return;
    
    for (int i=0; i < currentTripDay.places.length; i++) {
      final place = currentTripDay.places[i];
      final isSelected = _selectedPlaceIndex == i;
      
      _markers.add(
        Marker(
          markerId: MarkerId(place.googlePlaceId.isNotEmpty ? place.googlePlaceId : place.id),
          position: place.latLng,
          infoWindow: InfoWindow(title: place.name, snippet: "Stop ${i + 1}"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueViolet
          ),
          zIndex: isSelected ? 10 : 1,
        ),
      );
    }
    
    if (currentTripDay.places.length > 1) {
      final origin = currentTripDay.places.first.latLng;
      final destination = currentTripDay.places.last.latLng;
      final waypoints = currentTripDay.places.length > 2 
          ? currentTripDay.places.sublist(1, currentTripDay.places.length - 1).map((e) => e.latLng).toList()
          : <LatLng>[];

      final directions = await _directionsService.getDirections(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
      );

      if (directions != null && directions['points'] != null) {
        final List<LatLng> points = directions['points'] as List<LatLng>;
        
        // Add travel time labels at midpoints of legs if available
        if (directions['legs'] != null) {
           final legs = directions['legs'] as List;
           for (var leg in legs) {
             final duration = leg['duration']['text'];
             final stepMidpoint = leg['end_location']; // Roughly at the end of leg
             _markers.add(Marker(
               markerId: MarkerId("time_${leg['duration']['value']}"),
               position: LatLng(stepMidpoint['lat'], stepMidpoint['lng']),
               icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Placeholder for bubble
               alpha: 0.7,
               infoWindow: InfoWindow(title: "Travel Time: $duration"),
             ));
           }
        }

        _polylines.add(Polyline(
          polylineId: const PolylineId("day_route"),
          points: points,
          color: const Color(0xFF6C63FF).withOpacity(0.8),
          width: 5,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ));
        
        // Add a soft glow effect with a wider, semi-transparent polyline
        _polylines.add(Polyline(
          polylineId: const PolylineId("day_route_glow"),
          points: points,
          color: const Color(0xFF6C63FF).withOpacity(0.2),
          width: 12,
          geodesic: true,
          jointType: JointType.round,
        ));
      } else {
        // Fallback to connecting dots if API fails
        List<LatLng> points = currentTripDay.places.map((e) => e.latLng).toList();
        _polylines.add(Polyline(
          polylineId: const PolylineId("day_route_fallback"),
          points: points,
          color: const Color(0xFF6C63FF),
          width: 4,
          geodesic: true,
        ));
      }
    }
    notifyListeners();
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

  List<Map<String, dynamic>> _autocompleteSuggestions = [];
  List<Map<String, dynamic>> _aiSuggestions = [];
  List<Map<String, dynamic>> _nearbyPlaces = [];
  Map<String, dynamic>? _previewPlace;
  bool _isSearching = false;
  bool _isSuggestionsLoading = false;

  List<Map<String, dynamic>> get autocompleteSuggestions => _autocompleteSuggestions;
  List<Map<String, dynamic>> get aiSuggestions => _aiSuggestions;
  List<Map<String, dynamic>> get nearbyPlaces => _nearbyPlaces;
  Map<String, dynamic>? get previewPlace => _previewPlace;
  bool get isSearching => _isSearching;
  bool get isSuggestionsLoading => _isSuggestionsLoading;

  // Autocomplete
  Future<void> getAutocomplete(String query) async {
    if (query.isEmpty) {
      _autocompleteSuggestions = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    _autocompleteSuggestions = await _placesService.getAutocompleteSuggestions(query);
    _isSearching = false;
    notifyListeners();
  }

  Future<void> fetchSuggestions(Trip trip, int dayNumber) async {
    print("PlanProvider: Fetching AI/Nearby suggestions for Day $dayNumber");
    _isSuggestionsLoading = true;
    notifyListeners();

    try {
      if (_days.isEmpty) {
        print("PlanProvider: Cannot fetch suggestions, _days is empty.");
        return;
      }
      
      final currentDay = _days.firstWhere((d) => d.dayNumber == dayNumber, orElse: () => _days.first);
      final existingNames = currentDay.places.map((p) => p.name).toList();
      
      // Get AI Suggestions
      final aiRecs = await _geminiService.getAIPlaceSuggestions(
        trip: trip, 
        dayNumber: dayNumber, 
        existingActivities: existingNames
      );
      
      _aiSuggestions = aiRecs;

      // Get Nearby Suggestions if we have current places
      if (currentDay.places.isNotEmpty) {
        final lastPlace = currentDay.places.last;
        _nearbyPlaces = await _placesService.searchNearby(lastPlace.latitude, lastPlace.longitude);
      }
    } catch (e) {
      print("PlanProvider Error in fetchSuggestions: $e");
    } finally {
      _isSuggestionsLoading = false;
      notifyListeners();
    }
  }

  // Preview Place
  Future<void> getPlaceDetailsForPreview(String placeId) async {
    _isLoading = true;
    notifyListeners();
    _previewPlace = await _placesService.getPlaceDetails(placeId);
    _isLoading = false;
    notifyListeners();
  }

  void clearPreview() {
    _previewPlace = null;
    notifyListeners();
  }

  void clearSearch() {
    _autocompleteSuggestions = [];
    _isSearching = false;
    notifyListeners();
  }

  // Add Place Manually (Enhanced)
  Future<void> addPlace(String dayId, Map<String, dynamic> placeData, {String? arrivalTime}) async {
    print("PlanProvider: Adding place ${placeData['name']} to day $dayId");
    
    final dayIndex = _days.indexWhere((d) => d.id == dayId);
    if (dayIndex == -1) {
      print("PlanProvider Error: Day ID $dayId not found in local state.");
      throw Exception("Target day not found. Please refresh and try again.");
    }
    
    _isLoading = true;
    _loadingStatus = "Adding to your timeline...";
    notifyListeners();

    try {
      int newOrderIndex = _days[dayIndex].places.length;
      final loc = placeData['location']; 
      
      if (loc == null || loc['latitude'] == null || loc['longitude'] == null) {
        throw Exception("Place location data is missing.");
      }

      // Dedup check: prevent adding a place that already exists in the trip
      final googlePlaceId = placeData['place_id'] as String?;
      if (googlePlaceId != null && googlePlaceId.isNotEmpty) {
        final alreadyExists = _days.any((day) =>
            day.places.any((p) => p.googlePlaceId == googlePlaceId));
        if (alreadyExists) {
          throw Exception('This place is already in your trip plan.');
        }
      }

      final newPlaceData = {
        'trip_day_id': dayId,
        'name': placeData['name'],
        'type': placeData['type'] ?? 'Custom',
        'order_index': newOrderIndex,
        'arrival_time': arrivalTime ?? '12:00',
        'latitude': (loc['latitude'] as num).toDouble(),
        'longitude': (loc['longitude'] as num).toDouble(),
        'google_place_id': placeData['place_id'],
        'image_url': placeData['image_url'],
        'description': placeData['summary'] ?? placeData['address'] ?? "Manually added",
        'rating': (placeData['rating'] as num?)?.toDouble(),
        // 'ai_insight': placeData['summary'], // Column missing in DB
      };

      print("PlanProvider: Persisting new place to DB...");
      final savedPlaceRaw = await _planService.addPlace(newPlaceData);
      final newPlace = TripPlanPlace.fromJson(savedPlaceRaw);

      _days[dayIndex].places.add(newPlace);
      
      print("PlanProvider: Success. Updating map routes...");
      // RECAlCULATE ROUTE
      try {
        await _updateMap();
      } catch (mapErr) {
        print("PlanProvider Warning: Map update failed but place was saved: $mapErr");
        // We don't rethrow here because the place IS saved to DB and added to list.
      }
      
      notifyListeners();

    } catch (e) {
      print("PlanProvider Exception in addPlace: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate Plan (The "Magic" Button)
  Future<void> generatePlan(Trip trip) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Phase 1: Analyzing
      _loadingStatus = "Analyzing your trip details...";
      notifyListeners();
      
      final jsonPlan = await _geminiService.generateTripPlan(trip);
      if (jsonPlan['day_plans'] == null) throw Exception("Invalid AI Response");
      
      // Phase 2: Designing
      _loadingStatus = "Designing optimized routes...";
      notifyListeners();

      final rawDays = jsonPlan['day_plans'] as List;

      List<TripDay> newDays = [];

      // 2. Enrich & Store
      int totalDays = rawDays.length;
      for (int i = 0; i < totalDays; i++) {
        var dayData = rawDays[i];
        
        _loadingStatus = "Balancing sightseeing & food (Day ${i + 1})...";
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
            String? aiInsight = act['ai_insight'];
            
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

                // Combine AI insight into description to avoid data loss
                String fullDescription = "";
                if (aiInsight != null && aiInsight.isNotEmpty) {
                  fullDescription = "✨ AI Insight: $aiInsight\n\n";
                }
                fullDescription += specificDesc;

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
                    description: fullDescription,
                    // aiInsight: aiInsight // Removed as column missing in DB
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

      // Phase 3.5: Deduplicate places across all days by google_place_id
      final Set<String> seenPlaceIds = {};
      for (final day in newDays) {
        day.places.removeWhere((place) {
          final gid = place.googlePlaceId;
          if (gid != null && gid.isNotEmpty && seenPlaceIds.contains(gid)) {
            debugPrint('Dedup: removed duplicate place "${place.name}" (google_place_id: $gid)');
            return true;
          }
          if (gid != null && gid.isNotEmpty) {
            seenPlaceIds.add(gid);
          }
          return false;
        });
        // Re-index order after removal
        for (int j = 0; j < day.places.length; j++) {
          day.places[j] = TripPlanPlace(
            id: day.places[j].id,
            tripDayId: day.places[j].tripDayId,
            googlePlaceId: day.places[j].googlePlaceId,
            name: day.places[j].name,
            type: day.places[j].type,
            latitude: day.places[j].latitude,
            longitude: day.places[j].longitude,
            imageUrl: day.places[j].imageUrl,
            arrivalTime: day.places[j].arrivalTime,
            orderIndex: j,
            rating: day.places[j].rating,
            description: day.places[j].description,
          );
        }
      }

      // Phase 4: Finalizing
      _loadingStatus = "Finalizing your perfect plan...";
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
