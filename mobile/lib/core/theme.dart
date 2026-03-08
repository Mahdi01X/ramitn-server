import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Premium Café Tunisien Color Palette ─────────────────────
class CafeTunisienColors {
  // Greens — table
  static const Color tableGreen = Color(0xFF1A4D2E);
  static const Color tableGreenLight = Color(0xFF2D6A4F);
  static const Color feltGreen = Color(0xFF1B5E20);

  // Wood & warmth
  static const Color woodBrown = Color(0xFF3E1F00);
  static const Color woodLight = Color(0xFF6D4C2E);
  static const Color tableBorder = Color(0xFF8B6914);
  static const Color espresso = Color(0xFF2C1810);
  static const Color mahogany = Color(0xFF4A0E0E);

  // Gold & amber — accent
  static const Color gold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldPale = Color(0xFFFFE082);
  static const Color amber = Color(0xFFE8A317);
  static const Color brass = Color(0xFFB8860B);

  // Reds
  static const Color warmRed = Color(0xFFC0392B);
  static const Color rubyRed = Color(0xFF9B111E);

  // Neutrals
  static const Color cream = Color(0xFFFAF0E6);
  static const Color ivory = Color(0xFFFFF8F0);
  static const Color smoke = Color(0x33FFFFFF);
  static const Color darkOverlay = Color(0xDD1A1A1A);
  static const Color deepBlack = Color(0xFF0A0A0A);

  // Cards
  static const Color cardBack = Color(0xFF8B0000);
  static const Color cardWhite = Color(0xFFFFFDF7);

  // Glassmorphism
  static const Color glassWhite = Color(0x18FFFFFF);
  static const Color glassBorder = Color(0x30FFFFFF);
  static const Color glassBlack = Color(0x40000000);
}

// ─── Premium Text Styles ─────────────────────────────────────
class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    color: CafeTunisienColors.goldLight,
    letterSpacing: 3,
  );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: CafeTunisienColors.goldLight,
    letterSpacing: 2,
  );

  static TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white70,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    color: Colors.white54,
  );

  static TextStyle get labelGold => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: CafeTunisienColors.goldLight,
  );

  static TextStyle get arabicTagline => GoogleFonts.amiri(
    fontSize: 20,
    fontStyle: FontStyle.italic,
    color: CafeTunisienColors.goldPale,
  );

  static TextStyle get buttonText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// ─── Theme Data ──────────────────────────────────────────────
final ramiTheme = ThemeData(
  useMaterial3: true,
  fontFamily: GoogleFonts.poppins().fontFamily,
  colorScheme: ColorScheme.fromSeed(
    seedColor: CafeTunisienColors.tableGreen,
    primary: CafeTunisienColors.tableGreen,
    secondary: CafeTunisienColors.warmRed,
    tertiary: CafeTunisienColors.gold,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: CafeTunisienColors.espresso,
  cardTheme: CardThemeData(
    elevation: 8,
    color: CafeTunisienColors.cream,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    backgroundColor: Colors.transparent,
    foregroundColor: CafeTunisienColors.goldLight,
    elevation: 0,
    titleTextStyle: GoogleFonts.playfairDisplay(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: CafeTunisienColors.goldLight,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: CafeTunisienColors.gold,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      elevation: 8,
      shadowColor: CafeTunisienColors.gold.withOpacity(0.4),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: CafeTunisienColors.glassWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: CafeTunisienColors.glassBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: CafeTunisienColors.glassBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: CafeTunisienColors.gold, width: 2),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: CafeTunisienColors.woodBrown,
    contentTextStyle: GoogleFonts.poppins(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
  ),
);

final ramiDarkTheme = ramiTheme;
