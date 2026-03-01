import 'package:isar/isar.dart';

part 'cached_trip_link.g.dart';

@collection
class CachedTripLink {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id; // Supabase UUID

  @Index()
  late String tripId;

  late String title;
  late String url;
  late String addedBy;
  String? previewImageUrl;
  String? previewTitle;
  DateTime? createdAt;
  late DateTime lastSynced;
}
