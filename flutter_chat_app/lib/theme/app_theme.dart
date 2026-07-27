import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF5957D5);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: isLight
          ? const Color(0xFFF7F7FC)
          : const Color(0xFF111116),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isLight
            ? const Color(0xFFF7F7FC)
            : const Color(0xFF111116),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : colors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? Colors.white : colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
