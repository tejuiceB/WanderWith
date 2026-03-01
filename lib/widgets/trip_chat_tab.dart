import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:bubble/bubble.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

class TripChatTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function() onRefresh;
  const TripChatTab({super.key, required this.trip, required this.onRefresh});

  @override
  State<TripChatTab> createState() => _TripChatTabState();
}

class _TripChatTabState extends State<TripChatTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Stream<List<Map<String, dynamic>>> _messagesStream;
  late Stream<List<Map<String, dynamic>>> _reactionsStream;
  final ImagePicker _chatImagePicker = ImagePicker();
  bool _isUploadingImage = false;
  String? _editingMessageId;
  ChatMessage? _replyingToMessage;
  
  late RealtimeChannel _chatChannel;
  final Map<String, DateTime> _typingUsers = {};
  Timer? _typingTimer;
  final Set<String> _locallyDeletedMessageIds = {};
  // Optimistic reactions: map of messageId -> set of (user_id, reaction)
  final Map<String, Set<String>> _optimisticReactions = {};
  final Map<String, UserProfile> _memberProfiles = {};

  @override
  void initState() {
    super.initState();
    _messagesStream = Supabase.instance.client
        .from('trip_messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', widget.trip.id)
        .order('created_at', ascending: false)
        .map((data) => data);

    _reactionsStream = Supabase.instance.client
        .from('message_reactions')
        .stream(primaryKey: ['id'])
        .eq('trip_id', widget.trip.id)
        .map((data) => data);

    _setupRealtime();
    _fetchMemberProfiles();
  }

  Future<void> _fetchMemberProfiles() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .inFilter('id', widget.trip.memberIds);
      
      if (data != null && mounted) {
        setState(() {
          for (var item in data) {
            final profile = UserProfile.fromMap(item);
            _memberProfiles[profile.uid] = profile;
          }
        });
      }
    } catch (e) {
      print("Error fetching member profiles: $e");
    }
  }

  void _setupRealtime() {
    _chatChannel = Supabase.instance.client.channel('trip_chat:${widget.trip.id}');
    
    _chatChannel.onBroadcast(event: 'typing', callback: (payload) {
      final uid = payload['user_id'] as String;
      final name = payload['user_name'] as String;
      final isTyping = payload['is_typing'] as bool;

      if (uid == Supabase.instance.client.auth.currentUser?.id) return;

      setState(() {
        if (isTyping) {
          _typingUsers[name] = DateTime.now();
        } else {
          _typingUsers.remove(name);
        }
      });
    }).subscribe();

    // Cleanup stale typing status
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      bool changed = false;
      _typingUsers.removeWhere((name, time) {
        if (now.difference(time).inSeconds > 5) {
          changed = true;
          return true;
        }
        return false;
      });
      if (changed) setState(() {});
    });
  }

  void _onTypingChanged(String text, String uid, String name) {
    _typingTimer?.cancel();
    _chatChannel.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': uid, 'user_name': name, 'is_typing': text.isNotEmpty},
    );

    if (text.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _chatChannel.sendBroadcastMessage(
          event: 'typing',
          payload: {'user_id': uid, 'user_name': name, 'is_typing': false},
        );
      });
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _chatChannel.unsubscribe();
    super.dispose();
  }

  final List<String> _toxicWords = ['badword1', 'badword2', 'toxic']; // Simplified blacklist

  void _sendMessage(String uid, String name) async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    // 1. Basic Moderation Check
    bool isToxic = _toxicWords.any((w) => text.toLowerCase().contains(w));
    if (isToxic) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Message blocked: Toxicity detected"), backgroundColor: Colors.red));
      // Log for moderation
      await Supabase.instance.client.from('trip_chat_moderation_logs').insert({
        'trip_id': widget.trip.id,
        'user_id': uid,
        'action': 'message_blocked',
        'reason': 'Toxicity detected',
        'raw_content': text,
      });
      return;
    }

    if (_editingMessageId != null) {
      final mid = _editingMessageId!;
      setState(() => _editingMessageId = null);
      _msgController.clear();
      try {
        await Supabase.instance.client.from('trip_messages').update({
          'content': text,
          'is_edited': true,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', mid);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
      }
      return;
    }

    final replyTo = _replyingToMessage;
    setState(() => _replyingToMessage = null);
    _msgController.clear();

    try {
      final Map<String, dynamic> metadata = {};
      if (replyTo != null) {
        metadata['reply_to'] = {
          'id': replyTo.id,
          'sender_name': replyTo.senderName,
          'content': replyTo.content.isEmpty ? '[Media]' : replyTo.content,
        };
      }

      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': name,
        'content': text,
        'type': 'text',
        'metadata': metadata,
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }

      // AI BOT TRIGGER
      if (text.toLowerCase().contains('@wanderwith')) {
        _handleAIBot(text, uid, name);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
    }
  }

  void _handleAIBot(String userText, String uid, String name) async {
    try {
      final response = await GeminiService().getChatResponse(
        userMessage: userText,
        trip: widget.trip,
        history: [], // Single turn for now
      );
      
      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': null, // Null for system/bot
        'sender_name': 'WanderWith AI',
        'content': response,
        'type': 'text',
        'metadata': {'is_bot': true},
      });
    } catch (e) {
      print("AI Bot error: $e");
    }
  }

  void _toggleReaction(String messageId, String userId, String reaction) async {
    final reactionKey = "$userId:$reaction";
    
    setState(() {
      if (!_optimisticReactions.containsKey(messageId)) {
        _optimisticReactions[messageId] = {};
      }
      if (_optimisticReactions[messageId]!.contains(reactionKey)) {
        _optimisticReactions[messageId]!.remove(reactionKey);
      } else {
        _optimisticReactions[messageId]!.add(reactionKey);
      }
    });

    try {
      final existing = await Supabase.instance.client
          .from('message_reactions')
          .select()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('reaction', reaction)
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client.from('message_reactions').delete().eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('message_reactions').upsert({
          'message_id': messageId,
          'trip_id': widget.trip.id,
          'user_id': userId,
          'reaction': reaction,
        });
      }
    } catch (e) {
      print("Reaction error: $e");
      // Rollback on error
      setState(() {
        if (_optimisticReactions[messageId]!.contains(reactionKey)) {
          _optimisticReactions[messageId]!.remove(reactionKey);
        } else {
          _optimisticReactions[messageId]!.add(reactionKey);
        }
      });
    }
  }

  void _startEditing(ChatMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _replyingToMessage = null; // Can't edit and reply at once
      _msgController.text = message.content;
    });
  }

  void _startReplying(ChatMessage message) {
    setState(() {
      _replyingToMessage = message;
      _editingMessageId = null;
    });
  }

  Future<void> _sendImage(String uid, String name, {ImageSource source = ImageSource.gallery}) async {
    if (_isUploadingImage) return;
    try {
      final XFile? image = await _chatImagePicker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      // Compress
      final filePath = image.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.png|.jpg|.jpeg'));
      final targetPath = "${filePath.substring(0, lastIndex)}_compressed.jpg";
      
      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (result == null) throw Exception("Compression failed");

      final fileExt = "jpg";
      final fileName = "chat/${widget.trip.id}/$uid/${DateTime.now().millisecondsSinceEpoch}.$fileExt";

      await Supabase.instance.client.storage
          .from('chat_media')
          .upload(fileName, File(result.path));

      final publicUrl = Supabase.instance.client.storage
          .from('chat_media')
          .getPublicUrl(fileName);

      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': name,
        'content': '',
        'type': 'image',
        'metadata': {'url': publicUrl},
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image send failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _shareLocation(String uid, String name) async {
    // In a real app, we'd use geolocator. Sharing a dummy location for now.
    // Lat/Lng for a prominent spot based on trip name or just a default.
    const double lat = 37.7749;
    const double lng = -122.4194;
    
    try {
      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': name,
        'content': 'Shared a location',
        'type': 'location',
        'metadata': {
          'lat': lat,
          'lng': lng,
          'address': 'San Francisco, CA'
        },
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location share failed: $e")));
    }
  }

  void _showAttachmentMenu(String uid, String name) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.image, "Gallery", Colors.purple, () {
                  Navigator.pop(context);
                  _sendImage(uid, name);
                }),
                _buildAttachmentOption(Icons.camera_alt, "Camera", Colors.red, () {
                  Navigator.pop(context);
                  _sendImage(uid, name, source: ImageSource.camera);
                }),
                _buildAttachmentOption(Icons.location_on, "Location", Colors.green, () {
                  Navigator.pop(context);
                  _shareLocation(uid, name);
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _togglePinned(ChatMessage message) async {
    try {
      await Supabase.instance.client
          .from('trip_messages')
          .update({'is_pinned': !message.isPinned})
          .eq('id', message.id);
    } catch (e) {
      print("Pin error: $e");
    }
  }

  void _reportMessage(ChatMessage message) async {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Message"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Reason (e.g. Inappropriate content)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              await Supabase.instance.client.from('trip_chat_moderation_logs').insert({
                'trip_id': widget.trip.id,
                'user_id': message.senderId,
                'action': 'reported',
                'reason': reason,
                'raw_content': message.content,
              });
              Navigator.pop(context);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reported successfully")));
            },
            child: const Text("Submit"),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final colors = context.appColors;
    final isDark = context.isDark;
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;
    final userProfile = auth.userProfile;

    if (user == null) return Center(child: Text("Please Log In"));

    return Column(
      children: [
        // Member indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.cardBg,
            boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 4, offset:const Offset(0, 2))]
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 4, backgroundColor: Colors.green),
              const SizedBox(width: 8),
              Text("${widget.trip.memberIds.length} members online", style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.info_outline, size: 20, color: colors.textMuted),
                onPressed: () => _showTripInfo(),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messagesStream,
            builder: (context, msgSnapshot) {
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _reactionsStream,
                builder: (context, reactSnapshot) {
                  final isLoading = msgSnapshot.connectionState == ConnectionState.waiting;
                  final msgData = msgSnapshot.data ?? [];
                  final reactData = reactSnapshot.data ?? [];

                  final messages = msgData
                      .map((m) {
                        final messageId = m['id'];
                        final reactions = reactData
                            .where((r) => r['message_id'] == messageId)
                            .map((r) => ChatReaction.fromJson(r))
                            .toList();
                        final msg = ChatMessage.fromJson(m, reactions: reactions);
                        return msg;
                      })
                      .where((m) {
                        final isDeletedLocally = _locallyDeletedMessageIds.contains(m.id);
                        final isDeletedForMe = m.deletedFor.contains(user.id);
                        return !isDeletedForMe && !isDeletedLocally;
                      })
                      .toList();

                  if (messages.isEmpty && !isLoading) return _buildEmptyState();

                  final pinnedMessages = messages.where((m) => m.isPinned).toList();

                  return Column(
                    children: [
                      if (pinnedMessages.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.orange.shade50,
                          child: Row(
                            children: [
                              const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Pinned: ${pinnedMessages.last.content.isEmpty ? '[Media]' : pinnedMessages.last.content}",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text("${pinnedMessages.length} total", style: const TextStyle(fontSize: 10, color: Colors.orange)),
                            ],
                          ),
                        ),
                      Expanded(
                        child: Skeletonizer(
                          enabled: isLoading,
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            itemCount: isLoading ? 5 : messages.length,
                            itemBuilder: (context, index) {
                              if (isLoading) return _buildSkeletonBubble();
                              final msg = messages[index];
                              final isMe = msg.senderId == user.id;
                              final isAgency = _memberProfiles[msg.senderId]?.role == 'agency';
                                return _MessageBubble(
                                  message: msg, 
                                  isMe: isMe,
                                  isAgency: isAgency,
                                  onReact: (emoji) => _toggleReaction(msg.id, user.id, emoji),
                                  onReply: () => _startReplying(msg),
                                  onEdit: () => _startEditing(msg),
                                  onPin: () => _togglePinned(msg),
                                  onReport: () => _reportMessage(msg),
                                  onDeleteForMe: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    setState(() => _locallyDeletedMessageIds.add(msg.id));
                                    try {
                                      // Get current deleted_for list or empty
                                      List<String> currentDeleted = List<String>.from(msg.deletedFor);
                                      if (!currentDeleted.contains(user.id)) {
                                        currentDeleted.add(user.id);
                                        await Supabase.instance.client
                                            .from('trip_messages')
                                            .update({'deleted_for': currentDeleted})
                                            .eq('id', msg.id);
                                      }
                                    } catch (e) {
                                      print("Delete for me error: $e");
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text("Error: $e"),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 5),
                                            action: SnackBarAction(label: "HELP", onPressed: () => _showMigrationGuide()),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  onDeleteForEveryone: () {
                                    setState(() => _locallyDeletedMessageIds.add(msg.id));
                                    Supabase.instance.client.from('trip_messages').delete().eq('id', msg.id).then((_) {}).catchError((e) {
                                      setState(() => _locallyDeletedMessageIds.remove(msg.id));
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
                                    });
                                  },
                                  currentUserId: user.id,
                                  optimisticReactions: _optimisticReactions[msg.id] ?? {},
                                  isDead: widget.trip.isDead,
                                );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }
              );
            },
          ),
        ),
        
        if (_typingUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: colors.textMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  "${_typingUsers.keys.join(', ')} ${_typingUsers.length > 1 ? 'are' : 'is'} typing...",
                  style: TextStyle(fontSize: 10, color: colors.textMuted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        if (_editingMessageId != null && !widget.trip.isDead)
          _buildActionIndicator(
            icon: Icons.edit,
            label: "Editing message...",
            onClose: () => setState(() {
              _editingMessageId = null;
              _msgController.clear();
            }),
          ),
        if (_replyingToMessage != null && !widget.trip.isDead)
          _buildActionIndicator(
            icon: Icons.reply,
            label: "Replying to ${_replyingToMessage!.senderName}...",
            onClose: () => setState(() => _replyingToMessage = null),
          ),
        if (!widget.trip.isDead)
          _buildInputBar(user.id, userProfile?.displayName ?? 'User'),
      ],
    );
  }

  void _showMigrationGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("SQL Migration Required"),
        content: const Text("It looks like the 'deleted_for' column is missing from your 'trip_messages' table. Please run the SQL script in 'sql/fix_delete_for_me.sql' using your Supabase SQL Editor to enable this feature."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      )
    );
  }

  void _showTripInfo() {
    final colors = context.appColors;
    final isDark = context.isDark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(widget.trip.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text("${widget.trip.memberIds.length} Collaborators", style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: widget.trip.memberIds.length,
                itemBuilder: (context, index) {
                  final mid = widget.trip.memberIds[index];
                  final profile = _memberProfiles[mid];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                      backgroundImage: profile?.avatarUrl != null ? CachedNetworkImageProvider(profile!.avatarUrl!) : null,
                      child: profile?.avatarUrl == null ? Icon(Icons.person, color: AppColors.brand) : null,
                    ),
                    title: Text(profile?.displayName ?? "Member ${mid.substring(0, 5)}..."),
                    subtitle: Text(profile?.role == 'agency' ? "Travel Agency" : mid == widget.trip.createdBy ? "Trip Owner" : "Member"),
                    trailing: profile?.role == 'agency'
                      ? const Icon(Icons.verified, color: Colors.blueAccent, size: 16)
                      : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIndicator({required IconData icon, required String label, required VoidCallback onClose}) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.brand))),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppColors.brand),
            onPressed: onClose,
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     final colors = context.appColors;
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.forum_outlined, size: 64, color: AppColors.brand.withOpacity(0.2)),
           const SizedBox(height: 16),
           Text("Start a conversation!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textSecondary)),
           Text("Share plans and travel ideas.", style: TextStyle(color: colors.textMuted)),
         ],
       ),
     );
  }

  Widget _buildSkeletonBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(radius: 16),
          const SizedBox(width: 8),
          Container(width: 150, height: 40, decoration: BoxDecoration(color: context.appColors.border, borderRadius: BorderRadius.circular(12))),
        ],
      ),
    );
  }

  Widget _buildInputBar(String uid, String name) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 10, offset: const Offset(0, -2))]
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: _isUploadingImage 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.add_circle_outline, color: AppColors.brand),
              onPressed: _isUploadingImage ? null : () => _showAttachmentMenu(uid, name), 
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.fieldFillBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgController,
                  maxLines: 4,
                  minLines: 1,
                  onChanged: (val) => _onTypingChanged(val, uid, name),
                  decoration: InputDecoration(
                    hintText: _editingMessageId != null ? "Edit message..." : "Type a message...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.brand,
              child: IconButton(
                icon: Icon(_editingMessageId != null ? Icons.check : Icons.send, color: Colors.white, size: 18),
                onPressed: () => _sendMessage(uid, name),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isAgency;
  final Function(String) onReact;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onPin;
  final VoidCallback onReport;
  final VoidCallback onDeleteForMe;
  final VoidCallback onDeleteForEveryone;
  final String currentUserId;
  final Set<String> optimisticReactions;
  final bool isDead;

  const _MessageBubble({
    required this.message, 
    required this.isMe, 
    required this.onReact,
    required this.onReply,
    required this.onEdit,
    required this.onPin,
    required this.onReport,
    required this.onDeleteForMe,
    required this.onDeleteForEveryone,
    required this.currentUserId,
    required this.optimisticReactions,
    this.isAgency = false,
    this.isDead = false,
  });

  void _showOptions(BuildContext context) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️','🔥','👍','😂','😮','😢'].map((emoji) => IconButton(
                  onPressed: () {
                    onReact(emoji);
                    Navigator.pop(context);
                  },
                  icon: Text(emoji, style: const TextStyle(fontSize: 24)),
                )).toList(),
              ),
              const Divider(),
              _buildOption(Icons.reply, "Reply", () {
                Navigator.pop(context);
                onReply();
              }, color: colors.textPrimary),
              _buildOption(Icons.push_pin_outlined, message.isPinned ? "Unpin" : "Pin", () {
                Navigator.pop(context);
                onPin();
              }, color: colors.textPrimary),
              _buildOption(Icons.copy, "Copy Text", () {
                if (message.type == ChatMessageType.text) {
                  Clipboard.setData(ClipboardData(text: message.content));
                }
                Navigator.pop(context);
              }, color: colors.textPrimary),
              if (isMe && message.type == ChatMessageType.text) _buildOption(Icons.edit_outlined, "Edit", () {
                Navigator.pop(context);
                onEdit();
              }, color: colors.textPrimary),
              _buildOption(Icons.delete_outline, "Delete for me", () {
                Navigator.pop(context);
                onDeleteForMe();
              }, color: colors.textSecondary),
              if (isMe) _buildOption(Icons.delete_forever_outlined, "Delete for everyone", () {
                Navigator.pop(context);
                onDeleteForEveryone();
              }, color: AppColors.error),
              _buildOption(Icons.report_gmailerrorred, "Report", () {
                Navigator.pop(context);
                onReport();
              }, color: AppColors.warning),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(label, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDark;
    final Map<String, int> reactionCounts = {};
    for (var r in message.reactions) {
      reactionCounts[r.reaction] = (reactionCounts[r.reaction] ?? 0) + 1;
    }

    // Apply optimistic changes to reactionCounts and identify if "I" reacted
    final Set<String> myReactions = {};
    for (var r in message.reactions) {
      if (r.userId == currentUserId) myReactions.add(r.reaction);
    }

    for (var opt in optimisticReactions) {
      final parts = opt.split(':');
      final uid = parts[0];
      final emoji = parts[1];
      
      bool alreadyHas = message.reactions.any((r) => r.userId == uid && r.reaction == emoji);
      
      if (alreadyHas) {
        // Optimistic removal
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 1) - 1;
        if (uid == currentUserId) myReactions.remove(emoji);
      } else {
        // Optimistic addition
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
        if (uid == currentUserId) myReactions.add(emoji);
      }
    }
    
    reactionCounts.removeWhere((key, value) => value <= 0);

    final isBot = message.metadata['is_bot'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : isBot ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (!isMe && !isBot)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message.senderName ?? 'User', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textSecondary)),
                  if (isAgency) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blueAccent, size: 10),
                  ]
                ],
              )
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : isBot ? MainAxisAlignment.center : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe && !isBot) const SizedBox(width: 4),
              GestureDetector(
                onLongPress: isBot ? null : () => _showOptions(context),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : isBot ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Bubble(
                          alignment: isMe ? Alignment.topRight : isBot ? Alignment.center : Alignment.topLeft,
                          nip: isBot ? null : isMe ? BubbleNip.rightTop : BubbleNip.leftTop,
                          color: isBot ? (isDark ? Colors.indigo.withOpacity(0.15) : Colors.indigo.shade50) : isMe ? Colors.blue.shade600 : colors.cardBg,
                          elevation: isBot ? 0 : 1,
                          margin: isBot ? const BubbleEdges.symmetric(horizontal: 20) : null,
                          borderWidth: isBot ? 1 : 0,
                          borderColor: isBot ? (isDark ? Colors.indigo.withOpacity(0.2) : Colors.indigo.shade100) : Colors.transparent,
                          padding: const BubbleEdges.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (isBot)
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, size: 12, color: Colors.indigo),
                                    SizedBox(width: 4),
                                    Text("AI GUIDE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                  ],
                                ),
                                if (isBot) const SizedBox(height: 6),
                                if (message.metadata['reply_to'] != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.black12 : colors.surfaceBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.metadata['reply_to']['sender_name'] ?? 'User',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : AppColors.brand),
                                        ),
                                        Text(
                                          message.metadata['reply_to']['content'] ?? '',
                                          style: TextStyle(fontSize: 10, color: isMe ? Colors.white60 : colors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                _buildMessageContent(context),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (message.isPinned)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(Icons.push_pin, size: 8, color: Colors.white70),
                                    ),
                                  if (message.isEdited)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Text("edited", style: TextStyle(fontSize: 8, color: Colors.white54, fontStyle: FontStyle.italic)),
                                    ),
                                  Text(
                                    DateFormat('HH:mm').format(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isMe ? Colors.white70 : colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (reactionCounts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: reactionCounts.entries.map((e) {
                            final hasMe = myReactions.contains(e.key);
                            return GestureDetector(
                              onTap: () => onReact(e.key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasMe ? (isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50) : colors.surfaceBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: hasMe ? (isDark ? AppColors.brand.withOpacity(0.3) : Colors.blue.shade200) : Colors.transparent),
                                ),
                                child: Text("${e.key} ${e.value}", style: const TextStyle(fontSize: 10)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              if (isMe) const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final colors = context.appColors;
    switch (message.type) {
      case ChatMessageType.image:
        final url = message.metadata['url'] as String?;
        if (url == null) return const Icon(Icons.broken_image);
        return GestureDetector(
          onTap: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "Image",
              barrierColor: Colors.black,
              pageBuilder: (_, __, ___) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const CloseButton(color: Colors.white)),
                body: Center(
                  child: PhotoView(
                    imageProvider: CachedNetworkImageProvider(url),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  ),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 220,
              placeholder: (context, url) => Container(width: 220, height: 150, color: colors.border, child: const Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, e) => const Icon(Icons.error),
            ),
          ),
        );
      case ChatMessageType.location:
        final lat = message.metadata['lat'] as double?;
        final lng = message.metadata['lng'] as double?;
        final address = message.metadata['address'] as String? ?? "Unknown Location";
        return GestureDetector(
          onTap: () async {
            if (lat != null && lng != null) {
              final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            }
          },
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue.shade700 : colors.surfaceBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isMe ? Colors.white24 : AppColors.brand.withOpacity(0.1),
                      child: Icon(Icons.location_on, color: isMe ? Colors.white : AppColors.brand, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brand))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(address, style: TextStyle(fontSize: 12, color: isMe ? Colors.white : colors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white10 : colors.border,
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: NetworkImage("https://via.placeholder.com/400x200.png?text=Map+Preview"), // Replace with static map if key available
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Center(child: Icon(Icons.map, color: isMe ? Colors.white : AppColors.brand)),
                ),
              ],
            ),
          ),
        );
      case ChatMessageType.text:
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : colors.textPrimary,
            fontSize: 15,
          ),
        );
    }
  }
}
