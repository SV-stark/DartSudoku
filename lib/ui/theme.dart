import 'dart:ui';
import 'package:flutter/material.dart';

/// Centralized design constants, colors, and styles for the Sudoku application.
class AppTheme {
  // Brand Colors (Sleek Dark Mode with Neon accents)
  static const Color backgroundColor = Color(0xFF0A0E17);
  static const Color surfaceColor = Color(0xFF161F30);
  static const Color surfaceGlassColor = Color(0x9A161F30);

  // Neon accents
  static const Color neonViolet = Color(0xFF8B5CF6);
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonIndigo = Color(0xFF6366F1);
  static const Color neonAmber = Color(0xFFF59E0B);
  static const Color neonRed = Color(0xFFF43F5E);
  static const Color neonGreen = Color(0xFF10B981);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonViolet, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF050811), Color(0xFF0B132B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Cell Highlighting Colors
  static const Color selectedCellBg = Color(0x3B6366F1); // Translucent Indigo
  static const Color relatedCellBg = Color(0x0E06B6D4); // Faint Cyan
  static const Color sameNumberBg = Color(
    0x2E8B5CF6,
  ); // Subtle Violet highlight
  static const Color clueText = Color(0xFFF8FAFC); // Solid Off-White
  static const Color userText = Color(0xFF38BDF8); // Cyan-Blue for user edits
  static const Color noteText = Color(0xFF94A3B8); // Muted slate gray for notes

  // Font styles
  static TextStyle titleStyle = const TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    shadows: [Shadow(color: neonViolet, blurRadius: 10, offset: Offset(0, 0))],
  );

  static TextStyle subtitleStyle = TextStyle(
    color: Colors.white.withOpacity(0.7),
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static TextStyle bodyStyle = const TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  /// Helper for glassmorphic box decoration
  static BoxDecoration glassBoxDecoration({
    double borderRadius = 16.0,
    Color borderColor = const Color(0x228B5CF6),
    Color fillColor = surfaceGlassColor,
  }) {
    return BoxDecoration(
      color: fillColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Custom glassmorphism filter widget
  static Widget glassEffect({
    required Widget child,
    double blur = 12.0,
    double borderRadius = 16.0,
    Color borderColor = const Color(0x228B5CF6),
    Color fillColor = surfaceGlassColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: glassBoxDecoration(
            borderRadius: borderRadius,
            borderColor: borderColor,
            fillColor: fillColor,
          ),
          child: child,
        ),
      ),
    );
  }
}
