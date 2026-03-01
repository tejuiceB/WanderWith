import 'package:isar/isar.dart';

part 'cached_poll.g.dart';

@collection
class CachedPoll {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id; // Supabase UUID

  @Index()
  late String tripId;

  late String question;
  late String createdBy;
  late bool isAnonymous;
  late bool isMultiChoice;
  String? optionsJson; // JSON array of poll options with votes
  DateTime? createdAt;
  late DateTime lastSynced;
}
