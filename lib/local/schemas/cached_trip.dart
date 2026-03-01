import 'package:isar/isar.dart';

part 'cached_trip.g.dart';

@collection
class CachedTrip {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id; // Supabase UUID

  late String name;
  late String location;
  DateTime? startDate;
  DateTime? endDate;
  late bool isDateDecided;
  late String createdBy;
  late List<String> memberIds;
  late List<String> adminIds;
  String? metadataJson; // Store full metadata as JSON string
  late String budgetCurrency;
  String? budgetOptionsJson;
  String? budgetVotesJson;
  String? coverImageUrl;
  late String visibility;
  String? joinCode;
  late DateTime lastSynced;
}
