# WanderWith Chat System — Comprehensive Implementation Plan

## Current State Analysis

### What Already Exists (trip_chat_tab.dart ~1275 lines)

| Feature | Status | Quality |
|---------|--------|---------|
| Text messaging | ✅ Done | Good — with Supabase `.stream()` realtime |
| Image sharing | ✅ Done | Good — compressed upload to Supabase storage |
| Location sharing | ⚠️ Partial | Hardcoded coordinates, no real GPS |
| Reactions (6 emojis) | ✅ Done | Good — optimistic updates + DB sync |
| Reply to message | ✅ Done | Good — metadata.reply_to with preview |
| Edit message | ✅ Done | Good — inline editing with "edited" badge |
| Delete for me | ✅ Done | Good — deleted_for array in DB |
| Delete for everyone | ✅ Done | Good — full DB delete |
| Pin messages | ✅ Done | Good — pinned bar at top |
| AI Bot (@wanderwith) | ✅ Done | Basic — single turn, no context |
| Typing indicator | ✅ Done | Good — broadcast channel |
| Member profiles | ✅ Done | Good — cached in _memberProfiles |
| Agency badge | ✅ Done | Good — verified icon for agencies |
| Moderation | ✅ Done | Basic — toxicity filter + reporting |
| Skeleton loading | ✅ Done | Good |
| Optimistic messages | ✅ Done | Just added — instant sender feedback |

### Database Schema (Current)

```sql
-- trip_messages
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
trip_id UUID REFERENCES trips(id),
sender_id UUID REFERENCES auth.users(id),
sender_name TEXT,
content TEXT,
type TEXT DEFAULT 'text', -- text, image, location, link, system
metadata JSONB DEFAULT '{}',
is_pinned BOOLEAN DEFAULT false,
deleted_for UUID[] DEFAULT '{}',
is_edited BOOLEAN DEFAULT false,
updated_at TIMESTAMPTZ DEFAULT now(),
created_at TIMESTAMPTZ DEFAULT now()

-- message_reactions
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
message_id UUID REFERENCES trip_messages(id) ON DELETE CASCADE,
trip_id UUID,
user_id UUID REFERENCES auth.users(id),
reaction TEXT,
created_at TIMESTAMPTZ DEFAULT now()
UNIQUE(message_id, user_id, reaction)

-- trip_chat_moderation_logs
id, trip_id, user_id, action, reason, raw_content, created_at
```

### Current Realtime Architecture
- **Messages**: `Supabase.stream(primaryKey: ['id']).eq('trip_id', ...)` — Postgres Changes
- **Reactions**: Same `.stream()` approach
- **Typing**: `Supabase.channel('trip_chat:$tripId')` — Broadcast channel
- **Optimistic Updates**: Reactions (toggle before DB confirm), Messages (show before insert confirms)

---

## Implementation Roadmap

### Phase 1: Message Status & Read Receipts
**Priority: HIGH | Effort: Medium | Impact: HIGH**

The most impactful missing feature. Users need to know if their messages were sent, delivered, and read.

#### 1.1 Database Changes
```sql
-- Add status tracking to trip_messages
ALTER TABLE trip_messages ADD COLUMN status TEXT DEFAULT 'sent'; -- sent, delivered, read

-- Read receipts table (who read what, and when)
CREATE TABLE IF NOT EXISTS message_read_receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_read_message_id UUID REFERENCES trip_messages(id) ON DELETE SET NULL,
  last_read_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(trip_id, user_id)
);

-- Index for fast lookups
CREATE INDEX idx_read_receipts_trip ON message_read_receipts(trip_id);
CREATE INDEX idx_read_receipts_user ON message_read_receipts(trip_id, user_id);

-- RLS
ALTER TABLE message_read_receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members can read receipts" ON message_read_receipts
  FOR SELECT USING (
    trip_id IN (SELECT id FROM trips WHERE auth.uid() = ANY(member_ids))
  );
CREATE POLICY "Users can update own receipts" ON message_read_receipts
  FOR ALL USING (user_id = auth.uid());
```

#### 1.2 Flutter Implementation

**New file: `lib/services/chat_service.dart`**
```dart
class ChatService {
  final _supabase = Supabase.instance.client;
  
  /// Mark messages as read up to a specific message ID
  Future<void> markAsRead(String tripId, String messageId) async {
    await _supabase.from('message_read_receipts').upsert({
      'trip_id': tripId,
      'user_id': _supabase.auth.currentUser!.id,
      'last_read_message_id': messageId,
      'last_read_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Get read receipt status for a specific message
  /// Returns count of members who've read past this message
  Stream<List<Map<String, dynamic>>> readReceiptsStream(String tripId) {
    return _supabase
        .from('message_read_receipts')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId);
  }
}
```

**UI Changes in `_MessageBubble`:**
- Add tick marks after timestamp: `✓` (sent), `✓✓` (delivered to all), `✓✓` blue (read by all)
- For group chats: show "Read by X of Y" on long press
- Sender's messages show status; others' messages don't

**Logic:**
1. When chat tab is visible and new messages arrive → call `markAsRead(tripId, latestMessageId)`
2. Stream `message_read_receipts` alongside messages
3. A message is "read" when all other members' `last_read_message_id` timestamp >= message's `created_at`
4. Use broadcast channel for instant "read" notifications (supplement DB stream)

#### 1.3 Files to Modify
- `lib/services/chat_service.dart` — NEW
- `lib/widgets/trip_chat_tab.dart` — Add read receipt stream, tick marks in bubble
- `lib/models/chat_message.dart` — Add `status` field
- `sql/chat_read_receipts.sql` — NEW

---

### Phase 2: Date Separators & Improved Message Grouping
**Priority: HIGH | Effort: Low | Impact: Medium**

Visual improvement that makes chat feel professional.

#### 2.1 Implementation

No database changes needed — purely UI.

**In `build()` method of `_TripChatTabState`:**
```dart
// After filtering messages, before ListView.builder
// Group messages by date for separator insertion

Widget _buildDateSeparator(DateTime date) {
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  String label;
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    label = 'Today';
  } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
    label = 'Yesterday';
  } else {
    label = DateFormat('MMMM d, yyyy').format(date);
  }
  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w500)),
    ),
  );
}
```

**Logic in ListView.builder:**
- Since messages are `reverse: true`, check if current message's date differs from next message's date
- Insert a separator widget between date boundaries
- Use an indexed approach: convert message list to a mixed `List<dynamic>` of `ChatMessage` and `DateSeparator` objects

#### 2.2 Message Grouping (Same sender, close timestamps)
- If same sender sends multiple messages within 2 minutes, hide the sender name on subsequent messages
- Reduce vertical padding between grouped messages (4px → 1px)
- Only show timestamp on the last message in a group

#### 2.3 Files to Modify
- `lib/widgets/trip_chat_tab.dart` — Date separator logic + message grouping

---

### Phase 3: @Mentions System
**Priority: HIGH | Effort: Medium | Impact: HIGH**

Essential for group trip chat to direct messages at specific people.

#### 3.1 Database Changes
```sql
-- Track mentioned users for notification targeting
ALTER TABLE trip_messages ADD COLUMN mentioned_user_ids UUID[] DEFAULT '{}';

-- Index for efficient mention queries
CREATE INDEX idx_messages_mentions ON trip_messages USING GIN(mentioned_user_ids);
```

#### 3.2 Flutter Implementation

**Mention Detection in Input:**
```dart
// In _buildInputBar: detect '@' character and show member overlay
// Use a TextField with custom overlay

class MentionOverlay {
  // When user types '@', show a popup list of trip members
  // Filter as they type: @te → shows "Tejas"
  // On select: insert @DisplayName and store user_id in metadata
}
```

**Mention Rendering in Bubble:**
```dart
// Parse message content for @mentions
// Render mentions in bold blue/brand color
// Example: "Hey @Tejas check this out" → "Hey **@Tejas** check this out"
```

**Notification Integration:**
- When a message contains mentions, `mentioned_user_ids` is populated
- Push notifications check this array to send targeted @mention alerts
- Mentioned messages have a subtle highlight in the chat

#### 3.3 Input UX Flow
1. User types `@` in the text field
2. An overlay appears above the input bar showing filtered member list
3. User taps a member name → `@DisplayName ` is inserted into the text
4. On send: parse all `@mentions` from content, resolve to user IDs, populate `mentioned_user_ids`

#### 3.4 Files to Modify
- `lib/widgets/trip_chat_tab.dart` — Mention overlay, parsing, rendering
- `lib/models/chat_message.dart` — Add `mentionedUserIds` field
- `sql/chat_mentions.sql` — NEW

---

### Phase 4: Context Messages (System Events)
**Priority: MEDIUM | Effort: Medium | Impact: Medium**

Show trip activity as system messages in chat.

#### 4.1 System Message Types
```dart
enum SystemEventType {
  memberJoined,      // "Tejas joined the trip"
  memberLeft,        // "Alex left the trip"
  memberRemoved,     // "Admin removed Alex"
  planCreated,       // "Tejas created Day 1 plan"
  planUpdated,       // "New place added: Taj Mahal"
  pollCreated,       // "Tejas created a poll: Where to eat?"
  pollEnded,         // "Poll ended: Cafe won with 3 votes"
  expenseAdded,      // "Tejas added expense: ₹500 for Dinner"
  tripDateChanged,   // "Trip dates updated: Jan 5-10"
  photoShared,       // "Tejas shared 5 photos to gallery"
  checklistComplete, // "All checklist items completed! 🎉"
}
```

#### 4.2 Implementation

**System message insertion** — place trigger calls in relevant services:
```dart
// In TripService, when a member joins:
await _supabase.from('trip_messages').insert({
  'trip_id': tripId,
  'sender_id': null,
  'sender_name': 'System',
  'content': '${userName} joined the trip 🎉',
  'type': 'system',
  'metadata': {'event': 'member_joined', 'user_id': userId},
});
```

**Rendering system messages:**
- Centered in chat, no bubble
- Subtle background, small font
- Icon based on event type
- Tappable for context (e.g., tap "New place added" → opens plan)

#### 4.3 Places to Insert System Messages
- `lib/services/trip_service.dart` — Member join/leave/remove, trip updates
- `lib/services/expense_service.dart` — Expense additions
- `lib/widgets/trip_plan_tab.dart` — Plan creation/updates
- `lib/services/checklist_service.dart` — Checklist completion

