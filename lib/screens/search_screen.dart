import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/post_service.dart';
import '../models/post.dart';
import '../models/user_profile.dart';
import 'profile_screen.dart';
import 'post_detail_screen.dart';
import 'trip_dashboard_screen.dart';
import '../models/trip.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final PostService _postService = PostService();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription? _postRefreshSub;
  
  List<Post> _discoverPosts = [];
  List<Map<String, dynamic>> _trendingTags = [];
  List<UserProfile> _userResults = [];
  List<Post> _tagResults = [];
  List<Trip> _tripResults = [];
  List<UserProfile> _suggestedAgencies = [];
  List<Trip> _suggestedTrips = [];
  
  bool _isLoadingDiscover = true;
  bool _isLoadingSuggestions = true;
  bool _isSearching = false;
  String _searchType = 'users'; // 'users', 'tags', or 'trips'

  @override
  void initState() {
    super.initState();
    _loadDiscoverData();

    _postRefreshSub = PostService.refreshStream.listen((_) {
      if (mounted) _loadDiscoverData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _postRefreshSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDiscoverData() async {
    setState(() {
      _isLoadingDiscover = true;
      _isLoadingSuggestions = true;
    });
    try {
      final results = await Future.wait([
        _postService.getDiscoverFeed(limit: 20),
        _postService.getTrendingHashtags(),
        _postService.getSuggestedAgencies(),
        _postService.getSuggestedTrips(),
      ]);
      
      if (mounted) {
        setState(() {
          _discoverPosts = results[0] as List<Post>;
          _trendingTags = results[1] as List<Map<String, dynamic>>;
          _suggestedAgencies = results[2] as List<UserProfile>;
          _suggestedTrips = results[3] as List<Trip>;
          _isLoadingDiscover = false;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
         setState(() {
           _isLoadingDiscover = false;
           _isLoadingSuggestions = false;
         });
      }
    }
  }

  void _handleSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _userResults = [];
        _tagResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      if (_searchType == 'users') {
        final results = await _postService.searchUsers(query);
        if (mounted) setState(() => _userResults = results);
      } else if (_searchType == 'tags') {
        final results = await _postService.searchPostsByHashtag(query.replaceAll('#', ''));
        if (mounted) setState(() => _tagResults = results);
      } else {
        // Search Agency Trips
        final data = await _postService.supabase
            .from('searchable_agency_trips')
            .select()
            .ilike('name', '%$query%');
        if (mounted) setState(() => _tripResults = (data as List).map((t) => Trip.fromMap(t)).toList());
      }
    } catch (e) {
      print("Search error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: context.appColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBg,
        elevation: 0,
        title: Container(
          height: 45,
          decoration: BoxDecoration(color: context.appColors.fieldFillBg, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _searchController,
            onChanged: _handleSearch,
            decoration: InputDecoration(
              hintText: _searchType == 'users' ? "Search travelers..." : _searchType == 'tags' ? "Search #hashtags..." : "Search trip plans...",
              hintStyle: GoogleFonts.inter(color: context.appColors.textSecondary, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: context.appColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list_rounded, color: context.appColors.textPrimary),
            onSelected: (val) {
              setState(() {
                _searchType = val;
                _handleSearch(_searchController.text);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'users', child: Text("Search Users")),
              const PopupMenuItem(value: 'tags', child: Text("Search Tags")),
              const PopupMenuItem(value: 'trips', child: Text("Search Agency Trips")),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isSearching ? _buildSearchResults() : _buildDiscoverView(),
    );
  }

  Widget _buildDiscoverView() {
    return RefreshIndicator(
      onRefresh: _loadDiscoverData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Suggested Agencies
            if (_isLoadingSuggestions || _suggestedAgencies.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Suggested Agencies", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 20),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: _isLoadingSuggestions 
                  ? _buildSuggestedAgenciesSkeleton()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20),
                      itemCount: _suggestedAgencies.length,
                      itemBuilder: (context, index) {
                        final agency = _suggestedAgencies[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: agency.uid))),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: agency.avatarUrl != null ? CachedNetworkImageProvider(agency.avatarUrl!) : null,
                                  child: agency.avatarUrl == null ? const Icon(Icons.business_rounded) : null,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        agency.displayName ?? 'Agency',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (agency.role == 'agency') ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified, color: Colors.blueAccent, size: 12),
                                    ]
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],

            // Trending Trips
            if (_isLoadingSuggestions || _suggestedTrips.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text("Trending Trips", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 140,
                child: _isLoadingSuggestions
                  ? _buildSuggestedTripsSkeleton()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 20),
                      itemCount: _suggestedTrips.length,
                      itemBuilder: (context, index) {
                        final trip = _suggestedTrips[index];
                        return GestureDetector(
                          onTap: () {
                             Navigator.push(
                               context, 
                               MaterialPageRoute(builder: (_) => TripDashboardScreen(trip: trip))
                             );
                          },
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: trip.coverImageUrl != null 
                                ? DecorationImage(image: CachedNetworkImageProvider(trip.coverImageUrl!), fit: BoxFit.cover)
                                : null,
                              color: context.isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                            ),
                            child: Stack(
                              children: [
                                if (trip.coverImageUrl != null)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(trip.name, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(trip.location, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],

            // Trending Tags
            if (_trendingTags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                child: Text("Trending Tags", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20),
                  itemCount: _trendingTags.length,
                  itemBuilder: (context, index) {
                    final tag = _trendingTags[index]['tag'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ActionChip(
                        label: Text("#$tag", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brand)),
                        backgroundColor: context.isDark ? AppColors.brand.withOpacity(0.12) : Colors.blue.shade50,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          _searchController.text = tag;
                          setState(() => _searchType = 'tags');
                          _handleSearch(tag);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Text("Discover", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            _isLoadingDiscover 
              ? _buildSkeletonGrid()
              : _buildPostGrid(_discoverPosts),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedAgenciesSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 20),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        width: 60, height: 60,
        margin: const EdgeInsets.only(right: 16),
        decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildSuggestedTripsSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 20),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        width: 140, height: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchType == 'users') {
      if (_userResults.isEmpty) return _buildNoResults();
      return ListView.builder(
        itemCount: _userResults.length,
        itemBuilder: (context, index) {
          final user = _userResults[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
              child: user.avatarUrl == null ? Text(user.displayName?[0] ?? 'U') : null,
            ),
            title: Row(
              children: [
                Text(user.displayName ?? 'Traveler', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                if (user.role == 'agency') ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                ]
              ],
            ),
            subtitle: Text("@${user.username ?? ''}", style: GoogleFonts.inter(color: context.appColors.textSecondary)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.uid))),
          );
        },
      );
    } else if (_searchType == 'tags') {
      if (_tagResults.isEmpty) return _buildNoResults();
      return _buildPostGrid(_tagResults);
    } else {
      if (_tripResults.isEmpty) return _buildNoResults();
      return _buildTripList(_tripResults);
    }
  }

  Widget _buildTripList(List<Trip> trips) {
    return ListView.builder(
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return ListTile(
          leading: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: context.isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              image: trip.coverImageUrl != null ? DecorationImage(image: CachedNetworkImageProvider(trip.coverImageUrl!), fit: BoxFit.cover) : null,
            ),
            child: trip.coverImageUrl == null ? Icon(Icons.map_rounded, color: AppColors.brand) : null,
          ),
          title: Text(trip.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          subtitle: Text(trip.location, style: GoogleFonts.inter(color: context.appColors.textSecondary)),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.appColors.textMuted),
          onTap: () {
             // Navigate to Trip Dashboard in View-Only mode if not a member
             // This will be handled in TripDashboardScreen logic
          },
        );
      },
    );
  }

  Widget _buildPostGrid(List<Post> posts) {
     return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
           crossAxisCount: 2,
           mainAxisSpacing: 12,
           crossAxisSpacing: 12,
           childAspectRatio: 0.8,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
           final post = posts[index];
           return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id))),
              child: ClipRRect(
                 borderRadius: BorderRadius.circular(16),
                 child: Stack(
                    fit: StackFit.expand,
                    children: [
                       CachedNetworkImage(
                          imageUrl: post.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey.shade100),
                       ),
                       Positioned(
                          bottom: 0,
                          left: 0, right: 0,
                          child: Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                                gradient: LinearGradient(
                                   begin: Alignment.bottomCenter,
                                   end: Alignment.topCenter,
                                   colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                )
                             ),
                             child: Row(
                                children: [
                                   const Icon(Icons.favorite, size: 12, color: Colors.white),
                                   const SizedBox(width: 4),
                                   Text("${post.likeCount}", style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                             ),
                          ),
                       )
                    ],
                 ),
              ),
           );
        },
     );
  }

  Widget _buildSkeletonGrid() {
     return Skeletonizer(
        enabled: true,
        child: GridView.builder(
           shrinkWrap: true,
           physics: const NeverScrollableScrollPhysics(),
           padding: const EdgeInsets.symmetric(horizontal: 20),
           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
           ),
           itemCount: 6,
           itemBuilder: (context, index) => Container(decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16))),
        ),
     );
  }

  Widget _buildNoResults() {
     return Center(
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
              Icon(Icons.search_off_rounded, size: 48, color: context.appColors.textMuted),
              const SizedBox(height: 16),
              Text("No results found", style: GoogleFonts.outfit(fontSize: 18, color: context.appColors.textSecondary)),
           ],
        ),
     );
  }
}
