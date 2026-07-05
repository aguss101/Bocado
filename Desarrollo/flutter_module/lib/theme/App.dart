import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BocadoColors {
  final bool isDark;
  final Color bg;
  final Color surface;
  final Color surfaceContainer;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;

  const BocadoColors._({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.surfaceContainer,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
  });

  factory BocadoColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BocadoColors._(
      isDark: isDark,
      bg: isDark ? AppTheme.bgDark : AppTheme.surfaceContainerLight,
      surface: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      surfaceContainer:
          isDark ? AppTheme.surfaceContainerDark : AppTheme.surfaceContainerLight,
      border: isDark ? AppTheme.outlineDark : AppTheme.outlineLight,
      text: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
      muted: isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
      primary: AppTheme.primary,
    );
  }
}

class BocadoRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class BocadoSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class AppTheme {
  static const Color primary = Color(0xFFD96E11);
  static const Color primaryDark = Color(0xFFD96E11);

  static const Color bgDark = Color(0xFF0D0701);
  static const Color surfaceDark = Color(0xFF1A140F);
  static const Color surfaceContainerDark = Color(0xFF241D17);
  static const Color outlineDark = Color(0xFF3D3732);
  static const Color onSurfaceDark = Color(0xFFF5E6D3);
  static const Color secondaryDark = Color(0xFFA19E9A);

  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFFFFBF5);
  static const Color outlineLight = Color(0xFFE8CCB1);
  static const Color onSurfaceLight = Color(0xFF3E2916);
  static const Color secondaryLight = Color(0xFF7A614A);

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return GoogleFonts.montserratTextTheme(base);
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surfaceDark,
        onSurface: onSurfaceDark,
        outline: outlineDark,
      ),
      textTheme: _textTheme(Brightness.dark),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: secondaryDark, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surfaceContainerLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surfaceLight,
        onSurface: onSurfaceLight,
        outline: outlineLight,
      ),
      textTheme: _textTheme(Brightness.light),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: secondaryLight, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}