import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand
  static const Color navy = Color(0xFF1B2A4A);
  static const Color navyLight = Color(0xFF2D4470);
  static const Color navyDark = Color(0xFF0F1B33);
  static const Color gold = Color(0xFFC9A227);
  static const Color goldLight = Color(0xFFE8CC6E);

  // Pastel card backgrounds (from the reference designs)
  static const Color orangeCard = Color(0xFFFFD6A0);
  static const Color blueCard = Color(0xFFBDD7F1);
  static const Color greenCard = Color(0xFFB8E8D0);
  static const Color purpleCard = Color(0xFFD4C5F9);
  static const Color pinkCard = Color(0xFFFFC7D8);
  static const Color yellowCard = Color(0xFFFFF3B0);

  // Functional
  static const Color success = Color(0xFF00C9A7);
  static const Color successDark = Color(0xFF00A388);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF4E8AFF);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);
  static const Color orange = Color(0xFFFF9F43);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFF4F5F9);
  static const Color mutedGrey = Color(0xFF8E95A2);
  static const Color darkText = Color(0xFF1A1D26);
  static const Color cardBorder = Color(0xFFE8ECF2);
  static const Color surface = Color(0xFFF0F1F5);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.gold,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.pageBg,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          color: AppColors.darkText,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.mutedGrey,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.mutedGrey,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkText,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.darkText, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: AppColors.white,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
      ),
    );
  }
}
