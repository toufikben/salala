import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/db/daos.dart';
import '../../data/db/settings_dao.dart';
import '../../data/models/animal.dart';
import '../../data/models/litter.dart';
import '../../services/app_lock_service.dart';
import '../../services/pack_files.dart';
import '../../services/photo_files.dart';
import '../../services/reminder_scheduler.dart';

/// The opened database. `main()` overrides this after `ensureInitialized`, and
/// tests override it with a temporary file database — which is why nothing here
/// reaches for `getDatabasesPath()` itself.
final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

/// The notifier `main()` built and bootstrapped. Overriding matters: scheduling
/// against a second, uninitialised plugin instance throws on the first save,
/// so tests inject a recorder instead of letting the real one be constructed.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) =>
      throw UnimplementedError('reminderSchedulerProvider must be overridden'),
);

/// Whether this launch has already rebuilt the alarms from the ledger.
///
/// The guard cannot live in the screen's own state: the nav bar moves between
/// tabs with `go`, which throws the previous screen away, so every return to
/// the animal list would rebuild the alarms all over again.
class RemindersResynced extends Notifier<bool> {
  @override
  bool build() => false;

  /// True to the first caller of a launch, false to everyone after it.
  bool claim() {
    if (state) return false;
    state = true;
    return true;
  }
}

final remindersResyncProvider = NotifierProvider<RemindersResynced, bool>(
  RemindersResynced.new,
);

final daosProvider = Provider<Daos>((ref) => Daos(ref.watch(databaseProvider)));

final settingsDaoProvider = Provider<SettingsDao>(
  (ref) => SettingsDao(ref.watch(databaseProvider)),
);

final appLockProvider = Provider<AppLockService>((ref) => AppLockService());

/// The share sheet and the file picker. Tests hand in a recorder, because the
/// real one talks to Android.
final packFilesProvider = Provider<PackFiles>((ref) => const SystemPackFiles());

/// The photo folder and the image picker. Same seam for the same reason: the
/// real one talks to Android, so the screens are tested against a recorder.
final photoFilesProvider = Provider<PhotoFiles>(
  (ref) => const SystemPhotoFiles(),
);

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

  /// Stores the choice first, and only then shows it.
  ///
  /// The order is the whole point: setting the state before the write meant a
  /// phone that refused the row still moved the app into the new language, so
  /// the breeder saw Arabic for the day and English the morning after, with
  /// nothing between the two saying the choice had never been kept. This is
  /// D33's rule applied to a setting — a write that did not land is not a
  /// change the screen should display.
  Future<void> select(Locale? locale) async {
    await ref
        .read(settingsDaoProvider)
        .write(SettingKeys.languageCode, locale?.languageCode ?? 'system');
    state = locale;
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
    await _rereadAfter('add');
    return created;
  }

  /// Named `edit`, not `update`: Riverpod 3's AsyncNotifier already owns
  /// `update()` as an state-modifier method.
  Future<void> edit(Animal animal) async {
    await ref.read(daosProvider).animals.update(animal);
    await _rereadAfter('change');
  }

  /// Deleting an animal takes its picture folder with it.
  ///
  /// The foreign key removes the rows; only this app can reach the bytes. A
  /// delete that left them behind would keep a dead animal's photographs on the
  /// phone with no row, no screen and no way to find them again.
  ///
  /// So this clears the folder whether or not any row survived to be counted: the
  /// one state where the ledger says "no pictures" and the folder disagrees is a
  /// copy whose row was refused *and* whose sweep failed, and it is exactly the
  /// photograph that must not outlive the animal. The promise is the folder going,
  /// not the file list being walked.
  Future<void> delete(String id) async {
    final daos = ref.read(daosProvider);
    await daos.animals.delete(id);
    try {
      await ref.read(photoFilesProvider).deleteAll(id);
    } catch (error) {
      debugPrint('Photo folder for deleted animal $id not removed: $error');
    }
    await _rereadAfter('delete');
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// The herd list is a copy of what the ledger already holds, so a list that
  /// refuses to re-read is not the write failing. Every caller catches around
  /// these methods and says "nothing was written" — which is only true of the
  /// statement before this line. A re-read that throws is logged and the row
  /// stays put; the list refreshes again the next time the screen reads it.
  Future<void> _rereadAfter(String what) async {
    try {
      await refresh();
    } catch (error) {
      debugPrint('Herd re-read after $what failed: $error');
    }
  }
}

final animalsProvider = AsyncNotifierProvider<AnimalsController, List<Animal>>(
  AnimalsController.new,
);

class LittersController extends AsyncNotifier<List<Litter>> {
  @override
  Future<List<Litter>> build() => ref.read(daosProvider).litters.recent();

  /// Writes a whelping and its puppies, then refreshes both lists: puppies are
  /// animals, so the home list is stale the moment a litter is registered.
  Future<Litter> register(Litter litter, List<Animal> puppies) async {
    final daos = ref.read(daosProvider);
    final created = await daos.litters.createWithPuppies(litter, puppies);
    await ref.read(animalsProvider.notifier)._rereadAfter('a whelping');
    await _rereadAfter('a whelping');
    return created;
  }

  Future<void> edit(Litter litter) async {
    await ref.read(daosProvider).litters.update(litter);
    await _rereadAfter('a whelping change');
  }

  /// Deleting a litter unlinks its animals (`litter_id ON DELETE SET NULL`), so
  /// the puppies survive as animals and the home list has to be re-read.
  Future<void> delete(String id) async {
    final daos = ref.read(daosProvider);
    await daos.litters.delete(id);
    await ref.read(animalsProvider.notifier)._rereadAfter('a whelping delete');
    await _rereadAfter('a whelping delete');
  }

  /// Same rule as the herd list: `createWithPuppies` is one transaction, so by
  /// the time this runs the whelping and every puppy are already stored. A list
  /// that will not re-read must not be reported as a refused write, or the
  /// breeder registers the same litter a second time.
  Future<void> _rereadAfter(String what) async {
    try {
      await refresh();
    } catch (error) {
      debugPrint('Litter re-read after $what failed: $error');
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final littersProvider = AsyncNotifierProvider<LittersController, List<Litter>>(
  LittersController.new,
);