#### 4.4 Files to Create/Modify
- `lib/services/chat_event_service.dart` — NEW (centralized system message posting)
- Multiple service files — Add event triggers

---

### Phase 5: Share Plan Items in Chat
**Priority: MEDIUM | Effort: Medium | Impact: HIGH**

Allow sharing itinerary places, polls, and expenses directly in chat as rich cards.

#### 5.1 New Message Types
```dart
// Extend ChatMessageType enum
enum ChatMessageType {
  text,
  image,
  location,
  link,
  system,
  planItem,    // NEW — shared itinerary place
  poll,        // NEW — inline poll
  expense,     // NEW — expense summary card
  document,    // NEW — PDF/file attachment
}
```

#### 5.2 Plan Item Card
```dart
// metadata structure for planItem type:
{
  "plan_item_id": "uuid",
  "place_name": "Taj Mahal",
  "place_image": "https://...",
  "day_number": 1,
  "time_slot": "09:00 AM",
  "category": "sightseeing"
}
```

**Rendering:** A compact card with place image, name, day/time, and "View in Plan →" button.

#### 5.3 Expense Summary Card
```dart
// metadata for expense type:
{
  "expense_id": "uuid",
  "title": "Dinner at Bukhara",
  "amount": 2500,
  "currency": "INR",
  "split_count": 4,
  "per_person": 625,
  "paid_by": "Tejas"
}
```

**Rendering:** Compact expense card with amount, split info, and "View Details" button.

#### 5.4 Attachment Menu Update
```dart
// Update _showAttachmentMenu to add new options:
void _showAttachmentMenu(String uid, String name) {
  // Existing: 📷 Gallery, 📸 Camera, 📍 Location
  // New:      📋 Share Plan Item, 💰 Share Expense, 📄 Document
}
```

#### 5.5 Files to Modify
- `lib/models/chat_message.dart` — New enum values
- `lib/widgets/trip_chat_tab.dart` — New card renderers, attachment menu
- `lib/screens/trip_dashboard_screen.dart` — "Share to chat" buttons on plan items

---

### Phase 6: Live Location Sharing
**Priority: MEDIUM | Effort: High | Impact: HIGH**

Real-time location sharing for safety and meetup coordination.

#### 6.1 Database Changes
```sql
-- Live location shares (temporary, auto-expire)
CREATE TABLE IF NOT EXISTS live_location_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  accuracy DOUBLE PRECISION,
  heading DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  expires_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index and auto-cleanup
CREATE INDEX idx_live_location_trip ON live_location_shares(trip_id);
CREATE INDEX idx_live_location_expires ON live_location_shares(expires_at);

-- RLS
ALTER TABLE live_location_shares ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members can view trip locations" ON live_location_shares
  FOR SELECT USING (
    trip_id IN (SELECT id FROM trips WHERE auth.uid() = ANY(member_ids))
  );
CREATE POLICY "Users update own location" ON live_location_shares
  FOR ALL USING (user_id = auth.uid());
```

#### 6.2 Flutter Implementation

**Location Sharing Flow:**
1. User taps 📍 in chat → option: "Share Current Location" or "Share Live Location"
2. Share Current Location: one-time GPS fix → insert as `location` type message with real coords
3. Share Live Location: 
   - Duration picker: 15 min / 1 hr / 8 hrs
   - Start a background service that updates `live_location_shares` every 10 seconds
   - Insert a `system` message: "Tejas is sharing live location for 1 hour"
   - Other members see a map widget at top of chat showing active sharers
   - On tap: opens full-screen map with all active live locations

**Fix Current Location Sharing (Bug):**
```dart
// Replace hardcoded coordinates with real GPS
void _shareLocation(String uid, String name) async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    // Reverse geocode for address
    final placemarks = await placemarkFromCoordinates(
      position.latitude, position.longitude,
    );
    final address = placemarks.isNotEmpty 
        ? '${placemarks.first.street}, ${placemarks.first.locality}'
        : 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
    
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
  } catch (e) {
    // Handle permission denied, location unavailable, etc.
  }
}
```

#### 6.3 Live Location Map Widget
- Floating overlay at top of chat when live sharing is active
- Shows small map preview with markers for each sharer
- Tap to expand to full-screen Google Maps view
- Auto-removes when share expires

#### 6.4 Dependencies
- `geolocator` (already in project)
- `geocoding` (already in project)
- `google_maps_flutter` (already in project)

#### 6.5 Files to Create/Modify
- `lib/widgets/live_location_map.dart` — NEW
- `lib/services/location_share_service.dart` — NEW
- `lib/widgets/trip_chat_tab.dart` — Fix `_shareLocation`, add live location UI
- `sql/live_location.sql` — NEW

---

### Phase 7: Polls in Chat
**Priority: MEDIUM | Effort: Medium | Impact: Medium**

Quick group decisions directly in chat.

#### 7.1 Database (Already Exists)
The polls table was already created in a previous phase. We need to integrate poll creation and voting into the chat.

#### 7.2 Implementation

**Poll Creation Flow:**
1. User taps 📋 → "Create Poll" from attachment menu
2. Bottom sheet with:
   - Question field
   - 2-6 option fields (add more button)
   - "Allow multiple selections" toggle
   - "Anonymous voting" toggle
   - Expiry picker (optional)
3. On create: Insert poll into `trip_polls` table + send chat message of type `poll`

**Poll Chat Card:**
```dart
// metadata for poll type:
{
  "poll_id": "uuid",
  "question": "Where should we eat tonight?",
  "options": ["Pizza Place", "Sushi Bar", "Indian Restaurant"],
  "votes": {"Pizza Place": 2, "Sushi Bar": 1},
  "total_votes": 3,
  "is_closed": false,
  "expires_at": "2024-01-15T20:00:00Z"
}
```

**Poll Card Widget:**
- Question in bold
- Options as tappable bars with vote count
- Progress bars showing vote distribution
- "X votes" total counter
- Anonymous mode: only shows counts, not who voted

#### 7.3 Files to Create/Modify
- `lib/widgets/poll_chat_card.dart` — NEW
- `lib/widgets/trip_chat_tab.dart` — Poll creation bottom sheet, poll rendering
- `lib/services/poll_service.dart` — Existing, add chat integration

---

### Phase 8: Document & File Sharing
**Priority: LOW | Effort: Medium | Impact: Medium**

Share travel documents (boarding passes, hotel bookings, PDFs) in chat.

#### 8.1 Implementation

**File Upload Flow:**
1. User taps 📄 from attachment menu
2. File picker opens (PDF, DOC, images, etc.)
3. File is uploaded to Supabase Storage `trip_documents/{tripId}/`
4. Chat message inserted with type `document`

**metadata structure:**
```json
{
  "url": "https://storage.supabase.co/...",
  "file_name": "boarding_pass.pdf",
  "file_size": 245000,
  "file_type": "application/pdf",
  "thumbnail_url": null
}
```

**Document Card Widget:**
- File icon based on type (PDF icon, DOC icon, etc.)
- File name + size
- Download button
- For images: inline preview (existing)
- For PDFs: icon + name + "Open" button

#### 8.2 Dependencies
- `file_picker` package (NEW)
- `open_file` or `url_launcher` for opening downloaded files

#### 8.3 Files to Create/Modify
- `lib/widgets/document_message_card.dart` — NEW
- `lib/widgets/trip_chat_tab.dart` — File picker integration, document rendering
- `pubspec.yaml` — Add `file_picker` dependency

---

### Phase 9: Enhanced AI Assistant
**Priority: MEDIUM | Effort: Medium | Impact: HIGH**

Transform the basic @wanderwith bot into a contextual trip AI assistant.

#### 9.1 Current vs Improved

| Feature | Current | Improved |
|---------|---------|----------|
| Trigger | `@wanderwith` keyword | `@wanderwith` + dedicated AI button |
| Context | Single-turn, no history | Multi-turn with trip context injection |
| Capabilities | Generic response | Trip-aware suggestions, weather, budget tips |
| Formatting | Plain text | Markdown with cards, clickable suggestions |
| Suggestions | None | Quick action chips (weather, budget, restaurants) |

#### 9.2 Implementation

**Context-Aware Prompt:**
```dart
String _buildAIContext() {
  final trip = widget.trip;
  return '''
You are WanderWith AI, an expert travel assistant for the trip "${trip.name}" 
to ${trip.location}.
Trip dates: ${trip.startDate} to ${trip.endDate}.
Members: ${trip.memberIds.length} people.
Budget: ${trip.budgetCurrency}${trip.estimatedCost}.

Provide helpful, concise travel advice. You can:
- Suggest restaurants, activities, attractions
- Give weather forecasts and packing tips
- Help with budget planning
- Provide local cultural tips
- Suggest itinerary optimizations

Recent chat context:
${_getRecentMessages(5)}
''';
}
```

**Quick Suggestion Chips:**
After AI response, show tappable chips:
- "🌤 Weather forecast"
- "🍽 Restaurant suggestions"  
- "💰 Budget breakdown"
- "🗺 Today's itinerary"

**AI Response Formatting:**
- Parse markdown in AI responses (bold, lists, links)
- Render structured cards for specific queries (restaurant list, weather forecast)

#### 9.3 Multi-Turn Conversation
- Store last 10 messages as context in memory
- When `@wanderwith` is triggered, include recent chat history in the prompt
- AI can reference previous conversations

#### 9.4 Files to Modify
- `lib/services/gemini_service.dart` — Enhanced `getChatResponse` with trip context + history
- `lib/widgets/trip_chat_tab.dart` — AI button, suggestion chips, markdown rendering

---

### Phase 10: Swipe to Reply & UI Polish
**Priority: HIGH | Effort: Low | Impact: Medium**

Critical UX improvement — currently reply requires long press → menu → Reply.

#### 10.1 Swipe to Reply
```dart
// Wrap _MessageBubble in Dismissible or custom GestureDetector
Dismissible(
  direction: isMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
  confirmDismiss: (_) async {
    _startReplying(message);
    return false; // Don't actually dismiss
  },
  background: Container(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Icon(Icons.reply, color: colors.textMuted),
  ),
  child: _MessageBubble(...),
)
```

#### 10.2 Additional UI Polish
- **Scroll-to-bottom FAB**: Floating button when scrolled up, with unread count badge
- **Message grouping**: Same sender within 2 min → condensed bubbles
- **Link preview**: Auto-detect URLs and show OG preview card
- **New messages divider**: "── X new messages ──" separator when returning to chat
- **Smooth animations**: AnimatedList transitions for new messages
- **Photo gallery viewer**: Swipeable photo viewer when tapping images
- **Voice message support**: Record and send voice notes (future consideration)

