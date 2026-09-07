import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/utils/app_colors.dart';
import 'package:app/core/utils/app_tokens.dart';

class AppTheme {
  AppTheme._();

  /// Compact mobile type scale adhering to SKILL.md rules:
  /// - Hero / Large Title: 20-22px | w700 | height: 1.2
  /// - Section Heading / Card Title: 15-16px | w600 | height: 1.3
  /// - List Tile Title / Subheading: 14px | w500 or w600 | height: 1.35
  /// - Standard Body Text: 13-14px | w400 | height: 1.45
  /// - Secondary / Supporting Text: 12-13px | w400 | opacity: 60%
  /// - Micro Labels / Badges: 10-11px | w500 | letter-spacing: 0.2px
  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, color: primaryText,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w700, height: 1.2, color: primaryText,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w700, height: 1.25, color: primaryText,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: primaryText,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w600, height: 1.3, color: primaryText,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w600, height: 1.3, color: primaryText,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, height: 1.35, color: primaryText,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, height: 1.35, color: primaryText,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: primaryText,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13.5, fontWeight: FontWeight.w400, height: 1.45, color: primaryText,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: secondaryText,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, height: 1.3, color: primaryText,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500, height: 1.25, letterSpacing: 0.2, color: secondaryText,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w500, height: 1.2, letterSpacing: 0.2, color: secondaryText,
      ),
    );
  }

  // ─── DARK THEME ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    const primaryText = Color(0xFFEFF2FF);
    const secondaryText = Color(0xFF8FA3C8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.gold,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: primaryText,
      ),
      textTheme: _buildTextTheme(primaryText, secondaryText),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.rCard),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, color: primaryText,
        ),
        iconTheme: const IconThemeData(color: primaryText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: Color(0xFF4A5568),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          color: AppColors.primaryLight,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: secondaryText,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.s16, vertical: AppTokens.s12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: secondaryText, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF4A5568), fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rInput)),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24, vertical: AppTokens.s12),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkCard,
        labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: primaryText),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMicro)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ─── LIGHT THEME ────────────────────────────────────────────
  static ThemeData get lightTheme {
    const primaryText = Color(0xFF0F172A);
    const secondaryText = Color(0xFF475569);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.goldDark,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: primaryText,
      ),
      textTheme: _buildTextTheme(primaryText, secondaryText),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.rCard),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, color: primaryText,
        ),
        iconTheme: const IconThemeData(color: primaryText),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          color: AppColors.primaryBlue,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: secondaryText,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCardElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.s16, vertical: AppTokens.s12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rInput),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: secondaryText, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rInput)),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s24, vertical: AppTokens.s12),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightCardElevated,
        labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: primaryText),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rMicro)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
