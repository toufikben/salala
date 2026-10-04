import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';

/// The three top-level destinations.
///
/// Each screen carries its own bar instead of a shell route on purpose: three
/// lists do not need a preserved navigation stack per tab, and a plain bar
/// keeps every screen independently pumpable in a widget test.
class SalalaNavBar extends StatelessWidget {
  const SalalaNavBar({super.key, required this.index});

  final int index;

  static const List<String> _paths = <String>[
    AppPaths.animals,
    AppPaths.litters,
    AppPaths.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => context.go(_paths[i]),
      destinations: <NavigationDestination>[
        NavigationDestination(
          icon: const Icon(Icons.pets_outlined),
          selectedIcon: const Icon(Icons.pets),
          label: l10n.navAnimals,
        ),
        NavigationDestination(
          icon: const Icon(Icons.family_restroom_outlined),
          selectedIcon: const Icon(Icons.family_restroom),
          label: l10n.navLitters,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.navSettings,
        ),
      ],
    );
  }
}
