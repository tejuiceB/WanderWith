import 'dart:io';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import '../models/trip.dart';

class PostService {
  final SupabaseClient _supabase = Supabase.instance.client;
  SupabaseClient get supabase => _supabase;

  // Global refresh signal for feeds
  static final StreamController<void> _refreshController = StreamController<void>.broadcast();
  static Stream<void> get refreshStream => _refreshController.stream;
  static void notifyRefresh() => _refreshController.add(null);

  /// Create a new travel post
  Future<void> createPost({
    required File imageFile,
    required String fileName,
    String? caption,
    String? location,
    String visibility = 'followers',
    String? tripId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    try {
      final String path = 'posts/${user.id}/$fileName';
      await _supabase.storage.from('posts').upload(path, imageFile);
      final String imageUrl = _supabase.storage.from('posts').getPublicUrl(path);

      // Extract Hashtags & Mentions
      final socialData = (caption != null && caption.isNotEmpty) 
          ? await _parseSocialEngagement(caption)
          : {'hashtags': [], 'mentions': []};

      await _supabase.from('posts').insert({
        'user_id': user.id,
        'trip_id': tripId,
        'image_url': imageUrl,
        'caption': caption,
        'location': location,
        'visibility': visibility,
        'hashtags': socialData['hashtags'],
        'mentions': socialData['mentions'],
      });

      notifyRefresh();
    } catch (e) {
      print("Error creating post: $e");
      rethrow;
    }
  }

  /// Extracts Hashtags and Mentions from text
  Future<Map<String, List<String>>> _parseSocialEngagement(String text) async {
    // 1. Hashtags (#travel #wander)
    final hashtags = RegExp(r'\B#\w\w+')
        .allMatches(text)
        .map((match) => match.group(0)!.substring(1).toLowerCase())
        .toSet()
        .toList();

    // 2. Mentions Parsing (@tejas @traveler)
    final mentionUsernames = RegExp(r'\B@\w\w+')
        .allMatches(text)
        .map((match) => match.group(0)!.substring(1).toLowerCase())
        .toSet()
        .toList();

    List<String> mentionIds = [];
    if (mentionUsernames.isNotEmpty) {
      final List<dynamic> profiles = await _supabase
          .from('profiles')
          .select('id')
          .inFilter('username', mentionUsernames);
      
      mentionIds = profiles.map((p) => p['id'] as String).toList();
    }

    return {
      'hashtags': hashtags,
      'mentions': mentionIds,
    };
  }

  /// Hard delete a post and its associated image from storage
  Future<void> deletePost(Post post) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    try {
      // 1. Delete image from storage if it exists
      if (post.imageUrl.isNotEmpty) {
        // Extract the path from the public URL
        // Example URL: https://ixrxxiyvxxoxoxox.supabase.co/storage/v1/object/public/posts/posts/USER_ID/FILENAME.jpg
        // We need the part after '/posts/' (the bucket name)
        final uri = Uri.parse(post.imageUrl);
        final pathSegments = uri.pathSegments;
        final postsIndex = pathSegments.indexOf('posts');
        if (postsIndex != -1 && postsIndex + 1 < pathSegments.length) {
          final storagePath = pathSegments.sublist(postsIndex + 1).join('/');
          await _supabase.storage.from('posts').remove([storagePath]);
        }
      }

      // 2. Hard delete from DB with user_id check for extra safety
      await _supabase
          .from('posts')
          .delete()
          .eq('id', post.id)
          .eq('user_id', user.id);
      
      notifyRefresh();
    } catch (e) {
      print("Error deleting post: $e");
      rethrow;
    }
  }

  /// Update post caption
  Future<void> updatePostCaption(String postId, String caption) async {
    try {
      await _supabase
          .from('posts')
          .update({'caption': caption})
          .eq('id', postId);
      
      notifyRefresh();
    } catch (e) {
      print("Error updating post caption: $e");
      rethrow;
    }
  }

  /// Archive or Unarchive a post
  Future<void> setPostArchived(String postId, bool archived) async {
    try {
      await _supabase
          .from('posts')
          .update({'is_archived': archived})
          .eq('id', postId);
      
      notifyRefresh();
    } catch (e) {
      print("Error setting post archive status: $e");
      rethrow;
    }
  }

