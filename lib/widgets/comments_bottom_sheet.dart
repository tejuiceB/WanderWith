import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/user_profile.dart';
import '../services/post_service.dart';
import '../screens/profile_screen.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final VoidCallback? onCommentAdded;

  const CommentsBottomSheet({super.key, required this.postId, this.onCommentAdded});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  Map<String, List<Map<String, dynamic>>> _replies = {};
  bool _isLoading = true;
  bool _isSending = false;
  String? _postOwnerId;
  String? _currentUserId;

  // Editing state
  Map<String, dynamic>? _editingComment;

  // Replying & Mentions
  Map<String, dynamic>? _replyingTo;
  List<dynamic> _mentionSuggestions = [];
  bool _showMentions = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _commentController.addListener(_onCommentChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _onCommentChanged() async {
    final text = _commentController.text;
    final selection = _commentController.selection;
    if (selection.baseOffset <= 0) {
      if (_showMentions) setState(() => _showMentions = false);
      return;
    }
    final lastAtPos = text.lastIndexOf('@', selection.baseOffset - 1);
    if (lastAtPos != -1) {
      final query = text.substring(lastAtPos + 1, selection.baseOffset);
      if (!query.contains(' ')) {
        setState(() => _showMentions = true);
        final results = await _postService.searchUsers(query);
        if (mounted && _showMentions) setState(() => _mentionSuggestions = results);
        return;
      }
    }
    if (_showMentions) setState(() => _showMentions = false);
  }

  void _selectUser(UserProfile user) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    final lastAtPos = text.lastIndexOf('@', selection.baseOffset - 1);
    if (lastAtPos != -1) {
      final newText = text.replaceRange(lastAtPos, selection.baseOffset, "@${user.username} ");
      _commentController.text = newText;
      _commentController.selection = TextSelection.fromPosition(TextPosition(offset: lastAtPos + (user.username?.length ?? 0) + 2));
    }
    setState(() => _showMentions = false);
  }

  Future<void> _loadComments({bool append = false}) async {
    if (!append) setState(() => _isLoading = true);
    
    // Fetch Post Owner and Current User for permission checks
    if (_postOwnerId == null) {
      final post = await _postService.getPost(widget.postId);
      _postOwnerId = post?.userId;
      _currentUserId = _postService.supabase.auth.currentUser?.id;
    }

    DateTime? beforeTimestamp;
    if (append && _comments.isNotEmpty) {
       beforeTimestamp = DateTime.parse(_comments.last['created_at']);
    }

    final newComments = await _postService.getComments(widget.postId, beforeTimestamp: beforeTimestamp);
    
    if (mounted) {
      final Map<String, List<Map<String, dynamic>>> repliesMap = append ? Map.from(_replies) : {};
      final List<Map<String, dynamic>> rootComments = append ? List.from(_comments) : [];

      for (var comment in newComments) {
        if (comment['parent_comment_id'] == null) {
          rootComments.add(comment);
        } else {
          final parentId = comment['parent_comment_id'];
          repliesMap.putIfAbsent(parentId, () => []).add(comment);
        }
      }

      setState(() {
        _comments = rootComments;
        _replies = repliesMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCommentDelete(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Comment?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _postService.deleteComment(commentId);
        await _loadComments();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      }
    }
  }

  void _startEditing(Map<String, dynamic> comment) {
    setState(() {
      _editingComment = comment;
      _replyingTo = null;
      _commentController.text = comment['content'] ?? '';
    });
  }

  Future<void> _handleCommentSubmit() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      if (_editingComment != null) {
        await _postService.updateComment(_editingComment!['id'], content);
        setState(() => _editingComment = null);
      } else {
        await _postService.addComment(
          widget.postId, 
          content, 
          parentCommentId: _replyingTo?['id'],
        );
      }
      _commentController.clear();
      setState(() => _replyingTo = null);
      if (widget.onCommentAdded != null) widget.onCommentAdded!();
      await _loadComments();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, {bool isReply = false}) {
    final profile = comment['profiles'];
    final String displayName = (profile != null) ? (profile['display_name'] ?? 'User') : 'Traveler';
    final String? avatarUrl = (profile != null) ? profile['avatar_url'] : null;
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';
    final String content = comment['content'] ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: 20, left: isReply ? 40 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: comment['user_id']))),
                child: CircleAvatar(
                  radius: isReply ? 12 : 16,
                  backgroundImage: (avatarUrl != null) ? CachedNetworkImageProvider(avatarUrl) : null,
                  child: (avatarUrl == null) ? Text(initials, style: TextStyle(fontSize: isReply ? 10 : 12)) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: comment['user_id']))),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(displayName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              if (profile?['role'] == 'agency') ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: Colors.blueAccent, size: 12),
                              ],
                            ]
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(DateTime.parse(comment['created_at']), locale: 'en_short'),
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400]),
                        ),
                        if (comment['updated_at'] != null && 
                            DateTime.parse(comment['updated_at']).difference(DateTime.parse(comment['created_at'])).inSeconds > 5)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              "(edited)", 
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400], fontStyle: FontStyle.italic)
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(content, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!isReply)
                          GestureDetector(
                            onTap: () => setState(() {
                              _replyingTo = comment;
                              _editingComment = null;
                            }),
                            child: Text("Reply", style: GoogleFonts.inter(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          ),
                        if (!isReply) const SizedBox(width: 16),
                        
                        // Moderation Actions
                        if (comment['user_id'] == _currentUserId)
                          GestureDetector(
                            onTap: () => _startEditing(comment),
                            child: Text("Edit", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                          ),
                        if (comment['user_id'] == _currentUserId) const SizedBox(width: 16),
                        
                        if (comment['user_id'] == _currentUserId || _postOwnerId == _currentUserId)
                          GestureDetector(
                            onTap: () => _handleCommentDelete(comment['id']),
                            child: Text("Delete", style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent.withOpacity(0.8), fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Render replies (Limited to 2 initially if desired, or just all for now but with View More logic)
          if (!isReply && _replies.containsKey(comment['id']))
            ..._replies[comment['id']]!.map((r) => _buildCommentItem(r, isReply: true)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Comments",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty 
                      ? Center(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 200,
                              child: Center(
                                child: Text(
                                  "No comments yet. Be the first!", 
                                  style: GoogleFonts.inter(color: Colors.grey)
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) => _buildCommentItem(_comments[index]),
                        ),
              ),
              if (_showMentions && _mentionSuggestions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  color: Colors.grey.shade50,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _mentionSuggestions.length,
                    itemBuilder: (context, index) {
                      final user = _mentionSuggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text("@${user.username}", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                        onTap: () => _selectUser(user),
                      );
                    },
                  ),
                ),
              const Divider(height: 1),
              if (_replyingTo != null || _editingComment != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      Text(
                        _editingComment != null ? "Editing comment" : "Replying to @${(_replyingTo!['profiles'] != null ? _replyingTo!['profiles']['username'] : null) ?? 'user'}", 
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.blueAccent)
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() {
                          _replyingTo = null;
                          _editingComment = null;
                          if (_editingComment != null) _commentController.clear(); // Clear if canceling edit
                        }), 
                        child: const Icon(Icons.close, size: 16, color: Colors.blueAccent)
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        autofocus: _replyingTo != null || _editingComment != null,
                        decoration: InputDecoration(
                          hintText: _editingComment != null 
                            ? "Edit your comment..." 
                            : (_replyingTo == null ? "Add a comment..." : "Add a reply..."),
                          hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _isSending 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(onPressed: _handleCommentSubmit, icon: const Icon(Icons.send_rounded, color: Colors.blueAccent)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
