import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ColorblindNotifier.dart';

class ColorToken {
  final Color base;
  final Color protanopia;
  final Color deuteranopia;
  final Color tritanopia;

  const ColorToken({
    required this.base,
    required this.protanopia,
    required this.deuteranopia,
    required this.tritanopia,
  });

  Color resolve(ColorblindConfig config) {
    if (!config.enabled) return base;
    return switch (config.profile) {
      ColorblindProfile.protanopia => protanopia,
      ColorblindProfile.deuteranopia => deuteranopia,
      ColorblindProfile.tritanopia => tritanopia,
    };
  }
}

class BocadoPalette {
  static const primary = ColorToken(
    base: Color(0xFFD96E11),
    protanopia: Color(0xFFE69F00),
    deuteranopia: Color(0xFFE69F00),
    tritanopia: Color(0xFFD96E11),
  );
  static const error = ColorToken(
    base: Color(0xFFB91C1C),
    protanopia: Color(0xFFD55E00),
    deuteranopia: Color(0xFFD55E00),
    tritanopia: Color(0xFFDC2626),
  );
  static const success = ColorToken(
    base: Color(0xFF4CAF50),
    protanopia: Color(0xFF009E73),
    deuteranopia: Color(0xFF009E73),
    tritanopia: Color(0xFF16A34A),
  );
  static const like = ColorToken(
    base: Color(0xFFF44336),
    protanopia: Color(0xFFCC79A7),
    deuteranopia: Color(0xFFCC79A7),
    tritanopia: Color(0xFFE53935),
  );
  static const rating = ColorToken(
    base: Color(0xFFFFC107),
    protanopia: Color(0xFFF0E442),
    deuteranopia: Color(0xFFF0E442),
    tritanopia: Color(0xFFFFB300),
  );
  static const premium = ColorToken(
    base: Color(0xFFFFC107),
    protanopia: Color(0xFF785EF0),
    deuteranopia: Color(0xFF785EF0),
    tritanopia: Color(0xFF785EF0),
  );
}

Color cvdNeutral(Color base, ColorblindConfig config) {
  if (!config.enabled) return base;
  final hsl = HSLColor.fromColor(base);
  final double deltaHue = switch (config.profile) {
    ColorblindProfile.protanopia => 6.0,
    ColorblindProfile.deuteranopia => 6.0,
    ColorblindProfile.tritanopia => -6.0,
  };
  return hsl.withHue((hsl.hue + deltaHue) % 360.0).toColor();
}

class BocadoColors {
  final bool isDark;
  final Color bg;
  final Color surface;
  final Color surfaceContainer;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final Color error;
  final Color success;
  final Color like;
  final Color rating;
  final Color premium;

  const BocadoColors._({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.surfaceContainer,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.error,
    required this.success,
    required this.like,
    required this.rating,
    required this.premium,
  });

  factory BocadoColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cb = ColorblindScope.of(context).value;
    return BocadoColors._(
      isDark: isDark,
      bg: cvdNeutral(isDark ? AppTheme.bgDark : AppTheme.surfaceContainerLight, cb),
      surface: cvdNeutral(isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight, cb),
      surfaceContainer:
          cvdNeutral(isDark ? AppTheme.surfaceContainerDark : AppTheme.surfaceContainerLight, cb),
      border: cvdNeutral(isDark ? AppTheme.outlineDark : AppTheme.outlineLight, cb),
      text: cvdNeutral(isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight, cb),
      muted: cvdNeutral(isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight, cb),
      primary: BocadoPalette.primary.resolve(cb),
      error: BocadoPalette.error.resolve(cb),
      success: BocadoPalette.success.resolve(cb),
      like: BocadoPalette.like.resolve(cb),
      rating: BocadoPalette.rating.resolve(cb),
      premium: BocadoPalette.premium.resolve(cb),
    );
  }
}

class BocadoRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;
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

  static ThemeData dark(ColorblindConfig cb) {
    final primaryC = BocadoPalette.primary.resolve(cb);
    final bg = cvdNeutral(bgDark, cb);
    final surface = cvdNeutral(surfaceDark, cb);
    final surfaceContainer = cvdNeutral(surfaceContainerDark, cb);
    final outline = cvdNeutral(outlineDark, cb);
    final onSurface = cvdNeutral(onSurfaceDark, cb);
    final secondary = cvdNeutral(secondaryDark, cb);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: primaryC,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
      ),
      textTheme: _textTheme(Brightness.dark),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryC, width: 1.5),
        ),
        hintStyle: TextStyle(color: secondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryC,
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

  static ThemeData light(ColorblindConfig cb) {
    final primaryC = BocadoPalette.primary.resolve(cb);
    final surface = cvdNeutral(surfaceLight, cb);
    final surfaceContainer = cvdNeutral(surfaceContainerLight, cb);
    final outline = cvdNeutral(outlineLight, cb);
    final onSurface = cvdNeutral(onSurfaceLight, cb);
    final secondary = cvdNeutral(secondaryLight, cb);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surfaceContainer,
      colorScheme: ColorScheme.light(
        primary: primaryC,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
      ),
      textTheme: _textTheme(Brightness.light),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryC, width: 1.5),
        ),
        hintStyle: TextStyle(color: secondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryC,
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
