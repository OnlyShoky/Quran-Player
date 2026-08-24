import 'package:flutter/material.dart';

/// Central color constants for the app palette.
/// Use these tokens rather than hardcoded hex values in UI code.
abstract class AppColors {
  // --- Primary (Sage Green) ---
  static const Color primaryLight = Color(0xFF5C7A6B);
  static const Color primaryDark = Color(0xFF7DA892);

  // --- Secondary (Warm Brown) ---
  static const Color secondaryLight = Color(0xFFA07850);
  static const Color secondaryDark = Color(0xFFC4976A);

  // --- Surface ---
  static const Color surfaceLight = Color(0xFFFAF8F3);
  static const Color surfaceDark = Color(0xFF1A1A18);

  // --- Surface Container ---
  static const Color surfaceContainerLight = Color(0xFFF0EDE5);
  static const Color surfaceContainerDark = Color(0xFF252520);

  // --- On-Surface (text) ---
  static const Color onSurfaceLight = Color(0xFF1C1C1A);
  static const Color onSurfaceDark = Color(0xFFEAE8E2);

  // --- Muted / Subdued text ---
  static const Color mutedLight = Color(0xFF7A7870);
  static const Color mutedDark = Color(0xFF9A9890);

  // --- Outline / Divider ---
  static const Color outlineLight = Color(0xFFD8D4CC);
  static const Color outlineDark = Color(0xFF3A3A34);

  // --- Error ---
  static const Color errorLight = Color(0xFFB85C5C);
  static const Color errorDark = Color(0xFFE07070);

  // --- Surah number badge backgrounds (light/dark) ---
  static const Color badgeLight = Color(0xFFE8E4DA);
  static const Color badgeDark = Color(0xFF32322C);

  // --- Meccan / Medinan chips ---
  static const Color meccanLight = Color(0xFFD4E8DC);
  static const Color meccanDark = Color(0xFF1E3328);
  static const Color medinanLight = Color(0xFFE8DED0);
  static const Color medinanDark = Color(0xFF332A1E);
}
