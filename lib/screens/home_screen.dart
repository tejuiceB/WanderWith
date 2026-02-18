import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/auth_service.dart';
import '../services/feed_service.dart';
import '../models/post.dart';
import '../widgets/post_card.dart'; // Import PostCard
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'create_trip_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FeedService _feedService = FeedService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  List<Post> _posts = [];

  @override
  void initState() {
     super.initState();
     _loadInitialFeed();
     _scrollController.addListener(_onScroll);
     _requestPermissions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadInitialFeed() async {
    setState(() {
      _isLoading = true;
      _posts = [];
      _hasMore = true;
    });
    try {
      final posts = await _feedService.getHomeFeed(limit: 10);
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
          if (posts.length < 10) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error loading feed: $e");
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    try {
      final lastPost = _posts.last;
      final morePosts = await _feedService.getHomeFeed(
        limit: 10, 
        beforeTimestamp: lastPost.createdAt
      );

      if (mounted) {
        setState(() {
          _posts.addAll(morePosts);
          _isLoadingMore = false;
          if (morePosts.length < 10) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
      print("Error loading more posts: $e");
    }
  }

  void _requestPermissions() async {
     await Future.delayed(const Duration(seconds: 2));
     final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
     final android = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
     if (android != null) {
        await android.requestNotificationsPermission();
     }
  }

  Future<void> _refresh() async {
    await _loadInitialFeed();
  }

  @override
  Widget build(BuildContext context) {
    // We don't really use authService directly here anymore if using FeedService
    // but we might need it for profile or connectivity checks later.
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 24, 
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'android/assets/logo.png',
                height: 40,
                width: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "WanderWith", 
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, 
                fontSize: 24,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCountStream(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                   IconButton(
                     icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                     onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                     },
                   ),
                   if (count > 0)
                     Positioned(
                       right: 8,
                       top: 8,
                       child: Container(
                         padding: const EdgeInsets.all(4),
                         decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                         constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                       ),
                     )
                ],
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<ConnectivityResult>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == ConnectivityResult.none) {
                return Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        "Offline mode",
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: Colors.blueAccent,
              child: _isLoading && _posts.isEmpty
                  ? _buildSkeletonFeed()
                  : _posts.isEmpty 
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _posts.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                             if (index < _posts.length) {
                                return PostCard(post: _posts[index]);
                             } else {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blue.shade300,
                                    ),
                                  ),
                                );
                             }
                          },
                        ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
     return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
           SizedBox(height: MediaQuery.of(context).size.height * 0.2),
           Center(
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.flight_takeoff, size: 64, color: Colors.blue.shade300),
                   ),
                   const SizedBox(height: 24),
                   Text("No posts yet 🚀", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Text("Follow travelers or join trips to see updates here.", textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16)),
                   const SizedBox(height: 32),
                   ElevatedButton.icon(
                      onPressed: _refresh, 
                      icon: const Icon(Icons.refresh),
                      label: const Text("Refresh Feed"),
                      style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.black87,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      )
                   )
                ],
             ),
           )
        ],
     );
  }

  Widget _buildSkeletonFeed() {
     return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
           return Skeletonizer(
              enabled: true,
              child: Container(
                 margin: const EdgeInsets.only(bottom: 24),
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                          children: [
                             const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                             const SizedBox(width: 12),
                             Container(width: 120, height: 16, color: Colors.grey),
                          ],
                       ),
                       const SizedBox(height: 12),
                       Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                       ),
                       const SizedBox(height: 12),
                       Container(width: 200, height: 16, color: Colors.grey),
                       const SizedBox(height: 8),
                       Container(width: 150, height: 16, color: Colors.grey),
                    ],
                 ),
              ),
           );
        }
     );
  }
}
