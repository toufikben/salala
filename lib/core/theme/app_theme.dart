import 'package:flutter/material.dart';

/// Warm, high-contrast palette: this app is used outdoors in a kennel, often
/// with one hand and in daylight, so large touch targets and strong contrast
/// matter more than decoration.
class AppColors {
  AppColors._();

  static const Color seed = Color(0xFF7A4E2D);
  static const Color breedingStock = Color(0xFF1B5E20);
  static const Color overdue = Color(0xFFB3261E);
  static const Color placed = Color(0xFF37474F);
}

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: brightness,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(centerTitle: false, scrolledUnderElevation: 1),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
  );
}
