import 'package:isar/isar.dart';

part 'cached_trip_day.g.dart';

@collection
class CachedTripDay {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id; // Supabase UUID

  @Index()
  late String tripId;

  late int dayNumber;
  DateTime? date;
  String? summary;
  late DateTime lastSynced;
}
