import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/follow_service.dart';
import '../models/user_profile.dart';
import 'profile_screen.dart';

enum FollowListType { followers, following }

class FollowsListScreen extends StatefulWidget {
  final String userId;
  final String displayName;
  final FollowListType type;

  const FollowsListScreen({
    super.key,
    required this.userId,
    required this.displayName,
    required this.type,
  });

  @override
  State<FollowsListScreen> createState() => _FollowsListScreenState();
}

class _FollowsListScreenState extends State<FollowsListScreen> {
  final FollowService _followService = FollowService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  bool get isCurrentUser => widget.userId == _supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    final results = widget.type == FollowListType.followers
        ? await _followService.getFollowers(widget.userId)
        : await _followService.getFollowing(widget.userId);

    if (mounted) {
      setState(() {
        _users = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == FollowListType.followers ? "Followers" : "Following";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          children: [
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
            Text(widget.displayName, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Skeletonizer(
        enabled: _isLoading,
        child: _isLoading && _users.isEmpty
            ? _buildSkeletonList()
            : _users.isEmpty
                ? _buildEmptyState(title)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _users.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final item = _users[index];
                      // The query returns profiles based on the relationship
                      final profileData = item['profiles'];
                      return _buildUserTile(profileData);
                    },
                  ),
      ),
    );
  }

  Widget _buildUserTile(dynamic profile) {
    final String uid = profile['id'];
    final String name = profile['display_name'] ?? "User";
    final String? avatarUrl = profile['avatar_url'];
    final bool isPrivate = profile['is_private'] ?? false;
    final String username = name.toLowerCase().replaceAll(' ', '');

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(userId: uid)),
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade100,
        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? CachedNetworkImageProvider(avatarUrl)
            : null,
        child: (avatarUrl == null || avatarUrl.isEmpty)
            ? Text(name[0].toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey))
            : null,
      ),
      title: Row(
        children: [
          Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
          if (isPrivate) ...[
            const SizedBox(width: 4),
            const Icon(Icons.lock, size: 12, color: Colors.grey),
          ]
        ],
      ),
      subtitle: Text("@$username", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: 10,
      itemBuilder: (context, index) => ListTile(
        leading: const CircleAvatar(radius: 24),
        title: Container(height: 12, width: 100, color: Colors.white),
        subtitle: Container(height: 10, width: 60, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    final String message = widget.type == FollowListType.followers
        ? (isCurrentUser ? "No one is following you yet." : "${widget.displayName} doesn't have any followers yet.")
        : (isCurrentUser ? "You are not following anyone yet." : "${widget.displayName} isn't following anyone yet.");

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.people_outline, size: 64, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              "No $title Found",
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
            ),
            if (isCurrentUser) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleInviteFriends,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text("Invite Friends"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Go Back", style: GoogleFonts.inter(color: Colors.blueAccent)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleInviteFriends() {
    Share.share(
      "Join me on WanderWith, the most intentional and private travel app! 🌍✨\n\nDownload now: https://tejuice.fun",
      subject: "Join WanderWith",
    );
  }
}
