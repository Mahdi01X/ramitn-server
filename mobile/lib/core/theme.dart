import 'package:flutter/material.dart';

// ─── Couleurs Café Tunisien ──────────────────────────────────
class CafeTunisienColors {
  static const Color tableGreen = Color(0xFF1A4D2E);       // Tapis vert foncé
  static const Color tableGreenLight = Color(0xFF2D6A4F);   // Vert tapis clair
  static const Color tableBorder = Color(0xFF8B6914);        // Bord doré bois
  static const Color woodBrown = Color(0xFF5C3317);          // Bois foncé
  static const Color woodLight = Color(0xFF8B6914);          // Bois clair doré
  static const Color gold = Color(0xFFD4A017);               // Or tunisien
  static const Color goldLight = Color(0xFFFFD700);          // Or brillant
  static const Color warmRed = Color(0xFFC0392B);            // Rouge chaud
  static const Color cream = Color(0xFFFAF0E6);             // Crème
  static const Color smoke = Color(0x33FFFFFF);              // Fumée chicha
  static const Color darkOverlay = Color(0xDD1A1A1A);       // Overlay sombre
  static const Color cardBack = Color(0xFF8B0000);           // Dos carte rouge foncé
  static const Color amber = Color(0xFFE8A317);              // Ambre lampe
}

final ramiTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  colorScheme: ColorScheme.fromSeed(
    seedColor: CafeTunisienColors.tableGreen,
    primary: CafeTunisienColors.tableGreen,
    secondary: CafeTunisienColors.warmRed,
    tertiary: CafeTunisienColors.gold,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: CafeTunisienColors.tableGreen,
  cardTheme: CardThemeData(
    elevation: 6,
    color: CafeTunisienColors.cream,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  ),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    backgroundColor: CafeTunisienColors.woodBrown.withOpacity(0.95),
    foregroundColor: CafeTunisienColors.goldLight,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: CafeTunisienColors.gold,
      foregroundColor: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);

final ramiDarkTheme = ramiTheme; // Same — the game is always "dark" ambiance
