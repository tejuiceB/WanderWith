import 'package:isar/isar.dart';

part 'pending_action.g.dart';

@collection
class PendingAction {
  Id id = Isar.autoIncrement;

  late String actionType; // 'add_plan_place', 'upload_photo', 'add_expense', etc.
  late String payloadJson; // JSON-encoded parameters
  late DateTime createdAt;
  late int retryCount;
  String? errorMessage;
}
