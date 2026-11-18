import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/build_info.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../data/db/settings_dao.dart';
import '../../data/models/photo.dart';
import '../../services/csv_export.dart';
import '../../services/data_pack.dart';
import '../../services/pack_archive.dart';
import '../../services/pack_files.dart';
import '../../services/photo_files.dart';
import '../../services/reminder_resync.dart';
import '../../services/trial.dart';
import '../providers/agenda_providers.dart';
import '../providers/app_providers.dart';
import '../widgets/pin_dialogs.dart';
import '../widgets/salala_nav_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      bottomNavigationBar: const SalalaNavBar(index: 3),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          const _AppLockTile(),
          const _ChangePinTile(),
          const _LanguageTile(),
          const Divider(height: 32),
          const _PackTiles(),
          // Dormant until the app sells something: a free install never sees the
          // word "trial", and the row that counts down is the one place that
          // would otherwise nag a breeder who owes nothing.
          if (kBillingEnabled) const _TrialTile(),
          const Divider(height: 32),
          const _CsvTiles(),
          const Divider(height: 32),
          const _HelpTiles(),
          const Divider(height: 32),
          const _AboutTiles(),
          // Only a CI build carries a tag, so this row is the device-side proof
          // that the APK on the phone is the one just verified.
          if (buildTag.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.tag),
              title: Text(l10n.settingsBuildTag),
              subtitle: Text(buildTag),
            ),
        ],
      ),
    );
  }
}

class _AppLockTile extends ConsumerWidget {
  const _AppLockTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return SwitchListTile(
      value: ref.watch(hasPinProvider),
      title: Text(l10n.settingsAppLock),
      onChanged: (enable) async {
        final lock = ref.read(appLockProvider);
        final messenger = ScaffoldMessenger.of(context);
        try {
          if (enable) {
            final pin = await showPinSetupDialog(context);
            if (pin == null) return;
            await lock.enable(pin);
          } else {
            if (!await askCurrentPin(context, ref)) return;
            await lock.disable();
          }
        } catch (error) {
          // The keystore said no. Without this the exception leaves the async
          // handler mid-flight: the switch snaps back and nothing tells the
          // breeder the phone refused, so they tap a second time and read the
          // tile as broken. `disable()` removes the digest before the salt, so
          // a refusal here cannot have left an unlockable lock behind.
          debugPrint('App lock change refused: $error');
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.lockChangeFailed)),
          );
          return;
        }
        ref.read(hasPinProvider.notifier).set(enable);
      },
    );
  }
}

/// Changing the PIN, which is the one lock action that needs both digits and a
/// new pair: current first, so a phone left unlocked on a table cannot be
/// re-keyed by whoever picks it up.
///
/// Only shown once a PIN exists. Turning the lock on and off is the switch above;
/// this row is what makes the PIN a setting rather than a life sentence.
class _ChangePinTile extends ConsumerWidget {
  const _ChangePinTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (!ref.watch(hasPinProvider)) return const SizedBox.shrink();

    return ListTile(
      leading: const Icon(Icons.password_outlined),
      title: Text(l10n.settingsChangePin),
      subtitle: Text(l10n.settingsChangePinBody),
      onTap: () async {
        if (!await askCurrentPin(context, ref)) return;
        if (!context.mounted) return;
        final pin = await showPinSetupDialog(context);
        if (pin == null) return;
        if (!context.mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        try {
          // `enable` writes the same salt-and-digest pair the switch does, with a
          // fresh salt, so the old PIN stops matching the moment this lands.
          await ref.read(appLockProvider).enable(pin);
        } catch (error) {
          debugPrint('PIN change refused: $error');
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.lockChangeFailed)),
          );
          return;
        }
        messenger.showSnackBar(SnackBar(content: Text(l10n.lockChangePinDone)));
      },
    );
  }
}

/// Language names stay in their own script: "العربية" is what an Arabic reader
/// recognises, not "Arabic".
///
/// A `DropdownButton` in a tile's trailing slot announces the whole row as one
/// button while only the narrow trailing part reacts to a tap — on the phone a
/// tap on the "Language" label did nothing at all. The row is now the control.
class _LanguageTile extends ConsumerStatefulWidget {
  const _LanguageTile();

