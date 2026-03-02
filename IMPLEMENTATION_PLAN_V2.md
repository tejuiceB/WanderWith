# WanderWith — Implementation Plan v2

> **Created:** March 2, 2026
> **Version:** 1.0.1+7
> **Scope:** Security hardening, privacy expansion, AI intelligence, full notification engine, and polish features

---

## Pre-Plan: Codebase Audit Summary (What Already Exists)

Before planning new work, a deep audit revealed these features are **already fully implemented** and need NO work:

| Feature | Status | Location |
|---------|--------|----------|
| **@Mentions — detection** | ✅ DONE | `_detectMentionTrigger()` in `trip_chat_tab.dart` L226 |
| **@Mentions — dropdown overlay** | ✅ DONE | `_buildInputBar()` in `trip_chat_tab.dart` L2136 — filtered member list with avatars |
| **@Mentions — insert into text** | ✅ DONE | `_insertMention()` in `trip_chat_tab.dart` L263 |
| **@Mentions — parse user IDs** | ✅ DONE | `_parseMentionedUserIds()` in `trip_chat_tab.dart` L350 |
| **@Mentions — styled rendering** | ✅ DONE | `_buildRichText()` in `trip_chat_tab.dart` L3125 — bold + brand color |
| **@Mentions — DB storage** | ✅ DONE | `mentioned_user_ids` stored in message insert at L414 |
| **@Mentions — notification** | ✅ DONE | `"$senderName mentioned you in $tripName"` with type `chat_mention` in `notification_service.dart` L231 |
| **@WanderWith AI bot** | ✅ DONE | Triggers on `@wanderwith`, sends 10-msg context to Gemini |
| **Visa/Currency hidden for domestic** | ✅ DONE | `if (_isInternational)` guards on visa + currency rows in `trip_dashboard_screen.dart` L1221-1225 |
| **International vs domestic detection** | ✅ DONE | `countryNameToCode` mapping + comparison in `trip_dashboard_screen.dart` L710-725 |
| **International travel card** | ✅ DONE | Returns `SizedBox.shrink()` when `_internationalInfo == null` (L1280) |
| **Typing indicators** | ✅ DONE | Broadcast channel in `_setupRealtime()` |
| **Online presence** | ✅ DONE | Presence sync with `_onlineUserIds` tracking |
| **Read receipts** | ✅ DONE | `ChatService.markAsRead()` + `readReceiptsStream()` + `computeMessageStatus()` |
| **Reactions** | ✅ DONE | Optimistic UI + debounced DB + notification |
| **Reply-to messages** | ✅ DONE | Full reply UI + notification |
| **Edit/Delete messages** | ✅ DONE | With optimistic updates |
| **Image/Location/Document/Poll sharing** | ✅ DONE | All message types implemented |
| **Pinned messages** | ✅ DONE | `isPinned` field + UI |
| **Offline queue** | ✅ DONE | Isar-based `OfflineQueueService` with connectivity listener |
| **Real-time location sharing** | ✅ DONE | `LocationShareService` + `LiveLocationMap` widget |
| **Privacy settings** | ✅ DONE | Private account, post/trip visibility, follow requests, message privacy |
| **Blocked users** | ✅ DONE | Dedicated `BlockedUsersScreen` |
| **Change password** | ⚠️ PARTIAL | Works, but **no current password verification** |

---

## What Actually Needs To Be Built

Organized into **4 priority tiers:**

---

## TIER 1 — Critical (Security & Core UX) — ~2 days

### 1.1 Secure Password Change Flow

- **File:** `lib/screens/settings_screen.dart`
- **Current:** `_changePassword()` only asks for new + confirm. No current password verification.
- **Plan:**
  - Add "Current Password" field to the change password dialog
  - Before calling `authService.updatePassword()`, verify current password via `supabase.auth.signInWithPassword(email, currentPassword)`
  - If verification fails, show error "Current password is incorrect"
  - Only proceed with update if verification succeeds
- **Effort:** ~2 hours
- **DB changes:** None

### 1.2 Change Email Feature

- **File:** `lib/screens/settings_screen.dart` — new section in Account Info
- **Current:** Email shown as display-only. No way to change it.
- **Plan:**
  - Add "Change Email" option below email display row
  - Show dialog: Current password (for verification) + New email
  - Call `supabase.auth.updateUser(UserAttributes(email: newEmail))`
  - Supabase sends verification to new email automatically
  - Show info dialog: "Verification email sent to [new]. Click the link to confirm."
  - Update `profiles` table `email` field after verification (use a Supabase trigger or check on next login)
  - Handle edge case: email already in use → show error
- **Effort:** ~4 hours
- **DB changes:** None (Supabase auth handles it)

### 1.3 Delete Account — Re-authentication

- **File:** `lib/screens/settings_screen.dart`
- **Current:** Delete account only shows a confirmation dialog with text input. No password re-auth.
- **Plan:**
  - Add password field to delete confirmation dialog
  - Verify password via `signInWithPassword()` before proceeding
- **Effort:** ~1 hour
- **DB changes:** None

### 1.4 Emergency Numbers — Static Fallback Database

- **File:** `lib/screens/trip_dashboard_screen.dart`
- **Current:** All emergency numbers fall back to hardcoded `'112'` when AI data is unavailable.
- **Plan:**
  - Create a new file `lib/config/emergency_numbers.dart` with a static `Map<String, EmergencyNumbers>` keyed by country code
  - Cover top 50 countries with accurate police/ambulance/fire numbers
  - Emergency row fallback chain: **AI data → static database → `'112'` (last resort)**
  - Example: `'us': EmergencyNumbers(police: '911', ambulance: '911', fire: '911')`
  - Example: `'in': EmergencyNumbers(police: '100', ambulance: '108', fire: '101')`
  - Modify `_buildEmergencyInfoCard()` to check static DB before falling back to '112'
