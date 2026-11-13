import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    return MaterialApp.router(
      title: 'Salala',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
    );
  }
}
