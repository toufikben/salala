import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/triage_labels.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/agenda.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../../data/models/vaccination.dart';
import '../../services/reminder_resync.dart';
import '../providers/agenda_providers.dart';
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
        data: (list) => list.isEmpty
            ? const _EmptyBody()
            : _AnimalGroups(
                animals: list,
                agenda: ref.watch(agendaDosesProvider),
                onAgendaRetry: () => ref.invalidate(agendaDosesProvider),
              ),
      ),
    );
  }
}

/// The herd's open bookings, above the animals.
///
/// The two reads live in the screen's build and travel down as values (D27): the
/// home list is a lazy `ListView`, so a block that ran its own query would start
/// it at the moment the sliver first built the child, in the middle of whatever
/// the finger or the test was already doing.
class _AnimalGroups extends StatelessWidget {
  const _AnimalGroups({
    required this.animals,
    required this.agenda,
    required this.onAgendaRetry,
  });

  final List<Animal> animals;
  final AsyncValue<List<Vaccination>> agenda;
  final VoidCallback onAgendaRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final breeding = animals.where((a) => a.isBreedingStock).toList();
    final others = animals.where((a) => !a.isBreedingStock).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      children: <Widget>[
        _HerdAgenda(animals: animals, agenda: agenda, onRetry: onAgendaRetry),
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

/// Every animal still in the herd that is waiting for a dose, most overdue first.
///
/// One line per animal rather than one per dose: the ledger it opens shows the
/// whole history, and the point of this block is that nothing needs opening.
/// It is also the only place in the app that answers for the herd at all —
/// before it, "what is due this fortnight?" meant tapping every card.
class _HerdAgenda extends StatelessWidget {
  const _HerdAgenda({
    required this.animals,
    required this.agenda,
    required this.onRetry,
  });

  final List<Animal> animals;
  final AsyncValue<List<Vaccination>> agenda;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Nothing on screen while the first read is out — an agenda that has not
    // arrived and a herd with nothing to book look the same for a moment, and a
    // spinner would shove every animal down while it turned. A read that
    // *failed* says so instead of going quiet: an absent to-do list is exactly
    // how a rabies shot stays unscheduled.
    if (agenda.isLoading && !agenda.hasValue) return const SizedBox.shrink();
    if (agenda.hasError) return _AgendaFailure(onRetry: onRetry);

    final items = buildHerdAgenda(
      animals: animals,
      // Loading-with-a-value and data are the only states left, so the value is
      // there; `requireValue` rather than `?const []` because reaching for a
      // default here would turn a broken read back into a silent empty list.
      doses: agenda.requireValue,
      nowMs: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.agendaTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          for (final item in items)
            ListTile(
              dense: true,
              // Overdue is an icon and a colour, not only a colour — the same
              // reason the triage card puts a word beside its red.
              leading: Icon(
                item.overdue ? Icons.error_outline : Icons.event_outlined,
                color: item.overdue
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              title: Text(item.animalName),
              subtitle: Text(
                item.overdue
                    ? l10n.triageDoseOverdue(
                        item.vaccineName,
                        daysPhrase(l10n, item.days),
                      )
                    : l10n.triageDoseDueSoon(
                        item.vaccineName,
                        daysPhrase(l10n, item.days),
                      ),
              ),
              onTap: () => context.push(AppPaths.animal(item.animalId)),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// The agenda's own failure, kept to one line: the herd below it is still
/// readable, and a whole screen of "cloud off" for a to-do block would be a worse
/// lie than the block admitting which read it could not do.
class _AgendaFailure extends StatelessWidget {
  const _AgendaFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        dense: true,
        leading: Icon(Icons.help_outline, color: theme.colorScheme.error),
        title: Text(l10n.agendaTitle),
        trailing: TextButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
      ),
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
