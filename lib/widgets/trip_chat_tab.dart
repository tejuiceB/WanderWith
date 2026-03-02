import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
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
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:file_picker/file_picker.dart';
import '../models/trip.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../services/chat_service.dart';
import '../services/plan_service.dart';
import '../services/location_share_service.dart';
import '../models/trip_plan.dart';
import '../models/expense.dart';
import '../services/trip_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';
import 'live_location_map.dart';
import '../screens/chat_media_gallery.dart';
import '../screens/profile_screen.dart';
import '../services/offline_queue_service.dart';

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
  // Optimistic messages for instant display
  final List<ChatMessage> _optimisticMessages = [];
  // Read receipts data (updated via stream)
  List<Map<String, dynamic>> _readReceipts = [];
  late Stream<List<Map<String, dynamic>>> _readReceiptsStream;

  // @Mention overlay state
  bool _showMentionOverlay = false;
  String _mentionQuery = '';
  int _mentionStartIndex = -1;

  // Scroll-to-bottom FAB
  bool _showScrollToBottom = false;

  // Message search
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ChatMessage> _searchResults = [];
  bool _isSearchLoading = false;
  String? _highlightedMessageId;
  Timer? _searchDebounce;
  Timer? _highlightTimer;

  // Online presence
  Set<String> _onlineUserIds = {};

  // Offline cache & performance
  List<Map<String, dynamic>> _cachedMessages = [];
  bool _hasCachedData = false;
  Timer? _reactionDebounceTimer;
  final Map<String, String> _pendingReactions = {}; // messageId -> reaction
  int _messageLimit = 50; // pagination: load 50 initially
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Init offline queue & load cached messages immediately
    OfflineQueueService.instance.init();
    _loadCachedMessages();

    _messagesStream = Supabase.instance.client
        .from('trip_messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', widget.trip.id)
        .order('created_at', ascending: false)
        .map((data) {
          // Cache incoming messages in background
          OfflineQueueService.instance.cacheMessages(widget.trip.id, data);
          return data;
        });

    _reactionsStream = Supabase.instance.client
        .from('message_reactions')
        .stream(primaryKey: ['id'])
        .eq('trip_id', widget.trip.id)
        .map((data) => data);

    _readReceiptsStream = ChatService.instance.readReceiptsStream(widget.trip.id);
    // Listen to read receipts and keep local copy for status computation
    _readReceiptsStream.listen((data) {
      if (mounted) setState(() => _readReceipts = data);
    });

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
    final currentUid = Supabase.instance.client.auth.currentUser?.id;
    _chatChannel = Supabase.instance.client.channel('trip_chat:${widget.trip.id}');
    
    _chatChannel.onBroadcast(event: 'typing', callback: (payload) {
      final uid = payload['user_id'] as String;
      final name = payload['user_name'] as String;
      final isTyping = payload['is_typing'] as bool;

      if (uid == currentUid) return;

      setState(() {
        if (isTyping) {
          _typingUsers[name] = DateTime.now();
        } else {
          _typingUsers.remove(name);
        }
      });
    })
    .onPresenceSync((payload) {
      final presenceState = _chatChannel.presenceState();
      final online = <String>{};
      for (final state in presenceState) {
        for (final presence in state.presences) {
          final uid = presence.payload['user_id'];
          if (uid is String) online.add(uid);
        }
      }
      if (mounted) setState(() => _onlineUserIds = online);
    })
    .subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed && currentUid != null) {
        await _chatChannel.track({
          'user_id': currentUid,
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });

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

    // Detect @mention trigger
    _detectMentionTrigger(text);
  }

  void _detectMentionTrigger(String text) {
    final cursorPos = _msgController.selection.baseOffset;
    if (cursorPos < 0) {
      setState(() => _showMentionOverlay = false);
      return;
    }

    // Look backwards from cursor for '@'
    final textBeforeCursor = text.substring(0, cursorPos);
    final lastAt = textBeforeCursor.lastIndexOf('@');

    if (lastAt == -1) {
      setState(() => _showMentionOverlay = false);
      return;
    }

    // Ensure '@' is at start or preceded by a space
    if (lastAt > 0 && textBeforeCursor[lastAt - 1] != ' ' && textBeforeCursor[lastAt - 1] != '\n') {
      setState(() => _showMentionOverlay = false);
      return;
    }

    // Extract the query after '@'
    final query = textBeforeCursor.substring(lastAt + 1);
    // If there's a space in the query, the mention is complete
    if (query.contains(' ')) {
      setState(() => _showMentionOverlay = false);
      return;
    }

    setState(() {
      _showMentionOverlay = true;
      _mentionQuery = query.toLowerCase();
      _mentionStartIndex = lastAt;
    });
  }

  void _insertMention(UserProfile profile) {
    final text = _msgController.text;
    final cursorPos = _msgController.selection.baseOffset;
    final before = text.substring(0, _mentionStartIndex);
    final after = cursorPos < text.length ? text.substring(cursorPos) : '';
    final mentionText = '@${profile.displayName ?? 'User'} ';
    final newText = '$before$mentionText$after';
    _msgController.text = newText;
    _msgController.selection = TextSelection.collapsed(
      offset: _mentionStartIndex + mentionText.length,
    );
    setState(() => _showMentionOverlay = false);
  }

  void _insertEveryoneMention() {
    final text = _msgController.text;
    final cursorPos = _msgController.selection.baseOffset;
    final before = text.substring(0, _mentionStartIndex);
    final after = cursorPos < text.length ? text.substring(cursorPos) : '';
    const mentionText = '@everyone ';
    final newText = '$before$mentionText$after';
    _msgController.text = newText;
    _msgController.selection = TextSelection.collapsed(
      offset: _mentionStartIndex + mentionText.length,
    );
    setState(() => _showMentionOverlay = false);
  }

  void _insertWanderwithMention() {
    final text = _msgController.text;
    final cursorPos = _msgController.selection.baseOffset;
    final before = text.substring(0, _mentionStartIndex);
    final after = cursorPos < text.length ? text.substring(cursorPos) : '';
    const mentionText = '@wanderwith ';
    final newText = '$before$mentionText$after';
    _msgController.text = newText;
    _msgController.selection = TextSelection.collapsed(
      offset: _mentionStartIndex + mentionText.length,
    );
    setState(() => _showMentionOverlay = false);
  }

  void _onScroll() {
    // reverse:true means offset 0 = newest; show FAB if scrolled up > 300px
    final show = _scrollController.hasClients && _scrollController.offset > 300;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }

    // Pagination: load more when scrolled near the top (oldest messages)
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  /// Load cached messages from Isar for instant display
  Future<void> _loadCachedMessages() async {
    try {
      final cached = await OfflineQueueService.instance
          .getCachedMessages(widget.trip.id, limit: _messageLimit);
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _cachedMessages = cached;
          _hasCachedData = true;
        });
      }
    } catch (e) {
      // Silently fail — stream will provide live data anyway
    }
  }

  /// Pagination: increase message limit and reload
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final moreData = await Supabase.instance.client
          .from('trip_messages')
          .select()
          .eq('trip_id', widget.trip.id)
          .order('created_at', ascending: false)
          .range(_messageLimit, _messageLimit + 49);

      if (moreData.isEmpty) {
        setState(() => _hasMoreMessages = false);
      } else {
        _messageLimit += moreData.length;
      }
    } catch (e) {
      // Silently fail
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // ── Message search ──────────────────────────────────────────────────
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchResults = [];
        _isSearchLoading = false;
      } else {
        // Focus search field after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
      return;
    }
    setState(() => _isSearchLoading = true);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final data = await Supabase.instance.client
          .from('trip_messages')
          .select()
          .eq('trip_id', widget.trip.id)
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .limit(30);

      if (!mounted) return;
      setState(() {
        _searchResults = data
            .map((m) => ChatMessage.fromJson(m))
            .toList();
        _isSearchLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isSearchLoading = false);
    }
  }

  void _jumpToMessage(String messageId) {
    // First check if we need to load more messages to include this one.
    // The search result might be beyond the current _messageLimit.
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
      _highlightedMessageId = messageId;
    });

    // Clear highlight after 2.5 seconds
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });

    // Wait for rebuild, then try scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToMessageById(messageId);
    });
  }

  void _scrollToMessageById(String messageId) {
    if (!_scrollController.hasClients) return;

    // In the reversed ListView, index 0 is the newest message (scroll offset 0).
    // Older messages are at higher indices and higher scroll offsets.
    // We estimate ~80px per item (messages + date separators) and scroll to
    // the approximate position. The highlight animation makes the target visible.
    // Note: this is a best-effort approach—exact positioning requires
    // ScrollablePositionedList which would be a larger dependency.

    // For now, scroll to top (offset 0 = newest). The highlight makes it findable.
    // If users frequently search old messages, we can add ScrollablePositionedList later.
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _reactionDebounceTimer?.cancel();
    _searchDebounce?.cancel();
    _highlightTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _chatChannel.untrack();
    _msgController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _chatChannel.unsubscribe();
    super.dispose();
  }

  final List<String> _toxicWords = ['badword1', 'badword2', 'toxic']; // Simplified blacklist

  /// Parse @mentions in text and resolve to user IDs using _memberProfiles.
  /// Supports @everyone (resolves to all members except sender).
  List<String> _parseMentionedUserIds(String text) {
    // Check for @everyone first
    if (RegExp(r'@everyone\b', caseSensitive: false).hasMatch(text)) {
      final currentUid = Supabase.instance.client.auth.currentUser?.id;
      return _memberProfiles.keys.where((id) => id != currentUid).toList();
    }

    // Build a regex from known member display names for precise matching
    final names = _memberProfiles.values
        .map((p) => p.displayName)
        .where((n) => n != null && n.isNotEmpty)
        .map((n) => RegExp.escape(n!))
        .toList();
    if (names.isEmpty) return [];

    final namePattern = names.join('|');
    final mentionRegex = RegExp('@($namePattern)', caseSensitive: false);
    final mentionedIds = <String>{};

    for (final match in mentionRegex.allMatches(text)) {
      final mentionName = match.group(1)?.toLowerCase() ?? '';
      for (final entry in _memberProfiles.entries) {
        final displayName = (entry.value.displayName ?? '').toLowerCase();
        if (mentionName == displayName) {
          mentionedIds.add(entry.key);
        }
      }
    }
    return mentionedIds.toList();
  }

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

    final Map<String, dynamic> metadata = {};
    if (replyTo != null) {
      metadata['reply_to'] = {
        'id': replyTo.id,
        'sender_name': replyTo.senderName,
        'content': replyTo.content.isEmpty ? '[Media]' : replyTo.content,
      };
    }

    // Parse @mentions from text
    final mentionedUserIds = _parseMentionedUserIds(text);

    try {
      // Optimistic: show message instantly before DB roundtrip
      final optimisticId = 'optimistic_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final optimisticMsg = ChatMessage(
        id: optimisticId,
        tripId: widget.trip.id,
        senderId: uid,
        senderName: name,
        content: text,
        type: ChatMessageType.text,
        metadata: metadata,
        isPinned: false,
        deletedFor: [],
        isEdited: false,
        reactions: [],
        createdAt: now,
        updatedAt: now,
        mentionedUserIds: mentionedUserIds,
      );
      setState(() => _optimisticMessages.insert(0, optimisticMsg));

      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }

      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': name,
        'content': text,
        'type': 'text',
        'metadata': metadata,
        'mentioned_user_ids': mentionedUserIds,
      });

      // Send smart chat notifications
      NotificationService().sendChatNotification(
        tripId: widget.trip.id,
        tripName: widget.trip.name,
        senderId: uid,
        senderName: name,
        content: text,
        messageType: 'text',
        mentionedUserIds: mentionedUserIds,
        replyToUserId: replyTo != null ? replyTo.senderId : null,
      );

      // Remove optimistic message once stream delivers real one
      if (mounted) setState(() => _optimisticMessages.removeWhere((m) => m.id == optimisticId));

      // AI BOT TRIGGER
      if (text.toLowerCase().contains('@wanderwith')) {
        _handleAIBot(text, uid, name);
      }
    } catch (e) {
      // Queue message offline instead of losing it
      await OfflineQueueService.instance.queueMessage(
        tripId: widget.trip.id,
        senderId: uid,
        senderName: name,
        content: text,
        type: 'text',
        metadata: metadata,
        mentionedUserIds: mentionedUserIds,
      );
      // Keep optimistic message visible with a "queued" indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Message queued — will send when online")),
        );
      }
    }
  }

  void _handleAIBot(String userText, String uid, String name) async {
    try {
      // Fetch recent chat history for multi-turn context
      final recentRows = await Supabase.instance.client
          .from('trip_messages')
          .select('sender_name, content, metadata')
          .eq('trip_id', widget.trip.id)
          .eq('type', 'text')
          .order('created_at', ascending: false)
          .limit(10);
      final history = (recentRows as List).reversed.map<Map<String, String>>((r) {
        final isBot = r['metadata'] != null && r['metadata']['is_bot'] == true;
        return {
          'role': isBot ? 'model' : 'user',
          'text': '${r['sender_name']}: ${r['content']}',
        };
      }).toList();

      final response = await GeminiService().getChatResponse(
        userMessage: userText,
        trip: widget.trip,
        history: history,
      );
      
      // Build suggestion chips metadata
      final suggestions = <String>[
        '🌤 Weather forecast',
        '🍽 Restaurant suggestions',
        '💰 Budget breakdown',
        '🗺 Today\'s itinerary',
      ];

      // Use the current user's ID as sender_id to satisfy RLS policy
      // (sender_id must match auth.uid()). The message is identified as
      // a bot response via is_bot: true in metadata and sender_name.
      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': 'WanderWith AI',
        'content': response,
        'type': 'text',
        'metadata': {
          'is_bot': true,
          'suggestions': suggestions,
        },
      });
    } catch (e) {
      debugPrint("AI Bot error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("AI couldn't respond: $e"), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _toggleReaction(String messageId, String userId, String reaction) async {
    final reactionKey = "$userId:$reaction";
    
    // Optimistic UI update immediately
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

    // Debounce the actual DB call by 300ms to batch rapid toggles
    _pendingReactions[messageId] = reaction;
    _reactionDebounceTimer?.cancel();
    _reactionDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final pendingReaction = _pendingReactions.remove(messageId);
      if (pendingReaction == null) return;

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

        // Send reaction notification to message owner
        try {
          final msgData = await Supabase.instance.client
              .from('trip_messages')
              .select('sender_id')
              .eq('id', messageId)
              .maybeSingle();
          if (msgData != null) {
            final ownerId = msgData['sender_id'] as String;
            final reactorName = _memberProfiles[userId]?.displayName ?? 'Someone';
            NotificationService().sendReactionNotification(
              tripId: widget.trip.id,
              tripName: widget.trip.name,
              reactorId: userId,
              reactorName: reactorName,
              messageOwnerId: ownerId,
              emoji: reaction,
            );
          }
        } catch (_) {}
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
    }); // end debounce timer
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

      NotificationService().sendChatNotification(
        tripId: widget.trip.id,
        tripName: widget.trip.name,
        senderId: uid,
        senderName: name,
        content: '',
        messageType: 'image',
      );

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
    try {
      // Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission denied")));
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Reverse geocode for address
      String address = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          address = [p.street, p.locality].where((s) => s != null && s.isNotEmpty).join(', ');
          if (address.isEmpty) address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      } catch (_) {}

      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': name,
        'content': address,
        'type': 'location',
        'metadata': {
          'lat': position.latitude,
          'lng': position.longitude,
          'address': address,
        },
      });

      NotificationService().sendChatNotification(
        tripId: widget.trip.id,
        tripName: widget.trip.name,
        senderId: uid,
        senderName: name,
        content: address,
        messageType: 'location',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location share failed: $e")));
    }
  }

  /// Shows options: Share Current Location or Share Live Location
  void _showLocationOptions(String uid, String name) {
    final colors = context.appColors;
    final isCurrentlySharing = LocationShareService.instance.isSharing &&
        LocationShareService.instance.activeTripId == widget.trip.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: const Icon(Icons.my_location, color: Colors.green),
              ),
              title: Text("Share Current Location", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text("Send your current GPS coordinates", style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _shareLocation(uid, name);
              },
            ),
            const Divider(height: 1),
            if (isCurrentlySharing)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: const Icon(Icons.stop, color: Colors.red),
                ),
                title: Text("Stop Live Location", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                subtitle: Text("Stop sharing your live location", style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await LocationShareService.instance.stopSharing();
                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Live location sharing stopped")));
                  }
                },
              )
            else
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.share_location, color: Colors.blue),
                ),
                title: Text("Share Live Location", style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text("Share your location in real-time", style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLiveDurationPicker(uid, name);
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Duration picker for live location sharing
  void _showLiveDurationPicker(String uid, String name) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Share Live Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            const SizedBox(height: 4),
            Text("Choose how long to share", style: TextStyle(fontSize: 13, color: colors.textSecondary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDurationChip("15 min", const Duration(minutes: 15), uid, name, ctx),
                _buildDurationChip("1 hour", const Duration(hours: 1), uid, name, ctx),
                _buildDurationChip("8 hours", const Duration(hours: 8), uid, name, ctx),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(String label, Duration duration, String uid, String name, BuildContext ctx) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(ctx);
        try {
          await LocationShareService.instance.startSharing(widget.trip.id, duration);
          // Post system message
          await Supabase.instance.client.from('trip_messages').insert({
            'trip_id': widget.trip.id,
            'sender_id': uid,
            'sender_name': name,
            'content': '$name is sharing live location for $label',
            'type': 'system',
            'metadata': {
              'event': 'live_location_started',
              'duration': label,
            },
          });
          if (mounted) setState(() {});
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to start: $e")));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.brand.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brand.withOpacity(0.3)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.brand)),
      ),
    );
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
                  _showLocationOptions(uid, name);
                }),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.map_outlined, "Plan Item", Colors.teal, () {
                  Navigator.pop(context);
                  _showPlanItemPicker(uid, name);
                }),
                _buildAttachmentOption(Icons.receipt_long, "Expense", Colors.orange, () {
                  Navigator.pop(context);
                  _showExpensePicker(uid, name);
                }),
                _buildAttachmentOption(Icons.poll, "Poll", Colors.indigo, () {
                  Navigator.pop(context);
                  _showCreatePollSheet(uid, name);
                }),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(Icons.insert_drive_file, "Document", Colors.blueGrey, () {
                  Navigator.pop(context);
                  _sendDocument(uid, name);
                }),
                const SizedBox(width: 80),
                const SizedBox(width: 80),
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

  /// Shows a bottom sheet picker listing all plan places from the trip
  void _showPlanItemPicker(String uid, String name) async {
    final colors = context.appColors;
    try {
      final days = await PlanService().fetchTripPlan(widget.trip.id);
      if (!mounted) return;
      if (days.isEmpty || days.every((d) => d.places.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No plan items to share. Add places to your plan first.")),
        );
        return;
      }
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Share Plan Item", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: days.length,
                  itemBuilder: (ctx, di) {
                    final day = days[di];
                    if (day.places.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text("Day ${day.dayNumber}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textSecondary)),
                        ),
                        ...day.places.map((place) => ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: place.imageUrl != null && place.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(imageUrl: place.imageUrl!, width: 48, height: 48, fit: BoxFit.cover, errorWidget: (_, __, ___) => _placeholderIcon(colors))
                                : _placeholderIcon(colors),
                          ),
                          title: Text(place.name, style: TextStyle(fontSize: 14, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            [place.type, if (place.arrivalTime != null) place.arrivalTime!].join(' · '),
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _sendPlanItemMessage(uid, name, place, day.dayNumber);
                          },
                        )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load plan: $e")));
    }
  }

  Widget _placeholderIcon(dynamic colors) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: AppColors.brand.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.place, color: AppColors.brand, size: 24),
    );
  }

  void _sendPlanItemMessage(String uid, String name, TripPlanPlace place, int dayNumber) async {
    try {
      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': name,
        'content': '📋 Shared a plan item: ${place.name}',
        'type': 'planItem',
        'metadata': {
          'plan_item_id': place.id,
          'place_name': place.name,
          'place_image': place.imageUrl ?? '',
          'day_number': dayNumber,
          'time_slot': place.arrivalTime ?? '',
          'category': place.type,
        },
      });

      NotificationService().sendChatNotification(
        tripId: widget.trip.id,
        tripName: widget.trip.name,
        senderId: uid,
        senderName: name,
        content: place.name,
        messageType: 'planItem',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to share plan item: $e")));
    }
  }

  /// Shows a bottom sheet picker listing recent expenses from the trip
  void _showExpensePicker(String uid, String name) async {
    final colors = context.appColors;
    try {
      final rows = await Supabase.instance.client
          .from('trip_expenses')
          .select('*, expense_splits(*)')
          .eq('trip_id', widget.trip.id)
          .order('created_at', ascending: false)
          .limit(20);

      if (!mounted) return;
      final expenses = (rows as List).map((r) => TripExpense.fromJson(r)).toList();
      if (expenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No expenses to share. Add expenses first.")),
        );
        return;
      }
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text("Share Expense", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (ctx, i) {
                    final exp = expenses[i];
                    final emoji = TripExpense.categoryEmoji(exp.category);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(exp.title, style: TextStyle(fontSize: 14, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${exp.currency} ${exp.amount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendExpenseMessage(uid, name, exp);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load expenses: $e")));
    }
  }

  void _sendExpenseMessage(String uid, String name, TripExpense expense) async {
    // Resolve payer name
    String paidByName = 'Someone';
    final payer = _memberProfiles[expense.paidBy];
    if (payer != null) {
      paidByName = payer.displayName ?? 'User';
    }

    try {
      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': name,
        'content': '💰 Shared an expense: ${expense.title}',
        'type': 'expense',
        'metadata': {
          'expense_id': expense.id,
          'title': expense.title,
          'amount': expense.amount,
          'currency': expense.currency,
          'split_count': expense.splits.length,
          'per_person': expense.splits.isNotEmpty ? expense.splits.first.amount : 0,
          'paid_by': paidByName,
          'category': expense.category,
        },
      });

      NotificationService().sendChatNotification(
        tripId: widget.trip.id,
        tripName: widget.trip.name,
        senderId: uid,
        senderName: name,
        content: expense.title,
        messageType: 'expense',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to share expense: $e")));
    }
  }

  /// Bottom sheet for creating a poll directly from chat
  void _showCreatePollSheet(String uid, String name) {
    final questionController = TextEditingController();
    final optionControllers = [TextEditingController(), TextEditingController()];
    bool allowMultiple = false;
    DateTime? expiresAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ctx.appColors;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),
                    Text('Create Poll', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    const SizedBox(height: 16),
                    // Question
                    TextField(
                      controller: questionController,
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: colors.surfaceBg,
                      ),
                      maxLength: 200,
                    ),
                    const SizedBox(height: 8),
                    // Options
                    ...List.generate(optionControllers.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optionControllers[i],
                                decoration: InputDecoration(
                                  hintText: 'Option ${i + 1}',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  filled: true,
                                  fillColor: colors.surfaceBg,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                ),
                              ),
                            ),
                            if (optionControllers.length > 2)
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 20),
                                onPressed: () {
                                  setModalState(() {
                                    optionControllers[i].dispose();
                                    optionControllers.removeAt(i);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    if (optionControllers.length < 6)
                      TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            optionControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Option'),
                      ),
                    const SizedBox(height: 8),
                    // Toggles row
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            value: allowMultiple,
                            onChanged: (v) => setModalState(() => allowMultiple = v),
                            title: Text('Multi-select', style: TextStyle(fontSize: 13, color: colors.textPrimary)),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    // Expiry picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(Icons.timer_outlined, color: colors.textSecondary),
                      title: Text(
                        expiresAt != null ? 'Ends ${DateFormat.yMMMd().add_jm().format(expiresAt!)}' : 'No expiry',
                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                            setModalState(() {
                              expiresAt = DateTime(date.year, date.month, date.day, time?.hour ?? 23, time?.minute ?? 59);
                            });
                          }
                        },
                        child: Text(expiresAt != null ? 'Change' : 'Set'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Create button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          final q = questionController.text.trim();
                          final opts = optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                          if (q.isEmpty || opts.length < 2) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Need a question and at least 2 options')));
                            return;
                          }
                          Navigator.pop(ctx);
                          try {
                            // Create poll via existing service
                            final pollId = await TripService().createPollRelational(
                              tripId: widget.trip.id,
                              question: q,
                              options: opts,
                              endsAt: expiresAt,
                              isAnonymous: false,
                              allowMultiple: allowMultiple,
                              isPinned: false,
                            );
                            if (pollId == null) return;
                            // Fetch the actual option IDs from DB
                            final optRows = await Supabase.instance.client
                                .from('trip_poll_options')
                                .select('id, option_text')
                                .eq('poll_id', pollId)
                                .order('created_at', ascending: true);
                            final optionsMeta = (optRows as List).map<Map<String, dynamic>>((r) => {
                              'id': r['id'] as String,
                              'text': r['option_text'] as String,
                            }).toList();
                            // Post a poll-type chat message
                            await Supabase.instance.client.from('trip_messages').insert({
                              'trip_id': widget.trip.id,
                              'sender_id': uid,
                              'sender_name': name,
                              'content': '📊 Created a poll: $q',
                              'type': 'poll',
                              'metadata': {
                                'poll_id': pollId,
                                'question': q,
                                'options': optionsMeta,
                                'votes': <Map<String, dynamic>>[],
                                'total_votes': 0,
                                'is_closed': false,
                                'allow_multiple': allowMultiple,
                                if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
                              },
                            });
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to create poll: $e")));
                          }
                        },
                        child: const Text('Create Poll', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Pick and upload a document/file to chat
  void _sendDocument(String uid, String name) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'zip', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null || file.name.isEmpty) return;

      // Size limit: 10 MB
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File too large (max 10 MB)')));
        }
        return;
      }

      final ext = file.extension ?? 'bin';
      final storagePath = 'trip_documents/${widget.trip.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      // Upload to Supabase Storage
      await Supabase.instance.client.storage.from('trip-media').uploadBinary(
        storagePath,
        file.bytes!,
        fileOptions: FileOptions(contentType: _mimeFromExt(ext)),
      );

      final publicUrl = Supabase.instance.client.storage.from('trip-media').getPublicUrl(storagePath);

      // Insert chat message
      await Supabase.instance.client.from('trip_messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': uid,
        'sender_name': name,
        'content': '📄 Shared a file: ${file.name}',
        'type': 'document',
        'metadata': {
          'url': publicUrl,
          'file_name': file.name,
          'file_size': file.size,
          'file_type': _mimeFromExt(ext),
        },
      });

      NotificationService().sendChatNotification(
        tripId: widget.trip.id,
        tripName: widget.trip.name,
        senderId: uid,
        senderName: name,
        content: file.name,
        messageType: 'document',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to share file: $e")));
    }
  }

  String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt': return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt': return 'text/plain';
      case 'csv': return 'text/csv';
      case 'zip': return 'application/zip';
      case 'png': return 'image/png';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      default: return 'application/octet-stream';
    }
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
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 4, backgroundColor: Colors.green),
              const SizedBox(width: 8),
              Text(
                _onlineUserIds.isEmpty
                    ? "${widget.trip.memberIds.length} members"
                    : "${_onlineUserIds.length} online · ${widget.trip.memberIds.length} members",
                style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500),
              ),
              // Offline queue indicator
              if (!OfflineQueueService.instance.isOnline)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade700),
                ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.search_off : Icons.search,
                  size: 20,
                  color: _isSearching ? AppColors.brand : colors.textMuted,
                ),
                tooltip: 'Search messages',
                onPressed: _toggleSearch,
              ),
              IconButton(
                icon: Icon(Icons.info_outline, size: 20, color: colors.textMuted),
                onPressed: () => _showTripInfo(),
              ),
            ],
          ),
        ),

        // ── Search bar (animated slide-down) ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            decoration: BoxDecoration(
              color: colors.cardBg,
              border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search, size: 20, color: colors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: colors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                // Search results
                if (_isSearchLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (_searchResults.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: colors.border.withOpacity(0.5)),
                      itemBuilder: (context, index) {
                        final msg = _searchResults[index];
                        final sender = _memberProfiles[msg.senderId];
                        final senderName = sender?.displayName ?? msg.senderName ?? 'Unknown';
                        final query = _searchController.text.trim().toLowerCase();
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.brand.withOpacity(0.15),
                            backgroundImage: sender?.avatarUrl != null && sender!.avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(sender.avatarUrl!)
                                : null,
                            child: sender?.avatarUrl == null || sender!.avatarUrl!.isEmpty
                                ? Text(senderName[0].toUpperCase(),
                                    style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold, fontSize: 12))
                                : null,
                          ),
                          title: _buildHighlightedText(msg.content, query, colors),
                          subtitle: Text(
                            '$senderName · ${DateFormat('MMM d, h:mm a').format(msg.createdAt)}',
                            style: TextStyle(fontSize: 11, color: colors.textMuted),
                          ),
                          onTap: () => _jumpToMessage(msg.id),
                        );
                      },
                    ),
                  )
                else if (_searchController.text.trim().length >= 2 && !_isSearchLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No messages found', style: TextStyle(color: colors.textMuted, fontSize: 13)),
                  ),
              ],
            ),
          ),
          crossFadeState: _isSearching ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        
        // Live location banner (shows when active)
        LiveLocationBanner(
          tripId: widget.trip.id,
          memberProfiles: _memberProfiles,
        ),
        
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messagesStream,
            builder: (context, msgSnapshot) {
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _reactionsStream,
                builder: (context, reactSnapshot) {
                  final isLoading = msgSnapshot.connectionState == ConnectionState.waiting;

                  // Use cached messages while stream is still loading
                  final msgData = (isLoading && _hasCachedData)
                      ? _cachedMessages
                      : (msgSnapshot.data ?? []);
                  final reactData = reactSnapshot.data ?? [];

                  // Apply pagination limit
                  final limitedMsgData = msgData.take(_messageLimit).toList();

                  final messages = limitedMsgData
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

                  // Merge optimistic messages (not yet confirmed by stream)
                  // Remove optimistic msgs whose content already appeared in stream
                  if (_optimisticMessages.isNotEmpty) {
                    final streamContents = messages.map((m) => '${m.senderId}:${m.content}').toSet();
                    _optimisticMessages.removeWhere((om) => streamContents.contains('${om.senderId}:${om.content}'));
                    // Add remaining optimistic messages at the top (index 0 = newest since reversed)
                    for (final om in _optimisticMessages) {
                      messages.insert(0, om);
                    }
                  }

                  if (messages.isEmpty && !isLoading && _optimisticMessages.isEmpty) return _buildEmptyState();

                  // Mark latest message as read
                  if (messages.isNotEmpty && messages.first.senderId != user.id) {
                    // Schedule after build to avoid setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ChatService.instance.markAsRead(widget.trip.id, messages.first.id);
                    });
                  }

                  final pinnedMessages = messages.where((m) => m.isPinned).toList();

                  // Build mixed list with date separators
                  // messages is ordered newest-first (index 0 = newest) since reverse: true
                  final List<dynamic> chatItems = []; // ChatMessage or 'date:YYYY-MM-DD'
                  for (int i = 0; i < messages.length; i++) {
                    chatItems.add(messages[i]);
                    // Check if we need a date separator AFTER this message
                    // (visually ABOVE it since list is reversed)
                    final currentDate = DateTime(
                      messages[i].createdAt.year,
                      messages[i].createdAt.month,
                      messages[i].createdAt.day,
                    );
                    if (i + 1 < messages.length) {
                      final nextDate = DateTime(
                        messages[i + 1].createdAt.year,
                        messages[i + 1].createdAt.month,
                        messages[i + 1].createdAt.day,
                      );
                      if (currentDate != nextDate) {
                        chatItems.add('date:${currentDate.toIso8601String()}');
                      }
                    } else {
                      // Last message (oldest visible) — always show its date
                      chatItems.add('date:${currentDate.toIso8601String()}');
                    }
                  }

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
                        child: Stack(
                          children: [
                            Skeletonizer(
                          enabled: isLoading && !_hasCachedData,
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            itemCount: isLoading && !_hasCachedData
                                ? 5
                                : chatItems.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (isLoading && !_hasCachedData) return _buildSkeletonBubble();

                              // "Loading more" indicator at the very end (top of reversed list)
                              if (index == chatItems.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                                );
                              }

                              final item = chatItems[index];

                              // Date separator
                              if (item is String && item.startsWith('date:')) {
                                final date = DateTime.parse(item.substring(5));
                                return _buildDateSeparator(date);
                              }

                              final msg = item as ChatMessage;
                              final isMe = msg.senderId == user.id;
                              final isAgency = _memberProfiles[msg.senderId]?.role == 'agency';

                              // Message grouping: check if same sender within 2 min
                              bool showSenderName = true;
                              bool isLastInGroup = true;

                              // Find the PREVIOUS message in display order (next index since reversed)
                              final nextIdx = index + 1;
                              if (nextIdx < chatItems.length && chatItems[nextIdx] is ChatMessage) {
                                final prevMsg = chatItems[nextIdx] as ChatMessage;
                                if (prevMsg.senderId == msg.senderId &&
                                    msg.createdAt.difference(prevMsg.createdAt).inMinutes.abs() < 2) {
                                  showSenderName = false;
                                }
                              }
                              // Check if NEXT message in display order (prev index)
                              final prevIdx = index - 1;
                              if (prevIdx >= 0 && chatItems[prevIdx] is ChatMessage) {
                                final nextMsg = chatItems[prevIdx] as ChatMessage;
                                if (nextMsg.senderId == msg.senderId &&
                                    nextMsg.createdAt.difference(msg.createdAt).inMinutes.abs() < 2) {
                                  isLastInGroup = false;
                                }
                              }

                              // Compute read status for sender's messages
                              String messageStatus = 'sent';
                              if (isMe && !msg.id.startsWith('optimistic_')) {
                                messageStatus = ChatService.computeMessageStatus(
                                  messageId: msg.id,
                                  messageCreatedAt: msg.createdAt,
                                  senderId: msg.senderId!,
                                  memberIds: widget.trip.memberIds,
                                  readReceipts: _readReceipts,
                                );
                              }

                              // Render system messages as centered pills (no bubble)
                              if (msg.type == ChatMessageType.system) {
                                return _buildSystemMessage(msg);
                              }

                                final isHighlighted = _highlightedMessageId == msg.id;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  decoration: BoxDecoration(
                                    color: isHighlighted
                                        ? AppColors.brand.withOpacity(0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Dismissible(
                                  key: ValueKey('swipe_${msg.id}'),
                                  direction: isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
                                  confirmDismiss: (_) async {
                                    _startReplying(msg);
                                    return false; // Don't actually dismiss
                                  },
                                  background: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Icon(Icons.reply, color: colors.textSecondary, size: 24),
                                  ),
                                  child: _MessageBubble(
                                  message: msg, 
                                  isMe: isMe,
                                  isAgency: isAgency,
                                  showSenderName: showSenderName,
                                  isLastInGroup: isLastInGroup,
                                  messageStatus: messageStatus,
                                  memberCount: widget.trip.memberIds.length,
                                  readReceipts: _readReceipts,
                                  memberProfiles: _memberProfiles,
                                  onMentionTap: (userId) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)));
                                  },
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
                                  onSuggestionTap: (suggestion) {
                                    // Auto-fill the text field with the suggestion as @wanderwith query
                                    _msgController.text = '@wanderwith $suggestion';
                                    _sendMessage(user.id, userProfile?.displayName ?? 'User');
                                  },
                                ),
                                ),
                                );
                            },
                          ),
                        ),
                            // Scroll-to-bottom FAB
                            if (_showScrollToBottom)
                              Positioned(
                                right: 16,
                                bottom: 12,
                                child: FloatingActionButton.small(
                                  heroTag: 'scrollToBottom',
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  elevation: 4,
                                  onPressed: () {
                                    _scrollController.animateTo(
                                      0,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  child: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                          ],
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
            const SizedBox(height: 16),
            // Media & Files shortcut
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatMediaGallery(tripId: widget.trip.id, tripName: widget.trip.name),
                  ));
                },
                icon: Icon(Icons.perm_media_outlined, size: 18, color: AppColors.brand),
                label: Text('Media & Files', style: TextStyle(color: AppColors.brand)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: BorderSide(color: AppColors.brand.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: widget.trip.memberIds.length,
                itemBuilder: (context, index) {
                  final mid = widget.trip.memberIds[index];
                  final profile = _memberProfiles[mid];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDark ? AppColors.brand.withOpacity(0.15) : Colors.blue.shade50,
                          backgroundImage: profile?.avatarUrl != null ? CachedNetworkImageProvider(profile!.avatarUrl!) : null,
                          child: profile?.avatarUrl == null ? Icon(Icons.person, color: AppColors.brand) : null,
                        ),
                        if (_onlineUserIds.contains(mid))
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.cardBg, width: 2),
                              ),
                            ),
                          ),
                      ],
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

  /// Build text with the search query highlighted in bold brand color.
  Widget _buildHighlightedText(String text, String query, dynamic colors) {
    if (query.isEmpty) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: colors.textPrimary));
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brand),
      ));
      start = idx + query.length;
    }
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(fontSize: 13, color: colors.textPrimary),
        children: spans,
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

  Widget _buildDateSeparator(DateTime date) {
    final colors = context.appColors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    String label;
    if (d == today) {
      label = 'Today';
    } else if (d == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: colors.surfaceBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 2)],
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage msg) {
    final colors = context.appColors;
    final event = msg.metadata['event'] as String? ?? '';

    // Pick icon based on event type
    IconData icon;
    switch (event) {
      case 'member_joined':
        icon = Icons.person_add_alt_1;
        break;
      case 'member_left':
        icon = Icons.person_remove;
        break;
      case 'member_removed':
        icon = Icons.person_off;
        break;
      case 'expense_added':
        icon = Icons.receipt_long;
        break;
      case 'place_added':
        icon = Icons.place;
        break;
      case 'trip_dates_changed':
        icon = Icons.calendar_today;
        break;
      default:
        icon = Icons.info_outline;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.textMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                msg.content,
                style: TextStyle(fontSize: 12, color: colors.textSecondary, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(String uid, String name) {
    final colors = context.appColors;

    // Filter members for mention overlay
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final filteredMembers = _memberProfiles.values.where((p) {
      if (p.uid == currentUserId) return false; // Don't show self
      if (_mentionQuery.isEmpty) return true;
      return (p.displayName ?? '').toLowerCase().contains(_mentionQuery);
    }).toList();

    // Check if @everyone should appear in the overlay
    final showEveryoneOption = _mentionQuery.isEmpty || 'everyone'.contains(_mentionQuery);
    final showWanderwithOption = _mentionQuery.isEmpty || 'wanderwith'.contains(_mentionQuery);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // @Mention suggestions overlay
        if (_showMentionOverlay && (filteredMembers.isNotEmpty || showEveryoneOption || showWanderwithOption))
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: filteredMembers.length + (showEveryoneOption ? 1 : 0) + (showWanderwithOption ? 1 : 0),
              itemBuilder: (context, index) {
                // First item: @everyone
                if (showEveryoneOption && index == 0) {
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.brand.withOpacity(0.2),
                      child: Icon(Icons.groups, color: AppColors.brand, size: 18),
                    ),
                    title: Text('@everyone', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Notify all members', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                    onTap: () => _insertEveryoneMention(),
                  );
                }
                // Second special item: @wanderwith
                final wanderwithIndex = showEveryoneOption ? 1 : 0;
                if (showWanderwithOption && index == wanderwithIndex) {
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.indigo.withOpacity(0.2),
                      child: Icon(Icons.auto_awesome, color: Colors.indigo, size: 18),
                    ),
                    title: Text('@wanderwith', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('Ask AI travel assistant', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                    onTap: () => _insertWanderwithMention(),
                  );
                }
                final specialCount = (showEveryoneOption ? 1 : 0) + (showWanderwithOption ? 1 : 0);
                final member = filteredMembers[index - specialCount];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(member.avatarUrl!)
                        : null,
                    backgroundColor: AppColors.brand.withOpacity(0.2),
                    child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                        ? Text((member.displayName ?? '?')[0].toUpperCase(), style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold, fontSize: 14))
                        : null,
                  ),
                  title: Text(member.displayName ?? 'Unknown', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  onTap: () => _insertMention(member),
                );
              },
            ),
          ),
        // Original input bar
        Container(
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
                // AI Quick-Action Button
                IconButton(
                  icon: Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 22),
                  tooltip: 'Ask AI Assistant',
                  onPressed: () {
                    _msgController.text = '@wanderwith ';
                    _msgController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _msgController.text.length),
                    );
                  },
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
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isAgency;
  final bool showSenderName;
  final bool isLastInGroup;
  final String messageStatus; // 'sent', 'delivered', 'read'
  final int memberCount;
  final List<Map<String, dynamic>> readReceipts;
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
  final Function(String)? onSuggestionTap;
  final Map<String, UserProfile> memberProfiles;
  final Function(String)? onMentionTap;

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
    required this.memberProfiles,
    this.showSenderName = true,
    this.isLastInGroup = true,
    this.messageStatus = 'sent',
    this.memberCount = 1,
    this.readReceipts = const [],
    this.isAgency = false,
    this.isDead = false,
    this.onSuggestionTap,
    this.onMentionTap,
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
      padding: EdgeInsets.symmetric(vertical: isLastInGroup ? 4 : 1),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : isBot ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (!isMe && !isBot && showSenderName)
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
              Flexible(
              child: GestureDetector(
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
                                // AI suggestion chips
                                if (message.metadata['is_bot'] == true && message.metadata['suggestions'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: (message.metadata['suggestions'] as List<dynamic>).map<Widget>((s) {
                                        return ActionChip(
                                          label: Text(s.toString(), style: const TextStyle(fontSize: 11)),
                                          backgroundColor: AppColors.brand.withOpacity(0.1),
                                          side: BorderSide(color: AppColors.brand.withOpacity(0.3)),
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => onSuggestionTap?.call(s.toString()),
                                        );
                                      }).toList(),
                                    ),
                                  ),
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
                                  if (isMe) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      messageStatus == 'read' || messageStatus == 'delivered'
                                          ? Icons.done_all
                                          : Icons.check,
                                      size: 12,
                                      color: messageStatus == 'read'
                                          ? Colors.lightBlueAccent
                                          : Colors.white54,
                                    ),
                                  ],
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
      case ChatMessageType.planItem:
        return _buildPlanItemCard(context);
      case ChatMessageType.expense:
        return _buildExpenseCard(context);
      case ChatMessageType.poll:
        return _buildPollCard(context);
      case ChatMessageType.document:
        return _buildDocumentCard(context);
      case ChatMessageType.text:
      default:
        return _buildRichText(context);
    }
  }

  /// Compact card for shared plan items
  Widget _buildPlanItemCard(BuildContext context) {
    final colors = context.appColors;
    final meta = message.metadata;
    final placeName = meta['place_name'] as String? ?? 'Unknown Place';
    final dayNumber = meta['day_number'];
    final timeSlot = meta['time_slot'] as String? ?? '';
    final category = meta['category'] as String? ?? 'place';
    final placeImage = meta['place_image'] as String?;

    String categoryIcon;
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'food':
        categoryIcon = '🍽️';
        break;
      case 'hotel':
      case 'accommodation':
        categoryIcon = '🏨';
        break;
      case 'sightseeing':
      case 'tourist_attraction':
        categoryIcon = '📸';
        break;
      case 'shopping':
        categoryIcon = '🛍️';
        break;
      default:
        categoryIcon = '📍';
    }

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.shade700 : colors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Place image or gradient header
          if (placeImage != null && placeImage.isNotEmpty)
            CachedNetworkImage(
              imageUrl: placeImage,
              width: 220,
              height: 100,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 220, height: 100,
                color: AppColors.brand.withOpacity(0.2),
                child: const Center(child: Icon(Icons.place, size: 32)),
              ),
            )
          else
            Container(
              width: 220, height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brand.withOpacity(0.3), AppColors.brand.withOpacity(0.1)],
                ),
              ),
              child: Center(child: Text(categoryIcon, style: const TextStyle(fontSize: 28))),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$categoryIcon $placeName',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isMe ? Colors.white : colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (dayNumber != null || timeSlot.isNotEmpty)
                  Text(
                    [if (dayNumber != null) 'Day $dayNumber', if (timeSlot.isNotEmpty) timeSlot].join(' · '),
                    style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : colors.textSecondary),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Navigate to Plan tab (index 3)
                    DefaultTabController.of(context).animateTo(3);
                  },
                  child: Text(
                    'View in Plan →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white : AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact card for shared expenses
  Widget _buildExpenseCard(BuildContext context) {
    final colors = context.appColors;
    final meta = message.metadata;
    final title = meta['title'] as String? ?? 'Expense';
    final amount = (meta['amount'] as num?)?.toDouble() ?? 0;
    final currency = meta['currency'] as String? ?? 'INR';
    final splitCount = meta['split_count'] as int? ?? 0;
    final perPerson = (meta['per_person'] as num?)?.toDouble() ?? 0;
    final paidBy = meta['paid_by'] as String? ?? 'Someone';
    final category = meta['category'] as String? ?? 'general';

    String categoryEmoji;
    switch (category) {
      case 'food':
        categoryEmoji = '🍽️';
        break;
      case 'transport':
        categoryEmoji = '🚕';
        break;
      case 'accommodation':
        categoryEmoji = '🏨';
        break;
      case 'activity':
        categoryEmoji = '🎯';
        break;
      case 'shopping':
        categoryEmoji = '🛍️';
        break;
      default:
        categoryEmoji = '💰';
    }

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.shade700 : colors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: isMe ? null : Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(categoryEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isMe ? Colors.white : colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white : AppColors.brand,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Paid by $paidBy',
            style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : colors.textSecondary),
          ),
          if (splitCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              'Split $splitCount ways · $currency ${perPerson.toStringAsFixed(2)}/person',
              style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : colors.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // Navigate to Expenses tab (index 9)
              DefaultTabController.of(context).animateTo(9);
            },
            child: Text(
              'View Details →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isMe ? Colors.white : AppColors.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact card for shared documents/files
  Widget _buildDocumentCard(BuildContext context) {
    final colors = context.appColors;
    final meta = message.metadata;
    final fileName = meta['file_name'] as String? ?? 'Unknown file';
    final fileSize = meta['file_size'] as int? ?? 0;
    final fileType = meta['file_type'] as String? ?? '';
    final url = meta['url'] as String? ?? '';

    IconData fileIcon;
    Color iconColor;
    if (fileType.contains('pdf')) {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (fileType.contains('word') || fileType.contains('doc')) {
      fileIcon = Icons.description;
      iconColor = Colors.blue;
    } else if (fileType.contains('sheet') || fileType.contains('excel') || fileType.contains('csv')) {
      fileIcon = Icons.table_chart;
      iconColor = Colors.green;
    } else if (fileType.contains('presentation') || fileType.contains('powerpoint')) {
      fileIcon = Icons.slideshow;
      iconColor = Colors.orange;
    } else if (fileType.contains('image')) {
      fileIcon = Icons.image;
      iconColor = Colors.purple;
    } else if (fileType.contains('zip')) {
      fileIcon = Icons.folder_zip;
      iconColor = Colors.amber;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    String sizeStr;
    if (fileSize < 1024) {
      sizeStr = '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      sizeStr = '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      sizeStr = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return GestureDetector(
      onTap: () async {
        if (url.isNotEmpty) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade700 : colors.surfaceBg,
          borderRadius: BorderRadius.circular(12),
          border: isMe ? null : Border.all(color: colors.border, width: 0.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: iconColor.withOpacity(0.15),
              child: Icon(fileIcon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isMe ? Colors.white : colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sizeStr,
                    style: TextStyle(fontSize: 11, color: isMe ? Colors.white60 : colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.download_rounded, size: 20, color: isMe ? Colors.white70 : AppColors.brand),
          ],
        ),
      ),
    );
  }

  /// Interactive poll card with voting bars
  Widget _buildPollCard(BuildContext context) {
    final colors = context.appColors;
    final meta = message.metadata;
    final question = meta['question'] as String? ?? 'Poll';
    final options = (meta['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final votes = (meta['votes'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final totalVotes = (meta['total_votes'] as int?) ?? 0;
    final isClosed = (meta['is_closed'] as bool?) ?? false;
    final expiresAt = meta['expires_at'] != null ? DateTime.tryParse(meta['expires_at']) : null;
    final pollId = meta['poll_id'] as String?;
    final currentUid = Supabase.instance.client.auth.currentUser?.id;
    final allowMultiple = (meta['allow_multiple'] as bool?) ?? false;

    // Which option ids current user has voted for
    final myVoteOptionIds = votes
        .where((v) => v['user_id'] == currentUid)
        .map((v) => v['option_id'] as String)
        .toSet();
    final hasVoted = myVoteOptionIds.isNotEmpty;
    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt);
    final showResults = hasVoted || isClosed || isExpired;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.shade700 : colors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: isMe ? null : Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll, size: 20, color: isMe ? Colors.white : Colors.indigo),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isMe ? Colors.white : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...options.map<Widget>((opt) {
            final optId = opt['id'] as String? ?? '';
            final optText = opt['text'] as String? ?? '';
            final optVotes = votes.where((v) => v['option_id'] == optId).length;
            final pct = totalVotes > 0 ? optVotes / totalVotes : 0.0;
            final isMyVote = myVoteOptionIds.contains(optId);

            if (showResults) {
              // Show results bar
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isMyVote) Icon(Icons.check_circle, size: 14, color: isMe ? Colors.white : AppColors.brand),
                        if (isMyVote) const SizedBox(width: 4),
                        Expanded(child: Text(optText, style: TextStyle(fontSize: 12, color: isMe ? Colors.white : colors.textPrimary))),
                        Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : colors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: isMe ? Colors.white24 : colors.border,
                        valueColor: AlwaysStoppedAnimation(isMyVote ? AppColors.brand : (isMe ? Colors.white54 : Colors.indigo.shade300)),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Tappable vote option
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () async {
                    if (pollId == null) return;
                    try {
                      await TripService().votePollRelational(pollId: pollId, optionId: optId, allowMultiple: allowMultiple);
                    } catch (_) {}
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isMe ? Colors.white54 : AppColors.brand.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(optText, style: TextStyle(fontSize: 13, color: isMe ? Colors.white : AppColors.brand)),
                  ),
                ),
              );
            }
          }),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$totalVotes vote${totalVotes == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 11, color: isMe ? Colors.white60 : colors.textSecondary),
              ),
              if (expiresAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  isExpired ? '· Ended' : '· Ends ${DateFormat.MMMd().format(expiresAt)}',
                  style: TextStyle(fontSize: 11, color: isMe ? Colors.white60 : colors.textSecondary),
                ),
              ],
              if (allowMultiple) ...[
                const SizedBox(width: 8),
                Text('· Multi', style: TextStyle(fontSize: 11, color: isMe ? Colors.white60 : colors.textSecondary)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              // Navigate to Polls tab (index 6)
              DefaultTabController.of(context).animateTo(6);
            },
            child: Text(
              'View in Polls →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isMe ? Colors.white : AppColors.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds message text with @mentions highlighted in bold.
  /// Tapping a mention navigates to that user's profile.
  Widget _buildRichText(BuildContext context) {
    final colors = context.appColors;
    final baseStyle = TextStyle(
      color: isMe ? Colors.white : colors.textPrimary,
      fontSize: 15,
    );
    final mentionStyle = TextStyle(
      color: isMe ? Colors.white : AppColors.brand,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );

    // Build regex from known member names + @everyone for precise matching
    final names = memberProfiles.values
        .map((p) => p.displayName)
        .where((n) => n != null && n.isNotEmpty)
        .map((n) => RegExp.escape(n!))
        .toList();
    names.add('everyone');
    names.add('wanderwith');
    final namePattern = names.join('|');
    final mentionRegex = RegExp('@($namePattern)', caseSensitive: false);

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in mentionRegex.allMatches(message.content)) {
      // Add text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: message.content.substring(lastEnd, match.start), style: baseStyle));
      }

      final matchedName = match.group(1)?.toLowerCase() ?? '';

      // Find the user ID for this mention
      String? mentionUserId;
      if (matchedName != 'everyone') {
        for (final entry in memberProfiles.entries) {
          if ((entry.value.displayName ?? '').toLowerCase() == matchedName) {
            mentionUserId = entry.key;
            break;
          }
        }
      }

      spans.add(TextSpan(
        text: match.group(0),
        style: mentionStyle,
        recognizer: (mentionUserId != null && onMentionTap != null)
            ? (TapGestureRecognizer()..onTap = () => onMentionTap!(mentionUserId!))
            : null,
      ));
      lastEnd = match.end;
    }

    // Remaining text after last match
    if (lastEnd < message.content.length) {
      spans.add(TextSpan(text: message.content.substring(lastEnd), style: baseStyle));
    }

    if (spans.isEmpty) {
      return Text(message.content, style: baseStyle);
    }

    return RichText(text: TextSpan(children: spans));
  }
}
