import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../models/notification.dart';
import 'notification_service.dart';
import 'analytics_service.dart';
import '../models/trip_extras.dart';
import '../models/trip_link.dart';
import 'url_metadata_service.dart';

class TripService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();
  final AnalyticsService _analyticsService = AnalyticsService();

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
      },
      'cover_image_url': coverImageUrl,
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
    try {
      final data = await _supabase.from('trips').select().eq('id', tripId).single();
      return _mapToTrip(data);
    } catch (e) {
      _handleException(e);
      rethrow;
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
           return data
               .where((map) {
                 final members = List<String>.from(map['member_ids'] ?? []);
                 final creator = map['created_by'];
                 return members.contains(uid) || creator == uid;
               })
               .map((map) => _mapToTrip(map))
               .toList();
        });
  }

  /// Get user's trips as a Future (useful for dropdowns)
  Future<List<Trip>> getUserTripsFuture() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return [];
      
      final data = await _supabase
          .from('trips')
          .select()
          .contains('member_ids', [uid]);
          
      return (data as List).map((map) => _mapToTrip(map)).toList();
    } catch (e) {
      print("Error fetching trips future: $e");
      return [];
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
           return _mapToTrip(data.first);
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

  // Join Trip using ID
  Future<void> joinTrip(String tripId, String uid) async {
    try {
      // 1. Add to pending_members via RPC (SECURITY DEFINER)
      // This RPC handles duplicate checks and appends to metadata->'pending_members'
      await _supabase.rpc('join_trip', params: {
        'trip_uuid': tripId, 
        'user_id': uid
      });
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
      // 1. Download from Google
      final response = await http.get(Uri.parse(googlePhotoUrl));
      if (response.statusCode != 200) return null;

      final bytes = response.bodyBytes;
      final fileName = "cover_$tripId.jpg";
      final path = "${_supabase.auth.currentUser?.id}/$fileName";

      // 2. Upload to Supabase Storage
      await _supabase.storage.from('trips').uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      // 3. Get Public URL
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
        
        // Notify the Removed User
         await _notificationService.sendNotification(
          toUserId: memberUid,
          title: "Removed from Trip",
          body: "You have been removed from '$tripName'.",
          type: NotificationType.system, 
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
            return;
         } else {
            // Transfer Ownership to the next available member
            // (Simpler logic: just pick the first person who isn't me)
            final newCreator = memberIds.firstWhere((id) => id != uid, orElse: () => "");
            
            if (newCreator.isEmpty) {
               await _supabase.from('trips').delete().eq('id', tripId);
               return;
            }

            // Update Trip: Set new creator, remove me from members
            memberIds.remove(uid);
            
            await _supabase.from('trips').update({
              'created_by': newCreator,
              'member_ids': memberIds,
            }).eq('id', tripId);
            return;
         }
      }

      // 3. Regular Member Leaving (Use RPC to bypass RLS)
      try {
        await _supabase.rpc('leave_trip', params: {
          'trip_uuid': tripId,
          'user_id': uid,
        });
        return;
      } catch (_) {
        // Fallback to direct update if RPC not available
      }

      if (memberIds.contains(uid)) {
        memberIds.remove(uid);
        await _supabase.from('trips').update({'member_ids': memberIds}).eq('id', tripId);
      }
    } catch (e) {
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

  Future<void> createPollRelational({
    required String tripId,
    required String question,
    required List<String> options,
    DateTime? endsAt,
    bool isAnonymous = false,
    bool allowMultiple = false,
    bool isPinned = false,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

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

  Future<void> uploadPhotos(String tripId, List<XFile> images, {Function(int, int)? onProgress}) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    int completed = 0;
    final total = images.length;

    try {
      // Parallel uploads with batching to avoid hitting rate limits or memory issues if many images
      // For now, simple Future.wait
      await Future.wait(images.map((image) async {
        try {
          // 1. Upload to Storage
          String fileExt = image.path.split('.').last;
          String fileName = "${uid}/${DateTime.now().millisecondsSinceEpoch}_${image.name}";
          
          await _supabase.storage
              .from('trip_photos')
              .upload(fileName, File(image.path));

          // 2. Get Public URL
          final String publicUrl = _supabase.storage
              .from('trip_photos')
              .getPublicUrl(fileName);

          // 3. Save to Photos Table
          await _supabase.from('photos').insert({
            'trip_id': tripId,
            'url': publicUrl,
            'uploader_id': uid,
            'metadata': {
              'original_name': image.name,
              'size': await File(image.path).length(),
            }
          });

          completed++;
          if (onProgress != null) onProgress(completed, total);
        } catch (e) {
          print("Failed to upload individual photo: $e");
          // Continue with others
        }
      }));

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
}