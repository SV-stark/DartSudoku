import 'package:flutter/material.dart';

/// Centralized Material 3 theme helpers and color mapping.
class AppTheme {
  // Seed color used to generate the modern Material 3 color scheme
  static const Color primarySeed = Colors.indigo;

  // Common Text Styles utilizing context themes
  static TextStyle titleStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onBackground,
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
    return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6);
  }

  static Color relatedCellBg(BuildContext context) {
    return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15);
  }

  static Color sameNumberBg(BuildContext context) {
    return Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4);
  }

  static Color clueText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color userText(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color noteText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7);
  }

  static Color errorText(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }
}