#### 10.3 Scroll-to-Bottom FAB Implementation
```dart
// Track scroll position
bool _showScrollToBottom = false;
int _unreadCount = 0;

void _onScroll() {
  if (_scrollController.offset > 200 && !_showScrollToBottom) {
    setState(() => _showScrollToBottom = true);
  } else if (_scrollController.offset <= 200 && _showScrollToBottom) {
    setState(() => _showScrollToBottom = false);
  }
}
```

#### 10.4 Files to Modify
- `lib/widgets/trip_chat_tab.dart` — Swipe gesture, FAB, message grouping

---

### Phase 11: Media Gallery & Files Section
**Priority: LOW | Effort: Medium | Impact: Medium**

Dedicated section to browse all media shared in chat.

#### 11.1 Implementation

**Chat Info Screen:**
Accessible from the ℹ️ icon in the chat header.

```dart
class ChatMediaGallery extends StatelessWidget {
  // Tabs: Photos | Documents | Links
  // Photos: Grid of all shared images
  // Documents: List of all shared files
  // Links: List of all shared URLs
}
```

**Query:**
```dart
// Fetch all media messages
final photos = await supabase
    .from('trip_messages')
    .select()
    .eq('trip_id', tripId)
    .eq('type', 'image')
    .order('created_at', ascending: false);
```

#### 11.2 Files to Create
- `lib/screens/chat_media_gallery.dart` — NEW

---

### Phase 12: Smart Notifications
**Priority: HIGH | Effort: Medium | Impact: HIGH**

Targeted push notifications for chat events.

#### 12.1 Notification Categories
```dart
enum ChatNotificationType {
  newMessage,        // Regular message from member
  mention,           // @mentioned in chat
  reactionToYou,     // Someone reacted to your message
  pollCreated,       // New poll to vote on
  pollExpiring,      // Poll closing soon
  aiResponse,        // AI assistant responded
  liveLocation,      // Someone started sharing location
  systemEvent,       // Trip update via chat
}
```

#### 12.2 Notification Priority
| Event | Priority | Sound | Badge |
|-------|----------|-------|-------|
| @Mention | HIGH | Custom | Yes |
| Direct reply to you | HIGH | Default | Yes |
| New message | NORMAL | Default | Yes |
| Reaction to you | LOW | Silent | Badge only |
| System event | LOW | Silent | No |

#### 12.3 Implementation
- Use Supabase Edge Functions to trigger push notifications
- Check notification preferences per user
- Batch notifications for multiple messages from same sender within 1 min
- Deep link to specific message on tap

#### 12.4 Supabase Edge Function
```typescript
// supabase/functions/chat-notification/index.ts
Deno.serve(async (req) => {
  const { trip_id, sender_id, sender_name, content, type, mentioned_user_ids } = await req.json();
  
  // Get trip members (excluding sender)
  // For each member:
  //   - Check if they have push token
  //   - Check their notification preferences
  //   - Check if they're currently viewing the chat (skip if so)
  //   - Send FCM notification with deep link
});
```

#### 12.5 Files to Create/Modify
- `supabase/functions/chat-notification/index.ts` — NEW
- `lib/services/notification_service.dart` — Chat notification handling
- `lib/widgets/trip_chat_tab.dart` — Report "active viewing" to suppress notifications

---

### Phase 13: Online Presence & Status
**Priority: LOW | Effort: Low | Impact: Medium**

Show who's currently online/active in the trip chat.

#### 13.1 Implementation

**Using Supabase Presence (built into Realtime Channels):**
```dart
// Already have: _chatChannel = Supabase.instance.client.channel('trip_chat:$tripId')
// Add presence tracking:

_chatChannel.onPresenceSync((payload) {
  final presenceState = _chatChannel.presenceState();
  setState(() {
    _onlineUserIds = presenceState.keys
        .map((key) => presenceState[key]!.first.payload['user_id'] as String)
        .toSet();
  });
}).onPresenceJoin((payload) {
  // User came online
}).onPresenceLeave((payload) {
  // User went offline
}).subscribe((status, [error]) async {
  if (status == RealtimeSubscribeStatus.subscribed) {
    await _chatChannel.track({
      'user_id': currentUserId,
      'online_at': DateTime.now().toIso8601String(),
    });
  }
});
```

**UI:**
- Green dot on member avatars in chat header
- "X members online" text updated in real-time
- Last seen timestamp for offline members

#### 13.2 Files to Modify
- `lib/widgets/trip_chat_tab.dart` — Presence tracking, online indicators

---

### Phase 14: Offline Queue & Performance
**Priority: MEDIUM | Effort: High | Impact: HIGH**

Handle poor connectivity gracefully.

#### 14.1 Offline Message Queue

**Using Isar (already in project) for local caching:**
```dart
@collection
class PendingMessage {
  Id id = Isar.autoIncrement;
  String tripId;
  String content;
  String type;
  String metadataJson;
  DateTime createdAt;
  bool isSending;
}
```

**Flow:**
1. User sends message → save to Isar queue immediately
2. Show message with "⏳ Sending..." indicator
3. Try to send to Supabase
4. If fails (no network): keep in queue, retry periodically
5. On network restore: flush queue in order
6. Remove from Isar once confirmed by server

#### 14.2 Message Cache
```dart
// Cache last 100 messages per trip in Isar
// On chat open: show cached messages immediately
// Then stream updates from Supabase
// Merge cached + live data
```

#### 14.3 Performance Optimizations
- **Lazy loading**: Only render visible messages + 20 buffer
- **Image thumbnails**: Generate 200px thumbnails for chat images
- **Reaction batching**: Debounce rapid reaction toggles (300ms)
- **Stream optimization**: Use a single combined stream instead of nested StreamBuilders
- **Memory management**: Dispose image caches when scrolling far from them
- **Pagination**: Load 50 messages initially, load more on scroll up

#### 14.4 Combined Stream Approach
```dart
// Replace nested StreamBuilders with a CombineLatestStream
final combinedStream = CombineLatestStream.combine2(
  _messagesStream,
  _reactionsStream,
  (List<Map<String, dynamic>> messages, List<Map<String, dynamic>> reactions) {
    // Merge reactions into messages
    return messages.map((m) {
      final msgReactions = reactions.where((r) => r['message_id'] == m['id']).toList();
      return {...m, '_reactions': msgReactions};
    }).toList();
  },
);
```

#### 14.5 Dependencies
- `rxdart` (for CombineLatestStream) — already in project or add
- `connectivity_plus` (already in project) — for network state
- `isar` (already in project) — for local cache

#### 14.6 Files to Create/Modify
- `lib/services/offline_queue_service.dart` — NEW
- `lib/models/isar/pending_message.dart` — NEW
- `lib/widgets/trip_chat_tab.dart` — Offline indicators, combined stream

---

## Implementation Priority Matrix

```
Impact ↑
  HIGH │  P1(ReadReceipts)  P3(Mentions)  P12(Notifications)  P6(LiveLocation)
       │  P10(SwipeReply)   P5(ShareItems) P9(AI)              
       │                    P14(Offline)
  MED  │  P2(DateSep)       P4(Context)    P7(Polls)           P13(Presence)
       │                    P11(Gallery)   P8(Documents)
  LOW  │
       └──────────────────────────────────────────────────────→ Effort
         LOW                MEDIUM                HIGH
```

## Recommended Implementation Order

### Sprint 1 (Week 1-2): Essential UX
1. **Phase 2**: Date separators & message grouping (LOW effort, quick win)
2. **Phase 10**: Swipe to reply & scroll-to-bottom FAB (LOW effort, HIGH impact)
3. **Phase 6.2**: Fix location sharing (use real GPS instead of hardcoded)

### Sprint 2 (Week 2-3): Communication Basics
4. **Phase 1**: Read receipts & message status (the most requested feature)
5. **Phase 3**: @Mentions system (essential for group coordination)

### Sprint 3 (Week 3-4): Rich Content
6. **Phase 5**: Share plan items, expenses in chat (unique to travel app)
7. **Phase 4**: System/context messages (trip activity awareness)

### Sprint 4 (Week 4-5): Collaboration Tools
8. **Phase 7**: Polls in chat
9. **Phase 9**: Enhanced AI assistant with trip context

### Sprint 5 (Week 5-6): Platform Features
10. **Phase 12**: Smart notifications (FCM + Edge Functions)
11. **Phase 13**: Online presence
12. **Phase 8**: Document sharing

### Sprint 6 (Week 6-8): Performance & Polish
13. **Phase 14**: Offline queue & message caching
14. **Phase 11**: Media gallery & files section

---

## SQL Migration File

All database changes should be consolidated into a single migration file:

**File: `sql/chat_upgrade.sql`**
```sql
-- Phase 1: Read Receipts
ALTER TABLE trip_messages ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'sent';

CREATE TABLE IF NOT EXISTS message_read_receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_read_message_id UUID REFERENCES trip_messages(id) ON DELETE SET NULL,
  last_read_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(trip_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_read_receipts_trip ON message_read_receipts(trip_id);
ALTER TABLE message_read_receipts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "rr_read" ON message_read_receipts FOR SELECT USING (
  trip_id IN (SELECT id FROM trips WHERE auth.uid() = ANY(member_ids))
);
CREATE POLICY "rr_write" ON message_read_receipts FOR ALL USING (user_id = auth.uid());

-- Phase 3: Mentions
ALTER TABLE trip_messages ADD COLUMN IF NOT EXISTS mentioned_user_ids UUID[] DEFAULT '{}';
CREATE INDEX IF NOT EXISTS idx_messages_mentions ON trip_messages USING GIN(mentioned_user_ids);

-- Phase 6: Live Location
CREATE TABLE IF NOT EXISTS live_location_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  accuracy DOUBLE PRECISION,
  heading DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  expires_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_live_location_trip ON live_location_shares(trip_id);
ALTER TABLE live_location_shares ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ll_read" ON live_location_shares FOR SELECT USING (
  trip_id IN (SELECT id FROM trips WHERE auth.uid() = ANY(member_ids))
);
CREATE POLICY "ll_write" ON live_location_shares FOR ALL USING (user_id = auth.uid());
```

---

## New Files Summary

