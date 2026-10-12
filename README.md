# سلالة — Salala

سجل صحي ونسلي offline للمربّين الصغار (كلاب/قطط): حيوانات، بطنات، تطعيمات،
تحاليل صحية، أوزان، زيارات بيطرية، مشترٍ وتسليم — مع حزمة PDF تُسلَّم لمقتني
الجرو. بدون حساب، بدون سيرفر، وبدون إذن إنترنت: الصلاحية الوحيدة في
أندرويد هي `RECEIVE_BOOT_COMPLETED`، أي إعادة جدولة التنبيهات بعد الإقلاع.

An offline-first health and lineage record for small-scale dog and cat breeders,
with a transferable document pack for puppy buyers. No account, no server, no
network permission — the only Android permission the manifest declares is
`RECEIVE_BOOT_COMPLETED`, which is what keeps a dose reminder alive through a
reboot. Pictures come from the file picker, so there is no camera or storage
permission either.

| Document | What it answers |
|---|---|
| [`docs/FEASIBILITY.md`](docs/FEASIBILITY.md) | whether the idea can work, which claims in the original brief were false, and the money problem |
| [`ROADMAP.md`](ROADMAP.md) | the stages, each with its evidence gate |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | layers, schema decisions, state, security model |
| [`DECISIONS.md`](DECISIONS.md) | every costly choice, why, and which two are still open |

## Status

Two verifiers only, and neither is this machine: GitHub Actions, and one Android
phone. `ROADMAP.md` is the authoritative history — every stage there carries its
own run id and its own phone record. This section is a summary, and the numbers
are as of the run named below.

- CI verdict: run **38186602185** (commit `d46b367`, 2026-10-12) — `flutter
  analyze --fatal-infos`: **No issues found! (ran in 18.9s)**; `flutter test -j
  1 --dart-define=use_arabic=true`: **500 tests passed**.
- Built: the database layer with foreign keys and migrations; the animal list and
  form; settings and the app-lock PIN gate; English/Arabic/French with RTL; the
  litter list/form/detail, with a whelping that registers its puppies in one
  save; the animal ledger — vaccinations with an overdue badge, weigh-ins with a
  growth curve, health screenings, vet visits, symptoms; a triage card built from
  a rule table that never names a disease; the herd agenda and herd search;
  reminder alarms the operating system keeps and the next launch rebuilds; JSON
  export of the whole database and its restore; a per-animal PDF pack a buyer can
  open on any phone; and each animal's own photographs, stored under the app's
  documents and deleted with the animal behind a warning that says so, in all
  three languages.
- Device (`com.toufikben.ledger`, `versionName 0.1.0`): checked stage by stage on
  a Realme, most recently on 2026-10-12 at build `96eaa7c`, where the delete
  warning was read in English, Arabic and French and the picture folder was read
  back empty after the tap.
- Not yet done: **Stage 4 — Distribution**, and it is blocked on a business
  decision rather than code. No billing dependency, no purchase screen and no
  network permission exist yet, which is the point: the payment route (D8) has to
  be chosen before the store listing is a one-way door. Also open and named in
  `ROADMAP.md` — the launcher icon is still the stock Flutter template art, and
  iOS, FHIR alignment and a web viewer for received packs are triaged as not
  verifiable on this machine and this CI, so none is claimed.

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
