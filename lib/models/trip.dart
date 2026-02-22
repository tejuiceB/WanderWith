class Trip {
  final String id;
  final String name;
  final String location;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isDateDecided;
  final String createdBy; // User UID
  final List<String> memberIds;
  final List<String> adminIds; // List of Uid
  final Map<String, dynamic>? metadata; // Budget/Theme tags
  // New Budget Fields
  final String budgetCurrency;
  final Map<String, String>? budgetOptions;
  final Map<String, String>? budgetVotes; // {userId: 'low'|'mid'|'high'}
  final String? coverImageUrl;
  final String visibility; // 'public', 'private'
  final String? joinCode;

  // Computed Status
  String get status {
    final now = DateTime.now();
    if (isDead) return 'dead'; // Explicitly mark it dead if dead
    if (endDate != null && now.isAfter(endDate!)) {
      return 'completed';
    }
    final hasBudget = estimatedCost > 0 || budgetAllocations.isNotEmpty;
    if (isDateDecided && hasBudget) {
      return 'confirmed';
    }
    return 'planning';
  }

  // DEAD STATE getter
  bool get isDead =>
      (metadata != null && metadata!['is_dead'] == true);

  // Polls getter
  List<Map<String, dynamic>> get polls => 
      (metadata != null && metadata!['polls'] != null)
      ? List<Map<String, dynamic>>.from(metadata!['polls'])
      : [];
  // PENDING MEMBERS getter (New)
  List<String> get pendingMembers =>
      (metadata != null && metadata!['pending_members'] != null)
      ? List<String>.from(metadata!['pending_members'])
      : [];

  // REJECTED MEMBERS getter (New)
  List<String> get rejectedMembers =>
      (metadata != null && metadata!['rejected_members'] != null)
      ? List<String>.from(metadata!['rejected_members'])
      : [];

  // REVIEWS getter
  // Structure: {userId: {rating: int, comment: String, timestamp: String}}
  Map<String, dynamic> get reviews =>
      (metadata != null && metadata!['reviews'] != null)
      ? Map<String, dynamic>.from(metadata!['reviews'])
      : {};

  // ABOUT getter (New)
  String? get about =>
      (metadata != null && metadata!['about'] != null)
      ? metadata!['about'] as String
      : null;

  // BUDGET getters (New single-budget + allocations model)
  double get estimatedCost =>
      (metadata != null && metadata!['estimated_cost'] != null)
      ? (metadata!['estimated_cost'] is int ? (metadata!['estimated_cost'] as int).toDouble() : metadata!['estimated_cost'])
      : 0.0;

  List<Map<String, dynamic>> get budgetAllocations =>
      (metadata != null && metadata!['budget_allocations'] != null)
      ? List<Map<String, dynamic>>.from(metadata!['budget_allocations'])
      : [];

  Trip({
    required this.id,
    required this.name,
    required this.location,
    this.startDate,
    this.endDate,
    this.isDateDecided = false,
    required this.createdBy,
    required this.memberIds,
    List<String>? adminIds,
    this.metadata,
    this.budgetCurrency = '\$', 
    this.budgetOptions,
    this.budgetVotes,
    this.coverImageUrl,
    this.visibility = 'public',
    this.joinCode,
  }) : adminIds = adminIds ?? [createdBy];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_date_decided': isDateDecided,
      'created_by': createdBy,
      'member_ids': memberIds,
      'admin_ids': adminIds,
      'metadata': metadata,
      'budget_currency': budgetCurrency,
      'budget_options': budgetOptions,
      'budget_votes': budgetVotes,
      'cover_image_url': coverImageUrl,
      'visibility': visibility,
      'join_code': joinCode,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    // Helper to check multiple key formats
    dynamic get(String camel, String snake) => map[camel] ?? map[snake];

    return Trip(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Trip',
      location: map['location'] ?? 'Unknown',
      startDate: map['startDate'] != null || map['start_date'] != null 
          ? DateTime.tryParse(get('startDate', 'start_date')) 
          : null,
      endDate: map['endDate'] != null || map['end_date'] != null 
          ? DateTime.tryParse(get('endDate', 'end_date')) 
          : null,
      isDateDecided: map['isDateDecided'] ?? map['is_date_decided'] ?? true,
      createdBy: get('createdBy', 'created_by') ?? '',
      memberIds: List<String>.from(get('memberIds', 'member_ids') ?? []),
      adminIds: List<String>.from(get('adminIds', 'admin_ids') ?? []),
      metadata: map['metadata'],
      budgetCurrency: get('budgetCurrency', 'budget_currency') ?? '\$',
      budgetOptions: map['budgetOptions'] != null || map['budget_options'] != null 
          ? Map<String, String>.from(get('budgetOptions', 'budget_options').map((k,v) => MapEntry(k, v.toString()))) 
          : null,
      budgetVotes: map['budgetVotes'] != null || map['budget_votes'] != null 
          ? Map<String, String>.from(get('budgetVotes', 'budget_votes')) 
          : null,
      coverImageUrl: map['cover_image_url'],
      visibility: map['visibility'] ?? 'public',
      joinCode: map['join_code'],
    );
  }
}
