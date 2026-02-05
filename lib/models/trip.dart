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

  // Computed Status
  String get status {
    final now = DateTime.now();
    if (endDate != null && now.isAfter(endDate!)) {
      return 'completed';
    }
    final hasBudget = estimatedCost > 0 || budgetAllocations.isNotEmpty;
    if (isDateDecided && hasBudget) {
      return 'confirmed';
    }
    return 'planning';
  }

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

  // REVIEWS getter
  // Structure: {userId: {rating: int, comment: String, timestamp: String}}
  Map<String, dynamic> get reviews =>
      (metadata != null && metadata!['reviews'] != null)
      ? Map<String, dynamic>.from(metadata!['reviews'])
      : {};

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
  }) : adminIds = adminIds ?? [createdBy];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isDateDecided': isDateDecided,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'metadata': metadata,
      'budgetCurrency': budgetCurrency,
      'budgetOptions': budgetOptions,
      'budgetVotes': budgetVotes,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Trip',
      location: map['location'] ?? 'Unknown',
      startDate: map['startDate'] != null ? DateTime.tryParse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.tryParse(map['endDate']) : null,
      isDateDecided: map['isDateDecided'] ?? true,
      createdBy: map['createdBy'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      adminIds: (map['adminIds'] != null) 
          ? List<String>.from(map['adminIds']) 
          : (map['created_by'] != null ? [map['created_by']] : []), // Fallback to creator
      metadata: map['metadata'],
      budgetCurrency: map['budgetCurrency'] ?? '\$',
      budgetOptions: map['budgetOptions'] != null ? Map<String, String>.from(map['budgetOptions'].map((k,v) => MapEntry(k, v.toString()))) : null,
      budgetVotes: map['budgetVotes'] != null ? Map<String, String>.from(map['budgetVotes']) : null,
    );
  }
}
