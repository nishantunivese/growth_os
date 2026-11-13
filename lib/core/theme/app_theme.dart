import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// GROWTH OS - Master Dark Theme (Linear & Stripe Inspired)
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.electricPurple,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricPurple,
        secondary: AppColors.cyberCyan,
        surface: AppColors.cardSurface,
        background: AppColors.background,
        error: AppColors.roseDanger,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),

      // Typography with Plus Jakarta Sans
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1.0,
          ),
          displayMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.8,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
          bodyMedium: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted,
          ),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withOpacity(0.85),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Cards
      cardTheme: CardTheme(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.electricPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.roseDanger),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundElevated,
        selectedItemColor: AppColors.electricPurple,
        unselectedItemColor: AppColors.textDim,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

