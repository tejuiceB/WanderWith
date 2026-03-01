import 'package:isar/isar.dart';

part 'cached_gallery_photo.g.dart';

@collection
class CachedGalleryPhoto {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id; // Supabase UUID

  @Index()
  late String tripId;

  late String url;
  String? thumbnailUrl;
  late String uploadedBy;
  String? caption;
  DateTime? createdAt;
  late DateTime lastSynced;
}
