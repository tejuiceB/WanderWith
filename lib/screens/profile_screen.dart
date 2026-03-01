import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';
import '../services/follow_service.dart';
import 'trip_dashboard_screen.dart';
import 'settings_screen.dart';
import 'follow_requests_screen.dart';
import 'follows_list_screen.dart';
import '../services/post_service.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';
import '../widgets/trip_card.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user
  final String? username; // New: support deep linking by username
  const ProfileScreen({super.key, this.userId, this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TripService _tripService = TripService();
  final FollowService _followService = FollowService();
  final PostService _postService = PostService();
  late TabController _tabController;
  StreamSubscription? _postRefreshSub;
  
  List<Post> _userPosts = [];
  bool _isLoadingPosts = true;
  
  UserProfile? _targetProfile;
  bool _isLoadingTargetProfile = false;
  
  // Relationship State
  bool _isFollowing = false;
  bool _isFollowedBy = false;
  bool _isBlocked = false;
  String? _requestStatus; // 'pending', 'accepted', or null
  bool _isCheckingFollow = false;
  
  
  bool get isCurrentUser {
    final authId = Supabase.instance.client.auth.currentUser?.id;
    if (widget.userId == authId) return true;
    if (widget.userId == null && widget.username == null) return true;
    if (_targetProfile != null && _targetProfile!.uid == authId) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (isCurrentUser) {
       _isCheckingFollow = false;
       _loadProfileData(); // Reload stats for current user too
    } else {
       _loadProfileData();
    }

    _postRefreshSub = PostService.refreshStream.listen((_) {
      if (mounted && isCurrentUser) {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) _loadUserPosts(uid);
      }
    });
  }

  bool _isLoadingMorePosts = false;
  bool _hasMorePosts = true;

  Future<void> _loadUserPosts(String userId) async {
    setState(() {
      _isLoadingPosts = true;
      _userPosts = [];
      _hasMorePosts = true;
    });
    final posts = await _postService.getUserPosts(userId, limit: 12);
    if (mounted) {
      setState(() {
        _userPosts = posts;
        _isLoadingPosts = false;
        if (posts.length < 12) _hasMorePosts = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMorePosts || !_hasMorePosts || _targetProfile == null) return;
    
    final userId = _targetProfile?.uid ?? widget.userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoadingMorePosts = true);
    
    try {
      final lastPost = _userPosts.last;
      final morePosts = await _postService.getUserPosts(
        userId, 
        limit: 12, 
        beforeTimestamp: lastPost.createdAt
      );

      if (mounted) {
        setState(() {
          _userPosts.addAll(morePosts);
          _isLoadingMorePosts = false;
          if (morePosts.length < 12) _hasMorePosts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMorePosts = false);
      print("Error loading more user posts: $e");
    }
  }

  Future<void> _loadProfileData() async {
    final targetId = widget.userId ?? _targetProfile?.uid;
    
    setState(() {
      _isCheckingFollow = true;
      _isLoadingTargetProfile = true;
      // Reset relationship state to avoid stubs from previous profiles
      _isFollowing = false;
      _isFollowedBy = false;
      _requestStatus = null;
    });

    try {
      if (widget.username != null && widget.userId == null) {
        final profile = await Provider.of<AuthService>(context, listen: false).getProfileByUsername(widget.username!);
        if (mounted && profile != null) {
          setState(() => _targetProfile = profile);
          final relationship = await _followService.getRelationshipStatus(profile.uid);
          if (mounted) {
            setState(() {
              _isFollowing = relationship['is_following'] ?? false;
              _isFollowedBy = relationship['is_followed_by'] ?? false;
              _isBlocked = relationship['is_blocked'] ?? false;
              _requestStatus = relationship['request_status'];
            });
          }
          if (!_isBlocked) {
            await _loadUserPosts(profile.uid);
          }
        }
      } else if (widget.userId != null) {
        final results = await Future.wait<dynamic>([
          _followService.getRelationshipStatus(widget.userId!),
          _fetchTargetProfile(),
          _loadUserPosts(widget.userId!),
        ]);
        
        if (mounted) {
          final relationship = results[0] as Map<String, dynamic>? ?? {
            'is_following': false,
            'is_followed_by': false,
            'request_status': null,
            'is_blocked': false,
          };
          setState(() {
            _isFollowing = relationship['is_following'] ?? false;
            _isFollowedBy = relationship['is_followed_by'] ?? false;
            _isBlocked = relationship['is_blocked'] ?? false;
            _requestStatus = relationship['request_status'];
          });
          if (!_isBlocked) {
            await results[2]; // posts loading
          }
        }
      } else if (isCurrentUser) {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          // Force-refresh profile from DB to ensure interests and other
          // fields are up-to-date (fixes race condition after onboarding).
          await Provider.of<AuthService>(context, listen: false).refreshProfile();
          await _loadUserPosts(uid);
        }
      }
    } catch (e) {
      print("Error loading profile data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingFollow = false;
          _isLoadingTargetProfile = false;
        });
      }
    }
  }

  Future<void> _fetchTargetProfile() async {
     final profile = await Provider.of<AuthService>(context, listen: false).getOtherUserProfile(widget.userId!);
     if (mounted) {
        setState(() {
           _targetProfile = profile;
        });
     }
  }


  @override
  void dispose() {
    _tabController.dispose();
    _postRefreshSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.appColors;
    final isDark = context.isDark;
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    final currentUserProfile = authService.userProfile;
    final isLoading = authService.isLoadingProfile;

    // Use target profile if not current user, otherwise use auth profile
    final profile = isLoading || _isLoadingTargetProfile
        ? UserProfile(uid: 'skeleton', displayName: '          ', role: 'traveler', email: '          ', interests: ['        ', '        ', '        ']) 
        : (isCurrentUser ? (currentUserProfile ?? UserProfile(uid: 'unknown', displayName: 'User')) : (_targetProfile ?? UserProfile(uid: 'unknown', displayName: 'User')));

    final bool isProfileLoading = isLoading || _isLoadingTargetProfile;
    
    // Relationship derivation
    final bool isPrivate = profile.isPrivate;
    final bool isFollowing = _isFollowing;
    final bool isFollowedBy = _isFollowedBy;
    final bool isBlocked = _isBlocked;
    final String? requestStatus = _requestStatus;
    
    // Visibility logic
    final bool canSeeContent = isCurrentUser || !isPrivate || isFollowing || profile.role == 'agency';
    final bool canSeeMetadata = isCurrentUser || !isPrivate || isFollowing || isFollowedBy || profile.role == 'agency';

    if (user == null && !isLoading) return const Center(child: CircularProgressIndicator());

    // User Not Found or Blocked Case (Hard Barrier)
    if (!isCurrentUser && !isProfileLoading && (_targetProfile == null || isBlocked)) {
       return _buildBlockedProfile();
    }

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        title: Text(
           isLoading ? "       " : (profile.displayName ?? "Profile"), 
           style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: colors.textPrimary)
        ),
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (isCurrentUser) ...[
             Stack(
               children: [
                 IconButton(
                   icon: Icon(Icons.person_add_alt_outlined, color: colors.textPrimary), // Follow Requests
                   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowRequestsScreen())),
                 ),
                 if (profile.isPrivate)
                   StreamBuilder<int>(
                     stream: _followService.getPendingRequestsCountStream(),
                     builder: (context, snapshot) {
                       final count = snapshot.data ?? 0;
                       if (count == 0) return const SizedBox.shrink();
                       return Positioned(
                         right: 8,
                         top: 8,
                         child: Container(
                           padding: const EdgeInsets.all(2),
                           decoration: BoxDecoration(
                             color: Colors.redAccent,
                             shape: BoxShape.circle,
                             border: Border.all(color: colors.scaffoldBg, width: 1.5),
                           ),
                           constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                           child: Center(
                             child: Text(
                               count > 9 ? "10+" : count.toString(),
                               style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                               textAlign: TextAlign.center,
                             ),
                           ),
                         ),
                       );
                     },
                   ),
               ],
             ),
             IconButton(
               icon: Icon(Icons.settings_outlined, color: colors.textPrimary),
               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
             )
          ],
          if (!isCurrentUser && !isProfileLoading && _targetProfile != null)
             PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.textPrimary),
                onSelected: (val) async {
                   if (val == 'block') {
                      final confirmed = await showDialog<bool>(
                         context: context,
                         builder: (context) => AlertDialog(
                            title: const Text("Block User?"),
                            content: Text("Blocking will hide your posts and trips from ${_targetProfile?.displayName}. You will also be removed from each other's following lists."),
                            actions: [
                               TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                               TextButton(
                                  onPressed: () => Navigator.pop(context, true), 
                                  child: Text("Block", style: TextStyle(color: AppColors.error))
                               ),
                            ],
                         ),
                      );
                      if (confirmed == true && mounted) {
                         try {
                            await _followService.blockUser(_targetProfile!.uid);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User blocked")));
                            _loadProfileData(); // Reload to reflect blocked state or empty state
                         } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error blocking: $e")));
                         }
                      }
                   }
                },
                itemBuilder: (context) => [
                   const PopupMenuItem(
                      value: 'block',
                      child: Text("Block User", style: TextStyle(color: AppColors.error)),
                   ),
                ],
             ),
        ],
      ),
      body: (!isCurrentUser && !isProfileLoading && profile == null) 
          ? _buildProfileNotFound()
          : RefreshIndicator(
        onRefresh: () async {
          await authService.refreshProfile();
          if (!isCurrentUser && widget.userId != null) {
            await _loadProfileData();
          }
        },
        notificationPredicate: (notification) => notification.depth <= 2,
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, _) {
            return [
                SliverToBoxAdapter(
                  child: Skeletonizer(
                    enabled: isProfileLoading,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                         const SizedBox(height: 32),
                         _buildProfileHeader(context, authService, profile, isFollowedBy),
                         const SizedBox(height: 24),
                          _buildActionButtons(context, isCurrentUser, profile, isFollowing, isFollowedBy),
                          const SizedBox(height: 32),
                          _buildStatsRow(profile, canSeeMetadata, canSeeContent),
                         const SizedBox(height: 24),
                         _buildInterests(profile), 
                         const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
               SliverPersistentHeader(
                 pinned: true,
                 delegate: _SliverAppBarDelegate(
                   TabBar(
                     controller: _tabController,
                     labelColor: colors.textPrimary,
                     unselectedLabelColor: colors.textMuted,
                     indicatorColor: AppColors.brand,
                     labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                     tabs: const [
                        Tab(text: "Posts"),
                        Tab(text: "Trips"),
                     ],
                   ),
                 ),
               ),
            ];
          },
          body: Skeletonizer(
            enabled: isProfileLoading,
            child: TabBarView(
              controller: _tabController,
              children: [
                 // POSTS TAB
                 (profile.role == 'agency')
                     ? _buildPostsTab(isProfileLoading)
                     : (!isCurrentUser && !isProfileLoading && profile.isPrivate == true && !isFollowing)
                         ? _buildPrivacyLock()
                         : _buildPostsTab(isProfileLoading),

                 // TRIPS TAB
                 (profile.role == 'agency')
                     ? _ProfileTripsTab(key: ValueKey('trips_${profile.uid}'), userUid: profile.uid, tripService: _tripService, buildTripCard: _buildTripCard)
                     : (!isCurrentUser && !isProfileLoading && profile.isPrivate == true && !isFollowing)
                         ? _buildPrivacyLock()
                         : _ProfileTripsTab(key: ValueKey('trips_${profile.uid}'), userUid: profile.uid, tripService: _tripService, buildTripCard: _buildTripCard),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedProfile() {
    final isDeepLink = widget.username != null;
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDeepLink ? Icons.person_off_rounded : Icons.lock_person, size: 64, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              isDeepLink ? "User Not Found" : "Profile Not Available",
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                isDeepLink 
                  ? "The profile @${widget.username} does not exist." 
                  : "This profile is not available. This might be because you were blocked or the account was deleted.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNotFound() {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 64, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            "Profile not available",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            "This account may have been deleted or moved.",
            style: GoogleFonts.inter(color: colors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Go Back", style: GoogleFonts.inter(color: colors.scaffoldBg)),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksSection(BuildContext context, UserProfile? profile) {
    if (profile == null) return const SizedBox.shrink();
    final colors = context.appColors;
    final isDark = context.isDark;

    final List<Map<String, String>> allLinks = [];
    if (profile.instagramUrl != null && profile.instagramUrl!.isNotEmpty) {
      allLinks.add({'title': 'Instagram', 'url': profile.instagramUrl!});
    }
    if (profile.twitterUrl != null && profile.twitterUrl!.isNotEmpty) {
      allLinks.add({'title': 'Twitter/X', 'url': profile.twitterUrl!});
    }
    if (profile.youtubeUrl != null && profile.youtubeUrl!.isNotEmpty) {
      allLinks.add({'title': 'YouTube', 'url': profile.youtubeUrl!});
    }
    for (var url in profile.otherUrls) {
      if (url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        final title = uri?.host.replaceAll('www.', '') ?? url;
        allLinks.add({'title': title, 'url': url});
      }
    }

    if (allLinks.isEmpty) return const SizedBox.shrink();

    final primaryLink = allLinks.first;
    final int extraCount = allLinks.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () => _launchUrl(primaryLink['url']!),
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link, size: 14, color: AppColors.brand),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      primaryLink['url']!.replaceFirst(RegExp(r'^https?://(www\.)?'), ''),
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.brand, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (extraCount > 0)
          GestureDetector(
            onTap: () => _showAllLinksSheet(context, allLinks),
            child: Container(
              margin: const EdgeInsets.only(top: 12, left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                "+ $extraCount more",
                style: GoogleFonts.inter(fontSize: 12, color: colors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  void _showAllLinksSheet(BuildContext context, List<Map<String, String>> links) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Links", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...links.map((link) {
                  IconData iconData = Icons.link;
                  if (link['title'] == 'Instagram') iconData = Icons.camera_alt_outlined;
                  else if (link['title'] == 'Twitter/X') iconData = Icons.alternate_email;
                  else if (link['title'] == 'YouTube') iconData = Icons.play_circle_outline;
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: context.appColors.surfaceBg,
                      child: Icon(iconData, color: context.appColors.textPrimary, size: 20),
                    ),
                    title: Text(link['title']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text(link['url']!, style: GoogleFonts.inter(color: context.appColors.textSecondary, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.pop(ctx);
                      _launchUrl(link['url']!);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  // 1. IDENTITY SECTION
  Widget _buildProfileHeader(BuildContext context, AuthService auth, UserProfile? profile, bool isFollowedBy) {
    if (profile?.role == 'agency') {
       return _buildAgencyHeader(context, auth, profile, isFollowedBy);
    }
    return _buildStandardHeader(context, auth, profile, isFollowedBy);
  }

  Widget _buildAgencyHeader(BuildContext context, AuthService auth, UserProfile? profile, bool isFollowedBy) {
     final colors = context.appColors;
     final isDark = context.isDark;
     final coverUrl = profile?.coverImageUrl;
     final avatarUrl = profile?.avatarUrl;

     return Column(
       children: [
         Stack(
           clipBehavior: Clip.none,
           children: [
             // Cover Photo
             GestureDetector(
               onTap: isCurrentUser ? () async {
                 final picker = ImagePicker();
                 final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                 if (image != null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating cover photo...'), duration: Duration(seconds: 1)));
                    try {
                      await auth.updateAgencyCover(File(image.path));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                 }
               } : null,
               child: Container(
                 height: 180,
                 width: double.infinity,
                 decoration: BoxDecoration(
                   color: colors.surfaceBg,
                   image: (coverUrl != null && coverUrl.isNotEmpty)
                      ? DecorationImage(image: CachedNetworkImageProvider(coverUrl), fit: BoxFit.cover)
                      : null,
                 ),
                 child: (coverUrl == null || coverUrl.isEmpty)
                    ? Center(child: Icon(Icons.business_rounded, color: colors.textMuted, size: 48))
                    : null,
               ),
             ),
             // Avatar
             Positioned(
               bottom: -50,
               left: 20,
               child: GestureDetector(
                 onTap: isCurrentUser ? () => _showAvatarOptions(context, auth) : null,
                 child: Container(
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     border: Border.all(color: colors.cardBg, width: 4),
                     boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 10)],
                   ),
                   child: CircleAvatar(
                     radius: 50,
                     backgroundColor: colors.surfaceBg,
                     backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? CachedNetworkImageProvider(avatarUrl) : null,
                     child: (avatarUrl == null || avatarUrl.isEmpty) ? Text(profile?.displayName?[0] ?? 'A') : null,
                   ),
                 ),
               ),
             ),
           ],
         ),
         const SizedBox(height: 60),
         Padding(
           padding: const EdgeInsets.symmetric(horizontal: 24),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Text(profile?.displayName ?? "Agency", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                   const SizedBox(width: 8),
                   const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                 ],
               ),
               Text("@${profile?.username ?? ''}", style: GoogleFonts.inter(color: colors.textSecondary)),
               if (isFollowedBy && !isCurrentUser) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text("Follows You", style: GoogleFonts.inter(fontSize: 10, color: AppColors.brand, fontWeight: FontWeight.bold)),
                  ),
               ],
               if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                 const SizedBox(height: 16),
                 Text(profile.bio!, style: GoogleFonts.inter(fontSize: 15, height: 1.4)),
               ],
               if (profile?.city != null || profile?.country != null) ...[
                 const SizedBox(height: 12),
                 Row(
                   children: [
                     Icon(Icons.location_on_outlined, size: 16, color: colors.textSecondary),
                     const SizedBox(width: 4),
                     Text(
                       [profile?.city, profile?.country].where((s) => s != null && s.isNotEmpty).join(", "),
                       style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13),
                     ),
                   ],
                 ),
               ],
               _buildSocialLinksSection(context, profile),
             ],
           ),
         ),
       ],
     );
  }

  Widget _buildStandardHeader(BuildContext context, AuthService auth, UserProfile? profile, bool isFollowedBy) {
     final colors = context.appColors;
     final isDark = context.isDark;
     final avatarUrl = profile?.avatarUrl;
     return Column(
       children: [
         Stack(
            children: [
              GestureDetector(
                onTap: isCurrentUser ? () => _showAvatarOptions(context, auth) : null,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: colors.surfaceBg,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                       ? CachedNetworkImageProvider(avatarUrl) 
                       : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty) 
                       ? Text(profile?.displayName?.isNotEmpty == true ? profile!.displayName![0].toUpperCase() : "U", 
                           style: GoogleFonts.outfit(fontSize: 32, color: colors.textMuted, fontWeight: FontWeight.bold))
                       : null,
                  ),
                ),
              ),
              if (isCurrentUser)
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile?.displayName ?? "Traveler", 
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 4),
          Text(
            profile?.username != null ? "@${profile!.username}" : "@${(profile?.displayName ?? 'user').toLowerCase().replaceAll(' ', '')}",
            style: GoogleFonts.inter(color: colors.textSecondary, fontWeight: FontWeight.w500),
          ),
          if (isFollowedBy && !isCurrentUser) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isDark ? AppColors.brand.withOpacity(0.3) : Colors.blue.shade100),
              ),
              child: Text(
                "Follows You",
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.brand, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
             const SizedBox(height: 12),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 32),
               child: Text(
                 profile!.bio!,
                 textAlign: TextAlign.center,
                 style: GoogleFonts.inter(fontSize: 14, color: colors.textPrimary),
                 maxLines: 3,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
          ],
          const SizedBox(height: 8),
          if (profile?.country != null || profile?.city != null)
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                  Icon(Icons.location_on, size: 14, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    [profile?.city, profile?.country].where((s) => s != null && s.isNotEmpty).join(", "),
                    style: GoogleFonts.inter(color: colors.textSecondary, fontSize: 13),
                  ),
               ],
             ),
          _buildSocialLinksSection(context, profile),
       ],
     );
  }

    Widget _buildStatsRow(UserProfile? profile, bool canSeeMetadata, bool canSeeContent) {
     final colors = context.appColors;
     return Container(
       margin: const EdgeInsets.symmetric(horizontal: 24),
       padding: const EdgeInsets.symmetric(vertical: 16),
       decoration: BoxDecoration(
         color: colors.surfaceBg,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: colors.border),
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
         children: [
            _buildStatItem("Followers", canSeeMetadata ? "${profile?.followersCount ?? 0}" : "${profile?.followersCount ?? 0}", onTap: canSeeContent ? () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => FollowsListScreen(
                 userId: profile!.uid, 
                 displayName: profile.displayName ?? "User",
                 type: FollowListType.followers,
               )));
            } : null),
            _buildStatItem("Following", canSeeMetadata ? "${profile?.followingCount ?? 0}" : "${profile?.followingCount ?? 0}", onTap: canSeeContent ? () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => FollowsListScreen(
                 userId: profile!.uid, 
                 displayName: profile.displayName ?? "User",
                 type: FollowListType.following,
               )));
            } : null),
            _buildStatItem("Trips", canSeeMetadata ? "${profile?.tripsCount ?? 0}" : "${profile?.tripsCount ?? 0}", onTap: canSeeContent ? () {
               _tabController.animateTo(1);
            } : null), 
         ],
       ),
     );
   }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
     final colors = context.appColors;
     return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(8),
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
         child: Column(
           children: [
             Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 2),
             Text(label, style: GoogleFonts.inter(fontSize: 12, color: onTap != null ? AppColors.brand : colors.textSecondary)),
           ],
         ),
       ),
     );
  }

  // 3. ACTION BUTTONS
    Widget _buildActionButtons(BuildContext context, bool isMe, UserProfile? profile, bool isFollowing, bool isFollowedBy) {
     final colors = context.appColors;
     if (profile == null) return const SizedBox.shrink();

     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 24),
       child: Column(
         children: [
           Row(
             children: [
                if (isMe) ...[
                   Expanded(
                     child: OutlinedButton(
                       onPressed: () => _showEditProfile(context, profile),
                       style: OutlinedButton.styleFrom(
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                         side: BorderSide(color: colors.border),
                         padding: const EdgeInsets.symmetric(vertical: 12),
                       ),
                       child: Text("Edit Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: OutlinedButton(
                       onPressed: () => _handleShareProfile(profile),
                       style: OutlinedButton.styleFrom(
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                         side: BorderSide(color: colors.border),
                         padding: const EdgeInsets.symmetric(vertical: 12),
                       ),
                       child: Text("Share Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                     ),
                   ),
                 ] else ...[
                   Expanded(
                     child: ElevatedButton(
                       onPressed: (_isBlocked || (_requestStatus == null && !profile.allowFollowRequests && !isFollowing)) 
                           ? null 
                           : () => _handleFollowAction(profile),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: (!isFollowing && _requestStatus == null) ? AppColors.brand : colors.surfaceBg,
                         foregroundColor: (!isFollowing && _requestStatus == null) ? Colors.white : colors.textPrimary,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                         padding: const EdgeInsets.symmetric(vertical: 12),
                         elevation: (!isFollowing && _requestStatus == null) ? 2 : 0,
                         side: (isFollowing || _requestStatus != null) ? BorderSide(color: colors.border) : null,
                       ),
                       child: _isCheckingFollow 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey))
                          : Text(
                              isFollowing 
                                 ? "Following ✓" 
                                 : (_requestStatus == 'pending' 
                                    ? "Requested" 
                                    : (isFollowedBy ? "Follow Back" : "Follow")), 
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600)
                            ),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: OutlinedButton(
                       onPressed: () {
                          if (profile.messagePrivacy == 'nobody') {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("This user is not accepting messages.")));
                             return;
                          }
                          if (profile.messagePrivacy == 'followers' && !isFollowing) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Only followers can message this user.")));
                             return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat feature coming soon!")));
                       },
                       style: OutlinedButton.styleFrom(
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                         side: BorderSide(color: colors.border),
                         padding: const EdgeInsets.symmetric(vertical: 12),
                       ),
                       child: Text("Message", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                     ),
                   ),
                ],
             ],
           ),
           if (!isMe && isFollowedBy) ...[
              const SizedBox(height: 12),
              SizedBox(
                 width: double.infinity,
                 child: TextButton(
                    onPressed: () => _handleRemoveFollower(profile),
                    child: Text("Remove from Followers", style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
                 ),
              ),
           ]
         ],
       ),
     );
   }

  void _handleRemoveFollower(UserProfile profile) async {
     final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
           title: const Text("Remove Follower?"),
           content: Text("WanderWith won't tell ${profile.displayName} they were removed from your followers."),
           actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Remove", style: TextStyle(color: AppColors.error))),
           ],
        ),
     );

     if (confirmed == true && mounted) {
        try {
           await _followService.removeFollower(profile.uid);
           setState(() => _isFollowedBy = false);
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Follower removed.")));
        } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
     }
  }

  Widget _buildPrivateTripsPlaceholder() {
     final colors = context.appColors;
     return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                Icon(Icons.visibility_off_outlined, size: 48, color: colors.textMuted),
                const SizedBox(height: 16),
                Text("Trips are Private", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                const SizedBox(height: 8),
                Text("This user has hidden their trips.", style: GoogleFonts.inter(color: colors.textSecondary), textAlign: TextAlign.center),
             ],
          ),
        ),
     );
  }

  Future<void> _handleFollowAction(UserProfile profile) async {
     if (_isCheckingFollow) return;
     
     setState(() => _isCheckingFollow = true); // Optimistic UI update could be better, but simple for now
     
     try {
        if (!_isFollowing && _requestStatus == null) {
           await _followService.sendFollowRequest(profile.uid);
           if (profile.isPrivate) {
              if (mounted) { setState(() { _requestStatus = 'pending'; }); }
           } else {
              if (mounted) { setState(() { _isFollowing = true; _requestStatus = 'accepted'; }); }
           }
        } else {
           // Unfollow (works for both pending and following)
           await _followService.unfollow(profile.uid);
           if (mounted) { setState(() { _isFollowing = false; _requestStatus = null; }); }
        }
     } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
     } finally {
        setState(() => _isCheckingFollow = false);
     }
  }
  
  // 4. INTERESTS / SPECIALIZATIONS (unified display)
  Widget _buildInterests(UserProfile? profile) {
    final colors = context.appColors;
    final isDark = context.isDark;
    // Show interests if available, otherwise fall back to specializations
    final List<String> tags = (profile?.interests != null && profile!.interests.isNotEmpty)
        ? profile.interests
        : (profile?.specializations != null && profile!.specializations.isNotEmpty)
            ? profile.specializations
            : [];
    if (tags.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: tags.take(4).map((tag) => Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
           decoration: BoxDecoration(
             color: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: isDark ? AppColors.brand.withOpacity(0.2) : Colors.blue.shade100),
           ),
           child: Text(tag, style: GoogleFonts.inter(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w500)),
        )).toList(),
      ),
    );
  }

  // CONTENT TABS
  // Helper to check if we should show content
  bool get _canViewContent {
     // If loading, assume yes (skeletons will show)
     // If current user, yes
     if (isCurrentUser) return true;
     // If profile is public, yes
     // We invoke this on the *profile* object in build method, so let's pass it or access it
     // But wait, we need the profile object. Let's do this check inside the tabs or pass it.
     return true; 
  }

  Widget _buildPrivacyLock() {
     final colors = context.appColors;
     return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Column(
             mainAxisSize: MainAxisSize.min,
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                Container(
                   padding: const EdgeInsets.all(28),
                   decoration: BoxDecoration(
                     color: colors.surfaceBg, 
                     shape: BoxShape.circle,
                     border: Border.all(color: colors.border, width: 2),
                   ),
                   child: Icon(Icons.lock_outline_rounded, size: 56, color: colors.textMuted),
                ),
                const SizedBox(height: 24),
                Text(
                  "This account is private", 
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)
                ),
                const SizedBox(height: 12),
                Text(
                  "Follow this account to see their photos and shared trips.", 
                  style: GoogleFonts.inter(color: colors.textSecondary, height: 1.5), 
                  textAlign: TextAlign.center
                ),
                const SizedBox(height: 40),
             ],
          ),
        ),
     );
  }

  Widget _buildPostsTab(bool isLoading) {
    if (_isLoadingPosts || isLoading) {
       return const Center(child: CircularProgressIndicator());
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final isPrivateAgency = _targetProfile?.role == 'agency' && (_targetProfile?.isPrivate ?? false);
    final isFollowingAgency = _isFollowing || isCurrentUser;

    if (!isCurrentUser && isPrivateAgency && !isFollowingAgency) {
       return _buildPrivacyLock(); // Re-use the lock view INSIDE the tab for private agencies
    }

    if (_userPosts.isEmpty) {
      final colors = context.appColors;
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.grid_on, size: 48, color: colors.textMuted),
               const SizedBox(height: 16),
               Text("No posts yet", style: GoogleFonts.inter(color: colors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMorePosts();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16),
        itemCount: _userPosts.length + (_hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _userPosts.length) {
            return PostCard(
              post: _userPosts[index],
              onChanged: () {
                setState(() {
                  _userPosts.removeAt(index);
                });
              },
            );
          } else {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
        },
      ),
    );
  }

  Widget _buildTripsTab(String userUid, bool isLoading) {
     return StreamBuilder<List<Trip>>(
          stream: _tripService.getUserTrips(userUid),
          builder: (context, snapshot) {
            final isWaiting = snapshot.connectionState == ConnectionState.waiting || isLoading;
            
            if (isWaiting) {
               return SingleChildScrollView(
                 physics: const AlwaysScrollableScrollPhysics(), // Ensure refresh works even when loading
                 padding: const EdgeInsets.all(16),
                 child: Column(
                    children: List.generate(3, (index) => 
                        Skeletonizer(
                          enabled: true,
                          child: _buildTripCard(context, Trip(id: '1', name: 'Loading Trip', location: 'Location', createdBy: '', memberIds: []))
                        )
                    )
                 ),
               );
            }
                        final allTrips = snapshot.data ?? [];
            
            // Filter trips for agency privacy
            final filteredTrips = allTrips.where((t) {
              if (t.visibility == 'public') return true;
              return t.memberIds.contains(Supabase.instance.client.auth.currentUser?.id);
            }).toList();

            final hosted = filteredTrips.where((t) => t.createdBy == userUid).toList();
            final joined = filteredTrips.where((t) => t.createdBy != userUid).toList();
            
            if (filteredTrips.isEmpty) {
               return SingleChildScrollView(
                 physics: const AlwaysScrollableScrollPhysics(),
                 child: Container(
                   height: 300,
                   alignment: Alignment.center,
                   child: Text("No trips yet", style: GoogleFonts.inter(color: context.appColors.textSecondary)),
                 ),
               );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (hosted.isNotEmpty) ...[
                      Text("HOSTED BY YOU", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.appColors.textSecondary, letterSpacing: 1.1)),
                      const SizedBox(height: 12),
                      ...hosted.map((t) => _buildTripCard(context, t)),
                      const SizedBox(height: 24),
                   ],
                   
                   if (joined.isNotEmpty) ...[
                      Text("JOINED TRIPS", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.appColors.textSecondary, letterSpacing: 1.1)),
                      const SizedBox(height: 12),
                      ...joined.map((t) => _buildTripCard(context, t)),
                   ]
                ],
              ),
            );
          }
     );
  }
  
  Widget _buildTripCard(BuildContext context, Trip trip) {
    return TripCard(
      trip: trip,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: trip))),
      showStatus: true,
    );
  }

  // HELPER MOTHODS (Edit Profile, etc.)
  void _showAvatarOptions(BuildContext context, AuthService auth) {
     showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
               ListTile(
                 leading: const Icon(Icons.camera_alt),
                 title: const Text('Take a photo'),
                 onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(auth, ImageSource.camera);
                 }
               ),
               ListTile(
                 leading: const Icon(Icons.photo_library),
                 title: const Text('Choose from gallery'),
                 onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(auth, ImageSource.gallery);
                 },
               ),
            ],
          ),
        )
     );
  }

  Future<void> _pickImage(AuthService auth, ImageSource source) async {
     final picker = ImagePicker();
     final pickedFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 800);
     
     if (pickedFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Updating profile picture...'), duration: Duration(seconds: 1))
        );
        try {
           await auth.updateAvatar(File(pickedFile.path));
        } catch (e) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
     }
  }

  void _showEditProfile(BuildContext context, UserProfile? profile) {
     final bool isAgency = profile?.role == 'agency';

     // Basic info controllers
     final cName = TextEditingController(text: profile?.displayName);
     final cUsername = TextEditingController(text: profile?.username);
     final cBio = TextEditingController(text: profile?.bio);
     final cPhone = TextEditingController(text: profile?.phone);

     // Interests (traveler) / Specializations (agency)
     final cInterests = TextEditingController();
     List<String> selectedInterests = List.from(profile?.interests ?? []);
     List<String> selectedSpecializations = List.from(profile?.specializations ?? []);

     // Date of birth
     DateTime? selectedDob = profile?.dateOfBirth;

     // Social links
     final cInstagram = TextEditingController(text: profile?.instagramUrl);
     final cTwitter = TextEditingController(text: profile?.twitterUrl);
     final cYoutube = TextEditingController(text: profile?.youtubeUrl);
     final cOtherLinks = TextEditingController(text: (profile?.otherUrls != null && profile!.otherUrls!.isNotEmpty) ? profile.otherUrls!.first : null);

     // Agency-specific controllers
     final cAgencyName = TextEditingController(text: profile?.agencyName);
     final cContactPerson = TextEditingController(text: profile?.contactPerson);
     final cOfficeLocation = TextEditingController(text: profile?.officeLocation);
     final cAgencyDescription = TextEditingController(text: profile?.agencyDescription);
     final cLicenseNumber = TextEditingController(text: profile?.licenseNumber);
     final cWebsite = TextEditingController(text: profile?.website);
     final cYearEstablished = TextEditingController(text: profile?.yearEstablished?.toString() ?? '');

     bool isSaving = false;

     // Common specialization labels (matching onboarding)
     const List<String> allSpecLabels = [
       'Adventure Tours', 'Cultural Tours', 'Luxury Packages', 'Budget Travel',
       'Honeymoon', 'Group Tours', 'Corporate Travel', 'Wildlife Safari',
       'Pilgrimage', 'Cruise Packages', 'Trekking & Hiking', 'International',
     ];

     InputDecoration _inputDeco(String label, {IconData? prefixIcon, String? hint, String? prefix}) {
       return InputDecoration(
         labelText: label,
         hintText: hint,
         prefixText: prefix,
         prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
       );
     }

     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
       builder: (ctx) => Padding(
         padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
         child: StatefulBuilder(
           builder: (context, setSheetState) {
             return SingleChildScrollView(
               padding: const EdgeInsets.all(24),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    // ─── HEADER ────────────────────────────────────────
                    Row(
                      children: [
                        Text("Edit Profile", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── BASIC INFO ───────────────────────────────────
                    Text("Basic Info", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: context.appColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextField(controller: cName, decoration: _inputDeco("Display Name")),
                    const SizedBox(height: 14),
                    TextField(
                      controller: cUsername,
                      decoration: _inputDeco("Username", prefix: "@"),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: cBio, decoration: _inputDeco("Bio", hint: "Tell us about yourself..."), maxLines: 3),
                    const SizedBox(height: 14),
                    TextField(controller: cPhone, decoration: _inputDeco("Phone", prefixIcon: Icons.phone_rounded, hint: "+91 98765 43210"), keyboardType: TextInputType.phone),

                    // ─── DATE OF BIRTH (traveler only) ────────────────
                    if (!isAgency) ...[
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDob ?? DateTime(2000, 1, 1),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(primary: AppColors.brand),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDob = picked);
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: TextEditingController(
                              text: selectedDob != null
                                  ? "${selectedDob!.day.toString().padLeft(2, '0')}/${selectedDob!.month.toString().padLeft(2, '0')}/${selectedDob!.year}"
                                  : '',
                            ),
                            decoration: _inputDeco("Date of Birth", prefixIcon: Icons.cake_rounded, hint: "DD/MM/YYYY"),
                          ),
                        ),
                      ),
                    ],

                    // ─── INTERESTS (all users) ───────────────────────
                    ...[
                      const SizedBox(height: 20),
                      Text("Interests", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: context.appColors.textSecondary)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: cInterests,
                        decoration: InputDecoration(
                          labelText: "Add Interest",
                          hintText: "e.g. Photography, Food  (Press Enter)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final text = cInterests.text.trim();
                              if (text.isNotEmpty && !selectedInterests.contains(text)) {
                                setSheetState(() {
                                  selectedInterests.add(text);
                                  cInterests.clear();
                                });
                              }
                            },
                          ),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty && !selectedInterests.contains(text.trim())) {
                            setSheetState(() {
                              selectedInterests.add(text.trim());
                              cInterests.clear();
                            });
                          }
                        },
                      ),
                      if (selectedInterests.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedInterests.map((interest) {
                              return Chip(
                                label: Text(interest, style: GoogleFonts.inter(fontSize: 12)),
                                backgroundColor: context.isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                                side: BorderSide.none,
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () {
                                  setSheetState(() => selectedInterests.remove(interest));
                                },
                              );
                            }).toList(),
                          ),
                        ),
                    ],

                    // ─── AGENCY DETAILS ───────────────────────────────
                    if (isAgency) ...[
                      const SizedBox(height: 20),
                      Text("Agency Details", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: context.appColors.textSecondary)),
                      const SizedBox(height: 12),
                      TextField(controller: cAgencyName, decoration: _inputDeco("Agency Name", prefixIcon: Icons.business_rounded)),
                      const SizedBox(height: 14),
                      TextField(controller: cContactPerson, decoration: _inputDeco("Contact Person", prefixIcon: Icons.person_rounded)),
                      const SizedBox(height: 14),
                      TextField(controller: cOfficeLocation, decoration: _inputDeco("Office Location", prefixIcon: Icons.location_on_rounded)),
                      const SizedBox(height: 14),
                      TextField(controller: cAgencyDescription, decoration: _inputDeco("Agency Description", hint: "What your agency does..."), maxLines: 3),
                      const SizedBox(height: 14),
                      TextField(controller: cLicenseNumber, decoration: _inputDeco("License Number", prefixIcon: Icons.badge_rounded)),
                      const SizedBox(height: 14),
                      TextField(controller: cWebsite, decoration: _inputDeco("Website", prefixIcon: Icons.language_rounded, hint: "https://youragency.com")),
                      const SizedBox(height: 14),
                      TextField(controller: cYearEstablished, decoration: _inputDeco("Year Established", prefixIcon: Icons.calendar_today_rounded), keyboardType: TextInputType.number),
                      const SizedBox(height: 14),

                      // Specializations chips
                      Text("Specializations", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: context.appColors.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allSpecLabels.map((spec) {
                          final isSelected = selectedSpecializations.contains(spec);
                          return FilterChip(
                            label: Text(spec, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                            selected: isSelected,
                            selectedColor: context.isDark ? AppColors.brand.withOpacity(0.2) : Colors.blue.shade100,
                            backgroundColor: context.appColors.surfaceBg,
                            checkmarkColor: AppColors.brand,
                            side: BorderSide.none,
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) {
                                  selectedSpecializations.add(spec);
                                } else {
                                  selectedSpecializations.remove(spec);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    // ─── SOCIAL LINKS ─────────────────────────────────
                    const SizedBox(height: 20),
                    Text("Social Links", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: context.appColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextField(controller: cInstagram, decoration: _inputDeco("Instagram", prefixIcon: Icons.camera_alt_rounded)),
                    const SizedBox(height: 12),
                    TextField(controller: cTwitter, decoration: _inputDeco("Twitter / X", prefixIcon: Icons.alternate_email_rounded)),
                    const SizedBox(height: 12),
                    TextField(controller: cYoutube, decoration: _inputDeco("YouTube", prefixIcon: Icons.play_circle_fill_rounded)),
                    const SizedBox(height: 12),
                    TextField(controller: cOtherLinks, decoration: _inputDeco("Other Link", prefixIcon: Icons.link_rounded, hint: "https://example.com/")),

                    // ─── PHOTO BUTTONS ────────────────────────────────
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAvatarOptions(context, Provider.of<AuthService>(context, listen: false));
                      },
                      icon: const Icon(Icons.add_a_photo_rounded),
                      label: const Text("Change Profile Photo"),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        side: BorderSide(color: context.appColors.border),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isAgency) ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                             setSheetState(() => isSaving = true);
                             try {
                               await Provider.of<AuthService>(context, listen: false).updateAgencyCover(File(image.path));
                               if (ctx.mounted) Navigator.pop(ctx);
                             } catch (e) {
                               ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Error: $e")));
                             } finally {
                               setSheetState(() => isSaving = false);
                             }
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: const Text("Change Cover Photo"),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          side: BorderSide(color: AppColors.brand.withOpacity(0.5)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ─── SAVE BUTTON ──────────────────────────────────
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                           final username = cUsername.text.toLowerCase().trim();
                           if (username.isNotEmpty && username.length < 3) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                 const SnackBar(content: Text("Username must be at least 3 characters"))
                              );
                              return;
                           }

                           setSheetState(() => isSaving = true);
                           try {
                              // Auto-detect location on save
                              final authSvc = Provider.of<AuthService>(context, listen: false);
                              final loc = await authSvc.detectCurrentLocation();

                              await authSvc.updateProfile(
                                 displayName: cName.text.trim(),
                                 username: username,
                                 bio: cBio.text.trim(),
                                 phone: cPhone.text.trim().isNotEmpty ? cPhone.text.trim() : null,
                                 clearPhone: cPhone.text.trim().isEmpty && profile?.phone != null,
                                 dateOfBirth: selectedDob,
                                 interests: selectedInterests,
                                 // Location from GPS
                                 city: loc?['city'] as String?,
                                 country: loc?['country'] as String?,
                                 latitude: loc?['latitude'] as double?,
                                 longitude: loc?['longitude'] as double?,
                                 // Social links — pass value or clear flag
                                 instagramUrl: cInstagram.text.trim().isNotEmpty ? cInstagram.text.trim() : null,
                                 clearInstagram: cInstagram.text.trim().isEmpty && profile?.instagramUrl != null,
                                 twitterUrl: cTwitter.text.trim().isNotEmpty ? cTwitter.text.trim() : null,
                                 clearTwitter: cTwitter.text.trim().isEmpty && profile?.twitterUrl != null,
                                 youtubeUrl: cYoutube.text.trim().isNotEmpty ? cYoutube.text.trim() : null,
                                 clearYoutube: cYoutube.text.trim().isEmpty && profile?.youtubeUrl != null,
                                 otherUrls: cOtherLinks.text.trim().isNotEmpty ? [
                                    cOtherLinks.text.trim().startsWith('http') ? cOtherLinks.text.trim() : 'https://${cOtherLinks.text.trim()}'
                                 ] : [],
                                 // Agency fields
                                 agencyName: isAgency ? cAgencyName.text.trim() : null,
                                 contactPerson: isAgency ? cContactPerson.text.trim() : null,
                                 officeLocation: isAgency ? cOfficeLocation.text.trim() : null,
                                 agencyDescription: isAgency ? cAgencyDescription.text.trim() : null,
                                 licenseNumber: isAgency ? cLicenseNumber.text.trim() : null,
                                 website: isAgency && cWebsite.text.trim().isNotEmpty ? cWebsite.text.trim() : null,
                                 clearWebsite: isAgency && cWebsite.text.trim().isEmpty && profile?.website != null,
                                 specializations: isAgency ? selectedSpecializations : null,
                                 yearEstablished: isAgency && cYearEstablished.text.isNotEmpty ? int.tryParse(cYearEstablished.text.trim()) : null,
                              );
                              
                              if (ctx.mounted) Navigator.pop(ctx);
                           } catch (e) {
                              setSheetState(() => isSaving = false);
                              if (ctx.mounted) {
                                 ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")))
                                 );
                              }
                           }
                        },
                        style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.brand,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Changes"),
                      ),
                    ),
                    const SizedBox(height: 16),
                 ],
               ),
             );
           }
         ),
       ),
     );
  }

  void _handleShareProfile(UserProfile profile) {
     final username = profile.username ?? profile.displayName?.replaceAll(' ', '_').toLowerCase() ?? profile.uid;
     final webUrl = "https://tejuice.fun/u/$username";
     
     Share.share(webUrl);
  }
}

