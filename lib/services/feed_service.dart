import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/user_profile.dart';

class FeedService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Post>> getHomeFeed({int limit = 10, DateTime? beforeTimestamp}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      // 1. Get the list of people the current user follows
      final followingResponse = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id)
          .eq('status', 'accepted');
      
      final List<String> followingIds = (followingResponse as List)
          .map((f) => f['following_id'] as String)
          .toList();
      
      // 2. Add current user's own ID to the list
      followingIds.add(currentUser.id);

      // 3. Fetch posts from these users
      var query = _supabase
          .from('posts')
          .select('*, profiles!user_id(*), is_liked:likes(user_id)')
          .inFilter('user_id', followingIds)
          .eq('is_deleted', false);

      if (beforeTimestamp != null) {
        query = query.lt('created_at', beforeTimestamp.toIso8601String());
      }

      final List<dynamic> response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      if (response.isEmpty) return [];

      return response.map((json) {
        // Safe Author Mapping
        var authorMap = json['profiles'];
        if (authorMap is List && authorMap.isNotEmpty) {
           authorMap = authorMap[0];
        } else if (authorMap is List && authorMap.isEmpty) {
           authorMap = null;
        }
        
        final author = authorMap != null ? UserProfile.fromMap(authorMap as Map<String, dynamic>) : null;
        
        // Safe Liked Check
        final likesRaw = json['is_liked'];
        final bool isLiked = (likesRaw is List) 
            ? likesRaw.any((l) => l['user_id'] == currentUser.id)
            : (likesRaw != null && (likesRaw as Map)['user_id'] == currentUser.id);

        return Post.fromJson(json, author: author, isLiked: isLiked);
      }).toList();

    } catch (e) {
      print('Error fetching feed: $e');
      return [];
    }
  }
}
