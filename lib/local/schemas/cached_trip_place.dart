import 'package:isar/isar.dart';

part 'cached_trip_place.g.dart';

@collection
class CachedTripPlace {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id; // Supabase UUID

  @Index()
  late String tripDayId;

  late String googlePlaceId;
  late String name;
  late String type;
  late double latitude;
  late double longitude;
  String? imageUrl;
  String? arrivalTime;
  late int orderIndex;
  String? description;
  double? rating;
  String? aiInsight;
  late DateTime lastSynced;
}