| File | Phase | Description |
|------|-------|-------------|
| `lib/services/chat_service.dart` | 1 | Read receipts, message status management |
| `sql/chat_upgrade.sql` | 1,3,6 | All DB migrations consolidated |
| `lib/services/chat_event_service.dart` | 4 | Centralized system message posting |
| `lib/widgets/poll_chat_card.dart` | 7 | Poll card widget for inline voting |
| `lib/widgets/document_message_card.dart` | 8 | Document/file message card |
| `lib/widgets/live_location_map.dart` | 6 | Live location map overlay |
| `lib/services/location_share_service.dart` | 6 | Live location sharing service |
| `lib/screens/chat_media_gallery.dart` | 11 | Media/files/links gallery screen |
| `lib/services/offline_queue_service.dart` | 14 | Offline message queue with Isar |
| `lib/models/isar/pending_message.dart` | 14 | Isar model for pending messages |
| `supabase/functions/chat-notification/index.ts` | 12 | Edge function for push notifications |

---

## Modified Files Summary

| File | Phases | Changes |
|------|--------|---------|
| `lib/widgets/trip_chat_tab.dart` | ALL | Major refactor across all phases |
| `lib/models/chat_message.dart` | 1,3,5 | New fields: status, mentionedUserIds, new types |
| `lib/services/gemini_service.dart` | 9 | Enhanced getChatResponse with context |
| `lib/services/trip_service.dart` | 4 | System event triggers |
| `lib/services/expense_service.dart` | 4 | System event triggers |
| `pubspec.yaml` | 8,14 | New dependencies: file_picker, rxdart |

---

## Technical Constraints & Notes

1. **Flutter SDK**: 3.13.9 / Dart 3.1.5 — must use `MaterialStateProperty` (not WidgetStateProperty), `.withOpacity()` (not .withValues)
2. **fl_chart**: Max 0.64.x (0.65+ requires Flutter 3.16+)
3. **Supabase Realtime**: Use `.stream()` for persistent data, `broadcast` for ephemeral events (typing, presence)
4. **UserProfile.country**: String field (e.g., "India", "United States") — need country code mapping for comparisons
5. **Image compression**: Already handled via `flutter_image_compress` — maintain for documents too
6. **Chat tab is kept alive** via `AutomaticKeepAliveClientMixin` — good for maintaining stream connections

---

## Estimated Total Effort

| Sprint | Duration | Phases | Complexity |
|--------|----------|--------|------------|
| Sprint 1 | 1-2 weeks | 2, 10, 6.2 | Easy |
| Sprint 2 | 1-2 weeks | 1, 3 | Medium |
| Sprint 3 | 1-2 weeks | 5, 4 | Medium |
| Sprint 4 | 1-2 weeks | 7, 9 | Medium |
| Sprint 5 | 1-2 weeks | 12, 13, 8 | Medium-Hard |
| Sprint 6 | 2-3 weeks | 14, 11 | Hard |

**Total: ~6-8 weeks for full implementation**

---
---

# PART 2: Full App Upgrade — Master Implementation Plan

> Covers: UI Overflow Fixes, AI Enrichment Architecture, Dates Tab, Create Trip, Create Post, Settings, Privacy Policy, Terms & Conditions, Offline Mode, Trip Status, Emergency Info, and Overview Intelligence.

---

## Current Codebase Audit Summary

| Screen / Service | File | Lines | Current State |
|---|---|---|---|
| Place Detail | `lib/screens/place_detail_screen.dart` | 872 | Has fixed heights, shows "N/A" for missing data, AI enrichment exists but partial |
| Create Trip | `lib/screens/create_trip_screen.dart` | 579 | Basic: name, location, dates, budget, visibility. No trip type, no traveler count, no auto-budget |
| Create Post | `lib/screens/create_post_screen.dart` | 539 | Has multi-image, mentions, location autocomplete, trip association, 3 visibility options. Missing drafts, emoji toolbar |
| Settings | `lib/screens/settings_screen.dart` | 246 | Minimal: theme toggle, feedback, privacy/terms, archived posts, privacy settings, logout, delete account |
| Privacy Policy | `lib/screens/privacy_policy_screen.dart` | 97 | Basic flutter_markdown, NOT GDPR-ready, missing data portability, cookie policy, third-party details |
| Terms & Conditions | `lib/screens/terms_conditions_screen.dart` | 75 | Very basic, missing DMCA, age requirement, governing law, dispute resolution |
| Dates Tab | `_DateTab` in trip_dashboard_screen.dart | L2340-2738 | Only snapshot card + calendar editor + timeline. No countdown, no weather, no reminders |
| Google Places Service | `lib/services/google_places_service.dart` | 202 | Requests ratings, hours, photos, price level. Missing `currentOpeningHours`, `reviews` content unused |
| Offline / Sync | `lib/services/sync_service.dart` + `network_service.dart` | 96 + 54 | SyncService has queue skeleton but `_executeAction` is all stubs. NetworkService works. OfflineBanner exists |
| Local DB (Isar) | `lib/local/` | 9 schemas | Has CachedTrip, CachedProfile, CachedTripDay, CachedTripPlace, CachedGalleryPhoto, CachedMessage, CachedTripLink, CachedPoll, PendingAction. Schemas exist but sync logic is incomplete |
| Notification Service | `lib/services/notification_service.dart` | 231 | Real-time listener + local push. No scheduled notifications, no reminder scheduling |
| PlaceInsights Model | `lib/models/place_insights.dart` | 55 | 14 AI fields: bestTimeToVisit, crowdLevel, peakHours, avgVisitDuration, ticketRequired, ticketPriceEstimate, onlineBookingRecommended, bookingUrl, onsiteBookingAvailable, avgWaitingTime, insiderTips[], isWorthVisiting, familyFriendly, budgetFriendly |

---

## Section A: UI Overflow & Layout Fixes

### Problem Analysis

The app has layout overflow errors caused by:
1. **Fixed-height containers** with dynamic text content
2. **Unbounded text** in constrained layouts (e.g., `_infoTile`, `_detailRow`)
3. **Nearby attractions** cards with `SizedBox(height: 190)` where 2-line names + rating can exceed bounds
4. **Quick Facts Grid** with `childAspectRatio: 2.5` — long values like "None for beach entry; may be 10-15 min during weekends" overflow

### Phase A1: Place Detail Screen Overflow Fixes

**File: `lib/screens/place_detail_screen.dart`**

#### A1.1 — Quick Facts Grid (Line ~380)
```
CURRENT:  GridView.count with childAspectRatio: 2.5
PROBLEM:  Long values like "None for beach entry; may be 10–15 min during weekends" overflow
FIX:      
  - Remove GridView.count → use Wrap or Column with Row pairs
  - OR increase childAspectRatio to 2.0 and add maxLines: 2 + ellipsis on value Text
  - Value text: maxLines: 2, overflow: TextOverflow.ellipsis
```

#### A1.2 — `_infoTile` Widget (Line ~835)
```
CURRENT:  Row → Icon + Column(label, value)
PROBLEM:  Value text has no overflow handling, can push past container bounds
FIX:
  - Wrap the Column in Expanded
  - Value Text: maxLines: 2, overflow: TextOverflow.ellipsis
  - Make column use MainAxisSize.min
```

#### A1.3 — `_detailRow` Widget (Line ~810)
```
CURRENT:  Row with mainAxisAlignment: spaceBetween → label on left, value on right
PROBLEM:  Long values like "None for beach entry; may be 10–15 min during weekends" cause RIGHT overflow
FIX:
  - Wrap value Text in Flexible
  - Value Text: maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end
  - OR convert to Column layout for long values
```

#### A1.4 — Nearby Attractions (Line ~660)
```
CURRENT:  SizedBox(height: 190) → Container(width: 150) → Column(image 95px + Expanded text)
STATUS:   Previously fixed with Expanded + height 190
VERIFY:   Ensure text has maxLines: 2 + ellipsis (already present ✅)
```

#### A1.5 — Entry Details Section (Line ~458)
```
CURRENT:  _detailRow used for ticket, price, wait time, peak hours
PROBLEM:  Values from AI can be long sentences
FIX:      Apply Flexible/Expanded to all _detailRow value widgets
```

#### A1.6 — General Rule
```
RULE: NEVER use fixed height on any card containing dynamic text
REPLACE: Container(height: X) → Container() with MainAxisSize.min
REPLACE: SizedBox(height: X) → IntrinsicHeight or no fixed height
ADD:     maxLines + TextOverflow.ellipsis on ALL dynamic text widgets
```

### Phase A2: Hide Empty/N/A Fields

**Current Problem:** Several places show "N/A" or empty values which looks unprofessional.

#### Implementation

```dart
// CURRENT (in _buildQuickFactsGrid):
_infoTile(Icons.payments_rounded, "Price", priceLevel),  // Shows "N/A"
_infoTile(Icons.timer_rounded, "Duration", duration ?? "N/A"),
_infoTile(Icons.groups_rounded, "Crowds", crowd ?? "N/A"),

// FIX: Only add tiles that have real data
final List<Widget> factTiles = [];
if (rating != null) {
  factTiles.add(_infoTile(Icons.star_rounded, "Rating", ...));
}
if (priceLevel != 'N/A') {
  factTiles.add(_infoTile(Icons.payments_rounded, "Price", priceLevel));
}
if (duration != null) {
  factTiles.add(_infoTile(Icons.timer_rounded, "Duration", duration));
}
if (crowd != null) {
  factTiles.add(_infoTile(Icons.groups_rounded, "Crowds", crowd));
}
// Use Wrap widget instead of GridView for dynamic count
```

**Apply same rule across entire screen:**
- Entry Details: Only show rows where value is not null/empty
- AI Analysis: Only show if insights actually have content
- Contact section already handles this correctly ✅

### Files to Modify
- `lib/screens/place_detail_screen.dart` — All overflow fixes + N/A hiding

---

## Section B: AI Enrichment Architecture (2-Layer Data System)

### Problem Analysis

Currently WanderWith has a partial AI enrichment system:
- `TripService.getPlaceInsights(googlePlaceId)` → checks `place_ai_insights` DB table
- If null → `TripService.enrichPlaceInsights(placeId, name, tripLocation)` → calls Gemini → stores in DB
- This already works! But the prompt may not cover all user-expected fields
- Some places (beaches, natural attractions) get incomplete Google data → AI should fill smart defaults

### Phase B1: Enhance AI Enrichment Prompt

**File: `lib/services/gemini_service.dart`**

