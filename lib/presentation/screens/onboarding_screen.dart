import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../data/db/settings_dao.dart';
import '../providers/app_providers.dart';

/// What a brand-new install sees once, and what a returning breeder can reopen
/// from Settings.
///
/// Eight cards, one per thing the app actually does, in the order a breeder
/// meets them: the animal, the litter, the pedigree, the health, the buyer, the
/// document, the privacy, and finally who made it. No account, no permission
/// prompt: the point is that the app has nothing to ask for at the door. Every
/// sentence here is a promise the rest of the app keeps — a record per animal,
/// its health in order, its story leaving with it — because an introduction that
/// oversells is a screen the breeder reads once and then distrusts.
///
/// The last card is not a feature. It is the honest answer to "why does this
/// cost money": one programmer, no company, no ads, no investors, and the sale
/// is what pays for the next update. It comes last because a breeder who has
/// just read what the app does can judge whether that is worth anything, and a
/// plea before the demonstration is a plea nobody believes.
///
/// "Seen" is a settings row rather than a first-run flag in memory: an app that
/// re-introduces itself after every process death is an app that assumes the
/// breeder has forgotten, and the row also lets this page be reopened on demand.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.returnTo});

  /// Where Done goes when this was opened from Settings rather than at launch.
  /// Null means launch, which lands on the herd.
  final String? returnTo;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // Written before the screen closes: an introduction the phone would not
    // record would otherwise greet the breeder again on the next launch, and the
    // second showing reads as a bug rather than a welcome. A failure to write is
    // not worth a sentence — the cost is one extra slide-through.
    try {
      await ref
          .read(settingsDaoProvider)
          .writeBool(SettingKeys.onboardingSeen, true);
    } catch (error) {
      debugPrint('Onboarding flag not stored: $error');
    }
    // The flag in memory moves regardless: the router redirect is what closes
    // this page, and leaving it false would send the breeder straight back here
    // the moment the write failed for a reason the phone will not report.
    ref.read(onboardingSeenProvider.notifier).markSeen();
    if (!mounted) return;
    context.go(widget.returnTo ?? AppPaths.animals);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // One list, in reading order. Each card names one thing the app holds, so a
    // breeder who only ever reads this page still knows where the litter is and
    // where the buyer is.
    final slides = <_Slide>[
      _Slide(
        icon: Icons.pets_outlined,
        title: l10n.onboardingSlide1Title,
        body: l10n.onboardingSlide1Body,
      ),
      _Slide(
        icon: Icons.pregnant_woman_outlined,
        title: l10n.onboardingLittersTitle,
        body: l10n.onboardingLittersBody,
      ),
      _Slide(
        icon: Icons.account_tree_outlined,
        title: l10n.onboardingPedigreeTitle,
        body: l10n.onboardingPedigreeBody,
      ),
      _Slide(
        icon: Icons.vaccines_outlined,
        title: l10n.onboardingSlide2Title,
        body: l10n.onboardingSlide2Body,
      ),
      _Slide(
        icon: Icons.people_alt_outlined,
        title: l10n.onboardingBuyersTitle,
        body: l10n.onboardingBuyersBody,
      ),
      _Slide(
        icon: Icons.ios_share,
        title: l10n.onboardingSlide3Title,
        body: l10n.onboardingSlide3Body,
      ),
      _Slide(
        icon: Icons.wifi_off_outlined,
        title: l10n.onboardingYoursTitle,
        body: l10n.onboardingYoursBody,
      ),
      _Slide(
        icon: Icons.favorite_outline,
        title: l10n.onboardingSupportTitle,
        body: l10n.onboardingSupportBody,
        // The one card that is not a feature gets the clay tone the rest of the
        // app reserves for things that are not routine: it should not look like
        // a ninth feature, because it is not one.
        warm: true,
      ),
    ];
    final last = _index == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextButton(
                  // Skipping is not a decision to be punished with a second
                  // showing: it marks the introduction seen exactly as Done does.
                  onPressed: _finish,
                  child: Text(l10n.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: slides.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  return _Card(slide: slides[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (var dot = 0; dot < slides.length; dot++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: dot == _index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dot == _index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: last
                          ? _finish
                          : () => _pages.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            ),
                      child: Text(
                        last ? l10n.onboardingStart : l10n.onboardingNext,
                      ),
                    ),
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

/// One introduction card.
///
/// Scrollable rather than centred-and-clipped: a German sentence is longer than
/// an English one, and the card that explains the product is the last place to
/// discover that a paragraph does not fit.
class _Card extends StatelessWidget {
  const _Card({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = slide.warm
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.tertiaryContainer;
    final ink = slide.warm
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onTertiaryContainer;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: tile,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: Icon(slide.icon, size: 52, color: ink),
              ),
              const SizedBox(height: 30),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                slide.body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    this.warm = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool warm;
}
