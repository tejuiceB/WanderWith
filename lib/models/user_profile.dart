class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? country;
  final String? budgetStyle; // Budget, Mid, Luxury
  final String? tripVibe; // Chill, Adventure, Party
  final String? avatarUrl;

  UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.country,
    this.budgetStyle,
    this.tripVibe,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'country': country,
      'budgetStyle': budgetStyle,
      'tripVibe': tripVibe,
      'avatarUrl': avatarUrl,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      country: map['country'],
      budgetStyle: map['budgetStyle'],
      tripVibe: map['tripVibe'],
      avatarUrl: map['avatarUrl'], // internal usage
    );
  }
}
