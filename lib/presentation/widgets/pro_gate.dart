import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/trial.dart';
import '../providers/billing_providers.dart';
import '../screens/upgrade_screen.dart';

/// Asks the gate, and opens the sheet when the answer is no.
///
/// Every paid call site goes through this one function so the question is always
/// the same and the sentence is always the same. It returns true when the caller
/// may continue; false when the breeder has been shown the sheet and the caller
/// must stop. It never blocks on the store: a build with billing off answers yes
/// without touching Play.
Future<bool> ensurePro(
  BuildContext context,
  WidgetRef ref,
  ProFeature feature,
) async {
  // Answered before any await: a build that sells nothing must not add a
  // database round trip to attaching a contract or opening the gallery. The
  // free path stays exactly as fast as it was before billing existed.
  if (!ref.read(billingEnabledProvider)) return true;
  final access = await ref.read(proAccessProvider.future);
  if (!context.mounted) return false;
  if (access.allows(feature)) return true;
  await showProGate(context, feature);
  return false;
}

/// The sheet, not a page.
///
/// It comes up over the screen the breeder is already using, says one sentence
/// about the feature she just reached for, and leaves. A full screen here would
/// be a wall between her and the record she was writing; a sheet is a note she
/// can put down.
Future<void> showProGate(BuildContext context, ProFeature feature) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _ProGateSheet(feature: feature),
  );
}

class _ProGateSheet extends StatelessWidget {
  const _ProGateSheet({required this.feature});

  final ProFeature feature;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.proGateTitle(featureLabel(l10n, feature)),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.proGateBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                ),
                onPressed: () {
                  // Captured before the sheet closes: pushing from the sheet's own
                  // context after `pop` is pushing from an element that is being
                  // thrown away.
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  // The feature travels as a query parameter so the page can open
                  // on the question she asked rather than on a generic pitch.
                  router.push('${AppPaths.upgrade}?feature=${feature.name}');
                },
                child: Text(l10n.proGateSee),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.upgradeLater),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
