import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/follow_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final FollowService _followService = FollowService();
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _followService.getBlockedUsers();
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading blocked users: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnblock(String userId) async {
    try {
      await _followService.unblockUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User unblocked")),
      );
      _loadBlockedUsers(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error unblocking: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Blocked Accounts",
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blockedUsers.length,
                  separatorBuilder: (context, index) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final userWrap = _blockedUsers[index];
                    final profile = userWrap['profiles'] as Map<String, dynamic>?;
                    final userId = userWrap['blocked_id'] as String;
                    final displayName = profile?['display_name'] ?? "Hidden Profile";
                    final username = profile?['username'] ?? "blocked_user";
                    final avatarUrl = profile?['avatar_url'] as String?;

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                          child: avatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text("@$username", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _handleUnblock(userId),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text("Unblock", style: GoogleFonts.inter(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block_flipped, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No blocked accounts",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            "Users you block will appear here.",
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
