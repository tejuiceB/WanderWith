# WanderWith — Advanced Travel Product Implementation Plan

> **Scope**: Flutter Android app only  
> **Baseline**: Current codebase as of March 2026  
> **Approach**: Phased, incremental — each phase ships a usable improvement

---

## Table of Contents

1. [Phase 1 — Gallery Performance Fix](#phase-1--gallery-performance-fix-priority-critical)
2. [Phase 2 — Polls Permission Control](#phase-2--polls-permission-control-priority-high)
3. [Phase 3 — AI Plan Deduplication](#phase-3--ai-plan-deduplication-priority-high)
4. [Phase 4 — Reset Password Deep Link Fix](#phase-4--reset-password-deep-link-fix-priority-high)
5. [Phase 5 — Trip Intelligence Card (Overview Tab)](#phase-5--trip-intelligence-card-overview-tab)
6. [Phase 6 — International Travel Info (Visa + Embassy)](#phase-6--international-travel-info-visa--embassy)
7. [Phase 7 — Enhanced Place Detail Screen](#phase-7--enhanced-place-detail-screen)
8. [Phase 8 — AI Guide Memory System](#phase-8--ai-guide-memory-system)
9. [Phase 9 — Offline Mode (Full Architecture)](#phase-9--offline-mode-full-architecture)
10. [Phase 10 — Expense Split System](#phase-10--expense-split-system)
11. [Phase 11 — Smart Travel Checklist](#phase-11--smart-travel-checklist)
12. [Phase 12 — Budget Analytics](#phase-12--budget-analytics)
13. [Phase 13 — Emergency Info Section](#phase-13--emergency-info-section)
14. [Phase 14 — Future Advanced Features](#phase-14--future-advanced-features)
15. [New Supabase Tables Summary](#new-supabase-tables-summary)
16. [New Files Summary](#new-files-summary)
17. [Dependency Changes Summary](#dependency-changes-summary)

---

## Phase 1 — Gallery Performance Fix (Priority: CRITICAL)

**Problem**: 18-27 images cause lag. Full-resolution images uploaded, no lazy loading optimization, parallel upload with no concurrency limit.

**Current state**:
- `ImagePicker(imageQuality: 70)` is the only compression (JPEG quality reduction at pick time)
- `CachedNetworkImage` already used in `_GalleryGridTile` for display
- `SliverGrid` with `SliverGridDelegateWithFixedCrossAxisCount` already used
- Uploads via `Future.wait(images.map(...))` — no batching
- No thumbnail generation, no EXIF stripping, no max-dimension constraint

### Step 1.1 — Compress images before upload

**File**: `lib/services/trip_service.dart` → `uploadPhotos()`

**What to do**:
1. After `ImagePicker` returns files, compress each with `flutter_image_compress` before upload
2. Target: max width 1920px, quality 80 (high enough for full-screen viewing, small enough for fast load)
3. Generate a thumbnail version: max width 400px, quality 60 (for grid view)
4. Upload BOTH versions to separate storage paths

**Implementation**:
```dart
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<File> _compressImage(File file, {int maxWidth = 1920, int quality = 80}) async {
  final dir = await getTemporaryDirectory();
  final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg');
  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    minWidth: maxWidth,
    quality: quality,
    format: CompressFormat.jpeg,
  );
  return File(result!.path);
}

Future<File> _generateThumbnail(File file) async {
  return _compressImage(file, maxWidth: 400, quality: 60);
}
```

**Upload flow change**:
```dart
// Current:  upload raw file
// New:      compress → upload full + upload thumbnail
final compressed = await _compressImage(File(image.path));
final thumbnail = await _generateThumbnail(File(image.path));

final fullPath = '$uid/${timestamp}_full_$filename';
final thumbPath = '$uid/${timestamp}_thumb_$filename';

await storage.from('trip_photos').upload(fullPath, compressed);
await storage.from('trip_photos').upload(thumbPath, thumbnail);

// Store both URLs in photos table
final fullUrl = storage.from('trip_photos').getPublicUrl(fullPath);
final thumbUrl = storage.from('trip_photos').getPublicUrl(thumbPath);
```

**DB change**: Add `thumbnail_url` column to `photos` table:
```sql
ALTER TABLE photos ADD COLUMN thumbnail_url text;
```

### Step 1.2 — Use thumbnail in grid, full image in viewer

**File**: `lib/screens/trip_dashboard_screen.dart` → `_GalleryGridTile`

**What to do**:
- In grid view: use `photo['thumbnail_url'] ?? photo['url']` (fallback for old photos without thumbnails)
- In `GalleryViewer` (full-screen): keep using `photo['url']` (full res)
- Add `memCacheWidth: 400` to grid `CachedNetworkImage`
- Add `memCacheWidth: 1080` to viewer `CachedNetworkImage`

```dart
// Grid tile
CachedNetworkImage(
  imageUrl: photo['thumbnail_url'] ?? photo['url'],
  memCacheWidth: 400,
  placeholder: (ctx, url) => shimmerWidget(),
  errorWidget: (ctx, url, err) => errorPlaceholder(),
  fit: BoxFit.cover,
)

// Full viewer
CachedNetworkImage(
  imageUrl: photo['url'],
  memCacheWidth: 1080,
  placeholder: (ctx, url) => loadingIndicator(),
)
```

### Step 1.3 — Batch uploads with concurrency limit

**File**: `lib/services/trip_service.dart` → `uploadPhotos()`

**What to do**: Replace `Future.wait(all)` with batched uploads (3 at a time):

```dart
Future<void> uploadPhotos(String tripId, List<XFile> images, {Function(int, int)? onProgress}) async {
  const batchSize = 3;
  int completed = 0;

  for (int i = 0; i < images.length; i += batchSize) {
    final batch = images.skip(i).take(batchSize).toList();
    await Future.wait(batch.map((image) async {
      try {
        final compressed = await _compressImage(File(image.path));
        final thumbnail = await _generateThumbnail(File(image.path));
        // ... upload both, insert DB row ...
        completed++;
        onProgress?.call(completed, images.length);
      } catch (e) {
        debugPrint('Upload failed: $e');
      }
    }));
  }
}
```

### Step 1.4 — Optimize SliverGrid performance flags

**File**: `lib/screens/trip_dashboard_screen.dart` → `_GalleryTab`

**What to do**:
- Add `addAutomaticKeepAlives: false` and `addRepaintBoundaries: true` to `SliverGrid`
- These prevent offscreen tiles from staying alive (reduces memory)

```dart
SliverGrid(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 1,
  ),
  delegate: SliverChildBuilderDelegate(
    (context, index) => _GalleryGridTile(...),
    childCount: photos.length,
    addAutomaticKeepAlives: false,
    addRepaintBoundaries: true,
  ),
)
```

### Step 1.5 — Enable Supabase Storage CDN (Manual)

**Action**: In Supabase Dashboard → Storage → Settings → Enable CDN for `trip_photos` bucket

This is a dashboard toggle, not code. CDN caches images at edge nodes globally.

### Files modified:
| File | Changes |
|---|---|
| `lib/services/trip_service.dart` | Compress + thumbnail + batched uploads |
| `lib/screens/trip_dashboard_screen.dart` | Thumbnail URL in grid, memCacheWidth, SliverGrid flags |
| `pubspec.yaml` | Add `path_provider` (if not present), `path` (if not present) |
| `sql/` | `ALTER TABLE photos ADD COLUMN thumbnail_url text;` |

### Dependencies to add:
- `flutter_image_compress` already in `pubspec.yaml` ✅
- `path_provider` already in `pubspec.yaml` ✅
- `path` — add if not present

### Testing:
1. Upload 10+ photos → verify compressed size < 500KB each
2. Check grid loads instantly with thumbnails
3. Full-screen viewer still shows high-quality images
4. Verify old photos (no thumbnail_url) still display

---

## Phase 2 — Polls Permission Control (Priority: HIGH)

**Problem**: Any trip member can create polls. Should be owner/admin only.

**Current state**:
- FAB "New Poll" shown to all members (only guarded by `widget.trip.isDead`)
- `isAdmin` computed at line ~2700 but never used to gate poll creation
- RLS: only `created_by` can manage their own polls, no admin-level insert policy

### Step 2.1 — Frontend: Gate "New Poll" button

**File**: `lib/screens/trip_dashboard_screen.dart` → `_PollsTab` build method

**What to do**: Wrap FAB in admin/owner check:

```dart
// Current
floatingActionButton: widget.trip.isDead ? null : FloatingActionButton.extended(...)

// New
final isOwner = widget.trip.createdBy == Supabase.instance.client.auth.currentUser?.id;
final isAdmin = widget.trip.adminIds.contains(Supabase.instance.client.auth.currentUser?.id);
final canCreatePoll = isOwner || isAdmin;

floatingActionButton: (widget.trip.isDead || !canCreatePoll) ? null : FloatingActionButton.extended(...)
```

### Step 2.2 — Backend: Supabase RLS policy

**SQL migration**:
```sql
-- Drop existing insert policy on trip_polls if overly permissive
DROP POLICY IF EXISTS "Insert trip polls" ON trip_polls;

-- New policy: only owner or admin can insert polls
CREATE POLICY "Only owner or admin can insert polls"
ON trip_polls
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM trips
    WHERE trips.id = trip_polls.trip_id
    AND (
      trips.created_by = auth.uid()
      OR (trips.metadata->>'adminIds')::jsonb ? auth.uid()::text
    )
  )
);
```

**Note**: `adminIds` is stored in `trips.metadata` JSONB, not a separate column. The `?` operator checks if the array contains the value.

### Step 2.3 — Show info message for non-admin members

**File**: `lib/screens/trip_dashboard_screen.dart` → `_PollsTab`

If no polls exist and user is not admin, show:
```dart
if (polls.isEmpty && !canCreatePoll)
  Center(child: Text("No polls yet. Only trip admins can create polls."))
```

### Files modified:
| File | Changes |
|---|---|
| `lib/screens/trip_dashboard_screen.dart` | FAB permission check + info message |
| `sql/polls_permission.sql` | RLS policy migration |

### Testing:
1. Login as regular member → "New Poll" FAB should not appear
2. Login as admin/owner → "New Poll" FAB visible
3. Try API-level insert as regular member → should be rejected by RLS
4. Verify existing polls still render for all members

---

## Phase 3 — AI Plan Deduplication (Priority: HIGH)

**Problem**: AI-generated plan can include places already in the itinerary. No check against existing places.

**Current state**:
- `PlanProvider.generatePlan()` calls `GeminiService.generateTripPlan(trip)` → returns full plan
- `PlanService.saveTripPlan()` does full wipe-and-replace (DELETE all → INSERT new)
- `PlanService.addPlace()` is a simple INSERT with no duplicate check
- No comparison by `google_place_id`

### Step 3.1 — Dedup during AI plan generation

**File**: `lib/providers/plan_provider.dart` → `generatePlan()`

**What to do**: After AI generates places and Google Places enrichment resolves `google_place_id` values, dedup before saving:

```dart
// In generatePlan(), after enrichment loop:
final Set<String> seenPlaceIds = {};
for (final day in generatedDays) {
  day.places.removeWhere((place) {
    if (place.googlePlaceId != null && seenPlaceIds.contains(place.googlePlaceId)) {
      return true; // Remove duplicate
    }
    if (place.googlePlaceId != null) {
      seenPlaceIds.add(place.googlePlaceId!);
    }
    return false;
  });
}
```

### Step 3.2 — Dedup during manual place add

**File**: `lib/services/plan_service.dart` → `addPlace()`

**What to do**: Before inserting, check if a place with same `google_place_id` exists in the trip:

```dart
Future<void> addPlace(TripPlanPlace place) async {
  // Dedup check
  if (place.googlePlaceId != null) {
    final existing = await _supabase
        .from('trip_plan_places')
        .select('id')
        .eq('google_place_id', place.googlePlaceId!)
        .eq('trip_day_id', place.tripDayId)
        .maybeSingle();
    if (existing != null) {
      throw Exception('This place is already in your plan for this day.');
    }
  }
  // Existing insert logic...
}
```

### Step 3.3 — Dedup across entire trip (not just per-day)

For the AI generation case, check across ALL days of the trip:

```dart
Future<bool> placeExistsInTrip(String tripId, String googlePlaceId) async {
  final result = await _supabase
      .from('trip_plan_places')
      .select('id, trip_day_id!inner(trip_id)')
      .eq('trip_day_id.trip_id', tripId)
      .eq('google_place_id', googlePlaceId)
      .maybeSingle();
  return result != null;
}
```

### Files modified:
| File | Changes |
|---|---|
| `lib/providers/plan_provider.dart` | Dedup during AI plan generation |
| `lib/services/plan_service.dart` | Dedup check in `addPlace()`, `placeExistsInTrip()` |

### Testing:
1. Generate AI plan for trip with existing places → no duplicates
2. Manually add same place twice → error message
3. Generate plan from scratch → no inter-day duplicates

---

## Phase 4 — Reset Password Deep Link Fix (Priority: HIGH)

**Problem**: Password reset link not opening the app / not navigating to reset screen.

**Current state**:
- Deep link handling exists via `app_links` package in `AuthService`
- `AndroidManifest.xml` has intent filters for `wanderwith://reset-password` and `io.supabase.wanderwith://login-callback`
- Supabase sends reset email with link to redirect URL configured in Supabase Dashboard
- `_handleIncomingLink()` checks for `type=recovery` in fragment
- GoRouter redirects to `/reset-password` when `authService.isPasswordRecovery` is true

### Step 4.1 — Verify Supabase Dashboard config

**Manual check**: In Supabase Dashboard → Authentication → URL Configuration:
- **Site URL**: `io.supabase.wanderwith://login-callback`
- **Redirect URLs** must include:
  - `io.supabase.wanderwith://login-callback`
  - `wanderwith://reset-password`
  - `https://tejuice.fun/reset-password`

### Step 4.2 — Fix deep link handler for PKCE flow

**File**: `lib/services/auth_service.dart` → `_handleIncomingLink()`

**Issue**: With PKCE auth flow (which the app uses), password reset comes as a `code` parameter, not `access_token` in the fragment. The recovery detection needs to handle both:

```dart
void _handleIncomingLink(Uri uri) async {
  debugPrint('Deep link received: $uri');
  
  // Check for PKCE code-based recovery
  if (uri.queryParameters.containsKey('code')) {
    final type = uri.queryParameters['type'];
    if (type == 'recovery') {
      _isPasswordRecovery = true;
      _pendingDeepLink = uri;
      try {
        await _supabase.auth.exchangeCodeForSession(uri.queryParameters['code']!);
      } catch (e) {
        debugPrint('Code exchange failed: $e');
      }
      notifyListeners();
      return;
    }
  }
  
  // Check for fragment-based recovery (legacy/non-PKCE)
  if (uri.fragment.contains('type=recovery')) {
    _isPasswordRecovery = true;
    try {
      await _supabase.auth.setSessionFromUri(uri);
    } catch (_) {}
    notifyListeners();
    return;
  }
  
  // ... existing handling for other deep links
}
```

### Step 4.3 — Ensure AndroidManifest intent filters are complete

**File**: `android/app/src/main/AndroidManifest.xml`

Verify these intent filters exist (they should based on current analysis):

```xml
<!-- PKCE callback -->
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="io.supabase.wanderwith" android:host="login-callback"/>
</intent-filter>

<!-- Direct reset -->
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="wanderwith" android:host="reset-password"/>
</intent-filter>
```

### Step 4.4 — GoRouter: clear recovery flag after navigation

**File**: `lib/main.dart` → GoRouter redirect

After navigating to `/reset-password`, the flag should be cleared once the screen is shown. Currently the `ResetPasswordScreen` should call `authService.clearPasswordRecovery()` after the password is successfully updated.

```dart
// In ResetPasswordScreen, after successful password update:
AuthService.instance.clearPasswordRecovery();
context.go('/login');
```

### Files modified:
| File | Changes |
|---|---|
| `lib/services/auth_service.dart` | PKCE recovery code exchange |
| `android/app/src/main/AndroidManifest.xml` | Verify intent filters |
| `lib/main.dart` | Verify redirect logic |
| `lib/screens/auth/reset_password_screen.dart` | Clear recovery flag on success |

### Testing:
1. Trigger "Forgot Password" → receive email
2. Click link in email → app opens → navigates to Reset Password screen
3. Enter new password → success → navigated to login
4. Login with new password → works

---

## Phase 5 — Trip Intelligence Card (Overview Tab)

**Problem**: Overview tab lacks destination intelligence. No weather, visa, currency, timezone info.

**Current state**: Overview tab has: hero image, stats row, about section, travel crew. No destination metadata.

### Step 5.1 — New Supabase table: `trip_metadata`

```sql
CREATE TABLE trip_metadata (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE UNIQUE,
  destination_country_code text,         -- ISO 3166-1 alpha-2 (e.g., 'ID')
  best_time_to_visit text,               -- e.g., 'March – May'
  best_time_weather_emoji text,          -- e.g., '🌤'
  crowd_level text,                       -- 'Low', 'Moderate', 'High'
  avg_temp_range text,                    -- e.g., '24–30°C'
  visa_required text,                     -- 'Yes', 'No', 'On Arrival'
  currency_code text,                     -- e.g., 'IDR'
  currency_name text,                     -- e.g., 'Indonesian Rupiah'
  timezone text,                          -- e.g., 'GMT+8'
  language text,                          -- e.g., 'Indonesian (Bahasa)'
  emergency_number text,                  -- e.g., '112'
  best_season_months int[],              -- e.g., {3,4,5}
  raw_ai_response jsonb,                  -- Full AI response for debugging
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- RLS: same as trips
ALTER TABLE trip_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View trip metadata" ON trip_metadata FOR SELECT
USING (EXISTS (
  SELECT 1 FROM trips WHERE trips.id = trip_metadata.trip_id
  AND (trips.created_by = auth.uid() OR auth.uid() = ANY(trips.member_ids))
));

CREATE POLICY "Manage trip metadata" ON trip_metadata FOR ALL
USING (EXISTS (
  SELECT 1 FROM trips WHERE trips.id = trip_metadata.trip_id
  AND trips.created_by = auth.uid()
));
```

### Step 5.2 — New model: `TripMetadata`

**File**: `lib/models/trip_metadata.dart`

```dart
class TripMetadata {
  final String id;
  final String tripId;
  final String? destinationCountryCode;
  final String? bestTimeToVisit;
  final String? bestTimeWeatherEmoji;
  final String? crowdLevel;
  final String? avgTempRange;
  final String? visaRequired;
  final String? currencyCode;
  final String? currencyName;
  final String? timezone;
  final String? language;
  final String? emergencyNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TripMetadata({...}); // constructor
  factory TripMetadata.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;
}
```

### Step 5.3 — AI enrichment on trip creation

**File**: `lib/services/trip_service.dart` → new method `enrichTripMetadata()`

**Flow**:
1. When a trip is created (or when Overview tab loads and no metadata exists)
2. Call `GeminiService` with destination location
3. Parse structured JSON response
4. Save to `trip_metadata`
5. Next time → load from DB (no AI call)

**Gemini prompt**:
```
For the travel destination: "{trip.location}"

Return a JSON object with:
{
  "country_code": "ISO 3166-1 alpha-2 code",
  "best_time_to_visit": "month range",
  "best_time_weather_emoji": "single emoji",
  "crowd_level": "Low|Moderate|High",
  "avg_temp_range": "temperature range with unit",
  "visa_required": "Yes|No|On Arrival",
  "currency_code": "ISO currency code",
  "currency_name": "full currency name",
  "timezone": "GMT offset",
  "language": "primary language",
  "emergency_number": "local emergency number"
}
```

**File**: `lib/services/gemini_service.dart` → new method `enrichDestination()`

### Step 5.4 — UI: Trip Intelligence Card

**File**: `lib/screens/trip_dashboard_screen.dart` → `_OverviewTabState`

Insert new section between `_buildOverviewStats()` and "About this Trip":

```dart
// After stats row
_buildTripIntelligenceCard(metadata),

Widget _buildTripIntelligenceCard(TripMetadata? metadata) {
  if (metadata == null) return SizedBox.shrink(); // Loading or not enriched yet
  
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.travel_explore, color: AppColors.brand),
          SizedBox(width: 8),
          Text("Destination Intel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        SizedBox(height: 12),
        _intelRow("Best Time", "${metadata.bestTimeToVisit} ${metadata.bestTimeWeatherEmoji}"),
        _intelRow("Crowd Level", metadata.crowdLevel ?? "-"),
        _intelRow("Avg Temp", metadata.avgTempRange ?? "-"),
        _intelRow("Visa", metadata.visaRequired ?? "-"),
        _intelRow("Currency", "${metadata.currencyCode} (${metadata.currencyName})"),
        _intelRow("Timezone", metadata.timezone ?? "-"),
        _intelRow("Language", metadata.language ?? "-"),
      ],
    ),
  );
}

Widget _intelRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Flexible(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.end)),
      ],
    ),
  );
}
```

### Step 5.5 — Fetch logic in Overview tab

```dart
// In _OverviewTabState
TripMetadata? _metadata;

@override
void initState() {
  super.initState();
  _loadMetadata();
}

Future<void> _loadMetadata() async {
  final data = await TripService().getTripMetadata(widget.trip.id);
  if (data == null) {
    // First time — enrich via AI
    final enriched = await TripService().enrichTripMetadata(widget.trip);
    setState(() => _metadata = enriched);
  } else {
    setState(() => _metadata = data);
  }
}
```

### Files created/modified:
| File | Action |
|---|---|
| `lib/models/trip_metadata.dart` | CREATE — new model |
| `lib/services/trip_service.dart` | MODIFY — add `getTripMetadata()`, `enrichTripMetadata()`, `saveTripMetadata()` |
| `lib/services/gemini_service.dart` | MODIFY — add `enrichDestination()` |
| `lib/screens/trip_dashboard_screen.dart` | MODIFY — add intelligence card to Overview |
| `sql/trip_metadata.sql` | CREATE — table + RLS |

---

## Phase 6 — International Travel Info (Visa + Embassy)

**Problem**: No visa/embassy info for international trips. Must detect domestic vs international and show relevant info.

**Depends on**: Phase 5 (trip_metadata table, destination_country_code)

### Step 6.1 — Detect international trip

**Logic**: Compare user's `country` (from `UserProfile`) with trip's `destination_country_code` (from `TripMetadata`).

```dart
bool get isInternational {
  final userCountry = AuthService.instance.currentUser?.country; // "India"
  // Need ISO code → we'll add country_code to profiles
  final userCountryCode = AuthService.instance.currentUser?.countryCode; // "IN"
  final tripCountryCode = _metadata?.destinationCountryCode; // "ID"
  if (userCountryCode == null || tripCountryCode == null) return false;
  return userCountryCode != tripCountryCode;
}
```

### Step 6.2 — Add `country_code` to profiles

```sql
ALTER TABLE profiles ADD COLUMN country_code text; -- ISO 3166-1 alpha-2
```

**File**: `lib/models/user_profile.dart` — add `countryCode` field

**Auto-detect**: During onboarding or location detection, map country name → ISO code. Use a static map or the `intl` package.

### Step 6.3 — New table: `trip_international_info`

```sql
CREATE TABLE trip_international_info (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_country_code text NOT NULL,
  dest_country_code text NOT NULL,
  
  -- Visa info
  visa_required text,                    -- 'Yes', 'No', 'On Arrival', 'E-Visa'
  visa_type text,                         -- 'Tourist Visa', 'Business Visa'
  stay_duration text,                     -- '30 Days'
  processing_time text,                   -- '3-7 days'
  visa_apply_url text,                    -- official application link
  
  -- Embassy info
  embassy_name text,                      -- 'Embassy of India in Indonesia'
  embassy_address text,
  embassy_phone text,
  embassy_emergency_number text,
  embassy_email text,
  embassy_latitude double precision,
  embassy_longitude double precision,
  
  -- Emergency
  local_emergency_number text,            -- '112'
  local_police_number text,
  local_medical_number text,
  nearest_hospital_name text,
  
  raw_ai_response jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  UNIQUE(trip_id, user_country_code)    -- one per user-country per trip
);
```

### Step 6.4 — AI enrichment for international info

**File**: `lib/services/gemini_service.dart` → new method `getInternationalTravelInfo()`

**Prompt**:
```
User nationality: Indian (country code: IN)
Destination country: Indonesia (country code: ID)

Provide structured JSON:
{
  "visa_required": "Yes|No|On Arrival|E-Visa",
  "visa_type": "type name",
  "stay_duration": "allowed duration",
  "processing_time": "typical processing time",
  "visa_apply_url": "official government URL",
  "embassy_name": "name of user's embassy in destination",
  "embassy_address": "full address",
  "embassy_phone": "phone number",
  "embassy_emergency_number": "24/7 emergency number",
  "embassy_email": "email",
  "local_emergency_number": "local 911 equivalent",
  "local_police_number": "police number",
  "local_medical_number": "medical emergency number"
}
```

### Step 6.5 — Model: `TripInternationalInfo`

**File**: `lib/models/trip_international_info.dart` — CREATE

### Step 6.6 — UI: International Travel Info Card

**File**: `lib/screens/trip_dashboard_screen.dart` → `_OverviewTabState`

Insert between Trip Intelligence Card and About section, ONLY if `isInternational`:

```dart
if (isInternational && _internationalInfo != null) ...[
  _buildInternationalTravelCard(_internationalInfo!),
]

Widget _buildInternationalTravelCard(TripInternationalInfo info) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: 🌍 International Travel Info
        // Visa Section
        // Embassy Section with "Open in Maps" + "Call Now" buttons
        // Emergency Numbers section
      ],
    ),
  );
}
```

**Sections inside the card**:
1. 🛂 **Visa Requirement** — type, duration, processing time, "Apply Online" link button
2. 🏛 **Embassy / Consulate** — name, address, phone (tappable), emergency number, "Open in Maps" button
3. 🏥 **Emergency Numbers** — local emergency, police, medical

### Files created/modified:
| File | Action |
|---|---|
| `lib/models/trip_international_info.dart` | CREATE |
| `lib/models/user_profile.dart` | MODIFY — add `countryCode` |
| `lib/services/trip_service.dart` | MODIFY — fetch/save international info |
| `lib/services/gemini_service.dart` | MODIFY — `getInternationalTravelInfo()` |
| `lib/screens/trip_dashboard_screen.dart` | MODIFY — conditional card in Overview |
| `sql/international_info.sql` | CREATE — table + RLS |
| `sql/profiles_country_code.sql` | CREATE — ALTER TABLE |

---

## Phase 7 — Enhanced Place Detail Screen

**Problem**: Place detail screen is barebones — hardcoded duration, price; no real details; Add/Bookmark buttons are no-ops.

**Current state**: `place_detail_screen.dart` (347 lines) shows: hero image, directions button, basic info, community notes, 2x2 info grid with hardcoded values.

### Step 7.1 — Fetch rich place details from Google Places API

**File**: `lib/services/google_places_service.dart`

The existing `getPlaceDetails()` method already returns:
- `displayName`, `formattedAddress`
- `rating`, `userRatingCount`
- `currentOpeningHours`
- `priceLevel`
- `websiteUri`
- `nationalPhoneNumber`
- `reviews` (array)
- `photos` (array)
- `regularOpeningHours.weekdayDescriptions`

**What's NOT used yet**: opening hours, website, phone, reviews, price level. We need to surface these.

### Step 7.2 — AI enrichment for place insights

**File**: `lib/services/gemini_service.dart` → new method `getPlaceInsights()`

**Prompt**:
```
For the location: "{place.name}" in "{trip.location}"

Provide JSON:
{
  "best_time_to_visit": "morning/afternoon/evening + reason",
  "crowd_level": "Low|Moderate|High",
  "peak_hours": "e.g., 10 AM – 2 PM",
  "avg_visit_duration": "e.g., 1.5 - 2 hours",
  "ticket_required": true/false,
  "ticket_price_estimate": "price range in local currency",
  "online_booking_recommended": true/false,
  "booking_url": "official booking URL if available",
  "onsite_booking_available": true/false,
  "avg_waiting_time": "e.g., 15-30 min on weekends",
  "insider_tips": ["tip1", "tip2", "tip3"],
  "is_worth_visiting": "brief opinion",
  "family_friendly": true/false,
  "budget_friendly": true/false
}
```

Cache this in a new table `place_insights` keyed by `google_place_id`:

```sql
CREATE TABLE place_insights (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  google_place_id text NOT NULL UNIQUE,
  place_name text,
  insights jsonb NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

### Step 7.3 — Redesign `PlaceDetailScreen` sections

**File**: `lib/screens/place_detail_screen.dart` — major rewrite

**New section order**:

1. **Hero Image** (existing — keep)
2. **Action Row**: Get Directions, Share, Bookmark (wire up share)
3. **Quick Facts Grid** (REPLACE hardcoded):
   - Rating (from Google)
   - Price Level (from Google: `$`, `$$`, `$$$`)
   - Visit Duration (from AI insights)
   - Crowd Level (from AI insights)
4. **Opening Hours** (NEW — from Google Places `currentOpeningHours`)
5. **Best Time to Visit** (NEW — from AI + weather context)
6. **Entry Details** (NEW):
   - Ticket required? (Yes/No)
   - Estimated price
   - Online booking link button
   - Onsite booking available?
   - Average waiting time
   - Peak hours
7. **Insider Tips** (NEW):
   - Bullet list from AI (3-5 tips)
8. **AI Travel Analysis** (NEW):
   - "Is it worth visiting?"
   - "How much time to spend?"
   - "Family friendly?"
   - "Budget friendly?"
9. **Nearby Attractions** (NEW):
   - Horizontal scroll of 4 nearby places from `GooglePlacesService.searchNearby()`
   - Each shows: image, name, rating, distance
   - Tappable → opens another PlaceDetailScreen
10. **Community Notes** (existing — keep, move to bottom)
11. **Website & Contact** (NEW — from Google):
    - Website link
    - Phone number (tappable)

### Step 7.4 — Nearby attractions

**File**: `lib/screens/place_detail_screen.dart`

```dart
Future<List<Map>> _fetchNearbyPlaces() async {
  return await GooglePlacesService().searchNearby(
    latitude: widget.place.latitude,
    longitude: widget.place.longitude,
    radius: 2000, // 2km
    maxResults: 4,
  );
}

Widget _buildNearbyAttractions(List<Map> places) {
  return SizedBox(
    height: 180,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: places.length,
      itemBuilder: (ctx, i) => _NearbyPlaceCard(places[i]),
    ),
  );
}
```

### Files created/modified:
| File | Action |
|---|---|
| `lib/screens/place_detail_screen.dart` | MAJOR REWRITE — add 6 new sections |
| `lib/services/gemini_service.dart` | MODIFY — `getPlaceInsights()` |
| `lib/services/google_places_service.dart` | MODIFY — expose opening hours, website, phone |
| `lib/services/trip_service.dart` | MODIFY — `getPlaceInsights()` + `savePlaceInsights()` |
| `lib/models/place_insights.dart` | CREATE — model |
| `sql/place_insights.sql` | CREATE — table + RLS |

---

## Phase 8 — AI Guide Memory System

**Problem**: AI Guide has no memory between sessions. Each chat starts fresh.

**Current state**:
- `AIGuideScreen` stores `_messages` as local list (in-memory only)
- `GeminiService.getChatResponse()` accepts `conversationHistory` as `List<Map<String, String>>`
- Trip data + plan passed as context each call
- Messages lost on screen close

### Step 8.1 — New table: `trip_ai_memory`

```sql
CREATE TABLE trip_ai_memory (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conversation_history jsonb NOT NULL DEFAULT '[]',
  last_updated timestamptz DEFAULT now(),
  
  UNIQUE(trip_id, user_id) -- one conversation per user per trip
);

ALTER TABLE trip_ai_memory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own AI memory" ON trip_ai_memory FOR ALL
USING (auth.uid() = user_id);
```

### Step 8.2 — Service methods

**File**: `lib/services/trip_service.dart` (or new `lib/services/ai_memory_service.dart`)

```dart
Future<List<Map<String, String>>> getAiConversationHistory(String tripId) async {
  final uid = _supabase.auth.currentUser!.id;
  final result = await _supabase
      .from('trip_ai_memory')
      .select('conversation_history')
      .eq('trip_id', tripId)
      .eq('user_id', uid)
      .maybeSingle();
  
  if (result == null) return [];
  return (result['conversation_history'] as List)
      .map((e) => Map<String, String>.from(e))
      .toList();
}

Future<void> saveAiConversationHistory(String tripId, List<Map<String, String>> history) async {
  final uid = _supabase.auth.currentUser!.id;
  // Keep only last 15 messages to control token cost
  final trimmed = history.length > 15 ? history.sublist(history.length - 15) : history;
  
  await _supabase.from('trip_ai_memory').upsert({
    'trip_id': tripId,
    'user_id': uid,
    'conversation_history': trimmed,
    'last_updated': DateTime.now().toIso8601String(),
  }, onConflict: 'trip_id,user_id');
}
```

### Step 8.3 — Modify AIGuideScreen

**File**: `lib/screens/ai_guide_screen.dart`

**Changes**:
1. On screen open: load conversation history from DB
2. Display previous messages
3. Pass history to `GeminiService.getChatResponse()`
4. After each AI response: save updated history to DB
5. Add "Clear Memory" button in app bar

```dart
// initState
@override
void initState() {
  super.initState();
  _loadConversationHistory();
}

Future<void> _loadConversationHistory() async {
  final history = await TripService().getAiConversationHistory(widget.trip.id);
  setState(() {
    _messages = history.map((h) => ChatMessage(
      role: h['role']!,
      content: h['content']!,
    )).toList();
  });
}

// After AI response
Future<void> _sendMessage(String text) async {
  // ... existing send logic ...
  final response = await GeminiService().getChatResponse(
    userMessage: text,
    trip: widget.trip,
    conversationHistory: _messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
    tripPlan: _plan,
  );
  
  // Add to messages
  _messages.add(ChatMessage(role: 'model', content: response));
  
  // Persist
  await TripService().saveAiConversationHistory(
    widget.trip.id,
    _messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
  );
}
```

### Step 8.4 — Enhance AI system prompt

**File**: `lib/services/gemini_service.dart` → `getChatResponse()`

Update system prompt:
```
You are WanderWith Trip AI Guide with persistent memory.
This is trip data: [trip details JSON]
Trip budget: [budget], Currency: [currency], Dates: [dates]
Trip plan: [plan summary]

Previous conversation (you remember this context):
[conversation history - last 15 messages]

Answer the user's query clearly and contextually. Reference previous conversation when relevant.
Keep responses focused, practical, and budget-aware.
```

### Files created/modified:
| File | Action |
|---|---|
| `lib/screens/ai_guide_screen.dart` | MODIFY — load/save history, display previous messages |
| `lib/services/trip_service.dart` | MODIFY — `getAiConversationHistory()`, `saveAiConversationHistory()` |
| `lib/services/gemini_service.dart` | MODIFY — enhanced system prompt |
| `sql/ai_memory.sql` | CREATE — table + RLS |

---

## Phase 9 — Offline Mode (Full Architecture)

**Problem**: App crashes/breaks on no internet. No cached data. Forces re-login.

**Current state**: Minimal error handling. `_handleException()` detects `SocketException` but no caching/queue. Supabase `.stream()` provides some implicit caching for realtime subscriptions.

> **This is the largest phase. Estimated: 2-3 weeks of work.**

### Architecture: Local-First with Sync

```
UI Layer (Screens/Widgets)
     ↓ reads from
Repository Layer (TripRepository, ProfileRepository, etc.)
     ↓ reads/writes
Local Database (Isar)     ←→     Remote (Supabase)
                          sync
```

### Step 9.1 — Add Isar dependency

**File**: `pubspec.yaml`

```yaml
dependencies:
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1

dev_dependencies:
  isar_generator: ^3.1.0+1
  build_runner: ^2.4.6
```

### Step 9.2 — Define Isar schemas (local DB models)

**Directory**: `lib/local/`

Create Isar collection classes mirroring the key Supabase tables:

```dart
// lib/local/schemas/cached_trip.dart
@collection
class CachedTrip {
  Id isarId = Isar.autoIncrement;
  @Index(unique: true)
  late String id;  // Supabase UUID
  late String name;
  late String location;
  DateTime? startDate;
  DateTime? endDate;
  late String createdBy;
  late List<String> memberIds;
  String? coverImageUrl;
  String? metadataJson;  // Store metadata as JSON string
  late DateTime lastSynced;
}

// Similar for: CachedProfile, CachedTripDay, CachedPlace, CachedBudget, 
// CachedGalleryPhoto, CachedMessage (last 50), CachedPost
```

**Collections to create**:
| Collection | Source Table | Cache Strategy |
|---|---|---|
| `CachedProfile` | `profiles` | Cache own profile + trip members |
| `CachedTrip` | `trips` | Cache all user's trips |
| `CachedTripDay` | `trip_days` | Cache when trip is opened |
| `CachedTripPlace` | `trip_plan_places` | Cache when trip is opened |
| `CachedGalleryPhoto` | `photos` | Cache URLs + metadata |
| `CachedMessage` | `messages` | Last 50 per trip |
| `CachedTripLink` | `trip_links` | Cache when trip is opened |
| `CachedPoll` | `trip_polls` + options + votes | Cache when polls tab opened |
| `PendingAction` | (local only) | Queue for offline writes |

### Step 9.3 — Initialize Isar at app startup

**File**: `lib/local/local_db.dart`

```dart
class LocalDb {
  static late Isar instance;
  
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    instance = await Isar.open(
      [CachedTripSchema, CachedProfileSchema, CachedTripDaySchema, 
       CachedTripPlaceSchema, CachedGalleryPhotoSchema, CachedMessageSchema,
       CachedTripLinkSchema, CachedPollSchema, PendingActionSchema],
      directory: dir.path,
    );
  }
}
```

**File**: `lib/main.dart` — add `await LocalDb.initialize();` before `runApp()`

### Step 9.4 — Network state provider

**File**: `lib/services/network_service.dart` — CREATE

```dart
class NetworkService extends ChangeNotifier {
  static final NetworkService instance = NetworkService._();
  NetworkService._();
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  
  StreamSubscription? _connectivitySub;
  
  Future<void> initialize() async {
    // Initial check
    _isOnline = await _checkInternet();
    
    // Listen for changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) async {
      final wasOnline = _isOnline;
      _isOnline = await _checkInternet();
      if (wasOnline != _isOnline) {
        notifyListeners();
        if (_isOnline) {
          // Trigger sync when back online
          SyncService.instance.syncPendingActions();
        }
      }
    });
  }
  
  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
  
  void dispose() {
    _connectivitySub?.cancel();
  }
}
```

### Step 9.5 — Repository pattern

**Directory**: `lib/repositories/`

Example for trips:

```dart
// lib/repositories/trip_repository.dart
class TripRepository {
  final TripService _remote = TripService();
  final Isar _local = LocalDb.instance;
  
  /// Get all user trips — local first, then sync from remote
  Stream<List<Trip>> getUserTrips(String userId) async* {
    // 1. Yield cached data immediately
    final cached = await _local.cachedTrips
        .filter()
        .memberIdsElementContains(userId)
        .findAll();
    if (cached.isNotEmpty) {
      yield cached.map((c) => c.toTrip()).toList();
    }
    
    // 2. If online, fetch fresh data
    if (NetworkService.instance.isOnline) {
      try {
        await for (final trips in _remote.getUserTrips(userId)) {
          // Save to local cache
          await _local.writeTxn(() async {
            for (final trip in trips) {
              await _local.cachedTrips.put(CachedTrip.fromTrip(trip));
            }
          });
          yield trips;
        }
      } catch (e) {
        // Network failed mid-stream, cached data already yielded
        debugPrint('Remote fetch failed: $e');
      }
    }
  }
  
  /// Get single trip
  Future<Trip?> getTrip(String tripId) async {
    if (NetworkService.instance.isOnline) {
      try {
        final trip = await _remote.getTrip(tripId);
        // Cache it
        await _local.writeTxn(() async {
          await _local.cachedTrips.put(CachedTrip.fromTrip(trip));
        });
        return trip;
      } catch (_) {}
    }
    // Fallback to cache
    final cached = await _local.cachedTrips.filter().idEqualTo(tripId).findFirst();
    return cached?.toTrip();
  }
}
```

**Repositories to create**:
| Repository | Wraps |
|---|---|
| `TripRepository` | `TripService` |
| `ProfileRepository` | `AuthService` profile methods |
| `PlanRepository` | `PlanService` |
| `GalleryRepository` | `TripService` gallery methods |
| `ChatRepository` | Chat-related `TripService` methods |

### Step 9.6 — Pending actions queue (offline writes)

**File**: `lib/local/schemas/pending_action.dart`

```dart
@collection
class PendingAction {
  Id id = Isar.autoIncrement;
  late String actionType;      // 'add_plan_place', 'upload_photo', 'add_expense', etc.
  late String payloadJson;     // JSON-encoded parameters
  late DateTime createdAt;
  late int retryCount;
  String? errorMessage;
}
```

**File**: `lib/services/sync_service.dart` — CREATE

```dart
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();
  
  Future<void> syncPendingActions() async {
    final pending = await LocalDb.instance.pendingActions
        .where()
        .sortByCreatedAt()
        .findAll();
    
    for (final action in pending) {
      try {
        await _executeAction(action);
        // Success — remove from queue
        await LocalDb.instance.writeTxn(() async {
          await LocalDb.instance.pendingActions.delete(action.id);
        });
      } catch (e) {
        // Increment retry, log error
        action.retryCount++;
        action.errorMessage = e.toString();
        await LocalDb.instance.writeTxn(() async {
          await LocalDb.instance.pendingActions.put(action);
        });
        if (action.retryCount > 5) break; // Stop syncing if persistent failures
      }
    }
  }
  
  Future<void> _executeAction(PendingAction action) async {
    final payload = jsonDecode(action.payloadJson);
    switch (action.actionType) {
      case 'add_plan_place':
        await PlanService().addPlace(TripPlanPlace.fromJson(payload));
        break;
      case 'upload_photo':
        // Re-upload from local path
        break;
      case 'add_expense':
        // ... 
        break;
    }
  }
  
  /// Queue an action for later sync
  Future<void> queueAction(String actionType, Map<String, dynamic> payload) async {
    await LocalDb.instance.writeTxn(() async {
      await LocalDb.instance.pendingActions.put(PendingAction()
        ..actionType = actionType
        ..payloadJson = jsonEncode(payload)
        ..createdAt = DateTime.now()
        ..retryCount = 0
      );
    });
  }
}
```

### Step 9.7 — Offline banner widget

**File**: `lib/widgets/offline_banner.dart` — CREATE

```dart
class OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, network, _) {
        if (network.isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          color: Colors.amber.shade800,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text("Offline Mode — Some features unavailable",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

**File**: `lib/widgets/back_online_banner.dart` — Shows "Back Online ✓ Syncing..." briefly

### Step 9.8 — Prevent logout on network error

**File**: `lib/services/auth_service.dart`

**Changes**:
1. In `onAuthStateChange` listener: if `signedOut` event fires but `NetworkService.instance.isOffline`, ignore it
2. Catch `AuthSessionMissingException` — if offline, silently continue with cached profile
3. Disable auto-refresh when offline:

```dart
// In _init()
_supabase.auth.onAuthStateChange.listen((data) {
  final event = data.event;
  if (event == AuthChangeEvent.signedOut && NetworkService.instance.isOffline) {
    // Ignore — this is a network-induced false signout
    return;
  }
  // ... existing handling
});
```

### Step 9.9 — App launch while offline

**File**: `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.initialize();
  await NetworkService.instance.initialize();
  
  // Try Supabase init, but don't fail if offline
  try {
    await Supabase.initialize(...);
  } catch (e) {
    debugPrint('Supabase init failed (offline?): $e');
  }
  
  // Check if cached session exists
  final hasSession = Supabase.instance.client.auth.currentSession != null 
      || await _hasCachedProfile();
  
  runApp(MyApp(initialDarkMode: ..., hasOfflineSession: hasSession));
}
```

**GoRouter change**: If offline and has cached session → go to home, not login.

### Step 9.10 — Feature-level offline access matrix

**Implementation per feature**:

| Feature | Offline Read | Offline Write | Implementation |
|---|---|---|---|
| View Trips | ✅ | — | `TripRepository` serves from Isar |
| View Plan | ✅ | — | `PlanRepository` serves from Isar |
| View Budget | ✅ | — | Cached in trip metadata |
| View Members | ✅ | — | Cached profiles |
| View Gallery | ✅ (cached URLs) | — | URLs cached, `CachedNetworkImage` handles image cache |
| Add to Plan | — | ✅ (queue) | `SyncService.queueAction('add_plan_place', ...)` |
| Upload Photo | — | ✅ (queue) | Save file locally + queue upload |
| Chat | ❌ | ❌ | Show "Reconnect to send messages" |
| AI Guide | ❌ | ❌ | Show "AI requires internet connection" |
| Discover | ❌ | ❌ | Disabled with offline indicator |
| Add Expense | — | ✅ (queue) | Save locally + queue sync |

### Step 9.11 — Gallery image pre-caching

**File**: `lib/repositories/gallery_repository.dart`

When user first opens a trip gallery online, pre-cache images:

```dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

Future<void> preCacheGalleryImages(List<String> imageUrls) async {
  final cacheManager = DefaultCacheManager();
  for (final url in imageUrls) {
    try {
      await cacheManager.downloadFile(url);
    } catch (_) {}
  }
}
```

This leverages `CachedNetworkImage`'s underlying cache manager so images display offline.

### Step 9.12 — Wire NetworkService into Provider tree

**File**: `lib/main.dart` → add to `MultiProvider`:

```dart
ChangeNotifierProvider.value(value: NetworkService.instance),
```

### Files created/modified:
| File | Action |
|---|---|
| `lib/local/local_db.dart` | CREATE — Isar initialization |
| `lib/local/schemas/cached_trip.dart` | CREATE |
| `lib/local/schemas/cached_profile.dart` | CREATE |
| `lib/local/schemas/cached_trip_day.dart` | CREATE |
| `lib/local/schemas/cached_trip_place.dart` | CREATE |
| `lib/local/schemas/cached_gallery_photo.dart` | CREATE |
| `lib/local/schemas/cached_message.dart` | CREATE |
| `lib/local/schemas/cached_trip_link.dart` | CREATE |
| `lib/local/schemas/cached_poll.dart` | CREATE |
| `lib/local/schemas/pending_action.dart` | CREATE |
| `lib/services/network_service.dart` | CREATE |
| `lib/services/sync_service.dart` | CREATE |
| `lib/repositories/trip_repository.dart` | CREATE |
| `lib/repositories/plan_repository.dart` | CREATE |
| `lib/repositories/profile_repository.dart` | CREATE |
| `lib/repositories/gallery_repository.dart` | CREATE |
| `lib/repositories/chat_repository.dart` | CREATE |
| `lib/widgets/offline_banner.dart` | CREATE |
| `lib/widgets/back_online_banner.dart` | CREATE |
| `lib/main.dart` | MODIFY — init Isar, NetworkService, provider |
| `lib/services/auth_service.dart` | MODIFY — prevent false logout |
| `pubspec.yaml` | MODIFY — add isar, isar_flutter_libs, isar_generator, build_runner, flutter_cache_manager |
| ALL screen files | MODIFY — replace direct service calls with repository calls |

### Migration strategy (gradual):
1. **Week 1**: Set up Isar, NetworkService, offline banner, prevent false logout
2. **Week 2**: Repository for trips + plan (most critical views). Wire into home screen + trip dashboard
3. **Week 3**: Repository for gallery, chat, polls. Pending action queue + sync service

---

## Phase 10 — Expense Split System

**Problem**: No expense tracking or splitting between trip members. Travellers need Splitwise-like functionality.

### Step 10.1 — New tables

```sql
CREATE TABLE trip_expenses (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  title text NOT NULL,
  amount decimal(12,2) NOT NULL,
  currency text NOT NULL DEFAULT 'INR',
  category text DEFAULT 'general',     -- food, transport, accommodation, activity, other
  paid_by uuid NOT NULL REFERENCES auth.users(id),
  split_type text NOT NULL DEFAULT 'equal', -- equal, custom, full
  created_at timestamptz DEFAULT now(),
  receipt_url text,
  notes text
);

CREATE TABLE expense_splits (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  expense_id uuid NOT NULL REFERENCES trip_expenses(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  amount decimal(12,2) NOT NULL,       -- Amount this person owes
  is_settled bool DEFAULT false,
  settled_at timestamptz
);

-- RLS: trip members only
ALTER TABLE trip_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_splits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trip members manage expenses" ON trip_expenses FOR ALL
USING (EXISTS (
  SELECT 1 FROM trips WHERE trips.id = trip_expenses.trip_id
  AND auth.uid() = ANY(trips.member_ids)
));

CREATE POLICY "Trip members view splits" ON expense_splits FOR ALL
USING (EXISTS (
  SELECT 1 FROM trip_expenses e
  JOIN trips t ON t.id = e.trip_id
  WHERE e.id = expense_splits.expense_id
  AND auth.uid() = ANY(t.member_ids)
));
```

### Step 10.2 — Models

**File**: `lib/models/expense.dart` — CREATE

```dart
class TripExpense {
  final String id;
  final String tripId;
  final String title;
  final double amount;
  final String currency;
  final String category;
  final String paidBy;
  final String splitType;
  final DateTime createdAt;
  final String? receiptUrl;
  final String? notes;
  final List<ExpenseSplit> splits;
  // ...
}

class ExpenseSplit {
  final String id;
  final String expenseId;
  final String userId;
  final double amount;
  final bool isSettled;
  // ...
}
```

### Step 10.3 — Service

**File**: `lib/services/expense_service.dart` — CREATE

**Key methods**:
- `getExpensesStream(tripId)` — real-time stream enriched with splits
- `addExpense(expense, splits)` — insert expense + splits (equal calculation or custom amounts)
- `settleUp(expenseId, userId)` — mark a split as settled
- `calculateBalances(tripId)` → `Map<String, double>` — net balance per member (positive = owed, negative = owes)
- `getSimplifiedDebts(tripId)` → `List<Debt>` — minimize number of transactions (debt simplification algorithm)

**Balance calculation**:
```dart
Map<String, double> calculateBalances(List<TripExpense> expenses) {
  final balances = <String, double>{};
  for (final expense in expenses) {
    // Person who paid gets credited
    balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) + expense.amount;
    // Each person in split gets debited
    for (final split in expense.splits) {
      balances[split.userId] = (balances[split.userId] ?? 0) - split.amount;
    }
  }
  return balances; // Positive = others owe you, Negative = you owe others
}
```

**Simplified debts algorithm** (minimize transactions):
```dart
List<Debt> simplifyDebts(Map<String, double> balances) {
  final debtors = <MapEntry<String, double>>[]; // negative balance
  final creditors = <MapEntry<String, double>>[]; // positive balance
  
  for (final entry in balances.entries) {
    if (entry.value < -0.01) debtors.add(entry);
    if (entry.value > 0.01) creditors.add(entry);
  }
  
  debtors.sort((a, b) => a.value.compareTo(b.value)); // most negative first
  creditors.sort((a, b) => b.value.compareTo(a.value)); // most positive first
  
  final debts = <Debt>[];
  int i = 0, j = 0;
  while (i < debtors.length && j < creditors.length) {
    final amount = min(creditors[j].value, -debtors[i].value);
    debts.add(Debt(from: debtors[i].key, to: creditors[j].key, amount: amount));
    // Adjust balances and move pointers...
  }
  return debts;
}
```

### Step 10.4 — UI: New "Expenses" tab in trip dashboard

**File**: `lib/screens/trip_dashboard_screen.dart`

Add new tab between Budget and Plan (or replace the current Budget tab's static allocations):

**Tab contents**:
1. **Balance Summary Card** — Shows each member's net balance (+₹500 / -₹300)
2. **Simplified Debts** — "You owe Alice ₹200", "Bob owes you ₹150"
3. **Expense List** — Grouped by date, each shows: title, amount, who paid, category icon
4. **FAB**: "Add Expense" → Bottom sheet with:
   - Title input
   - Amount input
   - Category picker (food, transport, stay, activity, other)
   - "Paid by" picker (select member)
   - Split type: Equal / Custom
   - If custom: amount input per member
5. **Settle Up** button per debt → marks splits as settled

### Step 10.5 — Push notifications on new expense

When expense is added, notify other members:
```
"Alice added ₹2000 for Dinner — you owe ₹500"
```

### Files created/modified:
| File | Action |
|---|---|
| `lib/models/expense.dart` | CREATE |
| `lib/services/expense_service.dart` | CREATE |
| `lib/screens/trip_dashboard_screen.dart` | MODIFY — add Expenses tab |
| `sql/expenses.sql` | CREATE — tables + RLS |

---

## Phase 11 — Smart Travel Checklist

**Problem**: No packing/preparation checklist. International trips need visa/passport reminders.

### Step 11.1 — New table: `trip_checklist`

```sql
CREATE TABLE trip_checklist (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  trip_id uuid NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  item_text text NOT NULL,
  is_checked bool DEFAULT false,
  category text DEFAULT 'general',      -- documents, packing, bookings, health, money
  is_auto_generated bool DEFAULT false,
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE trip_checklist ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own checklist" ON trip_checklist FOR ALL
USING (auth.uid() = user_id);
```

### Step 11.2 — Auto-generate checklist items

**When**: Trip is created or when user first opens checklist
**Logic**:

```dart
List<ChecklistItem> generateDefaultChecklist(Trip trip, bool isInternational) {
  final items = <ChecklistItem>[
    // Always
    ChecklistItem(text: 'ID / Passport', category: 'documents'),
    ChecklistItem(text: 'Trip tickets / boarding passes', category: 'documents'),
    ChecklistItem(text: 'Hotel / accommodation booking', category: 'bookings'),
    ChecklistItem(text: 'Travel insurance', category: 'documents'),
    ChecklistItem(text: 'Phone charger & power bank', category: 'packing'),
    ChecklistItem(text: 'Medications / first aid', category: 'health'),
    ChecklistItem(text: 'Cash / cards', category: 'money'),
  ];
  
  if (isInternational) {
    items.addAll([
      ChecklistItem(text: 'Passport valid 6+ months', category: 'documents'),
      ChecklistItem(text: 'Visa approved / printed', category: 'documents'),
      ChecklistItem(text: 'Currency exchanged', category: 'money'),
      ChecklistItem(text: 'International SIM / eSIM', category: 'packing'),
      ChecklistItem(text: 'Embassy contact saved', category: 'documents'),
      ChecklistItem(text: 'Travel insurance (international)', category: 'documents'),
    ]);
  }
  
  return items;
}
```

### Step 11.3 — UI: Expandable checklist card in Overview tab

**Placement**: In Overview tab, after "About This Trip", before "Travel Crew"

```dart
Widget _buildChecklistCard() {
  return ExpansionTile(
    title: Row(children: [
      Icon(Icons.checklist, color: AppColors.brand),
      SizedBox(width: 8),
      Text("Travel Checklist"),
      Spacer(),
      Text("${checked}/${total}", style: TextStyle(color: colors.textSecondary)),
    ]),
    children: [
      // Grouped by category
      // Each item: Checkbox + text + delete button for custom items
      // "Add Item" button at bottom
    ],
  );
}
```

### Files created/modified:
| File | Action |
|---|---|
| `lib/models/checklist_item.dart` | CREATE |
| `lib/services/checklist_service.dart` | CREATE |
| `lib/screens/trip_dashboard_screen.dart` | MODIFY — add checklist to Overview |
| `sql/checklist.sql` | CREATE — table + RLS |

---

## Phase 12 — Budget Analytics

**Problem**: Budget tab shows static allocations. No visual analytics.

**Depends on**: Phase 10 (Expense Split — real expense data)

### Step 12.1 — Pie chart of expense categories

**Dependency**: `fl_chart` package

**File**: `lib/screens/trip_dashboard_screen.dart` → `_BudgetTab`

Add a section showing:
1. **Pie chart**: Expenses by category (food, transport, accommodation, activity, other)
2. **Budget burn rate**: "You've spent ₹8,000 of ₹25,000 (32%)" with linear progress bar
3. **Per-member spending**: Bar chart or list showing who has spent how much
4. **Daily spending trend**: Simple line chart of cumulative spend over trip days

```dart
// Using fl_chart
Widget _buildExpensePieChart(Map<String, double> categoryTotals) {
  return PieChart(PieChartData(
    sections: categoryTotals.entries.map((e) => PieChartSectionData(
      value: e.value,
      title: e.key,
      color: _categoryColor(e.key),
    )).toList(),
    centerSpaceRadius: 40,
  ));
}
```

### Files modified:
| File | Action |
|---|---|
| `lib/screens/trip_dashboard_screen.dart` | MODIFY — add charts to Budget tab |
| `pubspec.yaml` | MODIFY — add `fl_chart` |

---

## Phase 13 — Emergency Info Section

**Problem**: No emergency contact info available during trips.

**Partially covered by Phase 6** (international trips get embassy + emergency numbers).

### For ALL trips (including domestic):

**File**: `lib/screens/trip_dashboard_screen.dart` → Overview tab

Add "Emergency Info" expandable at bottom of Overview:

```dart
Widget _buildEmergencyInfo() {
  return ExpansionTile(
    title: Row(children: [
      Icon(Icons.emergency, color: Colors.red),
      SizedBox(width: 8),
      Text("Emergency Info"),
    ]),
    children: [
      _emergencyRow("Police", metadata?.localPoliceNumber ?? "100"),
      _emergencyRow("Ambulance", metadata?.localMedicalNumber ?? "108"),
      _emergencyRow("Fire", "101"),
      _emergencyRow("Women Helpline", "1091"),
      if (isInternational && _internationalInfo != null) ...[
        Divider(),
        _emergencyRow("Embassy Emergency", _internationalInfo!.embassyEmergencyNumber ?? "-"),
        _emergencyRow("Nearest Hospital", _internationalInfo!.nearestHospitalName ?? "-"),
      ],
    ],
  );
}

Widget _emergencyRow(String label, String number) {
  return ListTile(
    dense: true,
    title: Text(label),
    trailing: TextButton.icon(
      icon: Icon(Icons.phone, size: 16),
      label: Text(number),
      onPressed: () => launchUrl(Uri.parse('tel:$number')),
    ),
  );
}
```

### Files modified:
| File | Action |
|---|---|
| `lib/screens/trip_dashboard_screen.dart` | MODIFY — add emergency section to Overview |

---

## Phase 14 — Future Advanced Features

These are larger features for post-MVP. Brief architecture notes for each:

### 14.1 — Flight Tracker
- Integrate with AviationStack API or similar
- New table `trip_flights` (flight_number, departure, arrival, status)
- Auto-detect flight info from booking confirmation emails (advanced)
- Show flight status card in Overview tab

### 14.2 — Route Optimization
- Use Google Directions API with waypoints
- For each trip day, calculate optimal visit order
- Show total travel time + suggested order
- Integrate with `PlanProvider` / `DirectionsService` (already exists)

### 14.3 — Smart Hotel Suggestions
- Based on trip location + remaining budget
- Use Google Places API `searchNearby` with `lodging` type
- Filter by price level
- Show in a "Where to Stay" section

### 14.4 — Memory Auto-Tagging
- Use Gemini Vision API to classify uploaded photos
- Categories: Beach, Airport, Temple, Nightlife, Food, Mountain, etc.
- Store tags in `photos.metadata` JSONB
- Enable gallery filtering by tag
- Process in background after upload

### 14.5 — "Before You Go" Section
- Part of Phase 7 (Place Detail) — entry tickets, booking info
- Also add to trip-level Overview: aggregate all places that need tickets
- "You have 3 places that need advance booking" → CTA to book

### 14.6 — Daily Weather Forecast
- Integrate OpenWeatherMap One Call API 3.0
- Show weather for each trip day in the Dates tab
- Cache in `trip_metadata` or new `trip_weather` table
- Only fetch for future trip dates

### 14.7 — Local Events During Trip Dates
- Use Ticketmaster API or Google Events
- Show events happening at destination during trip dates
- "There's a festival on March 15 at your destination!"
- Cache results

---

## New Supabase Tables Summary

| Table | Phase | Purpose |
|---|---|---|
| `trip_metadata` | 5 | Destination intelligence (weather, visa, currency, timezone) |
| `trip_international_info` | 6 | Visa + embassy details per user-country pair |
| `place_insights` | 7 | AI-enriched place details (cached) |
| `trip_ai_memory` | 8 | Persistent AI conversation history |
| `trip_expenses` | 10 | Expense tracking |
| `expense_splits` | 10 | Per-member expense splits |
| `trip_checklist` | 11 | Personal travel checklist |

**Existing table changes**:
| Table | Phase | Change |
|---|---|---|
| `photos` | 1 | Add `thumbnail_url` column |
| `profiles` | 6 | Add `country_code` column |

---

## New Files Summary

### Models (`lib/models/`)
| File | Phase |
|---|---|
| `trip_metadata.dart` | 5 |
| `trip_international_info.dart` | 6 |
| `place_insights.dart` | 7 |
| `expense.dart` | 10 |
| `checklist_item.dart` | 11 |

### Services (`lib/services/`)
| File | Phase |
|---|---|
| `network_service.dart` | 9 |
| `sync_service.dart` | 9 |
| `expense_service.dart` | 10 |
| `checklist_service.dart` | 11 |

### Repositories (`lib/repositories/`)
| File | Phase |
|---|---|
| `trip_repository.dart` | 9 |
| `plan_repository.dart` | 9 |
| `profile_repository.dart` | 9 |
| `gallery_repository.dart` | 9 |
| `chat_repository.dart` | 9 |

### Local DB (`lib/local/`)
| File | Phase |
|---|---|
| `local_db.dart` | 9 |
| `schemas/cached_trip.dart` | 9 |
| `schemas/cached_profile.dart` | 9 |
| `schemas/cached_trip_day.dart` | 9 |
| `schemas/cached_trip_place.dart` | 9 |
| `schemas/cached_gallery_photo.dart` | 9 |
| `schemas/cached_message.dart` | 9 |
| `schemas/cached_trip_link.dart` | 9 |
| `schemas/cached_poll.dart` | 9 |
| `schemas/pending_action.dart` | 9 |

### Widgets (`lib/widgets/`)
| File | Phase |
|---|---|
| `offline_banner.dart` | 9 |
| `back_online_banner.dart` | 9 |

### SQL Migrations (`sql/`)
| File | Phase |
|---|---|
| `gallery_thumbnail.sql` | 1 |
| `polls_permission.sql` | 2 |
| `trip_metadata.sql` | 5 |
| `international_info.sql` | 6 |
| `profiles_country_code.sql` | 6 |
| `place_insights.sql` | 7 |
| `ai_memory.sql` | 8 |
| `expenses.sql` | 10 |
| `checklist.sql` | 11 |

---

## Dependency Changes Summary

| Package | Phase | Purpose |
|---|---|---|
| `path` | 1 | Path manipulation for thumbnails |
| `isar` | 9 | Local database |
| `isar_flutter_libs` | 9 | Isar platform bindings |
| `isar_generator` (dev) | 9 | Code generation for Isar schemas |
| `build_runner` (dev) | 9 | Code generation runner |
| `flutter_cache_manager` | 9 | Image pre-caching for offline |
| `fl_chart` | 12 | Pie charts, line charts for budget analytics |

**Already present** (no changes needed):
- `flutter_image_compress` ✅
- `cached_network_image` ✅
- `connectivity_plus` ✅
- `path_provider` ✅
- `image_picker` ✅
- `url_launcher` ✅
- `shared_preferences` ✅

---

## Implementation Timeline (Suggested Order)

| Week | Phases | Effort |
|---|---|---|
| **Week 1** | Phase 1 (Gallery perf) + Phase 2 (Polls perm) + Phase 3 (Dedup) | 3-4 days |
| **Week 2** | Phase 4 (Reset password) + Phase 5 (Trip intelligence) | 3-4 days |
| **Week 3** | Phase 6 (International info) + Phase 11 (Checklist) | 3-4 days |
| **Week 4** | Phase 7 (Place detail enhancement) | 4-5 days |
| **Week 5** | Phase 8 (AI memory) + Phase 13 (Emergency) | 2-3 days |
| **Week 6-7** | Phase 9 (Offline mode — foundation) | 8-10 days |
| **Week 8** | Phase 9 (Offline mode — repositories + sync) | 5 days |
| **Week 9** | Phase 10 (Expense split) | 5 days |
| **Week 10** | Phase 12 (Budget analytics) + Polish | 3-4 days |

**Total estimated: ~10 weeks for a solo developer**

---

## Risk Notes

1. **Isar maintenance**: Isar's maintainer has slowed development. If Isar becomes unmaintained, alternatives: `drift` (SQL-based) or `objectbox`. The repository pattern makes switching databases easy.

2. **Gemini API costs**: Phases 5, 6, 7 all call Gemini for enrichment. Always cache responses in DB. One enrichment call per trip/place, not per view.

3. **Google Places API costs**: Phase 7 (nearby attractions) makes additional API calls. Set `maxResults: 4` and cache results.

4. **Offline sync conflicts**: If two members edit the same data offline, last-write-wins is simplest. For expenses, append-only is safer (no edit conflicts).

5. **RLS policy testing**: Every new table needs RLS policies tested. Create a test user with member role (not owner) and verify access.

6. **Migration order matters**: Phase 6 depends on Phase 5 (needs `trip_metadata`). Phase 12 depends on Phase 10 (needs expense data). Phase 9 should be last because it touches all screens.
