import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../data/models/photo.dart';
import '../providers/record_providers.dart';

/// One picture off this phone, drawn at the size the layout asked for.
///
/// The size is the whole point of this widget existing at all. A 12-megapixel
/// camera JPEG costs about 48 MB once decoded; this app shows that file as an
/// 88-point tile on the herd list and as a full-width cover on the animal's own
/// page. Asked for the whole picture, the phone spends its memory on pixels it
/// then shrinks to nothing on the way to the canvas — on a device that may have
/// 350 MB free. So the caller says how large the frame is, and `cacheWidth` is
/// computed from it rather than guessed.
///
/// It lives here rather than inside the animal screen because the herd card and
/// the animal's own page now draw the same picture, and two copies of the decode
/// rule is two places for the memory behaviour to drift apart.
class PhotoImage extends ConsumerWidget {
  const PhotoImage({
    super.key,
    required this.photo,
    required this.width,
    required this.height,
    this.radius = 8,
    this.fit = BoxFit.cover,
    this.missing,
  });

  /// The frame, in logical points. [double.infinity] means "as wide as the
  /// parent allows" — which is how the full-bleed cover is asked for, and the
  /// only reason this cannot take the number straight to `cacheWidth`: an
  /// infinite width times a pixel ratio is an infinite `cacheWidth`, and
  /// `ceil()` on that throws inside the build.
  final Photo photo;

  final double width;
  final double height;
  final double radius;
  final BoxFit fit;

  /// What to draw when this phone does not have the bytes.
  ///
  /// Every caller has a different sensible answer — the strip names the gap, the
  /// herd card falls back to the animal's initial — and none of them is the same
  /// blank. Null uses [PhotoGap], the sentence the strip has always shown.
  final Widget? missing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gap = missing ?? const PhotoGap();
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ref
            .watch(photoPathProvider(photo))
            .when(
              // Not a spinner: the answer is one stat call, and a bar that appears
              // and disappears per tile is a list that flickers while scrolling.
              loading: () => const ColoredBox(color: Color(0x14000000)),
              error: (error, stack) => gap,
              data: (path) => path == null
                  ? gap
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // The frame's own size and nothing larger: a tiled
                        // thumbnail is 88 points on a 3x phone, and decoding at
                        // screen width would be four times the pixels for a
                        // picture drawn at a quarter of it. A caller that asked
                        // to fill its parent gets the width the parent actually
                        // gave it, which is the one number `SizedBox` cannot
                        // know when the value handed in was infinity.
                        final frame = width.isFinite
                            ? width
                            : (constraints.maxWidth.isFinite
                                  ? constraints.maxWidth
                                  : MediaQuery.sizeOf(context).width);
                        final decodeWidth = math.max(1, (frame * dpr).ceil());
                        return Image.file(
                          File(path),
                          cacheWidth: decodeWidth,
                          fit: fit,
                          // A file that will not decode is the same fact as one
                          // that is not there, told the same way.
                          errorBuilder: (context, error, stack) => gap,
                        );
                      },
                    ),
            ),
      ),
    );
  }
}

/// The named blank: a picture row this phone cannot produce a file for.
///
/// Same words everywhere it is used, because the fact is the same fact — the
/// ledger remembers a picture and the folder does not have it. Restoring the pack
/// is what puts it back, and a breeder who is told "not on this phone" has the
/// one piece of information that makes the missing thumbnail not a lost photo.
class PhotoGap extends StatelessWidget {
  const PhotoGap({super.key, this.radius = 8});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            AppLocalizations.of(context).photoMissing,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}
