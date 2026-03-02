import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/follow_service.dart';
import '../theme/theme_extensions.dart';

class RestrictedUsersScreen extends StatefulWidget {
  const RestrictedUsersScreen({super.key});

  @override
  State<RestrictedUsersScreen> createState() => _RestrictedUsersScreenState();
}

class _RestrictedUsersScreenState extends State<RestrictedUsersScreen> {
  final FollowService _followService = FollowService();
  List<Map<String, dynamic>> _restrictedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestrictedUsers();
  }

  Future<void> _loadRestrictedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _followService.getRestrictedUsers();
      setState(() {
        _restrictedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading restricted users: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnrestrict(String userId) async {
    try {
      await _followService.unrestrictUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User unrestricted")),
      );
      _loadRestrictedUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Restricted Accounts",
          style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _restrictedUsers.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _restrictedUsers.length,
                  separatorBuilder: (context, index) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final entry = _restrictedUsers[index];
                    final profile = entry['profiles'] as Map<String, dynamic>?;
                    final userId = entry['restricted_user_id'] as String;
                    final displayName = profile?['display_name'] ?? "User";
                    final username = profile?['username'] ?? "user";
                    final avatarUrl = profile?['avatar_url'] as String?;

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: context.appColors.surfaceBg,
                          backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                          child: avatarUrl == null ? Icon(Icons.person, color: context.appColors.textSecondary) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text("@$username", style: GoogleFonts.inter(color: context.appColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                "Can see your profile but can't interact",
                                style: GoogleFonts.inter(fontSize: 11, color: context.appColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _handleUnrestrict(userId),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.appColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text("Unrestrict", style: GoogleFonts.inter(color: context.appColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
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
          Icon(Icons.visibility_off_outlined, size: 64, color: context.appColors.textMuted),
          const SizedBox(height: 16),
          Text(
            "No restricted accounts",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: context.appColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Restricted users can see your profile but can't like, comment, or send you messages.",
              style: GoogleFonts.inter(color: context.appColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
