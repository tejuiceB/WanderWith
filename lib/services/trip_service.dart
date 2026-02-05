import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/notification.dart';
import 'notification_service.dart';
import 'analytics_service.dart';

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
  }) async {
    // Client-side ID generation
    final String tripId = _uuid.v4();
    
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
      }
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

  // Fetch users trips (Real-time)
  Stream<List<Trip>> getUserTrips(String uid) {
    // Postgrest supports filtering JSONB arrays or standard arrays using 'cs' (contains)
    // member_ids is likely a text[] or uuid[]
    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .map((List<Map<String, dynamic>> data) {
           // We need to filter client side or ensure the subscription is filtered.
           // Supabase Stream doesn't support complex array filters easily in the simplified SDK stream() method sometimes.
           // Ideally we use Row Level Security (RLS) so the user ONLY receives their trips.
           // So we just ask for 'trips' and RLS filters it on the server.
           return data.map((map) => _mapToTrip(map)).toList();
        });
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
      // 0. Validations: Prevent Owner Join & Duplicate Join
      Map<String, dynamic>? tripCheck;
      try {
        tripCheck = await _supabase
            .from('trips')
            .select('created_by, member_ids, metadata')
            .eq('id', tripId)
            .maybeSingle();
      } catch (_) {
        // Ignore: RLS may block until after RPC adds membership.
      }

      if (tripCheck != null) {
        final createdBy = _normalizeId(tripCheck['created_by']);
        if (createdBy == uid) {
          throw Exception("You are the owner of this trip. You cannot join it.");
        }

        final membersRaw = tripCheck['member_ids'];
        final members = membersRaw is List
            ? membersRaw.map(_normalizeId).where((id) => id.isNotEmpty).toList()
            : <String>[];

        final meta = Map<String, dynamic>.from(tripCheck['metadata'] ?? {});
        final pendingRaw = meta['pending_members'];
        final pendingList = pendingRaw is List
            ? pendingRaw.map(_normalizeId).where((id) => id.isNotEmpty).toList()
            : <String>[];

        if (members.contains(uid)) {
          if (pendingList.contains(uid)) {
            throw Exception("Your join request is already pending.");
          }
          throw Exception("You have already joined this trip.");
        }
      }

      // 1. Add to member_ids table (Low-level database access)
      // Use RPC function to bypass RLS "select" restriction and add to members array
      await _supabase.rpc('join_trip', params: {
        'trip_uuid': tripId, 
        'user_id': uid
      });

      // 2. Mark as "Pending" in metadata immediately
      // Now that we are a member (via step 1), we can likely read/update this trip
      // We rely on the client to put themselves in 'pending' state
      final resp = await _supabase
          .from('trips')
          .select('created_by, member_ids, metadata')
          .eq('id', tripId)
          .single();

      final createdBy = _normalizeId(resp['created_by']);
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
      final pendingRaw = metadata['pending_members'];
      final pending = pendingRaw is List
          ? pendingRaw.map(_normalizeId).where((id) => id.isNotEmpty).toList()
          : <String>[];

      // Logic Update: We just joined via RPC, so we are definitely in 'member_ids'.
      // We rely on the PRE-CHECK (above) to catch users who were ALREADY members before this function ran.
      // Therefore, we simply proceed to mark as pending.

      if (!pending.contains(uid)) {
        pending.add(uid);
        metadata['pending_members'] = pending;
        await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);

        final adminIdsRaw = metadata['adminIds'];
        final adminIds = adminIdsRaw is List
            ? adminIdsRaw.map(_normalizeId).where((id) => id.isNotEmpty).toList()
            : <String>[];

        final validAdmins = adminIds.isNotEmpty ? adminIds : [createdBy].where((id) => id.isNotEmpty).toList();

        final userResp = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', uid)
            .maybeSingle();
        final userName = userResp != null ? userResp['display_name'] : 'Someone';

        for (final adminId in validAdmins) {
          await _notificationService.sendNotification(
            toUserId: adminId,
            title: "New Join Request",
            body: "$userName wants to join your trip!",
            type: NotificationType.joinRequest,
            tripId: tripId,
          );
        }
      }

    } catch (e) {
      // Clean up error message
      String message;
      final text = e.toString();

      if (text.contains('Trip ID not found')) {
        message = "Trip ID not found";
      } else if (text.contains('You are the owner of this trip')) {
        message = "You are the owner of this trip. You cannot join it.";
      } else if (text.contains('You have already joined this trip')) {
        message = "You have already joined this trip.";
      } else if (text.contains('Your join request is already pending')) {
        message = "Your join request is already pending.";
      } else {
        message = text.replaceFirst('Exception: ', '');
      }
      _handleException(e);
      throw Exception(message);
    }
  }

  // Accept Member Request
  Future<void> acceptMember(String tripId, String uid) async {
    try {
      final resp = await _supabase.from('trips').select('name, metadata').eq('id', tripId).single();
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
      final tripName = resp['name'];
      
      List<String> pending = [];
      if (metadata['pending_members'] != null) {
         pending = List<String>.from(metadata['pending_members']);
      }
      
      pending.remove(uid);
      metadata['pending_members'] = pending;
      
      await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);

      // Log Analytics
      await _analyticsService.logEvent('member_joined_trip', parameters: {
        'trip_id': tripId,
        'user_id': uid
      });

      // Notify User
      await _notificationService.sendNotification(
        toUserId: uid,
        title: "Request Accepted! 🎉",
        body: "You have been accepted into '$tripName'.",
        type: NotificationType.joinResponse,
        tripId: tripId,
      );

    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }


  // Update Budget (Single Cost + Allocations)
  Future<void> updateTripBudget(String tripId, double estimatedCost, List<Map<String, dynamic>> allocations) async {
     try {
       final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
       final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
       
       metadata['estimated_cost'] = estimatedCost;
       metadata['budget_allocations'] = allocations; // [{'title': 'Hotel', 'cost': 500}, ...]
       
       await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);
     } catch (e) {
       _handleException(e);
       rethrow;
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

  // Delete Photo
  Future<void> deletePhoto(String tripId, String photoId, String photoUrl, String uploaderId) async {
    try {
      // 1. Delete from database record (Use ID for precision)
      final deleted = await _supabase.from('photos').delete().eq('id', photoId).select();
      if (deleted.isEmpty) {
        throw Exception("Photo not deleted (RLS or missing row)");
      }
      
      // 2. Delete from Storage bucket
      final uri = Uri.parse(photoUrl);
      final segments = uri.pathSegments;
      // pathSegments example: ['storage', 'v1', 'object', 'public', 'trip_photos', 'user123', 'file.jpg']
      
      final bucketIndex = segments.indexOf('trip_photos');
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
         final path = segments.sublist(bucketIndex + 1).join('/');
         await _supabase.storage.from('trip_photos').remove([path]);
      }
      
    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  // Reject Member Request (Decline join request)
  Future<void> rejectMember(String tripId, String uid) async {
    try {
      final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});

      List<String> pending = [];
      if (metadata['pending_members'] != null) {
         pending = List<String>.from(metadata['pending_members']);
      }

      if (pending.contains(uid)) {
        pending.remove(uid);
        metadata['pending_members'] = pending;
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
      
      await _supabase.from('trips').update({
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
        'is_date_decided': true
      }).eq('id', tripId);

      if (uid != null) {
        await _notificationService.notifyTripMembers(
          tripId: tripId,
          title: "Dates Updated 📅",
          body: "Trip dates set to ${start.day}/${start.month} - ${end.day}/${end.month}",
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

  Future<void> createPoll(String tripId, String question, List<String> options, String creatorId) async {
    try {
      final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
      final polls = List<Map<String, dynamic>>.from(metadata['polls'] ?? []);

      final newPoll = {
        'id': _uuid.v4(),
        'question': question,
        'options': options,
        'createdBy': creatorId,
        'createdAt': DateTime.now().toIso8601String(),
        'votes': {} // {userId: optionIndex}
      };

      polls.add(newPoll);
      metadata['polls'] = polls;

      await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);

      _notificationService.notifyTripMembers(
        tripId: tripId,
        title: "New Poll 📊",
        body: question,
        type: NotificationType.pollAdded,
        excludeUserId: creatorId,
      );

    } catch (e) {
      print("Error creating poll: $e");
      _handleException(e);
      rethrow;
    }
  }

  Future<void> votePoll(String tripId, String pollId, String uid, int optionIndex) async {
    try {
      final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
      final polls = List<Map<String, dynamic>>.from(metadata['polls'] ?? []);

      // Find and update poll
      final pollIndex = polls.indexWhere((p) => p['id'] == pollId);
      if (pollIndex == -1) throw Exception("Poll not found");

      final poll = Map<String, dynamic>.from(polls[pollIndex]);
      final votes = Map<String, dynamic>.from(poll['votes'] ?? {});
      
      votes[uid] = optionIndex; // User votes for option index
      poll['votes'] = votes;
      polls[pollIndex] = poll;
      metadata['polls'] = polls;

      await _supabase.from('trips').update({'metadata': metadata}).eq('id', tripId);

      // Log Analytics
      await _analyticsService.logEvent('poll_voted', parameters: {
         'trip_id': tripId,
         'poll_id': pollId,
         'option_idx': optionIndex
      });

    } catch (e) {
      _handleException(e);
      rethrow;
    }
  }

  Future<void> addAdmin(String tripId, String newAdminId) async {
    try {
      final resp = await _supabase.from('trips').select('metadata').eq('id', tripId).single();
      final metadata = Map<String, dynamic>.from(resp['metadata'] ?? {});
      
      // Get current adminIds or init with creator? 
      // Current trip service doesn't fetch creator easily here, but we can rely on existing list.
      // But we are reading metadata only.
      // Wait, adminIds in 'metadata' might be missing if it's a legacy trip.
      List<String> adminIds = [];
      if (metadata['adminIds'] != null) {
         adminIds = List<String>.from(metadata['adminIds']);
      } else {
         // If missing, we should probably fetch the trip created_by.
         // But for now, let's assume we append to set.
         // If list is empty, we might accidentally lock out original creator if we overwrite?
         // No, 'Trip' model handles fallback. But here we are writing back to DB.
         // We must be careful.
         // Better strategy: Read 'created_by' and 'metadata' together.
      }
    } catch (e) { rethrow; }
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
}