#### Current Prompt Fields (14 fields)
```
ticket_required, ticket_price_estimate, online_booking_recommended,
booking_url, onsite_booking_available, avg_waiting_time,
crowd_level, peak_hours, avg_visit_duration, best_time_to_visit,
insider_tips[], is_worth_visiting, family_friendly, budget_friendly
```

#### New Fields to Add (8 more = 22 total)
```
safety_rating          — "Very Safe" / "Safe" / "Exercise Caution"
parking_available      — true/false
nearby_restrooms       — true/false  
photography_allowed    — true/false
wheelchair_accessible  — true/false
estimated_cost_per_person — "₹500-800" or "Free"
recommended_duration_hours — 2.5 (numeric for sorting)
local_tips             — String (cultural etiquette, dress code, etc.)
```

#### Updated PlaceInsights Model
```dart
// ADD to PlaceInsights class:
String? get safetyRating => insights['safety_rating'] as String?;
bool get parkingAvailable => insights['parking_available'] == true;
bool get nearbyRestrooms => insights['nearby_restrooms'] == true;
bool get photographyAllowed => insights['photography_allowed'] != false; // true by default
bool get wheelchairAccessible => insights['wheelchair_accessible'] == true;
String? get estimatedCostPerPerson => insights['estimated_cost_per_person'] as String?;
double? get recommendedDurationHours => (insights['recommended_duration_hours'] as num?)?.toDouble();
String? get localTips => insights['local_tips'] as String?;
```

### Phase B2: Smart Default Values for Natural Attractions

**Logic in enrichPlaceInsights or in the Gemini prompt:**

```
For natural attractions (beaches, parks, hiking trails, lakes):
- If Google priceLevel is null → AI should infer "Free" for beaches/parks
- If crowd data unavailable but rating > 4.5 and review count > 10,000 → crowd = "High"
- If rating > 4.5 and review count > 5,000 → crowd = "Moderate to High"
- If review count < 500 → crowd = "Low" (hidden gem)
```

**Add to gemini prompt:**
```
Consider the place type: ${place.type}.
For natural attractions (beaches, parks, hiking trails), assume:
- Entry is typically free unless stated otherwise
- No ticket required unless it's a national park or protected area
- Estimate crowd based on rating and popularity
If specific data is unavailable, make reasonable travel-expert estimates rather than saying "unknown".
```

### Phase B3: Caching & Re-enrichment Strategy

```
CURRENT:  Enrich once → store forever
IMPROVED: 
  - Store enrichment with timestamp (already has updated_at)
  - If data is older than 90 days → re-enrich on next view
  - Add "Refresh" button on place detail screen → force re-enrich
  - Show "Last updated: X days ago" below AI sections
```

### Phase B4: Google Places API Field Optimization

**File: `lib/services/google_places_service.dart`**

**Current X-Goog-FieldMask for getPlaceDetails:**
```
id,displayName,location,photos,rating,formattedAddress,primaryType,
editorialSummary,reviews,regularOpeningHours,priceLevel,userRatingCount
```

**Add missing fields:**
```
currentOpeningHours       — Live "open now" status (more accurate than regularOpeningHours)
websiteUri                — Official website
internationalPhoneNumber  — Contact phone
accessibilityOptions      — Wheelchair info
parkingOptions            — Parking available
paymentOptions            — Cards accepted
```

**Updated FieldMask:**
```
id,displayName,location,photos,rating,formattedAddress,primaryType,
editorialSummary,reviews,regularOpeningHours,currentOpeningHours,
priceLevel,userRatingCount,websiteUri,internationalPhoneNumber,
accessibilityOptions,parkingOptions,paymentOptions
```

### Phase B5: Merge Display Logic

```dart
// Place detail screen load flow:
void _loadAllData() async {
  await Future.wait([
    _loadGoogleDetails(),    // Layer 1: Raw Google data
    _loadAiInsights(),       // Layer 2: AI enrichment
    _loadNearbyPlaces(),     // Nearby attractions
  ]);
  _mergeAndRender();  // NEW: Combine both layers
}

void _mergeAndRender() {
  // Google parking + AI parking → show whichever is available
  // Google priceLevel + AI estimatedCost → prefer AI if available
  // Google accessibility + AI wheelchair → combine
  // Google reviews → extract sentiment for crowd estimation
  setState(() {}); // Trigger rebuild with merged data
}
```

### Files to Create/Modify
- `lib/services/gemini_service.dart` — Enhanced enrichment prompt
- `lib/services/google_places_service.dart` — Additional field mask
- `lib/models/place_insights.dart` — 8 new getters
- `lib/screens/place_detail_screen.dart` — Merge logic, smart field hiding, new sections

---

## Section C: Dates Tab Upgrade

### Current State (Lines 2340-2738 in trip_dashboard_screen.dart)
- `_buildTripSnapshotCard`: Blue gradient hero with location, dates, duration, traveler count
- `_showCalendarModal`: TableCalendar for range editing
- Day timeline: Horizontal scroll of day badges
- Day-by-day list view below timeline

### Phase C1: Trip Countdown Widget

**Add inside `_buildTripSnapshotCard` (below the existing date range display)**

```dart
Widget _buildCountdown(Trip trip, AppColors colors) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  if (trip.startDate == null) {
    return _countdownChip("📅 Dates not set yet", colors);
  }
  
  final start = DateTime(trip.startDate!.year, trip.startDate!.month, trip.startDate!.day);
  final end = trip.endDate != null 
      ? DateTime(trip.endDate!.year, trip.endDate!.month, trip.endDate!.day) 
      : start;
  
  if (today.isBefore(start)) {
    final daysUntil = start.difference(today).inDays;
    if (daysUntil == 0) return _countdownChip("🛫 Trip starts today!", colors);
    if (daysUntil == 1) return _countdownChip("🛫 Trip starts tomorrow!", colors);
    return _countdownChip("⏳ $daysUntil days to go", colors);
  } else if (!today.isAfter(end)) {
    final dayNumber = today.difference(start).inDays + 1;
    final totalDays = end.difference(start).inDays + 1;
    return _countdownChip("🌍 Day $dayNumber of $totalDays", colors);
  } else {
    return _countdownChip("✅ Trip Completed", colors);
  }
}
```

### Phase C2: Weather Preview

**Add below the snapshot card**

```dart
Widget _buildWeatherPreview(Trip trip, AppColors colors) {
  // Only show for future/ongoing trips with dates set
  // Fetch from a weather API (OpenWeatherMap 5-day forecast or WeatherAPI.com)
  // Cache result for 6 hours
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.surfaceBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.border),
    ),
    child: Row(
      children: [
        Text("☀️", style: TextStyle(fontSize: 32)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Expected Weather in ${trip.location}",
                style: TextStyle(fontSize: 12, color: colors.textMuted)),
              Text("28°C | Partly Cloudy",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            ],
          ),
        ),
      ],
    ),
  );
}
```

**New Service: `lib/services/weather_service.dart`**
```dart
class WeatherService {
  // Use OpenWeatherMap free tier (60 calls/min)
  // Or WeatherAPI.com free tier (1M calls/month)
  
  Future<Map<String, dynamic>?> getForecast(String location, DateTime date) async {
    // 1. Geocode location to lat/lng (reuse GooglePlacesService)
    // 2. Call weather API
    // 3. Cache result in memory for 6 hours
    // 4. Return: {temp, condition, icon, humidity, wind}
  }
}
```

### Phase C3: Add Reminder System

**Uses `flutter_local_notifications` with `zonedSchedule` (already have the package)**

```dart
// Add to notification_service.dart:
Future<void> scheduleReminder({
  required String tripId,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
  
  await _localNotificationsPlugin.zonedSchedule(
    tripId.hashCode,  // Unique notification ID
    title,
    body,
    scheduledTZ,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'trip_reminders', 'Trip Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
```

**Reminder Types in Dates Tab:**
```dart
// Bottom sheet with quick reminder options:
void _showAddReminder(Trip trip) {
  showModalBottomSheet(
    // Options:
    // 🛫 "Booking flights" — 30 days before trip
    // 📋 "Start packing" — 3 days before trip  
    // 🛂 "Visa deadline" — 45 days before trip (international only)
    // 📝 "Custom reminder" — User picks date + message
  );
}
```

### Phase C4: Smart Conflict Warning

```dart
// When user edits dates via calendar:
void _checkForConflicts(DateTimeRange newDates) {
  // 1. Check if user has other trips overlapping these dates
  // 2. If yes: show warning banner
  // "⚠ You have a trip to Paris (Jan 5-10) during these dates"
}
```

### Phase C5: Duplicate Trip Button

```dart
// Add to Dates Tab or Trip Settings:
Future<void> _duplicateTrip(Trip trip) async {
  // 1. Ask for new dates (show date picker)
  // 2. Copy: name, location, budget, metadata
  // 3. Copy: all day plans and places
  // 4. Do NOT copy: members, chat, photos, expenses
  // 5. Navigate to new trip dashboard
}
```

### Phase C6: Timezone Display (International Trips)

```dart
// Below location in snapshot card:
if (_isInternational && _metadata?.timezone != null)
  Text("🕐 Timezone: ${_metadata!.timezone}",
    style: TextStyle(fontSize: 12, color: Colors.white70)),
```

### Files to Create/Modify
- `lib/screens/trip_dashboard_screen.dart` — Dates tab: countdown, weather, reminders, conflicts, duplicate, timezone
- `lib/services/weather_service.dart` — NEW
- `lib/services/notification_service.dart` — Add `scheduleReminder` method
- `pubspec.yaml` — May need `timezone` package for scheduling

---

## Section D: Create Trip Screen Upgrade

### Current State (579 lines)
Has: name, location (with autocomplete + auto cover photo), dates (with toggle), budget (collapsible), visibility (agency only).
Missing: trip type, traveler count, auto budget suggestion, description, tags, collaborators.

### Phase D1: Auto Cover Image Enhancement
```
CURRENT:  ✅ Already auto-fetches photo when location selected
IMPROVE:  Add blurred placeholder during fetch (already has LinearProgressIndicator)
          Add fallback category images if Google returns no photo
```

### Phase D2: Traveler Count Selector

**Add between Dates and Budget sections (~L224)**

