import 'user_profile.dart';

class Post {
  final String id;
  final String userId;
  final String? tripId;
  final String imageUrl;
  final List<String> imageUrls;
  final String? caption;
  final String? location;
  final String visibility;
  final DateTime createdAt;
  final bool isDeleted;
  final bool isArchived;
  final List<String> hashtags;
  final List<String> mentions;
  
  // Enriched data (joined at runtime)
  final UserProfile? author;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  // Owner privacy flags (populated from joined profile data)
  final bool ownerHideLikeCount;
  final String ownerCommentPrivacy; // 'everyone', 'followers', 'nobody'

  Post({
    required this.id,
    required this.userId,
    this.tripId,
    required this.imageUrl,
    this.imageUrls = const [],
    this.caption,
    this.location,
    required this.visibility,
    required this.createdAt,
    this.isDeleted = false,
    this.isArchived = false,
    this.hashtags = const [],
    this.mentions = const [],
    this.author,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.ownerHideLikeCount = false,
    this.ownerCommentPrivacy = 'everyone',
  });

  factory Post.fromJson(Map<String, dynamic> json, {UserProfile? author, int? likeCount, int? commentCount, bool? isLiked}) {
    // Try to extract owner privacy settings from joined profile data
    final profileData = json['profiles'] ?? json['author'];
    final ownerHideLike = profileData is Map ? (profileData['hide_like_count'] ?? false) : (author?.hideLikeCount ?? false);
    final ownerCommentPrv = profileData is Map ? (profileData['comment_privacy'] ?? 'everyone') : (author?.commentPrivacy ?? 'everyone');

    return Post(
      id: json['id'],
      userId: json['user_id'],
      tripId: json['trip_id'],
      imageUrl: json['image_url'],
      imageUrls: (json['image_urls'] is List) ? List<String>.from(json['image_urls']) : [],
      caption: json['caption'],
      location: json['location'],
      visibility: json['visibility'] ?? 'public',
      createdAt: DateTime.parse(json['created_at']),
      isDeleted: json['is_deleted'] ?? false,
      isArchived: json['is_archived'] ?? false,
      hashtags: List<String>.from(json['hashtags'] ?? []),
      mentions: List<String>.from(json['mentions'] ?? []),
      author: author,
      likeCount: likeCount ?? json['like_count'] ?? 0,
      commentCount: commentCount ?? json['comment_count'] ?? 0,
      isLiked: isLiked ?? false,
      ownerHideLikeCount: ownerHideLike == true,
      ownerCommentPrivacy: ownerCommentPrv?.toString() ?? 'everyone',
    );
  }
}