- **Effort:** ~3 hours (research + data entry for 50 countries)
- **DB changes:** None (static config file)

### 1.5 Settings Screen Polish

- **File:** `lib/screens/settings_screen.dart`
- **Current issues found:**
  - Footer says `"WanderWith v2.0.0"` — should show actual version dynamically
  - Missing Change Email (covered in 1.2)
  - Missing current password verify (covered in 1.1)
- **Plan:**
  - Use `package_info_plus` to dynamically display version: `"WanderWith v${packageInfo.version}+${packageInfo.buildNumber}"`
  - Reorder sections for better UX: Account Info → Security → Privacy → Appearance → Support → Danger Zone (delete)
  - Add "About" section with version, licenses, open-source credits
- **Effort:** ~3 hours

---

## TIER 2 — High Priority (Privacy & Social Safety) — ~5 days

### 2.1 Enhanced Privacy Controls

- **File:** `lib/screens/privacy_settings_screen.dart`
- **Current:** Has private account, post/trip visibility, follow requests, message privacy.
- **Missing controls to add:**

| Control | Type | Default | DB Column |
|---------|------|---------|-----------|
| Who can comment on posts | Dropdown: everyone / followers / nobody | everyone | `comment_privacy` |
| Hide like count on my posts | Toggle | off | `hide_like_count` |
| Hide my followers/following list | Toggle | off | `hide_followers_list` |
| Who can invite me to trips | Dropdown: everyone / followers / nobody | everyone | `trip_invite_privacy` |
| Restricted accounts | List screen | — | `restricted_users` (new table) |

