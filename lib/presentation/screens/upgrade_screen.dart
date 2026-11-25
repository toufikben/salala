import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../services/billing.dart';
import '../../services/trial.dart';
import '../providers/billing_providers.dart';

/// The one page that asks for money.
///
/// It is a page rather than a launch-time interstitial for one reason: a breeder
/// opens it because she decided to, and a paywall that appears on its own is a
/// paywall she closes before reading. Exactly two things lead here: the gate on a
/// feature she tapped, and the quiet row in Settings. Nothing pushes this route
/// on launch, on saving a record, or over a reminder.
class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key, this.reason});

  /// The feature that sent her here, so the page can open on the truth instead of
  /// a generic sales pitch. Null when she came from Settings.
  final ProFeature? reason;

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  CompanionPlan _plan = CompanionPlan.pro;
  BillingPeriod _period = BillingPeriod.yearly;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    // Play is asked again every time this page opens: a subscription bought on
    // another phone, or refunded yesterday, has to be reflected before a price is
    // shown next to a feature that may already be unlocked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(entitlementProvider.notifier).refreshFromStore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final offers = ref.watch(storeOffersProvider);
    final access = ref.watch(proAccessProvider).value;
    final paid = access?.paid ?? false;

    // Only plans the store actually holds are offered. A card for a plan that
    // was never created in Play Console is a price that loads forever, and a
    // breeder who taps it has been shown a product that does not exist.
    final listed = offers.value ?? const <StoreOffer>[];
    final plans = offers.isLoading
        ? CompanionPlan.values.toList()
        : CompanionPlan.values
              .where(
                (plan) => listed.any((offer) => offer.product.plan == plan),
              )
              .toList();
    // Read, not written: a build method that assigns state is a frame that
    // schedules another frame.
    final plan = plans.contains(_plan)
        ? _plan
        : (plans.isEmpty ? CompanionPlan.pro : plans.first);

    final selected = kCompanionProducts.firstWhere(
      (product) => product.plan == plan && product.period == _period,
      orElse: () => kCompanionProducts.first,
    );
    final matching = listed.where(
      (candidate) => candidate.product.id == selected.id,
    );
    final price = matching.isEmpty ? null : matching.first.price;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.upgradeTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: <Widget>[
          if (widget.reason != null) ...<Widget>[
            _ReasonBanner(feature: widget.reason!),
            const SizedBox(height: 16),
          ],
          Text(
            l10n.upgradeIntro,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              for (var i = 0; i < plans.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _PlanCard(
                    title: plans[i] == CompanionPlan.pro
                        ? l10n.upgradeProTitle
                        : l10n.upgradeStudioTitle,
                    body: plans[i] == CompanionPlan.pro
                        ? l10n.upgradeProBody
                        : l10n.upgradeStudioBody,
                    selected: plan == plans[i],
                    onTap: () => setState(() => _plan = plans[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _PeriodRow(
            period: _period,
            note: l10n.upgradeYearlyNote,
            monthly: l10n.upgradeMonthly,
            yearly: l10n.upgradeYearly,
            onChanged: (period) => setState(() => _period = period),
          ),
          const SizedBox(height: 20),
          Center(
            child: offers.isLoading
                ? Text(
                    l10n.upgradePriceLoading,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Text(
                    price ?? l10n.upgradePriceLoading,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          if (access != null)
            Center(
              child: Text(
                access.paid
                    ? l10n.upgradeThankYou
                    : access.expired
                    ? l10n.upgradeTrialOver
                    : l10n.upgradeTrialDays(access.trial.daysLeft),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          // Once the subscription is live there is nothing left to sell. Leaving
          // the button enabled would start a second purchase of the plan she
          // already owns, which Play would happily take.
          if (!paid)
            FilledButton(
              onPressed: price == null || _working
                  ? null
                  : () => _buy(selected),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _working
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.upgradeSubscribe),
            ),
          if (!paid) const SizedBox(height: 8),
          if (!paid)
            TextButton(
              onPressed: _working ? null : _restore,
              child: Text(l10n.upgradeRestore),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _working ? null : () => Navigator.of(context).maybePop(),
            child: Text(l10n.upgradeLater),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(StoreProduct product) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _working = true);
    final bought = await ref.read(entitlementProvider.notifier).buy(product);
    if (!mounted) return;
    setState(() => _working = false);
    _say(bought ? l10n.upgradeThankYou : l10n.upgradeFailed);
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _working = true);
    await ref.read(entitlementProvider.notifier).refreshFromStore();
    if (!mounted) return;
    setState(() => _working = false);
    final owned = ref.read(entitlementProvider).value;
    _say(
      owned != null && owned.unlocksEverything
          ? l10n.upgradeRestored
          : l10n.upgradeNothingToRestore,
    );
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The feature that sent her here, named at the top so the page answers the
/// question she actually asked.
class _ReasonBanner extends StatelessWidget {
  const _ReasonBanner({required this.feature});

  final ProFeature feature;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.lock_open_outlined,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.proGateTitle(featureLabel(l10n, feature)),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Turns the `feature=` query parameter into the enum, or null when the page was
/// opened from Settings rather than from a locked feature.
ProFeature? proFeatureFromName(String? name) {
  if (name == null || name.isEmpty) return null;
  for (final feature in ProFeature.values) {
    if (feature.name == name) return feature;
  }
  return null;
}

/// The name of a paid feature, in the reader's language.
String featureLabel(AppLocalizations l10n, ProFeature feature) {
  switch (feature) {
    case ProFeature.unlimitedPhotos:
      return l10n.featurePhotos;
    case ProFeature.reports:
      return l10n.featureReports;
    case ProFeature.contracts:
      return l10n.featureContracts;
    case ProFeature.statistics:
      return l10n.featureStats;
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({
    required this.period,
    required this.note,
    required this.monthly,
    required this.yearly,
    required this.onChanged,
  });

  final BillingPeriod period;
  final String note;
  final String monthly;
  final String yearly;
  final ValueChanged<BillingPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        SegmentedButton<BillingPeriod>(
          segments: <ButtonSegment<BillingPeriod>>[
            ButtonSegment<BillingPeriod>(
              value: BillingPeriod.monthly,
              label: Text(monthly),
            ),
            ButtonSegment<BillingPeriod>(
              value: BillingPeriod.yearly,
              label: Text(yearly),
            ),
          ],
          selected: <BillingPeriod>{period},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
        if (period == BillingPeriod.yearly) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
