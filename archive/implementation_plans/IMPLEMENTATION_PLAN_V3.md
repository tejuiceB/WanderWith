# WanderWith V3 — Implementation Plan
## Visa Logic, Smart Intel, Professional PDF Export, Account Management

> **Status**: Planning  
> **Created**: March 2, 2026  
> **Scope**: 7 major features across ~15 files  

---

## Table of Contents

1. [Phase 1: Passport & Nationality Fields](#phase-1)
2. [Phase 2: Dynamic Visa Logic (AI-Powered)](#phase-2)
3. [Phase 3: Smart Conditional UI (Country-Smart Intel)](#phase-3)
4. [Phase 4: Smart Checklist Auto-Add for Visa](#phase-4)
5. [Phase 5: Change Email in Settings](#phase-5)
6. [Phase 6: Professional Multi-Page PDF Export](#phase-6)
7. [Phase 7: QR Code Deep Link & Watermark System](#phase-7)

---

<a name="phase-1"></a>
## Phase 1: Passport & Nationality Fields

### Problem
User's profile has a generic `country` field (residence), but no `passport_country` field. Visa requirements depend on **passport nationality**, not residence.

### Current State
- `UserProfile` model has: `country` (String?)
- No `passport_country` or `residence_country` fields
- `_loadInternationalInfo()` in `trip_dashboard_screen.dart` uses `authService.userProfile?.country` for the user's country

### Implementation Steps

#### Step 1.1: SQL Migration — Add Profile Columns
**File**: `sql/passport_country_migration.sql` (NEW)

```sql
-- Add passport_country and residence_country to profiles
ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS passport_country TEXT,
  ADD COLUMN IF NOT EXISTS residence_country TEXT;

-- Backfill: Copy existing country → both new fields as default
UPDATE profiles 
SET passport_country = country, 
    residence_country = country 
WHERE country IS NOT NULL 
  AND passport_country IS NULL;
```

#### Step 1.2: Update UserProfile Model
**File**: `lib/models/user_profile.dart`

- Add fields:
  ```dart
  final String? passportCountry;
  final String? residenceCountry;
  ```
- Add to constructor with defaults
- Add to `fromMap()`: read `passport_country`, `residence_country`
- Add to `toMap()`: write both fields
- Add convenience getter:
  ```dart
  /// Returns the best country to use for visa determination.
  /// Priority: passportCountry → country → residenceCountry
  String? get nationalityCountry => passportCountry ?? country ?? residenceCountry;
  ```

#### Step 1.3: Update Auth Service
**File**: `lib/services/auth_service.dart`

- In `_fetchUserProfile()`: Add `passportCountry` and `residenceCountry` to the fields read from Supabase

#### Step 1.4: Add to Profile Edit / Onboarding
**File**: `lib/screens/edit_profile_screen.dart`

- Add two new fields under the existing "Country" field:
  - **Passport Country** — dropdown or text field with country autocomplete
  - **Residence Country** — dropdown or text field
- Pre-fill both from `country` if they're null (backward compat)
- Save both to Supabase on update

**File**: `lib/screens/onboarding_screen.dart` (if exists)
- Add passport country step after country selection

#### Step 1.5: Update International Info Loading
**File**: `lib/screens/trip_dashboard_screen.dart` → `_loadInternationalInfo()`

- Change:
  ```dart
  // OLD
  final userCountry = authService.userProfile?.country ?? '';
  // NEW
  final userCountry = authService.userProfile?.nationalityCountry ?? authService.userProfile?.country ?? '';
  ```
- This ensures visa/embassy lookups use passport nationality, not just residence

### Files Modified
| File | Action |
|------|--------|
| `sql/passport_country_migration.sql` | CREATE |
| `lib/models/user_profile.dart` | MODIFY (add 2 fields, fromMap, toMap, getter) |
| `lib/services/auth_service.dart` | MODIFY (_fetchUserProfile) |
| `lib/screens/edit_profile_screen.dart` | MODIFY (add 2 inputs) |
| `lib/screens/trip_dashboard_screen.dart` | MODIFY (_loadInternationalInfo) |

### Estimated LOC: ~80

---

<a name="phase-2"></a>
## Phase 2: Dynamic Visa Logic (AI-Powered)

### Problem  
Current visa field in `TripMetadata` is a static string like `"Yes"` / `"No"` — it's not personalized per user's nationality.

### Current State
- `TripMetadata.visaRequired` = generic string from AI (e.g., "Yes" or "No")
- `TripInternationalInfo` already has per-user visa fields: `visaRequired` (bool), `visaType`, `stayDuration`, `processingTime`, `visaApplyUrl`
- `GeminiService.getInternationalTravelInfo(userCountry, destination)` already asks Gemini for nationality-specific visa info
- The **international travel card** already displays visa info conditionally
- The issue is: `enrichDestination()` asks for visa from "most common nationalities perspective" — NOT user-specific

### Why NOT a Static `visa_rules` Table
A static table would require maintaining thousands of passport×destination combinations and would quickly become outdated. Instead, we already use **Gemini AI** for per-user visa info via `getInternationalTravelInfo()`. The AI approach is:
- Always up-to-date (LLM training data + real-time knowledge)
- Handles edge cases (dual nationality, special visa agreements)
- Already implemented in `TripInternationalInfo`

### Implementation Steps

#### Step 2.1: Enhance Gemini Visa Prompt
**File**: `lib/services/gemini_service.dart` → `getInternationalTravelInfo()`

Current prompt already asks for visa info. Enhance it to include:
```
"visa_fee_estimate": "approximate visa fee in USD (e.g., '$40' or 'Free')",
"visa_recommended_apply_date": "how many days before travel to apply (e.g., '30 days before departure')",
"entry_requirements": "COVID/vaccine/health requirements if any, or 'None currently'",
"driving_side": "Left or Right",
```

#### Step 2.2: Update TripInternationalInfo Model
**File**: `lib/models/trip_international_info.dart`

Add fields:
```dart
final String? visaFeeEstimate;
final String? visaRecommendedApplyDate;
final String? entryRequirements;
final String? drivingSide;
```

Update `fromJson()` and `toJson()`.

#### Step 2.3: SQL Migration — Add New Columns to trip_international_info
**File**: `sql/passport_country_migration.sql` (append)

```sql
ALTER TABLE trip_international_info
  ADD COLUMN IF NOT EXISTS visa_fee_estimate TEXT,
  ADD COLUMN IF NOT EXISTS visa_recommended_apply_date TEXT,
  ADD COLUMN IF NOT EXISTS entry_requirements TEXT,
  ADD COLUMN IF NOT EXISTS driving_side TEXT;
```

#### Step 2.4: Update International Travel Card Display
**File**: `lib/screens/trip_dashboard_screen.dart` → `_buildInternationalTravelCard()`

In the Visa Section, add:
```
If visa_required:
  🛂 Visa Required
  ⏳ Processing Time: {processingTime}
  💰 Estimated Fee: {visaFeeEstimate}  
  📅 Apply By: {visaRecommendedApplyDate} (contextual to trip start date)
  📄 Apply Online → {visaApplyUrl}

If visa on arrival:
  🛂 Visa on Arrival
  📍 Get at airport
  💰 Approx fee: {visaFeeEstimate}
  📋 Stay: {stayDuration}

If not required:
  ✅ No Visa Required
  📋 Stay: {stayDuration}
```

Also add new sections:
- **Entry Requirements**: `entryRequirements` (COVID, vaccines)
- **Driving Side**: `drivingSide` in the Connectivity section

#### Step 2.5: Contextual Visa Apply Date
**File**: `lib/screens/trip_dashboard_screen.dart` → `_buildInternationalTravelCard()`

If trip has a `startDate` and `visaRecommendedApplyDate` mentions "X days before":
- Parse the days and calculate actual date
- Show: "📅 Recommended apply before: {calculated_date}"
- If that date has passed, show warning: "⚠️ Apply ASAP — recommended deadline passed"

### Files Modified
| File | Action |
|------|--------|
| `lib/services/gemini_service.dart` | MODIFY (enhance prompt) |
| `lib/models/trip_international_info.dart` | MODIFY (add 4 fields) |
| `sql/passport_country_migration.sql` | MODIFY (append columns) |
| `lib/screens/trip_dashboard_screen.dart` | MODIFY (_buildInternationalTravelCard) |
| `lib/services/trip_service.dart` | MODIFY (enrichInternationalInfo — pass new fields) |

### Estimated LOC: ~120

---

<a name="phase-3"></a>
## Phase 3: Smart Conditional UI (Country-Smart Intel)

### Problem  
When user's country == trip's destination country (domestic trip), the UI still shows visa, embassy, and currency exchange info — which is irrelevant.

### Current State
- `_isInternational` flag already exists in `_OverviewTab`
- `_loadInternationalInfo()` already determines domestic vs international
- The international card is already hidden for domestic trips
- But: the Destination Intel card (`_buildTripIntelligenceCard`) still shows visa/currency for all trips

### Implementation Steps

#### Step 3.1: Conditional Intel Card Fields
**File**: `lib/screens/trip_dashboard_screen.dart` → `_buildTripIntelligenceCard()`

Already partially done! Lines 1467-1469 already hide visa/currency for domestic:
```dart
if (_isInternational)
  _intelRow(colors, "🛂 Visa", _metadata!.visaRequired ?? "-"),
if (_isInternational)
  _intelRow(colors, "💱 Currency", ...),
```

Additional changes needed:
- Also hide currency exchange reminder for domestic trips
- Show only "Local Emergency" for domestic (not embassy)
- For domestic trips, instead of hiding everything, show a subtle note: "🏠 Domestic trip — no visa or embassy needed"

#### Step 3.2: Smart Emergency Info Card
**File**: `lib/screens/trip_dashboard_screen.dart` → `_buildEmergencyInfoCard()`

- If domestic: Show only local emergency numbers (police, medical, fire)
- If international: Show all (local emergency + embassy emergency line)
- Already partially implemented — just needs the domestic/international split for what to display

#### Step 3.3: Conditional Metadata in Trip Intel
When `_isInternational == false`, hide from Destination Intel:
- Visa row
- Currency row  
- Add row: "🏠 Domestic" with "No visa or foreign exchange needed"

When `_isInternational == true`, show all as-is plus:
- Embassy section
- Entry requirements (from Phase 2)
- Driving side (from Phase 2)

### Files Modified
| File | Action |
|------|--------|
| `lib/screens/trip_dashboard_screen.dart` | MODIFY (_buildTripIntelligenceCard, _buildEmergencyInfoCard) |

### Estimated LOC: ~40

---

<a name="phase-4"></a>
## Phase 4: Smart Checklist Auto-Add for Visa

### Problem  
When visa is required, the checklist should automatically include visa-specific items. When visa is NOT required, those items should NOT appear.

### Current State
- `ChecklistService.generateDefaults()` already has an `isInternational` flag
- International items already include: "Passport valid 6+ months", "Visa approved / printed", "Currency exchanged", etc.
- `generateSmartChecklist()` uses Gemini AI and mentions "For international trips, include visa, currency exchange" in the prompt
- But there's no specific **visa-conditional** logic

### Implementation Steps

#### Step 4.1: Add Visa-Conditional Items to Defaults
**File**: `lib/services/checklist_service.dart` → `generateDefaults()`

Change the international items to be visa-conditional:
```dart
// Always for international:
{'text': 'Passport valid 6+ months', 'category': 'documents'},
{'text': 'Currency exchanged', 'category': 'money'},
{'text': 'International SIM / eSIM', 'category': 'packing'},
{'text': 'Travel adapter / converter', 'category': 'packing'},

// Only if visa required:
if (visaRequired) ...[
  {'text': 'Visa application form', 'category': 'documents'},
  {'text': 'Visa appointment booked', 'category': 'documents'},
  {'text': 'Visa approval copy', 'category': 'documents'},
  {'text': 'Passport-size photos (visa)', 'category': 'documents'},
],

// Only if visa NOT required — remove visa items:
if (!visaRequired) ...[
  // No visa items needed
]
```

Method signature change:
```dart
Future<List<ChecklistItem>> generateDefaults({
  required String tripId,
  required bool isInternational,
  bool visaRequired = false,  // NEW
}) async {
```

#### Step 4.2: Pass Visa Status to Checklist Generation
**File**: `lib/screens/trip_dashboard_screen.dart` 

Where checklist is generated (in `_loadInternationalInfo` or wherever `generateDefaults` / `generateSmartChecklist` is called):
```dart
await _checklistService.generateDefaults(
  tripId: widget.trip.id,
  isInternational: _isInternational,
  visaRequired: _internationalInfo?.visaRequired ?? false,
);
```

#### Step 4.3: Enhanced AI Prompt for Smart Checklist
**File**: `lib/services/checklist_service.dart` → `_callGeminiForChecklist()`

Add visa context to the prompt:
```
- Visa required: $visaRequired
- If visa required, include: visa application, appointment, approval copy, passport photos
- If visa NOT required, do NOT include any visa-related items
```

Method signature change:
```dart
Future<List<Map<String, dynamic>>> _callGeminiForChecklist(
  Trip trip,
  bool isInternational,
  {bool visaRequired = false}  // NEW
) async {
```

### Files Modified
| File | Action |
|------|--------|
| `lib/services/checklist_service.dart` | MODIFY (generateDefaults, _callGeminiForChecklist) |
| `lib/screens/trip_dashboard_screen.dart` | MODIFY (pass visaRequired to checklist) |

### Estimated LOC: ~50

---

<a name="phase-5"></a>
## Phase 5: Change Email in Settings

### Current State — ALREADY IMPLEMENTED ✅
After investigating the codebase:

- **Settings Screen** (`settings_screen.dart`): Already has "Email" under Account Info with `onTap: _changeEmail(context, authService)` for email users
- **`_changeEmail()`** method: Already exists at ~line 1340. It:
  1. Shows dialog with current email
  2. Asks for new email + current password
  3. Calls `authService.changeEmail(password, newEmail)`
  4. Shows "Confirmation email sent to {newEmail}. Please verify to complete the change."
- **`_changePassword()`**: Already exists with full validation (8 chars, uppercase, number, match, different from current)
- **Google users**: See "Signed in with Google — Password & email managed by Google" (no edit)

### Verdict: NO CHANGES NEEDED
Both Change Email and Change Password are fully implemented with proper UX:
- Password confirmation required
- Email verification flow
- Google user detection
- Input validation

---

<a name="phase-6"></a>
## Phase 6: Professional Multi-Page PDF Export

### Problem  
Current PDF export (`export_service.dart`) uses `pw.MultiPage` but produces a basic single-flow document with minimal styling. It's functional but not professional-looking.

### Current State
- `ExportService` exists with `exportAsPdf()` and `exportAsJson()`
- Uses `pdf: ^3.11.1` package
- Has: header (brand color banner), sections (overview, members, itinerary, checklist, expenses, emergency)
- Missing: Cover page, watermark, QR code, page separations, better typography, export options menu

### Implementation Steps

#### Step 6.1: Add Dependencies
**File**: `pubspec.yaml`

```yaml
qr_flutter: ^4.1.0    # QR code generation (for cover page)
printing: ^5.12.0      # Print support
```

Note: `qr_flutter` renders to a widget, but for PDF we need `qr` package or render QR manually with the `pdf` package's `BarcodeWidget`.

Actually, the `pdf` package has built-in barcode support:
```dart
pw.BarcodeWidget(
  barcode: Barcode.qrCode(),
  data: 'https://wanderwith.online/trip/abc123',
  width: 80, height: 80,
);
```
So no extra package needed for QR in PDF.

#### Step 6.2: Restructure PDF into Separate Pages
**File**: `lib/services/export_service.dart` — MAJOR REWRITE

Replace single `MultiPage` with structured pages:

```dart
Future<void> exportAsPdf(Trip trip) async {
  final data = await _gatherData(trip);
  final pdf = pw.Document();
  
  // Page 1: Cover Page
  pdf.addPage(_buildCoverPage(data));
  
  // Page 2: Trip Overview
  pdf.addPage(_buildOverviewPage(data));
  
  // Pages 3+: Day-by-Day Itinerary (auto-paginate)
  pdf.addPage(_buildItineraryPages(data));
  
  // Budget Section
  if (data.expenses.isNotEmpty) {
    pdf.addPage(_buildBudgetPage(data));
  }
  
  // Checklist Section
  if (data.checklist.isNotEmpty) {
    pdf.addPage(_buildChecklistPages(data));
  }
  
  // Final Page: Crew + QR
  pdf.addPage(_buildCrewPage(data));
  
  // Save & share...
}
```

#### Step 6.3: Cover Page Design
**Method**: `_buildCoverPage(_ExportData data)`

Layout:
```
┌─────────────────────────────────┐
│                                 │
│        [Trip Cover Image]       │  ← If available (from trip metadata or first photo)
│        (faded background)       │
│                                 │
│     ━━━━━━━━━━━━━━━━━━━━━━━    │
│                                 │
│       TRIP NAME                 │  ← Large, bold, outfit font
│       📍 London, UK  🇬🇧       │  ← Location + flag emoji
│                                 │
│       📅 Mar 15 — Mar 22       │  ← Dates
│       👥 4 Travelers            │  ← Member count
│       💰 £5,000 Budget          │  ← Budget
│       ● Planning                │  ← Status badge
│                                 │
│     ━━━━━━━━━━━━━━━━━━━━━━━    │
│                                 │
│        ┌──────────┐             │
│        │ QR Code  │             │  ← Links to trip
│        │          │             │
│        └──────────┘             │
│     Scan to open this trip      │
│                                 │
│   ─────────────────────────     │
│   WanderWith.online             │  ← Footer branding
│   Generated: Mar 2, 2026       │
└─────────────────────────────────┘
```

Implementation approach:
- Use `pw.Page` (not MultiPage) with full-page layout
- Background: light gradient or solid brand color area at top
- QR: `pw.BarcodeWidget(barcode: Barcode.qrCode(), data: tripUrl)`
- Trip URL: `https://wanderwith.online/trip/{trip_id}`

#### Step 6.4: Overview Page
**Method**: `_buildOverviewPage(_ExportData data)`

```
┌─────────────────────────────────┐
│  TRIP OVERVIEW                  │
│  ═══════════════                │
│                                 │
│  Destination    London, UK      │
│  Duration       7 days          │
│  Travelers      4 people        │
│  Budget         £5,000          │
│  Per Person     £1,250          │
│  Currency       GBP (Pound)     │
│  Status         Planning        │
│                                 │
│  ─── Visa Info ───              │  ← Only if international
│  🛂 Visa Required               │
│  Processing: 15-30 days         │
│  Apply: gov.uk/visa             │
│                                 │
│  ─── Emergency ───              │
│  Emergency: 999                 │
│  Police: 999                    │
│  Medical: 999                   │
│                                 │
│  ─── Destination Intel ───      │
│  Timezone: GMT+0                │
│  Language: English              │
│  Best Time: June – August ☀️   │
│  Plug Type: Type G              │
│                                 │
│  Page 2 — WanderWith.online     │
└─────────────────────────────────┘
```

Fetches: `_ExportData.metadata` + `TripInternationalInfo` (add to _gatherData)

#### Step 6.5: Itinerary Pages (Day-by-Day)  
**Method**: `_buildItineraryPages(_ExportData data)`

Uses `pw.MultiPage` for auto-pagination:
```
DAY 1 — March 15
──────────────────
  09:00 AM    Big Ben
              📍 Westminster, London
              
  01:00 PM    London Eye  
              📍 South Bank
              
  07:00 PM    Dinner in Soho
              📍 Soho, London

  Notes: Pre-book tickets, reach early
  
──────────────────────────────────
DAY 2 — March 16
──────────────────
  ...
```

Each day:
- Day header with number + date (if trip has dates, calculate from startDate + dayNumber)
- Timeline format with time + place name + location
- Notes section if day has a summary
- Auto-paginate if content overflows

#### Step 6.6: Budget Page
**Method**: `_buildBudgetPage(_ExportData data)`

```
BUDGET BREAKDOWN
════════════════

Category        Amount      %
─────────────────────────────
Accommodation   £2,000     40%
Transport       £800       16%
Food            £600       12%
Activities      £400        8%
Other           £1,200     24%
─────────────────────────────
TOTAL           £5,000    100%
Per Person      £1,250

Expense Log:
┌──────────────┬─────────┬──────────┬──────────┐
│ Item         │ Amount  │ Category │ Date     │
├──────────────┼─────────┼──────────┼──────────┤
│ Hotel Booking│ £2,000  │ Stay     │ Mar 10   │
│ Train Tickets│ £200    │ Transport│ Mar 12   │
└──────────────┴─────────┴──────────┴──────────┘
```

- Group expenses by category
- Show percentage breakdown
- Per-person calculation: total ÷ member count
- Full expense table below

#### Step 6.7: Checklist Pages
**Method**: `_buildChecklistPages(_ExportData data)`

```
TRAVEL CHECKLIST
════════════════

📄 Documents
  ☑ Passport valid 6+ months
  ☑ Visa approved / printed
  ☐ Travel insurance
  ☐ Hotel confirmation

🧳 Packing
  ☑ Phone charger & power bank
  ☐ Weather-appropriate clothing
  ☐ Travel adapter

💊 Health
  ☐ Medications / first aid
  ☐ Vaccination certificates

💰 Money
  ☑ Cash / cards
  ☐ Currency exchanged
```

- Group by category with emoji headers
- ☑ for checked, ☐ for unchecked
- Auto-paginate

#### Step 6.8: Crew Page (Final)
**Method**: `_buildCrewPage(_ExportData data)`

```
┌─────────────────────────────────┐
│                                 │
│  THE CREW                       │
│  ════════                       │
│                                 │
│  👑 Tejas (Admin)               │  ← Owner highlighted
│  👤 Alex                        │
│  👤 Sarah                       │
│  👤 Mike                        │
│                                 │
│  ─────────────────────────      │
│                                 │
│        ┌──────────┐             │
│        │ QR Code  │             │
│        └──────────┘             │
│     Scan to open in app         │
│                                 │
│  Trip ID: abc-123-def           │
│                                 │
│  ─────────────────────────      │
│  Planned with WanderWith        │
│  wanderwith.online              │
│  Generated: Mar 2, 2026         │
└─────────────────────────────────┘
```

#### Step 6.9: Watermark on Every Page
**Approach**: Use `pw.MultiPage`'s `build` or wrap each page's content.

The `pdf` package supports watermarks via `pw.Watermark`:
```dart
pw.Page(
  build: (context) => pw.Watermark(
    child: pw.Text('WanderWith.online',
      style: pw.TextStyle(
        fontSize: 60,
        color: PdfColor.fromHex('#E0E0E0'),
      ),
    ),
    angle: -45,  // Diagonal
  ),
)
```

Alternative approach using `pw.Stack`:
```dart
pw.Stack(
  children: [
    // Watermark layer
    pw.Center(
      child: pw.Transform.rotate(
        angle: -0.5,  // ~30 degrees
        child: pw.Text(
          'WanderWith.online',
          style: pw.TextStyle(fontSize: 50, color: PdfColors.grey200),
        ),
      ),
    ),
    // Content layer
    actualContent,
  ],
)
```

Apply to every page via the `pageTheme` parameter with a consistent watermark builder.

#### Step 6.10: Consistent Page Theme
**Shared across all pages**:

```dart
pw.PageTheme _buildPageTheme() {
  return pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(40),
    buildBackground: (context) => pw.Stack(
      children: [
        // Watermark
        pw.Positioned.fill(
          child: pw.Center(
            child: pw.Transform.rotate(
              angle: -0.5,
              child: pw.Opacity(
                opacity: 0.06,
                child: pw.Text('WanderWith.online',
                  style: pw.TextStyle(fontSize: 60, fontWeight: pw.FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
```

Footer on every page:
```dart
footer: (context) => pw.Container(
  alignment: pw.Alignment.centerRight,
  margin: const pw.EdgeInsets.only(top: 12),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text('Generated via WanderWith.online',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
    ],
  ),
),
```

#### Step 6.11: Fetch International Info for PDF
**File**: `lib/services/export_service.dart` → `_gatherData()`

Add to parallel fetches:
```dart
_fetchInternationalInfo(trip.id, userId),
```

Add to `_ExportData`:
```dart
final TripInternationalInfo? internationalInfo;
```

#### Step 6.12: Export Options Menu
**File**: `lib/screens/trip_dashboard_screen.dart`

Update the export button to show options:
```dart
showModalBottomSheet(
  children: [
    ListTile(icon: 📄, title: "Professional Itinerary (PDF)", onTap: exportFullPdf),
    ListTile(icon: 📋, title: "Checklist Only (PDF)", onTap: exportChecklistPdf),
    ListTile(icon: 📦, title: "Raw Data (JSON)", onTap: exportJson),
  ],
);
```

#### Step 6.13: Checklist-Only PDF Export
**File**: `lib/services/export_service.dart`

New method:
```dart
Future<void> exportChecklistPdf(Trip trip) async {
  // Fetch only checklist data
  // Single-page or multi-page PDF with just checklist grouped by category
  // Include trip name + location in header
  // Watermark + footer
}
```

### Files Modified
| File | Action |
|------|--------|
| `pubspec.yaml` | MODIFY (add printing package — qr_flutter NOT needed, pdf has BarcodeWidget) |
| `lib/services/export_service.dart` | MAJOR REWRITE (~500 lines) |
| `lib/screens/trip_dashboard_screen.dart` | MODIFY (export options menu) |

### Estimated LOC: ~600

---

<a name="phase-7"></a>
## Phase 7: QR Code Deep Link & Universal Link System

### Problem  
QR code in PDF should open the trip in the app (if installed) or website (if not).

### Implementation Steps

#### Step 7.1: URL Structure
```
https://wanderwith.online/trip/{trip_id}
```

For security (prevent guessing trip IDs), use a short-code system:
```
https://wanderwith.online/t/{short_code}
```

But since trip IDs are UUIDs (e.g., `a3b4c5d6-e7f8-9012-3456-789abcdef012`), they're already unguessable. Use the full trip ID for simplicity in v1.

#### Step 7.2: QR Code in PDF
**File**: `lib/services/export_service.dart`

Already planned in Phase 6. Use:
```dart
pw.BarcodeWidget(
  barcode: Barcode.qrCode(),
  data: 'https://wanderwith.online/trip/${data.trip.id}',
  width: 80,
  height: 80,
  color: PdfColors.grey800,
)
```

#### Step 7.3: Android App Links
**File**: `android/app/src/main/AndroidManifest.xml`

Add intent filter to the main activity:
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https"
        android:host="wanderwith.online"
        android:pathPrefix="/trip/" />
  <data android:scheme="https"
        android:host="wanderwith.online"
        android:pathPrefix="/t/" />
</intent-filter>
```

#### Step 7.4: iOS Universal Links
**File**: `ios/Runner/Runner.entitlements`

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:wanderwith.online</string>
</array>
```

#### Step 7.5: Website .well-known Files
**File**: `WanderWithSite/public/.well-known/assetlinks.json` (Android)
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.tejuice.wanderwith",
    "sha256_cert_fingerprints": ["YOUR_SHA256_HERE"]
  }
}]
```

**File**: `WanderWithSite/public/.well-known/apple-app-site-association` (iOS)
```json
{
  "applinks": {
    "details": [{
      "appID": "TEAM_ID.com.tejuice.wanderwith",
      "paths": ["/trip/*", "/t/*"]
    }]
  }
}
```

#### Step 7.6: Flutter Deep Link Handler
**File**: `lib/main.dart` or `lib/services/deep_link_service.dart` (NEW)

```dart
class DeepLinkService {
  static void init() {
    // Listen for incoming links
    // Parse: https://wanderwith.online/trip/{id}
    // Navigate to TripDashboardScreen with trip ID
    // If user not logged in → show trip preview + login prompt
  }
}
```

Use `app_links` or `uni_links` package for cross-platform deep link handling.

#### Step 7.7: Website Trip Page (Fallback)
**File**: `WanderWithSite/src/app/trip/[tripId]/page.tsx` (NEW)

When user has no app installed:
```
┌─────────────────────────────────┐
│  WanderWith                     │
│                                 │
│  Trip: London Adventure         │
│  📍 London, UK                  │
│  📅 Mar 15 — Mar 22            │
│                                 │
│  [Open in App]                  │
│  [Get it on Play Store]         │
│                                 │
│  Planned with WanderWith        │
└─────────────────────────────────┘
```

This fetches basic trip info from Supabase (public fields only) and shows a preview.

### Files Modified
| File | Action |
|------|--------|
| `lib/services/export_service.dart` | MODIFY (QR in PDF — already in Phase 6) |
| `android/app/src/main/AndroidManifest.xml` | MODIFY (intent filter) |
| `ios/Runner/Runner.entitlements` | MODIFY (associated domains) |
| `WanderWithSite/public/.well-known/assetlinks.json` | CREATE |
| `WanderWithSite/public/.well-known/apple-app-site-association` | CREATE |
| `lib/services/deep_link_service.dart` | CREATE |
| `lib/main.dart` | MODIFY (init deep link service) |
| `WanderWithSite/src/app/trip/[tripId]/page.tsx` | CREATE |
| `pubspec.yaml` | MODIFY (add app_links package) |

### Estimated LOC: ~250

---

## Execution Order & Dependencies

```
Phase 1 ──→ Phase 2 ──→ Phase 3
   │            │
   │            ↓
   │        Phase 4
   │
   ↓
Phase 5 (DONE — no work needed)

Phase 6 (independent, can run parallel with 1-4)
   │
   ↓
Phase 7 (depends on Phase 6 for QR placement)
```

### Recommended Build Order:
1. **Phase 1** → Foundation (passport_country field)
2. **Phase 2** → Enhanced visa logic uses Phase 1's nationality
3. **Phase 3** → Small UI conditionals, quick win
4. **Phase 4** → Smart checklist uses Phase 2's visa status
5. **Phase 6** → Major PDF rewrite (can start anytime)
6. **Phase 7** → QR + deep links (after Phase 6 cover page is built)

Phase 5 is already complete — no action needed.

---

## Summary Table

| Phase | Feature | Files | LOC | Status |
|-------|---------|-------|-----|--------|
| 1 | Passport Country Fields | 5 | ~80 | NOT STARTED |
| 2 | Dynamic Visa Logic | 5 | ~120 | NOT STARTED |
| 3 | Country-Smart UI | 1 | ~40 | NOT STARTED |
| 4 | Smart Checklist Auto-Add | 2 | ~50 | NOT STARTED |
| 5 | Change Email in Settings | 0 | 0 | ✅ ALREADY DONE |
| 6 | Professional PDF Export | 3 | ~600 | NOT STARTED |
| 7 | QR + Deep Links | 9 | ~250 | NOT STARTED |
| **TOTAL** | | **~25 files** | **~1,140** | |

---

## SQL Migration (Combined)
Run in Supabase Dashboard — SQL Editor:

```sql
-- File: sql/passport_country_migration.sql

-- 1. Profile: passport & residence country
ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS passport_country TEXT,
  ADD COLUMN IF NOT EXISTS residence_country TEXT;

UPDATE profiles 
SET passport_country = country, 
    residence_country = country 
WHERE country IS NOT NULL 
  AND passport_country IS NULL;

-- 2. International info: new visa/entry fields
ALTER TABLE trip_international_info
  ADD COLUMN IF NOT EXISTS visa_fee_estimate TEXT,
  ADD COLUMN IF NOT EXISTS visa_recommended_apply_date TEXT,
  ADD COLUMN IF NOT EXISTS entry_requirements TEXT,
  ADD COLUMN IF NOT EXISTS driving_side TEXT;
```

---

## Package Dependencies (New)

| Package | Version | Purpose |
|---------|---------|---------|
| `printing` | ^5.12.0 | Print PDF support |
| `app_links` | ^6.1.0 | Universal/deep link handling |

No `qr_flutter` needed — the `pdf` package has built-in `BarcodeWidget` for QR codes in PDFs.

---

## Notes & Decisions

1. **No static visa_rules table**: Using Gemini AI for per-user visa info is more accurate and maintainable than a static table. The AI already provides nationality-specific visa, embassy, and emergency data via `getInternationalTravelInfo()`.

2. **Change Email already works**: Full implementation with password verification, email confirmation flow, and Google user detection.

3. **QR security**: UUIDs are unguessable (128-bit). No need for encrypted short links in v1. Can add short-code mapping later if needed.

4. **Watermark approach**: Using `pw.PageTheme.buildBackground` for consistent watermark across all pages.

5. **Cover image in PDF**: If trip has a cover image URL, download bytes and embed. If not, use a solid brand-color header instead. Image download adds latency — make it optional/async.

6. **SDK constraints**: Continue using `MaterialStateProperty` (not WidgetStateProperty) and `.withOpacity()` per project conventions.
