import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../models/notification.dart';
import 'notification_service.dart';
import 'analytics_service.dart';
import 'chat_event_service.dart';
import '../models/trip_extras.dart';
import '../models/trip_link.dart';
import 'url_metadata_service.dart';
import '../models/trip_metadata.dart';
import '../models/trip_international_info.dart';
import '../models/place_insights.dart';
import 'gemini_service.dart';
import 'network_service.dart';
import '../local/local_db.dart';
import '../local/schemas/cached_trip.dart';

class TripService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();
  final AnalyticsService _analyticsService = AnalyticsService();
  
  // Optimistically hide trips the user just left so they don't linger on UI
  static final Set<String> _hiddenTripIds = {};

  // Create a new trip
  Future<String> createTrip({
    required String name,
    required String location,
    DateTime? startDate,
    DateTime? endDate,
    bool isDateDecided = false,
    required String creatorUid,
    String budgetCurrency = 'USD',
    double estimatedCost = 0.0,
    String? coverImageUrl,
    String visibility = 'public',
    String? joinCode,
    String tripType = 'leisure',
    int travelerCount = 1,
  }) async {
    // Client-side ID generation
    final String tripId = _uuid.v4();
    
    final int durationDays = (startDate != null && endDate != null) 
        ? endDate.difference(startDate).inDays + 1 
        : 3; // Default

    final tripData = {
      'id': tripId,
      'name': name,
      'location': location,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_date_decided': isDateDecided,
      'created_by': creatorUid,
      'member_ids': [creatorUid], 
      'status': 'planning',
      'budget_currency': budgetCurrency,
       // Metadata field in Supabase is typically JSONB
      'metadata': {
        'status': 'planning',
        'budgetCurrency': budgetCurrency,
        'estimated_cost': estimatedCost,
        'adminIds': [creatorUid],
        'days': durationDays,
        'trip_type': tripType,
        'traveler_count': travelerCount,
      },
      'cover_image_url': coverImageUrl,
      'visibility': visibility,
      'join_code': joinCode,
    };

    try {
      await _supabase.from('trips').insert(tripData);
      
      // Log Analytics
      await _analyticsService.logEvent('trip_created', parameters: {
        'trip_id': tripId,
        'location': location,
        'has_dates': isDateDecided
      });

      return tripId;
    } catch (e) {
      print("Error creating trip: $e");
      _handleException(e);
      rethrow;
    }
  }

  // ─── Offline Cache Helpers ────────────────────────────────────────

  /// Write a trip to the local Isar cache
  Future<void> _cacheTrip(Trip trip) async {
    try {
      await LocalDb.instance.writeTxn(() async {
        // Find existing by trip id or create new
        final existing = await LocalDb.instance.cachedTrips
            .filter()
            .idEqualTo(trip.id)
            .findFirst();
        final cached = existing ?? CachedTrip();
        cached
          ..id = trip.id
          ..name = trip.name
          ..location = trip.location
          ..startDate = trip.startDate
          ..endDate = trip.endDate
          ..isDateDecided = trip.isDateDecided
          ..createdBy = trip.createdBy
          ..memberIds = trip.memberIds
          ..adminIds = trip.adminIds
          ..metadataJson = trip.metadata != null ? jsonEncode(trip.metadata) : null
          ..budgetCurrency = trip.budgetCurrency
          ..budgetOptionsJson = trip.budgetOptions != null ? jsonEncode(trip.budgetOptions) : null
          ..budgetVotesJson = trip.budgetVotes != null ? jsonEncode(trip.budgetVotes) : null
          ..coverImageUrl = trip.coverImageUrl
          ..visibility = trip.visibility
          ..joinCode = trip.joinCode
          ..lastSynced = DateTime.now();
        await LocalDb.instance.cachedTrips.put(cached);
      });
    } catch (e) {
      debugPrint('TripService: Cache write failed: $e');
    }
  }

  /// Cache a list of trips
  Future<void> _cacheTrips(List<Trip> trips) async {
    for (final trip in trips) {
      await _cacheTrip(trip);
    }
  }

  /// Read a single trip from local cache
  Future<Trip?> _getCachedTrip(String tripId) async {
    try {
      final cached = await LocalDb.instance.cachedTrips
          .filter()
          .idEqualTo(tripId)
          .findFirst();
      if (cached == null) return null;
      return _cachedTripToTrip(cached);
    } catch (e) {
      debugPrint('TripService: Cache read failed: $e');
      return null;
    }
  }

  /// Read all cached trips for the current user
  Future<List<Trip>> _getCachedUserTrips() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return [];
      final all = await LocalDb.instance.cachedTrips.where().findAll();
      return all
          .where((c) => c.memberIds.contains(uid))
          .map(_cachedTripToTrip)
          .toList();
    } catch (e) {
      debugPrint('TripService: Cache read all failed: $e');
      return [];
    }
  }

  Trip _cachedTripToTrip(CachedTrip c) {
    Map<String, dynamic>? metadata;
    if (c.metadataJson != null) {
      try { metadata = jsonDecode(c.metadataJson!) as Map<String, dynamic>; } catch (_) {}
    }
    Map<String, String>? budgetOptions;
    if (c.budgetOptionsJson != null) {
      try { budgetOptions = Map<String, String>.from(jsonDecode(c.budgetOptionsJson!)); } catch (_) {}
    }
    Map<String, String>? budgetVotes;
    if (c.budgetVotesJson != null) {
      try { budgetVotes = Map<String, String>.from(jsonDecode(c.budgetVotesJson!)); } catch (_) {}
    }
    return Trip(
      id: c.id,
      name: c.name,
      location: c.location,
      startDate: c.startDate,
      endDate: c.endDate,
      isDateDecided: c.isDateDecided,
      createdBy: c.createdBy,
      memberIds: c.memberIds,
      adminIds: c.adminIds,
      metadata: metadata,
      budgetCurrency: c.budgetCurrency,
      budgetOptions: budgetOptions,
      budgetVotes: budgetVotes,
      coverImageUrl: c.coverImageUrl,
      visibility: c.visibility,
      joinCode: c.joinCode,
    );
  }

  // ─── End Cache Helpers ────────────────────────────────────────────

  // Helper for error handling
  void _handleException(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socketexception') || 
        msg.contains('connection failed') || 
        msg.contains('network is unreachable') ||
        msg.contains('clientoffset')) { // ClientOffset often appears in supabase offline
       throw Exception("No internet connection. offline mode not supported for this action.");
    }
     if (msg.contains('jwt') || msg.contains('unauthorized')) {
       throw Exception("Session expired. Please log in again.");
     }
     if (msg.contains('pgrst204') || msg.contains('schema cache')) {
       throw Exception("Database schema is out of sync. Please run the latest SQL fixes for the trips table.");
     }
  }

  // Fetch Single Trip Future (for deep linking or one-time load)
  Future<Trip> getTrip(String tripId) async {
    if (NetworkService.instance.isOnline) {
      try {
        final data = await _supabase.from('trips').select().eq('id', tripId).single();
        final trip = _mapToTrip(data);
        // Write-through cache
        _cacheTrip(trip);
        return trip;
      } catch (e) {
        // Fallback to cache on network error
        final cached = await _getCachedTrip(tripId);
        if (cached != null) {
          debugPrint('TripService: getTrip falling back to cache for $tripId');
          return cached;
        }
        _handleException(e);
        rethrow;
      }
    } else {
      // Pure offline mode
      final cached = await _getCachedTrip(tripId);
      if (cached != null) return cached;
      throw Exception('Trip not available offline. Please connect to the internet.');
    }
  }

  // Fetch trips for a specific user where they are a member (Real-time)
  Stream<List<Trip>> getUserTrips(String uid) {
    // We use member_ids array check to filter
    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('status', 'planning') // Optional: default filter, but better to keep it broad or specific
        .map((List<Map<String, dynamic>> data) {
           // Post-process filtering for safety and accuracy
           // Since .stream() on array contains might be tricky in some versions, 
           // and RLS provides the base visibility, we filter for the specific user's membership.
           final trips = data
               .where((map) {
                 final docId = map['id']?.toString();
                 if (docId != null && _hiddenTripIds.contains(docId)) return false;
                 
                 final members = List<String>.from(map['member_ids'] ?? []);
                 return members.contains(uid);
               })
               .map((map) => _mapToTrip(map))
               .toList();
           // Write-through cache on every stream emission
           _cacheTrips(trips);
           return trips;
        });
  }

  /// Get user's trips as a Future (useful for dropdowns) — with offline cache
  Future<List<Trip>> getUserTripsFuture() async {
    if (NetworkService.instance.isOnline) {
      try {
        final uid = _supabase.auth.currentUser?.id;
        if (uid == null) return [];
        
        final data = await _supabase
            .from('trips')
            .select()
            .contains('member_ids', [uid]);
            
        final trips = (data as List).map((map) => _mapToTrip(map)).toList();
        // Write-through cache
        _cacheTrips(trips);
        return trips;
      } catch (e) {
        debugPrint('TripService: getUserTripsFuture online failed, trying cache: $e');
        return await _getCachedUserTrips();
      }
    } else {
      return await _getCachedUserTrips();
    }
  }

  // Fetch single trip stream (Real-time)
  Stream<Trip> getTripStream(String tripId) {
    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .map((data) {
           if (data.isEmpty) throw Exception("Trip not found");
           final trip = _mapToTrip(data.first);
           // Write-through cache on every emission
           _cacheTrip(trip);
           return trip;
        });
  }
  
  Trip _mapToTrip(Map<String, dynamic> map) {
     return Trip(
       id: map['id'],
       name: map['name'],
       location: map['location'],
       startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
       endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
       isDateDecided: map['is_date_decided'] ?? false,
       createdBy: map['created_by'],
       memberIds: List<String>.from(map['member_ids'] ?? []),
       metadata: map['metadata'],
       adminIds: (map['metadata'] != null && map['metadata']['adminIds'] != null)
          ? List<String>.from(map['metadata']['adminIds'])
          : null, // Fallback to [createdBy] in Constructor
       budgetCurrency: map['budget_currency'] ?? 'USD',
       budgetOptions: map['budget_options'] != null ? Map<String, String>.from(map['budget_options'].map((key, value) => MapEntry(key, value.toString()))) : null,
       budgetVotes: (map['metadata'] != null && map['metadata']['budgetVotes'] != null) 
          ? Map<String, String>.from(map['metadata']['budgetVotes']) 
          : null,
       coverImageUrl: map['cover_image_url'],
       visibility: map['visibility'] ?? 'public',
       joinCode: map['join_code'],
     );
  }

  String _normalizeId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    final asString = value.toString();
    if (asString.startsWith('UuidValue(') && asString.endsWith(')')) {
      return asString.substring(10, asString.length - 1);
    }
    return asString;
  }

  // Join Trip using ID or Code
  Future<void> joinTrip(String codeOrId, String uid) async {
    try {
      final codeOrIdTrimmed = codeOrId.trim();
      
      // Use RPC to bypass RLS and fetch basic info needed for joining
      final response = await _supabase.rpc('get_trip_info_for_join', params: {
        'code_or_id': codeOrIdTrimmed,
      });

      if (response == null || (response as List).isEmpty) {
         throw Exception("Trip not found with this ID or Code.");
      }

      final tripData = response[0];
      String actualTripId = tripData['id'];
      List<dynamic> members = tripData['member_ids'] ?? [];
      
      if (members.contains(uid)) {
         throw Exception("You are already a member of this trip.");
      }

      // Fetch user profile
      final userData = await _supabase.from('profiles').select('display_name, email, phone').eq('id', uid).maybeSingle();
      String fullName = userData?['display_name'] ?? 'User';
      String email = userData?['email'] ?? '';
      String phone = userData?['phone'] ?? '';

      // Submit request to the new table
      await submitJoinRequest(
         tripId: actualTripId, 
         userId: uid, 
         fullName: fullName, 
         email: email, 
         phone: phone,
         tripName: tripData['name'],
         creatorId: tripData['created_by'],
      );
    } catch (e) {
      print("Error joining trip: $e");
      _handleException(e);
      rethrow;
    }
  }

  /// Respond to a join request (Approve/Decline)
  Future<void> respondToJoinRequest(String tripId, String userId, bool approve) async {
    try {
      await _supabase.rpc('respond_to_join_request', params: {
        'trip_uuid': tripId,
        'target_user_id': userId,
        'approve': approve,
      });

      // Notify the requester
      try {
        final tripData = await _supabase.from('trips').select('name').eq('id', tripId).single();
        final String tripName = tripData['name'] ?? 'Trip';

        await NotificationService().sendNotification(
          toUserId: userId,
          tripId: tripId,
          title: approve ? "Join Request Approved! 🎉" : "Join Request Update",
          body: approve 
            ? "You've been accepted to the trip: $tripName" 
            : "Your request to join $tripName was not accepted at this time.",
          type: NotificationType.joinResponse,
          metadata: {'approved': approve},
        );

        // Post system message for approved members
        if (approve) {
          try {
            final userData = await _supabase.from('profiles').select('display_name').eq('id', userId).maybeSingle();
            final memberName = userData?['display_name'] ?? 'A new member';
            await ChatEventService.instance.memberJoined(tripId, memberName);
          } catch (_) {}
        }
      } catch (e) {
        print("Error sending join response notification: $e");
      }

    } catch (e) {
      print("Error responding to join request: $e");
      _handleException(e);
      rethrow;
    }
  }

  Future<void> acceptMember(String tripId, String userId) => respondToJoinRequest(tripId, userId, true);
  Future<void> rejectMember(String tripId, String userId) => respondToJoinRequest(tripId, userId, false);



  // Update Budget (Single Cost + Allocations)
  Future<void> updateTripBudget(String tripId, double estimatedCost, List<Map<String, dynamic>> allocations) async {
     try {
       final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
       final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
       
       metadata['estimated_cost'] = estimatedCost;
       metadata['budget_allocations'] = allocations; // [{'title': 'Hotel', 'cost': 500}, ...]
       
       await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);
     } catch (e) { rethrow; }
  }

  /// Download location image from Google and upload to Supabase 'trips' bucket.
  /// Returns the public Supabase URL.
  Future<String?> uploadTripCover(String googlePhotoUrl, String tripId) async {
    try {
      // 1. Download from Google (follows redirects automatically)
      final response = await http.get(Uri.parse(googlePhotoUrl));
      if (response.statusCode != 200) {
        print('Failed to download cover image: HTTP ${response.statusCode}');
        return null;
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        print('Downloaded cover image is empty');
        return null;
      }

      // 2. Detect actual content type from response headers
      final rawContentType = response.headers['content-type'] ?? 'image/jpeg';
      final contentType = rawContentType.split(';').first.trim();
      final ext = contentType.contains('png') ? 'png'
                : contentType.contains('webp') ? 'webp'
                : 'jpg';

      final fileName = "cover_$tripId.$ext";
      final path = "${_supabase.auth.currentUser?.id}/$fileName";

      // 3. Upload to Supabase Storage
      await _supabase.storage.from('trips').uploadBinary(
        path, 
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );

      // 4. Get Public URL
      return _supabase.storage.from('trips').getPublicUrl(path);
    } catch (e) {
      print("Error uploading trip cover: $e");
      return null;
    }
  }
  
  // Delete Poll (Owner/Creator action)
  Future<void> deletePoll(String tripId, String pollId) async {
    try {
       final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
       final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
       
       if (metadata['polls'] != null) {
          List<dynamic> polls = List.from(metadata['polls']);
          polls.removeWhere((p) => p['id'] == pollId);
          metadata['polls'] = polls;
          
          await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);
       }
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // Add Link
  Future<void> addTripLink(String tripId, String title, String url, String addedByUid) async {
    try {
       final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
       final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
       
       List<dynamic> links = [];
       if (metadata['links'] != null) {
          links = List.from(metadata['links']);
       }

       links.add({
         'id': _uuid.v4(),
         'title': title,
         'url': url,
         'added_by': addedByUid,
         'created_at': DateTime.now().toIso8601String(),
       });

       metadata['links'] = links;
       await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);
       
       // Notify Members
       await _notificationService.notifyTripMembers(
          tripId: tripId,
          title: "New Link Added 🔗",
          body: "$title has been added to important links.",
          type: NotificationType.tripUpdate,
          excludeUserId: addedByUid,
       );

    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // Delete Link
  Future<void> deleteTripLink(String tripId, String linkId) async {
    try {
       final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
       final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
       
       if (metadata['links'] != null) {
          List<dynamic> links = List.from(metadata['links']);
          links.removeWhere((l) => l['id'] == linkId);
          metadata['links'] = links;
          await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);
       }
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }



  // Remove Member (Admin Action - Kick User)
  Future<void> removeMember(String tripId, String memberUid) async {
    try {
      // 1. Get current members
      final resp = await _supabase.from('trips').select('member_ids, name').eq('id', tripId).single();
      List<String> currentMembers = List<String>.from(resp['member_ids'] ?? []);
      final tripName = resp['name'];
      
      if (currentMembers.contains(memberUid)) {
        currentMembers.remove(memberUid);
        await _supabase.from('trips').update({'member_ids': currentMembers}).eq('id', tripId);
        
        // Post system message
        try {
          final userData = await _supabase.from('profiles').select('display_name').eq('id', memberUid).maybeSingle();
          final memberName = userData?['display_name'] ?? 'A member';
          await ChatEventService.instance.memberRemoved(tripId, memberName);
        } catch (_) {}

        // Notify the Removed User
         await _notificationService.sendNotification(
          toUserId: memberUid,
          title: "Removed from Trip",
          body: "You have been removed from '$tripName'.",
          type: NotificationType.removedFromTrip, 
          tripId: tripId,
        );
      }
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // Leave Trip (User Action)
  Future<void> leaveTrip(String tripId) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception("User not logged in");
    
    try {
      // 1. Fetch Trip Data to determine role
      // Note: 'admin_ids' is NOT a column, it is in metadata. We only select verified columns.
      final resp = await _supabase.from('trips').select('created_by, member_ids').eq('id', tripId).single();
      final creatorId = resp['created_by'];
      List<String> memberIds = List<String>.from(resp['member_ids'] ?? []);

      // 2. Handle Creator Leaving
      if (uid == creatorId) {
         if (memberIds.length <= 1) {
            // Only creator is left -> Delete Trip
            await _supabase.from('trips').delete().eq('id', tripId);
         } else {
            // Mark trip as dead, remove creator from members
            memberIds.remove(uid);
            final metadataResp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
            final metadata = Map<String, dynamic>.from(metadataResp['metadata'] ?? {});
            metadata['is_dead'] = true;
            
            await _supabase.from('trips').update({
              'member_ids': memberIds,
              'metadata': metadata,
            }).eq('id', tripId);
         }
         _hiddenTripIds.add(tripId);
         return;
      }

      // 3. Regular Member Leaving (Use RPC to bypass RLS)
      // Post system message before leaving
      try {
        final userData = await _supabase.from('profiles').select('display_name').eq('id', uid).maybeSingle();
        final memberName = userData?['display_name'] ?? 'A member';
        await ChatEventService.instance.memberLeft(tripId, memberName);
      } catch (_) {}

      try {
        await _supabase.rpc('leave_trip', params: {
          'trip_uuid': tripId,
          'target_user_id': uid,
        });
        _hiddenTripIds.add(tripId);
        return;
      } catch (e) {
        print("RPC leave_trip failed: $e. Falling back to manual update.");
      }

      if (memberIds.contains(uid)) {
        memberIds.remove(uid);
        
        if (memberIds.isEmpty) {
           await _supabase.from('trips').delete().eq('id', tripId);
        } else {
           await _supabase.from('trips').update({'member_ids': memberIds}).eq('id', tripId);
        }
        _hiddenTripIds.add(tripId);
      }
    } catch (e) {
      print("Error leaving trip: $e");
      _handleException(e);
      rethrow;
    }
  }

  // Update Trip Name
  Future<void> updateTripName(String tripId, String newName) async {
    try {
      await _supabase.from('trips').update({
        'name': newName,
      }).eq('id', tripId);
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // Update Trip About
  Future<void> updateTripAbout(String tripId, String aboutText) async {
    try {
      final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
      metadata['about'] = aboutText;
      await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // AI Summary: Save into metadata
  Future<void> saveAiSummary(String tripId, String summary) async {
    try {
      final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
      metadata['ai_summary'] = summary;
      metadata['ai_summary_updated_at'] = DateTime.now().toIso8601String();
      await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // AI Summary: Fetch from metadata
  Future<String?> getAiSummary(String tripId) async {
    try {
      final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
      return metadata['ai_summary'] as String?;
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // Update Dates (Admin Only check should be in UI, but this performs the action)
  Future<void> updateTripDates(String tripId, DateTime start, DateTime end) async {
      final uid = _supabase.auth.currentUser?.id;
      final int days = end.difference(start).inDays + 1;

      // Fetch current metadata to preserve other fields
      final response = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
      Map<String, dynamic> metadata = Map<String, dynamic>.from(response['metadata'] ?? {});
      metadata['days'] = days;
      
      await _supabase.from('trips').update({
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
        'is_date_decided': true,
        'metadata': metadata
      }).eq('id', tripId);

      if (uid != null) {
        await _notificationService.notifyTripMembers(
          tripId: tripId,
          title: "Dates Updated 📅",
          body: "Trip dates set to ${start.day}/${start.month} - ${end.day}/${end.month} ($days Days)",
          type: NotificationType.dateChange,
          excludeUserId: uid,
        );
      }
  }

  // Update Budget Configuration (Currency/Options)
  Future<void> updateBudgetSettings(String tripId, String currency, Map<String, int> options) async {
    final uid = _supabase.auth.currentUser?.id;
    final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
    final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
    
    metadata['budgetCurrency'] = currency;
    metadata['budgetOptions'] = options;

    await _supabase.from('trips').update({
      'budget_currency': currency,
      'budget_options': options, 
      'metadata': metadata
    }).eq('id', tripId);

    if (uid != null) {
      await _notificationService.notifyTripMembers(
        tripId: tripId,
        title: "Budget Updated 💰",
        body: "The budget options have been updated.",
        type: NotificationType.budgetChange,
        excludeUserId: uid,
      );
    }
  }

  // Vote for Budget
  Future<void> voteBudget(String tripId, String uid, String option) async {
    try {
      // 1. Get current metadata
      final resp = await _supabase
          .from('trips')
          .select('metadata')
          .eq('id', tripId)
          .single();
          
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
      final votes = Map<String, dynamic>.from(metadata['budgetVotes'] ?? {});
      
      // 2. Update vote
      votes[uid] = option;
      metadata['budgetVotes'] = votes;

      // 3. Save back
      await _supabase
          .from('trips')
          .update({'metadata': metadata})
          .eq('id', tripId);
          
    } catch (e) {
      print("Vote failed: $e");
      _handleException(e);
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Polls & Admins
  // --------------------------------------------------------------------------

  // --------------------------------------------------------------------------
  // Polls 2.0 (Relational)
  // --------------------------------------------------------------------------

  Stream<List<TripPoll>> getPollsStream(String tripId) {
    return _supabase
        .from('trip_polls')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('is_pinned', ascending: false)
        .order('updated_at', ascending: false)
        .asyncMap((pollsData) async {
          if (pollsData.isEmpty) return [];
          
          final List<String> pollIds = pollsData.map((p) => p['id'] as String).toList();
          
          // 1. Fetch ALL options and votes in parallel
          final results = await Future.wait([
            _supabase.from('trip_poll_options').select().inFilter('poll_id', pollIds),
            _supabase.from('trip_poll_votes').select().inFilter('poll_id', pollIds),
          ]);
          
          final List<PollOption> allOptions = (results[0] as List).map((o) => PollOption.fromMap(o)).toList();
          final List<PollVote> allVotes = (results[1] as List).map((v) => PollVote.fromMap(v)).toList();

          // 2. Assemble
          return pollsData.map((pMap) {
            final pollId = pMap['id'];
            final options = allOptions.where((o) => o.pollId == pollId).toList();
            final votes = allVotes.where((v) => v.pollId == pollId).toList();
            return TripPoll.fromMap(pMap, options: options, votes: votes);
          }).toList();
        });
  }

  Future<void> deletePollRelational(String pollId) async {
    try {
      final response = await _supabase.from('trip_polls').delete().eq('id', pollId).select();
      if ((response as List).isEmpty) {
        throw Exception("Delete failed: Record not found or permission denied.");
      }
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  Future<String?> createPollRelational({
    required String tripId,
    required String question,
    required List<String> options,
    DateTime? endsAt,
    bool isAnonymous = false,
    bool allowMultiple = false,
    bool isPinned = false,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;

    try {
      // 1. Create Poll
      final pollResp = await _supabase.from('trip_polls').insert({
        'trip_id': tripId,
        'question': question,
        'created_by': uid,
        'ends_at': endsAt?.toIso8601String(),
        'is_anonymous': isAnonymous,
        'allow_multiple': allowMultiple,
        'is_pinned': isPinned,
      }).select().single();

      final pollId = pollResp['id'];

      // 2. Create Options
      final optionsToInsert = options.map((opt) => {
        'poll_id': pollId,
        'option_text': opt,
      }).toList();

      await _supabase.from('trip_poll_options').insert(optionsToInsert);

      // 3. Notify trip members
      _notificationService.notifyTripMembers(
        tripId: tripId,
        title: "New Poll 🗳️",
        body: question,
        type: NotificationType.pollAdded,
        excludeUserId: uid,
      );

      // Log Analytics
      await _analyticsService.logEvent('poll_created_v2', parameters: {
        'trip_id': tripId,
        'poll_id': pollId,
        'options_count': options.length
      });

      return pollId;

    } catch (e) {
      print("Error creating poll v2: $e");
      _handleException(e);
      rethrow;
    }
  }

  Future<void> votePollRelational({
    required String pollId,
    required String optionId,
    required bool allowMultiple,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      if (!allowMultiple) {
        // Remove any existing votes for this poll by this user
        await _supabase
            .from('trip_poll_votes')
            .delete()
            .eq('poll_id', pollId)
            .eq('user_id', uid);
      }

      // Add the new vote (upsert handles single-choice toggling if we want, 
      // but here we just insert since we cleared old votes above for single-choice)
      await _supabase.from('trip_poll_votes').upsert({
        'poll_id': pollId,
        'option_id': optionId,
        'user_id': uid,
      });

      // Log Analytics
      await _analyticsService.logEvent('poll_voted_v2', parameters: {
        'poll_id': pollId,
        'option_id': optionId
      });

    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // Gallery 2.0 & Reactions
  // --------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getPhotosStream(String tripId) {
    // We fetch photos and reactions in one go by using a select with join if possible, 
    // but for real-time streaming, we'll listen to photos and then fetch reactions.
    // To be truly reactive to BOTH, we'd need to combine streams.
    return _supabase
        .from('photos')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: false)
        .asyncMap((photosData) async {
          if (photosData.isEmpty) return [];
          
          final List<String> photoIds = photosData.map((p) => p['id'] as String).toList();
          
          // Fetch all reactions for these photos in one batch query
          final reactionsData = await _supabase
              .from('trip_photo_reactions')
              .select()
              .inFilter('photo_id', photoIds);
          
          final List<PhotoReaction> allReactions = (reactionsData as List).map((r) => PhotoReaction.fromMap(r)).toList();

          final List<Map<String, dynamic>> enrichedPhotos = [];
          for (var photo in photosData) {
            final photoId = photo['id'];
            photo['reactions'] = allReactions.where((r) => r.photoId == photoId).toList();
            enrichedPhotos.add(photo);
          }
          return enrichedPhotos;
        });
  }

  // Stream just for reactions of a specific photo (useful for the viewer)
  Stream<List<PhotoReaction>> getPhotoReactionsStream(String photoId) {
    return _supabase
        .from('trip_photo_reactions')
        .stream(primaryKey: ['id'])
        .eq('photo_id', photoId)
        .map((data) => data.map((r) => PhotoReaction.fromMap(r)).toList());
  }

  Future<void> togglePhotoReaction(String photoId, String reaction) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      // Check if this specific reaction already exists from this user
      final existing = await _supabase
          .from('trip_photo_reactions')
          .select()
          .eq('photo_id', photoId)
          .eq('user_id', uid)
          .eq('reaction', reaction)
          .maybeSingle();

      if (existing != null) {
        // Remove reaction
        await _supabase
            .from('trip_photo_reactions')
            .delete()
            .eq('id', existing['id']);
      } else {
        // Add reaction (or update if user can only have one reaction per photo?)
        // The unique constraint is on (photo_id, user_id), so one reaction per user per photo.
        await _supabase.from('trip_photo_reactions').upsert({
          'photo_id': photoId,
          'user_id': uid,
          'reaction': reaction,
        });
      }
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  /// Compress an image to a target max dimension and quality.
  Future<File> _compressImage(File file, {int maxWidth = 1920, int quality = 80}) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: maxWidth,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    return result != null ? File(result.path) : file;
  }

  /// Generate a small thumbnail (400px wide) for grid display.
  Future<File> _generateThumbnail(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_thumb.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 400,
      quality: 60,
      format: CompressFormat.jpeg,
    );
    return result != null ? File(result.path) : file;
  }

  Future<void> uploadPhotos(String tripId, List<XFile> images, {Function(int, int)? onProgress}) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    int completed = 0;
    final total = images.length;
    const batchSize = 3; // Upload 3 at a time to avoid memory spikes

    try {
      for (int i = 0; i < images.length; i += batchSize) {
        final batch = images.skip(i).take(batchSize).toList();
        await Future.wait(batch.map((image) async {
          try {
            final originalFile = File(image.path);
            final originalSize = await originalFile.length();

            // 1. Compress for full-res view (max 1920px, quality 80)
            final compressed = await _compressImage(originalFile);

            // 2. Generate thumbnail for grid view (400px, quality 60)
            final thumbnail = await _generateThumbnail(originalFile);

            // 3. Upload full-res
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fullPath = '$uid/${timestamp}_full_${image.name}';
            await _supabase.storage
                .from('trip_photos')
                .upload(fullPath, compressed);
            final String fullUrl = _supabase.storage
                .from('trip_photos')
                .getPublicUrl(fullPath);

            // 4. Upload thumbnail
            final thumbPath = '$uid/${timestamp}_thumb_${image.name}';
            await _supabase.storage
                .from('trip_photos')
                .upload(thumbPath, thumbnail);
            final String thumbUrl = _supabase.storage
                .from('trip_photos')
                .getPublicUrl(thumbPath);

            // 5. Save to Photos Table with both URLs
            await _supabase.from('photos').insert({
              'trip_id': tripId,
              'url': fullUrl,
              'thumbnail_url': thumbUrl,
              'uploader_id': uid,
              'metadata': {
                'original_name': image.name,
                'original_size': originalSize,
                'compressed_size': await compressed.length(),
                'thumbnail_size': await thumbnail.length(),
              }
            });

            completed++;
            if (onProgress != null) onProgress(completed, total);

            // Clean up temp files
            try {
              if (compressed.path != originalFile.path) await compressed.delete();
              if (thumbnail.path != originalFile.path) await thumbnail.delete();
            } catch (_) {}
          } catch (e) {
            debugPrint('Failed to upload individual photo: $e');
            // Continue with others
          }
        }));
      }

      // Log Analytics
      await _analyticsService.logEvent('photos_uploaded', parameters: {
        'trip_id': tripId,
        'count': completed
      });

    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  
  Future<void> deletePhoto(String tripId, String photoId, String photoUrl, String uploaderId) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      // 1. Delete from DB (RLS will catch if not permitted, but we check here too)
      await _supabase.from('photos').delete().eq('id', photoId);

      // 2. Delete from Storage
      final fileName = photoUrl.split('/').last;
      final fullPath = "${uploaderId}/$fileName";
      await _supabase.storage.from('trip_photos').remove([fullPath]);

    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  Future<void> updatePhotoCaption(String photoId, String caption) async {
    try {
      await _supabase.from('photos').update({'caption': caption}).eq('id', photoId);
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  Future<void> deletePhotosBatch(String tripId, List<Map<String, dynamic>> photos) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final List<String> photoIds = photos.map((p) => p['id'] as String).toList();
      
      // 1. Delete from DB
      await _supabase.from('photos').delete().inFilter('id', photoIds);

      // 2. Delete from Storage
      final List<String> paths = photos.map((p) {
        final fileName = (p['url'] as String).split('/').last;
        return "${p['uploader_id']}/$fileName";
      }).toList();
      
      await _supabase.storage.from('trip_photos').remove(paths);

    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // Revised addAdmin with safety
  Future<void> promoteToAdmin(String tripId, String newAdminId) async {
    try {
       final resp = await _supabase.from('trips').select('created_by, metadata').eq('id', tripId).single();
       final creator = resp['created_by'] as String;
       final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
       
       List<String> currentAdmins = [];
       if (metadata['adminIds'] != null) {
          currentAdmins = List<String>.from(metadata['adminIds']);
       } else {
          currentAdmins = [creator];
       }

       if (!currentAdmins.contains(newAdminId)) {
          currentAdmins.add(newAdminId);
          metadata['adminIds'] = currentAdmins;
          await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);
          
          // Notify the promoted user
          try {
            final tripResp = await _supabase.from('trips').select('name').eq('id', tripId).single();
            final tripName = tripResp['name'] ?? 'a trip';
            await _notificationService.sendNotification(
              toUserId: newAdminId,
              title: "You're now an Admin! 🎉",
              body: "You've been promoted to admin in '$tripName'.",
              type: NotificationType.adminPromoted,
              tripId: tripId,
            );
          } catch (_) {}
       }
    } catch (e) {
       print("Promote failed: $e");
       _handleException(e);
       rethrow;
    }
  }

  Future<void> demoteFromAdmin(String tripId, String adminId) async {
    try {
       final resp = await _supabase.from('trips').select('created_by, metadata').eq('id', tripId).single();
       final creator = resp['created_by'] as String;
       // Prevent demoting creator
       if (creator == adminId) return;

       final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
       List<String> currentAdmins = [];
       if (metadata['adminIds'] != null) {
          currentAdmins = List<String>.from(metadata['adminIds']);
       }

       if (currentAdmins.contains(adminId)) {
          currentAdmins.remove(adminId);
          metadata['adminIds'] = currentAdmins;
          await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);
       }
    } catch (e) {
       print("Demote failed: $e");
       _handleException(e);
       rethrow;
    }
  }

  // Submit Feedback
  Future<void> submitReview(String tripId, String uid, int rating, String comment) async {
    try {
      final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});

      // Get existing reviews or init
      final reviews = (metadata['reviews'] != null)
          ? Map<String, dynamic>.from(metadata['reviews'])
          : <String, dynamic>{};

      // Add/Update review for this user
      reviews[uid] = {
        'rating': rating,
        'comment': comment,
        'timestamp': DateTime.now().toIso8601String(),
      };

      metadata['reviews'] = reviews;
      await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  /// Log activity to the trip activity feed
  Future<void> logActivity({
    required String tripId,
    required String type,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('trip_activities').insert({
        'trip_id': tripId,
        'user_id': user?.id,
        'type': type,
        'content': content,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      print("Error logging activity: $e");
    }
  }

  /// Get Activity Stream for a trip
  Stream<List<Map<String, dynamic>>> getTripActivityStream(String tripId) {
     return _supabase
        .from('trip_activities')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Get profiles for all trip members securely (Soft Visibility)
  Future<List<UserProfile>> getTripMembersProfilesByTripId(String tripId) async {
    try {
      final data = await _supabase.rpc('get_trip_member_profiles', params: {'trip_id_param': tripId});
      if (data == null) return [];
      
      return (data as List)
          .where((m) => m != null)
          .map((m) {
            final map = Map<String, dynamic>.from(m);
            final profile = UserProfile.fromMap(map);
            // We can temporarily store the status in the profile if we wanted, 
            // but for now we'll just return the profiles and the UI can check trip.memberIds
            return profile;
          }).toList();
    } catch (e) {
      print("Error fetching member profiles via RPC: $e");
      return [];
    }
  }

  /// Get profiles for multiple member IDs (Strict RLS apply)
  Future<List<UserProfile>> getTripMembersProfiles(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', memberIds);
      
      return (data as List).map((m) => UserProfile.fromMap(m)).toList();
    } catch (e) {
      print("Error fetching member profiles: $e");
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // Links Hub (Relational)
  // --------------------------------------------------------------------------

  Stream<List<TripLink>> getTripLinksStream(String tripId) {
    return _supabase
        .from('trip_links')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .map((data) => data.map((map) => TripLink.fromMap(map)).toList());
  }

  Future<void> addTripLinkRelational({
    required String tripId,
    required String title,
    required String url,
    String? category,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      // 1. Fetch metadata
      final metadata = await UrlMetadataService.fetchMetadata(url);
      
      // 2. Auto-detect category if not provided
      final finalCategory = category ?? UrlMetadataService.detectCategory(url);

      // 3. Insert into DB
      await _supabase.from('trip_links').insert({
        'trip_id': tripId,
        'title': title,
        'url': url,
        'category': finalCategory,
        'preview_image': metadata.image,
        'site_name': metadata.siteName,
        'description': metadata.description,
        'added_by': uid,
      });

      // 4. Activity log
      await logActivity(
        tripId: tripId,
        type: 'link_added',
        content: "added a new resource: $title",
      );
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  Future<void> toggleLinkPin(String linkId, bool isPinned) async {
    try {
      await _supabase
          .from('trip_links')
          .update({'is_pinned': isPinned})
          .eq('id', linkId);
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  Future<void> deleteTripLinkRelational(String linkId) async {
    try {
      await _supabase.from('trip_links').delete().eq('id', linkId);
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  Future<void> updateLinkCategory(String linkId, String category) async {
    try {
      await _supabase
          .from('trip_links')
          .update({'category': category})
          .eq('id', linkId);
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // Submit Join Request
  Future<void> submitJoinRequest({
    required String tripId,
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    String? tripName,
    String? creatorId,
  }) async {
    try {
      await _supabase.from('trip_join_requests').insert({
        'trip_id': tripId,
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'phone': phone,
      });

      // Notify Trip Creator
      try {
        String finalTripName = tripName ?? 'Trip';
        String finalCreatorId = creatorId ?? '';

        if (tripName == null || creatorId == null) {
          final tripData = await _supabase.from('trips').select('name, created_by').eq('id', tripId).single();
          finalTripName = tripData['name'] ?? 'Trip';
          finalCreatorId = tripData['created_by'];
        }

        if (finalCreatorId.isNotEmpty) {
          await NotificationService().sendNotification(
            toUserId: finalCreatorId,
            tripId: tripId,
            title: "New Join Request! 🎒",
            body: "$fullName wants to join your trip: $finalTripName",
            type: NotificationType.joinRequest,
            metadata: {'requester_id': userId},
          );
        }
      } catch (e) {
        print("Error sending join request notification: $e");
      }

    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation (duplicate join request)
        print("Join request already exists. Ignoring.");
        return;
      }
      print("Error submitting join request: $e");
      _handleException(e);
      rethrow;
    } catch (e) {
      print("Error submitting join request: $e");
      _handleException(e);
      rethrow;
    }
  }

  // Manual Join via Code
  Future<void> respondToJoinRequestManual(String tripId, String userId) async {
     return respondToJoinRequest(tripId, userId, true);
  }

  // Get Join Requests
  Future<List<Map<String, dynamic>>> getJoinRequests(String tripId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('trip_join_requests')
          .select()
          .eq('trip_id', tripId)
          .eq('status', 'pending');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print("Error fetching join requests: $e");
      return [];
    }
  }

  // Check if a specific user has a pending join request
  Future<bool> hasPendingJoinRequest(String tripId, String userId) async {
    try {
      final data = await _supabase
          .from('trip_join_requests')
          .select()
          .eq('trip_id', tripId)
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();
      return data != null;
    } catch (e) {
      print("Error checking pending request: $e");
      return false;
    }
  }

  // ── Trip Metadata (Destination Intelligence) ──

  final GeminiService _geminiService = GeminiService();

  /// Fetch cached trip metadata from DB
  Future<TripMetadata?> getTripMetadata(String tripId) async {
    try {
      final data = await _supabase
          .from('trip_metadata')
          .select()
          .eq('trip_id', tripId)
          .maybeSingle();
      if (data != null) return TripMetadata.fromJson(data);
      return null;
    } catch (e) {
      debugPrint('Error fetching trip metadata: $e');
      return null;
    }
  }

  /// Enrich trip metadata via AI and save to DB
  Future<TripMetadata?> enrichTripMetadata(Trip trip) async {
    try {
      final aiResponse = await _geminiService.enrichDestination(trip.location);
      if (aiResponse == null) return null;

      final metadataJson = {
        'trip_id': trip.id,
        'destination_country_code': aiResponse['country_code'],
        'best_time_to_visit': aiResponse['best_time_to_visit'],
        'best_time_weather_emoji': aiResponse['best_time_weather_emoji'],
        'crowd_level': aiResponse['crowd_level'],
        'avg_temp_range': aiResponse['avg_temp_range'],
        'visa_required': aiResponse['visa_required'],
        'currency_code': aiResponse['currency_code'],
        'currency_name': aiResponse['currency_name'],
        'timezone': aiResponse['timezone'],
        'language': aiResponse['language'],
        'emergency_number': aiResponse['emergency_number'],
        'raw_ai_response': aiResponse,
      };

      final saved = await _supabase
          .from('trip_metadata')
          .upsert(metadataJson, onConflict: 'trip_id')
          .select()
          .single();

      return TripMetadata.fromJson(saved);
    } catch (e) {
      debugPrint('Error enriching trip metadata: $e');
      return null;
    }
  }

  // ── International Travel Info ──────────────────────────────────────

  /// Fetch cached international travel info from DB
  Future<TripInternationalInfo?> getInternationalInfo(
      String tripId, String userCountry) async {
    try {
      final rows = await _supabase
          .from('trip_international_info')
          .select()
          .eq('trip_id', tripId)
          .eq('user_country', userCountry)
          .limit(1);

      if (rows.isEmpty) return null;
      return TripInternationalInfo.fromJson(rows.first);
    } catch (e) {
      debugPrint('Error fetching international info: $e');
      return null;
    }
  }

  /// Enrich international travel info via AI and save to DB
  Future<TripInternationalInfo?> enrichInternationalInfo(
      Trip trip, String userCountry) async {
    try {
      final aiResponse = await _geminiService.getInternationalTravelInfo(
        userCountry,
        trip.location,
      );
      if (aiResponse == null) return null;

      final infoJson = {
        'trip_id': trip.id,
        'user_country': userCountry,
        'dest_country': trip.location,
        'visa_required': aiResponse['visa_required'] ?? false,
        'visa_type': aiResponse['visa_type'],
        'stay_duration': aiResponse['stay_duration'],
        'processing_time': aiResponse['processing_time'],
        'visa_apply_url': aiResponse['visa_apply_url'],
        'embassy_name': aiResponse['embassy_name'],
        'embassy_address': aiResponse['embassy_address'],
        'embassy_phone': aiResponse['embassy_phone'],
        'embassy_emergency_number': aiResponse['embassy_emergency_number'],
        'embassy_email': aiResponse['embassy_email'],
        'local_emergency_number': aiResponse['local_emergency_number'],
        'local_police_number': aiResponse['local_police_number'],
        'local_medical_number': aiResponse['local_medical_number'],
        'plug_type': aiResponse['plug_type'],
        'tipping_customs': aiResponse['tipping_customs'],
        'useful_phrases': aiResponse['useful_phrases'],
        'sim_info': aiResponse['sim_info'],
        'passport_reminder': aiResponse['passport_reminder'],
        'travel_insurance_note': aiResponse['travel_insurance_note'],
      };

      final saved = await _supabase
          .from('trip_international_info')
          .upsert(infoJson, onConflict: 'trip_id,user_country')
          .select()
          .single();

      return TripInternationalInfo.fromJson(saved);
    } catch (e) {
      debugPrint('Error enriching international info: $e');
      return null;
    }
  }

  // ── Domestic Travel Intelligence ──────────────────────────────────

  /// Enrich domestic travel info via AI and save to trip_metadata
  Future<TripMetadata?> enrichDomesticInfo(String tripId, String destination) async {
    try {
      final aiResponse = await _geminiService.getDomesticTravelInfo(destination);
      if (aiResponse == null) return null;

      final updateData = {
        'local_transport_tips': aiResponse['local_transport_tips'],
        'sim_connectivity_info': aiResponse['sim_connectivity_info'],
        'safety_tips': aiResponse['safety_tips'],
        'local_customs': aiResponse['local_customs'],
        'local_food_recommendations': aiResponse['local_food_recommendations'],
      };

      final saved = await _supabase
          .from('trip_metadata')
          .update(updateData)
          .eq('trip_id', tripId)
          .select()
          .single();

      return TripMetadata.fromJson(saved);
    } catch (e) {
      debugPrint('Error enriching domestic info: $e');
      return null;
    }
  }

  // ── Place Insights (shared AI cache) ──────────────────────────────

  /// Fetch cached place insights from DB
  Future<PlaceInsights?> getPlaceInsights(String googlePlaceId) async {
    try {
      final rows = await _supabase
          .from('place_insights')
          .select()
          .eq('google_place_id', googlePlaceId)
          .limit(1);

      if (rows.isEmpty) return null;
      return PlaceInsights.fromJson(rows.first);
    } catch (e) {
      debugPrint('Error fetching place insights: $e');
      return null;
    }
  }

  /// Enrich place insights via AI and save to shared cache
  Future<PlaceInsights?> enrichPlaceInsights(
      String googlePlaceId, String placeName, String? tripLocation, {String? placeType}) async {
    try {
      final aiResponse = await _geminiService.getPlaceInsights(placeName, tripLocation, placeType: placeType);
      if (aiResponse == null) return null;

      final saved = await _supabase
          .from('place_insights')
          .upsert({
            'google_place_id': googlePlaceId,
            'place_name': placeName,
            'insights': aiResponse,
          }, onConflict: 'google_place_id')
          .select()
          .single();

      return PlaceInsights.fromJson(saved);
    } catch (e) {
      debugPrint('Error enriching place insights: $e');
      return null;
    }
  }

  // ──────────────── AI Guide Memory ────────────────

  /// Load conversation history for the current user in a trip
  Future<List<Map<String, String>>> getAiConversationHistory(String tripId) async {
    final uid = _supabase.auth.currentUser!.id;
    final result = await _supabase
        .from('trip_ai_memory')
        .select('conversation_history')
        .eq('trip_id', tripId)
        .eq('user_id', uid)
        .maybeSingle();

    if (result == null) return [];
    return (result['conversation_history'] as List)
        .map((e) => Map<String, String>.from(e))
        .toList();
  }

  /// Save conversation history (keeps last 15 messages to control token cost)
  Future<void> saveAiConversationHistory(
      String tripId, List<Map<String, String>> history) async {
    final uid = _supabase.auth.currentUser!.id;
    final trimmed =
        history.length > 15 ? history.sublist(history.length - 15) : history;

    await _supabase.from('trip_ai_memory').upsert({
      'trip_id': tripId,
      'user_id': uid,
      'conversation_history': trimmed,
      'last_updated': DateTime.now().toIso8601String(),
    }, onConflict: 'trip_id,user_id');
  }

  /// Clear conversation history for the current user in a trip
  Future<void> clearAiConversationHistory(String tripId) async {
    final uid = _supabase.auth.currentUser!.id;
    await _supabase
        .from('trip_ai_memory')
        .delete()
        .eq('trip_id', tripId)
        .eq('user_id', uid);
  }
}