import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user
  final String? username; // New: support deep linking by username
  const ProfileScreen({super.key, this.userId, this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();
  final FollowService _followService = FollowService();
  final PostService _postService = PostService();
  late TabController _tabController;
  
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
  
  bool get isCurrentUser => widget.userId == null || widget.userId == Supabase.instance.client.auth.currentUser?.id;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final bool canSeeContent = isCurrentUser || !isPrivate || isFollowing;
    final bool canSeeMetadata = isCurrentUser || !isPrivate || isFollowing || isFollowedBy;

    if (user == null && !isLoading) return const Center(child: CircularProgressIndicator());

    // User Not Found or Blocked Case (Hard Barrier)
    if (!isCurrentUser && !isProfileLoading && (_targetProfile == null || isBlocked)) {
       return _buildBlockedProfile();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
           isLoading ? "       " : (profile.displayName ?? "Profile"), 
           style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (isCurrentUser) ...[
             Stack(
               children: [
                 IconButton(
                   icon: const Icon(Icons.person_add_alt_outlined, color: Colors.black87), // Follow Requests
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
                             border: Border.all(color: Colors.white, width: 1.5),
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
               icon: const Icon(Icons.settings_outlined, color: Colors.black87),
               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
             )
          ],
          if (!isCurrentUser && !isProfileLoading && _targetProfile != null)
             PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
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
                                  child: const Text("Block", style: TextStyle(color: Colors.red))
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
                      child: Text("Block User", style: TextStyle(color: Colors.red)),
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
                         _buildHeader(context, authService, profile, isFollowedBy),
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
                     labelColor: Colors.black87,
                     unselectedLabelColor: Colors.grey,
                     indicatorColor: Colors.black87,
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
                 (!isCurrentUser && !isProfileLoading && profile.isPrivate == true && !isFollowing)
                     ? _buildPrivacyLock()
                     : _buildPostsTab(isProfileLoading),

                 // TRIPS TAB
                 (!isCurrentUser && !isProfileLoading && profile.isPrivate == true && !isFollowing)
                     ? _buildPrivacyLock()
                     : (isPrivate && !isCurrentUser && !isFollowing)
                        ? _buildPrivacyLock()
                        : _buildTripsTab(profile.uid, isProfileLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedProfile() {
    final isDeepLink = widget.username != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDeepLink ? Icons.person_off_rounded : Icons.lock_person, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isDeepLink ? "User Not Found" : "Profile Not Available",
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                isDeepLink 
                  ? "The profile @${widget.username} does not exist." 
                  : "This profile is not available. This might be because you were blocked or the account was deleted.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Profile not available",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            "This account may have been deleted or moved.",
            style: GoogleFonts.inter(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Go Back", style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 1. IDENTITY SECTION
  Widget _buildHeader(BuildContext context, AuthService auth, UserProfile? profile, bool isFollowedBy) {
     final avatarUrl = profile?.avatarUrl;
     final isAgency = profile?.role == 'agency';

     return Column(
       children: [
         Stack(
            children: [
              GestureDetector(
                onTap: isCurrentUser ? () => _showAvatarOptions(context, auth) : null,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                       ? CachedNetworkImageProvider(avatarUrl) 
                       : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty) 
                       ? Text(profile?.displayName?.isNotEmpty == true ? profile!.displayName![0].toUpperCase() : "U", 
                           style: GoogleFonts.outfit(fontSize: 32, color: Colors.grey.shade400, fontWeight: FontWeight.bold))
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
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text(
                 profile?.displayName ?? "Traveler", 
                 style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)
               ),
               if (isAgency) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
               ]
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profile?.username != null ? "@${profile!.username}" : "@${(profile?.displayName ?? 'user').toLowerCase().replaceAll(' ', '')}",
            style: GoogleFonts.inter(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          if (isFollowedBy && !isCurrentUser) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                "Follows You",
                style: GoogleFonts.inter(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
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
                 style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
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
                 Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                 const SizedBox(width: 4),
                 Text(
                   [profile?.city, profile?.country].where((s) => s != null && s.isNotEmpty).join(", "),
                   style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                 ),
              ],
            ),
       ],
     );
  }

    Widget _buildStatsRow(UserProfile? profile, bool canSeeMetadata, bool canSeeContent) {
     
     return Container(
       margin: const EdgeInsets.symmetric(horizontal: 24),
       padding: const EdgeInsets.symmetric(vertical: 16),
       decoration: BoxDecoration(
         color: Colors.grey.shade50,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: Colors.grey.shade100),
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
     return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(8),
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
         child: Column(
           children: [
             Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 2),
             Text(label, style: GoogleFonts.inter(fontSize: 12, color: onTap != null ? Colors.blueAccent : Colors.grey.shade600)),
           ],
         ),
       ),
     );
  }

  // 3. ACTION BUTTONS
    Widget _buildActionButtons(BuildContext context, bool isMe, UserProfile? profile, bool isFollowing, bool isFollowedBy) {
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
                         side: BorderSide(color: Colors.grey.shade300),
                         padding: const EdgeInsets.symmetric(vertical: 12),
                       ),
                       child: Text("Edit Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87)),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: OutlinedButton(
                       onPressed: () => _handleShareProfile(profile),
                       style: OutlinedButton.styleFrom(
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                         side: BorderSide(color: Colors.grey.shade300),
                         padding: const EdgeInsets.symmetric(vertical: 12),
                       ),
                       child: Text("Share Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87)),
                     ),
                   ),
                 ] else ...[
                   Expanded(
                     child: ElevatedButton(
                       onPressed: (_isBlocked || (_requestStatus == null && !profile.allowFollowRequests && !isFollowing)) 
                           ? null 
                           : () => _handleFollowAction(profile),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: (!isFollowing && _requestStatus == null) ? Colors.blueAccent : Colors.grey.shade100,
                         foregroundColor: (!isFollowing && _requestStatus == null) ? Colors.white : Colors.black87,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                         padding: const EdgeInsets.symmetric(vertical: 12),
                         elevation: (!isFollowing && _requestStatus == null) ? 2 : 0,
                         side: (isFollowing || _requestStatus != null) ? BorderSide(color: Colors.grey.shade300) : null,
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
                         side: BorderSide(color: Colors.grey.shade300),
                         padding: const EdgeInsets.symmetric(vertical: 12),
                       ),
                       child: Text("Message", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87)),
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
                    child: Text("Remove from Followers", style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
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
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Remove", style: TextStyle(color: Colors.redAccent))),
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
     return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                Icon(Icons.visibility_off_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text("Trips are Private", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Text("This user has hidden their trips.", style: GoogleFonts.inter(color: Colors.grey), textAlign: TextAlign.center),
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
  
  // 4. INTERESTS
  Widget _buildInterests(UserProfile? profile) {
    if (profile?.interests == null || profile!.interests.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: profile.interests.take(4).map((tag) => Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
           decoration: BoxDecoration(
             color: Colors.blue.shade50,
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: Colors.blue.shade100),
           ),
           child: Text(tag, style: GoogleFonts.inter(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w500)),
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
     return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // Since it's usually short, but allow fitting
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Column(
             mainAxisSize: MainAxisSize.min,
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                Container(
                   padding: const EdgeInsets.all(28),
                   decoration: BoxDecoration(
                     color: Colors.grey.shade50, 
                     shape: BoxShape.circle,
                     border: Border.all(color: Colors.grey.shade100, width: 2),
                   ),
                   child: Icon(Icons.lock_outline_rounded, size: 56, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 24),
                Text(
                  "This account is private", 
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
                ),
                const SizedBox(height: 12),
                Text(
                  "Follow this account to see their photos and shared trips.", 
                  style: GoogleFonts.inter(color: Colors.grey.shade600, height: 1.5), 
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

    if (_userPosts.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.grid_on, size: 48, color: Colors.grey.shade300),
               const SizedBox(height: 16),
               Text("No posts yet", style: GoogleFonts.inter(color: Colors.grey.shade500)),
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
            return PostCard(post: _userPosts[index]);
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
            final hosted = allTrips.where((t) => t.createdBy == userUid).toList();
            final joined = allTrips.where((t) => t.createdBy != userUid).toList();
            
            if (allTrips.isEmpty) {
               return SingleChildScrollView(
                 physics: const AlwaysScrollableScrollPhysics(),
                 child: Container(
                   height: 300,
                   alignment: Alignment.center,
                   child: Text("No trips yet", style: GoogleFonts.inter(color: Colors.grey)),
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
                      Text("HOSTED BY YOU", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade500, letterSpacing: 1.1)),
                      const SizedBox(height: 12),
                      ...hosted.map((t) => _buildTripCard(context, t)),
                      const SizedBox(height: 24),
                   ],
                   
                   if (joined.isNotEmpty) ...[
                      Text("JOINED TRIPS", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade500, letterSpacing: 1.1)),
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
     final cName = TextEditingController(text: profile?.displayName);
     final cUsername = TextEditingController(text: profile?.username);
     final cBio = TextEditingController(text: profile?.bio);
     final cCity = TextEditingController(text: profile?.city);
      
     bool isSaving = false;

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
                    Text("Edit Profile", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(controller: cName, decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    TextField(
                      controller: cUsername, 
                      decoration: InputDecoration(
                        labelText: "Username", 
                        prefixText: "@",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      )
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: cBio, decoration: InputDecoration(labelText: "Bio", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 3),
                    const SizedBox(height: 16),
                    TextField(controller: cCity, decoration: InputDecoration(labelText: "City", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                           setSheetState(() => isSaving = true);
                           try {
                              await Provider.of<AuthService>(context, listen: false).updateProfile(
                                 displayName: cName.text,
                                 username: cUsername.text.toLowerCase().trim(),
                                 bio: cBio.text,
                                 city: cCity.text,
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
                           backgroundColor: Colors.blueAccent,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Changes"),
                      ),
                    )
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
     final appUrl = "wanderwith://u/$username";
     
     Share.share(
       "Check out ${profile.displayName}'s profile on WanderWith! 🌍✨\n\nLink: $webUrl\nApp Link: $appUrl",
       subject: "WanderWith Profile",
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
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
