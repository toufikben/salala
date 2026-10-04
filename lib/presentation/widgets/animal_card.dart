import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../providers/app_providers.dart';

class AnimalCard extends ConsumerWidget {
  const AnimalCard({super.key, required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final subtitle = <String>[
      if (animal.breed != null && animal.breed!.isNotEmpty) animal.breed!,
      sexLabel(l10n, animal.sex),
      if (animal.birthDate != null) formatDay(context, animal.birthDate),
      if (animal.status != AnimalStatus.active)
        statusLabel(l10n, animal.status),
    ].join(' · ');
    final initial = animal.name.isEmpty
        ? '?'
        : animal.name.substring(0, 1).toUpperCase();

    return Card(
      child: ListTile(
        onTap: () => context.push(AppPaths.editAnimal(animal.id)),
        leading: CircleAvatar(
          backgroundColor: animal.isBreedingStock
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(initial, style: theme.textTheme.titleMedium),
        ),
        title: Text(animal.name, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: PopupMenuButton<_CardAction>(
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
      ),
    );
  }
}

enum _CardAction { edit, delete }

Future<void> confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Animal animal,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.animalDeleteTitle(animal.name)),
      content: Text(l10n.animalDeleteBody),
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

  if (confirmed == true) {
    await ref.read(animalsProvider.notifier).delete(animal.id);
  }
}
