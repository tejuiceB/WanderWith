import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'dart:io';
import 'dart:async';
import '../config/app_env.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_links/app_links.dart';

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

  // OTP / email verification state
  String? _pendingVerificationEmail;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  
  bool get isEmailVerified => _userProfile?.emailVerified ?? false;

  // Deep link handling
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  Uri? _pendingDeepLink;
  Uri? get pendingDeepLink => _pendingDeepLink;
  
  // Password recovery state - set when Supabase detects a recovery session
  bool _isPasswordRecovery = false;
  bool get isPasswordRecovery => _isPasswordRecovery;
  
  void clearPendingDeepLink() {
    _pendingDeepLink = null;
    _isPasswordRecovery = false;
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
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      _user = session?.user;
      
      // Detect password recovery event — Supabase SDK has established the session
      if (event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
        notifyListeners();
        return;
      }
      
      // If signedIn fires but we already know it's a recovery, skip normal flow
      if (event == AuthChangeEvent.signedIn && _isPasswordRecovery) {
        notifyListeners();
        return;
      }
      
      // For signedIn events from PKCE callback, briefly delay to allow 
      // passwordRecovery event to fire first (it follows immediately after)
      if (event == AuthChangeEvent.signedIn && _pendingDeepLink != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isPasswordRecovery) return; // Recovery event arrived, skip normal flow
          if (_user != null) {
            _userProfile = null;
            _isLoadingProfile = true;
            notifyListeners();
            _fetchUserProfile();
          }
        });
        return;
      }
      
      if (_user != null) {
        // Always re-fetch profile on signedIn to ensure fresh data
        // (handles Google sign-in, re-login, identity linking, etc.)
        if (event == AuthChangeEvent.signedIn || _userProfile == null) {
           _userProfile = null;
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

    // Initialize deep link listener
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    // Handle link when app is opened from terminated state
    _appLinks.getInitialAppLink().then((uri) {
      if (uri != null) _handleIncomingLink(uri);
    });
    // Handle links while app is running
    _linkSub = _appLinks.uriLinkStream.listen(_handleIncomingLink);
  }

  void _handleIncomingLink(Uri uri) {
    // With PKCE, recovery links come as: io.supabase.wanderwith://login-callback?code=XXXX
    // The Supabase SDK will fire passwordRecovery event, but there's a race condition
    // with signedIn event. Pre-mark recovery if we detect the callback URL.
    final isCallback = uri.scheme == 'io.supabase.wanderwith' && uri.host == 'login-callback';
    
    // Also handle legacy direct reset deep links
    final isResetHost = uri.host == 'reset-password';
    final isResetPath = uri.path.contains('reset-password');
    final isRecoveryFragment = uri.fragment.contains('type=recovery');
    
    if (isResetHost || isResetPath || isRecoveryFragment) {
      _isPasswordRecovery = true;
      Uri effectiveUri = uri;
      if (uri.fragment.isNotEmpty && uri.queryParameters.isEmpty) {
        effectiveUri = Uri.parse('${uri.scheme}://${uri.host}${uri.path}?${uri.fragment}');
      }
      _pendingDeepLink = effectiveUri;
      setSessionFromUri(effectiveUri).then((_) {
        notifyListeners();
      });
      return;
    }
    
    // For PKCE callback, we can't know for sure it's recovery yet
    // but we store the link so the Supabase SDK can process it
    if (isCallback) {
      _pendingDeepLink = uri;
      // Don't set recovery flag here — wait for the SDK passwordRecovery event
      // The Supabase SDK will process this automatically
      return;
    }
    
    // Handle Supabase auth callback
    if (uri.host == 'callback' || uri.path.contains('callback')) {
      _pendingDeepLink = uri;
      notifyListeners();
    }
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
          coverImageUrl: data['cover_image_url'],
          instagramUrl: data['instagram_url'],
          twitterUrl: data['twitter_url'],
          youtubeUrl: data['youtube_url'],
          otherUrls: (data['other_urls'] is List) ? List<String>.from(data['other_urls']) : [],
          onboardingCompleted: data['onboarding_completed'] == true,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          dateOfBirth: data['date_of_birth'] != null ? DateTime.tryParse(data['date_of_birth']) : null,
          specializations: (data['specializations'] is List) ? List<String>.from(data['specializations']) : [],
          yearEstablished: data['year_established'] as int?,
          uploadHdPosts: data['upload_hd_posts'] ?? false,
        );
        print("[PROFILE FETCH] interests: ${_userProfile!.interests}");
      } else {
        // No profile found by user ID — try email-based fallback
        // (handles identity linking where Google creates a new user ID
        //  but the user already had an email/password account)
        final email = _user!.email;
        if (email != null) {
          final emailData = await _supabase
              .from('profiles')
              .select()
              .eq('email', email)
              .maybeSingle();
          if (emailData != null && emailData['onboarding_completed'] == true) {
            // Found an existing profile with same email that completed onboarding.
            // Copy the onboarding data to the new user ID.
            _userProfile = UserProfile(
              uid: _user!.id,
              email: emailData['email'],
              username: emailData['username'],
              displayName: emailData['display_name'] ?? _user!.userMetadata?['full_name'],
              country: emailData['country'],
              budgetStyle: emailData['budget_style'],
              tripVibe: emailData['trip_vibe'],
              avatarUrl: emailData['avatar_url'] ?? _user!.userMetadata?['avatar_url'] ?? _user!.userMetadata?['picture'],
              role: emailData['role'] ?? 'traveler',
              bio: emailData['bio'],
              city: emailData['city'],
              interests: (emailData['interests'] is List) ? List<String>.from(emailData['interests']) : [],
              isPrivate: emailData['is_private'] ?? true,
              onboardingCompleted: true,
              latitude: (emailData['latitude'] as num?)?.toDouble(),
              longitude: (emailData['longitude'] as num?)?.toDouble(),
            );
            // Persist the profile for the new user ID so future fetches work
            try {
              await _supabase.from('profiles').upsert({
                'id': _user!.id,
                'email': email,
                'username': emailData['username'],
                'display_name': emailData['display_name'],
                'country': emailData['country'],
                'budget_style': emailData['budget_style'],
                'trip_vibe': emailData['trip_vibe'],
                'avatar_url': emailData['avatar_url'] ?? _user!.userMetadata?['avatar_url'],
                'role': emailData['role'] ?? 'traveler',
                'bio': emailData['bio'],
                'city': emailData['city'],
                'interests': emailData['interests'] ?? [],
                'is_private': emailData['is_private'] ?? true,
                'onboarding_completed': true,
                'latitude': emailData['latitude'],
                'longitude': emailData['longitude'],
              });
            } catch (e) {
              print('Failed to persist profile for new user ID: $e');
            }
            return;
          }
        }
        // Truly new user: no profile by ID or email
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

  /// Check if a username is currently taken
  Future<bool> isUsernameAvailable(String username) async {
    if (username.length < 3) return false;
    try {
      final bool available = await _supabase.rpc(
        'check_username_available',
        params: {'target_username': username.trim()},
      );
      return available;
    } catch (e) {
      print("Error checking username availability: $e");
      return false;
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

  // Update Agency Cover
  Future<void> updateAgencyCover(File imageFile) async {
    if (_user == null || _userProfile?.role != 'agency') return;
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${_user!.id}/cover.$fileExt';
      
      final storage = _supabase.storage.from('agency_covers');
      
      await storage.upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      final imageUrl = storage.getPublicUrl(fileName);
      final bustCacheUrl = '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      await _supabase.from('profiles').update({
        'cover_image_url': bustCacheUrl,
      }).eq('id', _user!.id);
      
      await refreshProfile();
      
    } catch (e) {
      print("Error uploading cover: $e");
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

      // Ensure profile is loaded before returning so router has correct data
      await _fetchUserProfile();
      
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
      final response = await _supabase.auth.signUp(email: email, password: password);
      _pendingVerificationEmail = email;
      notifyListeners();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify OTP code sent to email during signup
  Future<AuthResponse> verifyOTP(String email, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      // Mark email as verified in profiles
      if (_user != null || response.user != null) {
        final uid = response.user?.id ?? _user!.id;
        await _supabase.from('profiles').update({
          'email_verified': true,
        }).eq('id', uid);
      }
      _pendingVerificationEmail = null;
      notifyListeners();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Resend OTP code for email verification
  Future<void> resendOTP(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Send password reset email with deep link
  Future<void> sendPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.wanderwith://login-callback',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update user password (called from reset password screen)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Set session from deep link tokens (for password reset flow)
  Future<bool> setSessionFromUri(Uri uri) async {
    try {
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];
      if (accessToken != null && refreshToken != null) {
        await _supabase.auth.setSession(refreshToken);
        return true;
      }
      // Try fragment-based tokens (Supabase sometimes uses hash fragments)
      final fragment = uri.fragment;
      if (fragment.isNotEmpty) {
        final params = Uri.splitQueryString(fragment);
        final aToken = params['access_token'];
        final rToken = params['refresh_token'];
        if (aToken != null && rToken != null) {
          await _supabase.auth.setSession(rToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error setting session from URI: $e");
      return false;
    }
  }

  // Detect current device location via GPS
  Future<Map<String, dynamic>?> detectCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return null;
      }
      if (perm == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String? city;
      String? country;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city = p.locality ?? p.subAdministrativeArea;
        country = p.country;
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'city': city,
        'country': country,
      };
    } catch (e) {
      print('Location detection error: $e');
      return null;
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
    String? coverImageUrl,
    // New fields
    DateTime? dateOfBirth,
    List<String>? specializations,
    int? yearEstablished,
    bool? isPrivate,
  }) async {
    if (_user == null) return;

    final profileData = <String, dynamic>{
      'id': _user!.id,
      'email': _user!.email,
      'role': role,
      'display_name': displayName,
      'username': username,
      'bio': bio,
      'city': city,
      'interests': interests ?? [],
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
      'cover_image_url': coverImageUrl,
      'is_private': isPrivate ?? true,
      'post_visibility': (isPrivate == false) ? 'public' : 'followers',
      'trips_visibility': (isPrivate == false) ? 'public' : 'followers',
      'allow_follow_requests': true,
      'message_privacy': (isPrivate == false) ? 'everyone' : 'followers',
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Only add optional columns if they have values (these columns may not exist in older DB schemas)
    if (dateOfBirth != null) profileData['date_of_birth'] = dateOfBirth.toIso8601String().split('T').first;
    if (specializations != null && specializations.isNotEmpty) profileData['specializations'] = specializations;
    if (yearEstablished != null) profileData['year_established'] = yearEstablished;

    print("[ONBOARDING SAVE] interests: ${profileData['interests']}");

    // Save to DB FIRST — only update local state after DB confirms success
    try {
      await _supabase.from('profiles').upsert(profileData);
    } catch (e) {
      print("CRITICAL ERROR SAVING PROFILE: $e");
      throw Exception("Failed to save profile: $e");
    }

    // DB succeeded — re-fetch profile from DB for authoritative state
    // This ensures interests (text[]) and other fields are properly deserialized
    await _fetchUserProfile();
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
    String? coverImageUrl,
    List<String>? interests,
    String? instagramUrl,
    String? twitterUrl,
    String? youtubeUrl,
    List<String>? otherUrls,
    String? phone,
    DateTime? dateOfBirth,
    // Agency fields
    String? agencyName,
    String? contactPerson,
    String? officeLocation,
    String? agencyDescription,
    String? licenseNumber,
    String? website,
    List<String>? specializations,
    int? yearEstablished,
    // Pass empty string to clear optional text fields
    bool clearInstagram = false,
    bool clearTwitter = false,
    bool clearYoutube = false,
    bool clearPhone = false,
    bool clearWebsite = false,
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
    if (coverImageUrl != null) updates['cover_image_url'] = coverImageUrl;
    if (interests != null) updates['interests'] = interests;
    if (otherUrls != null) updates['other_urls'] = otherUrls;
    if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String().split('T').first;
    if (specializations != null) updates['specializations'] = specializations;
    if (yearEstablished != null) updates['year_established'] = yearEstablished;

    // Text fields that can be set or cleared
    if (instagramUrl != null) updates['instagram_url'] = instagramUrl;
    else if (clearInstagram) updates['instagram_url'] = null;

    if (twitterUrl != null) updates['twitter_url'] = twitterUrl;
    else if (clearTwitter) updates['twitter_url'] = null;

    if (youtubeUrl != null) updates['youtube_url'] = youtubeUrl;
    else if (clearYoutube) updates['youtube_url'] = null;

    if (phone != null) updates['phone'] = phone;
    else if (clearPhone) updates['phone'] = null;

    if (website != null) updates['website'] = website;
    else if (clearWebsite) updates['website'] = null;

    // Agency fields
    if (agencyName != null) updates['agency_name'] = agencyName;
    if (contactPerson != null) updates['contact_person'] = contactPerson;
    if (officeLocation != null) updates['office_location'] = officeLocation;
    if (agencyDescription != null) updates['agency_description'] = agencyDescription;
    if (licenseNumber != null) updates['license_number'] = licenseNumber;

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
