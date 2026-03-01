class TripMetadata {
  final String id;
  final String tripId;
  final String? destinationCountryCode;
  final String? bestTimeToVisit;
  final String? bestTimeWeatherEmoji;
  final String? crowdLevel;
  final String? avgTempRange;
  final String? visaRequired;
  final String? currencyCode;
  final String? currencyName;
  final String? timezone;
  final String? language;
  final String? emergencyNumber;
  // K1: Domestic travel intelligence
  final String? localTransportTips;
  final String? simConnectivityInfo;
  final String? safetyTips;
  final String? localCustoms;
  final String? localFoodRecommendations;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TripMetadata({
    required this.id,
    required this.tripId,
    this.destinationCountryCode,
    this.bestTimeToVisit,
    this.bestTimeWeatherEmoji,
    this.crowdLevel,
    this.avgTempRange,
    this.visaRequired,
    this.currencyCode,
    this.currencyName,
    this.timezone,
    this.language,
    this.emergencyNumber,
    this.localTransportTips,
    this.simConnectivityInfo,
    this.safetyTips,
    this.localCustoms,
    this.localFoodRecommendations,
    this.createdAt,
    this.updatedAt,
  });

  factory TripMetadata.fromJson(Map<String, dynamic> json) {
    return TripMetadata(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      destinationCountryCode: json['destination_country_code'] as String?,
      bestTimeToVisit: json['best_time_to_visit'] as String?,
      bestTimeWeatherEmoji: json['best_time_weather_emoji'] as String?,
      crowdLevel: json['crowd_level'] as String?,
      avgTempRange: json['avg_temp_range'] as String?,
      visaRequired: json['visa_required'] as String?,
      currencyCode: json['currency_code'] as String?,
      currencyName: json['currency_name'] as String?,
      timezone: json['timezone'] as String?,
      language: json['language'] as String?,
      emergencyNumber: json['emergency_number'] as String?,
      localTransportTips: json['local_transport_tips'] as String?,
      simConnectivityInfo: json['sim_connectivity_info'] as String?,
      safetyTips: json['safety_tips'] as String?,
      localCustoms: json['local_customs'] as String?,
      localFoodRecommendations: json['local_food_recommendations'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'destination_country_code': destinationCountryCode,
      'best_time_to_visit': bestTimeToVisit,
      'best_time_weather_emoji': bestTimeWeatherEmoji,
      'crowd_level': crowdLevel,
      'avg_temp_range': avgTempRange,
      'visa_required': visaRequired,
      'currency_code': currencyCode,
      'currency_name': currencyName,
      'timezone': timezone,
      'language': language,
      'emergency_number': emergencyNumber,
      'local_transport_tips': localTransportTips,
      'sim_connectivity_info': simConnectivityInfo,
      'safety_tips': safetyTips,
      'local_customs': localCustoms,
      'local_food_recommendations': localFoodRecommendations,
    };
  }
}
