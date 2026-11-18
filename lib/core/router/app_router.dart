import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/screens/animal_detail_screen.dart';
import '../../presentation/screens/animal_form_screen.dart';
import '../../presentation/screens/animal_list_screen.dart';
import '../../presentation/screens/about_screen.dart';
import '../../presentation/screens/buyer_list_screen.dart';
import '../../presentation/screens/health_test_form_screen.dart';
import '../../presentation/screens/help_screen.dart';
import '../../presentation/screens/kennel_stats_screen.dart';
import '../../presentation/screens/litter_form_screen.dart';
import '../../presentation/screens/litter_list_screen.dart';
import '../../presentation/screens/lock_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/privacy_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/terms_screen.dart';
import '../../presentation/screens/vaccination_form_screen.dart';
import '../../presentation/screens/vet_visit_form_screen.dart';
import '../../presentation/screens/weight_form_screen.dart';
import '../../presentation/screens/whats_new_screen.dart';

class AppPaths {
  AppPaths._();

  static const String lock = '/lock';
  static const String animals = '/animals';
  static const String newAnimal = '/animals/new';
  static const String litters = '/litters';
  static const String newLitter = '/litters/new';
  static const String buyers = '/buyers';
  static const String settings = '/settings';
  static const String onboarding = '/welcome';
  static const String about = '/settings/about';
  static const String privacy = '/settings/privacy';
  static const String terms = '/settings/terms';
  static const String help = '/settings/help';
  static const String whatsNew = '/settings/whats-new';
  static const String stats = '/settings/stats';

  static String editAnimal(String id) => '/animals/$id/edit';

  static String animal(String id) => '/animals/$id';

  static String newVaccination(String animalId) =>
      '/animals/$animalId/vaccinations/new';

  static String vaccination(String animalId, String id) =>
      '/animals/$animalId/vaccinations/$id';

  static String newWeight(String animalId) => '/animals/$animalId/weights/new';

  static String newHealthTest(String animalId) =>
      '/animals/$animalId/health-tests/new';

  static String healthTest(String animalId, String id) =>
      '/animals/$animalId/health-tests/$id';

  static String newVisit(String animalId) => '/animals/$animalId/visits/new';

  static String visit(String animalId, String id) =>
      '/animals/$animalId/visits/$id';

  static String litter(String id) => '/litters/$id';

  static String editLitter(String id) => '/litters/$id/edit';
}

/// go_router only re-runs `redirect` when this fires.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    _sub = ref.listen<bool>(lockGateProvider, (previous, next) {
      if (previous != next) notifyListeners();
    });
    // The introduction closing is the second thing that changes where this phone
    // belongs. It is a separate subscription because the gate and the slides
    // answer different questions: one says whether the ledger may be shown, the
    // other whether the breeder has been shown around it.
    _onboarding = ref.listen<bool>(onboardingSeenProvider, (previous, next) {
      if (previous != next) notifyListeners();
    });
  }

  late final ProviderSubscription<bool> _sub;
  late final ProviderSubscription<bool> _onboarding;

  @override
  void dispose() {
    _sub.close();
    _onboarding.close();
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
      final seen = ref.read(onboardingSeenProvider);
      final here = state.matchedLocation;
      final onLockPage = here == AppPaths.lock;
      final onOnboarding = here == AppPaths.onboarding;

      // The gate first, always. A phone in a bag is locked whether or not anyone
      // has been shown the introduction, and two redirects that both claim the
      // first frame would fight over it.
      if (hasPin && !unlocked) return onLockPage ? null : AppPaths.lock;
      if (hasPin && unlocked && onLockPage) {
        return seen ? AppPaths.animals : AppPaths.onboarding;
      }
      // Unlocked, or never locked: a fresh install is walked through three slides
      // before an empty herd. Reopening them from Settings is a `go` to the same
      // path with `seen` already true, and that has to be allowed through rather
      // than bounced back — the tile exists precisely so the page can be seen
      // again.
      if (!seen && !onOnboarding) return AppPaths.onboarding;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppPaths.onboarding,
        builder: (context, state) =>
            OnboardingScreen(returnTo: state.uri.queryParameters['from']),
      ),
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
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                AnimalDetailScreen(animalId: state.pathParameters['id']!),
            routes: <RouteBase>[
              // 'new' is declared before ':recordId' so a new dose is never read
              // as an id, exactly as /litters/new is.
              GoRoute(
                path: 'vaccinations/new',
                builder: (context, state) => VaccinationFormScreen(
                  animalId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'vaccinations/:recordId',
                builder: (context, state) => VaccinationFormScreen(
                  animalId: state.pathParameters['id']!,
                  vaccinationId: state.pathParameters['recordId'],
                ),
              ),
              GoRoute(
                path: 'weights/new',
                builder: (context, state) =>
                    WeightFormScreen(animalId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'health-tests/new',
                builder: (context, state) =>
                    HealthTestFormScreen(animalId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'health-tests/:recordId',
                builder: (context, state) => HealthTestFormScreen(
                  animalId: state.pathParameters['id']!,
                  testId: state.pathParameters['recordId'],
                ),
              ),
              GoRoute(
                path: 'visits/new',
                builder: (context, state) =>
                    VetVisitFormScreen(animalId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'visits/:recordId',
                builder: (context, state) => VetVisitFormScreen(
                  animalId: state.pathParameters['id']!,
                  visitId: state.pathParameters['recordId'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppPaths.litters,
        builder: (context, state) => const LitterListScreen(),
        routes: <RouteBase>[
          // Declared before ':id' so a new litter is never read as an id.
          GoRoute(
            path: 'new',
            builder: (context, state) => const LitterFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) =>
                LitterFormScreen(litterId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                LitterDetailScreen(litterId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: AppPaths.buyers,
        builder: (context, state) => const BuyerListScreen(),
      ),
      GoRoute(
        path: AppPaths.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: 'terms',
            builder: (context, state) => const TermsScreen(),
          ),
          GoRoute(
            path: 'help',
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: 'whats-new',
            builder: (context, state) => const WhatsNewScreen(),
          ),
          GoRoute(
            path: 'stats',
            builder: (context, state) => const KennelStatsScreen(),
          ),
        ],
      ),
    ],
  );
});
