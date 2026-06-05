import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AquaColors extends ThemeExtension<AquaColors> {
  final Color scaffoldGradientStart;
  final Color scaffoldGradientMid;
  final Color scaffoldGradientEnd;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textHint;
  final Color sheetBg;

  const AquaColors({
    required this.scaffoldGradientStart,
    required this.scaffoldGradientMid,
    required this.scaffoldGradientEnd,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textHint,
    required this.sheetBg,
  });

  static const dark = AquaColors(
    scaffoldGradientStart: Color(0xFF0A1929),
    scaffoldGradientMid: Color(0xFF0D2137),
    scaffoldGradientEnd: Color(0x4D006064),
    cardBg: Color(0x0DFFFFFF),
    cardBorder: Color(0x14FFFFFF),
    textPrimary: Colors.white,
    textSecondary: Color(0xB3FFFFFF),
    textTertiary: Color(0x8AFFFFFF),
    textHint: Color(0x61FFFFFF),
    sheetBg: Color(0xFF0D2137),
  );

  static const light = AquaColors(
    scaffoldGradientStart: Color(0xFFF5FBFC),
    scaffoldGradientMid: Color(0xFFE8F5F7),
    scaffoldGradientEnd: Color(0xFFD4EEEF),
    cardBg: Color(0x0A000000),
    cardBorder: Color(0x14000000),
    textPrimary: Color(0xDE000000),
    textSecondary: Color(0x99000000),
    textTertiary: Color(0x61000000),
    textHint: Color(0x42000000),
    sheetBg: Color(0xFFF5FBFC),
  );

  @override
  AquaColors copyWith({
    Color? scaffoldGradientStart,
    Color? scaffoldGradientMid,
    Color? scaffoldGradientEnd,
    Color? cardBg,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textHint,
    Color? sheetBg,
  }) =>
      AquaColors(
        scaffoldGradientStart: scaffoldGradientStart ?? this.scaffoldGradientStart,
        scaffoldGradientMid: scaffoldGradientMid ?? this.scaffoldGradientMid,
        scaffoldGradientEnd: scaffoldGradientEnd ?? this.scaffoldGradientEnd,
        cardBg: cardBg ?? this.cardBg,
        cardBorder: cardBorder ?? this.cardBorder,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        textHint: textHint ?? this.textHint,
        sheetBg: sheetBg ?? this.sheetBg,
      );

  @override
  AquaColors lerp(AquaColors? other, double t) {
    if (other == null) return this;
    return AquaColors(
      scaffoldGradientStart: Color.lerp(scaffoldGradientStart, other.scaffoldGradientStart, t)!,
      scaffoldGradientMid: Color.lerp(scaffoldGradientMid, other.scaffoldGradientMid, t)!,
      scaffoldGradientEnd: Color.lerp(scaffoldGradientEnd, other.scaffoldGradientEnd, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      sheetBg: Color.lerp(sheetBg, other.sheetBg, t)!,
    );
  }
}

extension AquaColorsX on BuildContext {
  AquaColors get aqua => Theme.of(this).extension<AquaColors>()!;
}

class AppTheme {
  AppTheme._();

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
        extensions: const [AquaColors.light],
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
        extensions: const [AquaColors.dark],
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