  @override
  ConsumerState<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends ConsumerState<_LanguageTile> {
  /// The languages the app ships, read off the generated delegate rather than
  /// typed here: a new `.arb` file is a new language, and a list written by hand
  /// is a second place to forget. `system` is the only entry this app adds.
  static final List<String> _codes = <String>[
    'system',
    for (final locale in AppLocalizations.supportedLocales) locale.languageCode,
  ];

  final MenuController _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider);
    final selected = current?.languageCode ?? 'system';

    return MenuAnchor(
      controller: _menu,
      alignmentOffset: const Offset(0, 8),
      menuChildren: <Widget>[
        for (final code in _codes)
          MenuItemButton(
            onPressed: () async {
              // Captured before the await, and the choice is only shown once the
              // row is stored — `select` writes first now, so a refusal leaves
              // the app in the language it was in, and this is the sentence that
              // says why the tap appeared to do nothing.
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(localeControllerProvider.notifier)
                    .select(code == 'system' ? null : Locale(code));
              } catch (error) {
                debugPrint('Language choice refused: $error');
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.languageNotStored)),
                );
              }
            },
            child: Text(_endonym(code, l10n)),
          ),
      ],
      child: ListTile(
        leading: const Icon(Icons.translate),
        title: Text(l10n.settingsLanguage),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_endonym(selected, l10n)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
        onTap: _menu.open,
      ),
    );
  }

  /// Each language names itself, and the name lives in that language's own
  /// `.arb` file — so adding a language is one file and nothing here. Written as
  /// a `switch` it was a second list to keep in step, and a fifth `.arb` file
  /// shipped a language the menu called "System default".
  String _endonym(String code, AppLocalizations l10n) => code == 'system'
      ? l10n.settingsLanguageSystem
      : lookupAppLocalizations(Locale(code)).languageName;
}

/// The transfer pack (Stage 2): every record on this phone out as one JSON file,
/// and back.
///
/// Export leaves the phone only through the breeder's own hands — the system
/// share sheet, no account, nothing uploaded — which is the whole promise of an
/// offline app: the backup is theirs, not ours.
///
/// Import is the dangerous direction, so it names the counts it is about to
/// destroy and asks before it wipes anything.
class _PackTiles extends ConsumerWidget {
  const _PackTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.ios_share),
          title: Text(l10n.settingsExport),
          subtitle: Text(l10n.settingsExportBody),
          onTap: () => _exportPack(context, ref),
        ),
        const _LastBackupRow(),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: Text(l10n.settingsImport),
          subtitle: Text(l10n.settingsImportBody),
          onTap: () => _importPack(context, ref),
        ),
      ],
    );
  }
}

/// How old the only copy of this ledger is.
///
/// A backup the breeder cannot date is a backup they assume is recent. The row
/// is deliberately quiet — it is a fact, not a warning — and it reads the value
/// out of the settings table rather than from the last export this session,
/// because "eight months ago" survives a reinstall and a session does not.
class _LastBackupRow extends ConsumerWidget {
  const _LastBackupRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final last = ref.watch(lastBackupProvider).value;
    final localeTag = Localizations.localeOf(context).toString();

    return ListTile(
      dense: true,
      leading: const Icon(Icons.history),
      title: Text(
        last == null
            ? l10n.settingsNeverBackedUp
            : l10n.settingsLastBackup(
                formatDayFor(localeTag, last.millisecondsSinceEpoch),
              ),
      ),
    );
  }
}

/// The ledger as four spreadsheets, one tap each.
///
/// Separate from the pack on purpose. The pack is the whole ledger with its
/// pictures, restored whole; a CSV is one table a person other than the app is
/// going to read — the accountant, a registry office, a co-owner — and each of
/// those wants one table, not five.
class _CsvTiles extends ConsumerWidget {
  const _CsvTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ExpansionTile(
      leading: const Icon(Icons.grid_on),
      title: Text(l10n.settingsCsv),
      subtitle: Text(l10n.settingsCsvBody),
      children: <Widget>[
        for (final table in _CsvTable.values)
          ListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: 56,
              end: 24,
            ),
            title: Text(_label(l10n, table)),
            onTap: () => _exportCsv(context, ref, table),
          ),
      ],
    );
  }

  static String _label(AppLocalizations l10n, _CsvTable table) =>
      switch (table) {
        _CsvTable.herd => l10n.settingsCsvHerd,
        _CsvTable.litters => l10n.settingsCsvLitters,
        _CsvTable.vaccinations => l10n.settingsCsvVaccinations,
        _CsvTable.placements => l10n.settingsCsvPlacements,
      };
}

enum _CsvTable { herd, litters, vaccinations, placements }

