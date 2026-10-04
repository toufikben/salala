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

## Status (Stage 0)

- `flutter analyze` (whole project including tests): **No issues found**
- `flutter test`: **35 passed, 0 failed** — schema 8, animal DAO 8, record DAOs 7,
  app-lock 7, widget 5
- Built: database layer with foreign keys and migrations, animal list/form,
  settings, app-lock PIN gate, English/Arabic/French with RTL
- Not yet done: CI has never run (no git remote exists — that is an owner
  decision), litter and record screens, PDF/JSON export

## Toolchain

Flutter **3.47.5** / Dart **3.13.4** at `C:\src\flutter` (not on `PATH`).

The development machine is 2 cores / 4 GB RAM / HDD. **Gradle cannot build an APK
here**; every build and install artifact comes from GitHub Actions, and UI
claims are verified on the physical device, not by compilation.

```sh
C:/src/flutter/bin/flutter pub get
C:/src/flutter/bin/flutter gen-l10n   # regenerate AppLocalizations
C:/src/flutter/bin/dart analyze
C:/src/flutter/bin/flutter test -j 1
C:/src/flutter/bin/dart format lib test
C:/src/flutter/bin/flutter run        # debug on a connected phone
```

Tests open a real SQLite database through `sqflite_common_ffi`, one temp file
per test; there are no database mocks.

## Conventions the tooling enforces

- Hand-written Riverpod 3 notifiers — no `build_runner`, no codegen.
- `flutter_lints` plus `dart format` on `lib/` and `test/`.
- User-visible strings live in `lib/core/l10n/*.arb`, never inline in a widget.
- Forms scroll (`SingleChildScrollView` + `Column`); they are never virtualised.
