import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/follow_service.dart';
import 'profile_screen.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  final FollowService _followService = FollowService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final data = await _followService.getPendingRequests();
      if (mounted) {
        setState(() {
          _requests = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _accept(String followerId) async {
    // Optimistic remove
    setState(() {
      _requests.removeWhere((r) => r['follower_id'] == followerId);
    });
    
    try {
       await _followService.acceptFollowRequest(followerId);
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request accepted")));
    } catch (e) {
       _fetchRequests(); // Revert on error
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _reject(String followerId) async {
     // Optimistic remove
    setState(() {
      _requests.removeWhere((r) => r['follower_id'] == followerId);
    });
    
    try {
       await _followService.rejectFollowRequest(followerId);
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request deleted")));
    } catch (e) {
       _fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.scaffoldBg,
      appBar: AppBar(
        title: Text("Follow Requests", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
        backgroundColor: context.appColors.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.appColors.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        child: _isLoading 
            ? _buildSkeletonList()
            : _requests.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      // The query returns `profiles!follower_id(...)`
                      // Supabase dart might nest it or flatten it depending on config, but based on service:
                      // .select('follower_id, created_at, profiles!follower_id(id, display_name, avatar_url)')
                      
                      final profile = req['profiles'] as Map<String, dynamic>? ?? {};
                      final name = profile['display_name'] ?? 'Unknown';
                      final avatar = profile['avatar_url'];
                      final uid = req['follower_id'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.appColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.appColors.border),
                          boxShadow: [
                             BoxShadow(color: context.appColors.shadow, blurRadius: 8, offset: const Offset(0, 2))
                          ]
                        ),
                        child: Row(
                          children: [
                             GestureDetector(
                               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: uid))),
                               child: CircleAvatar(
                                 radius: 24,
                                 backgroundImage: (avatar != null && avatar.isNotEmpty) ? CachedNetworkImageProvider(avatar) : null,
                                 child: (avatar == null || avatar.isEmpty) ? Text(name[0], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)) : null,
                               ),
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("Wants to follow you", style: GoogleFonts.inter(fontSize: 12, color: context.appColors.textSecondary)),
                                 ],
                               ),
                             ),
                             Row(
                               children: [
                                  IconButton(
                                    onPressed: () => _accept(uid), 
                                    icon: Icon(Icons.check_circle, color: AppColors.brand, size: 32),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    onPressed: () => _reject(uid), 
                                    icon: Icon(Icons.cancel, color: context.appColors.textSecondary, size: 32),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                               ],
                             )
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              Icon(Icons.notifications_none, size: 64, color: context.appColors.textMuted),
              const SizedBox(height: 16),
              Text("No pending requests", style: GoogleFonts.inter(color: context.appColors.textSecondary)),
           ],
        ),
     );
  }

  Widget _buildSkeletonList() {
     return ListView.builder(
       padding: const EdgeInsets.all(16),
       itemCount: 5,
       itemBuilder: (context, index) {
          return Skeletonizer(
             enabled: true,
             child: Container(
               margin: const EdgeInsets.only(bottom: 16),
               height: 72,
               decoration: BoxDecoration(color: context.appColors.cardBg, borderRadius: BorderRadius.circular(16)),
               child: ListTile(
                  leading: const CircleAvatar(),
                  title: const Text("Loading Name"),
                  subtitle: const Text("Wants to follow you"),
               ),
             ),
          );
       }
     );
  }
}
