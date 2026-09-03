import 'package:flutter/material.dart';

class AppColors {
  // Primary Luxury Islamic Emerald Greens
  static const Color primary = Color(0xFF0F5A47);
  static const Color primaryDark = Color(0xFF0A3D30);
  static const Color primaryLight = Color(0xFF1B7A62);
  static const Color primaryContainer = Color(0xFFE8F5F1);

  // Royal Golden Accents
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color goldDark = Color(0xFFA67C00);
  static const Color goldGradientStart = Color(0xFFE6C875);
  static const Color goldGradientEnd = Color(0xFFB8860B);

  // Neutral & Parchment Backgrounds (Light Mode)
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color quranParchment = Color(0xFFFAF7EE);
  static const Color dividerLight = Color(0xFFE5E9E7);

  // Dark Mode Palette
  static const Color backgroundDark = Color(0xFF0E1714);
  static const Color surfaceDark = Color(0xFF15221E);
  static const Color cardDark = Color(0xFF1B2B26);
  static const Color cardDarkSecondary = Color(0xFF233630);
  static const Color dividerDark = Color(0xFF283D36);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1C2826);
  static const Color textSecondaryLight = Color(0xFF63736D);
  static const Color textPrimaryDark = Color(0xFFF1F5F3);
  static const Color textSecondaryDark = Color(0xFF9CAEA6);

  // Status & Highlights
  static const Color accentGreen = Color(0xFF2EC4B6);
  static const Color accentAmber = Color(0xFFFF9F1C);
  static const Color accentRed = Color(0xFFE71D36);
  static const Color accentBlue = Color(0xFF3A86FF);

  // Linear Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F5A47), Color(0xFF09392D)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE2BE57), Color(0xFFB3820F)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF146356), Color(0xFF0B4638)],
  );
}
