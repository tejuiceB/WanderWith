import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';

class ArchivedPostsScreen extends StatefulWidget {
  const ArchivedPostsScreen({super.key});

  @override
  State<ArchivedPostsScreen> createState() => _ArchivedPostsScreenState();
}

class _ArchivedPostsScreenState extends State<ArchivedPostsScreen> {
  final PostService _postService = PostService();
  final List<Post> _archivedPosts = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchArchivedPosts();
  }

  Future<void> _fetchArchivedPosts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final posts = await _postService.getArchivedPosts();
      if (mounted) {
        setState(() {
          _archivedPosts.clear();
          _archivedPosts.addAll(posts);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
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
          "Archived Posts", 
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text("Failed to load archived posts", style: GoogleFonts.inter(color: Colors.grey)),
                      TextButton(onPressed: _fetchArchivedPosts, child: const Text("Retry")),
                    ],
                  ),
                )
              : _archivedPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.archive_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text("No archived posts", style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text("Posts you archive will appear here", style: GoogleFonts.inter(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchArchivedPosts,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _archivedPosts.length,
                        itemBuilder: (context, index) {
                          return PostCard(
                            post: _archivedPosts[index],
                            onChanged: () {
                              setState(() {
                                _archivedPosts.removeAt(index);
                              });
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
