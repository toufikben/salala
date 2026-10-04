import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/db/daos.dart';
import '../../data/db/settings_dao.dart';
import '../../data/models/animal.dart';
import '../../services/app_lock_service.dart';

/// The opened database. `main()` overrides this after `ensureInitialized`, and
/// tests override it with a temporary file database — which is why nothing here
/// reaches for `getDatabasesPath()` itself.
final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final daosProvider = Provider<Daos>((ref) => Daos(ref.watch(databaseProvider)));

final settingsDaoProvider = Provider<SettingsDao>(
  (ref) => SettingsDao(ref.watch(databaseProvider)),
);

final appLockProvider = Provider<AppLockService>((ref) => AppLockService());

/// True once the PIN gate has been satisfied (or never armed). The router
/// redirects on this, so it is a synchronous flag, not the async digest check.
class LockGate extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;

  void relock() => state = false;
}

final lockGateProvider = NotifierProvider<LockGate, bool>(LockGate.new);

/// Whether a PIN digest exists on this device. `main()` reads the keystore once
/// at startup and seeds this, so the router redirect stays synchronous.
class HasPin extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final hasPinProvider = NotifierProvider<HasPin, bool>(HasPin.new);

/// `main()` overrides this with the value stored in `user_settings`, so the
/// chosen language survives a restart without a loading flash.
final initialLocaleProvider = Provider<Locale?>((ref) => null);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => ref.watch(initialLocaleProvider);

  Future<void> select(Locale? locale) async {
    state = locale;
    await ref
        .read(settingsDaoProvider)
        .write(SettingKeys.languageCode, locale?.languageCode ?? 'system');
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class AnimalsController extends AsyncNotifier<List<Animal>> {
  @override
  Future<List<Animal>> build() => ref.read(daosProvider).animals.findAll();

  Future<Animal> create(Animal animal) async {
    final daos = ref.read(daosProvider);
    final created = await daos.animals.create(animal);
    await refresh();
    return created;
  }

  /// Named `edit`, not `update`: Riverpod 3's AsyncNotifier already owns
  /// `update()` as an state-modifier method.
  Future<void> edit(Animal animal) async {
    await ref.read(daosProvider).animals.update(animal);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(daosProvider).animals.delete(id);
    await refresh();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final animalsProvider = AsyncNotifierProvider<AnimalsController, List<Animal>>(
  AnimalsController.new,
);