Future<void> _exportCsv(
  BuildContext context,
  WidgetRef ref,
  _CsvTable table,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final daos = ref.read(daosProvider);

  try {
    // Read from the database, not from the lists on screen: a settings screen
    // opened cold has watched nothing, and an export that silently depended on
    // which tab was visited first would produce a short file nobody suspects.
    final animals = await daos.animals.all();
    final String text;
    switch (table) {
      case _CsvTable.herd:
        text = herdCsv(animals, l10n);
      case _CsvTable.litters:
        text = littersCsv(await daos.litters.all(), animals, l10n);
      case _CsvTable.vaccinations:
        text = vaccinationsCsv(await daos.vaccinations.all(), animals, l10n);
      case _CsvTable.placements:
        text = placementsCsv(
          await daos.placements.all(),
          animals,
          await daos.buyers.all(),
          l10n,
        );
    }
    if (animals.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvEmpty)));
      return;
    }
    final name = await ref
        .read(packFilesProvider)
        .shareBytes(
          csvFileName(table.name, DateTime.now()),
          // UTF-8 bytes, and the BOM is the first character of the string: a
          // CSV is text, but the file on disk is bytes, and encoding here is
          // what keeps the mark in front of the first field rather than after it.
          utf8.encode(text),
        );
    messenger.showSnackBar(SnackBar(content: Text(l10n.csvShared(name))));
  } catch (error) {
    debugPrint('CSV export failed: $error');
    messenger.showSnackBar(SnackBar(content: Text(l10n.csvShareFailed)));
  }
}

Future<void> _exportPack(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  try {
    // One file, and it carries the pictures too: a restore on a new phone gets
    // the ledger and the images the rows name, which the JSON-only pack could
    // not promise.
    final bytes = await buildPackArchive(
      ref.read(databaseProvider),
      ref.read(photoFilesProvider),
    );
    final name = await ref
        .read(packFilesProvider)
        .shareBytes(packFileName(DateTime.now()), bytes);
    // Only after the sheet actually took the file: a share that threw is a
    // backup that did not happen, and stamping the day anyway would turn the
    // one honest row on this screen into a claim the breeder cannot check.
    await ref
        .read(settingsDaoProvider)
        .write(
          SettingKeys.lastPackExportedAt,
          '${DateTime.now().millisecondsSinceEpoch}',
        );
    ref.invalidate(lastBackupProvider);
    messenger.showSnackBar(SnackBar(content: Text(l10n.packShared(name))));
  } catch (error) {
    // A phone that refuses the share sheet still shows the ledger; the failure
    // leaves a trace instead of a spinner.
    debugPrint('Pack export failed: $error');
    messenger.showSnackBar(SnackBar(content: Text(l10n.packShareFailed)));
  }
}

