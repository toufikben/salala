# Salala — roadmap

Every stage ends with **evidence, not adjectives**: `flutter analyze` clean, the
named test counts green, and for anything user-visible a screenshot from the
physical device. A stage is not done until its gate passes, and the next stage
does not start on a failed gate.

Device reality that shapes this plan: the development machine is 2 cores / 4 GB
RAM / HDD, so **no local APK builds**. GitHub Actions is the only builder and
the only verifier of compiled Android output.

## Stage 0 — Foundation  *(gate: analyze + DB tests green, CI builds an APK)*

| Deliverable | Status |
|---|---|
| Flutter scaffold, Android/iOS, empty iOS work | done |
| `pubspec.yaml`, dependency set pinned | done |
| SQLite schema v1 (9 tables, 9 indexes) + FK-on configure | done |
| `RecordDao` base + 9 DAOs + settings DAO | done |
| Migration runner that fails loudly on a version gap | done |
| Value models (Equatable, `fromMap`/`toMap`) | done |
| Riverpod provider layer + `main()` injection | done |
| Router with synchronous PIN-gate redirect | done |
| App-lock PIN service (salted SHA-256 in secure storage) | done |
| en/ar/fr localisation + RTL | done |
| Animal list, animal form, settings, PIN screens | done |
| `.github/workflows/flutter-ci.yml` (analyze → test → APK) | **run 37230817629**: `Analyze and test` success — `No issues found! (ran in 10.3s)`, `35 tests passed.` |
| Backup/extraction rules closed on Android | done |
| `dart analyze` (whole project incl. tests) | **No issues found** |
| `flutter test` | **35 passed, 0 failed, exit 0, 44 s** — schema 8, animal DAO 8, record DAOs 7, app-lock 7, widgets 5 |

The widget suite found and fixed a real defect: the animal form was a `Form`
wrapped in a lazy `ListView`, so `Form.validate()` skipped every field outside
the cache extent — an animal could be saved with no name just because the name
box had scrolled away. It is a `SingleChildScrollView` + `Column` now
(`DECISIONS.md` D11).

No production key exists, so the release build types stay debug-signed and the
CI publishes debug artifacts only.

The `dart analyze` and `flutter test` lines above were run on the development
machine **before** the push. The user has since ruled that verification happens
on GitHub and on the phone only ("لا تفحص او تبني محليا"), so from here on CI is
the first verdict a change gets and the device is the second.

## Stage 1 — The breeder's ledger  *(the wedge the app is judged on)*

### 1a — Litters *(CI green, install verified)*

- `LitterDao.createWithPuppies` — litter + puppies in one transaction, lineage
  stamped by the dao (D14).
- Litter list, litter form, litter detail; a three-tab nav bar (D15).
- Expected whelping date from the mating date, dog and cat only (D16).
- en/ar/fr copy for every new string.
- Tests: 4 litter-DAO cases (linking, rollback, both delete paths), 5 gestation
  cases, 3 widget cases (empty state, refused save, a whelping that registers
  three puppies and shows them under Animals).
- CI: **run 37233197370** — `Analyze and test` success, `No issues found! (ran in
  11.4s)`, `47 tests passed.`; `Build debug APK` success, published to the
  `debug-apk` release (168 MB, `updated_at 2026-10-04T20:51:21Z`).
- Getting there took three red runs, all of them test-side or import-side:
  6 analyzer findings (missing screen imports in the router, an unused import,
  a null-aware element, an unused variable that should have been an assertion),
  then `45 passed, 2 failed` (a subtitle asserted without picking a sire; an
  Arabic title check the new nav bar duplicated), then `46 passed, 1 failed`
  (a tab tap attempted from a pushed route that has no nav bar).

### 1b — The animal ledger *(CI green, device check passed)*

- Tapping an animal now opens its card (`/animals/:id`) instead of its form;
  editing stays in the card's menu.
- Vaccinations: log, correct, delete, with the next-due date as a first-class
  field and an overdue badge driven by `Vaccination.isOverdue(now)` (D17).
- Weights: type kilograms, store grams, one kilogram is where the spoken unit
  changes; a growth curve drawn from the stored series; a mis-typed weigh-in is
  deleted and measured again rather than edited (D18).
- `parseWeightToGrams`/`formatWeight` in `core/utils/weight.dart`, covered by
  unit tests because a unit bug here is invisible until a vet reads the chart.
