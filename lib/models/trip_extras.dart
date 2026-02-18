import 'package:supabase_flutter/supabase_flutter.dart';

class TripPoll {
  final String id;
  final String tripId;
  final String question;
  final String createdBy;
  final DateTime? endsAt;
  final bool isAnonymous;
  final bool allowMultiple;
  final bool isPinned;
  final DateTime createdAt;
  final List<PollOption> options;
  final List<PollVote> votes;

  TripPoll({
    required this.id,
    required this.tripId,
    required this.question,
    required this.createdBy,
    this.endsAt,
    this.isAnonymous = false,
    this.allowMultiple = false,
    this.isPinned = false,
    required this.createdAt,
    this.options = const [],
    this.votes = const [],
  });

  bool get isExpired => endsAt != null && DateTime.now().isAfter(endsAt!);

  factory TripPoll.fromMap(Map<String, dynamic> map, {List<PollOption> options = const [], List<PollVote> votes = const []}) {
    return TripPoll(
      id: map['id'],
      tripId: map['trip_id'],
      question: map['question'],
      createdBy: map['created_by'],
      endsAt: map['ends_at'] != null ? DateTime.parse(map['ends_at']) : null,
      isAnonymous: map['is_anonymous'] ?? false,
      allowMultiple: map['allow_multiple'] ?? false,
      isPinned: map['is_pinned'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      options: options,
      votes: votes,
    );
  }
}

class PollOption {
  final String id;
  final String pollId;
  final String optionText;

  PollOption({
    required this.id,
    required this.pollId,
    required this.optionText,
  });

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'],
      pollId: map['poll_id'],
      optionText: map['option_text'],
    );
  }
}

class PollVote {
  final String id;
  final String pollId;
  final String optionId;
  final String userId;

  PollVote({
    required this.id,
    required this.pollId,
    required this.optionId,
    required this.userId,
  });

  factory PollVote.fromMap(Map<String, dynamic> map) {
    return PollVote(
      id: map['id'],
      pollId: map['poll_id'],
      optionId: map['option_id'],
      userId: map['user_id'],
    );
  }
}

class PhotoReaction {
  final String id;
  final String photoId;
  final String userId;
  final String reaction;

  PhotoReaction({
    required this.id,
    required this.photoId,
    required this.userId,
    required this.reaction,
  });

  factory PhotoReaction.fromMap(Map<String, dynamic> map) {
    return PhotoReaction(
      id: map['id'],
      photoId: map['photo_id'],
      userId: map['user_id'],
      reaction: map['reaction'],
    );
  }
}
