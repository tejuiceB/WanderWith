import 'package:isar/isar.dart';

part 'cached_message.g.dart';

@collection
class CachedMessage {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id; // Supabase UUID

  @Index()
  late String tripId;

  late String senderId;
  late String senderName;
  late String text;
  late String messageType; // 'text', 'image', 'system'
  String? imageUrl;
  DateTime? createdAt;
  late DateTime lastSynced;
}
