import 'package:isar/isar.dart';

part 'cached_profile.g.dart';

@collection
class CachedProfile {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id; // Supabase user UUID

  late String displayName;
  String? avatarUrl;
  String? bio;
  String? country;
  String? email;
  String? username;
  late DateTime lastSynced;
}
