import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  // English display/headings — DM Serif Display
  static TextStyle displayLarge = GoogleFonts.dmSerifDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  static TextStyle displayMedium = GoogleFonts.dmSerifDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );

  static TextStyle displaySmall = GoogleFonts.dmSerifDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static TextStyle headlineLarge = GoogleFonts.dmSerifDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static TextStyle headlineMedium = GoogleFonts.dmSerifDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  // English body/UI — DM Sans
  static TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle labelLarge = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle labelMedium = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle labelSmall = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
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
