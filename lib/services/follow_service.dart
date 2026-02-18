import 'package:supabase_flutter/supabase_flutter.dart';

enum FollowStatus {
  none,
  pending,
  following,
}

class FollowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the current user's follow status for the [targetUserId]
  Future<FollowStatus> getFollowStatus(String targetUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == targetUserId) return FollowStatus.none;

    try {
      final response = await _supabase
          .from('follows')
          .select('status')
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      if (response == null) return FollowStatus.none;

      final status = response['status'] as String;
      if (status == 'accepted') return FollowStatus.following;
      if (status == 'pending') return FollowStatus.pending;
      
      return FollowStatus.none;
    } catch (e) {
      print('Error getting follow status: $e');
      return FollowStatus.none;
    }
  }

  /// Sends a follow request or instantly follows if public
  Future<void> sendFollowRequest(String targetUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception("Not logged in");

    // 1. Check if target user is private
    final profile = await _supabase
        .from('profiles')
        .select('is_private')
        .eq('id', targetUserId)
        .single();
    
    final isPrivate = profile['is_private'] as bool? ?? true;
    final status = isPrivate ? 'pending' : 'accepted';

    // 2. Upsert into follows table to avoid duplicate key errors
    await _supabase.from('follows').upsert({
      'follower_id': currentUserId,
      'following_id': targetUserId,
      'status': status,
    }, onConflict: 'follower_id,following_id');
  }

  /// Unfollows a user or cancels a pending request
  Future<void> unfollow(String targetUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId);
  }

  /// Removes a follower (blocks/removes from follower list)
  Future<void> removeFollower(String followerId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', currentUserId);
  }

  /// Accepts a pending follow request
  Future<void> acceptFollowRequest(String followerId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    await _supabase
        .from('follows')
        .update({'status': 'accepted'})
        .eq('follower_id', followerId)
        .eq('following_id', currentUserId);
  }

  /// Reject is same as remove/delete
  Future<void> rejectFollowRequest(String followerId) async {
    await removeFollower(followerId);
  }

  /// Get pending follow requests for the CURRENT user
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      final response = await _supabase
          .from('follows')
          .select('follower_id, created_at, profiles!follower_id(id, display_name, avatar_url)')
          .eq('following_id', currentUserId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      // Flatten the response slightly for easier consumption
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching requests: $e");
      return [];
    }
  }
  
  /// Get list of followers for a user
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('follower_id, profiles!follower_id(id, display_name, avatar_url, bio, is_private)')
          .eq('following_id', userId)
          .eq('status', 'accepted');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching followers: $e");
      return [];
    }
  }

  /// Get list of following for a user
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('following_id, profiles!following_id(id, display_name, avatar_url, bio, is_private)')
          .eq('follower_id', userId)
          .eq('status', 'accepted');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching following: $e");
      return [];
    }
  }
  /// Get counts
  Future<Map<String, int>> getFollowCounts(String userId) async {
     final followers = await _supabase
        .from('follows')
        .count()
        .eq('following_id', userId)
        .eq('status', 'accepted');
        
     final following = await _supabase
        .from('follows')
        .count()
        .eq('follower_id', userId)
        .eq('status', 'accepted');
        
     return {
       'followers': followers,
       'following': following
     };
  }

  Stream<int> getPendingRequestsCountStream() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return Stream.value(0);

    // Filter in map as SupabaseStreamBuilder .eq() is version-dependent or restricted
    return _supabase
        .from('follows')
        .stream(primaryKey: ['follower_id', 'following_id'])
        .map((data) => data.where((row) => 
            row['following_id'] == uid && 
            row['status'] == 'pending'
        ).length);
  }

  /// Block a user
  Future<void> blockUser(String targetUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception("Not logged in");

    await _supabase.from('blocked_users').upsert({
      'blocker_id': currentUserId,
      'blocked_id': targetUserId,
    });
    // Trigger handle_user_block_cleanup in DB will handle the follows cleanup
  }

  /// Unblock a user
  Future<void> unblockUser(String targetUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception("Not logged in");

    await _supabase
        .from('blocked_users')
        .delete()
        .eq('blocker_id', currentUserId)
        .eq('blocked_id', targetUserId);
  }

  /// Get list of blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      final data = await _supabase.rpc('get_blocked_user_profiles');
      
      if (data == null) return [];
      
      // Map RPC table results to the 'profiles' join format the UI expects
      return (data as List).map((row) {
        final blockedId = row['blocked_id'] as String;
        return {
          'blocked_id': blockedId,
          'profiles': {
            'id': blockedId,
            'username': row['username'],
            'display_name': row['display_name'],
            'avatar_url': row['avatar_url'],
          }
        };
      }).toList();
    } catch (e) {
      print("Error fetching blocked users via RPC: $e");
      return [];
    }
  }

  /// Get structured relationship data between current user and target user
  Future<Map<String, dynamic>> getRelationshipStatus(String targetUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == targetUserId) {
      return {
        'is_following': false,
        'is_followed_by': false,
        'request_status': null,
        'is_blocked': false,
      };
    }

    try {
      final response = await _supabase.rpc(
        'get_relationship_status',
        params: {
          'viewer_id': currentUserId,
          'target_id': targetUserId,
        },
      );
      if (response == null) {
        return {
          'is_following': false,
          'is_followed_by': false,
          'request_status': null,
          'is_blocked': false,
        };
      }
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error getting relationship status: $e');
      return {
        'is_following': false,
        'is_followed_by': false,
        'request_status': null,
        'is_blocked': false,
      };
    }
  }
}
