import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';
import 'comments_bottom_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
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
      builder: (context) => CommentsBottomSheet(postId: widget.post.id),
    );
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
            padding: const EdgeInsets.all(16),
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
                  label: "${widget.post.commentCount}",
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
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildCaption(widget.post.caption!),
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
