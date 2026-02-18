import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripDay {
  final String id;
  final String tripId;
  final int dayNumber;
  final DateTime? date;
  final String? summary;
  final List<TripPlanPlace> places;

  TripDay({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    this.date,
    this.summary,
    this.places = const [],
  });

  factory TripDay.fromJson(Map<String, dynamic> json) {
    return TripDay(
      id: json['id'],
      tripId: json['trip_id'],
      dayNumber: json['day_number'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      summary: json['summary'],
      places: (json['trip_plan_places'] as List<dynamic>?)
              ?.map((e) => TripPlanPlace.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'day_number': dayNumber,
      'date': date?.toIso8601String(),
      'summary': summary,
    };
  }
}

class TripPlanPlace {
  final String id;
  final String tripDayId;
  final String googlePlaceId;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? arrivalTime;
  final int orderIndex;
  final String? description;
  final double? rating;
  final String? aiInsight;

  TripPlanPlace({
    required this.id,
    required this.tripDayId,
    required this.googlePlaceId,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.arrivalTime,
    required this.orderIndex,
    this.description,
    this.rating,
    this.aiInsight,
  });

  factory TripPlanPlace.fromJson(Map<String, dynamic> json) {
    return TripPlanPlace(
      id: json['id'] ?? '',
      tripDayId: json['trip_day_id'] ?? '',
      googlePlaceId: json['google_place_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Place',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
      arrivalTime: json['arrival_time'],
      orderIndex: json['order_index'] ?? 0,
      description: json['description'],
      rating: (json['rating'] as num?)?.toDouble(),
      aiInsight: json['ai_insight'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_day_id': tripDayId,
      'google_place_id': googlePlaceId,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'arrival_time': arrivalTime,
      'order_index': orderIndex,
      'description': description,
      'rating': rating,
      // 'ai_insight': aiInsight, // Removed as column doesn't exist in DB
    };
  }
  
  LatLng get latLng => LatLng(latitude, longitude);
}
