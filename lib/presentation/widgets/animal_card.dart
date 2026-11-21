import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/db/daos.dart';
import '../../data/models/animal.dart';
import '../../data/models/photo.dart';
import '../../services/reminder_resync.dart';
import '../providers/app_providers.dart';
import '../providers/record_providers.dart';
import 'photo_thumb.dart';
import 'record_refusal.dart';

/// One animal, as a photograph with a name on it.
///
/// The card used to be a `ListTile` with an initial in a circle: a row of text
/// with a placeholder where the animal is. A breeder with thirty dogs does not
/// find one by reading thirty names — they recognise the dog, and the name is
/// what they read afterwards to check. So the photograph is the card, the name
/// sits on it, and the facts sit under it.
///
/// What did not change: tapping opens the ledger rather than the form (a breeder
/// tapping a dog wants doses and weights, not a form), the menu still holds edit
/// and delete, and the delete dialog still counts what a dam's removal takes.
class AnimalCard extends ConsumerWidget {
  const AnimalCard({super.key, required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Watched here rather than passed down: the litter screen builds the same
    // card for a puppy, and both screens already hold the whole herd, so the read
    // is one map either way.
    final photo = ref.watch(herdPhotosProvider).value?[animal.id];

    final facts = <String>[
      if (animal.breed != null && animal.breed!.isNotEmpty) animal.breed!,
      sexLabel(l10n, animal.sex),
      if (animal.birthDate != null) formatDay(context, animal.birthDate),
    ].join(' · ');

    return Card(
      child: InkWell(
        onTap: () => context.push(AppPaths.animal(animal.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _CardPhoto(animal: animal, photo: photo),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    // The name is on the photograph, above. What sits here is
                    // what a breeder checks after recognising the dog: breed,
                    // sex, and the day she was born.
                    child: Text(
                      facts.isEmpty ? ' ' : facts,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<_CardAction>(
                    tooltip: l10n.actionEdit,
                    onSelected: (action) => action == _CardAction.delete
                        ? confirmDelete(context, ref, animal)
                        : context.push(AppPaths.editAnimal(animal.id)),
                    itemBuilder: (context) => <PopupMenuEntry<_CardAction>>[
                      PopupMenuItem(
                        value: _CardAction.edit,
                        child: Text(l10n.actionEdit),
                      ),
                      PopupMenuItem(
                        value: _CardAction.delete,
                        child: Text(l10n.actionDelete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The picture, or the shape of one.
///
/// Two overlays carry what a breeder needs before opening anything: the status
/// chips top-start (breeding stock, sold, deceased — never on an active home dog,
/// because a badge that is always there is a badge nobody reads), and the name in
/// large type bottom-start over a scrim, so a light photograph cannot swallow it.
class _CardPhoto extends StatelessWidget {
  const _CardPhoto({required this.animal, required this.photo});

  final Animal animal;
  final Photo? photo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final badges = <Widget>[
      if (animal.isBreedingStock)
        _Badge(label: l10n.homeBreedingStock, tone: _BadgeTone.clay),
      if (animal.status == AnimalStatus.sold)
        _Badge(label: statusLabel(l10n, animal.status), tone: _BadgeTone.ink),
      if (animal.status == AnimalStatus.deceased)
        _Badge(label: statusLabel(l10n, animal.status), tone: _BadgeTone.muted),
      if (animal.status == AnimalStatus.retired)
        _Badge(label: statusLabel(l10n, animal.status), tone: _BadgeTone.muted),
    ];

    return ConstrainedBox(
      // A cap, not the ratio alone: the ratio decides the shape on a phone, but
      // on a tablet — or in a widget test's 800-point window — 16:10 of the full
      // width would be a card taller than the screen it is scrolling on. 220 is
      // one third of a small tablet and still two thirds of a phone's width, so
      // the photograph stays the card without eating the list.
      constraints: const BoxConstraints(maxHeight: 220),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (photo == null)
              _PortraitGap(animal: animal)
            else
              PhotoImage(
                photo: photo!,
                width: double.infinity,
                height: double.infinity,
                radius: 0,
                // A missing file under a row that exists: the animal still has to
                // be recognisable, so the initial comes back as the fallback.
                missing: _PortraitGap(animal: animal),
              ),
            // The scrim exists for the name, not for mood: without it a white dog
            // in sunlight erases the type entirely.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x00000000), Color(0x8A000000)],
                  stops: <double>[0.55, 1],
                ),
              ),
            ),
            if (badges.isNotEmpty)
              PositionedDirectional(
                top: 10,
                start: 10,
                child: Wrap(spacing: 6, children: badges),
              ),
            PositionedDirectional(
              start: 14,
              end: 14,
              bottom: 10,
              child: Text(
                animal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  shadows: const <Shadow>[
                    Shadow(blurRadius: 8, color: Color(0x66000000)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The shape of a picture, for an animal this phone has never photographed.
///
/// The initial, in the palette, on a warm ground: a card with a grey box where
/// the dog should be reads as a broken image, and a card with the animal's letter
/// on it reads as an animal nobody has photographed yet. The tint follows the
/// sex, which is the one attribute a breeder reads off a photo instantly anyway.
class _PortraitGap extends StatelessWidget {
  const _PortraitGap({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ground = switch (animal.sex) {
      Sex.male => scheme.primaryContainer,
      Sex.female => scheme.tertiaryContainer,
      Sex.unknown => scheme.surfaceContainerHigh,
    };
    final ink = switch (animal.sex) {
      Sex.male => scheme.onPrimaryContainer,
      Sex.female => scheme.onTertiaryContainer,
      Sex.unknown => scheme.onSurfaceVariant,
    };
    final initial = animal.name.isEmpty
        ? '?'
        : animal.name.characters.first.toUpperCase();

    return ColoredBox(
      color: ground,
      child: Center(
        child: Text(
          initial,
          style: theme.textTheme.displayMedium?.copyWith(
            color: ink.withValues(alpha: 0.55),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum _BadgeTone { clay, ink, muted }

/// A word on a photograph.
///
/// Solid rather than translucent: white-on-image with no ground fails contrast
/// the moment the photograph behind it is pale, and this is the one place the app
/// states that a dog has died or has been sold.
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tone});

  final String label;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color ground, Color ink) = switch (tone) {
      _BadgeTone.clay => (AppColors.clay, Colors.white),
      _BadgeTone.ink => (scheme.inverseSurface, scheme.onInverseSurface),
      _BadgeTone.muted => (scheme.surfaceContainerHighest, scheme.onSurface),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: ink, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

enum _CardAction { edit, delete }

/// The rows a dam's deletion would take with it, counted before the dialog.
///
/// A failed count is not a reason to refuse a delete the breeder asked for: the
/// dialog falls back to the sentence that names no numbers.
Future<({int litters, int puppies})> _deleteImpact(
  Daos daos,
  String animalId,
) async {
  try {
    final litters = await daos.litters.countForDam(animalId);
    if (litters == 0) return (litters: 0, puppies: 0);
    return (
      litters: litters,
      puppies: await daos.animals.countPuppiesOfDam(animalId),
    );
  } catch (error) {
    debugPrint('Delete impact count failed: $error');
    return (litters: 0, puppies: 0);
  }
}

Future<void> confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Animal animal,
) async {
  final l10n = AppLocalizations.of(context);
  // Read with the localizations, before the dialog is ever shown. This is a
  // `BuildContext` read like the line above it, and asking the same question
  // after an `await` is what `use_build_context_synchronously` exists to catch:
  // the card can be gone by the time the delete answers.
  final localeTag = Localizations.localeOf(context).toString();
  final daos = ref.read(daosProvider);

  // What the cascade actually costs, counted while the rows still exist.
  // `litters.dam_id` is CASCADE and the puppies under it are SET NULL, so a dam's
  // delete takes her whelpings and leaves her puppies behind without a mother on
  // file. Read by the dialog rather than awaited here: the question has to open
  // on the same frame the breeder tapped it.
  final impact = _deleteImpact(daos, animal.id);
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.animalDeleteTitle(animal.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.animalDeleteBody),
          FutureBuilder<({int litters, int puppies})>(
            future: impact,
            builder: (context, snapshot) {
              final counts = snapshot.data;
              if (counts == null || counts.litters == 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.animalDeleteLittersNote(counts.litters, counts.puppies),
                ),
              );
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.actionDelete),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  // The handles the rebuild needs are read before the delete rather than after
  // it: the card can be gone by then, and a disposed widget's `ref` answers
  // nothing.
  final scheduler = ref.read(reminderSchedulerProvider);

  try {
    await ref.read(animalsProvider.notifier).delete(animal.id);
  } catch (error) {
    // The animal is still in the ledger, so its alarms stay booked and none of
    // the rebuild below runs. Saying so out loud is the point: a card that did
    // nothing after a confirmed delete reads as an animal that is gone.
    if (context.mounted) refuseRecordDelete(context, error);
    return;
  }
  ref.invalidate(herdPhotosProvider);

  // The doses and screenings that went with the animal are what the phone's
  // alarms were booked off, and no row left on this device names them: a reminder
  // would still arrive for a dose of an animal the herd no longer has. So the
  // alarms are emptied and rebuilt from what is actually left, which is the same
  // pair of steps a launch and a restore run.
  try {
    await scheduler.clearEverything();
    await resyncReminders(
      scheduler,
      daos: daos,
      l10n: l10n,
      dueDayText: (ms) => formatDayFor(localeTag, ms),
    );
  } catch (error) {
    // The animal is out of the ledger, and that is the part that was asked for.
    // A phone that refuses its alarms is reported, not passed off as a failed
    // delete — the same line the restore takes.
    debugPrint('Reminder rebuild after an animal delete failed: $error');
  }
}
