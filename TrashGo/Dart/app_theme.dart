import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Gradient base colors (from splash/design)
  static const Color gradientCyan = Color(0xFF7DE8E8);
  static const Color gradientYellow = Color(0xFFE8E87D);
  static const Color gradientMid = Color(0xFF9DDBB0);

  // Primary brand
  static const Color primaryGreen = Color(0xFF4A7C59);
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color accentOrange = Color(0xFFFF6B2B);
  static const Color accentBlue = Color(0xFF1B5E9E);
  static const Color accentYellow = Color(0xFFFFC107);

  // Scan stage colors
  static const Color scanOrangeRed = Color(0xFFFF5722);
  static const Color scanBlue = Color(0xFF2196F3);
  static const Color scanGreen = Color(0xFF4CAF50);

  // UI surfaces
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGlass = Color(0x33FFFFFF);
  static const Color cardYellow = Color(0xFFF5E97A);
  static const Color cardTeal = Color(0xFF26C6DA);

  // Text
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF4A4A6A);
  static const Color textLight = Color(0xFF9E9EB8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Leaderboard podium
  static const Color gold = Color(0xFFFFB800);
  static const Color silver = Color(0xFF5B8DB8);
  static const Color bronze = Color(0xFF4A7C59);
  static const Color podiumListOrange = Color(0xFFFFCB80);
  static const Color podiumUser = Color(0xFFB2EBF2);
}

class AppTheme {
  static LinearGradient get backgroundGradient => const LinearGradient(
        colors: [AppColors.gradientCyan, AppColors.gradientMid, AppColors.gradientYellow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.accentBlue,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.accentBlue,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.accentBlue,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMedium,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMedium,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textWhite,
        ),
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
        textTheme: textTheme,
        scaffoldBackgroundColor: Colors.transparent,
      );

  static BoxDecoration get gradientBackground => BoxDecoration(
        gradient: backgroundGradient,
      );

  static BoxDecoration get glassCard => BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
      );

  static BoxDecoration get whiteCard => BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );
}
