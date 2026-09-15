import 'package:flutter/material.dart';

class AppColors {
  static const violet = Color(0xFF7057FF);
  static const coral = Color(0xFFFF725E);
  static const mint = Color(0xFF31C99B);
  static const ink = Color(0xFF19182A);
  static const cloud = Color(0xFFF7F7FB);
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.violet,
    brightness: brightness,
    primary: isDark ? const Color(0xFFA99AFF) : AppColors.violet,
    secondary: AppColors.coral,
    surface: isDark ? const Color(0xFF1D1C2B) : Colors.white,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: scheme.outlineVariant),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF12111C) : AppColors.cloud,
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          fontFamily: 'Arial',
          bodyColor: isDark ? Colors.white : AppColors.ink,
          displayColor: isDark ? Colors.white : AppColors.ink,
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF252435) : const Color(0xFFF9F9FC),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .65)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

