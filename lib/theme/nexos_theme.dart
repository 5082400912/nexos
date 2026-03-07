// lib/theme/nexos_theme.dart
// NexOS Design System - CSEC 431-1

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NexOSTheme {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0A0E1A); // deep navy
  static const Color surface = Color(0xFF111827); // card bg
  static const Color surfaceAlt = Color(0xFF1C2333); // elevated card
  static const Color accent = Color(0xFF00D4FF); // cyan
  static const Color accentGlow = Color(0x3300D4FF);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF5252);
  static const Color textPri = Color(0xFFECEFF1);
  static const Color textSec = Color(0xFF90A4AE);
  static const Color border = Color(0xFF263040);

  // ── Typography ────────────────────────────────────────────────────────────
  static TextTheme get textTheme =>
      GoogleFonts.spaceGroteskTextTheme().copyWith(
        displayLarge: GoogleFonts.orbitron(
          color: textPri,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.orbitron(
          color: textPri,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: textPri,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          color: textPri,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(color: textPri, fontSize: 14),
        bodyMedium: GoogleFonts.spaceGrotesk(color: textSec, fontSize: 13),
        labelLarge: GoogleFonts.spaceGrotesk(
          color: textPri,
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
      titleTextStyle: GoogleFonts.spaceGrotesk(
        color: textPri,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: accent),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSec),
      hintStyle: const TextStyle(color: textSec),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: bg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
  );
}

// Reusable gradient for neon accents
class NexGradient {
  static const LinearGradient accent = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF7B2FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient boot = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0D1B2A), Color(0xFF0A0E1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
