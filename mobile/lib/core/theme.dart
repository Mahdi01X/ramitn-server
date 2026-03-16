import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Premium Café Tunisien Color Palette ─────────────────────
class CafeTunisienColors {
  // Greens — table
  static const Color tableGreen = Color(0xFF1A4D2E);
  static const Color tableGreenLight = Color(0xFF2D6A4F);
  static const Color feltGreen = Color(0xFF1B5E20);
  static const Color emerald = Color(0xFF0B3D0B);
  static const Color malachite = Color(0xFF115E26);

  // Wood & warmth
  static const Color woodBrown = Color(0xFF3E1F00);
  static const Color woodLight = Color(0xFF6D4C2E);
  static const Color tableBorder = Color(0xFF8B6914);
  static const Color espresso = Color(0xFF2C1810);
  static const Color mahogany = Color(0xFF4A0E0E);
  static const Color walnut = Color(0xFF1A0D06);
  static const Color rosewood = Color(0xFF3B1515);

  // Gold & amber — accent
  static const Color gold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldPale = Color(0xFFFFE082);
  static const Color amber = Color(0xFFE8A317);
  static const Color brass = Color(0xFFB8860B);
  static const Color champagne = Color(0xFFF7E7CE);
  static const Color goldenrod = Color(0xFFDAA520);

  // Reds
  static const Color warmRed = Color(0xFFC0392B);
  static const Color rubyRed = Color(0xFF9B111E);
  static const Color crimson = Color(0xFFDC143C);
  static const Color burgundy = Color(0xFF800020);

  // Blues (for online/multiplayer accents)
  static const Color royalBlue = Color(0xFF1565C0);
  static const Color sapphire = Color(0xFF0F3460);

  // Neutrals
  static const Color cream = Color(0xFFFAF0E6);
  static const Color ivory = Color(0xFFFFF8F0);
  static const Color smoke = Color(0x33FFFFFF);
  static const Color darkOverlay = Color(0xDD1A1A1A);
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color obsidian = Color(0xFF060304);

  // Cards
  static const Color cardBack = Color(0xFF8B0000);
  static const Color cardWhite = Color(0xFFFFFDF7);
  static const Color cardShadow = Color(0xFF2A0000);

  // Glassmorphism
  static const Color glassWhite = Color(0x18FFFFFF);
  static const Color glassBorder = Color(0x30FFFFFF);
  static const Color glassBlack = Color(0x40000000);
  static const Color glassGold = Color(0x25D4A017);

  // Gradients
  static const List<Color> goldGradient = [
    Color(0xFFE8A317),
    Color(0xFFFFD700),
    Color(0xFFF7E7CE),
    Color(0xFFFFD700),
    Color(0xFFD4A017),
  ];

  static const List<Color> darkWoodGradient = [
    Color(0xFF1A0D06),
    Color(0xFF2C1810),
    Color(0xFF3E1F00),
  ];

  static const List<Color> feltGradient = [
    Color(0xFF0D3B13),
    Color(0xFF1B5E20),
    Color(0xFF256B28),
    Color(0xFF367D3A),
  ];
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

  static TextStyle get scoreValue => GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: CafeTunisienColors.goldLight,
  );

  static TextStyle get cardRank => GoogleFonts.playfairDisplay(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    height: 1.0,
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