```dart
Widget _buildTravelerCount() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("TRAVELERS", style: _sectionLabelStyle),
      SizedBox(height: 8),
      Container(
        padding: EdgeInsets.all(16),
        decoration: _fieldDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.people_outline, color: AppColors.brand),
              SizedBox(width: 12),
              Text("Travelers", style: TextStyle(fontSize: 16)),
            ]),
            Row(children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline),
                onPressed: _travelerCount > 1 ? () => setState(() => _travelerCount--) : null,
              ),
              Text("$_travelerCount", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: AppColors.brand),
                onPressed: () => setState(() => _travelerCount++),
              ),
            ]),
          ],
        ),
      ),
    ],
  );
}
```

**Store in trip metadata:** `metadata['traveler_count'] = _travelerCount`

### Phase D3: Trip Type Selector

**Add after location section**

```dart
// State:
String _tripType = 'leisure';
final _tripTypes = [
  {'id': 'leisure', 'emoji': '🏖', 'label': 'Leisure'},
  {'id': 'backpacking', 'emoji': '🎒', 'label': 'Backpacking'},
  {'id': 'luxury', 'emoji': '💎', 'label': 'Luxury'},
  {'id': 'family', 'emoji': '👨‍👩‍👧', 'label': 'Family'},
  {'id': 'workation', 'emoji': '💼', 'label': 'Workation'},
  {'id': 'adventure', 'emoji': '🧗', 'label': 'Adventure'},
  {'id': 'romantic', 'emoji': '💕', 'label': 'Romantic'},
  {'id': 'solo', 'emoji': '🧘', 'label': 'Solo'},
];

Widget _buildTripTypeSelector() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("TRIP TYPE", style: _sectionLabelStyle),
      SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _tripTypes.map((type) {
          final isSelected = _tripType == type['id'];
          return GestureDetector(
            onTap: () => setState(() => _tripType = type['id'] as String),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.textPrimary : colors.surfaceBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? colors.textPrimary : colors.border),
              ),
              child: Text(
                "${type['emoji']} ${type['label']}",
                style: TextStyle(
                  color: isSelected ? colors.scaffoldBg : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}
```

**Store in trip metadata:** `metadata['trip_type'] = _tripType`

### Phase D4: Estimated Budget Auto Suggestion

**After location + dates + trip type are selected:**

```dart
Widget _buildBudgetSuggestion() {
  if (_locationController.text.isEmpty || _tripType.isEmpty) return SizedBox.shrink();
  
  // Call Gemini with: location, trip type, traveler count, duration
  // OR use static lookup table for common destinations
  // Return: { low: "₹10,000", mid: "₹25,000", high: "₹50,000" }
  
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Text("💰", style: TextStyle(fontSize: 20)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            "Estimated: ₹15,000 – ₹30,000 per person (mid-range)",
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
      ],
    ),
  );
}
```

**New method in GeminiService:**
```dart
Future<Map<String, dynamic>?> estimateTripBudget({
  required String location,
  required String tripType,
  required int travelers,
  required int days,
  required String currency,
}) async {
  // Prompt: estimate low/mid/high budget for X days in Y for Z travelers
  // Return: {low: amount, mid: amount, high: amount, breakdown: {stay, food, transport, activities}}
}
```

### Phase D5: Visibility Logic Fix

```
CURRENT:  Visibility section only shows for agencies
CHANGE:
  - Travelers: ALWAYS private (remove public option)
  - Agencies: Keep both public + private
  - Remove the section entirely for travelers (trips are private by default)
  - Auto-generate join code for all traveler trips
```

```dart
Widget _buildVisibilitySection() {
  final userProfile = Provider.of<AuthService>(context, listen: false).userProfile;
  
  // For regular travelers, force private — no UI needed
  if (userProfile?.role != 'agency') {
    _visibility = 'private';  // Force
    return const SizedBox.shrink();
  }
  
  // Agency users get the choice
  // ... existing radio list tiles ...
}
```

### Phase D6: Advanced Options (Collapsible)

```dart
Widget _buildAdvancedOptions() {
  return Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      title: Text("ADVANCED OPTIONS", style: _sectionLabelStyle),
      children: [
        // Trip Description
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(hintText: "Describe your trip (optional)"),
        ),
        SizedBox(height: 16),
        // Tags
        Wrap(children: _tags.map((t) => Chip(label: Text(t))).toList()),
        TextField(hintText: "Add tags (e.g., beach, adventure)"),
        SizedBox(height: 16),
        // Collaborators
        Text("Invite collaborators (they can edit the plan)"),
        // Search + add members by username
      ],
    ),
  );
}
```

### Files to Modify
- `lib/screens/create_trip_screen.dart` — Traveler count, trip type, budget suggestion, visibility fix, advanced options
- `lib/services/gemini_service.dart` — Budget estimation method
- `lib/services/trip_service.dart` — Store new metadata fields (trip_type, traveler_count, description, tags)

---

## Section E: Create Post Screen Upgrade

### Current State (539 lines)
Has: multi-image picker, caption with @mentions, location autocomplete, trip association, 3 visibility options (followers, public, trip only). 
Missing: carousel preview, emoji toolbar, drafts, close friends visibility.

### Phase E1: Image Carousel Enhancement

```
CURRENT:  Horizontal ListView of images, tap last item to add more ✅
IMPROVE:  
  - Add page indicator dots below carousel  
  - Add reorder capability (long press to drag)
  - Show image count badge: "3/10"
```

### Phase E2: Emoji Caption Toolbar

```dart
Widget _buildEmojiToolbar() {
  final quickEmojis = ['😍', '🌍', '✈️', '🏖', '⛰️', '🍽', '📸', '🎉', '❤️', '🔥'];
  
  return Container(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: quickEmojis.length,
      separatorBuilder: (_, __) => SizedBox(width: 8),
      itemBuilder: (context, index) => GestureDetector(
        onTap: () {
          final text = _captionController.text;
          final selection = _captionController.selection;
          final newText = text.replaceRange(
            selection.start, selection.end, quickEmojis[index]);
          _captionController.text = newText;
          _captionController.selection = TextSelection.fromPosition(
            TextPosition(offset: selection.start + quickEmojis[index].length));
        },
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.surfaceBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(quickEmojis[index], style: TextStyle(fontSize: 20)),
        ),
      ),
    ),
  );
}
```

### Phase E3: Draft Saving System

```dart
// Auto-save draft when user navigates away
void _saveDraft() async {
  if (_captionController.text.isEmpty && _selectedImages.isEmpty) return;
  
  final draft = {
    'caption': _captionController.text,
    'location': _locationController.text,
    'visibility': _visibility,
    'trip_id': _selectedTrip?.id,
    'image_paths': _selectedImages.map((f) => f.path).toList(),
    'saved_at': DateTime.now().toIso8601String(),
  };
  
  // Save to SharedPreferences or Isar
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('post_draft', jsonEncode(draft));
}

// Load draft on init
void _loadDraft() async {
  final prefs = await SharedPreferences.getInstance();
  final draftJson = prefs.getString('post_draft');
  if (draftJson != null) {
    // Show: "Resume draft?" bottom sheet
  }
}
```

**In Settings screen, add "Draft Posts" section (under Archived Posts)**

### Phase E4: Enhanced Visibility Options

```dart
// Add "Close Friends" option
// Post visibility options:
// followers — visible to followers
// public — visible to everyone
// trip — visible only to trip members (if trip selected)
// close_friends — visible to close friends list (new feature)

// Requires:
// 1. Close friends list management in profile/settings
// 2. DB: close_friends table (user_id, friend_id)
// 3. RLS policy for close_friends visibility
```

### Files to Modify
- `lib/screens/create_post_screen.dart` — Emoji toolbar, drafts, visibility upgrade
- `lib/services/post_service.dart` — Draft save/load, close friends visibility filter
- `lib/screens/settings_screen.dart` — Add "Draft Posts" + "Close Friends" management

---

## Section F: Settings Screen Upgrade

### Current State (246 lines)
Sections: Appearance (theme toggle), Support (feedback, privacy, terms), Privacy (archived posts, privacy settings), Account (logout, delete).

### Phase F1: Account Info Section

```dart
_buildSectionHeader(context, "Account Info"),
_buildSettingsItem(context,
  icon: Icons.email_outlined,
  title: "Email",
  subtitle: authService.user?.email ?? 'Not set',
  onTap: () {}, // Non-editable, just display
),
_buildSettingsItem(context,
  icon: Icons.person_outline,
  title: "Username",
  subtitle: authService.userProfile?.username ?? 'Not set',
  onTap: () => _editUsername(context),
),
_buildSettingsItem(context,
  icon: Icons.lock_outline,
  title: "Change Password",
  onTap: () => _changePassword(context),
),
```

**Change Password Flow:**
```dart
void _changePassword(BuildContext context) async {
  // 1. Show dialog with current password + new password fields
  // 2. Call Supabase auth.updateUser(UserAttributes(password: newPassword))
  // 3. Show success/error
}
```

### Phase F2: Notification Settings

```dart
_buildSectionHeader(context, "Notifications"),
_buildToggleItem(context,
  icon: Icons.notifications_outlined,
  title: "Push Notifications",
  value: _pushEnabled,
  onChanged: (val) => _updateNotifPref('push_enabled', val),
),
_buildToggleItem(context,
  icon: Icons.chat_bubble_outline,
  title: "Chat Messages",
  value: _chatNotifs,
  onChanged: (val) => _updateNotifPref('chat_notifs', val),
),
_buildToggleItem(context,
  icon: Icons.group_outlined,
  title: "Trip Updates",
  value: _tripNotifs,
  onChanged: (val) => _updateNotifPref('trip_notifs', val),
),
_buildToggleItem(context,
  icon: Icons.favorite_outline,
  title: "Likes & Comments",
  value: _socialNotifs,
  onChanged: (val) => _updateNotifPref('social_notifs', val),
),
```

**Storage:** Save preferences in `profiles` table metadata or a separate `notification_preferences` table.

### Phase F3: Data & Storage Section

```dart
_buildSectionHeader(context, "Data & Storage"),
_buildSettingsItem(context,
  icon: Icons.download_outlined,
  title: "Download My Data",
  onTap: _requestDataExport,  // GDPR requirement
),
_buildSettingsItem(context,
  icon: Icons.cleaning_services_outlined,
  title: "Clear Cache",
  subtitle: "${_cacheSize}MB",
  onTap: _clearCache,
),
_buildSettingsItem(context,
  icon: Icons.sd_storage_outlined,
  title: "Offline Storage",
  subtitle: "${_offlineSize}MB used",
  onTap: () {},
),
```

