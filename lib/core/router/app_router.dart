import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/screens/animal_form_screen.dart';
import '../../presentation/screens/animal_list_screen.dart';
import '../../presentation/screens/lock_screen.dart';
import '../../presentation/screens/settings_screen.dart';

class AppPaths {
  AppPaths._();

  static const String lock = '/lock';
  static const String animals = '/animals';
  static const String newAnimal = '/animals/new';
  static const String settings = '/settings';

  static String editAnimal(String id) => '/animals/$id/edit';
}

/// go_router only re-runs `redirect` when this fires.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    _sub = ref.listen<bool>(lockGateProvider, (previous, next) {
      if (previous != next) notifyListeners();
    });
  }

  late final ProviderSubscription<bool> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppPaths.animals,
    refreshListenable: refresh,
    redirect: (context, state) {
      final hasPin = ref.read(hasPinProvider);
      final unlocked = ref.read(lockGateProvider);
      final onLockPage = state.matchedLocation == AppPaths.lock;

      if (hasPin && !unlocked && !onLockPage) return AppPaths.lock;
      if ((!hasPin || unlocked) && onLockPage) return AppPaths.animals;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppPaths.lock,
        builder: (context, state) => const PinGateScreen(),
      ),
      GoRoute(
        path: AppPaths.animals,
        builder: (context, state) => const AnimalListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (context, state) =>
                const AnimalFormScreen(mode: AnimalFormMode.create),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) => AnimalFormScreen(
              mode: AnimalFormMode.edit,
              animalId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppPaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
