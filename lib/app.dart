import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';

/// The app shell, and the one place that watches the app leave the screen.
///
/// A PIN that is only asked for at launch is not a lock: a phone handed to a
/// buyer stays unlocked until the process dies, which on Android can be days.
class SalalaApp extends ConsumerStatefulWidget {
  const SalalaApp({super.key});

  @override
  ConsumerState<SalalaApp> createState() => _SalalaAppState();
}

class _SalalaAppState extends ConsumerState<SalalaApp>
    with WidgetsBindingObserver {
  /// When the app last went to the background, or null while it is in front.
  DateTime? _leftAt;

  /// The router, kept so a tapped reminder can be opened from outside the tree.
  ///
  /// `MaterialApp.router` builds its own `Navigator`, so there is no `context`
  /// to push from at the moment the tap arrives — on a cold start there is not
  /// even a frame yet. The `GoRouterState` is the one handle that survives.
  GoRouter? _router;
  ProviderSubscription<String?>? _tapSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The launch payload is only known after `runApp`, so `main()` records it
    // and this picks it up on the first frame — the same path a live tap takes,
    // because by then the difference between the two has stopped mattering.
    _tapSubscription = ref.listenManual<String?>(
      pendingAnimalTapProvider,
      (previous, next) => _openTappedAnimal(next),
    );
  }

  @override
  void dispose() {
    _tapSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Sends a tapped reminder into the ledger, once the shell can take it.
  ///
  /// The animal is opened by id, so an alert for a dog deleted in the meantime
  /// lands on the screen's own "this animal is gone" rather than on a blank
  /// route. Called again on return from the gate: a locked phone answers the tap
  /// with the PIN, and the alert must not be forgotten behind it.
  void _openTappedAnimal(String? animalId) {
    if (animalId == null) return;
    final router = _router;
    if (router == null) return;
    if (ref.read(hasPinProvider) && !ref.read(lockGateProvider)) return;
    ref.read(pendingAnimalTapProvider.notifier).take();
    router.go(AppPaths.animal(animalId));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Kept rather than overwritten: `paused` and `hidden` both arrive for one
        // trip to the background, and resetting the mark on the second would hide
        // how long the app was actually away.
        _leftAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final left = _leftAt;
        _leftAt = null;
        if (left == null) return;
        if (!ref.read(hasPinProvider)) return;
        if (DateTime.now().difference(left) <
            ref.read(lockGracePeriodProvider)) {
          return;
        }
        // The router watches this flag and sends the app to the gate, so the
        // screen that was open is not left readable underneath a dialog.
        ref.read(lockGateProvider.notifier).relock();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watched rather than read: unlocking is what makes a pending tap
    // answerable, and the gate flips the flag without the route changing.
    ref.listen<bool>(lockGateProvider, (previous, next) {
      if (next) _openTappedAnimal(ref.read(pendingAnimalTapProvider));
    });
    final router = ref.watch(routerProvider);
    _router = router;

    return MaterialApp.router(
      title: 'Salala',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
    );
  }
}
