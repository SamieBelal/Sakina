import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        error: AppColors.error,
        errorContainer: AppColors.errorBackground,
        outline: AppColors.borderLight,
      ),
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryLight,
        ),
        displayMedium: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryLight,
        ),
        displaySmall: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryLight,
        ),
        headlineLarge: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryLight,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryLight,
        ),
        headlineSmall: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryLight,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          color: AppColors.textPrimaryLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.dmSans(color: AppColors.textTertiaryLight),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDarkMode,
        onPrimary: AppColors.backgroundDark,
        primaryContainer: AppColors.primaryLightDark,
        secondary: AppColors.secondaryDark,
        secondaryContainer: AppColors.secondaryLightDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.errorDark,
        outline: AppColors.borderDark,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryDark,
        ),
        displayMedium: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryDark,
        ),
        displaySmall: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryDark,
        ),
        headlineLarge: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryDark,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryDark,
        ),
        headlineSmall: GoogleFonts.dmSerifDisplay(
          color: AppColors.textPrimaryDark,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          color: AppColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.borderDark, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDarkMode,
          foregroundColor: AppColors.backgroundDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide: const BorderSide(color: AppColors.primaryDarkMode, width: 1.5),
        ),
        hintStyle: GoogleFonts.dmSans(color: AppColors.textSecondaryDark),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryDarkMode,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
      ),
    );
  }
}
