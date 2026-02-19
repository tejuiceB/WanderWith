import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';
import 'comments_bottom_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onChanged;

  const PostCard({super.key, required this.post, this.onChanged});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  late String? _caption;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
    _caption = widget.post.caption;
  }

  void _handleLikeToggle() async {
    final bool originalLiked = _isLiked;
    final int originalCount = _likeCount;

    // Optimistic UI update
    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _likeCount++ : _likeCount--;
    });

    try {
      final success = await _postService.toggleLike(widget.post.id);
      
      if (mounted && success != _isLiked) {
         setState(() {
           _isLiked = success;
           _likeCount = success ? originalCount + 1 : originalCount - 1;
         });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = originalLiked;
          _likeCount = originalCount;
        });
      }
    }
  }

  void _handleShare() {
    final String authorName = widget.post.author?.displayName ?? 'a traveler';
    final String webUrl = "https://tejuice.fun/p/${widget.post.id}";
    final String appUrl = "wanderwith://p/${widget.post.id}";
    
    Share.share(
      "Check out this travel post by $authorName on WanderWith! 🌍✨\n\nLink: $webUrl\nApp Link: $appUrl",
      subject: "WanderWith Post",
    );
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        postId: widget.post.id,
        onCommentAdded: () {
          if (mounted) {
            setState(() {
              _commentCount++;
            });
          }
        },
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text("Edit Caption", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showEditCaptionDialog();
              },
            ),
            ListTile(
              leading: Icon(widget.post.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
              title: Text(widget.post.isArchived ? "Unarchive Post" : "Archive Post", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _handleArchiveToggle();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text("Delete Post", style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              subtitle: Text("This action cannot be undone.", style: GoogleFonts.inter(fontSize: 12)),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                _confirmDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditCaptionDialog() {
    final controller = TextEditingController(text: widget.post.caption);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Caption", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "What's on your mind?",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newCaption = controller.text.trim();
              Navigator.pop(context);
              _handleUpdateCaption(newCaption);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdateCaption(String newCaption) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await _postService.updatePostCaption(widget.post.id, newCaption);
      if (mounted) {
        Navigator.pop(context); // Close loading
        setState(() {
          _caption = newCaption;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Caption updated! ✨")));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _handleArchiveToggle() async {
    final bool willArchive = !widget.post.isArchived;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await _postService.setPostArchived(widget.post.id, willArchive);
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(willArchive ? "Post archived 📦" : "Post unarchived! 🌍")),
        );
        PostService.notifyRefresh();
        if (widget.onChanged != null) widget.onChanged!();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Post?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to permanently delete this post?", style: GoogleFonts.inter()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _handleDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );

    try {
      await _postService.deletePost(widget.post);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post deleted 🗑️"), behavior: SnackBarBehavior.floating),
        );
        PostService.notifyRefresh();
        if (widget.onChanged != null) widget.onChanged!();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting post: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildCaption(String caption) {
    final List<TextSpan> spans = [];
    final words = caption.split(' ');

    for (var word in words) {
      if (word.startsWith('#') && word.length > 1) {
        spans.add(TextSpan(
          text: '$word ',
          style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.w600),
          recognizer: TapGestureRecognizer()..onTap = () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Hashtag $word search coming soon!"), behavior: SnackBarBehavior.floating),
            );
          },
        ));
      } else if (word.startsWith('@') && word.length > 1) {
        final username = word.substring(1).replaceAll(RegExp(r'[^\w]'), '');
        spans.add(TextSpan(
          text: '$word ',
          style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          recognizer: TapGestureRecognizer()..onTap = () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(username: username)));
          },
        ));
      } else {
        spans.add(TextSpan(text: '$word ', style: GoogleFonts.inter(color: Colors.black87)));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authorName = widget.post.author?.displayName ?? 'Traveler';
    final authorAvatar = widget.post.author?.avatarUrl;
    final initials = (authorName.isNotEmpty) ? authorName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.post.userId))),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: (authorAvatar != null && authorAvatar.isNotEmpty) ? CachedNetworkImageProvider(authorAvatar) : null,
                    child: (authorAvatar == null || authorAvatar.isEmpty) ? Text(initials, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (widget.post.location != null && widget.post.location!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 10, color: Colors.blueAccent),
                            const SizedBox(width: 2),
                            Text(widget.post.location!, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                    ],
                  ),
                ),
                Text(
                  timeago.format(widget.post.createdAt, locale: 'en_short'),
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400]),
                ),
                if (widget.post.userId == Supabase.instance.client.auth.currentUser?.id)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.black54),
                    onPressed: () => _showPostOptions(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // 2. Image with immersive styling
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrl,
                  width: double.infinity,
                  height: 350,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade100),
                  errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.2)],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 3. Interactions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _InteractionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.redAccent : Colors.black87,
                  label: "$_likeCount",
                  onTap: _handleLikeToggle,
                ),
                const SizedBox(width: 20),
                _InteractionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: "$_commentCount",
                  onTap: _showComments,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 22, color: Colors.black87),
                  onPressed: _handleShare,
                ),
              ],
            ),
          ),

          // 4. Caption
          if (_caption != null && _caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildCaption(_caption!),
            ),
        ],
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _InteractionButton({required this.icon, required this.label, required this.onTap, this.color = Colors.black87});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
