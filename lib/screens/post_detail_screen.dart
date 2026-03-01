import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import '../theme/theme_extensions.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  Post? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final post = await _postService.getPost(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
          if (post == null) _error = "Post not found or unavailable.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "An error occurred while loading the post.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBg,
        elevation: 0,
        title: Text("Post", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.appColors.textPrimary)),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: context.appColors.textMuted),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: context.appColors.textSecondary)),
                        const SizedBox(height: 24),
                        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back")),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: PostCard(
                    post: _post!,
                    onChanged: () {
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ),
    );
  }
}
