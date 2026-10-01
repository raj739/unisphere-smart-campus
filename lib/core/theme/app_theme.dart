import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const colors = ColorScheme.light(
      primary: Color(0xFF1F3A5F),
      onPrimary: Colors.white,
      secondary: Color(0xFF0F766E),
      onSecondary: Colors.white,
      tertiary: Color(0xFFB45309),
      onTertiary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF172033),
      error: Color(0xFFB42318),
      outline: Color(0xFFD7DDE7),
    );

    const fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(7)),
      borderSide: BorderSide(color: Color(0xFFD7DDE7)),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      colorScheme: colors,
      scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      dividerColor: const Color(0xFFE5E9F0),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(7)),
          borderSide: BorderSide(color: Color(0xFF1F3A5F), width: 1.6),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(color: Color(0xFF526078)),
        hintStyle: TextStyle(color: Color(0xFF8A96A8)),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: Color(0xFFE2E7EF)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 450),
      ),
    );
  }
}
