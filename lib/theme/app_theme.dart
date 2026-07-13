import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Système de couleurs "African Modernism"
/// Une fusion entre la terre, la nature et le luxe minimaliste.
class AppColors {
  // --- Palette Light ---
  static const Color terracotta = Color(0xFFC05A3B); // Primary : Terre cuite sophistiquée
  static const Color forest = Color(0xFF2D5A27);     // Secondary : Vert forêt profond
  static const Color chocolate = Color(0xFF4B3621);  // Accent : Chocolat riche
  static const Color ochre = Color(0xFFB8860B);      // Highlight : Ocre doré
  static const Color sand = Color(0xFFFDFBFA);       // Background : Blanc sable chaud
  static const Color surface = Color(0xFFFFFFFF);    // Surface : Blanc pur
  static const Color outline = Color(0xFFE0D7D0);    // Bordures : Sable grisâtre
  static const Color textPrimary = Color(0xFF2D2D2D); // Texte principal : Anthracite chaud
  static const Color textSecondary = Color(0xFF757575); // Texte secondaire

  // --- Palette Dark ---
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTerracotta = Color(0xFFE57399);
  static const Color darkForest = Color(0xFF81C784);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Helpers pour les variantes de couleurs
  static Color withOpacity(Color color, double opacity) => color.withValues(alpha: opacity);
}

class AppTheme {
  // --- THÈME CLAIR (LIGHT MODE) ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.terracotta,
        onPrimary: Colors.white,
        secondary: AppColors.forest,
        onSecondary: Colors.white,
        tertiary: AppColors.chocolate,
        onTertiary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        background: AppColors.sand,
        onBackground: AppColors.textPrimary,
        error: const Color(0xFFB00020),
        onError: Colors.white,
        outline: AppColors.outline,
      ),
      
      // Typographie : Utilisation de GoogleFonts pour une élégance moderne
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 57, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.medium, color: AppColors.textSecondary,
        ),
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.terracotta,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: AppColors.terracotta),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.terracotta,
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      // Champs de saisie
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.w600),
      ),

      // Cartes
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  // --- THÈME SOMBRE (DARK MODE) ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkTerracotta,
        onPrimary: Colors.black,
        secondary: AppColors.darkForest,
        onSecondary: Colors.black,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkTextPrimary,
        error: const Color(0xFFCF6679),
        onError: Colors.black,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 57, fontWeight: FontWeight.bold, color: AppColors.darkTextPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.darkTextSecondary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.medium, color: AppColors.darkTextSecondary,
        ),
      ),
      // Les autres thèmes (boutons, input) suivent la logique Material 3 dark
      // mais on peut les personnaliser ici pour plus de finesse.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.darkTerracotta, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
    );
  }
}