  /// Get archived posts for current user
  Future<List<Post>> getArchivedPosts({int limit = 20, DateTime? beforeTimestamp}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      var query = _supabase
          .from('posts')
          .select('*, profiles!user_id(*), is_liked:likes(user_id)')
          .eq('user_id', user.id)
          .eq('is_archived', true)
          .eq('is_deleted', false);

      if (beforeTimestamp != null) {
        query = query.lt('created_at', beforeTimestamp.toIso8601String());
      }

      final List<dynamic> response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) {
        var authorMap = json['profiles'];
        if (authorMap is List && authorMap.isNotEmpty) authorMap = authorMap[0];
        final author = authorMap != null ? UserProfile.fromMap(authorMap as Map<String, dynamic>) : null;
        
        final likesRaw = json['is_liked'];
        final bool isLiked = (likesRaw is List) 
            ? likesRaw.any((l) => l['user_id'] == user.id)
            : (likesRaw != null && (likesRaw as Map)['user_id'] == user.id);

        return Post.fromJson(json, author: author, isLiked: isLiked);
      }).toList();
    } catch (e) {
      print("Error fetching archived posts: $e");
      return [];
    }
  }

  /// Toggle Like (Harden for persistence)
  Future<bool> toggleLike(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // 1. Check if already liked
      final currentLike = await _supabase
          .from('likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (currentLike != null) {
        // 2. Unlike
        await _supabase
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
        return false;
      } else {
        // 3. Like
        await _supabase.from('likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });

        // 4. Trigger Notification (Optimized: Check if not self-like)
        final post = await getPost(postId);
        if (post != null && post.userId != user.id) {
           final currentUserProfile = await getCurrentUserProfile();
           final senderName = currentUserProfile?.displayName ?? 'Someone';
           
           await NotificationService().sendNotification(
              toUserId: post.userId,
              title: "New Like! ❤️",
              body: "$senderName liked your post.",
              type: NotificationType.like,
              metadata: {'postId': postId}
           );
        }

        return true;
      }
    } catch (e) {
      print("Error toggling like: $e");
      rethrow; // Rethrow to trigger revert in UI
    }
  }

  /// Add a comment
  Future<void> addComment(String postId, String content, {String? parentCommentId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    try {
      await _supabase.from('comments').insert({
        'post_id': postId,
        'user_id': user.id,
        'content': content,
        'parent_comment_id': parentCommentId,
      });

      // Notify post owner
      final post = await getPost(postId);
      if (post != null && post.userId != user.id) {
         final currentUserProfile = await getCurrentUserProfile();
         final senderName = currentUserProfile?.displayName ?? 'Someone';
         
         await NotificationService().sendNotification(
            toUserId: post.userId,
            title: "New Comment! 💬",
            body: "$senderName: $content",
            type: NotificationType.comment,
            metadata: {'postId': postId}
         );
      }

      // Note: Mentions in comments are currently handled by array logic in POSTS. 
      // For comments, we'll implement array-based mentions if needed later, 
      // or stick to the legacy mentions table if complexity warrants.
      // For now, let's keep it simple as per optimization goal.
    } catch (e) {
      print("Error adding comment: $e");
      rethrow;
    }
  }

  /// Update a comment (Only writer confirmed by RLS)
  Future<void> updateComment(String commentId, String content) async {
    try {
      await _supabase
          .from('comments')
          .update({'content': content})
          .eq('id', commentId);
    } catch (e) {
      print("Error updating comment: $e");
      rethrow;
    }
  }

  /// Delete a comment (Writer or Post Creator confirmed by RLS)
  Future<void> deleteComment(String commentId) async {
    try {
      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId);
    } catch (e) {
      print("Error deleting comment: $e");
      rethrow;
    }
  }

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromMap(response);
    } catch (e) {
      print("Error fetching current user profile: $e");
      return null;
    }
  }

  /// Search users for mentions (@username)
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await _supabase
          .from('searchable_profiles') // Query the search-safe view
          .select()
          .ilike('username', '$query%')
          .limit(5);
      
      return (response as List).map((map) => UserProfile.fromMap(map)).toList();
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }

  /// Get Comments for a post (Paginated)
  Future<List<Map<String, dynamic>>> getComments(String postId, {int limit = 10, DateTime? beforeTimestamp}) async {
    try {
      var query = _supabase
          .from('comments')
          .select('*, profiles(id, display_name, avatar_url, username)')
          .eq('post_id', postId);

      if (beforeTimestamp != null) {
        query = query.lt('created_at', beforeTimestamp.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching comments: $e");
      return [];
    }
  }

  /// Get posts for a specific user (Optimized with cached counts)
  Future<List<Post>> getUserPosts(String userId, {int limit = 10, DateTime? beforeTimestamp}) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return [];

    try {
      var query = _supabase
          .from('posts')
          .select('*, profiles!user_id(*), is_liked:likes(user_id)')
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .eq('is_archived', false);

      if (beforeTimestamp != null) {
        query = query.lt('created_at', beforeTimestamp.toIso8601String());
      }

      final List<dynamic> response = await query
          .order('created_at', ascending: false)
          .limit(limit);

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
      print("Error fetching user posts: $e");
      return [];
    }
  }

  /// Get a single post by ID (Optimized)
  Future<Post?> getPost(String postId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return null;

    try {
      final response = await _supabase
          .from('posts')
          .select('*, profiles!user_id(*), is_liked:likes(user_id)')
          .eq('id', postId)
          .eq('is_deleted', false)
          .eq('is_archived', false)
          .maybeSingle();

      if (response == null) return null;

      final authorRaw = response['profiles'];
      Map<String, dynamic>? authorMap;
      if (authorRaw is List && authorRaw.isNotEmpty) {
         authorMap = authorRaw[0];
      } else if (authorRaw is Map) {
         authorMap = authorRaw as Map<String, dynamic>;
      }
      
      final author = authorMap != null ? UserProfile.fromMap(authorMap) : null;
      
      final likesRaw = response['is_liked'];
      final bool isLiked = (likesRaw is List) 
          ? likesRaw.any((l) => l['user_id'] == currentUser.id)
          : (likesRaw != null && (likesRaw as Map)['user_id'] == currentUser.id);

      return Post.fromJson(response, author: author, isLiked: isLiked);
    } catch (e) {
      print("Error fetching post: $e");
      return null;
    }
  }

  /// Get Trending Hashtags (In-memory aggregation for now)
  Future<List<Map<String, dynamic>>> getTrendingHashtags() async {
    try {
      final response = await _supabase
          .from('posts')
          .select('hashtags')
          .eq('is_deleted', false)
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .limit(100);

      final Map<String, int> counts = {};
      for (var row in response) {
        final List<dynamic> hashtags = row['hashtags'] ?? [];
        for (var tag in hashtags) {
          final sTag = tag.toString().toLowerCase();
          counts[sTag] = (counts[sTag] ?? 0) + 1;
        }
      }

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(10).map((e) => {'tag': e.key, 'count': e.value}).toList();
    } catch (e) {
      print("Error fetching trending hashtags: $e");
      return [];
    }
  }

  /// Discover Feed (Recently popular or just latest for now)
  Future<List<Post>> getDiscoverFeed({int limit = 20, DateTime? beforeTimestamp}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      var query = _supabase
          .from('posts')
          .select('*, profiles!user_id(*), is_liked:likes(user_id)')
          .eq('is_deleted', false)
          .eq('is_archived', false)
          .eq('visibility', 'public');

      if (beforeTimestamp != null) {
        query = query.lt('created_at', beforeTimestamp.toIso8601String());
      }

      final List<dynamic> response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) {
        var authorMap = json['profiles'];
        if (authorMap is List && authorMap.isNotEmpty) authorMap = authorMap[0];
        final author = authorMap != null ? UserProfile.fromMap(authorMap as Map<String, dynamic>) : null;
        
        final likesRaw = json['is_liked'];
        final bool isLiked = currentUser != null && ((likesRaw is List) 
            ? likesRaw.any((l) => l['user_id'] == currentUser.id)
            : (likesRaw != null && (likesRaw as Map)['user_id'] == currentUser.id));

        return Post.fromJson(json, author: author, isLiked: isLiked);
      }).toList();
    } catch (e) {
      print("Error fetching discover feed: $e");
      return [];
    }
  }

  /// Search Posts by Hashtag
  Future<List<Post>> searchPostsByHashtag(String hashtag, {int limit = 20}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final response = await _supabase
          .from('posts')
          .select('*, profiles!user_id(*), is_liked:likes(user_id)')
          .contains('hashtags', [hashtag.toLowerCase()])
          .eq('is_deleted', false)
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) {
        var authorMap = json['profiles'];
        if (authorMap is List && authorMap.isNotEmpty) authorMap = authorMap[0];
        final author = authorMap != null ? UserProfile.fromMap(authorMap as Map<String, dynamic>) : null;
        
        final likesRaw = json['is_liked'];
        final bool isLiked = currentUser != null && ((likesRaw is List) 
            ? likesRaw.any((l) => l['user_id'] == currentUser.id)
            : (likesRaw != null && (likesRaw as Map)['user_id'] == currentUser.id));

        return Post.fromJson(json, author: author, isLiked: isLiked);
      }).toList();
    } catch (e) {
      print("Error searching posts by hashtag: $e");
      return [];
    }
  }
  /// Get Suggested Agency Profiles
  Future<List<UserProfile>> getSuggestedAgencies({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'agency')
          .order('followers_count', ascending: false)
          .limit(limit);
      
      return (response as List).map((map) => UserProfile.fromMap(map)).toList();
    } catch (e) {
      print("Error fetching suggested agencies: $e");
      return [];
    }
  }

  /// Get Trending Agency Trips
  Future<List<Trip>> getSuggestedTrips({int limit = 5}) async {
    try {
       final response = await _supabase
          .from('searchable_agency_trips')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
       
       return (response as List).map((map) => Trip.fromMap(map)).toList();
    } catch (e) {
      print("Error fetching suggested trips: $e");
      return [];
    }
  }
}
