import 'package:flutter/material.dart';

class PlumaColors {
  static const Color surface = Color(0xFF061700);
  static const Color surfaceBright = Color(0xFF2B3E1D);
  static const Color onSurface = Color(0xFFD2EABB);
  static const Color onSurfaceVariant = Color(0xFFA0B88D);
  static const Color outline = Color(0xFFA18D7C);
  static const Color primary = Color(0xFFFFB870);
  static const Color onPrimary = Color(0xFF4A2800);
  static const Color secondary = Color(0xFF67DAC2);
  static const Color tertiary = Color(0xFF92CFEA);
  static const Color neonActive = Color(0xFF98FF98);
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  // Preset profile accent colors.
  static const List<Map<String, String>> presets = [
    {'color': '#ffb870', 'label': 'bursztyn'},
    {'color': '#67dac2', 'label': 'morska'},
    {'color': '#92cfea', 'label': 'blekit'},
    {'color': '#98ff98', 'label': 'plynny'},
    {'color': '#d2eabb', 'label': 'grafit'},
  ];
}

class PlumaTheme {
  static Color parseHex(String hex) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? PlumaColors.primary : Color(parsed);
  }

  static String colorToHex(Color color) {
    final argb = color.toARGB32();
    final rgb = argb & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  static ThemeData build(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PlumaColors.surface,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: PlumaColors.onPrimary,
        secondary: PlumaColors.secondary,
        tertiary: PlumaColors.tertiary,
        surface: PlumaColors.surface,
        onSurface: PlumaColors.onSurface,
        error: PlumaColors.error,
      ),
      fontFamily: 'Ubuntu',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: PlumaColors.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w300,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          color: PlumaColors.onSurface,
          fontSize: 12,
          height: 1.5,
        ),
        headlineSmall: TextStyle(
          color: PlumaColors.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          color: PlumaColors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
