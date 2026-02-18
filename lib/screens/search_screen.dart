import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/post_service.dart';
import '../models/post.dart';
import '../models/user_profile.dart';
import 'profile_screen.dart';
import 'post_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final PostService _postService = PostService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Post> _discoverPosts = [];
  List<Map<String, dynamic>> _trendingTags = [];
  List<UserProfile> _userResults = [];
  List<Post> _tagResults = [];
  
  bool _isLoadingDiscover = true;
  bool _isSearching = false;
  String _searchType = 'users'; // 'users' or 'tags'

  @override
  void initState() {
    super.initState();
    _loadDiscoverData();
  }

  Future<void> _loadDiscoverData() async {
    setState(() => _isLoadingDiscover = true);
    try {
      final results = await Future.wait([
        _postService.getDiscoverFeed(limit: 20),
        _postService.getTrendingHashtags(),
      ]);
      
      if (mounted) {
        setState(() {
          _discoverPosts = results[0] as List<Post>;
          _trendingTags = results[1] as List<Map<String, dynamic>>;
          _isLoadingDiscover = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDiscover = false);
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
      } else {
        final results = await _postService.searchPostsByHashtag(query.replaceAll('#', ''));
        if (mounted) setState(() => _tagResults = results);
      }
    } catch (e) {
      print("Search error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 45,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _searchController,
            onChanged: _handleSearch,
            decoration: InputDecoration(
              hintText: _searchType == 'users' ? "Search travelers..." : "Search #hashtags...",
              hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.black87),
            onSelected: (val) {
              setState(() {
                _searchType = val;
                _handleSearch(_searchController.text);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'users', child: Text("Search Users")),
              const PopupMenuItem(value: 'tags', child: Text("Search Tags")),
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
            // Trending Tags
            if (_trendingTags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                        label: Text("#$tag", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                        backgroundColor: Colors.blue.shade50,
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
            title: Text(user.displayName ?? 'Traveler', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            subtitle: Text("@${user.username ?? ''}", style: GoogleFonts.inter(color: Colors.grey)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.uid))),
          );
        },
      );
    } else {
      if (_tagResults.isEmpty) return _buildNoResults();
      return _buildPostGrid(_tagResults);
    }
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
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text("No results found", style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)),
           ],
        ),
     );
  }
}
