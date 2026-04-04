import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondary: AppColors.onSecondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: TextTheme(
        // Display - Lexend
        displayLarge: GoogleFonts.lexend(
          fontSize: 56, fontWeight: FontWeight.w900,
          color: AppColors.onSurface, letterSpacing: -2,
        ),
        displayMedium: GoogleFonts.lexend(
          fontSize: 40, fontWeight: FontWeight.w900,
          color: AppColors.onSurface, letterSpacing: -1.5,
        ),
        displaySmall: GoogleFonts.lexend(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: AppColors.onSurface, letterSpacing: -1,
        ),
        // Headline - Lexend
        headlineLarge: GoogleFonts.lexend(
          fontSize: 28, fontWeight: FontWeight.w800,
          color: AppColors.onSurface, letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.lexend(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        headlineSmall: GoogleFonts.lexend(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        // Label - Space Grotesk
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: AppColors.onSurface, letterSpacing: 1.5,
        ),
        labelMedium: GoogleFonts.spaceGrotesk(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant, letterSpacing: 1.5,
        ),
        labelSmall: GoogleFonts.spaceGrotesk(
          fontSize: 9, fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant, letterSpacing: 2,
        ),
        // Body - Manrope
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16, fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(
            color: AppColors.primaryContainer, width: 1,
          ),
        ),
        labelStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.onSurfaceVariant,
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2,
        ),
        hintStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.outlineVariant, fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1A484847), thickness: 1,
      ),
    );
  }
}