Future<void> _importPack(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final localeTag = Localizations.localeOf(context).toString();
  final messenger = ScaffoldMessenger.of(context);
  final db = ref.read(databaseProvider);
  final files = ref.read(packFilesProvider);
  final photoFiles = ref.read(photoFilesProvider);

  final PickedPackFile? chosen;
  try {
    chosen = await files.pick();
  } catch (error) {
    debugPrint('Pack file could not be opened: $error');
    messenger.showSnackBar(SnackBar(content: Text(l10n.packReadFailed)));
    return;
  }
  // Backing out of the file picker is the breeder's own decision, not a fault,
  // so it ends here without a message.
  if (chosen == null) return;

  // Two containers, one reader: a ZIP carries `pack.json` and the pictures, and
  // a plain JSON file is a pack from a version that predates them. The shape is
  // decided by the bytes, not by the name — a renamed file still restores.
  final PackArchive? archive;
  final String json;
  try {
    if (isZipBytes(chosen.bytes)) {
      archive = decodePackArchive(chosen.bytes);
      json = archive.json;
    } else {
      archive = null;
      json = utf8.decode(chosen.bytes);
    }
  } on PackReject catch (reject) {
    messenger.showSnackBar(SnackBar(content: Text(_whyRejected(l10n, reject))));
    return;
  } on FormatException {
    messenger.showSnackBar(SnackBar(content: Text(l10n.packNotAPack)));
    return;
  }

  final PackRows pack;
  try {
    pack = parsePack(json);
  } on PackReject catch (reject) {
    messenger.showSnackBar(SnackBar(content: Text(_whyRejected(l10n, reject))));
    return;
  }

  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.packRestoreTitle),
      content: Text(
        l10n.packRestoreBody(
          pack.countOf('animals'),
          pack.totalRows,
          formatDayFor(localeTag, pack.exportedAtMs),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.actionReplace),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  // The pictures are written before the rows, and each one is remembered so a
  // failed restore can take them back out. Rows that name files nobody wrote
  // would be a ledger claiming pictures it does not hold; files with no rows are
  // only strays, and strays are what the sweep below removes.
  final written = <String>[];
  for (final entry
      in archive?.photos.entries ?? const <MapEntry<String, List<int>>>[]) {
    final split = entry.key.indexOf('/');
    if (split <= 0) continue;
    final folder = entry.key.substring(0, split);
    final fileName = entry.key.substring(split + 1);
    try {
      await photoFiles.restore(folder, fileName, entry.value);
      written.add(entry.key);
    } on PhotoRefused catch (refused) {
      // One unusable picture is not a reason to refuse the ledger: the row comes
      // back and renders as the named blank this app already shows for bytes a
      // phone does not have.
      debugPrint('Pack picture ${entry.key} refused: $refused');
    } catch (error) {
      debugPrint('Pack picture ${entry.key} could not be written: $error');
    }
  }

  final List<Photo> survivors;
  try {
    survivors = await restorePack(db, pack);
  } catch (error) {
    // The transaction is what failed, so the rows that were here are still here
    // and the message can say so out loud. The pictures written above belong to
    // the restore that did not happen, so they go too.
    debugPrint('Pack restore failed: $error');
    for (final path in written) {
      final split = path.indexOf('/');
      try {
        await photoFiles.delete(
          path.substring(0, split),
          path.substring(split + 1),
        );
      } catch (cleanup) {
        debugPrint('Pack picture $path survived a failed restore: $cleanup');
      }
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.packRestoreFailed)));
    return;
  }

  // The phone holds a different ledger now. Two things were derived from the
  // rows that used to be here — the lists on screen and the alarms booked off
  // them — and nothing on screen would tell the breeder that either moved.
  try {
    final scheduler = ref.read(reminderSchedulerProvider);
    // The alarms the rows that used to be here booked are not in the new ledger,
    // and nothing on this phone names them any more: a dose of an animal the pack
    // did not carry would still wake the breeder at nine in the morning. So the
    // phone is emptied first, and the rebuild books only what is now on it.
    await scheduler.clearEverything();
    await resyncReminders(
      scheduler,
      daos: ref.read(daosProvider),
      l10n: l10n,
      dueDayText: (ms) => formatDayFor(localeTag, ms),
    );
  } catch (error) {
    // The records are back; that is the win. A phone that refuses alarms must
    // not be reported as a failed restore.
    debugPrint('Reminder resync after a restore failed: $error');
  }
  // The folder on this phone has to match the rows that survived: a pack can
  // name animals this phone never had, and the pictures of those animals are
  // bytes D10 promised nobody else would ever hold. The rows the restore left
  // standing — the pack's own when it carried pictures, this phone's own when it
  // did not — are the only honest answer to which files still belong here.
  try {
    final kept = <String, Set<String>>{};
    for (final photo in survivors) {
      kept.putIfAbsent(photo.animalId, () => <String>{}).add(photo.fileName);
    }
    await photoFiles.deleteUnbacked(kept);
  } catch (error) {
    // The ledger is restored; a folder this phone will not clear is said to the
    // log, not to the breeder, who has nothing to do about it.
    debugPrint('Photo sweep after a restore failed: $error');
  }
  await ref.read(animalsProvider.notifier).refresh();
  await ref.read(littersProvider.notifier).refresh();
  // The pack carried the *other* phone's backup habit in its settings rows. This
  // phone has never exported anything, and a freshness row inherited from
  // someone else's habit is a claim about this device that is simply false.
  try {
    await ref.read(settingsDaoProvider).remove(SettingKeys.lastPackExportedAt);
    ref.invalidate(lastBackupProvider);
  } catch (error) {
    debugPrint('Backup stamp could not be cleared after a restore: $error');
  }
  // The herd agenda on the home screen is the third thing derived from these
  // rows, and the only one that is a plain read rather than a controller: it has
  // no `refresh()` to call, so the restore asks for it by name.
  ref.invalidate(agendaDosesProvider);
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.packRestored(pack.totalRows))),
  );
}

