import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../../services/reminder_resync.dart';
import '../providers/app_providers.dart';
import '../widgets/animal_card.dart';
import '../widgets/salala_nav_bar.dart';

class AnimalListScreen extends ConsumerStatefulWidget {
  const AnimalListScreen({super.key});

  @override
  ConsumerState<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends ConsumerState<AnimalListScreen> {
  @override
  void initState() {
    super.initState();
    // After the frame, not inside it: the rebuild talks to the platform, and
    // the ledger must not wait on an alarm manager to show a breeder their dogs.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resyncReminders());
  }

  Future<void> _resyncReminders() async {
    // Mounted first, so a screen that went away before its own callback leaves
    // the one-shot unclaimed for whichever list screen comes next.
    if (!mounted) return;
    if (!ref.read(remindersResyncProvider.notifier).claim()) return;
    final localeTag = Localizations.localeOf(context).toString();
    try {
      await resyncReminders(
        ref.read(reminderSchedulerProvider),
        daos: ref.read(daosProvider),
        l10n: AppLocalizations.of(context),
        dueDayText: (ms) => formatDayFor(localeTag, ms),
      );
    } catch (error) {
      // Same bargain `main()` strikes with the bootstrap: a phone that refuses
      // notifications still opens the ledger, and the failure leaves a trace.
      debugPrint('Reminder resync failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final animals = ref.watch(animalsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAnimals)),
      bottomNavigationBar: const SalalaNavBar(index: 0),
      // The empty herd carries its own "Add animal" button in the middle of the
      // screen; a second affordance for the same action at the thumb corner only
      // competes with it.
      floatingActionButton: (animals.value?.isNotEmpty ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppPaths.newAnimal),
              icon: const Icon(Icons.add),
              label: Text(l10n.homeAddAnimal),
            )
          : null,
      body: animals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorBody(
          onRetry: () => ref.read(animalsProvider.notifier).refresh(),
        ),
        data: (list) => list.isEmpty ? const _EmptyBody() : _AnimalGroups(list),
      ),
    );
  }
}

class _AnimalGroups extends StatelessWidget {
  const _AnimalGroups(this.animals);

  final List<Animal> animals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final breeding = animals.where((a) => a.isBreedingStock).toList();
    final others = animals.where((a) => !a.isBreedingStock).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      children: <Widget>[
        if (breeding.isNotEmpty) ...<Widget>[
          _SectionHeader(l10n.homeBreedingStock),
          for (final animal in breeding) AnimalCard(animal: animal),
        ],
        if (others.isNotEmpty) ...<Widget>[
          _SectionHeader(l10n.homeAllAnimals),
          for (final animal in others) AnimalCard(animal: animal),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.pets_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.homeEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.homeEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(AppPaths.newAnimal),
              icon: const Icon(Icons.add),
              label: Text(l10n.homeAddAnimal),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
        ],
      ),
    );
  }
}