- Tests: 6 weight-unit cases (three in grams, three in and out of kilograms),
  7 widget cases (ledger shape, logging a dose, the overdue badge, correcting a
  dose, a kilogram weigh-in, a gram weigh-in ordered newest-first, deleting a
  weigh-in).
- CI: **run 37236013403** — `Analyze and test` success, `No issues found! (ran in
  11.6s)`, `60 tests passed.`; `Build debug APK` success, new asset on the
  `debug-apk` release (`updated_at 2026-10-04T21:33:17Z`).
- Three red runs on the way, each one a real defect rather than noise:
  `Path.addPolyline` does not exist, then neither does `Path.addPoints` (the
  polyline primitive in `dart:ui` is `addPolygon(points, false)` — checked
  against the engine source before the third push), then the ledger's parentage
  row printed the litter form's "Dam (mother)" wording.

### Device check — Stages 0/1a/1b on a Realme RMX3910 *(passed)*

- Evidence: numbered screenshots in the session's `device-check/` folder
  (00-foreground … 73-herd-empty-arabic), APK from the rolling `debug-apk` release.
- Host boundary, named: `mobile-use inventory` returned `surfaceCount: 0` — no
  live Canvas surface exists for this project — so the check drove the phone
  over host `adb` (720×1604, screenshot pixels 1:1 with device pixels). Taps are
  coordinate taps: `uiautomator dump` returns only an opaque Flutter view, so
  there are no semantics nodes to select by.
- Build identity confirmed on screen: Settings → "Build d2c33cf", matching HEAD.
- Happy path verified end to end on hardware: empty herd → add-animal form (every
  validator firing, species/sex/status dropdowns, date picker, the breeding
  switch) → save → herd card → ledger identity card → log a DHPP dose → correct
  it (edit form reopens prefilled) → log an 18.50 kg weigh-in → both rows
  persisted and rendered → Settings (Export disabled with its Phase-2 copy, the
  About privacy line).
- Language switching verified live: English → French → Arabic. Arabic is fully
  RTL — mirrored nav bar, mirrored FAB and switch, disclosure chevrons pointing
  left, dialog buttons swapped, Arabic-Indic numerals in dates, and both record
  sections showing their own empty state.
- Deletion paths verified in Arabic: weigh-in deleted, dose deleted with a
  "تم حذف التطعيم" confirmation, and the animal deleted behind a destructive
  confirm dialog; the herd returned to its empty state, so the device is clean.
- App lock: toggling it opens the create-PIN dialog. It was cancelled without
  entering a PIN and the switch reverted to off — no device secret is ever
  typed in from this workflow.
- Findings, and what became of them:
  1. `animal_form_screen.dart` — the species helper text `'dog · cat'` was a
     hardcoded English string inside a localized form; it stayed English in the
     Arabic and French UI. Fixed in 1c through `animalSpeciesHelper`; the
     screening-result helper got the same treatment.
  2. Herd card subtitle left a trailing "·" when it wrapped to a second line.
     Fixed: the birth date now takes its own line.
  3. Empty herd offered two "Add animal" affordances at once (filled button +
     FAB). Fixed: the FAB appears only once there is a herd to add to. A test
     had been asserting the duplication (`findsNWidgets(2)`), so the bug was
     written down as expected behaviour — that assertion is now the guard.
  4. The weight unit renders as "kg" in every locale. Open: it needs a decision
     about Arabic unit wording (كغ vs keeping kg), not just a key.
- Not covered by this check: reminder scheduling (unbuilt), and anything needing
  a second device. Health tests and vet visits were unchecked at the time of
  writing; they have since been run on the device — see the 1c pass below.

### 1c — Screenings and consultations on the same ledger *(CI green; device check done; its five findings fixed and re-checked on `6c874cd`)*

- Health tests: the screening a buyer is shown — type, result, testing body,
  certificate number, who verified it, and a `validUntil` that turns a row from
  a fact into a claim with an expiry. A lapsed certificate gets an "Expired"
  flag on its row; a permanent grade gets none.
- Vet visits: reason, outcome, clinic, vet, and a cost kept exactly as typed
  with its currency code normalised. No conversion — a placement pack has to
  show what was spent, not what a fluctuating rate says it is worth today.
- Both are creatable, correctable from their own row, and deletable behind the
  same confirm dialog every record uses.
