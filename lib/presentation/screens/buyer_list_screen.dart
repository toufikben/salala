import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../data/models/animal.dart';
import '../../data/models/buyer.dart';
import '../../data/models/placement.dart';
import '../providers/app_providers.dart';
import '../providers/record_providers.dart';
import '../widgets/buyer_dialog.dart';
import '../widgets/companion_nav_bar.dart';

/// The people on the other side of the ledger.
///
/// A contact list has to be its own screen rather than a dropdown inside the
/// handover form, because the questions a breeder asks about it are not about one
/// animal: *who still owes me*, *what did I sell this person*, *this phone number
/// is dead, which dogs did they take*. The dropdown can only answer "choose one",
/// and a contact and their animals were reachable only by opening the animal
/// first — which is backwards for the one list a breeder keeps outside the app.
///
/// Deleting a person from here keeps the handover, exactly as the dialog that
/// confirms it says: the sale is the breeder's record, the name belonged to the
/// buyer.
class BuyerListScreen extends ConsumerWidget {
  const BuyerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final buyers = ref.watch(buyersProvider);
    final animals = ref.watch(animalsProvider).value ?? const <Animal>[];
    final placements =
        ref.watch(placementsProvider).value ?? const <Placement>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navBuyers)),
      bottomNavigationBar: const CompanionNavBar(index: 2),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.buyerAdd),
      ),
      body: buyers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(buyersProvider),
            child: Text(l10n.actionRetry),
          ),
        ),
        data: (list) => list.isEmpty
            ? _EmptyBody(onAdd: () => _edit(context, null))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) => _BuyerCard(
                  buyer: list[index],
                  animals: animals,
                  placements: placements,
                  onTap: () => _edit(context, list[index]),
                ),
              ),
      ),
    );
  }

  /// The dialog writes the row itself and invalidates both lists that read it —
  /// the contact list on screen, and the herd search, which matches on the
  /// buyer's name and would otherwise keep a name that was just corrected.
  Future<void> _edit(BuildContext context, Buyer? existing) async {
    await showBuyerDialog(context, existing: existing);
  }
}

/// One contact, with what this ledger says they took.
class _BuyerCard extends StatelessWidget {
  const _BuyerCard({
    required this.buyer,
    required this.animals,
    required this.placements,
    required this.onTap,
  });

  final Buyer buyer;
  final List<Animal> animals;
  final List<Placement> placements;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final taken = placements.where((p) => p.buyerId == buyer.id).toList()
      ..sort((a, b) => (b.placedDate ?? 0).compareTo(a.placedDate ?? 0));
    final names = <String>[
      for (final placement in taken)
        if (animalById(animals, placement.animalId)?.name
            case final String name)
          name,
    ];

    final contact = <String?>[
      buyer.phone,
      buyer.email,
      buyer.countryCode,
    ].whereType<String>().where((line) => line.trim().isNotEmpty).join(' · ');

    // Who they are first, what they took second: a breeder looking for a phone
    // number should not have to read past a list of dogs to find it.
    final subtitle = <String>[
      if (contact.isNotEmpty) contact,
      if (names.isEmpty) l10n.buyersNoAnimals else names.join(', '),
    ].join('\n');

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            buyer.name.isEmpty ? '?' : buyer.name.substring(0, 1).toUpperCase(),
          ),
        ),
        title: Text(buyer.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.people_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.buyersEmptyTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.buyersEmptyBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt),
              label: Text(l10n.buyerAdd),
            ),
          ],
        ),
      ),
    );
  }
}
