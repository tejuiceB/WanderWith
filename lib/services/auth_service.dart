import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'dart:io';
import '../config/app_env.dart';

class AuthService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Keep for potential ID token flow if needed, but mostly relying on Supabase OAuth

  User? _user;
  UserProfile? _userProfile;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;

  bool get isAuthenticated => _user != null;
  bool get hasCompletedOnboarding => _userProfile?.country != null;
  bool get isProfileLoaded => _user == null || _userProfile != null;
  
  bool _isLoadingProfile = true;
  bool get isLoadingProfile => _isLoadingProfile;

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
    await _fetchUserProfile();
    notifyListeners();
  }

  Future<void> _fetchUserProfile() async {
    if (_user == null) return;
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
          email: data['email'],
          displayName: data['display_name'],
          country: data['country'],
          budgetStyle: data['budget_style'],
          tripVibe: data['trip_vibe'],
          avatarUrl: data['avatar_url'],
        );
      } else {
        _userProfile = UserProfile(
          uid: _user!.id,
          email: _user!.email,
          displayName: _user!.userMetadata?['full_name'],
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

  // Save Onboarding Data
  Future<void> saveUserProfile({
    required String country,
    required String budgetStyle,
    required String tripVibe,
    String? displayName,
  }) async {
    if (_user == null) return;

    final profileData = {
      'id': _user!.id, 
      'email': _user!.email,
      'display_name': displayName ?? _user!.userMetadata?['full_name'] ?? "Traveler",
      'country': country,
      'budget_style': budgetStyle,
      'trip_vibe': tripVibe,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Update local immediately
    _userProfile = UserProfile(
       uid: _user!.id,
       email: _user!.email,
       displayName: profileData['display_name'] as String?,
       country: country,
       budgetStyle: budgetStyle,
       tripVibe: tripVibe
    );
    notifyListeners();

    try {
      await _supabase.from('profiles').upsert(profileData);
    } catch (e) {
      print("CRITICAL ERROR SAVING PROFILE: $e");
      throw Exception("Failed to save profile");
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _user = null;
    _userProfile = null;
    notifyListeners();
  }
}