- Device finding 1 was half fixed in `1f59646`: the species helper and the
  screening result helper no longer hardcoded English inside a localized form —
  both now read from `.arb`. But the `healthTestResultHelper` value was left in
  English in `app_ar.arb` and `app_fr.arb`. All five findings were then fixed in
  `6c874cd` and re-checked on the phone; see the re-check below.
- Tests: 7 DAO cases (certificate round trip, expiry clearing, newest-first
  ordering, decimal fee round trip, a null fee that must not read as zero) and
  8 widget cases, including an Arabic ledger that asserts each row by scrolling
  to it rather than trusting the list to be built.

- CI verdict (run `37243802618`, commit `1f59646`): `flutter analyze
  --fatal-infos` → "No issues found! (ran in 7.9s)"; `flutter test -j 1` →
  "🎉 75 tests passed."; debug APK published (168,825,323 bytes) and installed
  on the Realme — Settings prints "Build 1f59646".

- Device check of 1c (Realme RMX3910, build `1f59646`). Every claim below is
  backed by a screenshot that was opened and read, plus `salala.db` pulled off
  the phone with `run-as` and queried directly. English UI first, then the same
  screens in Arabic and French.
  - Add animal → **Zeus** saved; herd card and one `animals` row.
  - Ledger renders all four sections — Vaccinations, Health tests, Vet visits,
    Weights — each with its own add action and empty-state line.
  - **Health test created**: BAER / Clear / Clinic / BAER-1024 / Dr. Haddad,
    Tested on prefilled to today. Stored as `test_date 1791154800000` (local
    midnight Oct 5 2026) and `valid_until 1792018800000` — exactly ten days
    later, so the day-boundary encoding is right.
  - **"Expired" flag verified live**: editing Valid until to a past date made the
    row show "Expired" and reloaded the ledger; the DB then read
    `valid_until 1788217200000`.
  - **Vet visit created**: reason, outcome, clinic, vet, cost 350.5 typed as
    "350.50", stored `cost: 350.5` REAL with `currency: "MAD"` normalised.
  - **Vaccination and weigh-in created on this build**: `batch_number A123`,
    `certificate_number VAC-9`, `weight_grams 18500` — the ledger row showed
    18.50 kg.
  - **Edit path verified for every record type that has an edit form** — health
    test, vet visit, vaccination — plus the animal. Each reopened prefilled with
    every stored value; changing a value and saving wrote it back
    (`vet_visits.cost` 350.5 → 420, `vaccinations.batch_number` A123 → B777)
    while `created_at` stayed and `updated_at` moved. Weigh-ins have **no edit
    route by design** (`WeightFormScreen` takes only an `animalId`; the route is
    `weights/new`): a weigh-in is a measurement, so correcting one means deleting
    it and logging it again. That is deliberate, but nothing on the row says so —
    worth a hint later.
  - **Delete path verified for all four record types plus the animal itself.**
    Each confirm dialog names the record type in its body; the Cancel branch was
    checked too. After each confirm, the section fell back to "Nothing recorded
    yet." and the table row count dropped to 0.
  - **Cascade delete proven with live data**, not just an empty animal: a second
    animal was created, given a weigh-in ("12.40 kg" on the ledger, one
    `weight_entries` row), then deleted from the herd card menu behind "Delete
    Pu? — Its vaccinations, health tests, weights and visits are deleted too."
    Reading the pulled database afterwards: `animals 0`, `weight_entries 0`.
  - **Required-field validation on-device**: saving an animal with no species
    kept the form open, outlined the Species field and showed "Choose a species"
    as the error; filling it in let the same tap save.
  - **Arabic (RTL) pass**: language switch persisted to `user_settings`
    (`language_code = ar`) and held across every screen of the pass. RTL
    mirrored correctly — tab bar order, back arrow, calendar icons, Save on the
    left, dropdown menus anchored to the left edge. Section titles, add actions,
    empty states and all four delete dialogs render in Arabic. Dates use
    Arabic-Indic digits (٥ أكتوبر ٢٠٢٦) while weights and certificate numbers
    stay Latin in the same screen. **Cold restart verified**: the app was
    force-stopped and relaunched via the launcher intent and came back straight
    into Arabic RTL on the empty herd, so the boot-time locale read in `main.dart`
    works on a real device.
  - **French pass**: accented strings render (Réglages, À propos, Portées,
    N° du certificat, Valable jusqu'au) and the longer labels fit; the card menu
    read Modifier / Supprimer and the animal dialog "Supprimer Zeus ?". Language
    restored to System default afterwards; the phone was left with no test data.
- Open device findings from this pass, none of them data-loss bugs:
  1. `healthTestResultHelper` is "Clear · 0 · Affected" in **all three** `.arb`
     files — the middle token is a bare digit that reads as nothing on a phone,
     and the whole hint is untranslated in ar/fr, which is why it showed in
     Latin script inside the Arabic and French forms.
  2. `DateTile`'s trailing calendar icon is not a tap target: the accessibility
     bounds of the tappable region start at x=136 while the icon paints at
     x≈48–104, so tapping the icon does nothing in both LTR and RTL. The icon is
     what reads as the affordance.
  3. A `ListTile` that only carries a `trailing` widget announces itself as one
     wide Button while only the trailing part reacts — the Settings language row
     swallows a tap on its own label. Same shape as finding 2; both need the hit
     area widened.
  4. `formatWeight` hardcoded an English "kg", so the Arabic ledger showed
     "kg 18.50" beside an Arabic "الوزن (كغ)" label. Checked after writing this
     up: the unit sitting left of the number is the bidi algorithm doing its job
     in an RTL paragraph, not a defect — only the unit's language was wrong.
  5. No bottom inset for the system navigation bar. On the ledger the last row
     sits under it (row bottom y=1556 vs nav bar top y=1516) and cannot be
     scrolled clear; on the animal form the Save/Cancel row is pinned at
     y=1444–1540, so the bottom ~24px of the pills is clipped by the nav bar at
     every scroll position. The tap still lands (the centre is above the bar),
     so this is cosmetic — but on a shorter screen it would not be. The weigh-in
     form is short enough to clear the bar, which is why it was missed earlier.

- **Re-check of the five fixes on the phone** (Realme RMX3910, build `6c874cd`,
  CI run `37284242980` → success: `flutter analyze --fatal-infos` → "No issues
  found! (ran in 12.0s)", `flutter test -j 1` → "🎉 76 tests passed." (the 75
  from `1f59646` plus the new locale-unit case), debug APK built and published).
  The installed build was proven to be the fixes commit by the Settings row itself:
  "رقم البناء | 6c874cd" in Arabic and "Version | 6c874cd" in French. `install -r`
  was refused again with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, so the old build
  was uninstalled first — after reading the pulled database and confirming every
  business table held 0 rows, so nothing of the user's was lost.
  - **Finding 3 (language row) closed.** The row now reports
    `clickable=true` across its full width (`0,304-720,416`) and the menu opens
    from a tap at x=90 (over the label), x=360 (centre) and x=650 (over the
    endonym) — in Arabic RTL and in French LTR. The menu lists all four options
    unclipped, and picking one changes the whole app.
  - **Finding 2 (date tile) closed.** "تاريخ الميلاد" reports `clickable=true`
    over `32,746-688,844`, and five separate taps — centre (360,795), right edge
    over the label (660,795), left edge over the calendar icon (60,795), top
    strip (400,752), bottom strip (400,838) — each opened the picker. The picker
    itself is fully Arabic (١٥ أكتوبر ٢٠٢٥, Arabic-Indic day cells), and the
    chosen date wrote back into the tile.
  - **Finding 1 (result helper) closed.** The Arabic screening form reads
    "كما في الشهادة: Clear · Carrier · Affected" and the French one "Comme au
    certificat : Clear · Carrier · Affected". The three grade words stay Latin
    on purpose — that is how a certificate prints them.
  - **Finding 4 (weight unit) closed.** `formatWeight` now takes its units from
    the locale: the Arabic ledger shows "18.50 كغ" and "430 غ" (one entry above
    the kilogram line, one below), and the French ledger shows "18.50 kg" and
    "430 g". The stored grams are exactly 18500 and 430, read back from
    `salala.db`.
  - **Finding 5 (bottom inset) closed.** On the ledger, scrolled to the end, the
    last weigh-in row sits at y 1312–1456 with the nav bar starting at 1516 —
    clear, where the same row previously ended at y=1556. On the animal form the
    حفظ/إلغاء pills sit at y 1356–1452; on the vet-visit edit form the Cancel
    row ends at y=1410. With the keyboard up every form lands its Save at
    32,846-348,942, above the IME, so the pill is never clipped or unreachable.
  - **Regression sweep on the same build**, in Arabic: animal `baraka` created
    (`species dog`, `birth_date 1760482800000` = 15 Oct 2025), then a
    vaccination (`dhpp`), a health test (`hip` / `Clear`, `valid_until
    1790809200000` = 1 Oct 2026 → the row carries "منتهي الصلاحية"), two
    weigh-ins, and a vet visit (`reason checkup`, `cost 350.5`, `currency MAD`).
    The vet visit was then deleted from its own edit screen ("Supprimer cet
    enregistrement ?") and the animal deleted from the herd menu ("Supprimer
    baraka ?"), which cascaded the rest: the pulled database read
    `animals 0, vaccinations 0, health_tests 0, weight_entries 0, vet_visits 0`.
  - **Validation still holds on-device**: typing the weight into the Note field
    left the Weight field empty and red-outlined with "أدخل الوزن", and the save
    was refused — the same guard the English pass showed, now seen in Arabic.
  - **Delete confirmations are localized**: "حذف هذا السجل؟ / يُحذف هذا الوزن. لا
    يمكن التراجع عن ذلك." in Arabic, "Supprimer cet enregistrement ?" in French.
    One of these was reached by an accidental tap on a weigh-in's trash icon and
    cancelled, so the Cancel branch is proven on this build too.
  - Phone left clean: all business tables 0 rows and `language_code = system`,
    verified by a force-stop and cold relaunch into the English empty herd.
- Still open from this re-check, cosmetic only:
  6. The Arabic ledger mixes numeral systems inside one row — "18.50 كغ" in
     Latin digits next to "٥ أكتوبر ٢٠٢٦" in Arabic-Indic. Dates go through
     `intl`, weights are printed by `formatWeight` with `toStringAsFixed`. A
     Moroccan breeder reads both fine, so this is a polish call, not a defect;
     deciding it means picking one system for the whole screen.

Still open in Stage 1: the numeral-system call above (finding 6, cosmetic), the
30-day reminder scheduler — which needs a
`flutter_local_notifications` spike, not an argument — and `es`/`de` `.arb`
files once the copy settles. Findings 1–5 are fixed in `6c874cd` and were
re-checked on the device.

Gate: every record type creatable, editable, deletable on the device — **met**
(weigh-ins by delete-and-relog, as designed) for all four record types and the
animal, in English, Arabic and French.
Reminders firing on the phone inside the window is still open, so Stage 1 is not
closed.

## Stage 2 — The transfer pack (the thing people pay for)

- PDF pack generator: animal sheet, pedigree (2–3 generations), vaccination
  history, health-test certificates, weight curve, feeding plan, and the
  buyer/placement record.
- JSON export/import of the whole database — the honest answer to "what if I
  lose my phone", and the reason there is no cloud.
- Share sheet, no account, no upload.

Gate: a generated PDF opened on the phone, verified page by page against the
record for a real animal.

## Stage 3 — Rule-based triage + small intent classifier

- Deterministic triage first: symptom→urgency rules over the stored record
  (age, last vaccination, species, breed-specific risk), returning "act now /
  watch / routine vet". Rules are data, editable without a rebuild.
- Then, and only then, a small on-device intent classifier for free-text
  symptom input. Scope is decided by measured accuracy, not by ambition.
- Explicit non-claim in the UI: this is not a veterinary diagnosis.

Gate: the rule table ships with the triage screen; every rule has a test; the
classifier is behind a measured benchmark or it does not ship.

## Stage 4 — Distribution

Blocked on the business question in `docs/FEASIBILITY.md` §Payments: a Morocco
resident developer cannot receive Play money directly. Options ranked there.
Whatever is chosen happens **before** the package id and the store listing are
made permanent, because both are one-way doors.

## Stage 5 — Later candidates (no commitment yet)

Multi-breeder/club accounts (the B2B2C path), breeding-plan and mate-pairing
advice, FHIR `patient-animal` alignment for vet interoperability, iOS build,
photo/attachment storage, and a web viewer for buyers who received a pack.

## Standing constraints

- Offline-first: no network permission until a feature provably needs it.
- Tests hit real SQLite, not mocks.
- Nothing is claimed as passing without a command and its output.
- No stubs or dead scaffolding to satisfy a checklist.
- The repository's `ARCHITECTURE.md` and `DECISIONS.md` are updated whenever a
  structural choice changes.
