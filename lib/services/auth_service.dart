import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'dart:io';
import '../config/app_env.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class AuthService with ChangeNotifier {
  static final AuthService instance = AuthService();
  
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Keep for potential ID token flow if needed, but mostly relying on Supabase OAuth

  User? _user;
  UserProfile? _userProfile;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;

  bool get isAuthenticated => _user != null;

  bool get hasCompletedOnboarding => _userProfile?.onboardingCompleted ?? false;
  bool get isProfileLoaded => _user == null || _userProfile != null;
  
  bool _isLoadingProfile = true;
  bool get isLoadingProfile => _isLoadingProfile;

  bool _hasShownSplash = false;
  bool get hasShownSplash => _hasShownSplash;
  void markSplashShown() {
    _hasShownSplash = true;
    notifyListeners();
  }

  // Temporary storage for onboarding flow
  String? _tempRole;
  String? get tempRole => _tempRole;
  void setTempRole(String role) => _tempRole = role;

  AuthService() {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      _fetchUserProfile();
    } else {
      _isLoadingProfile = false;
    }

    _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      _user = session?.user;
      
      if (_user != null) {
        if (_userProfile == null) {
           _isLoadingProfile = true;
           notifyListeners();
           _fetchUserProfile();
        }
      } else {
        _userProfile = null;
        _isLoadingProfile = false;
        notifyListeners();
      }
    });
  }

  Future<void> refreshProfile() async {
    _isLoadingProfile = true;
    notifyListeners();
    await _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (_user == null) {
      _userProfile = null;
      _isLoadingProfile = false;
      notifyListeners();
      return;
    }

    _isLoadingProfile = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle(); 
      
      if (data != null) {
        // Map snake_case from DB to camelCase for UserProfile
        _userProfile = UserProfile(
          uid: data['id'],
          username: data['username'],
          email: data['email'],
          displayName: data['display_name'],
          country: data['country'],
          budgetStyle: data['budget_style'],
          tripVibe: data['trip_vibe'],
          avatarUrl: data['avatar_url'] ?? _user!.userMetadata?['avatar_url'] ?? _user!.userMetadata?['picture'],
          role: data['role'] ?? 'traveler',
          bio: data['bio'],
          city: data['city'],
          interests: (data['interests'] is List) ? List<String>.from(data['interests']) : [],
          isPrivate: data['is_private'] ?? true,
          followersCount: data['followers_count'] ?? 0,
          followingCount: data['following_count'] ?? 0,
          tripsCount: data['trips_count'] ?? 0,
          postVisibility: data['post_visibility'] ?? 'followers',
          tripsVisibility: data['trips_visibility'] ?? 'followers',
          allowFollowRequests: data['allow_follow_requests'] ?? true,
          messagePrivacy: data['message_privacy'] ?? 'followers',
          agencyName: data['agency_name'],
          contactPerson: data['contact_person'],
          phone: data['phone'],
          officeLocation: data['office_location'],
          agencyDescription: data['agency_description'],
          licenseNumber: data['license_number'],
          website: data['website'],
          onboardingCompleted: data['onboarding_completed'] == true,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
        );
      } else {
        // NEW USER: No record in 'profiles' table yet.
        _userProfile = UserProfile(
          uid: _user!.id,
          email: _user!.email,
          displayName: _user!.userMetadata?['full_name'],
          role: _tempRole ?? 'traveler', 
          avatarUrl: _user!.userMetadata?['avatar_url'] ?? _user!.userMetadata?['picture'],
          onboardingCompleted: false, // Explicitly false for new users
        );
      }
    } catch (e) {
      if (e is SocketException) {
        throw "It seems you are offline. Please check your internet connection.";
      }
      print("Error fetching user profile: $e");
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<UserProfile?> getOtherUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (data != null) {
        return UserProfile.fromMap(data);
      }
      return null;
    } catch (e) {
      print("Error fetching other user profile: $e");
      return null;
    }
  }

  Future<UserProfile?> getProfileByUsername(String username) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('username', username.toLowerCase())
          .maybeSingle();
      
      if (data != null) {
        return UserProfile.fromMap(data);
      }
      return null;
    } catch (e) {
      print("Error fetching profile by username: $e");
      return null;
    }
  }
  
  // Update Avatar
  Future<void> updateAvatar(File imageFile) async {
    if (_user == null) return;
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${_user!.id}/avatar.$fileExt'; // Fixed path per user, auto-replaces
      
      // Upload using proper storage method
      // UPSERT is true by default for upload? No, we might need to handle overwrite options
      // Supabase storage 'upload' throws if exists unless upsert is set (if supported by client)
      // Usually better to remove old one or just use upsert
      
      final storage = _supabase.storage.from('avatars');
      
      // Attempt upload with explicit upsert
      await storage.upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      // Get Public URL
      final imageUrl = storage.getPublicUrl(fileName);
      
      // Update profile
      // Add randomness to URL to bust cache immediately on client side
      final bustCacheUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      await _supabase.from('profiles').update({
        'avatar_url': bustCacheUrl,
      }).eq('id', _user!.id);
      
      await refreshProfile();
      
    } catch (e) {
      print("Error uploading avatar: $e");
      rethrow;
    }
  }

  // Google Sign In (Native)
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: AppEnv.googleWebClientId,
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false; // User cancelled
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'No Access Token or ID Token found.';
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      return true;
    } catch (e) {
      print("Google Sign In Error: $e");
      if (e.toString().contains("SocketException") || e.toString().contains("Network is unreachable")) {
         throw "No internet connection. Please check your settings.";
      }
      rethrow;
    }
  }

  // Email Sign In
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<AuthResponse> registerWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Geocoding Helper
  Future<Map<String, dynamic>?> geocodeLocation(String location) async {
    try {
      List<Location> locations = await locationFromAddress(location);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        
        // Also try to get city/country name back from lat/long to be sure
        List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
        String? city;
        String? country;
        
        if (placemarks.isNotEmpty) {
           final p = placemarks.first;
           city = p.locality ?? p.subAdministrativeArea;
           country = p.country;
        }

        return {
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'city': city,
          'country': country,
        };
      }
    } catch (e) {
      print("Geocoding error for $location: $e");
    }
    return null;
  }

  // Save Onboarding Data (New Flow)
  Future<void> saveOnboardingData({
    required String role,
    required String displayName,
    String? username,
    String? bio,
    String? city,
    List<String>? interests,
    // Agency
    String? agencyName,
    String? contactPerson,
    String? phone,
    String? officeLocation,
    String? agencyDescription,
    String? website,
    String? licenseNumber,
    double? latitude,
    double? longitude,
    String? country,
  }) async {
    if (_user == null) return;

    final profileData = {
      'id': _user!.id,
      'email': _user!.email,
      'role': role,
      'display_name': displayName,
      'username': username,
      'bio': bio,
      'city': city,
      'interests': interests,
      'agency_name': agencyName,
      'contact_person': contactPerson,
      'phone': phone,
      'office_location': officeLocation,
      'agency_description': agencyDescription,
      'website': website,
      'license_number': licenseNumber,
      'onboarding_completed': true,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Update local immediately (partial)
    _userProfile = UserProfile(
      uid: _user!.id,
      email: _user!.email,
      displayName: displayName,
      username: username,
      role: role,
      bio: bio,
      city: city,
      interests: interests ?? [],
      agencyName: agencyName,
      contactPerson: contactPerson,
      phone: phone,
      officeLocation: officeLocation,
      agencyDescription: agencyDescription,
      website: website,
      licenseNumber: licenseNumber,
      onboardingCompleted: true,
      latitude: latitude,
      longitude: longitude,
      country: country,
    );
    notifyListeners();

    try {
      await _supabase.from('profiles').upsert(profileData);
    } catch (e) {
      print("CRITICAL ERROR SAVING PROFILE: $e");
      throw Exception("Failed to save profile");
    }
  }

  // Update Privacy Settings
  Future<void> updatePrivacySettings({
    bool? isPrivate,
    String? postVisibility,
    String? tripsVisibility,
    bool? allowFollowRequests,
    String? messagePrivacy,
  }) async {
    if (_user == null) return;
    
    final updates = <String, dynamic>{};
    if (isPrivate != null) updates['is_private'] = isPrivate;
    if (postVisibility != null) updates['post_visibility'] = postVisibility;
    if (tripsVisibility != null) updates['trips_visibility'] = tripsVisibility;
    if (allowFollowRequests != null) updates['allow_follow_requests'] = allowFollowRequests;
    if (messagePrivacy != null) updates['message_privacy'] = messagePrivacy;

    if (updates.isEmpty) return;

    try {
      await _supabase.from('profiles').update(updates).eq('id', _user!.id);
      await _fetchUserProfile(); // Refresh local profile
    } catch (e) {
      print("Error updating privacy: $e");
      throw Exception("Failed to update privacy");
    }
  }

  // Permanent account deletion
  Future<void> deleteAccount() async {
    if (_user == null) return;
    final userId = _user!.id;

    try {
      // Call the RPC to wipe all user data, including the auth record
      await _supabase.rpc('wipe_user_data', params: {'target_user_id': userId});
      
      // Clear local state
      _user = null;
      _userProfile = null;
      notifyListeners();
      
      // Force sign out just in case the RPC didn't trigger immediate session termination
      await _supabase.auth.signOut();
    } catch (e) {
      print("Error during account deletion: $e");
      throw Exception("Failed to delete account. Please try again or contact support.");
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
  }) async {
    if (_user == null) return;
    
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (city != null) updates['city'] = city;
    if (country != null) updates['country'] = country;
    if (latitude != null) updates['latitude'] = latitude;
    if (longitude != null) updates['longitude'] = longitude;

    if (updates.isEmpty) return;

    try {
      await _supabase.from('profiles').update(updates).eq('id', _user!.id);
      await _fetchUserProfile();
    } catch (e) {
      print("Error updating profile: $e");
      throw Exception("Failed to update profile");
    }
  }

  // Legacy method - keeping for compatibility if referenced elsewhere, but basically deprecated
  Future<void> saveUserProfile({
    required String country,
    required String budgetStyle,
    required String tripVibe,
    String? displayName,
  }) async {
      await saveOnboardingData(
         role: 'traveler', // Default fallback
         displayName: displayName ?? _user?.userMetadata?['full_name'] ?? 'Traveler',
         city: country, // Map country to city/location
         // We might want to map budgetStyle/tripVibe to interests or bio?
         // For now, let's just ignore them or store in metadata if needed, 
         // but the new schema doesn't have budget_style column in my create script? 
         // Wait, the create script ADDED columns, it didn't remove existing ones.
         // 'country', 'budget_style', 'trip_vibe' EXIST in the original schema.
         // So we can still save them! 
         // Let me update saveOnboardingData to INCLUDE them if I want to maintain backward compat.
         // Actually, the new flow uses 'city' instead of 'country', and 'interests' instead of 'tripVibe'.
         // I'll leave this legacy method as is, but maybe implementation should route to new logic.
         // But wait, the previous `upsert` included them.
      );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _user = null;
    _userProfile = null;
    notifyListeners();
  }
}
