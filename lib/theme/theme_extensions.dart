import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Convenience extension for concise theme access.
///
/// Usage:
/// ```dart
/// final colors = context.appColors;
/// Text("Hello", style: TextStyle(color: colors.textPrimary));
/// ```
extension ThemeContextX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
