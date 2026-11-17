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
/// Three slides, no account, no permission prompt: the point is that the app has
/// nothing to ask for at the door. Every sentence here is a promise the rest of
/// the app keeps — a record per animal, its health in order, its story leaving
/// with it — because an introduction that oversells is a screen the breeder reads
/// once and then distrusts.
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
    final theme = Theme.of(context);

    final slides = <_Slide>[
      _Slide(
        icon: Icons.pets_outlined,
        title: l10n.onboardingSlide1Title,
        body: l10n.onboardingSlide1Body,
      ),
      _Slide(
        icon: Icons.vaccines_outlined,
        title: l10n.onboardingSlide2Title,
        body: l10n.onboardingSlide2Body,
      ),
      _Slide(
        icon: Icons.ios_share,
        title: l10n.onboardingSlide3Title,
        body: l10n.onboardingSlide3Body,
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
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 58,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(height: 34),
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
                      ],
                    ),
                  );
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
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: dot == _index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dot == _index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
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

class _Slide {
  const _Slide({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}
