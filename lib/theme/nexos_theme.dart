// lib/theme/nexos_theme.dart
// NexOS Design System – Ubuntu Style

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NexOSTheme {
  // ── Ubuntu Palette ────────────────────────────────────────────────────────
  static const Color bg         = Color(0xFF2C001E); // dark aubergine
  static const Color surface    = Color(0xFF3D1030); // aubergine surface
  static const Color surfaceAlt = Color(0xFF4F1A3F); // elevated surface
  static const Color accent     = Color(0xFFE95420); // Ubuntu orange
  static const Color accentGlow = Color(0x33E95420); // orange glow
  static const Color success    = Color(0xFF4CAF50); // green
  static const Color warning    = Color(0xFFFFB300); // amber
  static const Color error      = Color(0xFFCF6679); // soft red
  static const Color textPri    = Color(0xFFFFFFFF); // white
  static const Color textSec    = Color(0xFFAEA79F); // Ubuntu warm grey
  static const Color border     = Color(0xFF5C2049); // aubergine border

  // ── Typography ────────────────────────────────────────────────────────────
  static TextTheme get textTheme =>
      GoogleFonts.ubuntuTextTheme().copyWith(
        displayLarge: GoogleFonts.ubuntu(
          color: textPri,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.ubuntu(
          color: textPri,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: GoogleFonts.ubuntu(
          color: textPri,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: GoogleFonts.ubuntu(
          color: textPri,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: GoogleFonts.ubuntu(color: textPri, fontSize: 14),
        bodyMedium: GoogleFonts.ubuntu(color: textSec, fontSize: 13),
        labelLarge: GoogleFonts.ubuntu(
          color: textPri,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  // ── Material Theme ────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: success,
      surface: surface,
      error: error,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.ubuntu(
        color: textPri,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: const IconThemeData(color: textPri),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      labelStyle: const TextStyle(color: textSec),
      hintStyle: const TextStyle(color: textSec),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.ubuntu(fontWeight: FontWeight.w500),
      ),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
  );
}

// Reusable gradients
class NexGradient {
  static const LinearGradient accent = LinearGradient(
    colors: [Color(0xFFE95420), Color(0xFF77216F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient boot = LinearGradient(
    colors: [Color(0xFF2C001E), Color(0xFF3D1030), Color(0xFF2C001E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
