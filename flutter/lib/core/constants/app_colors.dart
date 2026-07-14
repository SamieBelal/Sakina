import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Light Mode ──

  static const backgroundLight = Color(0xFFFBF7F2);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceAltLight = Color(0xFFF3EDE4);

  static const primary = Color(0xFF1B6B4A);
  static const primaryLight = Color(0xFFE8F5EE);
  static const primaryDark = Color(0xFF134D36);

  static const secondary = Color(0xFFC8985E);
  static const secondaryLight = Color(0xFFF5EBD9);

  static const textPrimaryLight = Color(0xFF1A1A2E);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textTertiaryLight = Color(0xFF9CA3AF);
  static const textOnPrimary = Color(0xFFFFFFFF);

  static const streakAmber = Color(0xFFE8A154); // Softened: warmer, less neon (was F59E0B)
  static const streakBackground = Color(0xFFFEF3C7);

  static const error = Color(0xFFDC2626);
  static const errorBackground = Color(0xFFFEE2E2);

  static const borderLight = Color(0xFFE5E0D8);
  static const dividerLight = Color(0xFFF0EBE3);

  // ── Dark Mode ──

  static const backgroundDark = Color(0xFF1C1917);
  static const surfaceDark = Color(0xFF292524);
  static const surfaceAltDark = Color(0xFF1E1B19);

  static const primaryDarkMode = Color(0xFF4ADE80);
  static const primaryLightDark = Color(0xFF1A3A2A);

  static const secondaryDark = Color(0xFFD4A44C);
  static const secondaryLightDark = Color(0xFF3D2E1A);

  static const textPrimaryDark = Color(0xFFF5F0EB);
  static const textSecondaryDark = Color(0xFFA8A29E);

  static const streakAmberDark = Color(0xFFFBBF24);
  static const errorDark = Color(0xFFF87171);

  static const borderDark = Color(0xFF44403C);

  // ── Sacred Canvas ──
  // The beat reveal flow's immersion surface. A deliberate mode change vs the
  // cream home — entering/leaving the flow reads as entering/leaving the ritual.
  // Same canvas in light and dark themes (it is its own surface, not themed).
  // Rule: gold (#C8985E) measures ~2.5:1 on the emerald canvas and FAILS WCAG for
  // text — it is a non-text accent only (progress fill, bars). Functional text on
  // the canvas uses sacredInk (cream) at >=80%.
  static const sacredCanvasTop = Color(0xFF17553C); // gradient start (178deg)
  static const sacredCanvasBase = Color(0xFF1B6B4A); // gradient mid (~60%)
  static const sacredCanvasGlow = Color(0xFF1F7A55); // gradient end
  static const sacredInk = Color(0xFFF6EFE4); // primary text on canvas

  static const sacredInkSoft = Color(0xB3F6EFE4); // 70% — supporting text, loader
  static const sacredInkFaint = Color(0x73F6EFE4); // 45% — hint, source lines
  static const sacredTrack = Color(0x38F6EFE4); // 22% — progress segment track
  static const sacredPattern = Color(0x14F6EFE4); // 8% — geometric accent

  /// The canvas gradient (top → base → glow), 178° per the approved mockup.
  static const sacredCanvasGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sacredCanvasTop, sacredCanvasBase, sacredCanvasGlow],
    stops: [0.0, 0.6, 1.0],
  );
}