String _whyRejected(AppLocalizations l10n, PackReject reject) =>
    switch (reject.problem) {
      PackProblem.fromTheFuture => l10n.packFromTheFuture,
      PackProblem.missingTable => l10n.packIncomplete(reject.detail),
      PackProblem.unknownTable => l10n.packUnknownTable(reject.detail),
      // Reachable only from inside the transaction, and the restore catch below
      // already says the sentence that fits: nothing on this phone moved.
      PackProblem.danglingReference => l10n.packRestoreFailed,
      PackProblem.unreadable || PackProblem.notAPack => l10n.packNotAPack,
    };

/// The four pages a breeder reads once and the two rows that ask the store for
/// something.
///
/// One group rather than five dividers: they are all "the app talking about
/// itself", and a settings screen whose rows are separated by a rule every two
/// lines stops reading as groups at all.
class _HelpTiles extends ConsumerWidget {
  const _HelpTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: Text(l10n.settingsHelp),
          onTap: () => context.push(AppPaths.help),
        ),
        ListTile(
          leading: const Icon(Icons.auto_stories_outlined),
          title: Text(l10n.settingsOnboarding),
          onTap: () => context.push(
            // `from` sends Done back here rather than to the herd: a breeder who
            // reopened the slides from Settings was not starting over.
            '${AppPaths.onboarding}?from=${Uri.encodeComponent(AppPaths.settings)}',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.new_releases_outlined),
          title: Text(l10n.settingsWhatsNew),
          onTap: () => context.push(AppPaths.whatsNew),
        ),
        ListTile(
          leading: const Icon(Icons.insights_outlined),
          title: Text(l10n.settingsStats),
          onTap: () => context.push(AppPaths.stats),
        ),
        const _RateTile(),
      ],
    );
  }
}

/// The rating row, which is a fallback rather than a nag.
///
/// No timing heuristic, no "are you enjoying the app?" pre-question and no
/// counter of saves: Android already rate-limits its own card, and an app that
/// decides when to ask is an app that has decided to interrupt. The row waits to
/// be tapped, and says so when the phone has no card to give.
class _RateTile extends ConsumerStatefulWidget {
  const _RateTile();

  @override
  ConsumerState<_RateTile> createState() => _RateTileState();
}

class _RateTileState extends ConsumerState<_RateTile> {
  /// The tap is a channel call, and a double tap on a slow phone would ask twice.
  bool _asking = false;

  Future<void> _rate() async {
    if (_asking) return;
    setState(() => _asking = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final shown = await ref.read(reviewServiceProvider).request();
      // The store page was opened instead, which is still what the breeder
      // asked for — so the only outcome worth a sentence is the one where
      // neither happened.
      if (!shown && !mounted) return;
    } catch (error) {
      debugPrint('Rating row failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(l10n.rateUnavailable)));
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      leading: const Icon(Icons.star_outline),
      title: Text(l10n.settingsRate),
      subtitle: Text(l10n.settingsRateBody),
      trailing: _asking
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _asking ? null : _rate,
    );
  }
}

/// About, privacy, terms — and the one honest sentence about the whole app,
/// which now sits on the page that has room for it.
/// The trial, stated rather than sold.
///
/// Only rendered when `kBillingEnabled` is true, so the row itself is the switch:
/// a free build shows nothing, and the day billing is turned on the count appears
/// without a single other change. It is a `FutureProvider` because the start day
/// is a database row, and the row is deliberately not a countdown — a clock
/// ticking on a settings screen is a pressure nobody asked for.
final trialStateProvider = FutureProvider.autoDispose<TrialState>((ref) {
  return TrialService(settings: ref.watch(settingsDaoProvider)).state();
});

class _TrialTile extends ConsumerWidget {
  const _TrialTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(trialStateProvider).value;

    return ListTile(
      leading: const Icon(Icons.hourglass_bottom),
      title: Text(l10n.settingsTrial),
      subtitle: Text(
        state == null
            ? ''
            : state.expired
            ? l10n.settingsTrialOver
            : l10n.settingsTrialRemaining('${state.daysLeft}'),
      ),
    );
  }
}

class _AboutTiles extends StatelessWidget {
  const _AboutTiles();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.workspace_premium_outlined),
          title: Text(l10n.settingsAbout),
          subtitle: Text(l10n.settingsOfflineNote),
          onTap: () => context.push(AppPaths.about),
        ),
        ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: Text(l10n.settingsPrivacy),
          onTap: () => context.push(AppPaths.privacy),
        ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(l10n.settingsTerms),
          onTap: () => context.push(AppPaths.terms),
        ),
      ],
    );
  }
}
