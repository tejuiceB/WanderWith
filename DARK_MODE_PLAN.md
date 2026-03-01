# WanderWith Flutter App — Dark Mode Implementation Plan

> **Goal:** Add Light/Dark theme toggle with zero feature/logic/layout changes.
> **Scope:** 50+ files, ~14,000+ lines of hardcoded colors → centralized, theme-aware system.

---

## Table of Contents

1. [Current State Audit](#1-current-state-audit)
2. [Architecture: Theme System Design](#2-architecture-theme-system-design)
3. [Phase 1 — Foundation (Theme Infrastructure)](#3-phase-1--foundation)
4. [Phase 2 — Theme Provider & Persistence](#4-phase-2--theme-provider--persistence)
5. [Phase 3 — Wire Into MaterialApp](#5-phase-3--wire-into-materialapp)
6. [Phase 4 — Settings Toggle UI](#6-phase-4--settings-toggle-ui)
7. [Phase 5 — Screen-by-Screen Migration](#7-phase-5--screen-by-screen-migration)
8. [Phase 6 — Widget-by-Widget Migration](#8-phase-6--widget-by-widget-migration)
9. [Phase 7 — Bottom Sheets, Dialogs & Overlays](#9-phase-7--bottom-sheets-dialogs--overlays)
10. [Phase 8 — Polish & Edge Cases](#10-phase-8--polish--edge-cases)
11. [File Change Matrix](#11-file-change-matrix)
12. [Testing Checklist](#12-testing-checklist)

---

## 1. Current State Audit

### What Exists
- `lib/theme/` directory exists but is **completely empty**
- A single `ThemeData` in `main.dart`:
  ```dart
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
    useMaterial3: true,
  )
  ```
- No `darkTheme`, no `themeMode`, no theme provider
- Only 3 `Theme.of(context)` calls in entire codebase (DatePicker, Stepper header, Markdown)

### Problem: 100% Hardcoded Colors
Every single screen sets colors inline:
```dart
// This pattern occurs 200+ times across codebase
Scaffold(backgroundColor: Colors.white, ...)
AppBar(backgroundColor: Colors.white, ...)
Text("...", style: GoogleFonts.outfit(color: Colors.black87))
Container(color: Colors.grey.shade50, ...)
```

### Color Catalog (currently hardcoded everywhere)

| Category | Light Value | Used In |
|---|---|---|
| **Brand Primary** | `#448AFF` | Buttons, links, active states — **ALL screens** |
| **Heading Text** | `#1A1A2E` | Auth, onboarding, splash titles |
| **Body Text** | `Colors.black87` | Every screen |
| **Secondary Text** | `#8E99A4` | Labels, hints, subtitles |
| **Muted Text** | `#BCC5CE` | Hints, branding footer |
| **Scaffold BG** | `Colors.white` | 14+ screens explicit |
| **Card BG** | `Colors.white` | Cards, sheets, dialogs |
| **Field Fill** | `#F8F9FA` | Text field backgrounds |
| **Border** | `#E8ECF0` | Input borders, dividers |
| **Surface Tint** | `Colors.grey.shade50` | Settings items, list tiles |
| **Error** | `#E53935` | Validation, destructive |
| **Success** | `#4CAF50` | Confirmations, checks |
| **Warning** | `#FF9800` | Caution states |

### File Inventory

| File | Lines | Has Hardcoded Colors | Scaffold White BG |
|---|---|---|---|
| `main.dart` | 259 | Yes | — |
| **Auth Screens** | | | |
| `auth/login_screen.dart` | 296 | Heavy | Yes |
| `auth/signup_screen.dart` | 496 | Heavy | Yes |
| `auth/otp_verification_screen.dart` | 340 | Heavy | Yes |
| `auth/forgot_password_screen.dart` | 337 | Heavy | Yes |
| `auth/reset_password_screen.dart` | 329 | Heavy | Yes |
| `auth/widgets/auth_header.dart` | 68 | Yes | — |
| `auth/widgets/auth_text_field.dart` | 102 | Yes | — |
| `auth/widgets/social_sign_in_button.dart` | 72 | Yes | — |
| **Onboarding** | | | |
| `onboarding/onboarding_wizard_screen.dart` | 473 | Heavy | Yes |
| `onboarding/steps/role_step.dart` | 170 | Heavy | — |
| `onboarding/steps/basic_info_step.dart` | 182 | Heavy | — |
| `onboarding/steps/location_step.dart` | 191 | Heavy | — |
| `onboarding/steps/traveler_interests_step.dart` | ~170 | Heavy | — |
| `onboarding/steps/agency_details_step.dart` | ~180 | Heavy | — |
| `onboarding/steps/agency_specializations_step.dart` | ~150 | Heavy | — |
| `onboarding/steps/privacy_step.dart` | ~120 | Heavy | — |
| `onboarding/steps/review_step.dart` | ~250 | Heavy | — |
| `onboarding/widgets/avatar_picker.dart` | ~80 | Yes | — |
| `onboarding/widgets/interest_card.dart` | ~50 | Yes | — |
| `onboarding/widgets/onboarding_progress_bar.dart` | ~40 | Yes | — |
| **Main App Screens** | | | |
| `main_screen.dart` | 260 | Yes | Yes |
| `home_screen.dart` | 331 | Yes | Yes |
| `search_screen.dart` | 529 | Yes | Yes |
| `my_trips_screen.dart` | 146 | Yes | Yes |
| `profile_screen.dart` | 1814 | Heavy | Yes |
| `notifications_screen.dart` | 232 | Partial | No |
| `settings_screen.dart` | 175 | Yes | Yes |
| **Trip Screens** | | | |
| `trip_dashboard_screen.dart` | **4541** | **Very Heavy** | Yes |
| `trip_plan_tab.dart` | 410 | Yes | — |
| `create_trip_screen.dart` | 577 | Yes | Yes |
| `join_trip_screen.dart` | 174 | Yes | Yes |
| **Post Screens** | | | |
| `create_post_screen.dart` | 535 | Yes | Yes |
| `post_detail_screen.dart` | 86 | Yes | Yes |
| **Other Screens** | | | |
| `splash_screen.dart` | 453 | Yes (special) | Gradient |
| `ai_guide_screen.dart` | 373 | Yes | No |
| `place_detail_screen.dart` | 339 | Yes | Yes |
| `blocked_users_screen.dart` | 139 | Yes | Yes |
| `follows_list_screen.dart` | 211 | Yes | Yes |
| `follow_requests_screen.dart` | 192 | Yes | Yes |
| `privacy_settings_screen.dart` | 196 | Yes | Yes |
| `privacy_policy_screen.dart` | 79 | No (clean) | No |
| `terms_conditions_screen.dart` | 64 | No (clean) | No |
| `archived_posts_screen.dart` | 115 | Yes | Yes |
| **Shared Widgets** | | | |
| `widgets/post_card.dart` | 566 | Yes | — |
| `widgets/trip_card.dart` | 133 | Yes | — |
| `widgets/comments_bottom_sheet.dart` | 422 | Yes | — |
| `widgets/add_place_bottom_sheet.dart` | 406 | Yes | — |
| `widgets/ai_generation_overlay.dart` | 257 | Yes | — |
| `widgets/trip_activity_tab.dart` | 75 | Yes | — |
| `widgets/trip_chat_tab.dart` | 1223 | Heavy | — |
| `widgets/timeline_itinerary_item.dart` | 175 | Yes | — |

**Total: ~50 files, ~16,000+ lines to audit and update.**

---

## 2. Architecture: Theme System Design

### Strategy: `ThemeExtension` + Centralized Color Tokens

We will NOT do find-replace with `Theme.of(context).colorScheme.surface` everywhere (too brittle, too many mismatches). Instead:

#### Create `AppColors` ThemeExtension
A custom `ThemeExtension<AppColors>` with semantic tokens matching every hardcoded color in the app:

```dart
// lib/theme/app_colors.dart
class AppColors extends ThemeExtension<AppColors> {
  // Backgrounds
  final Color scaffoldBg;        // Light: #FFFFFF → Dark: #0F0F0F
  final Color cardBg;            // Light: #FFFFFF → Dark: #1E1E1E
  final Color surfaceBg;         // Light: grey.shade50 → Dark: #181818
  final Color fieldFillBg;       // Light: #F8F9FA → Dark: #1E1E1E
  final Color sheetBg;           // Light: #FFFFFF → Dark: #1E1E1E
  final Color dialogBg;          // Light: #FFFFFF → Dark: #1E1E1E
  
  // Text
  final Color textPrimary;       // Light: #1A1A2E / black87 → Dark: #FFFFFF
  final Color textSecondary;     // Light: #8E99A4 → Dark: #B3B3B3
  final Color textMuted;         // Light: #BCC5CE → Dark: #888888
  final Color textOnPrimary;     // White always (for brand-colored buttons)
  
  // Borders & Dividers
  final Color border;            // Light: #E8ECF0 → Dark: rgba(255,255,255,0.08)
  final Color borderSubtle;      // Light: grey.shade100 → Dark: rgba(255,255,255,0.05)
  final Color divider;           // Light: grey.shade200 → Dark: rgba(255,255,255,0.08)
  
  // Interactive
  final Color iconDefault;       // Light: black87 → Dark: #FFFFFF
  final Color iconSecondary;     // Light: grey.shade600 → Dark: #B3B3B3
  final Color iconMuted;         // Light: grey.shade400 → Dark: #888888
  
  // Navigation
  final Color navBarBg;          // Light: #FFFFFF → Dark: #181818
  final Color navSelected;       // Light: #000000 → Dark: #FFFFFF
  final Color navUnselected;     // Light: grey → Dark: #888888
  
  // Chips & Tags
  final Color chipBg;            // Light: blue.shade50 → Dark: #448AFF1A (10% blue)
  final Color chipBorder;        // Light: blue.shade100 → Dark: #448AFF33 (20% blue)
  
  // Status (unchanged between themes — brand identity)
  // Brand: #448AFF (stays same)
  // Error: #E53935 (stays same)
  // Success: #4CAF50 (stays same)
  // Warning: #FF9800 (stays same)
  
  // Shadows
  final Color shadow;            // Light: black.withOpacity(0.03) → Dark: transparent
  
  // Special Surfaces
  final Color searchBarBg;       // Light: grey.shade100 → Dark: #1E1E1E
  final Color hoverBg;           // Light: grey.shade100 → Dark: rgba(255,255,255,0.05)
  final Color skeletonBase;      // Light: grey.shade200 → Dark: #2A2A2A
  final Color skeletonHighlight; // Light: grey.shade100 → Dark: #3A3A3A
}
```

#### Access Pattern (in screens)
```dart
final colors = Theme.of(context).extension<AppColors>()!;

Scaffold(
  backgroundColor: colors.scaffoldBg,  // was Colors.white
  appBar: AppBar(
    backgroundColor: colors.scaffoldBg,
    title: Text("Settings", style: GoogleFonts.outfit(color: colors.textPrimary)),
    leading: Icon(Icons.arrow_back, color: colors.iconDefault),
  ),
)
```

This gives autocomplete, compile-time safety, and a single source of truth.

#### Helper Extension for convenience
```dart
// lib/theme/theme_extensions.dart
extension ThemeContextX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
```

Usage: `context.appColors.scaffoldBg` — shorter than `Theme.of(context).extension<AppColors>()!.scaffoldBg`.

---

## 3. Phase 1 — Foundation

### Files to Create

#### `lib/theme/app_colors.dart`
Full `ThemeExtension<AppColors>` class with:
- All semantic color tokens (listed above)
- `copyWith()` override
- `lerp()` override (for smooth 300ms transition animation)
- Static `light` and `dark` instances with exact hex values

#### `lib/theme/app_theme.dart`
Two complete `ThemeData` objects:
- `AppTheme.light` — current look preserved exactly
- `AppTheme.dark` — dark theme with specified hex values

Each includes:
- `scaffoldBackgroundColor`
- `appBarTheme` (background, elevation, icon color, title style)
- `bottomNavigationBarTheme`
- `cardTheme`
- `dialogTheme`
- `bottomSheetTheme`
- `dividerTheme`
- `inputDecorationTheme` (fill color, border colors, hint style, label style)
- `elevatedButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`
- `chipTheme`
- `switchTheme`, `checkboxTheme`
- `scrollbarTheme`
- `snackBarTheme`
- `extensions: [AppColors.light]` / `extensions: [AppColors.dark]`
- `textTheme` set using GoogleFonts.interTextTheme (won't break since screens use GoogleFonts directly)
- `colorScheme` with proper surface/background/onSurface colors
- `brightness: Brightness.light` / `Brightness.dark`

#### `lib/theme/theme_extensions.dart`
Context extension for concise access:
```dart
extension ThemeContextX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
```

### Exact Color Mapping

| Token | Light Mode | Dark Mode |
|---|---|---|
| `scaffoldBg` | `#FFFFFF` | `#0F0F0F` |
| `cardBg` | `#FFFFFF` | `#1E1E1E` |
| `surfaceBg` | `grey.shade50 (#FAFAFA)` | `#181818` |
| `fieldFillBg` | `#F8F9FA` | `#1E1E1E` |
| `sheetBg` | `#FFFFFF` | `#1E1E1E` |
| `dialogBg` | `#FFFFFF` | `#1E1E1E` |
| `textPrimary` | `#1A1A2E` | `#FFFFFF` |
| `textSecondary` | `#8E99A4` | `#B3B3B3` |
| `textMuted` | `#BCC5CE` | `#888888` |
| `textOnPrimary` | `#FFFFFF` | `#FFFFFF` |
| `border` | `#E8ECF0` | `rgba(255,255,255,0.08)` |
| `borderSubtle` | `grey.shade100` | `rgba(255,255,255,0.05)` |
| `divider` | `grey.shade200` | `rgba(255,255,255,0.08)` |
| `iconDefault` | `Colors.black87` | `#FFFFFF` |
| `iconSecondary` | `grey.shade600` | `#B3B3B3` |
| `iconMuted` | `grey.shade400` | `#888888` |
| `navBarBg` | `#FFFFFF` | `#181818` |
| `navSelected` | `#000000` | `#FFFFFF` |
| `navUnselected` | `grey` | `#888888` |
| `chipBg` | `blue.shade50` | `#448AFF1A` |
| `chipBorder` | `blue.shade100` | `#448AFF33` |
| `shadow` | `black @ 3%` | `transparent` |
| `searchBarBg` | `grey.shade100` | `#1E1E1E` |
| `hoverBg` | `grey.shade100` | `rgba(255,255,255,0.05)` |
| `skeletonBase` | `grey.shade200` | `#2A2A2A` |
| `skeletonHighlight` | `grey.shade100` | `#3A3A3A` |

**Brand colors stay same in both:** `#448AFF`, `#E53935`, `#4CAF50`, `#FF9800`, `#FF7043`

---

## 4. Phase 2 — Theme Provider & Persistence

### File to Create: `lib/providers/theme_provider.dart`

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  
  ThemeProvider() {
    _loadFromPrefs();
  }
  
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
  }
  
  Future<void> setDarkMode(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', dark);
  }
}
```

### Dependency: `shared_preferences`
Already in `pubspec.yaml` (used by other services). No new dependency needed.

---

## 5. Phase 3 — Wire Into MaterialApp

### File: `lib/main.dart`

**Changes:**
1. Import `theme_provider.dart`, `app_theme.dart`
2. Add `ThemeProvider` to `MultiProvider`
3. Wrap `MaterialApp.router` in `Consumer<ThemeProvider>`
4. Set `theme:`, `darkTheme:`, `themeMode:` properties

```dart
// Before:
child: MaterialApp.router(
  routerConfig: _router,
  title: 'WanderWith',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
    useMaterial3: true,
  ),
),

// After:
child: Consumer<ThemeProvider>(
  builder: (context, themeProvider, _) => MaterialApp.router(
    routerConfig: _router,
    title: 'WanderWith',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: themeProvider.themeMode,
  ),
),
```

The 300ms smooth transition comes from `lerp()` in AppColors + Flutter's built-in theme animation on MaterialApp.

---

## 6. Phase 4 — Settings Toggle UI

### File: `lib/screens/settings_screen.dart` (~175 lines)

**Add BEFORE the "Support" section:**

```
├── _buildSectionHeader("Appearance")
├── _buildThemeToggle()   ← NEW: Row with ☀️/🌙 icons and Switch
├── SizedBox(32)
├── _buildSectionHeader("Support")
...rest unchanged
```

The toggle widget:
```dart
Widget _buildThemeToggle(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: context.appColors.surfaceBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.appColors.borderSubtle),
    ),
    child: ListTile(
      leading: Icon(
        themeProvider.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        color: context.appColors.iconDefault,
      ),
      title: Text("Dark Mode", style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: context.appColors.textPrimary)),
      trailing: Switch.adaptive(
        value: themeProvider.isDark,
        onChanged: (_) => themeProvider.toggleTheme(),
        activeColor: Color(0xFF448AFF),
      ),
    ),
  );
}
```

**Also update ALL existing settings items** to use `context.appColors.*` instead of hardcoded colors.

### Detailed Changes in settings_screen.dart

| Line Area | Current | New |
|---|---|---|
| Scaffold bg | `Colors.white` | `context.appColors.scaffoldBg` |
| AppBar bg | `Colors.white` | `context.appColors.scaffoldBg` |
| AppBar title color | `Colors.black87` | `context.appColors.textPrimary` |
| Back icon color | `Colors.black87` | `context.appColors.iconDefault` |
| Section header color | `grey.shade500` | `context.appColors.textSecondary` |
| Item container bg | `grey.shade50` | `context.appColors.surfaceBg` |
| Item border | `grey.shade100` | `context.appColors.borderSubtle` |
| Item icon | `Colors.black87` | `context.appColors.iconDefault` |
| Item text | `Colors.black87` | `context.appColors.textPrimary` |
| Trailing chevron | `grey.shade400` | `context.appColors.iconMuted` |
| Version text | `grey.shade400` | `context.appColors.textMuted` |
| Destructive items | `Colors.redAccent` | Keep `Colors.redAccent` (stays same) |

---

## 7. Phase 5 — Screen-by-Screen Migration

### Migration Pattern (same for every screen)

For each screen file:
1. Add import: `import '../../theme/theme_extensions.dart';`
2. Early in `build()`, get colors: `final colors = context.appColors;`
3. Replace every hardcoded color with the semantic token
4. **DO NOT** change any logic, layout, or functionality

### 7.1 Auth Screens (5 screens + 3 widgets)

#### `auth/login_screen.dart` (296 lines)
| Element | Current Color | Replace With |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| Title "Welcome Back" | `Color(0xFF1A1A2E)` | `colors.textPrimary` |
| Subtitle text | `Color(0xFF8E99A4)` | `colors.textSecondary` |
| "Don't have an account?" | `Color(0xFF8E99A4)` | `colors.textSecondary` |
| "Sign Up" link | `Color(0xFF448AFF)` | Keep (brand) |
| Primary button bg | `Color(0xFF448AFF)` | Keep (brand) |
| Button text | `Colors.white` | Keep (textOnPrimary) |
| Divider "Or continue with" | `Color(0xFFE8ECF0)` + `Color(0xFF8E99A4)` | `colors.border` + `colors.textSecondary` |
| Error text | `Color(0xFFE53935)` | Keep (error) |
| Bottom branding | `Color(0xFFBCC5CE)` | `colors.textMuted` |

#### `auth/signup_screen.dart` (496 lines)
Same pattern as login. Additional:
| Element | Current | Replace |
|---|---|---|
| Password strength bars | Keep colors (semantic: red/orange/green) | Keep |
| Password requirement text | `Color(0xFF8E99A4)` / `Color(0xFF4CAF50)` | `colors.textSecondary` / Keep green |

#### `auth/otp_verification_screen.dart` (340 lines)
| Element | Current | Replace |
|---|---|---|
| OTP boxes border | `Color(0xFFE8ECF0)` | `colors.border` |
| OTP box focused border | `Color(0xFF448AFF)` | Keep (brand) |
| OTP box filled border | `Color(0xFF4CAF50)` | Keep (success) |
| OTP digit text | `Color(0xFF1A1A2E)` | `colors.textPrimary` |
| Timer text | `Color(0xFF8E99A4)` | `colors.textSecondary` |

#### `auth/forgot_password_screen.dart` (337 lines)
Same pattern as login + OTP. Replace heading/subtitle/hint/border colors.

#### `auth/reset_password_screen.dart` (329 lines)
Same pattern. Password strength colors stay.

#### `auth/widgets/auth_header.dart` (68 lines)
| Element | Current | Replace |
|---|---|---|
| Title | `Color(0xFF1A1A2E)` | `colors.textPrimary` |
| Subtitle | `Color(0xFF8E99A4)` | `colors.textSecondary` |

#### `auth/widgets/auth_text_field.dart` (102 lines)
| Element | Current | Replace |
|---|---|---|
| Fill color | `Color(0xFFF8F9FA)` | `colors.fieldFillBg` |
| Border | `Color(0xFFE8ECF0)` | `colors.border` |
| Focused border | `Color(0xFF448AFF)` | Keep (brand) |
| Error border | `Color(0xFFE53935)` | Keep (error) |
| Label text | `Color(0xFF8E99A4)` | `colors.textSecondary` |
| Hint text | `Color(0xFFBCC5CE)` | `colors.textMuted` |
| Input text | `Color(0xFF1A1A2E)` | `colors.textPrimary` |
| Suffix icon | `Color(0xFF8E99A4)` | `colors.iconSecondary` |

#### `auth/widgets/social_sign_in_button.dart` (72 lines)
| Element | Current | Replace |
|---|---|---|
| Button bg | `Colors.white` | `colors.cardBg` |
| Border | `Color(0xFFE8ECF0)` | `colors.border` |
| Text | `Color(0xFF1A1A2E)` | `colors.textPrimary` |
| Google blue icon | `Color(0xFF4285F4)` | Keep (Google brand) |

---

### 7.2 Onboarding Screens (1 wizard + 8 steps + 3 widgets)

#### `onboarding/onboarding_wizard_screen.dart` (473 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| Skip button text | `Color(0xFF8E99A4)` | `colors.textSecondary` |
| Back button bg | `Color(0xFFF5F7FA)` | `colors.surfaceBg` |
| Back button icon | `Color(0xFF6B7280)` | `colors.iconSecondary` |
| Continue button bg | `Color(0xFF448AFF)` | Keep (brand) |
| Disabled button bg | `Color(0xFFBCC5CE)` | `colors.textMuted` |
| Progress bar bg | `Color(0xFFE8ECF0)` | `colors.border` |
| Progress bar fill | `Color(0xFF448AFF)` | Keep (brand) |
| Error text | `Color(0xFFE53935)` | Keep (error) |
| Bottom branding | `Color(0xFFBCC5CE)` | `colors.textMuted` |

#### `onboarding/steps/role_step.dart` (170 lines)
| Element | Current | Replace |
|---|---|---|
| Title | `Color(0xFF1A1A2E)` | `colors.textPrimary` |
| Subtitle | `Color(0xFF8E99A4)` | `colors.textSecondary` |
| Card bg (unselected) | `Colors.white` | `colors.cardBg` |
| Card border (unselected) | `Color(0xFFE8ECF0)` | `colors.border` |
| Card bg (selected) | `Color(0xFF448AFF).withOpacity(0.05)` | Keep brand-tinted |
| Card border (selected) | `Color(0xFF448AFF)` | Keep (brand) |
| Role title | `Color(0xFF1A1A2E)` | `colors.textPrimary` |
| Role description | `Color(0xFF8E99A4)` | `colors.textSecondary` |
| Icon bg | `Color(0xFFF8F9FA)` | `colors.fieldFillBg` |

#### `onboarding/steps/basic_info_step.dart` (182 lines)
Same field/text color pattern. Replace heading, labels, hints, borders, fill.

#### `onboarding/steps/location_step.dart` (191 lines)
Same pattern. Also has "Use my location" button — keep brand color, replace text/border colors.

#### `onboarding/steps/traveler_interests_step.dart` (~170 lines)
| Element | Current | Replace |
|---|---|---|
| Interest chips (unselected) bg | `Colors.white` | `colors.cardBg` |
| Interest chips (unselected) border | `Color(0xFFE8ECF0)` | `colors.border` |
| Interest chips (selected) bg | `Color(0xFF448AFF)` | Keep (brand) |
| Chip text | `Color(0xFF1A1A2E)` / `Colors.white` | `colors.textPrimary` / Keep white |

#### `onboarding/steps/agency_details_step.dart` (~180 lines)
Same field/text color pattern as basic_info_step.

#### `onboarding/steps/agency_specializations_step.dart` (~150 lines)
Same chip pattern as traveler_interests_step.

#### `onboarding/steps/privacy_step.dart` (~120 lines)
| Element | Current | Replace |
|---|---|---|
| Switch active color | `Color(0xFF448AFF)` | Keep (brand) |
| Option card bg | `Colors.white` | `colors.cardBg` |
| Option card border | `Color(0xFFE8ECF0)` | `colors.border` |
| Description text | `Color(0xFF8E99A4)` | `colors.textSecondary` |

#### `onboarding/steps/review_step.dart` (~250 lines)
Review summary cards showing all onboarding data.
| Element | Current | Replace |
|---|---|---|
| Summary card bg | `Colors.white` / `Color(0xFFF8F9FA)` | `colors.cardBg` / `colors.fieldFillBg` |
| Section titles | `Color(0xFF1A1A2E)` | `colors.textPrimary` |
| Value text | `Color(0xFF8E99A4)` | `colors.textSecondary` |
| Dividers | `Color(0xFFE8ECF0)` | `colors.border` |

#### `onboarding/widgets/avatar_picker.dart` (~80 lines)
| Element | Current | Replace |
|---|---|---|
| Container bg | `Color(0xFFF0F4F8)` | `colors.surfaceBg` |
| Icon | `Color(0xFF8E99A4)` | `colors.iconSecondary` |
| Text | `Color(0xFF8E99A4)` | `colors.textSecondary` |

#### `onboarding/widgets/interest_card.dart` (~50 lines)
Same chip pattern — replace unselected state colors, keep brand for selected.

#### `onboarding/widgets/onboarding_progress_bar.dart` (~40 lines)
| Element | Current | Replace |
|---|---|---|
| Track bg | `Color(0xFFE8ECF0)` | `colors.border` |
| Active fill | `Color(0xFF448AFF)` | Keep (brand) |

---

### 7.3 Main App Screens

#### `splash_screen.dart` (453 lines)
**Special case:** Splash has gradient background (`#448AFF` → `#FF7043`). This is brand identity.
- **Do NOT change** the splash gradient background.
- The gradient stays the same in dark mode (it's a branded splash).
- Only update any overlaid text that uses `Colors.white` — but on gradient, white is already correct.
- **Change:** Status bar icon brightness from `Brightness.dark` to `Brightness.light` if in dark mode (the splash bg is dark enough for light icons already).

#### `main_screen.dart` (260 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| BottomNavBar bg | `Colors.white` | `colors.navBarBg` |
| BottomNavBar selected | `Colors.black` | `colors.navSelected` |
| BottomNavBar unselected | `Colors.grey` | `colors.navUnselected` |
| Center FAB bg | `Colors.black` | Keep or `colors.textPrimary` |
| Create modal bg | `Colors.white` | `colors.sheetBg` |
| Create modal drag handle | `grey.shade300` | `colors.divider` |
| Modal item icons | `Colors.black87` | `colors.iconDefault` |
| Modal item text | `Colors.black87` | `colors.textPrimary` |
| Modal subtitle text | `grey.shade600` | `colors.textSecondary` |
| Border around items | `Colors.grey.shade200` | `colors.borderSubtle` |
| Top border | `grey.shade200` | `colors.divider` |

#### `home_screen.dart` (331 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| AppBar bg | `Colors.white` | `colors.scaffoldBg` |
| AppBar title | `Color(0xFF1A1A1A)` | `colors.textPrimary` |
| Story ring — keep existing colors | — | No change |
| Empty state icon | `Colors.blue.shade300` | Keep subtle brand |
| Empty state bg | `Colors.blue.shade50` | `colors.chipBg` |
| Empty state text | `Colors.grey.shade600` | `colors.textSecondary` |

#### `search_screen.dart` (529 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| Search bar bg | `Colors.grey.shade100` | `colors.searchBarBg` |
| Search hint | `Colors.grey.shade500` | `colors.textSecondary` |
| Search icon | `Colors.grey.shade500` | `colors.iconSecondary` |
| Tab bar indicator | Keep brand | — |
| Tab labels selected | `Colors.black` | `colors.textPrimary` |
| Tab labels unselected | `Colors.grey` | `colors.textSecondary` |
| User list tiles | `Colors.white` bg | `colors.cardBg` |
| Username text | `Colors.black87` | `colors.textPrimary` |
| secondary text | `Colors.grey.shade600` | `colors.textSecondary` |
| Dividers | `Colors.grey.shade200` | `colors.divider` |

#### `my_trips_screen.dart` (146 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| AppBar bg | `Colors.white` | `colors.scaffoldBg` |
| Title color | `Colors.black87` | `colors.textPrimary` |
| Empty state icon bg | `Colors.blue.shade50` | `colors.chipBg` |
| Empty state icon | `Colors.blue.shade300` | Keep brand |
| Empty state text | `Colors.grey.shade600` | `colors.textSecondary` |

#### `profile_screen.dart` (1814 lines) — **LARGEST SCREEN**
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| AppBar bg | `Colors.white` | `colors.scaffoldBg` |
| Profile name | `GoogleFonts.outfit(fontWeight, Colors.black87)` | `colors.textPrimary` |
| Username | `Colors.grey.shade600` | `colors.textSecondary` |
| Bio text | `Colors.black87` | `colors.textPrimary` |
| Location text | `Colors.grey.shade600` | `colors.textSecondary` |
| Stats row text | various black/grey | `colors.textPrimary` / `colors.textSecondary` |
| Follow/Edit button bg | `Color(0xFF448AFF)` | Keep (brand) |
| Tab bar selected | brand | Keep |
| Tab bar unselected | grey | `colors.textSecondary` |
| Interest chips bg | `Colors.blue.shade50` | `colors.chipBg` |
| Social link icons | `grey.shade600` | `colors.iconSecondary` |
| Edit profile sheet bg | `Colors.white` | `colors.sheetBg` |
| Edit field borders | `grey.shade?` / standard | `colors.border` |
| Edit field fill | implicit white | `colors.fieldFillBg` |
| Edit section headers | `grey.shade700` | `colors.textSecondary` |
| Edit field labels/hints | default | `colors.textSecondary`/`colors.textMuted` |
| Skeleton placeholder | grey shades | `colors.skeletonBase` |
| Blocked profile bg | `grey.shade100` | `colors.surfaceBg` |
| "Follows you" badge bg | `blue.shade50` | `colors.chipBg` |
| Agency cover overlay | `Colors.black.withOpacity(0.3)` | Keep (image overlay) |

#### `notifications_screen.dart` (232 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | Not set (defaults) | `colors.scaffoldBg` |
| AppBar bg | Not set | `colors.scaffoldBg` |
| Notification item bg | implicit | `colors.surfaceBg` for unread, `colors.scaffoldBg` for read |
| Text primary | default | `colors.textPrimary` |
| Text secondary | `grey.shade600` | `colors.textSecondary` |
| Timestamp | `grey.shade500` | `colors.textMuted` |
| Divider | default | `colors.divider` |

#### `settings_screen.dart` (175 lines)
Covered in Phase 4 above.

#### `privacy_settings_screen.dart` (196 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| AppBar bg | `Colors.white` | `colors.scaffoldBg` |
| Title | `Colors.black87` | `colors.textPrimary` |
| Switch tiles | `Colors.black` active, default bg | `Color(0xFF448AFF)` active, `colors.surfaceBg` bg |
| Description text | `Colors.grey.shade600` | `colors.textSecondary` |
| Dividers | implied | `colors.divider` |

---

### 7.4 Trip Screens

#### `trip_dashboard_screen.dart` (4541 lines) — **BIGGEST FILE, MOST WORK**

This is the monster. It contains:
- Trip header with cover image
- 8–9 tabs (Overview, Plan, Chat, Members, Activity, Expenses, Photos, Settings, Checklist, etc.)
- Inline tab content embedded in the file
- Many bottom sheets, dialogs, and inline widgets

**Strategy: Systematic pass** — search for each color pattern and replace:

| Pattern | Count (est.) | Replace With |
|---|---|---|
| `Colors.white` (bg) | ~50+ | `colors.scaffoldBg` / `colors.cardBg` / `colors.sheetBg` |
| `Colors.black87` (text) | ~40+ | `colors.textPrimary` |
| `Colors.grey.shade600` | ~20+ | `colors.textSecondary` |
| `Colors.grey.shade100-200` (borders) | ~15+ | `colors.borderSubtle` / `colors.divider` |
| `Colors.grey.shade300-400` (muted) | ~10+ | `colors.iconMuted` / `colors.textMuted` |
| `Colors.grey.shade50` (surface) | ~5+ | `colors.surfaceBg` |
| `Color(0xFF448AFF)` | ~15+ | Keep (brand) |
| `Colors.blueAccent` | ~10+ | Keep (brand) |
| `BoxShadow(color: Colors.black.withOpacity(0.03-0.1))` | ~10+ | `colors.shadow` |

**Tabs to audit individually:**

1. **Overview Tab** — Trip info card, member avatars, quick stats
2. **Plan Tab** (`trip_plan_tab.dart` 410 lines) — Day-by-day itinerary, place cards, timeline
3. **Chat Tab** (`trip_chat_tab.dart` 1223 lines) — Message bubbles, input bar, reactions
4. **Members Tab** — Member list, role badges, invite button
5. **Activity Tab** (`trip_activity_tab.dart` 75 lines) — Activity feed items
6. **Expenses Tab** — Expense list, split calculator
7. **Photos Tab** — Gallery grid
8. **Settings Tab** — Trip settings, danger zone
9. **Checklist Tab** — Todo items

Each tab needs the same color replacement pattern.

#### `trip_plan_tab.dart` (410 lines)
| Element | Current | Replace |
|---|---|---|
| Day header bg | `Colors.white` | `colors.cardBg` |
| Place card bg | `Colors.white` | `colors.cardBg` |
| Place name | `Colors.black87` | `colors.textPrimary` |
| Place address | `Colors.grey.shade600` | `colors.textSecondary` |
| Timeline line | `Colors.grey.shade300` | `colors.divider` |
| Timeline dot | `Color(0xFF448AFF)` | Keep (brand) |
| Time text | `Colors.grey.shade500` | `colors.textSecondary` |

#### `create_trip_screen.dart` (577 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| Step labels | `Theme.of(context).textTheme` | Already themed — add dark text override |
| Input fields | Various | `colors.fieldFillBg`, `colors.border` |
| Stepper connector | default | `colors.divider` |
| Active step circle | `Color(0xFF448AFF)` | Keep |

#### `join_trip_screen.dart` (174 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| Code input bg | implicit white | `colors.fieldFillBg` |
| Input border | default | `colors.border` |
| Title text | `Colors.black87` | `colors.textPrimary` |
| Join button | brand color | Keep |

---

### 7.5 Post Screens

#### `create_post_screen.dart` (535 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| AppBar bg/title | `Colors.white` / `Colors.black87` | tokens |
| Text input area | white bg | `colors.fieldFillBg` |
| Image preview border | `grey.shade200` | `colors.borderSubtle` |
| "Trip" selector | various | tokens |
| Post button | brand | Keep |

#### `post_detail_screen.dart` (86 lines)
Small wrapper — just Scaffold + AppBar + PostCard embed.
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| AppBar bg | `Colors.white` | `colors.scaffoldBg` |

---

### 7.6 Other Screens

#### `ai_guide_screen.dart` (373 lines)
| Element | Current | Replace |
|---|---|---|
| AppBar bg | `Colors.white` | `colors.scaffoldBg` |
| Message bubbles (user) | brand color | Keep |
| Message bubbles (AI) | `Colors.grey.shade100` | `colors.surfaceBg` |
| Input bar bg | `Colors.white` | `colors.cardBg` |
| Input border | `grey.shade300` | `colors.border` |
| Markdown text | default | Override with `colors.textPrimary` |

#### `place_detail_screen.dart` (339 lines)
| Element | Current | Replace |
|---|---|---|
| Scaffold bg | `Colors.white` | `colors.scaffoldBg` |
| Info card bg | `Colors.white` | `colors.cardBg` |
| Text colors | `Colors.black87` / `grey.shade600` | tokens |
| Map overlay | keep | — |

#### `blocked_users_screen.dart` (139 lines)
Standard list screen — Scaffold bg, AppBar, list tile colors.

#### `follows_list_screen.dart` (211 lines)
Standard list + tabs. Scaffold bg, tab colors, tile colors.

#### `follow_requests_screen.dart` (192 lines)
Standard list. Scaffold bg, request cards, accept/reject buttons.

#### `archived_posts_screen.dart` (115 lines)
Standard list. Scaffold bg, AppBar, empty state.

#### `privacy_policy_screen.dart` (79 lines) & `terms_conditions_screen.dart` (64 lines)
**Already clean** — use theme defaults. Will auto-adapt with just the ThemeData.
May only need check that Markdown body text is readable.

---

## 8. Phase 6 — Widget-by-Widget Migration

### `widgets/post_card.dart` (566 lines)
| Element | Current | Replace |
|---|---|---|
| Card bg | `Colors.white` | `colors.cardBg` |
| Card border | `Colors.grey.shade200` | `colors.borderSubtle` |
| Author name | `Colors.black87` | `colors.textPrimary` |
| Caption text | `Colors.black87` | `colors.textPrimary` |
| Timestamp | `Colors.grey.shade500` | `colors.textMuted` |
| Like/comment icons | `Colors.grey.shade700` | `colors.iconDefault` |
| Like count text | `Colors.grey.shade600` | `colors.textSecondary` |
| Options sheet bg | `Colors.white` | `colors.sheetBg` |
| Options dividers | `Colors.grey.shade200` | `colors.divider` |
| "Liked" heart | `Colors.red` | Keep (semantic) |
| Image — no change | — | — |
| Shadow | `black @ 3%` | `colors.shadow` |

### `widgets/trip_card.dart` (133 lines)
| Element | Current | Replace |
|---|---|---|
| Card bg | `Colors.white` | `colors.cardBg` |
| Border | `grey.shade200` | `colors.borderSubtle` |
| Trip name | `Colors.black87` | `colors.textPrimary` |
| Location text | `grey.shade600` | `colors.textSecondary` |
| Date text | `grey.shade500` | `colors.textMuted` |
| Member avatar border | `Colors.white` | `colors.cardBg` |
| Shadow | `black @ 5%` | `colors.shadow` |

### `widgets/comments_bottom_sheet.dart` (422 lines)
| Element | Current | Replace |
|---|---|---|
| Sheet bg | `Colors.white` | `colors.sheetBg` |
| Drag handle | `grey.shade300` | `colors.divider` |
| Comment author | `Colors.black87` | `colors.textPrimary` |
| Comment text | `Colors.black87` | `colors.textPrimary` |
| Timestamp | `grey.shade500` | `colors.textMuted` |
| Input bg | white | `colors.fieldFillBg` |
| Input border | `grey.shade300` | `colors.border` |
| Send icon | `Color(0xFF448AFF)` | Keep (brand) |
| Dividers | `grey.shade200` | `colors.divider` |

### `widgets/add_place_bottom_sheet.dart` (406 lines)
| Element | Current | Replace |
|---|---|---|
| Sheet bg | `Colors.white` | `colors.sheetBg` |
| Input fields | white bg, grey borders | `colors.fieldFillBg`, `colors.border` |
| Search results | white bg | `colors.cardBg` |
| Place name text | `Colors.black87` | `colors.textPrimary` |
| Address text | `grey.shade600` | `colors.textSecondary` |

### `widgets/ai_generation_overlay.dart` (257 lines)
| Element | Current | Replace |
|---|---|---|
| Overlay bg | Semi-transparent | Keep (overlay always dark-ish) |
| Content card bg | `Colors.white` | `colors.cardBg` |
| Title text | `Colors.black87` | `colors.textPrimary` |
| Body text | `Colors.black87` | `colors.textPrimary` |
| Progress indicator | brand color | Keep |

### `widgets/trip_chat_tab.dart` (1223 lines) — **2nd LARGEST FILE**
| Element | Current | Replace |
|---|---|---|
| Background | `Colors.white` | `colors.scaffoldBg` |
| Own message bubble | `Color(0xFF448AFF)` | Keep (brand) |
| Own message text | `Colors.white` | Keep |
| Other's bubble bg | `Colors.grey.shade100` | `colors.surfaceBg` |
| Other's bubble text | `Colors.black87` | `colors.textPrimary` |
| Sender name | `Colors.grey.shade600` | `colors.textSecondary` |
| Timestamp | `Colors.white60/70` / `grey.shade500` | Adapt |
| Input bar bg | `Colors.white` | `colors.cardBg` |
| Input field border | `grey.shade300` | `colors.border` |
| Send button | brand | Keep |
| Reaction picker bg | `Colors.white` | `colors.cardBg` |
| Date separator | `grey.shade300` bg | `colors.surfaceBg` |
| Date text | `grey.shade600` | `colors.textSecondary` |
| Link preview card | `Colors.white` | `colors.cardBg` |
| Reply bar | `grey.shade100` | `colors.surfaceBg` |

### `widgets/trip_activity_tab.dart` (75 lines)
Small file. CircleAvatar colors + text colors.

### `widgets/timeline_itinerary_item.dart` (175 lines)
| Element | Current | Replace |
|---|---|---|
| Card bg | `Colors.white` | `colors.cardBg` |
| Timeline line | `grey.shade300` | `colors.divider` |
| Time text | `grey.shade600` | `colors.textSecondary` |
| Place name | `Colors.black87` | `colors.textPrimary` |
| Detail text | `grey.shade600` | `colors.textSecondary` |

---

## 9. Phase 7 — Bottom Sheets, Dialogs & Overlays

Many screens open inline `showModalBottomSheet` / `showDialog`. Each needs updating:

### Bottom Sheets (across all screens)
Pattern to find and update:
```dart
// Current:
showModalBottomSheet(
  backgroundColor: Colors.transparent,  // or Colors.white
  builder: (_) => Container(
    decoration: BoxDecoration(color: Colors.white, ...)

// New:
showModalBottomSheet(
  backgroundColor: Colors.transparent,
  builder: (ctx) => Container(
    decoration: BoxDecoration(color: context.appColors.sheetBg, ...)
```

Located in:
- `profile_screen.dart` — Edit profile sheet, avatar options sheet
- `main_screen.dart` — Create modal
- `post_card.dart` — Options sheet
- `trip_dashboard_screen.dart` — Multiple (invite, settings, expenses, etc.)
- `comments_bottom_sheet.dart` — The sheet itself
- `add_place_bottom_sheet.dart` — The sheet itself

### Dialogs
Pattern:
```dart
// Current:
AlertDialog(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.white,

// New:
AlertDialog(
  backgroundColor: context.appColors.dialogBg,
  surfaceTintColor: context.appColors.dialogBg,
```

Located in:
- `main_screen.dart` — Create dialog
- `trip_dashboard_screen.dart` — Delete confirmations, leave trip, etc.
- `settings_screen.dart` — Logout, delete account confirmations
- `profile_screen.dart` — Block user dialog

### SnackBars
Most use default styling or inline styled:
```dart
SnackBar(content: Text("..."))
```
These will auto-adapt via `snackBarTheme` in AppTheme. No per-file changes needed.

---

## 10. Phase 8 — Polish & Edge Cases

### 10.1 System UI Overlay (Status Bar / Nav Bar)

In `main.dart` or per-screen, ensure:
```dart
SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
  systemNavigationBarColor: isDark ? Color(0xFF0F0F0F) : Colors.white,
  systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
));
```

### 10.2 Splash Screen
- Keep gradient as-is (brand identity)
- Ensure `SystemUiOverlayStyle.light` for white status bar icons (gradient is dark enough)

### 10.3 Google Maps (trip_dashboard, place_detail)
- Maps have their own dark style: Apply `mapStyle` JSON for dark mode
- Detect theme and use `_mapStyleDark` string if dark

### 10.4 Image Overlays
- Profile cover images already have `Colors.black.withOpacity(0.3)` overlay → Keep
- Any text-over-image should maintain overlay for readability

### 10.5 `Skeletonizer` Widget
Some screens use `Skeletonizer` for loading. Its base/highlight colors should adapt:
```dart
Skeletonizer(
  effect: ShimmerEffect(
    baseColor: colors.skeletonBase,
    highlightColor: colors.skeletonHighlight,
  ),
)
```

### 10.6 Autofill Background (Text Fields)
Flutter autofill can show yellow/blue backgrounds. In dark mode, override via:
```dart
autofillDecorationStyle: AutofillDecorationStyle(
  backgroundColor: colors.fieldFillBg,
)
```
Or handle via the `InputDecorationTheme` in `AppTheme`.

### 10.7 DatePicker / TimePicker
Currently themed inline:
```dart
Theme(data: Theme.of(context).copyWith(
  colorScheme: ColorScheme.light(primary: Color(0xFF448AFF)),
), child: child!)
```
Update to respect current brightness:
```dart
Theme(data: Theme.of(context).copyWith(
  colorScheme: context.isDark 
    ? ColorScheme.dark(primary: Color(0xFF448AFF))
    : ColorScheme.light(primary: Color(0xFF448AFF)),
), child: child!)
```

### 10.8 Markdown Rendering (ai_guide_screen)
Override `MarkdownStyleSheet` body text color:
```dart
MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
  p: GoogleFonts.inter(color: colors.textPrimary),
)
```

### 10.9 URL Launcher / External Links
No theme changes needed — these open system browser.

### 10.10 No-Flicker on Load
`ThemeProvider` loads saved preference in constructor. To prevent white flash:
- Load theme synchronously from `SharedPreferences` before `runApp()`
- Or ensure `ThemeMode.system` default until prefs load (minor flash acceptable if fast)

Best approach:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ...existing init...
  
  // Load theme pref before runApp to avoid flicker
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  
  runApp(MyApp(initialThemeMode: isDark ? ThemeMode.dark : ThemeMode.light));
}
```

### 10.11 Scrollbar Theming
Handled globally via `scrollbarTheme` in AppTheme:
```dart
scrollbarTheme: ScrollbarThemeData(
  thumbColor: WidgetStateProperty.all(isDark ? Color(0xFF555555) : Colors.grey.shade400),
)
```

---

## 11. File Change Matrix

### New Files (3)
| File | Purpose |
|---|---|
| `lib/theme/app_colors.dart` | ThemeExtension with all color tokens + light/dark instances |
| `lib/theme/app_theme.dart` | Full ThemeData for light & dark + component themes |
| `lib/theme/theme_extensions.dart` | `BuildContext` extension for `appColors` shortcut |
| `lib/providers/theme_provider.dart` | ChangeNotifier with SharedPreferences persistence |

### Modified Files (49)
| File | Change Type | Effort |
|---|---|---|
| **Infrastructure** | | |
| `lib/main.dart` | Add ThemeProvider, wire theme/darkTheme/themeMode | Small |
| **Auth (8 files)** | | |
| `lib/screens/auth/login_screen.dart` | Replace ~20 color refs | Medium |
| `lib/screens/auth/signup_screen.dart` | Replace ~30 color refs | Medium |
| `lib/screens/auth/otp_verification_screen.dart` | Replace ~25 color refs | Medium |
| `lib/screens/auth/forgot_password_screen.dart` | Replace ~25 color refs | Medium |
| `lib/screens/auth/reset_password_screen.dart` | Replace ~25 color refs | Medium |
| `lib/screens/auth/widgets/auth_header.dart` | Replace ~4 color refs | Small |
| `lib/screens/auth/widgets/auth_text_field.dart` | Replace ~8 color refs | Small |
| `lib/screens/auth/widgets/social_sign_in_button.dart` | Replace ~4 color refs | Small |
| **Onboarding (11 files)** | | |
| `lib/screens/onboarding/onboarding_wizard_screen.dart` | Replace ~30 color refs | Medium |
| `lib/screens/onboarding/steps/role_step.dart` | Replace ~15 color refs | Medium |
| `lib/screens/onboarding/steps/basic_info_step.dart` | Replace ~15 color refs | Medium |
| `lib/screens/onboarding/steps/location_step.dart` | Replace ~15 color refs | Medium |
| `lib/screens/onboarding/steps/traveler_interests_step.dart` | Replace ~12 color refs | Medium |
| `lib/screens/onboarding/steps/agency_details_step.dart` | Replace ~12 color refs | Medium |
| `lib/screens/onboarding/steps/agency_specializations_step.dart` | Replace ~10 color refs | Small |
| `lib/screens/onboarding/steps/privacy_step.dart` | Replace ~10 color refs | Small |
| `lib/screens/onboarding/steps/review_step.dart` | Replace ~15 color refs | Medium |
| `lib/screens/onboarding/widgets/avatar_picker.dart` | Replace ~5 color refs | Small |
| `lib/screens/onboarding/widgets/interest_card.dart` | Replace ~5 color refs | Small |
| `lib/screens/onboarding/widgets/onboarding_progress_bar.dart` | Replace ~3 color refs | Small |
| **Main Screens (9 files)** | | |
| `lib/screens/main_screen.dart` | Replace ~15 color refs | Medium |
| `lib/screens/home_screen.dart` | Replace ~12 color refs | Medium |
| `lib/screens/search_screen.dart` | Replace ~20 color refs | Medium |
| `lib/screens/my_trips_screen.dart` | Replace ~8 color refs | Small |
| `lib/screens/profile_screen.dart` | Replace ~80+ color refs | **Large** |
| `lib/screens/notifications_screen.dart` | Replace ~10 color refs | Small |
| `lib/screens/settings_screen.dart` | Replace ~12 refs + add toggle | Medium |
| `lib/screens/privacy_settings_screen.dart` | Replace ~10 color refs | Small |
| `lib/screens/splash_screen.dart` | System UI overlay only | Small |
| **Trip Screens (3 files)** | | |
| `lib/screens/trip_dashboard_screen.dart` | Replace ~150+ color refs | **Very Large** |
| `lib/screens/trip_plan_tab.dart` | Replace ~20 color refs | Medium |
| `lib/screens/create_trip_screen.dart` | Replace ~25 color refs | Medium |
| `lib/screens/join_trip_screen.dart` | Replace ~10 color refs | Small |
| **Post Screens (2 files)** | | |
| `lib/screens/create_post_screen.dart` | Replace ~20 color refs | Medium |
| `lib/screens/post_detail_screen.dart` | Replace ~5 color refs | Small |
| **Other Screens (5 files)** | | |
| `lib/screens/ai_guide_screen.dart` | Replace ~15 color refs + markdown | Medium |
| `lib/screens/place_detail_screen.dart` | Replace ~15 color refs | Medium |
| `lib/screens/blocked_users_screen.dart` | Replace ~8 color refs | Small |
| `lib/screens/follows_list_screen.dart` | Replace ~10 color refs | Small |
| `lib/screens/follow_requests_screen.dart` | Replace ~10 color refs | Small |
| `lib/screens/archived_posts_screen.dart` | Replace ~8 color refs | Small |
| **Shared Widgets (8 files)** | | |
| `lib/widgets/post_card.dart` | Replace ~25 color refs | Medium |
| `lib/widgets/trip_card.dart` | Replace ~10 color refs | Small |
| `lib/widgets/comments_bottom_sheet.dart` | Replace ~20 color refs | Medium |
| `lib/widgets/add_place_bottom_sheet.dart` | Replace ~20 color refs | Medium |
| `lib/widgets/ai_generation_overlay.dart` | Replace ~12 color refs | Medium |
| `lib/widgets/trip_activity_tab.dart` | Replace ~5 color refs | Small |
| `lib/widgets/trip_chat_tab.dart` | Replace ~60+ color refs | **Large** |
| `lib/widgets/timeline_itinerary_item.dart` | Replace ~10 color refs | Small |

### Estimated Total Color Replacements: **~800+**

---

## 12. Testing Checklist

### Per-Screen Verification (Light + Dark)

- [ ] **Splash Screen** — Gradient intact, text readable, no flash
- [ ] **Login Screen** — Fields visible, buttons readable, errors visible
- [ ] **Signup Screen** — Password strength colors correct, all fields dark
- [ ] **OTP Screen** — OTP boxes visible, timer readable
- [ ] **Forgot Password** — Fields, buttons, links all visible
- [ ] **Reset Password** — Password fields, strength bars visible
- [ ] **Onboarding Wizard** — All 8 steps display correctly
- [ ] **Role Selection** — Cards visible, selection state clear
- [ ] **Basic Info Step** — Fields, avatar picker, validation errors
- [ ] **Location Step** — Location button, text fields
- [ ] **Interests Step** — Chip selection states
- [ ] **Agency Steps** — All fields, specialization chips
- [ ] **Privacy Step** — Toggle switches visible
- [ ] **Review Step** — Summary cards readable
- [ ] **Home Feed** — Posts display, skeleton loading, empty state
- [ ] **Search Screen** — Search bar, tabs, results
- [ ] **My Trips** — Trip cards, empty state
- [ ] **Profile Screen** — Avatar, stats, bio, tabs, edit sheet
- [ ] **Edit Profile Sheet** — All fields themed, save button visible
- [ ] **Notifications** — Read/unread distinction, timestamps
- [ ] **Settings** — Theme toggle works, all items visible
- [ ] **Privacy Settings** — Toggles, descriptions
- [ ] **Trip Dashboard** — All 8-9 tabs:
  - [ ] Overview tab
  - [ ] Plan tab + timeline
  - [ ] Chat tab + messages + input
  - [ ] Members tab
  - [ ] Activity tab
  - [ ] Expenses tab
  - [ ] Photos tab
  - [ ] Settings tab
  - [ ] Checklist tab
- [ ] **Create Trip** — Stepper, fields, map
- [ ] **Join Trip** — Code input, join button
- [ ] **Create Post** — Image preview, caption field
- [ ] **Post Detail** — PostCard themed
- [ ] **Comments Sheet** — Comment list, input bar
- [ ] **AI Guide** — Chat bubbles, markdown rendering
- [ ] **Place Detail** — Info card, map, details
- [ ] **Blocked Users** — List, unblock button
- [ ] **Follows List** — Tabs, user tiles
- [ ] **Follow Requests** — Request cards, accept/reject
- [ ] **Archived Posts** — Post list, restore option
- [ ] **Privacy Policy** — Text readable
- [ ] **Terms & Conditions** — Text readable

### Cross-Cutting Checks
- [ ] Theme persists after app kill + reopen
- [ ] Theme persists after logout + login
- [ ] No white flash on app startup in dark mode
- [ ] Status bar icons adapt (light icons on dark bg)
- [ ] System navigation bar adapts
- [ ] All dialogs themed
- [ ] All bottom sheets themed
- [ ] All SnackBars readable
- [ ] DatePicker / TimePicker themed
- [ ] Scrollbars subtle in dark mode
- [ ] No invisible text anywhere
- [ ] No invisible icons anywhere
- [ ] No invisible buttons
- [ ] WCAG contrast maintained (4.5:1 for text)
- [ ] Brand color (#448AFF) unchanged
- [ ] Error/Success/Warning colors unchanged
- [ ] Images and avatars unaffected
- [ ] Smooth 300ms transition when toggling
- [ ] Skeleton loading states themed
- [ ] Google Maps dark style (if applicable)

---

## Implementation Order (Recommended)

| Order | Phase | Files | Estimated Effort |
|---|---|---|---|
| 1 | Foundation | 3 new files (app_colors, app_theme, theme_extensions) | 1 pass |
| 2 | Provider | 1 new file (theme_provider) | 1 pass |
| 3 | Wire into main | main.dart | Quick |
| 4 | Settings toggle | settings_screen.dart | Quick |
| 5 | Auth screens | 8 files | Medium batch |
| 6 | Onboarding | 11 files | Medium batch |
| 7 | Main screens | 9 files | Medium batch (profile_screen is heavy) |
| 8 | Trip screens | 4 files | Heavy batch (trip_dashboard is huge) |
| 9 | Post screens | 2 files | Quick batch |
| 10 | Other screens | 5 files | Quick batch |
| 11 | Shared widgets | 8 files | Medium batch (chat is heavy) |
| 12 | Polish | System UI, maps, edge cases | Final pass |

**Total new files:** 4
**Total modified files:** 49
**Total estimated color replacements:** ~800+
