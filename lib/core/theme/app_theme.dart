import 'package:flutter/material.dart';

/// CampusCart "Aurora Iris & Slate" Design System
/// Ultra-modern, aesthetic, and accessible design tokens tailored for high-end mobile & web UX.
class AppTheme {
  // Brand Primary & Iris Accents
  static const Color primaryIris = Color(0xFF4F46E5); // Modern deep iris/indigo
  static const Color primaryIndigo = Color(
    0xFF6366F1,
  ); // Vibrant electric indigo
  static const Color primaryBlue =
      primaryIris; // Maintained for backward compatibility
  static const Color primaryDark = Color(0xFF312E81); // Deep slate-indigo
  static const Color primaryLight = Color(0xFFEEF2FF); // Soft indigo-50 tint

  // High-Energy Accents
  static const Color accentPurple = Color(0xFF8B5CF6); // Cyber violet
  static const Color accentCyan = Color(0xFF06B6D4); // Electric teal
  static const Color accentGreen = Color(
    0xFF10B981,
  ); // Emerald mint for verified badges
  static const Color accentAmber = Color(0xFFF59E0B); // Amber warning/rating
  static const Color accentRose = Color(
    0xFFF43F5E,
  ); // Hot coral for deals / alerts

  // Background & Surfaces
  static const Color bgLight = Color(0xFFF8FAFC); // Clean Slate-50 background
  static const Color bgCardSubtle = Color(0xFFF1F5F9); // Slate-100 container
  static const Color surfaceCard = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF6366F1);

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900 high contrast
  static const Color textSecondary = Color(0xFF64748B); // Slate-500 medium
  static const Color textMuted = Color(0xFF94A3B8); // Slate-400 hint

  // AI & Hero Gradients
  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient dealGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Aesthetic Card Decoration Helper
  static BoxDecoration modernCardDecoration({
    Color backgroundColor = Colors.white,
    BorderRadius? borderRadius,
    bool hasShadow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: Border.all(color: borderLight, width: 1),
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: primaryIndigo.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  // AI Glow Decoration Helper
  static BoxDecoration aiContainerDecoration({
    BorderRadius? borderRadius,
    bool isGlowing = true,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF5F3FF), Color(0xFFEEF2FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFC7D2FE), width: 1.2),
      boxShadow: isGlowing
          ? [
              BoxShadow(
                color: primaryIndigo.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        primary: primaryIris,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: primaryDark,
        secondary: accentGreen,
        tertiary: accentPurple,
        surface: surfaceCard,
        onSurface: textPrimary,
      ),
      fontFamilyFallback: const ['Segoe UI', 'Roboto', 'Arial', 'sans-serif'],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary, size: 22),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIris,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryIris,
          side: const BorderSide(color: primaryIris, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryIris,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryLight,
        disabledColor: borderLight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primaryIris,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: primaryIris,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryIris, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