**Clear Cache Implementation:**
```dart
void _clearCache() async {
  // 1. Clear Isar local database
  await LocalDb.instance.clearAll();
  // 2. Clear image cache
  await DefaultCacheManager().emptyCache();
  // 3. Show confirmation
}
```

### Phase F4: Contact Support

```dart
_buildSectionHeader(context, "Support"),
_buildSettingsItem(context,
  icon: Icons.email_outlined,
  title: "Contact Support",
  subtitle: "wanderwithplan@gmail.com",
  onTap: () async {
    final uri = Uri(scheme: 'mailto', path: 'wanderwithplan@gmail.com',
        queryParameters: {'subject': 'WanderWith Support Request'});
    await launchUrl(uri);
  },
),
// Keep existing feedback, privacy, terms items
```

### Phase F5: App Info Update

```dart
// Update footer:
Text("WanderWith v2.0.0"),
Text("Made with ❤️ for Travelers"),
// Add: "Rate us on Play Store" link
```

### Files to Modify
- `lib/screens/settings_screen.dart` — All new sections
- `lib/services/auth_service.dart` — Change password method
- May need `lib/screens/notification_preferences_screen.dart` — NEW (if complex)

---

## Section G: Privacy Policy (GDPR-Ready Rewrite)

### Phase G1: Complete Privacy Policy

**Replace entire content of `lib/screens/privacy_policy_screen.dart`**

The privacy policy must cover:
1. Information We Collect (personal, trip, usage, device, location)
2. Legal Basis for Processing (consent, legitimate interest, contract)
3. How We Use Information (service delivery, personalization, analytics, safety)
4. Data Sharing & Third Parties (Supabase hosting, Google Maps, Gemini AI, analytics)
5. International Data Transfers (Supabase regions, GDPR adequacy)
6. Data Retention (how long we keep data, auto-deletion policies)
7. Your Rights Under GDPR (access, rectification, erasure, portability, restriction, objection, withdraw consent)
8. Your Rights Under CCPA (know, delete, opt-out, non-discrimination)
9. Children's Privacy (13+ age requirement, COPPA compliance)
10. Location Data (when collected, how used, how to disable)
11. Cookies & Similar Technologies (if web version used)
12. Account Deletion (process, timeline, what gets deleted)
13. Data Security (encryption, access controls, breach notification)
14. Changes to Policy (notification method, effective date)
15. Contact Information (DPO, email, address)

**Effective Date:** March 1, 2026
**Contact:** wanderwithplan@gmail.com

### Phase G2: In-App Consent Management

```dart
// On first launch after policy update:
// Show consent dialog with:
// - Summary of changes
// - "I Agree" / "Read Full Policy" buttons
// - Store consent timestamp in profile metadata
```

### Files to Modify
- `lib/screens/privacy_policy_screen.dart` — Complete rewrite with full GDPR/CCPA text

---

## Section H: Terms & Conditions Rewrite

### Phase H1: Complete Terms

**Replace entire content of `lib/screens/terms_conditions_screen.dart`**

Must cover:
1. Acceptance of Terms (by using = agreeing)
2. Account Registration (accurate info, age 13+, one account, security responsibility)
3. User Content (ownership retained, license to WanderWith for service, prohibited content)
4. Prohibited Conduct (harassment, illegal content, spam, impersonation, scraping, malware)
5. Trip Planning Disclaimer (NOT a travel agency, no booking responsibility, no insurance)
6. Intellectual Property (WanderWith owns app, brand, features)
7. Third-Party Services (Google Maps, AI services, payment processors)
8. Account Suspension & Termination (grounds, appeal process, data after termination)
9. DMCA / Copyright (report infringement, counter-notice process)
10. Limitation of Liability (cap, exclusions, indemnification)
11. Dispute Resolution (governing law, arbitration, class action waiver)
12. Modifications (30-day notice, continued use = acceptance)
13. Severability (if one provision invalid, rest remains)
14. Contact (legal@wanderwithplan.com)

**Effective Date:** March 1, 2026

### Files to Modify
- `lib/screens/terms_conditions_screen.dart` — Complete rewrite

---

## Section I: Offline Mode — Complete Implementation

### Current State
- ✅ `NetworkService` — monitors connectivity, notifies listeners
- ✅ `SyncService` — has queue framework but `_executeAction` is all stubs
- ✅ `OfflineBanner` — shows amber bar when offline
- ✅ 9 Isar schemas exist (CachedTrip, CachedProfile, CachedTripDay, CachedTripPlace, CachedGalleryPhoto, CachedMessage, CachedTripLink, CachedPoll, PendingAction)
- ❌ Data never actually written to Isar cache on fetch
- ❌ Screens don't try to read from Isar when offline
- ❌ SyncService actions are all `debugPrint` stubs

### Phase I1: Write-Through Cache Layer

**Add cache writing to every data fetch in TripService:**

```dart
// PATTERN: Every fetch should cache
Future<Trip> getTrip(String tripId) async {
  if (NetworkService.instance.isOnline) {
    try {
      final data = await _supabase.from('trips').select().eq('id', tripId).single();
      final trip = Trip.fromMap(data);
      
      // Cache it
      await _cacheTrip(trip);
      
      return trip;
    } catch (e) {
      // Fallback to cache on network error
      return await _getCachedTrip(tripId) ?? rethrow;
    }
  } else {
    // Pure offline mode
    final cached = await _getCachedTrip(tripId);
    if (cached != null) return cached;
    throw Exception("Trip not available offline");
  }
}

Future<void> _cacheTrip(Trip trip) async {
  await LocalDb.instance.writeTxn(() async {
    await LocalDb.instance.cachedTrips.put(
      CachedTrip()
        ..tripId = trip.id
        ..dataJson = jsonEncode(trip.toMap())
        ..updatedAt = DateTime.now()
    );
  });
}

Future<Trip?> _getCachedTrip(String tripId) async {
  final cached = await LocalDb.instance.cachedTrips
      .filter().tripIdEqualTo(tripId).findFirst();
  if (cached == null) return null;
  return Trip.fromMap(jsonDecode(cached.dataJson));
}
```

### Phase I2: What Must Be Cached

| Data | Schema | Cache On | Priority |
|---|---|---|---|
| Trip list | CachedTrip | Every getUserTrips fetch | HIGH |
| Trip details | CachedTrip | Every getTrip fetch | HIGH |
| Trip day plans | CachedTripDay | Every plan fetch | HIGH |
| Plan places | CachedTripPlace | Every place fetch | HIGH |
| Member profiles | CachedProfile | Every getMembersProfiles | MEDIUM |
| Chat messages (last 200) | CachedMessage | Every stream update | MEDIUM |
| Gallery photos (metadata) | CachedGalleryPhoto | Every gallery fetch | LOW |
| Polls | CachedPoll | Every poll stream | LOW |
| Trip links | CachedTripLink | Every link fetch | LOW |

### Phase I3: Implement SyncService Actions

```dart
Future<void> _executeAction(PendingAction action) async {
  final payload = jsonDecode(action.payloadJson) as Map<String, dynamic>;
  
  switch (action.actionType) {
    case 'add_plan_place':
      await _supabase.from('trip_plan_places').insert(payload);
      break;
    case 'upload_photo':
      // Re-read from local path, upload to storage, insert record
      final file = File(payload['local_path']);
      if (file.existsSync()) {
        final path = 'trip_photos/${payload['trip_id']}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('trip-photos').upload(path, file);
        await _supabase.from('trip_photos').insert({
          'trip_id': payload['trip_id'],
          'photo_url': _supabase.storage.from('trip-photos').getPublicUrl(path),
          'uploader_id': payload['uploader_id'],
        });
      }
      break;
    case 'add_expense':
      await _supabase.from('trip_expenses').insert(payload);
      break;
    case 'send_message':
      await _supabase.from('trip_messages').insert(payload);
      break;
    case 'toggle_reaction':
      // Check if exists → delete, else → insert
      break;
    case 'update_checklist':
      await _supabase.from('trip_checklist').upsert(payload);
      break;
  }
}
```

### Phase I4: Offline-Aware Screen Pattern

```dart
// Generic pattern for all screens:
class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OfflineBanner(),  // Already exists
        Expanded(
          child: // Screen content
          // Use StreamBuilder when online → FutureBuilder from Isar when offline
        ),
      ],
    );
  }
}
```

### Phase I5: Smart Cache Invalidation

```dart
// Strategies:
// 1. Time-based: Re-fetch if cache older than 1 hour (for trips, plans)
// 2. Event-based: Invalidate when user makes a change
// 3. Version-based: Cache a version number, invalidate on mismatch
// 4. Size-based: Limit Isar DB to 100MB, prune old data

Future<void> pruneOldCache() async {
  final cutoff = DateTime.now().subtract(Duration(days: 30));
  await LocalDb.instance.writeTxn(() async {
    // Delete cached data older than 30 days for completed trips
    await LocalDb.instance.cachedMessages
        .filter().updatedAtLessThan(cutoff).deleteAll();
  });
}
```

### Files to Modify
- `lib/services/sync_service.dart` — Implement all `_executeAction` cases
- `lib/services/trip_service.dart` — Add cache write after every fetch
- `lib/services/plan_service.dart` — Add cache write/read
- `lib/local/local_db.dart` — May need schema updates
- Multiple screens — Add OfflineBanner + offline-aware data loading

---

## Section J: Trip Status Dynamic System

### Phase J1: Status Display

```dart
// Trip model already has .status computed property:
// 'planning' | 'confirmed' | 'completed' | 'dead'
// ADD: 'ongoing' status

String get status {
  final now = DateTime.now();
  if (isDead) return 'dead';
  if (startDate != null && endDate != null) {
    if (now.isAfter(endDate!)) return 'completed';
    if (now.isAfter(startDate!) || now.isAtSameMomentAs(startDate!)) return 'ongoing';
  }
  final hasBudget = estimatedCost > 0 || budgetAllocations.isNotEmpty;
  if (isDateDecided && hasBudget) return 'confirmed';
  return 'planning';
}
```

### Phase J2: Status-Based Overview Changes

```dart
// In trip_dashboard_screen.dart Overview tab:
switch (trip.status) {
  case 'planning':
    // Show: Planning checklist, budget suggestions, date picker CTA
    // Hide: Weather (dates not final), Day-by-day guides
    break;
  case 'confirmed':
    // Show: Countdown, weather forecast, packing checklist, booking reminders
    break;
  case 'ongoing':
    // Show: Today's plan, live location, nearby attractions, expense tracker
    // Show: Emergency info prominently
    break;
  case 'completed':
    // Show: Trip summary, photo gallery, expenses summary, review prompt
    // Hide: Planning tools, weather
    break;
}
```

