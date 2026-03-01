class PlaceInsights {
  final String id;
  final String googlePlaceId;
  final String? placeName;
  final Map<String, dynamic> insights;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PlaceInsights({
    required this.id,
    required this.googlePlaceId,
    this.placeName,
    required this.insights,
    this.createdAt,
    this.updatedAt,
  });

  factory PlaceInsights.fromJson(Map<String, dynamic> json) {
    return PlaceInsights(
      id: json['id'] as String,
      googlePlaceId: json['google_place_id'] as String,
      placeName: json['place_name'] as String?,
      insights: json['insights'] is Map<String, dynamic>
          ? json['insights'] as Map<String, dynamic>
          : {},
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  // Convenience getters for AI insights
  String? get bestTimeToVisit => insights['best_time_to_visit'] as String?;
  String? get crowdLevel => insights['crowd_level'] as String?;
  String? get peakHours => insights['peak_hours'] as String?;
  String? get avgVisitDuration => insights['avg_visit_duration'] as String?;
  bool get ticketRequired => insights['ticket_required'] == true;
  String? get ticketPriceEstimate => insights['ticket_price_estimate'] as String?;
  bool get onlineBookingRecommended => insights['online_booking_recommended'] == true;
  String? get bookingUrl => insights['booking_url'] as String?;
  bool get onsiteBookingAvailable => insights['onsite_booking_available'] == true;
  String? get avgWaitingTime => insights['avg_waiting_time'] as String?;
  List<String> get insiderTips =>
      (insights['insider_tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  String? get isWorthVisiting => insights['is_worth_visiting'] as String?;
  bool get familyFriendly => insights['family_friendly'] == true;
  bool get budgetFriendly => insights['budget_friendly'] == true;

  // New B1 fields
  String? get safetyRating => insights['safety_rating'] as String?;
  bool get parkingAvailable => insights['parking_available'] == true;
  bool get nearbyRestrooms => insights['nearby_restrooms'] == true;
  bool get photographyAllowed => insights['photography_allowed'] != false;
  bool get wheelchairAccessible => insights['wheelchair_accessible'] == true;
  String? get estimatedCostPerPerson => insights['estimated_cost_per_person'] as String?;
  double? get recommendedDurationHours => (insights['recommended_duration_hours'] as num?)?.toDouble();
  String? get localTips => insights['local_tips'] as String?;

  /// Returns true if data is older than 90 days and should be re-enriched.
  bool get isStale {
    if (updatedAt == null) return true;
    return DateTime.now().difference(updatedAt!).inDays > 90;
  }
}
