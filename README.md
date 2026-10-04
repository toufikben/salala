# سلالة — Salala

سجل صحي ونسلي offline للمربّين الصغار (كلاب/قطط): حيوانات، بطنات، تطعيمات،
تحاليل صحية، أوزان، زيارات بيطرية، مشترٍ وتسليم — مع حزمة PDF تُسلَّم لمقتني
الجرو. بدون حساب، بدون سيرفر، بدون إذن إنترنت في المراحل 0–2.

An offline-first health and lineage record for small-scale dog and cat breeders,
with a transferable document pack for puppy buyers. No account, no server, no
network permission in Phase 0–2.

| Document | What it answers |
|---|---|
| [`docs/FEASIBILITY.md`](docs/FEASIBILITY.md) | whether the idea can work, which claims in the original brief were false, and the money problem |
| [`ROADMAP.md`](ROADMAP.md) | the stages, each with its evidence gate |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | layers, schema decisions, state, security model |
| [`DECISIONS.md`](DECISIONS.md) | every costly choice, why, and which two are still open |

## Status

- CI run **37236013403** (`Analyze and test`, commit `1dbf60c`): **No issues
  found!** and **60 tests passed** — schema 8, animal DAO 8, record DAOs 7,
  litter DAO 4, gestation 5, weight units 6, app-lock 7, widget 15 (5 animal
  list, 3 litter, 7 ledger). That is the authoritative verdict; the same
  commands run on the laptop are a convenience, not a gate (see `ROADMAP.md`).
- Built: database layer with foreign keys and migrations, animal list/form,
  settings, app-lock PIN gate, English/Arabic/French with RTL, litter
  list/form/detail with a whelping that registers its puppies in one save, and
  the animal ledger (vaccinations with an overdue badge, weigh-ins with a
  growth curve).
- Device: the CI debug APK from the `debug-apk` release installed on the Realme
  (`com.salala.salala`, `versionName 0.1.0`) at 2026-10-04 21:53. Screenshots
  and button-by-button checks are still owed.
- Not yet done: health-test and vet-visit sections, reminders, PDF/JSON export.

## Toolchain

Flutter **3.47.5** / Dart **3.13.4** at `C:\src\flutter` (not on `PATH`).

The development machine is 2 cores / 4 GB RAM / HDD. **Gradle cannot build an APK
here**; every build and install artifact comes from GitHub Actions, and UI
claims are verified on the physical device, not by compilation.

```sh
C:/src/flutter/bin/flutter pub get
C:/src/flutter/bin/flutter gen-l10n   # regenerate AppLocalizations
C:/src/flutter/bin/dart format lib test
```

The debug APK is published to a rolling `debug-apk` prerelease rather than an
Actions artifact (the account's artifact quota is shared and full — see
`DECISIONS.md` D13):

```sh
gh release download debug-apk -p "*.apk" -D build/apk
```

Tests open a real SQLite database through `sqflite_common_ffi`, one temp file
per test; there are no database mocks.

## Conventions the tooling enforces

- Hand-written Riverpod 3 notifiers — no `build_runner`, no codegen.
- `flutter_lints` plus `dart format` on `lib/` and `test/`.
- User-visible strings live in `lib/core/l10n/*.arb`, never inline in a widget.
- Forms scroll (`SingleChildScrollView` + `Column`); they are never virtualised.
