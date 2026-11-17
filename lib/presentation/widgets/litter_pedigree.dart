/// The pedigree, drawn as what it is: two parents, one litter, the puppies of it.
///
/// A litter page already said `dam × sire` in one line and then listed puppies
/// underneath, which reads correctly and answers nothing. A breeder standing at
/// a mating is asking a different question — *which line is this puppy from* —
/// and that question is a shape, not a sentence: the two animals the litter came
/// from on top, the litter in the middle, the puppies it produced below.
///
/// Every name that resolves to an animal is a tap target, because the reason to
/// look at a pedigree is almost always to go and read one of the animals on it.
/// A name that resolves to nothing is drawn as text: a parent known only by the
/// name typed on the litter, or a record that was deleted, is a fact about the
/// litter rather than a broken link.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../../data/models/litter.dart';
import '../../data/models/photo.dart';
import 'photo_thumb.dart';

/// The whole pedigree card for one litter.
class LitterPedigree extends StatelessWidget {
  const LitterPedigree({
    super.key,
    required this.litter,
    required this.dam,
    required this.sire,
    required this.puppies,
    required this.animals,
    this.coverFor,
  });

  final Litter litter;
  final Animal? dam;
  final Animal? sire;

  /// The puppies of this litter, in the order the page lists them.
  final List<Animal> puppies;

  /// The whole herd, for the grandparents.
  final List<Animal> animals;

  /// A face per animal id, or null when the caller has no herd photograph map.
  /// Passed in rather than read here so the tree stays a pure widget.
  final Map<String, Photo>? coverFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.pedigreeTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            // The parents side by side, because they are a pair and reading them
            // as one row is how the litter is described everywhere else.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _ParentBranch(
                    parent: dam,
                    role: l10n.animalDam,
                    animals: animals,
                    photo: _photoOf(dam),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ParentBranch(
                    parent: sire,
                    role: l10n.animalSire,
                    animals: animals,
                    photo: _photoOf(sire),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            _Arrow(theme: theme),
            Center(
              child: _Chip(
                label: litter.name.isEmpty ? l10n.navLitters : litter.name,
                caption: _litterCaption(context, l10n, litter, puppies.length),
                emphasis: true,
              ),
            ),
            if (puppies.isNotEmpty) ...<Widget>[
              _Arrow(theme: theme),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  for (final puppy in puppies)
                    _Chip(
                      label: puppy.name,
                      caption: sexLabel(l10n, puppy.sex),
                      onTap: () => context.push(AppPaths.animal(puppy.id)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Photo? _photoOf(Animal? animal) =>
      animal == null ? null : coverFor?[animal.id];

  /// "3 puppies · born 4 May" — the two facts the middle node is about.
  String _litterCaption(
    BuildContext context,
    AppLocalizations l10n,
    Litter litter,
    int count,
  ) {
    final born = litter.whelpingDate;
    final when = born == null ? null : formatDay(context, born);
    if (when == null) return l10n.litterPuppyCount(count);
    return '${l10n.litterPuppyCount(count)} · $when';
  }
}

/// The small chevron between two rows of the tree.
class _Arrow extends StatelessWidget {
  const _Arrow({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Center(
      child: Icon(Icons.expand_more, size: 18, color: theme.colorScheme.outline),
    ),
  );
}

/// One parent as a branch: the name, the role, and the grandparents under it.
class _ParentBranch extends StatelessWidget {
  const _ParentBranch({
    required this.parent,
    required this.role,
    required this.animals,
    required this.photo,
  });

  final Animal? parent;
  final String role;
  final List<Animal> animals;
  final Photo? photo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (parent == null) {
      return _Chip(label: role, caption: l10n.valueUnknown);
    }

    final dam = animalById(animals, parent.damId);
    final sire = animalById(animals, parent.sireId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Chip(
          label: parent.name,
          caption: role,
          photo: photo,
          onTap: () => context.push(AppPaths.animal(parent.id)),
        ),
        // The grandparents are text rather than chips: four tap targets in an
        // eighth of a phone's width is a target nobody can hit, and each
        // grandparent is two taps away through its own child anyway.
        if (dam != null || sire != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              <String>[
                if (dam != null) dam.name,
                if (sire != null) sire.name,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// A name in a box, optionally with a face and a second line.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.caption,
    this.onTap,
    this.photo,
    this.emphasis = false,
  });

  final String label;
  final String caption;
  final VoidCallback? onTap;
  final Photo? photo;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = emphasis
        ? scheme.tertiaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = emphasis
        ? scheme.onTertiaryContainer
        : scheme.onSurfaceVariant;

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (photo != null) ...<Widget>[
            ClipOval(
              child: PhotoImage(photo: photo!, width: 26, height: 26),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: emphasis ? scheme.onTertiaryContainer : null,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.field),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? child : InkWell(onTap: onTap, child: child),
    );
  }
}
