class UserProfile {
  final String uid;
  final String? username;
  final String? email;
  final String? displayName;
  final String? country;
  final String? budgetStyle; // Budget, Mid, Luxury
  final String? tripVibe; // Chill, Adventure, Party
  final String? avatarUrl;
  final String? coverImageUrl;

  // Social Links
  final String? instagramUrl;
  final String? twitterUrl;
  final String? youtubeUrl;
  final List<String> otherUrls;

  // New Onboarding Fields
  final String role; // 'traveler' or 'agency'
  final String? bio;
  final String? city;
  final List<String> interests;
  final bool isPrivate;
  final int followersCount;
  final int followingCount;
  final int tripsCount;
  // Privacy Fields
  final String postVisibility; // 'public', 'followers'
  final String tripsVisibility; // 'public', 'followers', 'private'
  final bool allowFollowRequests;
  final String messagePrivacy; // 'everyone', 'followers', 'nobody'
  final bool onboardingCompleted;
  final double? latitude;
  final double? longitude;

  // Agency Specific
  final String? agencyName;
  final String? contactPerson;
  final String? phone;
  final String? officeLocation;
  final String? agencyDescription;
  final String? licenseNumber;
  final String? website;

  final bool uploadHdPosts;

  // New onboarding fields
  final DateTime? dateOfBirth;
  final List<String> specializations;
  final int? yearEstablished;
  final bool emailVerified;

  UserProfile({
    required this.uid,
    this.username,
    this.email,
    this.displayName,
    this.country,
    this.budgetStyle,
    this.tripVibe,
    this.avatarUrl,
    this.coverImageUrl,
    this.instagramUrl,
    this.twitterUrl,
    this.youtubeUrl,
    this.otherUrls = const [],
    this.role = 'traveler',
    this.bio,
    this.city,
    this.interests = const [],
    this.isPrivate = true,
    this.followersCount = 0,
    this.followingCount = 0,
    this.tripsCount = 0,
    this.postVisibility = 'followers',
    this.tripsVisibility = 'followers',
    this.allowFollowRequests = true,
    this.messagePrivacy = 'followers',
    this.agencyName,
    this.contactPerson,
    this.phone,
    this.officeLocation,
    this.agencyDescription,
    this.licenseNumber,
    this.website,
    this.uploadHdPosts = false,
    this.onboardingCompleted = false,
    this.latitude,
    this.longitude,
    this.dateOfBirth,
    this.specializations = const [],
    this.yearEstablished,
    this.emailVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'display_name': displayName,
      'country': country,
      'budget_style': budgetStyle,
      'trip_vibe': tripVibe,
      'avatar_url': avatarUrl,
      'cover_image_url': coverImageUrl,
      'instagram_url': instagramUrl,
      'twitter_url': twitterUrl,
      'youtube_url': youtubeUrl,
      'other_urls': otherUrls,
      'role': role,
      'bio': bio,
      'city': city,
      'interests': interests,
      'is_private': isPrivate,
      'followers_count': followersCount,
      'following_count': followingCount,
      'trips_count': tripsCount,
      'post_visibility': postVisibility,
      'trips_visibility': tripsVisibility,
      'allow_follow_requests': allowFollowRequests,
      'message_privacy': messagePrivacy,
      'agency_name': agencyName,
      'contact_person': contactPerson,
      'phone': phone,
      'office_location': officeLocation,
      'agency_description': agencyDescription,
      'license_number': licenseNumber,
      'website': website,
      'upload_hd_posts': uploadHdPosts,
      'onboarding_completed': onboardingCompleted,
      'latitude': latitude,
      'longitude': longitude,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'specializations': specializations,
      'year_established': yearEstablished,
      'email_verified': emailVerified,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['id'] ?? map['uid'] ?? '',
      username: map['username'],
      email: map['email'],
      displayName: map['display_name'] ?? map['displayName'],
      country: map['country'],
      budgetStyle: map['budget_style'] ?? map['budgetStyle'],
      tripVibe: map['trip_vibe'] ?? map['tripVibe'],
      avatarUrl: map['avatar_url'] ?? map['avatarUrl'],
      coverImageUrl: map['cover_image_url'] ?? map['coverImageUrl'],
      instagramUrl: map['instagram_url'] ?? map['instagramUrl'],
      twitterUrl: map['twitter_url'] ?? map['twitterUrl'],
      youtubeUrl: map['youtube_url'] ?? map['youtubeUrl'],
      otherUrls: (map['other_urls'] is List) ? List<String>.from(map['other_urls']) : [],
      role: map['role'] ?? 'traveler',
      bio: map['bio'],
      city: map['city'],
      interests: (map['interests'] is List) ? List<String>.from(map['interests']) : [],
      isPrivate: map['is_private'] ?? map['isPrivate'] ?? true,
      followersCount: map['followers_count'] ?? map['followersCount'] ?? 0,
      followingCount: map['following_count'] ?? map['followingCount'] ?? 0,
      tripsCount: map['trips_count'] ?? map['tripsCount'] ?? 0,
      postVisibility: map['post_visibility'] ?? 'followers',
      tripsVisibility: map['trips_visibility'] ?? 'followers',
      allowFollowRequests: map['allow_follow_requests'] ?? true,
      messagePrivacy: map['message_privacy'] ?? 'followers',
      agencyName: map['agency_name'] ?? map['agencyName'],
      contactPerson: map['contact_person'] ?? map['contactPerson'],
      phone: map['phone'],
      officeLocation: map['office_location'] ?? map['officeLocation'],
      agencyDescription: map['agency_description'] ?? map['agencyDescription'],
      licenseNumber: map['license_number'] ?? map['licenseNumber'],
      website: map['website'],
      uploadHdPosts: map['upload_hd_posts'] ?? map['uploadHdPosts'] ?? false,
      onboardingCompleted: map['onboarding_completed'] ?? map['onboardingCompleted'] ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      dateOfBirth: map['date_of_birth'] != null ? DateTime.tryParse(map['date_of_birth']) : null,
      specializations: (map['specializations'] is List) ? List<String>.from(map['specializations']) : [],
      yearEstablished: map['year_established'] as int?,
      emailVerified: map['email_verified'] ?? false,
    );
  }
}
