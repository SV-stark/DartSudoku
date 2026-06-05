import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Material 3 theme helpers and color mapping.
class AppTheme {
  // Seed color used to generate the modern Material 3 color scheme
  static const Color primarySeed = Colors.indigo;

  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.dark,
  );

  static const String _themeKey = 'sudoku_app_theme_mode';

  /// Load theme preferences from SharedPreferences.
  static Future<void> initTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_themeKey);
      if (modeIndex != null) {
        themeModeNotifier.value = ThemeMode.values[modeIndex];
      }
    } catch (_) {}
  }

  /// Toggle between Dark and Light themes and persist selection.
  static Future<void> toggleTheme() async {
    final current = themeModeNotifier.value;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, next.index);
    } catch (_) {}
  }

  // Common Text Styles utilizing context themes
  static TextStyle titleStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );
  }

  static TextStyle subtitleStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 14,
      fontWeight: FontWeight.normal,
    );
  }

  static TextStyle bodyStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 14,
    );
  }

  // Grid Cell Highlights using standard Material 3 Container Colors
  static Color selectedCellBg(BuildContext context) {
    return Theme.of(
      context,
    ).colorScheme.primaryContainer.withValues(alpha: 0.6);
  }

  static Color relatedCellBg(BuildContext context) {
    return Theme.of(
      context,
    ).colorScheme.primaryContainer.withValues(alpha: 0.15);
  }

  static Color sameNumberBg(BuildContext context) {
    return Theme.of(
      context,
    ).colorScheme.secondaryContainer.withValues(alpha: 0.4);
  }

  static Color clueText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color userText(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color noteText(BuildContext context) {
    return Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
  }

  static Color errorText(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }
}
