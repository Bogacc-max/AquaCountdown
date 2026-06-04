import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AquaCountdown Tasarım Sistemi
///
/// Renk paleti:
///   Primary:        #00BCD4  (Aqua)
///   Primary Dark:   #006064
///   Accent:         #FFD54F  (Su damlası altın)
///   Bg Light:       #F5FBFC
///   Bg Dark:        #0A1929
///   Surface:        #FFFFFF / #1A2332
class AppTheme {
  AppTheme._();

  // ─── Renkler ─────────────────────────────────────
  static const primary = Color(0xFF00BCD4);
  static const primaryDark = Color(0xFF006064);
  static const accent = Color(0xFFFFD54F);
  static const bgLight = Color(0xFFF5FBFC);
  static const bgDark = Color(0xFF0A1929);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1A2332);
  static const error = Color(0xFFE57373);

  // ─── Açık Tema ───────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          secondary: accent,
          surface: surfaceLight,
          error: error,
        ),
        scaffoldBackgroundColor: bgLight,
        textTheme: _textTheme(Colors.black87),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgLight,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surfaceLight,
          indicatorColor: primary.withOpacity(0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: primary, fontWeight: FontWeight.w600, fontSize: 12);
            }
            return const TextStyle(color: Colors.black54, fontSize: 12);
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: primary,
          thumbColor: primary,
          inactiveTrackColor: Colors.black12,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );

  // ─── Koyu Tema ───────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          primary: primary,
          secondary: accent,
          surface: surfaceDark,
          error: error,
        ),
        scaffoldBackgroundColor: bgDark,
        textTheme: _textTheme(Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0A1929),
          indicatorColor: primary.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: primary, fontWeight: FontWeight.w600, fontSize: 12);
            }
            return TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12);
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: primary,
          thumbColor: primary,
          inactiveTrackColor: Colors.white12,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF0D2137),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
          contentTextStyle: TextStyle(color: Colors.white70),
        ),
      );

  static TextTheme _textTheme(Color baseColor) => TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: baseColor,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: baseColor,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: baseColor,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: baseColor,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          color: baseColor,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: baseColor.withOpacity(0.8),
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: baseColor.withOpacity(0.6),
        ),
      );
}
