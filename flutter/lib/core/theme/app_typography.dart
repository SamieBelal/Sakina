import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  // English display/headings — Outfit Bold
  // STANDARDIZED: All main screen titles use displayLarge (34pt) for consistency
  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.68, // -0.02em for elegance
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static TextStyle displaySmall = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle headlineLarge = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle headlineMedium = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // English body/UI — Outfit Regular/Medium
  static TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle labelMedium = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle labelSmall = GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // Arabic — Quran verses (naskh)
  static TextStyle quranArabic = GoogleFonts.amiri(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.8,
  );

  // Arabic — Name of Allah hero display (calligraphic)
  static TextStyle nameOfAllahDisplay = GoogleFonts.arefRuqaa(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  // Arabic — alternate (classical)
  static TextStyle arabicClassical = GoogleFonts.scheherazadeNew(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.8,
  );
}