class _ProfileTripsTab extends StatefulWidget {
  final String userUid;
  final TripService tripService;
  final Widget Function(BuildContext, Trip) buildTripCard;
  const _ProfileTripsTab({super.key, required this.userUid, required this.tripService, required this.buildTripCard});

  @override
  State<_ProfileTripsTab> createState() => _ProfileTripsTabState();
}

class _ProfileTripsTabState extends State<_ProfileTripsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Stream<List<Trip>> _tripsStream;

  @override
  void initState() {
    super.initState();
    _tripsStream = widget.tripService.getUserTrips(widget.userUid);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Trip>>(
      stream: _tripsStream,
      builder: (context, snapshot) {
        final isWaiting = snapshot.connectionState == ConnectionState.waiting;

        if (isWaiting) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(3, (index) =>
                Skeletonizer(
                  enabled: true,
                  child: widget.buildTripCard(context, Trip(id: '1', name: 'Loading Trip', location: 'Location', createdBy: '', memberIds: []))
                )
              )
            ),
          );
        }

        final allTrips = snapshot.data ?? [];
        final filteredTrips = allTrips.where((t) {
          if (t.visibility == 'public') return true;
          return t.memberIds.contains(Supabase.instance.client.auth.currentUser?.id);
        }).toList();

        final hosted = filteredTrips.where((t) => t.createdBy == widget.userUid).toList();
        final joined = filteredTrips.where((t) => t.createdBy != widget.userUid).toList();

        if (filteredTrips.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: 300,
              alignment: Alignment.center,
              child: Text("No trips yet", style: GoogleFonts.inter(color: context.appColors.textSecondary)),
            ),
          );
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hosted.isNotEmpty) ...[
                Text("HOSTED BY YOU", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.appColors.textSecondary, letterSpacing: 1.1)),
                const SizedBox(height: 12),
                ...hosted.map((t) => widget.buildTripCard(context, t)),
                const SizedBox(height: 24),
              ],
              if (joined.isNotEmpty) ...[
                Text("JOINED TRIPS", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: context.appColors.textSecondary, letterSpacing: 1.1)),
                const SizedBox(height: 12),
                ...joined.map((t) => widget.buildTripCard(context, t)),
              ]
            ],
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: Theme.of(context).extension<AppColors>()!.scaffoldBg,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}