- **Plan:**
  - Add new section "Content Controls" between existing Interactions and Safety
  - Add `comment_privacy`, `hide_like_count`, `hide_followers_list`, `trip_invite_privacy` to `UserProfile` model
  - Create `restricted_users` table (like blocked but lighter — can still see profile but can't interact)
  - Create `RestrictedUsersScreen` (similar to existing `BlockedUsersScreen`)
  - Update all consuming screens to respect new privacy flags
- **Effort:** ~3 days
- **DB changes:** 4 new columns to `profiles` + new `restricted_users` table

### 2.2 Report / Mute User

- **Current:** Block exists but no report or mute.
- **Plan:**
  - **Report:**
    - Create `reports` table (reporter_id, reported_user_id, reason, content_type, content_id, status, created_at)
    - Add "Report" option to user profile overflow menu and message long-press menu
    - Report reasons: Spam, Harassment, Inappropriate content, Fake account, Other
    - Submit report inserts to `reports` table — admin reviews via Supabase dashboard
  - **Mute:**
    - Create `muted_users` table (user_id, muted_user_id)
    - Muted users' messages still show in chat but notifications are suppressed
    - Add "Mute/Unmute" to user profile and chat member list
    - Filter muted users in `sendChatNotification()` logic
- **Files:** New `lib/screens/report_user_screen.dart`, modify `notification_service.dart`, modify `trip_chat_tab.dart`
- **Effort:** ~2 days
- **DB changes:** 2 new tables (`reports`, `muted_users`)

---

## TIER 3 — Medium Priority (Intelligence & AI) — ~5 days

### 3.1 AI-Generated Smart Checklists

- **File:** `lib/services/checklist_service.dart`
- **Current:** `generateDefaults()` returns hardcoded lists — 10 common + 7 international items.
- **Plan:**
  - Add `generateSmartChecklist()` method that calls Gemini AI with trip context:
    - Destination, duration, season/month, international flag, number of travelers
    - Prompt: "Generate a travel checklist for [N]-day trip to [destination] in [month]. Include items for: documents, packing (weather-appropriate), health, money, electronics, activities. Return as JSON array."
  - Parse AI response into `ChecklistItem` objects with categories
  - Cache generated checklist in `trip_checklists` table to avoid regenerating
  - Keep `generateDefaults()` as fallback if AI fails
  - Add "Regenerate" button in checklist UI
  - Add per-person assignments (who needs to bring what) — new `assigned_to` field
- **Effort:** ~2 days
- **DB changes:** Add `assigned_to uuid[]` column to `trip_checklist_items`, add `ai_generated boolean` flag

### 3.2 Weather Forecast Integration

- **Current:** No weather data anywhere in the app.
- **Plan:**
  - Integrate free weather API (recommend **WeatherAPI.com** — 1M calls/month free tier)
  - New file `lib/services/weather_service.dart`
  - Show weather card on trip dashboard between intelligence card and checklist card
  - Display: 7-day forecast for trip dates (or current weather if trip is ongoing)
  - Include: temperature, conditions, precipitation probability, icon
  - Cache weather data in `trip_metadata` with 6-hour refresh
  - For future trips: show historical averages for the destination + month
- **Effort:** ~2 days
- **New files:** `lib/services/weather_service.dart`, `lib/models/weather_forecast.dart`
- **DB changes:** Add `weather_data jsonb`, `weather_updated_at timestamptz` to `trip_metadata`

### 3.3 🔔 Complete AI-Powered Notification Engine

This is the crown jewel of the app. Not just basic push — a full 11-layer intelligent notification system that feels human, respects user preferences, and drives engagement without being spammy.

**Current state:** `notification_service.dart` has basic transactional notifications (chat, mention, reaction, reply, trip updates). All sent unconditionally with no frequency control, no localization, no smart timing, and no AI generation.

---

#### Layer A: Real-Time Transactional Notifications (Already Partially Exists)

Instant notifications for critical events. These are **non-negotiable** — always sent (unless user globally disables).

| Event | Current Status | Work Needed |
|-------|---------------|-------------|
| New chat message | ✅ EXISTS | None |
| @Mention in chat | ✅ EXISTS | None |
| Join request received | ✅ EXISTS | None |
| Join request approved/rejected | ✅ EXISTS | None |
| New follower | ✅ EXISTS | None |
| Like on post | ✅ EXISTS | None |
| Comment on post | ✅ EXISTS | None |
| Promoted to admin | ⚠️ PARTIAL | Add dedicated notification type |
| Removed from trip | ⚠️ PARTIAL | Add dedicated notification type |
| Reaction on message | ✅ EXISTS | None |
| Reply to message | ✅ EXISTS | None |

**Plan:**
- Add `admin_promoted` and `removed_from_trip` notification types to `NotificationType` enum
- Add corresponding insert calls in trip admin actions
- Deep link payload for every notification: `{"type": "...", "trip_id": "...", "deep_link": "/trip/123/chat"}`
- Every notification MUST open the exact relevant page when tapped — no generic landing
- **Effort:** ~3 hours

---

#### Layer B: Smart Engagement Notifications (Behavior-Based)

Sent based on trip state, user activity, and timing. Powered by a **Supabase Edge Function cron job** that runs every 6 hours.

| Trigger | Example Notification | Condition |
|---------|---------------------|----------|
| Trip approaching | "Your Goa trip starts in 3 days ✈️" | `start_date - now() <= 3 days` |
| Trip approaching | "Your Goa trip starts tomorrow! All set?" | `start_date - now() <= 1 day` |
| Empty itinerary day | "You haven't added plans for Day 2 yet" | Trip has days with no plan items |
| Trip going dead | "Rishikesh trip is getting quiet 👀 Add something" | No activity in trip for 5+ days, trip not completed |
| New posts from following | "3 new posts from people you follow" | Batch digest every 24h |
| Trip chat revival | "Rishikesh crew is planning something 👀" | Chat silent 2+ days then 5+ messages in 1 hour |
| Created trip, no members | "Your Goa trip needs crew! Share the invite" | Trip created 3+ days ago, only creator as member |
| Joined trip, not active | "Manali trip is active — don't miss the planning" | User joined but 0 messages/plans in 7 days |
| Likes travel posts, no trips | "You love travel posts... why not plan your own?" | 10+ post likes, 0 trips in last 60 days |

**Plan:**
- New file: `supabase/functions/smart-notifications/index.ts` — Supabase Edge Function
- Runs on cron schedule: `0 */6 * * *` (every 6 hours)
- Queries trip dates, user activity, chat timestamps
- Generates `smart_engagement` type notifications with specific subtypes
- Respects user notification preferences (check `notification_prefs` JSONB)
- **Anti-spam rule:** Max 1 engagement notification per user per 12 hours
- **Effort:** ~3 days
- **DB changes:** New `notification_log` table for dedup tracking

---

#### Layer C: Marketing / Emotional Notifications (AI-Generated)

Zomato/Swiggy-style emotional hooks. AI-written, personalized, never generic.

| Context | Example |
|---------|---------|
| Weekend approaching, no plans | "Weekend calling? Plan something spontaneous 🌍" |
| User inactive 14+ days | "Long time no trip... let's fix that." |
| Memories from past trips | "Memories fade. Trips don't. 📸" |
| Valentine's season + no trips | "Valentine's over? अब खुद के लिए घूम आओ 💛" |
| Post-festival Monday | "Back to routine? Start planning the next escape 🏔" |

**Plan:**
- Gemini AI generates notification text from a prompt with context:
  - User's last activity, preferred language, country, recent searches, trip mood
  - Prompt template: `"Generate a short, emotional travel notification in {language} for a user who {context}. Max 80 chars. Include 1 emoji. Tone: {tone}."`
- Store generated text in `scheduled_notifications` table with send time
- Supabase Edge Function cron picks up and sends at optimal time (see Layer I)
- **Anti-spam rule:** Max 1 marketing notification per 3 days
- **Auto-throttle:** If user ignores 5 consecutive marketing pushes → reduce to 1/week. Ignored 10 → stop until user re-engages.
- **Effort:** ~2 days
- **DB changes:** New `scheduled_notifications` table

---

#### Layer D: Regional Language Notifications 🌍

Every notification should speak the user's language — not just English.

**How it works:**

**Step 1 — Detect & Store User Language:**
```json
{
  "country": "India",
  "language": "hi",
  "preferred_notification_language": "auto"
}
```
- Sources: Device locale (`Platform.localeName`), user-selected preference in settings, profile country
- `auto` = use device locale. User can override to any supported language.
- Add `preferred_notification_language` field to `profiles` table

**Step 2 — Supported Languages (Phase 1):**

| Language | Code | Coverage |
|----------|------|----------|
| English | `en` | Default |
| Hindi | `hi` | India |
| Marathi | `mr` | India (Maharashtra) |
| Spanish | `es` | Latin America, Spain |
| French | `fr` | France, Africa |
| Japanese | `ja` | Japan |
| Portuguese | `pt` | Brazil |
| German | `de` | Germany, Austria |

**Step 3 — Translation Pipeline:**
- **Transactional notifications:** Pre-translated static templates stored in `lib/config/notification_templates.dart`
  - Example: `trip_starting_soon["hi"] = "आपकी {destination} ट्रिप {days} दिनों में शुरू होगी ✈️"`
  - Template variables: `{destination}`, `{days}`, `{name}`, `{trip_name}`
- **AI-generated notifications:** Gemini generates directly in target language
  - Prompt includes: `"Write in {language_name}. Use local slang if appropriate."`
- **Fallback:** If translation unavailable → English

**Step 4 — Language Selection UI:**
- Add to Settings > Notifications: "Notification Language" dropdown
- Options: Auto (device), English, Hindi, Marathi, Spanish, French, Japanese, Portuguese, German

**Effort:** ~3 days
**DB changes:** Add `preferred_notification_language text DEFAULT 'auto'` to `profiles`
**New file:** `lib/config/notification_templates.dart` — all template strings in all languages

---

#### Layer E: Festival & Seasonal Travel Notifications 🎉

Country-aware festival travel suggestions. Only sent if relevant to user's country.

**Plan:**
- Create `lib/config/festival_calendar.dart` — static map of festivals by country+date:

| Country | Festival | Date Range | Notification |
|---------|----------|------------|-------------|
| 🇮🇳 India | Diwali | Oct-Nov | "Diwali long weekend? Plan a getaway 🪔" |
| 🇮🇳 India | Holi | Mar | "Holi in Mathura? Book before it's too late 🎨" |
| 🇮🇳 India | New Year | Dec 28-Jan 1 | "Goa calling for New Year 🎊" |
| 🇺🇸 USA | Thanksgiving | Nov (4th Thu) | "Thanksgiving getaway ideas 🦃" |
| 🇺🇸 USA | Spring Break | Mar | "Spring break is coming — where to?" |
| 🇯🇵 Japan | Cherry Blossom | Mar-Apr | "Cherry blossom season is here 🌸" |
| 🇬🇧 UK | Bank Holiday | Various | "Bank holiday weekend trip? 🇬🇧" |
| 🇫🇷 France | Bastille Day | Jul 14 | "Long weekend — time for a French road trip 🇫🇷" |

- Supabase Edge Function checks festival calendar weekly
- Sends festival notification 7-10 days before the festival
- Only to users in the matching country
- AI personalizes the message based on user's travel history + language
- **Anti-spam:** Max 1 festival notification per festival. Skip if user already has a trip planned during that period.
- **Effort:** ~1.5 days
- **New file:** `lib/config/festival_calendar.dart`

---

#### Layer F: Trip Lifecycle Smart Notifications 📅

Automatic notifications tied to trip timeline — before, during, and after.

**Before Trip:**

| When | Notification |
|------|---------|
| 7 days before | "🧳 Packing reminder: {destination} in 1 week!" |
| 3 days before | "🌤 Weather alert: {destination} will be {temp}°{unit} — pack accordingly" |
| 1 day before | "🚨 Emergency info for {destination} is ready. Check the dashboard." |
| 1 day before | "📋 Checklist check: {unchecked_count} items still unchecked" |

**During Trip:**

| When | Notification |
|------|---------|
| Trip start day | "🎉 Your {destination} trip starts today! Have an amazing time" |
| Daily morning (8 AM local) | "📍 Day {n} in {destination}! Here's today's plan" (if itinerary exists) |
| Sunset time | "🌅 Sunset at {time} today in {destination}" (weather API data) |

**After Trip:**

| When | Notification |
|------|---------|
| Trip end + 1 day | "📸 Relive your {destination} memories" |
| Trip end + 3 days | "✍️ Share your trip experience — create a highlight post" |
| Trip end + 7 days | "⭐ Rate your {destination} trip and help others" |

**Plan:**
- Extend the Supabase Edge Function cron to check trip timelines
- Use trip `start_date`, `end_date`, destination timezone
- Weather data from WeatherAPI.com (reuse from 3.2)
- Sunset time from weather API response
- **Effort:** ~2 days
- **DB changes:** None (uses existing trip data + `notification_log` for dedup)

---

#### Layer G: Weather-Triggered Notifications 🌧️

Proactive weather alerts for upcoming and ongoing trips.

| Trigger | Notification |
|---------|-------------|
| Rain forecast during trip | "🌧️ Heavy rain expected during your Goa trip — plan indoor activities?" |
| Extreme heat | "🔥 {destination} hitting {temp}°C this week — stay hydrated!" |
| Cold snap | "❄️ It's going to be cold in {destination} — pack warm layers" |
| Perfect weather | "☀️ Weather in {destination} looks perfect for your trip!" |

**Plan:**
- Integrate with Weather API (reuse from 3.2)
- Check weather 3 days before trip + daily during trip
- Only alert on significant weather events (rain > 60%, temp > 40°C or < 5°C)
- AI writes the notification text with destination context
- **Effort:** ~1 day (mostly reuses weather service from 3.2)
- **DB changes:** None

---

#### Layer H: Notification User Controls 🎯

Users MUST have granular control. This builds trust.

**Settings > Notifications screen:**

| Category | Toggle | Default |
|----------|--------|---------|
| **Messages** | Chat messages from trips | ✅ ON |
| **Mentions** | @Mentions (forced on) | 🔒 ON (locked) |
| **Trip Updates** | Member joined/left, dates changed, admin changes | ✅ ON |
| **Likes & Comments** | Likes and comments on your posts | ✅ ON |
| **Follow Activity** | New followers | ✅ ON |
| **Trip Reminders** | Packing, weather, checklist, departure | ✅ ON |
| **Festival Alerts** | Festival travel suggestions | ✅ ON |
| **Travel Inspiration** | AI-generated travel nudges | ✅ ON |
| **Marketing** | Promotional messages | ✅ ON |
| **Weather Alerts** | Weather warnings for trips | ✅ ON |
| **Notification Language** | Auto / English / Hindi / Marathi / ... | Auto |
| **Quiet Hours** | Do Not Disturb schedule | ❌ OFF |

**Plan:**
- New screen: `lib/screens/notification_preferences_screen.dart`
- Store as JSONB in `profiles.notification_prefs`:
  ```json
  {
    "messages": true,
    "mentions": true,
    "trip_updates": true,
    "likes_comments": true,
    "follow_activity": true,
    "trip_reminders": true,
    "festival_alerts": true,
    "travel_inspiration": true,
    "marketing": true,
    "weather_alerts": true,
    "quiet_hours_enabled": false,
    "quiet_hours_start": "22:00",
    "quiet_hours_end": "08:00"
  }
  ```
- Every notification send method checks user prefs before inserting
- Quiet Hours: If `quiet_hours_enabled` and current user-local time is in range → delay notification to `quiet_hours_end`
- **Effort:** ~2 days
- **DB changes:** `notification_prefs jsonb` in profiles (already planned)

---

#### Layer I: Smart Notification Timing ⏰

Don't send at 3 AM. Send when the user actually engages.

**Plan:**
- Track `last_active_at` timestamp on every app open (already tracked via auth session)
- Compute user's **active window** from last 30 days of `last_active_at` data:
  - If user mostly opens app 8-10 PM → optimal send time = 7:30 PM
  - If user mostly opens app 7-9 AM → optimal send time = 7:00 AM
- New `optimal_send_hour` computed field in profiles (updated weekly by Edge Function)
- Non-transactional notifications (engagement, marketing, festival, weather) are **scheduled** at the user's optimal hour
- Transactional notifications (chat, mention, join request) → always instant
- Use user's timezone (from `profiles.timezone` or device locale) for local time calculation
- **Fallback:** If no activity data → default to 9:00 AM user-local
- **Effort:** ~1.5 days
- **DB changes:** Add `optimal_send_hour int`, `timezone text` to profiles

---

#### Layer J: Memory Anniversary & Emotional Hooks 💛

Powerful re-engagement through nostalgia.

| Trigger | Notification |
|---------|-------------|
| 1 year since trip | "🌊 1 year ago you were in Goa — want to go again?" |
| 6 months since trip | "Half a year since Rishikesh... time for another adventure?" |
| Trip photo memories | "📸 Look back at your Manali trip photos" |
| First trip anniversary | "🎂 Your very first WanderWith trip was 1 year ago today!" |

**Plan:**
- Supabase Edge Function checks: `trips.end_date` where `end_date + 365 days = today` or `+ 180 days = today`
- AI generates nostalgic notification in user's preferred language
- Include trip cover image in rich notification (Android BigPictureStyle)
- Only send for trips where user was a member
- **Effort:** ~1 day
- **DB changes:** None (uses existing trip dates)

---

#### Layer K: Advanced AI Features (Future Roadmap) 🚀

These are powerful but lower priority. Build foundation now, enable later.

**K1 — AI Travel Mood Detection:**
- Analyze: posts liked, trips searched, chat keywords, trip types
- Classify user mood: Adventure / Relax / Party / Solo / Couple / Family
- Send mood-matched notifications: "Adventure seekers love Rishikesh this time of year 🌊"
- Store mood in `profiles.travel_mood text`
- **Effort:** ~2 days

**K2 — Gamified Notifications:**
- "You planned 3 trips this year 🏆"
- "Top Explorer badge unlocked"
- "You've visited 5 states — next milestone: 10!"
- Requires: `user_stats` table tracking trip count, states visited, badges earned
- **Effort:** ~2 days

**K3 — Price Drop Alerts (Future — when booking integrated):**
- "Flight to Bali just dropped 18% ✈️"
- Requires flight/hotel API integration — not in current scope
- **Effort:** TBD

**K4 — Location-Based Push (Future):**
- "Looks like you're at the airport 👀 Start a trip?"
- Uses geofencing — requires background location permission
- Privacy-sensitive — opt-in only
- **Effort:** TBD

---

#### Notification Technical Structure

**Push delivery:** Firebase Cloud Messaging (FCM) — required for reliable Android push in background.

**Notification payload structure (every notification):**
```json
{
  "type": "trip_message",
  "subtype": "chat_mention",
  "trip_id": "abc-123",
  "sender_id": "def-456",
  "deep_link": "/trip/abc-123/chat",
  "title": "Tejas mentioned you in Goa Trip",
  "body": "@Tejas Hey are you coming tomorrow?",
  "image_url": null,
  "language": "en",
  "priority": "high",
  "created_at": "2026-03-02T14:30:00Z"
}
```

**Deep link routing:**
- Every notification payload includes `deep_link`
- On tap → app parses deep link → navigates to exact screen
- Examples: `/trip/{id}/chat`, `/trip/{id}/dashboard`, `/profile/{id}`, `/post/{id}`
- **NEVER** send a notification without a deep link

**Notification channels (Android):**

| Channel ID | Name | Importance | Vibrate | Sound |
|------------|------|------------|---------|-------|
| `wanderwith_messages` | Messages | HIGH | Yes | Default |
| `wanderwith_mentions` | Mentions | MAX | Yes | Custom |
| `wanderwith_trips` | Trip Updates | HIGH | Yes | Default |
| `wanderwith_social` | Social | DEFAULT | No | Silent |
| `wanderwith_reminders` | Reminders | DEFAULT | Yes | Default |
| `wanderwith_marketing` | Inspiration | LOW | No | Silent |

**Anti-spam rules (enforced server-side):**

| Category | Frequency Limit |
|----------|----------------|
| Transactional (chat, mention, join) | Unlimited |
| Engagement (trip reminders, activity) | Max 1 per 12 hours |
| Marketing (AI-generated, festivals) | Max 1 per 3 days |
| Auto-throttle | If 5 marketing ignored → 1/week. If 10 ignored → stop. |
| Quiet hours | Non-transactional delayed to `quiet_hours_end` |

---

#### Notification System — Effort Summary

| Layer | Description | Effort | Priority |
|-------|-------------|--------|----------|
| A | Real-time transactional (partial exists) | ~3 hours | 🔴 Critical |
| B | Smart engagement (cron + behavior) | ~3 days | 🔴 Critical |
| C | AI-generated marketing | ~2 days | 🟠 High |
| D | Regional language support | ~3 days | 🟠 High |
| E | Festival & seasonal | ~1.5 days | 🟡 Medium |
| F | Trip lifecycle (before/during/after) | ~2 days | 🔴 Critical |
| G | Weather-triggered | ~1 day | 🟡 Medium |
| H | User controls & preferences | ~2 days | 🔴 Critical |
| I | Smart timing (optimal hour) | ~1.5 days | 🟡 Medium |
| J | Memory anniversary | ~1 day | 🟢 Nice to have |
| K | Advanced AI (mood, gamified) | ~4 days | 🟢 Future |
| **Total notification engine** | | **~21 days** | |

---

#### Notification System — Database Schema

```sql
-- Notification preferences in profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS notification_prefs jsonb DEFAULT '{
  "messages": true, "mentions": true, "trip_updates": true,
  "likes_comments": true, "follow_activity": true, "trip_reminders": true,
  "festival_alerts": true, "travel_inspiration": true, "marketing": true,
  "weather_alerts": true, "quiet_hours_enabled": false,
  "quiet_hours_start": "22:00", "quiet_hours_end": "08:00"
}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS preferred_notification_language text DEFAULT 'auto';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS optimal_send_hour int DEFAULT 9;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS user_timezone text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS travel_mood text;

-- Notification log for deduplication & anti-spam
CREATE TABLE IF NOT EXISTS notification_log (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type text NOT NULL,     -- 'transactional', 'engagement', 'marketing', 'festival'
  subtype text,                        -- 'trip_starting', 'weather_alert', etc.
  trip_id uuid,
  sent_at timestamptz DEFAULT now(),
  opened boolean DEFAULT false,
  opened_at timestamptz,
  CONSTRAINT unique_dedup UNIQUE(user_id, subtype, trip_id, (sent_at::date))
);

-- Scheduled notifications (for delayed/optimal-time sends)
CREATE TABLE IF NOT EXISTS scheduled_notifications (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL,
  type text NOT NULL,
  subtype text,
  trip_id uuid,
  deep_link text,
  image_url text,
  language text DEFAULT 'en',
  scheduled_for timestamptz NOT NULL,
  sent boolean DEFAULT false,
  sent_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Index for cron job performance
CREATE INDEX IF NOT EXISTS idx_scheduled_pending 
  ON scheduled_notifications(scheduled_for) 
  WHERE sent = false;
CREATE INDEX IF NOT EXISTS idx_notification_log_user 
  ON notification_log(user_id, notification_type, sent_at);
```

#### Notification System — New Files

| File | Purpose |
|------|---------|
| `lib/services/smart_notification_service.dart` | Orchestrates all notification layers, checks prefs, handles language |
| `lib/services/fcm_service.dart` | Firebase Cloud Messaging setup, token management, foreground/background handling |
| `lib/config/notification_templates.dart` | Pre-translated notification templates in all supported languages |
| `lib/config/festival_calendar.dart` | Country → festival → date mapping for festival notifications |
| `lib/screens/notification_preferences_screen.dart` | Full user control UI with category toggles + quiet hours + language picker |
| `lib/models/scheduled_notification.dart` | Model for scheduled notification records |
| `supabase/functions/smart-notifications/index.ts` | Edge Function: cron-based smart notification engine (engagement, festival, lifecycle, timing) |
| `supabase/functions/send-push/index.ts` | Edge Function: FCM push sender (called by other functions) |

---

## TIER 4 — Nice to Have (Polish & Enhancement) — ~4 days

### 4.1 Chat Mention Improvements

- **File:** `lib/widgets/trip_chat_tab.dart`
- **Current:** @mentions fully work but the regex `@(\S+(?:\s\S+)?)` is greedy — may match non-mentions.
- **Plan:**
  - Improve mention regex to only match known display names from `_memberProfiles`
  - Add tap handler on mention spans in `_buildRichText()` — tap @name opens that user's profile
  - Add `@everyone` mention support (notifies all trip members)
- **Effort:** ~4 hours

### 4.2 Message Search in Chat

- **Current:** No way to search through chat history.
- **Plan:**
  - Add search icon in chat app bar
  - Slide-down search field with live filtering
  - Query: `supabase.from('trip_messages').select().eq('trip_id', tripId).ilike('content', '%query%').order('created_at')`
  - Show results with message preview + timestamp + sender
  - Tap result scrolls to that message in the chat list
- **Effort:** ~1 day
- **DB changes:** None (use existing `ilike` query)

### 4.3 Trip Templates

- **Current:** Each trip starts from scratch.
- **Plan:**
  - After a trip is completed, offer "Save as Template"
  - Template stores: checklist items, itinerary structure, budget categories, duration
  - New trip creation: "Start from template" option
  - Store in `trip_templates` table
- **Effort:** ~1.5 days
- **DB changes:** New `trip_templates` table

### 4.4 Export Trip Data

- **Current:** No export capability.
- **Plan:**
  - Add "Export Trip" in trip overflow menu
  - Generate PDF with: itinerary, checklist, expense summary, member list, emergency info
  - Use `pdf` Flutter package
  - Also offer JSON export for data portability
  - Share via system share sheet
- **Effort:** ~1.5 days
- **New dependency:** `pdf: ^3.10.0`

---

## Implementation Sequence (Recommended Order)

```
Phase 1 — Security & Stability (Week 1)
├── 1.1 Secure password change              [2 hrs]
├── 1.2 Change email feature                 [4 hrs]
├── 1.3 Delete account re-auth               [1 hr]
├── 1.4 Emergency numbers database           [3 hrs]
└── 1.5 Settings screen polish               [3 hrs]
     Total: ~13 hours (2 days)

Phase 2 — Privacy & Safety (Week 1-2)
├── 2.1 Enhanced privacy controls            [3 days]
└── 2.2 Report / Mute user                  [2 days]
     Total: ~5 days

Phase 3A — Intelligence & AI (Week 2-3)
├── 3.1 AI-generated checklists              [2 days]
└── 3.2 Weather forecast                     [2 days]
     Total: ~4 days

Phase 3B — Notification Engine Core (Week 3-5)
├── 3.3-A Transactional fixes                [3 hrs]
├── 3.3-H User controls & preferences       [2 days]
├── 3.3-F Trip lifecycle notifications       [2 days]
├── 3.3-B Smart engagement (cron + behavior) [3 days]
├── 3.3-G Weather-triggered notifications    [1 day]
     Total: ~8.5 days

Phase 3C — Notification Engine Advanced (Week 5-7)
├── 3.3-D Regional language support          [3 days]
├── 3.3-C AI-generated marketing             [2 days]
├── 3.3-E Festival & seasonal               [1.5 days]
├── 3.3-I Smart timing (optimal hour)        [1.5 days]
├── 3.3-J Memory anniversary                 [1 day]
     Total: ~9 days

Phase 4 — Polish (Week 7-8)
├── 4.1 Chat mention improvements            [4 hrs]
├── 4.2 Message search                       [1 day]
├── 4.3 Trip templates                       [1.5 days]
└── 4.4 Export trip data                     [1.5 days]
     Total: ~4 days

Phase 5 — Future Roadmap (Post-Launch)
├── 3.3-K1 AI travel mood detection          [2 days]
├── 3.3-K2 Gamified notifications            [2 days]
├── 3.3-K3 Price drop alerts                 [TBD]
└── 3.3-K4 Location-based push               [TBD]
     Total: ~4+ days
```

---

## Database Migration — All Schema Changes

All SQL needed across all tiers in a single migration:

```sql
-- ============================================================
-- PHASE 2: Privacy Enhancements
-- ============================================================

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS comment_privacy text DEFAULT 'everyone';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS hide_like_count boolean DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS hide_followers_list boolean DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS trip_invite_privacy text DEFAULT 'everyone';

CREATE TABLE IF NOT EXISTS restricted_users (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  restricted_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, restricted_user_id)
);

CREATE TABLE IF NOT EXISTS muted_users (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  muted_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, muted_user_id)
);

CREATE TABLE IF NOT EXISTS reports (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  reported_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  reason text NOT NULL,
  content_type text,        -- 'user', 'message', 'post', 'trip'
  content_id text,
  description text,
  status text DEFAULT 'pending',  -- pending, reviewed, resolved, dismissed
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- PHASE 3A: AI Checklists + Weather
-- ============================================================

ALTER TABLE trip_checklist_items ADD COLUMN IF NOT EXISTS assigned_to uuid[];
ALTER TABLE trip_checklist_items ADD COLUMN IF NOT EXISTS ai_generated boolean DEFAULT false;

ALTER TABLE trip_metadata ADD COLUMN IF NOT EXISTS weather_data jsonb;
ALTER TABLE trip_metadata ADD COLUMN IF NOT EXISTS weather_updated_at timestamptz;

-- ============================================================
-- PHASE 3B+3C: Full Notification Engine
-- ============================================================

-- Profile columns for notification system
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS notification_prefs jsonb DEFAULT '{
  "messages": true, "mentions": true, "trip_updates": true,
  "likes_comments": true, "follow_activity": true, "trip_reminders": true,
  "festival_alerts": true, "travel_inspiration": true, "marketing": true,
  "weather_alerts": true, "quiet_hours_enabled": false,
  "quiet_hours_start": "22:00", "quiet_hours_end": "08:00"
}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS preferred_notification_language text DEFAULT 'auto';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS optimal_send_hour int DEFAULT 9;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS user_timezone text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token text;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS travel_mood text;

-- Notification log for deduplication & anti-spam tracking
CREATE TABLE IF NOT EXISTS notification_log (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type text NOT NULL,     -- 'transactional', 'engagement', 'marketing', 'festival'
  subtype text,                        -- 'trip_starting', 'weather_alert', etc.
  trip_id uuid,
  sent_at timestamptz DEFAULT now(),
  opened boolean DEFAULT false,
  opened_at timestamptz,
  CONSTRAINT unique_dedup UNIQUE(user_id, subtype, trip_id, (sent_at::date))
);

-- Scheduled notifications for delayed/optimal-time sends
CREATE TABLE IF NOT EXISTS scheduled_notifications (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL,
  type text NOT NULL,
  subtype text,
  trip_id uuid,
  deep_link text,
  image_url text,
  language text DEFAULT 'en',
  scheduled_for timestamptz NOT NULL,
  sent boolean DEFAULT false,
  sent_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_scheduled_pending 
  ON scheduled_notifications(scheduled_for) 
  WHERE sent = false;
CREATE INDEX IF NOT EXISTS idx_notification_log_user 
  ON notification_log(user_id, notification_type, sent_at);
CREATE INDEX IF NOT EXISTS idx_notification_log_dedup 
  ON notification_log(user_id, subtype, trip_id);

-- ============================================================
-- PHASE 4: Templates
-- ============================================================

CREATE TABLE IF NOT EXISTS trip_templates (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_by uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  duration_days int,
  checklist_items jsonb,
  itinerary_structure jsonb,
  budget_categories jsonb,
  tags text[],
  is_public boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
```

---

## New Files to Create

| File | Purpose | Phase |
|------|---------|-------|
| `lib/config/emergency_numbers.dart` | Static emergency number database for 50+ countries | 1 |
| `lib/screens/report_user_screen.dart` | Report user/content flow | 2 |
| `lib/screens/restricted_users_screen.dart` | Manage restricted accounts | 2 |
| `lib/services/weather_service.dart` | Weather API integration | 3A |
| `lib/models/weather_forecast.dart` | Weather data model | 3A |
| `lib/services/smart_notification_service.dart` | Orchestrates all notification layers, checks prefs, handles language | 3B |
| `lib/services/fcm_service.dart` | Firebase Cloud Messaging setup, token management, background handling | 3B |
| `lib/screens/notification_preferences_screen.dart` | Full user control UI — category toggles, quiet hours, language picker | 3B |
| `lib/config/notification_templates.dart` | Pre-translated notification templates in all supported languages | 3C |
| `lib/config/festival_calendar.dart` | Country → festival → date mapping for festival notifications | 3C |
| `lib/models/scheduled_notification.dart` | Model for scheduled notification records | 3B |
| `supabase/functions/smart-notifications/index.ts` | Edge Function: cron-based smart notification engine | 3B |
| `supabase/functions/send-push/index.ts` | Edge Function: FCM push sender | 3B |

## Files to Modify

| File | Changes | Phase |
|------|---------|-------|
| `lib/screens/settings_screen.dart` | Secure password, change email, re-auth delete, dynamic version | 1 |
| `lib/screens/trip_dashboard_screen.dart` | Static emergency fallback, weather card | 1, 3A |
| `lib/screens/privacy_settings_screen.dart` | New privacy controls | 2 |
| `lib/models/user_profile.dart` | New privacy fields + notification prefs + language + timezone + FCM token + mood | 2, 3B |
| `lib/services/notification_service.dart` | Mute check, preference check, FCM integration, deep links, anti-spam, channels | 2, 3B |
| `lib/widgets/trip_chat_tab.dart` | Improved mention regex, tap handler, search | 4 |
| `lib/services/checklist_service.dart` | AI generation, assignments | 3A |
| `lib/main.dart` | FCM initialization, token refresh listener | 3B |
| `android/app/build.gradle` | Firebase Messaging dependency | 3B |
| `android/app/src/main/AndroidManifest.xml` | FCM service, notification channels | 3B |

---

## Key Architectural Decisions

1. **Weather API choice:** WeatherAPI.com (1M calls/month free) over OpenWeatherMap (1,000 calls/day free). Far more generous free tier.

2. **Notification preferences storage:** JSONB in `profiles` (simpler, fewer queries, always loaded with user profile) over a separate table.

3. **Report handling:** No admin panel in the app. Reports go to Supabase `reports` table — review via Supabase Dashboard or a future admin web panel. Set up a Supabase Edge Function to email `wanderwithplan@gmail.com` on new reports.

4. **Emergency numbers data source:** Statically compiled in the app (fast, offline-capable) then enriched by AI (more detail but may be inaccurate). Static data is the **source of truth** for critical numbers like 911/112/100.

5. **Push notification delivery:** Firebase Cloud Messaging (FCM) — required for reliable background push on Android. Supabase alone cannot deliver push when app is killed. FCM token stored in `profiles.fcm_token`, refreshed on every app start.

6. **Notification generation:** Two-track system:
   - **Transactional:** Pre-translated static templates (`notification_templates.dart`) with variable interpolation. Fast, no AI call.
   - **AI-generated:** Gemini generates personalized text for marketing/engagement/festival. Cached in `scheduled_notifications` table. Slower but human-feeling.

7. **Smart timing architecture:** Non-transactional notifications go into `scheduled_notifications` table with `scheduled_for` set to user's optimal hour. A Supabase Edge Function cron (every 15 min) picks up and sends pending notifications whose `scheduled_for <= now()`. This decouples generation from delivery.

8. **Anti-spam enforcement:** All frequency limits enforced server-side via `notification_log` table. The Edge Function checks recent sends before inserting. Client-side preferences are a soft filter; server-side log is the hard filter.

9. **Language pipeline:** Transactional = pre-translated templates (instant). AI-generated = Gemini writes directly in target language (1-2s latency, acceptable for scheduled sends). Fallback = English if language unsupported.

10. **Deep link contract:** Every notification MUST include `deep_link` field. App registers a `_handleDeepLink()` in `main.dart` that parses the path and pushes the correct route. No notification should ever land on the home screen generically.

---

## Total Estimated Effort

| Phase | Duration | Priority |
|-------|----------|----------|
| Phase 1 — Security & Stability | ~2 days | 🔴 Critical |
| Phase 2 — Privacy & Safety | ~5 days | 🟠 High |
| Phase 3A — Intelligence & AI | ~4 days | 🟡 Medium |
| Phase 3B — Notification Engine Core | ~8.5 days | 🔴 Critical |
| Phase 3C — Notification Engine Advanced | ~9 days | 🟠 High |
| Phase 4 — Polish & Enhancement | ~4 days | 🟢 Nice to have |
| Phase 5 — Future (Mood, Gamification) | ~4+ days | 🟢 Future |
| **Total** | **~36.5 days** | |

---

## Summary

Many features originally thought to be missing (@mentions, typing indicators, read receipts, visa/currency hiding, real-time location, offline sync) are **already fully implemented**. The actual remaining work focuses on:

- **Security hardening** — password/email flows, re-authentication
- **Privacy expansion** — new controls, report/mute/restrict
- **AI intelligence** — weather forecasts, smart checklists
- **🔔 Full notification engine** — 11-layer AI-powered system covering transactional, smart engagement, AI-generated marketing, regional language support, festival/seasonal alerts, trip lifecycle notifications, weather triggers, granular user controls, smart timing, memory anniversaries, and future mood/gamification features. This is the single largest feature scope (~21 days) and will transform the app from "sends basic alerts" to "feels like it knows you personally"
- **Polish** — search, templates, export, mention improvements

