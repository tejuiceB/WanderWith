class TripInternationalInfo {
  final String id;
  final String tripId;
  final String userCountry;
  final String destCountry;

  // Visa info
  final bool visaRequired;
  final String? visaType;
  final String? stayDuration;
  final String? processingTime;
  final String? visaApplyUrl;

  // Embassy info
  final String? embassyName;
  final String? embassyAddress;
  final String? embassyPhone;
  final String? embassyEmergencyNumber;
  final String? embassyEmail;

  // Emergency
  final String? localEmergencyNumber;
  final String? localPoliceNumber;
  final String? localMedicalNumber;

  // K2: Enhanced international fields
  final String? plugType;
  final String? tippingCustoms;
  final String? usefulPhrases;
  final String? simInfo;
  final String? passportReminder;
  final String? travelInsuranceNote;

  final DateTime? createdAt;

  TripInternationalInfo({
    required this.id,
    required this.tripId,
    required this.userCountry,
    required this.destCountry,
    this.visaRequired = false,
    this.visaType,
    this.stayDuration,
    this.processingTime,
    this.visaApplyUrl,
    this.embassyName,
    this.embassyAddress,
    this.embassyPhone,
    this.embassyEmergencyNumber,
    this.embassyEmail,
    this.localEmergencyNumber,
    this.localPoliceNumber,
    this.localMedicalNumber,
    this.plugType,
    this.tippingCustoms,
    this.usefulPhrases,
    this.simInfo,
    this.passportReminder,
    this.travelInsuranceNote,
    this.createdAt,
  });

  factory TripInternationalInfo.fromJson(Map<String, dynamic> json) {
    return TripInternationalInfo(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      userCountry: json['user_country'] as String,
      destCountry: json['dest_country'] as String,
      visaRequired: json['visa_required'] as bool? ?? false,
      visaType: json['visa_type'] as String?,
      stayDuration: json['stay_duration'] as String?,
      processingTime: json['processing_time'] as String?,
      visaApplyUrl: json['visa_apply_url'] as String?,
      embassyName: json['embassy_name'] as String?,
      embassyAddress: json['embassy_address'] as String?,
      embassyPhone: json['embassy_phone'] as String?,
      embassyEmergencyNumber: json['embassy_emergency_number'] as String?,
      embassyEmail: json['embassy_email'] as String?,
      localEmergencyNumber: json['local_emergency_number'] as String?,
      localPoliceNumber: json['local_police_number'] as String?,
      localMedicalNumber: json['local_medical_number'] as String?,
      plugType: json['plug_type'] as String?,
      tippingCustoms: json['tipping_customs'] as String?,
      usefulPhrases: json['useful_phrases'] as String?,
      simInfo: json['sim_info'] as String?,
      passportReminder: json['passport_reminder'] as String?,
      travelInsuranceNote: json['travel_insurance_note'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'user_country': userCountry,
      'dest_country': destCountry,
      'visa_required': visaRequired,
      'visa_type': visaType,
      'stay_duration': stayDuration,
      'processing_time': processingTime,
      'visa_apply_url': visaApplyUrl,
      'embassy_name': embassyName,
      'embassy_address': embassyAddress,
      'embassy_phone': embassyPhone,
      'embassy_emergency_number': embassyEmergencyNumber,
      'embassy_email': embassyEmail,
      'local_emergency_number': localEmergencyNumber,
      'local_police_number': localPoliceNumber,
      'local_medical_number': localMedicalNumber,
      'plug_type': plugType,
      'tipping_customs': tippingCustoms,
      'useful_phrases': usefulPhrases,
      'sim_info': simInfo,
      'passport_reminder': passportReminder,
      'travel_insurance_note': travelInsuranceNote,
    };
  }
}