### Phase J3: Status Badge Widget

```dart
Widget _buildStatusBadge(String status) {
  Color color;
  String label;
  IconData icon;
  
  switch (status) {
    case 'planning': color = Colors.orange; label = "Planning"; icon = Icons.edit_note; break;
    case 'confirmed': color = Colors.blue; label = "Confirmed"; icon = Icons.check_circle; break;
    case 'ongoing': color = Colors.green; label = "Ongoing"; icon = Icons.flight_takeoff; break;
    case 'completed': color = Colors.grey; label = "Completed"; icon = Icons.flag; break;
    default: color = Colors.red; label = "Cancelled"; icon = Icons.cancel; break;
  }
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );
}
```

### Files to Modify
- `lib/models/trip.dart` — Add 'ongoing' to status getter
- `lib/screens/trip_dashboard_screen.dart` — Status-aware overview, status badge
- `lib/widgets/trip_card.dart` — Show status badge on trip cards in list

---

## Section K: Overview Tab — Smart Destination Intel (Already Partially Fixed)

### What Was Already Fixed
- ✅ Bug 4: Domestic trips no longer show visa/currency (using `_isInternational` flag)
- ✅ Bug 5: Emergency info shows destination-specific numbers with 112 fallback

### What Still Needs to Be Added

#### K1: Domestic Trip Additions
```
Currently shown for domestic:
✔ Weather (via trip metadata)
✔ Emergency numbers (fixed, destination-specific)
✔ AI Summary

Should also show:
➕ Local transport tips (AI-generated)
➕ Local SIM/connectivity info (AI-generated)
➕ Safety tips specific to destination (AI-generated)
➕ Local customs & etiquette (AI-generated)
```

#### K2: International Trip Additions
```
Currently shown:
✔ Visa requirements
✔ Currency exchange
✔ Embassy contact
✔ Emergency numbers

Should also show:
➕ Passport validity reminder ("Ensure passport valid for 6+ months")
➕ Travel insurance reminder
➕ Power plug type info (Type C, Type G, etc.)
➕ SIM card / connectivity info
➕ Language & useful phrases
➕ Tipping customs
```

#### K3: Implementation

**Enhance `enrichInternationalInfo` Gemini prompt** to include these extra fields. The `TripInternationalInfo` model would need new fields:

```dart
// Add to TripInternationalInfo:
String? get plugType => data['plug_type'] as String?;
String? get tippingCustoms => data['tipping_customs'] as String?;
List<String> get usefulPhrases => (data['useful_phrases'] as List?)?.cast<String>() ?? [];
String? get simInfo => data['sim_info'] as String?;
String? get passportReminder => data['passport_reminder'] as String?;
String? get travelInsuranceNote => data['travel_insurance_note'] as String?;
```

**For domestic trips — add new Gemini prompt:**
```dart
Future<Map<String, dynamic>?> getDomesticTravelInfo(String destination) async {
  // Prompt: For domestic travel to {destination}, provide:
  // - Local transport options and tips
  // - SIM/connectivity info
  // - Safety tips
  // - Local customs and etiquette
  // - Best local food to try
  // Return structured JSON
}
```

### Files to Modify
- `lib/services/gemini_service.dart` — Enhanced international prompt + new domestic prompt
- `lib/models/trip_international_info.dart` — New fields
- `lib/screens/trip_dashboard_screen.dart` — New domestic info cards, new international cards

---

## Implementation Priority & Sprint Plan

### Sprint 1 (Week 1): Critical UI + Quick Wins
| Task | Section | Effort | Impact |
|---|---|---|---|
| Fix all overflow errors | A1-A5 | Low | HIGH — crashes/visual bugs |
| Hide N/A fields | A2 | Low | Medium — polished UX |
| Trip countdown in Dates tab | C1 | Low | Medium — engagement |
| Trip status system | J1-J3 | Low | Medium — smart UX |
| Timezone display | C6 | Low | Low — informational |

### Sprint 2 (Week 2): Create Trip + Post Upgrades
| Task | Section | Effort | Impact |
|---|---|---|---|
| Traveler count selector | D2 | Low | Medium |
| Trip type selector | D3 | Low | HIGH — AI personalization |
| Visibility fix (travelers always private) | D5 | Low | Medium — UX clarity |
| Emoji toolbar for posts | E2 | Low | Low — fun UX |
| Draft saving for posts | E3 | Medium | Medium — saves work |

### Sprint 3 (Week 3): Settings + Legal
| Task | Section | Effort | Impact |
|---|---|---|---|
| Settings account/notif/data sections | F1-F4 | Medium | HIGH — completeness |
| Privacy Policy GDPR rewrite | G1 | Medium | HIGH — legal compliance |
| Terms & Conditions rewrite | H1 | Medium | HIGH — legal compliance |
| Contact support | F4 | Low | Medium |

### Sprint 4 (Week 3-4): AI Enrichment
| Task | Section | Effort | Impact |
|---|---|---|---|
| Enhanced AI enrichment prompt (22 fields) | B1 | Medium | HIGH — core value |
| Smart defaults for natural attractions | B2 | Low | Medium — completeness |
| Google Places API field optimization | B4 | Low | Medium — more data |
| Merge display logic | B5 | Medium | HIGH — unified UX |
| Auto budget suggestion | D4 | Medium | HIGH — wow factor |

### Sprint 5 (Week 4-5): Dates Tab + Weather
| Task | Section | Effort | Impact |
|---|---|---|---|
| Weather preview | C2 | Medium | HIGH — smart feel |
| Reminder system | C3 | Medium | HIGH — engagement |
| Duplicate trip | C5 | Medium | Medium — convenience |
| Smart conflict warning | C4 | Low | Low — edge case |

### Sprint 6 (Week 5-6): Overview Intelligence
| Task | Section | Effort | Impact |
|---|---|---|---|
| Domestic travel info cards | K1 | Medium | HIGH — completeness |
| International info enhancements | K2 | Medium | HIGH — travel utility |
| Status-based overview changes | J2 | Medium | HIGH — contextual UX |

### Sprint 7 (Week 6-8): Offline Mode
| Task | Section | Effort | Impact |
|---|---|---|---|
| Write-through cache for all data | I1-I2 | HIGH | HIGH — reliability |
| Implement SyncService actions | I3 | HIGH | HIGH — offline writes |
| Offline-aware screen pattern | I4 | Medium | HIGH — user experience |
| Cache invalidation | I5 | Medium | Medium — correctness |
| Advanced options for create trip | D6 | Medium | Low |

---

## New Files Summary

| File | Section | Description |
|---|---|---|
| `lib/services/weather_service.dart` | C2 | Weather forecast for trip dates |
| `lib/screens/notification_preferences_screen.dart` | F2 | Notification settings UI |
| (Optional) `lib/screens/draft_posts_screen.dart` | E3 | View/resume draft posts |

## Modified Files Summary (All Sections)

| File | Sections | Key Changes |
|---|---|---|
| `lib/screens/place_detail_screen.dart` | A, B | Overflow fixes, N/A hiding, merge display, new AI sections |
| `lib/screens/create_trip_screen.dart` | D | Traveler count, trip type, budget suggestion, visibility, advanced options |
| `lib/screens/create_post_screen.dart` | E | Emoji toolbar, drafts, carousel enhancement |
| `lib/screens/settings_screen.dart` | F | Account info, notifications, data & storage, support |
| `lib/screens/privacy_policy_screen.dart` | G | Complete GDPR-ready rewrite |
| `lib/screens/terms_conditions_screen.dart` | H | Complete legal rewrite |
| `lib/screens/trip_dashboard_screen.dart` | C, J, K | Countdown, weather, reminders, status, domestic/international intel |
| `lib/models/trip.dart` | J | 'ongoing' status |
| `lib/models/place_insights.dart` | B | 8 new AI field getters |
| `lib/models/trip_international_info.dart` | K | New fields (plug type, SIM, phrases, etc.) |
| `lib/services/gemini_service.dart` | B, D, K | Enhanced enrichment, budget estimation, domestic info |
| `lib/services/google_places_service.dart` | B | Additional API field mask |
| `lib/services/trip_service.dart` | D, I | New metadata fields, cache write-through |
| `lib/services/sync_service.dart` | I | Implement all executeAction cases |
| `lib/services/notification_service.dart` | C | scheduleReminder method |
| `lib/widgets/trip_card.dart` | J | Status badge |

---

## Database Changes Summary

```sql
-- No new tables needed for Sections A-K
-- Everything uses existing tables + metadata JSON columns + Isar local cache

-- OPTIONAL: Notification preferences table
CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  push_enabled BOOLEAN DEFAULT true,
  chat_notifs BOOLEAN DEFAULT true,
  trip_notifs BOOLEAN DEFAULT true,
  social_notifs BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- OPTIONAL: Close friends table (for post visibility)  
CREATE TABLE IF NOT EXISTS close_friends (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, friend_id)
);

-- OPTIONAL: Post drafts table (alternative to local storage)
CREATE TABLE IF NOT EXISTS post_drafts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  caption TEXT,
  location TEXT,
  visibility TEXT DEFAULT 'followers',
  trip_id UUID,
  image_paths TEXT[],
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

---

## Total Estimated Effort

| Section | Description | Sprints | Duration |
|---|---|---|---|
| A | UI Overflow Fixes | Sprint 1 | 2-3 days |
| B | AI Enrichment Architecture | Sprint 4 | 1 week |
| C | Dates Tab Upgrade | Sprint 1 + 5 | 1.5 weeks |
| D | Create Trip Upgrade | Sprint 2 | 1 week |
| E | Create Post Upgrade | Sprint 2 | 3-4 days |
| F | Settings Upgrade | Sprint 3 | 3-4 days |
| G | Privacy Policy | Sprint 3 | 1 day |
| H | Terms & Conditions | Sprint 3 | 1 day |
| I | Offline Mode | Sprint 7 | 2 weeks |
| J | Trip Status System | Sprint 1 + 6 | 3-4 days |
| K | Overview Intelligence | Sprint 6 | 1 week |

**Part 2 Total: ~7-8 weeks**
**Part 1 (Chat) + Part 2 Combined: ~12-14 weeks**
