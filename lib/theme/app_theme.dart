import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Complete Light & Dark ThemeData for WanderWith.
class AppTheme {
  AppTheme._();

  // ─── Brand primary (unchanged across themes) ───
  static const Color _brand = AppColors.brand;

  // ═══════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.light.scaffoldBg,
      onSurface: AppColors.light.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.light.scaffoldBg,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.light.scaffoldBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.light.iconDefault),
      titleTextStyle: GoogleFonts.outfit(
        color: AppColors.light.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.light.navBarBg,
      selectedItemColor: AppColors.light.navSelected,
      unselectedItemColor: AppColors.light.navUnselected,
    ),
    cardTheme: CardTheme(
      color: AppColors.light.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.light.borderSubtle),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.light.dialogBg,
      surfaceTintColor: AppColors.light.dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.light.sheetBg,
      surfaceTintColor: AppColors.light.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.light.divider,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.light.fieldFillBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.light.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.light.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brand, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: GoogleFonts.inter(color: AppColors.light.textSecondary),
      hintStyle: GoogleFonts.inter(color: AppColors.light.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _brand,
        side: const BorderSide(color: _brand),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _brand),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.light.chipBg,
      side: BorderSide(color: AppColors.light.chipBorder),
      labelStyle: GoogleFonts.inter(color: AppColors.light.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return _brand;
        return Colors.grey.shade400;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return _brand.withOpacity(0.3);
        return Colors.grey.shade300;
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.light.textPrimary,
      contentTextStyle: GoogleFonts.inter(color: AppColors.light.textOnPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: MaterialStateProperty.all(Colors.grey.shade400),
    ),
    extensions: const [AppColors.light],
  );

  // ═══════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.dark.scaffoldBg,
      onSurface: AppColors.dark.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.dark.scaffoldBg,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.dark.scaffoldBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.dark.iconDefault),
      titleTextStyle: GoogleFonts.outfit(
        color: AppColors.dark.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.dark.navBarBg,
      selectedItemColor: AppColors.dark.navSelected,
      unselectedItemColor: AppColors.dark.navUnselected,
    ),
    cardTheme: CardTheme(
      color: AppColors.dark.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.dark.borderSubtle),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.dark.dialogBg,
      surfaceTintColor: AppColors.dark.dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.dark.sheetBg,
      surfaceTintColor: AppColors.dark.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.dark.divider,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.dark.fieldFillBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.dark.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.dark.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _brand, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: GoogleFonts.inter(color: AppColors.dark.textSecondary),
      hintStyle: GoogleFonts.inter(color: AppColors.dark.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _brand,
        side: const BorderSide(color: _brand),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _brand),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.dark.chipBg,
      side: BorderSide(color: AppColors.dark.chipBorder),
      labelStyle: GoogleFonts.inter(color: AppColors.dark.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return _brand;
        return Colors.grey.shade600;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return _brand.withOpacity(0.3);
        return Colors.grey.shade800;
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.dark.cardBg,
      contentTextStyle: GoogleFonts.inter(color: AppColors.dark.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: MaterialStateProperty.all(const Color(0xFF555555)),
    ),
    extensions: const [AppColors.dark],
  );
}
