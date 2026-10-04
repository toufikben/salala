import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/build_info.dart';
import '../../core/l10n/app_localizations.dart';
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
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l10n.settingsExport),
            subtitle: Text(l10n.settingsExportSoon),
          ),
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
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  static const List<String> _codes = <String>['system', 'en', 'ar', 'fr'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider);
    final selected = current?.languageCode ?? 'system';

    return ListTile(
      leading: const Icon(Icons.translate),
      title: Text(l10n.settingsLanguage),
      trailing: DropdownButton<String>(
        value: selected,
        underline: const SizedBox.shrink(),
        items: <DropdownMenuItem<String>>[
          for (final code in _codes)
            DropdownMenuItem<String>(
              value: code,
              child: Text(_endonym(code, l10n)),
            ),
        ],
        onChanged: (code) {
          if (code == null) return;
          ref
              .read(localeControllerProvider.notifier)
              .select(code == 'system' ? null : Locale(code));
        },
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
