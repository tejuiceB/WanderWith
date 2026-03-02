class TripTemplate {
  final String id;
  final String createdBy;
  final String name;
  final String? description;
  final String? location;
  final String tripType;
  final int durationDays;
  final String budgetCurrency;
  final double estimatedCost;
  final List<Map<String, dynamic>> budgetAllocations;
  final List<Map<String, dynamic>> checklistItems; // [{text, category}]
  final List<Map<String, dynamic>> itinerary;      // [{day_number, summary, places}]
  final String? coverImageUrl;
  final bool isPublic;
  final int useCount;
  final String? sourceTripId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripTemplate({
    required this.id,
    required this.createdBy,
    required this.name,
    this.description,
    this.location,
    this.tripType = 'leisure',
    this.durationDays = 3,
    this.budgetCurrency = 'USD',
    this.estimatedCost = 0,
    this.budgetAllocations = const [],
    this.checklistItems = const [],
    this.itinerary = const [],
    this.coverImageUrl,
    this.isPublic = false,
    this.useCount = 0,
    this.sourceTripId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripTemplate.fromJson(Map<String, dynamic> json) {
    return TripTemplate(
      id: json['id'] ?? '',
      createdBy: json['created_by'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      location: json['location'],
      tripType: json['trip_type'] ?? 'leisure',
      durationDays: json['duration_days'] ?? 3,
      budgetCurrency: json['budget_currency'] ?? 'USD',
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0,
      budgetAllocations: json['budget_allocations'] != null
          ? List<Map<String, dynamic>>.from(json['budget_allocations'])
          : [],
      checklistItems: json['checklist_items'] != null
          ? List<Map<String, dynamic>>.from(json['checklist_items'])
          : [],
      itinerary: json['itinerary'] != null
          ? List<Map<String, dynamic>>.from(json['itinerary'])
          : [],
      coverImageUrl: json['cover_image_url'],
      isPublic: json['is_public'] ?? false,
      useCount: json['use_count'] ?? 0,
      sourceTripId: json['source_trip_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'created_by': createdBy,
        'name': name,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
        'trip_type': tripType,
        'duration_days': durationDays,
        'budget_currency': budgetCurrency,
        'estimated_cost': estimatedCost,
        'budget_allocations': budgetAllocations,
        'checklist_items': checklistItems,
        'itinerary': itinerary,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        'is_public': isPublic,
        if (sourceTripId != null) 'source_trip_id': sourceTripId,
      };

  /// Friendly label for trip type
  String get tripTypeLabel {
    const labels = {
      'leisure': '🏖 Leisure',
      'backpacking': '🎒 Backpacking',
      'luxury': '💎 Luxury',
      'family': '👨‍👩‍👧 Family',
      'workation': '💼 Workation',
      'adventure': '🧗 Adventure',
      'romantic': '💕 Romantic',
      'solo': '🧘 Solo',
    };
    return labels[tripType] ?? tripType;
  }

  /// Duration as human-readable text
  String get durationLabel {
    if (durationDays == 1) return '1 day';
    if (durationDays <= 7) return '$durationDays days';
    final weeks = durationDays ~/ 7;
    final remaining = durationDays % 7;
    if (remaining == 0) return '$weeks week${weeks > 1 ? 's' : ''}';
    return '$weeks week${weeks > 1 ? 's' : ''}, $remaining day${remaining > 1 ? 's' : ''}';
  }
}
