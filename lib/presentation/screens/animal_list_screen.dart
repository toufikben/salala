import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/triage_labels.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/agenda.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/herd_search.dart';
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
  /// What is in the search box, kept here and nowhere else.
  ///
  /// The herd is already in memory for the list, so a query filters that list
  /// instead of asking the database for a second one — the same reason the agenda
  /// is passed down as a value (D27). It stays in the screen rather than a
  /// provider because leaving the screen and coming back should show the whole
  /// herd again, not the last word typed three days ago.
  String _query = '';

  /// Owns the typed text so the clear button can empty the box as well as the
  /// list below it.
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // After the frame, not inside it: the rebuild talks to the platform, and
    // the ledger must not wait on an alarm manager to show a breeder their dogs.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resyncReminders());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
    // Read here, once per rebuild: the field, the list under it and the agenda
    // all answer to one decision about the typed text, and `queryFilters` is the
    // only place that makes it. The raw text is what the list is handed, because
    // the filter normalises it again for matching and the no-match message has to
    // print back what was actually typed.
    final String query = _query;
    final bool filtering = queryFilters(query);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navAnimals),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              // Nothing to navigate to: the answer is the list already on screen,
              // so the keyboard's own button only closes itself.
              textInputAction: TextInputAction.done,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.homeSearchHint,
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filtering
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const SalalaNavBar(index: 0),
      // The empty herd carries its own "Add animal" button in the middle of the
      // screen; a second affordance for the same action at the thumb corner only
      // competes with it. During a search there is no such middle button, and
      // "nothing matches" plus this FAB is the app saying: register that one.
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
        data: (list) {
          if (list.isEmpty) return const _EmptyBody();
          final matches = searchHerd(list, query);
          if (matches.isEmpty) return _NoMatches(query: query);
          return _AnimalGroups(
            animals: matches,
            // The agenda answers for the herd (D28), not for the matches, and
            // showing the whole herd's to-do list above a filtered handful of
            // cards reads as if those animals were the ones with the doses due.
            showAgenda: !filtering,
            // The two sections exist to give shape to everything a breeder owns.
            // A search is not asking that question — it asked which one, and the
            // answer has an order. Splitting the matches by breeding stock would
            // put a dog that matched on a word in its note above the dog whose
            // name was typed in full, because the breeding block is printed
            // first whatever the ranking said.
            grouped: !filtering,
            agenda: ref.watch(agendaDosesProvider),
            onAgendaRetry: () => ref.invalidate(agendaDosesProvider),
          );
        },
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
    required this.showAgenda,
    required this.grouped,
    required this.agenda,
    required this.onAgendaRetry,
  });

  final List<Animal> animals;
  final bool showAgenda;
  final bool grouped;
  final AsyncValue<List<Vaccination>> agenda;
  final VoidCallback onAgendaRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!grouped) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
        children: <Widget>[
          for (final animal in animals) AnimalCard(animal: animal),
        ],
      );
    }

    final breeding = animals.where((a) => a.isBreedingStock).toList();
    final others = animals.where((a) => !a.isBreedingStock).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      children: <Widget>[
        if (showAgenda)
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
              // A zero is a day, not a rounding artifact: the dose is due today,
              // and saying "0 days" would read as a count gone wrong.
              subtitle: Text(
                item.days == 0
                    ? l10n.reminderDueBody(item.vaccineName)
                    : item.overdue
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

/// Nothing in the herd answers that query.
///
/// The word is printed back: "no results" on its own cannot be told apart from a
/// typo the breeder has already forgotten typing, and the letter an Arabic
/// keyboard put in the wrong place is invisible until it is quoted.
class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.query});

  final String query;

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
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(l10n.homeNoMatches(query), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
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
