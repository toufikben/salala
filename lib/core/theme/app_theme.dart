import 'package:flutter/material.dart';

/// The palette, and the reason for it.
///
/// This app is used outdoors in a kennel, often with one hand and in daylight, so
/// contrast and touch size still outrank decoration. What changed is the *tone*:
/// the first identity was a brown seed with everything else left to
/// `ColorScheme.fromSeed`, which reads as a form. A ledger about animals that a
/// breeder keeps for years should look like a place where the animals are, so the
/// page is warm paper, the ink is a deep pine, and the accent is clay — the three
/// colours of a stall at a show, not of a spreadsheet.
///
/// The seed is the pine. Clay is a second, explicit colour rather than something
/// derived, because a derived tertiary drifted to a purple at this seed and the
/// one place a warm highlight matters — the breeding-stock chip — turned lilac
/// under a warm photo.
class AppColors {
  AppColors._();

  /// Deep pine. Everything structural: app bar ink, selected tab, primary text.
  static const Color seed = Color(0xFF1F5C4D);

  /// Clay. The accent a breeder's eye lands on: breeding stock, and nothing else
  /// that is also a warning.
  static const Color clay = Color(0xFFB4623C);

  /// Warm paper, light scheme. Not white: a white page behind a photo makes the
  /// photo look grey, and this screen is mostly photos now.
  static const Color paper = Color(0xFFFBF7F1);

  /// Warm charcoal, dark scheme. Not black, for the same reason.
  static const Color inkPaper = Color(0xFF17181A);

  static const Color breedingStock = Color(0xFF1B5E20);

  /// The only red in the app, and it means "late", never "wrong".
  static const Color overdue = Color(0xFFB3261E);

  static const Color placed = Color(0xFF37474F);
}

/// One corner radius for everything with a border, so a card, a photo and a field
/// look like they belong to one app.
class AppRadius {
  AppRadius._();

  /// Cards and the photograph inside them.
  static const double card = 20;

  /// A picture tile inside a card: the inner curve is tighter than the outer one
  /// so the two do not read as one shape drawn twice.
  static const double photo = 14;

  static const double field = 14;
}

ThemeData buildAppTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: brightness,
      ).copyWith(
        // Declared rather than derived, for the reason in [AppColors.clay]: the
        // generated tertiary under this seed is a mauve, and the chip it paints is
        // the one warm thing on a herd of photographs.
        tertiary: AppColors.clay,
        onTertiary: Colors.white,
        tertiaryContainer: light
            ? const Color(0xFFFBE3D5)
            : const Color(0xFF4A2818),
        onTertiaryContainer: light
            ? const Color(0xFF3B1B0B)
            : const Color(0xFFFFDBC8),
        // The page. `surface` is what every screen paints behind its cards, and the
        // difference between paper and white is most of what makes a photo sit in
        // the screen rather than on it.
        surface: light ? AppColors.paper : AppColors.inkPaper,
        surfaceContainerLowest: light ? Colors.white : const Color(0xFF101113),
        surfaceContainerLow: light
            ? const Color(0xFFFFFCF7)
            : const Color(0xFF1D1E21),
        surfaceContainer: light
            ? const Color(0xFFF5F0E8)
            : const Color(0xFF232427),
        surfaceContainerHigh: light
            ? const Color(0xFFEFE9DF)
            : const Color(0xFF2B2C30),
        surfaceContainerHighest: light
            ? const Color(0xFFE7E0D5)
            : const Color(0xFF34353A),
      );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final text = base.textTheme;

  return base.copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      // The bar is the page, not a slab on top of it: a raised grey band above a
      // warm page is the single most "generated form" thing a Material app does.
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      // A hairline instead of a shadow: on a phone in daylight a 1-point border
      // reads and a soft shadow does not, and the photo inside supplies the
      // depth the card would otherwise need.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: light ? 0.7 : 0.5),
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return text.labelMedium?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.photo),
      ),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.6),
      space: 1,
      thickness: 1,
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
    ),
  );
}
