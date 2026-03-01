import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // NEW
import 'package:url_launcher/url_launcher.dart';
import '../models/trip.dart';
import '../models/trip_plan.dart'; 
import '../services/gemini_service.dart';
import '../services/trip_service.dart'; // NEW
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

class AIGuideScreen extends StatefulWidget {
  final Trip trip;
  final List<TripDay> plan; // Pass the plan so AI knows the schedule

  const AIGuideScreen({super.key, required this.trip, required this.plan});

  @override
  State<AIGuideScreen> createState() => _AIGuideScreenState();
}

class _AIGuideScreenState extends State<AIGuideScreen> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, String>> _messages = []; // {'role': 'user'|'model', 'text': '...'}
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Initial friendly message
    _messages.add({
      'role': 'model',
      'text': "Hi! I'm your personal guide for ${widget.trip.location}. I know your itinerary and budget. Ask me anything!"
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Prepare context
    String planJson = jsonEncode(widget.plan.map((d) => {
      'day': d.dayNumber,
      'places': d.places.map((p) => p.name).toList()
    }).toList());

    try {
      final response = await _geminiService.getChatResponse(
        userMessage: text,
        trip: widget.trip,
        history: _messages.sublist(0, _messages.length - 1), // Exclude just added user msg to avoid duping provided handling
        planContext: planJson,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'model', 'text': response});
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'model', 'text': "I lost connection. Please try again."});
          _isTyping = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- ACTIONS ---

  void _shareToChat(String text) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    try {
      final profile = await Supabase.instance.client.from('profiles').select('display_name').eq('id', user.id).maybeSingle();
      final name = profile?['display_name'] ?? 'User';

      // Clean up markdown bold markers for cleaner plain text chat
      String cleanText = text.replaceAll('**', '');

      await Supabase.instance.client.from('messages').insert({
        'trip_id': widget.trip.id,
        'sender_id': user.id,
        'sender_name': name,
        'text': "🤖 AI Recommendation:\n$cleanText", 
        'message_type': 'text',
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shared to group chat!")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to share: $e")));
    }
  }

  Future<void> _saveLinkFromText(String text) async {
    // Regex for URLs
    final urlRegExp = RegExp(r"(https?:\/\/[^\s\)]+)");
    final matches = urlRegExp.allMatches(text);
    
    if (matches.isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No links found in this message.")));
      return;
    }

    String? selectedUrl;
    
    if (matches.length == 1) {
      selectedUrl = matches.first.group(0);
    } else {
      // Pick one
      selectedUrl = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text("Select Link to Save"),
          children: matches.map((m) {
             final url = m.group(0)!;
             return SimpleDialogOption(
               onPressed: () => Navigator.pop(ctx, url),
               child: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
             );
          }).toList(),
        )
      );
    }

    if (selectedUrl != null && mounted) {
       _showAddLinkDialog(selectedUrl);
    }
  }

  void _showAddLinkDialog(String url) {
     final cTitle = TextEditingController(text: "Hotel / Place Info");
     final cUrl = TextEditingController(text: url);
     
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text("Save to Links Tab"),
         content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               TextField(controller: cTitle, decoration: const InputDecoration(labelText: "Description / Title")),
               const SizedBox(height: 8),
               TextField(controller: cUrl, decoration: const InputDecoration(labelText: "URL")),
            ],
         ),
         actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                 if (cTitle.text.isNotEmpty) {
                    try {
                        final uid = Supabase.instance.client.auth.currentUser!.id;
                        await TripService().addTripLink(widget.trip.id, cTitle.text.trim(), cUrl.text.trim(), uid);
                        Navigator.pop(ctx);
                        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link Saved!")));
                    } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                 }
              }, 
              child: const Text("Save")
            )
         ],
       )
     );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purpleAccent),
            SizedBox(width: 8),
            Text("AI Travel Guide"),
          ],
        ),
        backgroundColor: colors.scaffoldBg,
        foregroundColor: colors.textPrimary,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 1. Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.brand : colors.surfaceBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUser) 
                           Text(msg['text']!, style: const TextStyle(color: Colors.white))
                        else 
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               MarkdownBody(
                                data: msg['text']!,
                                onTapLink: (text, href, title) {
                                   if(href != null) launchUrl(Uri.parse(href));
                                },
                                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                  p: const TextStyle(fontSize: 15),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _shareToChat(msg['text']!),
                                    icon: const Icon(Icons.share, size: 16),
                                    label: const Text("Share to Chat", style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _saveLinkFromText(msg['text']!),
                                    icon: const Icon(Icons.link, size: 16),
                                    label: const Text("Save Link", style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  ),
                                ],
                              )
                             ],
                           ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Typing Indicator
          if (_isTyping)
             Padding(
               padding: const EdgeInsets.only(left: 16, bottom: 8),
               child: Align(
                 alignment: Alignment.centerLeft,
                 child: Text("Thinking...", style: TextStyle(color: colors.textSecondary, fontStyle: FontStyle.italic)),
               ),
             ),

          // 3. Quick Suggestions
          if (!_isTyping && _messages.length < 3)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _SuggestionChip(
                    label: "Budget food nearby?", 
                    onTap: () => _sendMessage("What are some good budget food options near my current itinerary locations?"),
                  ),
                  _SuggestionChip(
                    label: "Taxi cost to Airport?", 
                    onTap: () => _sendMessage("Estimate the taxi fare from the city center to the nearest airport."),
                  ),
                  _SuggestionChip(
                    label: "Must-visit hidden gems", 
                    onTap: () => _sendMessage("What are some hidden gems in this city that aren't on my plan?"),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),

          // 4. Input Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.cardBg,
              boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 5, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: "Ask about food, prices, or directions...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: colors.fieldFillBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.brand,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: Colors.purple.shade50,
        labelStyle: TextStyle(color: Colors.purple.shade700),
      ),
    );
  }
}
