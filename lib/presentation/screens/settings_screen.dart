import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/build_info.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../services/data_pack.dart';
import '../../services/reminder_resync.dart';
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
      bottomNavigationBar: const SalalaNavBar(index: 2),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          const _AppLockTile(),
          const _LanguageTile(),
          const Divider(height: 32),
          const _PackTiles(),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l10n.settingsAbout),
            subtitle: Text(l10n.settingsOfflineNote),
          ),
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
        if (enable) {
          final pin = await showPinSetupDialog(context);
          if (pin == null) return;
          await lock.enable(pin);
          ref.read(hasPinProvider.notifier).set(true);
        } else {
          if (!await askCurrentPin(context, ref)) return;
          await lock.disable();
          ref.read(hasPinProvider.notifier).set(false);
        }
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
  static const List<String> _codes = <String>['system', 'en', 'ar', 'fr'];

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
            onPressed: () {
              ref
                  .read(localeControllerProvider.notifier)
                  .select(code == 'system' ? null : Locale(code));
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

  String _endonym(String code, AppLocalizations l10n) => switch (code) {
    'en' => 'English',
    'ar' => 'العربية',
    'fr' => 'Français',
    _ => l10n.settingsLanguageSystem,
  };
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

Future<void> _exportPack(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  try {
    final json = encodePack(await packFrom(ref.read(databaseProvider)));
    final name = await ref
        .read(packFilesProvider)
        .share(json, now: DateTime.now());
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

  final String? text;
  try {
    text = await files.pick();
  } catch (error) {
    debugPrint('Pack file could not be opened: $error');
    messenger.showSnackBar(SnackBar(content: Text(l10n.packReadFailed)));
    return;
  }
  // Backing out of the file picker is the breeder's own decision, not a fault,
  // so it ends here without a message.
  if (text == null) return;

  final PackRows pack;
  try {
    pack = parsePack(text);
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

  try {
    await restorePack(db, pack);
  } catch (error) {
    // The transaction is what failed, so the rows that were here are still here
    // and the message can say so out loud.
    debugPrint('Pack restore failed: $error');
    messenger.showSnackBar(SnackBar(content: Text(l10n.packRestoreFailed)));
    return;
  }

  // The phone holds a different ledger now. Two things were derived from the
  // rows that used to be here — the lists on screen and the alarms booked off
  // them — and nothing on screen would tell the breeder that either moved.
  try {
    await resyncReminders(
      ref.read(reminderSchedulerProvider),
      daos: ref.read(daosProvider),
      l10n: l10n,
      dueDayText: (ms) => formatDayFor(localeTag, ms),
    );
  } catch (error) {
    // The records are back; that is the win. A phone that refuses alarms must
    // not be reported as a failed restore.
    debugPrint('Reminder resync after a restore failed: $error');
  }
  await ref.read(animalsProvider.notifier).refresh();
  await ref.read(littersProvider.notifier).refresh();
  messenger.showSnackBar(
    SnackBar(content: Text(l10n.packRestored(pack.totalRows))),
  );
}

String _whyRejected(AppLocalizations l10n, PackReject reject) =>
    switch (reject.problem) {
      PackProblem.fromTheFuture => l10n.packFromTheFuture,
      PackProblem.missingTable => l10n.packIncomplete(reject.detail),
      PackProblem.unknownTable => l10n.packUnknownTable(reject.detail),
      PackProblem.unreadable || PackProblem.notAPack => l10n.packNotAPack,
    };
