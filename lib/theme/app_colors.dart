import 'package:flutter/material.dart';

/// Centralized semantic color tokens for WanderWith.
/// Access via `Theme.of(context).extension<AppColors>()!` or `context.appColors`.
class AppColors extends ThemeExtension<AppColors> {
  // ─── Backgrounds ───
  final Color scaffoldBg;
  final Color cardBg;
  final Color surfaceBg;
  final Color fieldFillBg;
  final Color sheetBg;
  final Color dialogBg;

  // ─── Text ───
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnPrimary;

  // ─── Borders & Dividers ───
  final Color border;
  final Color borderSubtle;
  final Color divider;

  // ─── Icons ───
  final Color iconDefault;
  final Color iconSecondary;
  final Color iconMuted;

  // ─── Navigation ───
  final Color navBarBg;
  final Color navSelected;
  final Color navUnselected;

  // ─── Chips & Tags ───
  final Color chipBg;
  final Color chipBorder;

  // ─── Shadows ───
  final Color shadow;

  // ─── Special Surfaces ───
  final Color searchBarBg;
  final Color hoverBg;
  final Color skeletonBase;
  final Color skeletonHighlight;

  const AppColors({
    required this.scaffoldBg,
    required this.cardBg,
    required this.surfaceBg,
    required this.fieldFillBg,
    required this.sheetBg,
    required this.dialogBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnPrimary,
    required this.border,
    required this.borderSubtle,
    required this.divider,
    required this.iconDefault,
    required this.iconSecondary,
    required this.iconMuted,
    required this.navBarBg,
    required this.navSelected,
    required this.navUnselected,
    required this.chipBg,
    required this.chipBorder,
    required this.shadow,
    required this.searchBarBg,
    required this.hoverBg,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  // ─── Brand constants (same in both themes) ───
  static const Color brand = Color(0xFF448AFF);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color orange = Color(0xFFFF7043);

  // ═══════════════════════════════════════════
  //  LIGHT THEME COLORS
  // ═══════════════════════════════════════════
  static const AppColors light = AppColors(
    scaffoldBg: Colors.white,
    cardBg: Colors.white,
    surfaceBg: Color(0xFFFAFAFA),       // grey.shade50
    fieldFillBg: Color(0xFFF8F9FA),
    sheetBg: Colors.white,
    dialogBg: Colors.white,

    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF8E99A4),
    textMuted: Color(0xFFBCC5CE),
    textOnPrimary: Colors.white,

    border: Color(0xFFE8ECF0),
    borderSubtle: Color(0xFFF5F5F5),     // grey.shade100
    divider: Color(0xFFEEEEEE),          // grey.shade200

    iconDefault: Color(0xDD000000),       // Colors.black87
    iconSecondary: Color(0xFF757575),     // grey.shade600
    iconMuted: Color(0xFFBDBDBD),         // grey.shade400

    navBarBg: Colors.white,
    navSelected: Colors.black,
    navUnselected: Colors.grey,

    chipBg: Color(0xFFE3F2FD),           // blue.shade50
    chipBorder: Color(0xFFBBDEFB),       // blue.shade100

    shadow: Color(0x08000000),            // black @ ~3%

    searchBarBg: Color(0xFFF5F5F5),      // grey.shade100
    hoverBg: Color(0xFFF5F5F5),          // grey.shade100
    skeletonBase: Color(0xFFEEEEEE),     // grey.shade200
    skeletonHighlight: Color(0xFFF5F5F5), // grey.shade100
  );

  // ═══════════════════════════════════════════
  //  DARK THEME COLORS
  // ═══════════════════════════════════════════
  static const AppColors dark = AppColors(
    scaffoldBg: Color(0xFF0F0F0F),
    cardBg: Color(0xFF1E1E1E),
    surfaceBg: Color(0xFF181818),
    fieldFillBg: Color(0xFF1E1E1E),
    sheetBg: Color(0xFF1E1E1E),
    dialogBg: Color(0xFF1E1E1E),

    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textMuted: Color(0xFF888888),
    textOnPrimary: Colors.white,

    border: Color(0x14FFFFFF),            // rgba(255,255,255,0.08)
    borderSubtle: Color(0x0DFFFFFF),      // rgba(255,255,255,0.05)
    divider: Color(0x14FFFFFF),           // rgba(255,255,255,0.08)

    iconDefault: Color(0xFFFFFFFF),
    iconSecondary: Color(0xFFB3B3B3),
    iconMuted: Color(0xFF888888),

    navBarBg: Color(0xFF181818),
    navSelected: Colors.white,
    navUnselected: Color(0xFF888888),

    chipBg: Color(0x1A448AFF),           // 10% brand blue
    chipBorder: Color(0x33448AFF),       // 20% brand blue

    shadow: Colors.transparent,

    searchBarBg: Color(0xFF1E1E1E),
    hoverBg: Color(0x0DFFFFFF),           // rgba(255,255,255,0.05)
    skeletonBase: Color(0xFF2A2A2A),
    skeletonHighlight: Color(0xFF3A3A3A),
  );

  @override
  AppColors copyWith({
    Color? scaffoldBg,
    Color? cardBg,
    Color? surfaceBg,
    Color? fieldFillBg,
    Color? sheetBg,
    Color? dialogBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnPrimary,
    Color? border,
    Color? borderSubtle,
    Color? divider,
    Color? iconDefault,
    Color? iconSecondary,
    Color? iconMuted,
    Color? navBarBg,
    Color? navSelected,
    Color? navUnselected,
    Color? chipBg,
    Color? chipBorder,
    Color? shadow,
    Color? searchBarBg,
    Color? hoverBg,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppColors(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      cardBg: cardBg ?? this.cardBg,
      surfaceBg: surfaceBg ?? this.surfaceBg,
      fieldFillBg: fieldFillBg ?? this.fieldFillBg,
      sheetBg: sheetBg ?? this.sheetBg,
      dialogBg: dialogBg ?? this.dialogBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      divider: divider ?? this.divider,
      iconDefault: iconDefault ?? this.iconDefault,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      iconMuted: iconMuted ?? this.iconMuted,
      navBarBg: navBarBg ?? this.navBarBg,
      navSelected: navSelected ?? this.navSelected,
      navUnselected: navUnselected ?? this.navUnselected,
      chipBg: chipBg ?? this.chipBg,
      chipBorder: chipBorder ?? this.chipBorder,
      shadow: shadow ?? this.shadow,
      searchBarBg: searchBarBg ?? this.searchBarBg,
      hoverBg: hoverBg ?? this.hoverBg,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      surfaceBg: Color.lerp(surfaceBg, other.surfaceBg, t)!,
      fieldFillBg: Color.lerp(fieldFillBg, other.fieldFillBg, t)!,
      sheetBg: Color.lerp(sheetBg, other.sheetBg, t)!,
      dialogBg: Color.lerp(dialogBg, other.dialogBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      iconDefault: Color.lerp(iconDefault, other.iconDefault, t)!,
      iconSecondary: Color.lerp(iconSecondary, other.iconSecondary, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      navBarBg: Color.lerp(navBarBg, other.navBarBg, t)!,
      navSelected: Color.lerp(navSelected, other.navSelected, t)!,
      navUnselected: Color.lerp(navUnselected, other.navUnselected, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      chipBorder: Color.lerp(chipBorder, other.chipBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      searchBarBg: Color.lerp(searchBarBg, other.searchBarBg, t)!,
      hoverBg: Color.lerp(hoverBg, other.hoverBg, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
    );
  }
}
