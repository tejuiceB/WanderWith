class TripLink {
  final String id;
  final String tripId;
  final String title;
  final String url;
  final String category;
  final String? previewImage;
  final String? siteName;
  final String? description;
  final String addedBy;
  final bool isPinned;
  final DateTime createdAt;

  TripLink({
    required this.id,
    required this.tripId,
    required this.title,
    required this.url,
    required this.category,
    this.previewImage,
    this.siteName,
    this.description,
    required this.addedBy,
    this.isPinned = false,
    required this.createdAt,
  });

  factory TripLink.fromMap(Map<String, dynamic> map) {
    return TripLink(
      id: map['id'],
      tripId: map['trip_id'],
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      category: map['category'] ?? 'Other',
      previewImage: map['preview_image'],
      siteName: map['site_name'],
      description: map['description'],
      addedBy: map['added_by'],
      isPinned: map['is_pinned'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'url': url,
      'category': category,
      'preview_image': previewImage,
      'site_name': siteName,
      'description': description,
      'added_by': addedBy,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
