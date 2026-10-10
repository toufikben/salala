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
- Closed since, by the owner:
  6. The Arabic ledger mixed numeral systems inside one row — "18.50 كغ" in
     Latin digits next to "٥ أكتوبر ٢٠٢٦" in Arabic-Indic. Dates went through
     `intl`, weights through `formatWeight`'s `toStringAsFixed`. **Decided: Latin
     digits in every language (D21).** Month and day names stay Arabic — only the
     digits move — because a dose date is read against a certificate typed in
     Latin. The conversion sits in `formatDayFor`, the app's only `DateFormat`
     call, and `test/core/date_utils_test.dart` is written to hold the line — that
     code has not had a CI verdict or a screen yet, so it rides with 1e's next run.

Still open in Stage 1: watching the 09:00 alarm actually arrive (1d below), the
D20 device check (1e below), the Arabic digits on a real screen (D21, above) and
`es`/`de` `.arb` files once the copy settles. Findings 1–5 are fixed in `6c874cd`
and were re-checked on the device.

### 1d — The 30-day reminder (spike: CI green, alarms booked on the phone, delivery pending)

The last Stage 1 gate item was a claim the code had never made: telling the
breeder *without the app being open*. That needs the operating system to hold an
alarm, so it was built as a spike against the real plugin rather than argued
about.

What is in it:

- `lib/core/utils/reminders.dart` — the policy, pure Dart: two moments per due
  date (30 days ahead, and the due morning at 09:00 local), anything already in
  the past dropped rather than delivered late, and a stable 32-bit notification
  id derived from the record's uuid so re-saving a dose replaces its own alarms
  instead of stacking copies.
- `lib/services/reminder_scheduler.dart` — the only file that touches
  `flutter_local_notifications`. Channel `salala_reminders`; the phone's own
  timezone pinned through `flutter_timezone` before anything is scheduled, or a
  nine-in-the-morning note wakes a breeder at midnight;
  `AndroidScheduleMode.inexactAllowWhileIdle` deliberately, because an exact
  alarm needs `SCHEDULE_EXACT_ALARM` and a Play policy audit for a message whose
  only deadline is "that morning" is not worth it.
- The forms call it: saving a dose or a screening replaces its reminders, deleting
  cancels them, and the notification is titled with the animal's name and carries
  the localized body (`reminderHeadsUpBody` / `reminderDueBody` in `en`, `ar`,
  `fr`). Scheduling happens after the database write, so a record is never lost
  because a notification failed.
- `main()` bootstraps one scheduler before the first frame and injects it, inside
  a `try` — a phone that refuses notifications still opens the ledger.
- Manifest: `RECEIVE_BOOT_COMPLETED` plus the plugin's two receivers declared by
  hand (the plugin stopped merging them in at v16, and without them a scheduled
  reminder simply never arrives). `POST_NOTIFICATIONS` is left to the plugin's own
  manifest. Gradle: core-library desugaring switched on, which the plugin has
  required since v10 for `java.time` on older APIs.
- Tests: the date policy and id folding are covered directly
  (`test/core/reminders_test.dart`, 12 cases). The scheduler is reached through a
  seam the app owns — `abstract class NotificationWriter`, implemented in
  production by `PluginNotifications` — because the plugin's own constructor is a
  `factory` and so cannot be subclassed: the first CI run proved that by refusing
  to compile a test that tried. So `test/services/reminder_scheduler_test.dart`
  (9 cases) runs the real scheduling rules over `FakeNotificationWriter`, which is
  what shows two alarms per due date, at 09:00 in the pinned zone, inexact, with
  the stale ids cleared *before* the new ones are written, and in the language on
  screen. Four widget tests drive the same real scheduler through the form: a dose
  with no due date books nothing, a dose 20 days out books only its due morning
  under the animal's name, a dose 45 days out books two alarms exactly
  `reminderLeadDays` apart, and deleting a booked dose clears precisely the two ids
  that booking wrote. No test ever talks to a real notification channel.

**Verification status: CI green, alarms proven on the phone, delivery still open.**

- CI run `37297326645` on `9872281`: `flutter analyze --fatal-infos` clean and
  **100 tests passed**. The two earlier reds were both worth having: run
  `37294879238` refused to compile a double that extended the plugin (its
  constructor is a `factory`), which is what produced the `NotificationWriter`
  seam; run `37296888540` failed because the *test helper* wrote
  `dueMs ?? dueInSixtyDays()`, so the "no due date" case never reached the
  scheduler with a null. The production rule was right — the widget test through
  the real form passed — and the helper was the lie.
- Run `37353640524` (a commit that touched only the workflow and this file) came
  back **99 passed, 1 failed**: `saving a dose books its due morning on the phone`
  read zero alarms from a dose that had one. That was a real race, not a wrong
  rule — the same code had been green twice, and the only test that can lose a
  race silently (`written, isEmpty`) stayed green while the one that cannot
  failed. The widget writes the dose on SQLite's isolate, so the alarms reach the
  writer some real milliseconds after the tap; the assertion was reading too
  early. The four reminder widget tests now wait for the scheduler's own call
  log — two clears plus one write per alarm — and a save that reached the
  scheduler but booked nothing fails naming how far the log got, so the wait
  cannot mask the bug it was added for.
- Realme RMX3910, debug APK from that run (`9872281`), after an empty-database
  check (`0` animals) and a reinstall:
  - The Android 13 prompt really appears, at launch: "Allow **Salala** to send you
    notifications?" → `POST_NOTIFICATIONS: granted=true, flags=[USER_SET|…]`.
  - `aapt2 dump` of the CI-built APK shows both hand-declared receivers
    (`ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`) — the
    one thing a green build would not have caught on its own.
  - Booking `Rabies` due tomorrow and `Parvo` due 19 Nov left **exactly three**
    alarms in `dumpsys alarm`, all `RTC_WAKEUP`, all aimed at
    `ScheduledNotificationReceiver`, each with `window=+1h0m0s0ms` (the inexact
    mode, visible from the outside): `2026-10-06 09:00`, `2026-10-20 09:00`,
    `2026-11-19 09:00`. The Rabies month-ahead alarm is absent because it is
    already past — the drop rule works on a real date, not only in a test.
  - Deleting the `Parvo` row took **both** of its alarms out: `dumpsys alarm`
    then listed only `2026-10-06 09:00`.
  - `am force-stop com.salala.salala` took the remaining alarm out too (0 left),
    while the ledger rows survived. That is AlarmManager's own behaviour rather
    than a bug in the scheduler, but it is a product finding: clearing the app
    away can delete next morning's reminder, and only re-saving the dose puts it
    back. Whether a swipe from the recents screen does the same on ColorOS is
    untested — it is the next thing to measure, because breeders do swipe.
  - The `salala_reminders` channel does **not** exist yet (`grep -c` = 0). That is
    the plugin's own design, read from its Java source: `createNotification`
    builds the channel at delivery time, so no `createNotificationChannel` call
    is needed at startup — and it means the channel cannot be screenshot-proofed
    before the first alarm fires.

Still open, and the only thing the gate actually asks for: whether the
`2026-10-06 09:00` alarm is *delivered* as a visible notification. The dose has to
be re-booked first (the force-stop above removed its alarm), and the phone then
left alone overnight so the answer is the real one —
no battery-optimisation whitelist, because ColorOS killing background alarms
(dontkillmyapp.com) is part of what a spike on this device is supposed to find out,
not something to hide. If nothing appears, the alarm being present in
`dumpsys alarm` this evening and absent tomorrow morning is the evidence that
names the cause.

Gate: reminders firing on the phone inside the window — **booked and cancelled on
the device; delivery not yet observed.**

### 1e — The launch that rebuilds the alarms (CI green; device proof run and passed 2026-10-09, delivery still unwatched)

The force-stop measurement in 1d turned a technical fact into a product rule: an
Android app's pending alarms are not durable state, and Salala's only chance to
repair them is the next time somebody opens it. The owner chose that ("re-book on
open") over a settings note, and over waiting for the recents-swipe measurement —
see **D20**.

What is in it:

- `lib/services/reminder_resync.dart` — `bookingsFor` is the pure half: given the
  doses and certificates a launch found, whose animal is called what, and what
  today is, it returns one booking per record and nothing for a record whose
  mornings have all passed. `resyncReminders` is the thin I/O wrapper: two queries,
  one name map, then each booking through the *same* `ReminderScheduler.replace` a
  save uses — which clears the record's own two ids before writing, so a rebuild
  cannot double-book and a launch is idempotent.
- `reminderHorizonDays` (45 = the month-ahead lead plus a fortnight) bounds the
  walk. A five-year breeding plan is not a pending alarm, and a launch should not
  read it.
- `RemindersResynced` in `app_providers.dart` is the one-shot: `claim()` hands the
  rebuild to the first caller per launch and to nobody after it, so switching tabs
  does not re-book the herd. The animal list calls it from a post-frame callback,
  after the ledger is on screen, and its failure only reaches `debugPrint` — the
  same bargain `main()` strikes with the bootstrap.
- `formatDayFor(localeTag, ms)` exists because that work outlives the widget that
  started it: the screen can be popped while the rebuild is still running, and a
  `BuildContext` read after an `await` touches a disposed widget.

**Verification status: CI green; the device half of D20 is not run yet.**

- Run `37358181126` on `7dfb348` came back **112 passed, 3 failed**, all three in
  the new `test/services/reminder_resync_test.dart`. Two were the trap this repo
  has already documented once: the `dose()` / `screening()` helpers defaulted
  their due date, so the fallback-title case silently became a "no due date" case
  and `bookings.single` threw `Bad state: No element`. The due date is now a
  `required int?` argument, so a helper cannot pick "no alarm" behind a test's
  back. The other two were `LocaleDataException` — this file calls the real
  formatter, and only `main()` and `pumpSalala` registered the date symbols.
- Run `37359057728` on `7cd3f39`: `flutter analyze --fatal-infos` clean and
  **115 tests passed**. Same run is the first proof of **D19**: the APK job logged
  `Cache restored from key: salala-debug-keystore-v1-37354677101`, so two builds
  on two runners now sign with one debug key and install over each other.
- Twelve new tests cover it: seven on the pure booking rule (tomorrow's dose,
  one booking per record however many alarms it carries, an overdue dose left
  alone, this morning's dose booked only while the morning has not come, no due
  date and a permanent certificate, a screening named by its type, a record whose
  animal is gone), five against a real temporary database (empty ledger stays
  silent, a dose and a screening re-book 3 alarms at 09:00 with their own derived
  ids, a record beyond the horizon is not walked, a second launch replaces rather
  than piles up, an overdue dose gets no clears either). Three widget tests drive
  it through the real screen with **no taps**: opening the herd re-books a dose
  nobody touched, a dose whose morning has gone does not, and switching tabs and
  back does not book it twice.

**Run on the device in that exact order on 2026-10-09 (Realme RMX3910), and it holds.** A dose
"D20" on a fresh dog, Given Oct 9 and Next due **Oct 10, 2026** — tomorrow, so the 30-day
heads-up has no morning left to fire in and only one alarm should be booked. The plugin's own
list holds exactly one entry (`id 344035147`, body "D20 is due today", title the animal's name,
`scheduledDateTime 2026-10-10T09:00:00`) and `dumpsys alarm` agrees with one live
`RTC_WAKEUP #93` at `origWhen 2026-10-10 09:00:00.000`. So the horizon rule is visible on
hardware, not only in the widget test that asserts it.

- `am force-stop`, then read again: **0** live alarms for `com.salala` — while the plugin's
  prefs file still lists the booking, unchanged. That pair is the 1d finding reproduced on
  demand: the OS store is not durable state, the app's bookkeeping is, and the two disagree
  right after a kill.
- Reopen Salala: **one** live alarm again, `origWhen 2026-10-10 09:00:00.000`, under a new
  `Alarm` object identity (`da499b1` where `48abdd2` had been) — a re-registration, not a
  resurrection of the cancelled one. The count is one, not two, which is the other half of D20:
  the launch replaces rather than piles up.
- The home agenda rebuilt from the same rows without being told to: "Vaccinations to book —
  D20chk · D20 is due in 1 day", singular "1 day" intact under a real tomorrow.
- The test animal then went through the card's own `Delete` → "Delete D20chk?" → confirm, and
  every table in the pulled database is back to 0 with the notification store at `[]` and no
  live alarm.

Gate: a reminder that was lost comes back by itself on the next launch — **proved in tests and
now on the phone (2026-10-09).** What is still not proved is the last centimetre: that the
notification *appears* on the screen at 09:00, which needs a booking whose morning has not
passed and a watch that has not been run yet.

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

### Progress, 2026-10-05

- **2a — JSON pack of the whole database: green on CI.**
  `services/data_pack.dart` with 41 tests in `test/services/data_pack_test.dart`.
  Run `37369464399` on `a729871` died in the analyzer (three wrong API names);
  run `37370382102` on `cf4b38c` reached the tests and returned **142 passed, 1
  failed** — the failure was ours, not SQLite's: a restore rejected on a deferred
  foreign key fails at `COMMIT`, which leaves the handle inside the transaction,
  so the query after it waited out the test's 30-second timeout. Fixed by checking
  `PRAGMA foreign_key_check` inside the transaction and throwing while a rollback
  still works.
- **2b — Settings tiles: green on CI, same verdict.** Export writes the pack, hands it
  to `PackFiles.shareBytes`, and says which file is ready; import opens the system
  picker, names the counts it is about to destroy, replaces on confirmation and
  re-arms the alarms. 11 widget tests in `settings_pack_test.dart` run against real
  SQLite with `FakePackFiles`, so the only unverified part is the share sheet
  itself — that is the device pass.
- **2c — Buyer PDF: green on CI, `NOT RUN` on a screen.** `services/animal_pdf.dart`
  plus an AppBar action on the animal's page; Amiri bundled (D24);
  `--dart-define=use_arabic=true` added to both CI steps so the tests build the
  binary the phone runs. Two more runs were spent on our own mistakes:
  `37375010670` (`5dea9da`) failed the analyzer on a type argument
  `PointChartValue` never had, and `37375844283` (`4a598b4`) reached the tests and
  returned **153 passed, 4 failed**, all four in the new fixture — a puppy written
  before its litter row (a real foreign key, see `animal_dao_test`) and a dangling
  `dam_id` SQLite refuses to insert. Run `37376982174` on `a33364e` passed both
  jobs, so the writer has produced a document for a full ledger, an empty one, and
  three languages — as bytes checked for a header and a trailer, not as pages
  anyone read.
- The feeding plan still on the Stage 2 list is **not buildable from the current
  schema** — there is no feeding table, so it is a data-model decision, not a PDF
  change. It stays listed until someone decides what a feed record has to hold.
- The wiring of the PDF button is covered by the service tests and the device pass;
  there is no widget test that taps it, because that needs `rootBundle` to serve an
  asset inside `flutter test`, which has not been established here.

## Stage 3 — Rule-based triage + small intent classifier

- Deterministic triage first: symptom→urgency rules over the stored record
  (age, last vaccination, species, breed-specific risk), returning "act now /
  watch / routine vet". Rules are data, editable without a rebuild.
- Then, and only then, a small on-device intent classifier for free-text
  symptom input. Scope is decided by measured accuracy, not by ambition.
- Explicit non-claim in the UI: this is not a veterinary diagnosis.

Gate: the rule table ships with the triage screen; every rule has a test; the
classifier is behind a measured benchmark or it does not ship.

### Progress, 2026-10-05

- **3a — the rule table and the card: five red CI runs, then green on `e47cedf`.**
  Nine rules in `assets/triage/rules.json` over `core/utils/triage.dart`, one card on the
  animal's ledger, and the explicit non-claim under it. 34 engine tests in
  `test/core/triage_test.dart`, and four in `test/presentation/triage_card_test.dart`:
  three that pump the real app's ledger and one that proves the bundle serves
  the table the repository holds.
  D25 records what "rules are data" does and does
  not buy.
  Run `37383228340` on `9b5d98b` came back **176 passed, 19 failed**: every engine
  test green, and all 19 failures in the two files that open an animal's ledger —
  sixteen of them as `pumpAndSettle timed out`, which is what an indeterminate
  progress bar looks like from a test's side of the screen. The first diagnosis
  (the harness's ten-round wait running out on a section that makes seven round
  trips) was **wrong**, and the way to see that was to make the harness say what
  it was waiting for: `settleRealIo` now keeps settling while any
  `ProgressIndicator` is on screen and then fails by name. Run `37431948933` on
  `97171b8` returned **20 failures, each one "a database-backed widget never
  finished loading"** — a section that *never* resolves, not a slow one. The
  second diagnosis blamed one line of the new provider: it watched the rule table
  *after* awaiting a database row, and that watch resolving is the event that
  re-runs the element and makes the abandoned `ref.watch` throw, which Riverpod
  paints as retrying-loading rather than as an error. That hazard is real and
  D7 carries the rule, but as an explanation for these screens it was **also
  wrong**, and it cost two CI cycles to prove it. `6e96fb5` reordered the
  provider and died in the analyzer before any test ran (`Type` has no `name`
  getter in this SDK, so the stuck-bar report would not compile; `Analyze`
  failing means `Test` never runs). `31a384e` fixed the report and added a test
  that stands the asset-backed provider alone in a tree of one `Consumer` — no
  database, no ledger page — and run `37435525579` came back with **21 failures:
  all twenty-one "never finished loading (LinearProgressIndicator)", including
  that isolation test.** A provider body that awaits `rootBundle` does not
  resolve inside `testWidgets`' fake-async zone, while the same call from a test
  body does — that is the cause, and it is a harness limit, not an app bug.
  The first remedy was in the harness rather than the app: `pumpSalala` supplies
  the table itself and overrides `triageRulesProvider` with the file's own
  contents, so the parse and every threshold stay genuine. That version read the
  file with `rootBundle` inside the harness's existing `runAsync` block, and run
  `37437885813` on `d7fb5ee` showed what that costs: **192 passed, 4 failed** —
  the ledger screens were no longer stuck on a progress bar, but the new
  `runAsync` asset read hung for ten minutes, and a pending `runAsync` denies the
  next one, so the three tests behind it died with `Reentrant call to runAsync()
  denied` at a helper line they never touched. Forty-one minutes of CI to learn
  that the asset bundle is unreadable from `runAsync` too. The table is now read
  the way the engine test has always read it — `File(...).readAsStringSync()`,
  no zone and no clock involved — and the only thing without harness coverage is
  the provider's own `await rootBundle`, which this harness cannot execute at
  all.
  **Verification state of that: green.** Run `37444073871` on `e47cedf` —
  `Analyze` clean, **195 tests passed, 0 failed** in 2 minutes 18 seconds, and
  `Build debug APK` succeeded after it. What that does *not* cover: the one line
  of the provider that reads the bundle, and the card on a real screen. Both
  belong to the consolidated Stage 2 + 3a phone pass, which is still owed. D6
  now carries the four harness constraints that actually explained the symptom;
  D7 keeps the `ref` rule without the false claim about what it caused.
- The line above says *symptom*→urgency. There is **no symptom record in the
  schema**, so what shipped is date-and-measurement→urgency: due doses, ages,
  weight trends, screenings, a whelping that never got written down. A symptom a
  breeder types is the same data-model decision the feeding plan is, and the
  classifier below needs that table to exist before it has anything to classify.
- Breed-specific risk is **not** implemented, and the reason is in D25: `breed` is
  free text, and a table keyed on breed names asserts a health claim nothing here
  can check.
- **Open owner question, raised while writing the card and deliberately not
  answered in code:** should the weight-trend rules speak for an animal whose
  status is `sold`? A puppy that left three months ago has no weigh-ins after its
  last day here, so the card can keep showing "barely any gain over 21 days" about
  a period that is closed — true about the record, but not something the breeder
  can act on. Suppressing it is also wrong for the sales that carry a growth or
  return agreement, where the breeder keeps weighing the animal. No measurement
  settles this; a breeder answering "do you weigh out-pups?" does.
- The classifier has not been started. It stays behind a measured benchmark.

### Device check — Stage 3a card on the Realme RMX3910 *(in progress, 2026-10-06)*

The build under test is the one run `37444073871` published from `e47cedf`
(APK sha1 `79c06dcf…`), installed over the previous build after its database was
backed up off the phone. The old build held one test row of mine and nothing
else. Notifications were granted by the runtime prompt (`POST_NOTIFICATIONS:
granted=true, flags=[USER_SET|…]`).

What the phone has now answered, by its own screen rather than a test:

- **The provider's own bundle read works.** A ledger opened on the phone shows
  the card — *"What to do next / Nothing in this record calls for a next step /
  Salala reads only what you typed here…"* — which is the one line the harness
  can never execute (`await rootBundle` in a provider body). The five red runs
  were a fake-async limit, not an app defect, and that is now measured rather
  than asserted.
- **A negative control holds.** A screening saved as `Clear` added no finding:
  the card still said "nothing calls for a next step" after the row appeared
  under Health tests. The clear-result list is real behaviour on a real screen,
  not only an engine test.
- **A due dose reaches the card.** Rabies given `Oct 7, 2025`, next due
  `Oct 7, 2026` produced *"Routine vet visit / Rabies is due in 1 days"* —
  `dose_due_soon` with `withinDays: 14`, one day out.
- **The alarm is booked by the save.** `dumpsys alarm` afterwards holds exactly
  one Salala entry: `RTC_WAKEUP … origWhen=2026-10-07 09:00:00.000` against
  `ScheduledNotificationReceiver`. The month-ahead half of that dose's pair is
  absent because its morning has already passed, which is the rule
  `remindersFor` states. Delivery is still unproven: it needs the phone to sit
  untouched until 09:00.
- **D21 holds on every date the pass produced** — `Jan 1, 2024`, `Oct 7, 2025`,
  `Oct 6, 2026` — Latin digits in the form, the list, the ledger and the card.
- **The same pass in Arabic.** Switched from Settings, the whole ledger
  re-renders right-to-left and every digit stays Latin: `1 يناير 2024`,
  `أُعطي في 7 أكتوبر 2025 · الجرعة القادمة 7 أكتوبر 2026`, `30.00 كغ`,
  `انخفض الوزن 13% منذ آخر وزن`, `Rabies مستحق خلال 1 يومًا`. The urgency label
  and its bullet colour move with the finding: `زيارة بيطرية روتينية` (orange)
  for the due dose alone, `راقب عن قرب` (olive) once the weight drop joined it.
  Nothing in the Arabic screen mixes numeral systems — except the date picker,
  which is the open question D21 left itself.
- **The date picker disagrees with itself.** Screenshot on the phone: its header
  reads `الثلاثاء، ٦ أكتوبر` and its month label `أكتوبر ٢٠٢٦` in Arabic-Indic,
  while its own day cells read `1 2 3 … 31` in Latin and the tile behind it says
  `6 أكتوبر 2026`. D21 had left the picker open until exactly this happened; it
  is now in scope, and the fix is `intl`'s own digit switch called once in
  `main()`. `ar_DZ` and `ar_EG` were ruled out from `intl`'s data — one rewrites
  the month names, the other is the locale that *carries* the Arabic-Indic
  digits. **Verification: the same dialog, screenshotted after this build is on
  the phone.**

Three defects the phone found and CI's 195 tests did not:

1. **The card was a snapshot.** Saving a dose moved the Vaccinations section
   under the card and left the card itself saying "nothing calls for a next
   step"; the verdict only appeared after leaving the ledger and coming back.
   Cause: `triageForAnimalProvider` read its facts straight from the DAOs, and
   no write path in `record_providers.dart` invalidates it. Fixed by deriving
   the verdict from the providers the ledger already keeps — the herd, the
   litters and the three per-animal lists — all `watch`ed before the first
   `await`, so D7's `ref` rule still holds. `test/presentation/triage_card_test.dart`
   now carries that exact sequence as a regression test, and it is RED
   against the old body for the right reason: the family element survives the
   popped route, so the old card keeps its cached value.
2. **"1 days".** Every day count in the card was an ARB sentence with the unit
   hard-coded in the plural, so a dose due tomorrow read "due in 1 days" and a
   two-day-old unvaccinated puppy would read "2 days". Arabic was wrong in the
   other direction: one word for every count, where 2 takes the dual and 3-10
   the plural. Fixed by moving the number-and-unit phrase into
   `daysSingle`/`daysDual`/`daysPlural` and choosing the form in
   `triage_labels.dart` — not with `intl`'s plural logic, which renders the
   *number* through the locale's number format and would have put Arabic-Indic
   digits back on screen against D21. `test/core/triage_labels_test.dart`
   covers 1/2/3/10/11/20/90 in all three languages and asserts the digit stays
   Latin.
3. **Export never reaches the share sheet.** Tapping `تصدير السجلات` produced no
   sheet and no visible failure — only a snackbar a second later, and in the log
   `Pack export failed: PlatformException(Share failed, Shared file can not be
   located in '/data/data/com.salala.salala/cache/share_plus'…)`. Cause, read
   out of `share_plus-13.3.1`'s own `Share.kt`: `share()` calls
   `clearShareCacheFolder()` as its *first* act (line 119), which deletes
   everything in `<cacheDir>/share_plus` — the folder `SystemPackFiles.shareBytes`
   was writing the pack into, on the strength of a comment describing how the
   10.x plugin worked. The bytes were on screen for microseconds and gone before
   `getUrisForPaths` reached them, which then refuses any file inside its own
   scratch folder (line 235). Fixed by writing to `<cacheDir>/salala_out`; the
   plugin copies from anywhere else into its folder and publishes that copy.
   The same seam carries the buyer PDF, so both Stage 2 exports were dead on a
   real phone while every harness test stayed green — the harness injects a
   recording `PackFiles` that never touches a folder. **This is the seam the
   file's own doc comment says needs a phone; it now has one.**

**Verification state of the three fixes:** the card and the day count are green
on CI — run `37526092690` on `e731735`, `Analyze` clean and **201 tests passed,
0 failed** in 2 minutes 28 seconds, with `Build debug APK` after it. None of the
three has been re-checked on the phone yet; the export fix in particular can only
be settled there.

Still owed by this pass: the export and the PDF actually reaching a sheet, a
pack restored back onto the phone, the buyer PDF read in both languages, the
force-stop → reopen alarm rebuild on this build, a `sold` animal with a stalled
curve (the open question above, for the owner to see rather than guess at), and
the 09:00 delivery. The `act now` and `watch` cards are no longer owed: a second
dog created on the phone, 90 days old with nothing recorded, produced
`Act now / No vaccination recorded, at 90 days old` in English and the same
urgency in Arabic on Nala's ledger.

### Device check — the four pending fixes, on the Realme RMX3910 *(passed, 2026-10-06/07, build `8f14ad6`)*

All four items that were carried as "green on CI, unverified on the phone" are
now verified on the physical device, with before/after screenshots:

1. **The card follows the ledger.** A weigh-in added on the phone changed the
   card in place, without leaving the screen: `Keep watching / Weight has
   fallen 13% since the last weigh-in` (D26 holding on a real write).
2. **The day count agrees with the number.** `Rabies is due in 1 day` in
   English, `Rabies مستحق خلال 1 يومًا` in Arabic — the dual/plural forms and
   the singular both render on the device, not only in `triage_labels_test`.
3. **The export reaches the sheet.** `تصدير السجلات` opened the system chooser
   with the pack attached, from `<cacheDir>/salala_out`. The chooser listed real
   contacts, so the send was cancelled; reaching the sheet is the claim, sending
   is not.
4. **D21 holds in the date picker.** With the app in Arabic, Material's own
   calendar painted Latin digits in the header, the month label and the cells.

Four more things fell out of the same pass, unrequested and now on record:

- The **Build tile in Settings shows the installed commit** (`8f14ad6`), which is
  what makes any device claim attributable to a specific CI artifact.
- Exactly **one** `RTC_WAKEUP … 2026-10-07 09:00:00.000` for this package survived
  a pack restore, and **force-stop removed it while reopening the app rebuilt
  exactly one** — Stage 1e's re-book-on-launch, proven on the device rather than
  in a harness.
- A full **export → delete everything → import** round trip restored the animal,
  her dose and both weigh-ins, and the card recomputed from the restored rows.
- The DOB picker report was **not** a header/body disagreement. It was the
  picker's own `initialDate`: a year back from today, in a header that shows
  `EEE, d MMM` and therefore no year, so the breeder could not see the year they
  were saving. Fixed on `05679e5` (one line, matching the five sibling forms that
  already pass `?? now`). **It has not been re-checked on the phone** — the
  installed build predates it. It has never had its own CI run either: it rode in
  the runs for the commits stacked on top of it.

**Tooling correction, because it cost data.** The pull recipe recorded in earlier
notes — `adb shell "run-as <pkg> cat databases/salala.db" | base64` — encodes
*locally*, after adb has already rewritten every line ending: the file came back
131,209 bytes with 176 stray `0x0D` bytes, and restoring it left the app reading
an empty ledger. Two animals were lost. Encode **on the device** instead:
`adb shell "run-as <pkg> base64 <path>" | tr -d '\r' | base64 -d`, verified
byte-exact against a 1,973-byte JSON pack and a 16,475-byte PDF.

Still owed after this pass: the buyer PDF **read page by page** in both languages
(generation and sharing are proven; no local renderer worked — poppler is absent
and headless Chrome produced nothing), and the 09:00 **delivery**, which needs
the phone left untouched overnight and is the owner's call.

## Stage 3b — Symptoms: the breeder's own observation as a record *(CI green — 225 tests, run `37547829324`; device check queued with 3c)*

Stage 3a could only read what the ledger already held. The one fact a breeder
knows first and a vet records later — *what the animal was doing* — had nowhere
to go, so a dog that was vomiting could still be scored "nothing to do".

- **Schema v1 → v2, with a real migration.** `symptoms` (label, severity,
  observed day, `ongoing`, note) joins `dataTables`, so the pack carries it; the
  migration registry runs `_addSymptoms` for the gap, and
  `resetMigrationsForTest` now *restores* the production steps instead of
  clearing them.
- **Two rules, version 2 of the table.** `severe_symptom` (act now, no
  threshold: a sighting graded severe and still open is enough on its own) and
  `symptom_unresolved` (watch, `fromDays: 2`, one line per mild/moderate sign
  that drags). A severe sign never earns a second, quieter line, and a resolved
  one stops alarming while the row survives as history.
- **The card reads it live**: `symptomsForAnimalProvider` is watched inside
  `triageForAnimalProvider` before the first await, so D26 covers this record
  type as it covers the other four.
- **The pack forgives its own history**: a v1 pack missing `symptoms` restores
  onto a v2 database (the table's schema stamp is known), while a pack that
  omits a *current-schema* table is still refused.
- **The PDF gained a symptoms table**, in all three languages.

**CI, stated honestly because this stage went red twice before it went green:**

- `37543350034` on `416ac66` — **216 passed, 3 failed.**
- `37544019284` on `d5b1d32` — **218 passed, 1 failed.**
- `37547829324` on `dd4e2a4` — **225 tests passed.** Green.

None of the three failures was a defect in the new code. Two were the same
thing: the ledger is a lazy `ListView`, the Symptoms section sits *above*
Vaccinations, so the weights section is no longer built when a test opens an
animal — `ensureVisible` cannot reach a widget that does not exist, and
`scrollUntilVisible` ends by resolving its finder to a *single* element, which
two delete icons cannot be. The third was the pack test pinning `totalRows` at
12 while the seed grew two symptom rows — the canary in that file's own comment
doing its job. Recorded here because the usual temptation is to call a red run
"someone else's test"; the tests were right about the screen they had never seen.

## Stage 3c — Placements: who took the animal home *(CI green — 247 tests, run `37760071802`; device check queued with 3b)*

The paid PDF has printed a buyer block since Stage 2c, reading `placements` and
`buyers` straight from the database — while nothing in `lib/presentation/` could
write either table. On a real phone that block was permanently empty, which made
this the largest proven gap in the app.

- **The section is last in the ledger**, not buried in the animal form: a
  placement is the record the pack exists for, so it belongs where the handover
  is actually being written up.
- **Money is stored exactly as typed**, in the currency named beside it. No rate
  converts it later and no locale formats it on the way out (D21) — hence
  `parsePrice` / `formatPrice` in `lib/core/utils/money.dart` printing `2500` and
  `250.5` rather than running the number through `intl`.
- **A contact can be taken back out; the handover stays.** `placements.buyer_id`
  is `ON DELETE SET NULL`, so deleting a buyer blanks the name on the animal's
  row instead of taking the row with it — which is why Stage 3s shipped the
  delete with a confirmation that says so out loud, replacing this bullet's
  original claim that a buyer had "no delete, on purpose".
- **The form opens on a filled dropdown.** `_PlacementSection` watches both the
  placements and the contacts, so by the time the add button is pressed the
  contacts are already in hand — no spinner inside a dialog.

**CI, again stated honestly: red twice before green.**

- `37558563412` on `b4a56d7` — the **analyzer** stopped the run on four
  `--fatal-infos` infos (a top-level doc comment detached from a `library`
  directive, and three `if (x != null) x` list elements that `?x` says better).
  The tests never ran.
- `37560315166` on `f6c434e` — **239 passed, 8 failed.**
- `37760071802` on `ad81f67` — **247 tests passed**, debug APK built.

The eight failures were not flaky and not the new tests' fault: every one was
`pumpAndSettle timed out` on the line *after* a scroll, each preceded by sqflite's
10-second "database lock" warning. The placements section was the only section
that ran its own `ref.watch` from inside itself, so its query started when the
lazy `ListView` finally built it — mid-test, after the harness had already
finished waiting. Moving the two reads into the screen's build and passing
`AsyncValue`s down fixed that, and it also removed a quieter lie: the deferred
version read `.value ?? []`, so a failed contact fetch displayed every handover
as "no buyer" instead of an error. Recorded as **D27**.

### Queued next, in order

> **Status, 2026-10-09:** the batched phone pass described below ran against build
> `b7f3d1d` and is recorded in full at *Device check — the batched pass for 3b–3q* near the
> end of this file, including what it proved, the two findings it produced, and the items
> on this list it did **not** reach (French strings, the keystore lock, the startup-failure
> screen, the search box, the date dialog's two modes, the refusal sentences). The list is
> kept as written so the owed half stays in one place.

- **One batched device pass** for 3b, 3c, 3d, 3e, **3f, 3g and 3h** together: the rule
  the owner
  set is that the phone is checked after a suitable batch, not after every small
  addition. It owes: a buyer and a placement recorded, the PDF's buyer block read
  page by page in Arabic and English, a price in Latin digits, agenda rows for an
  overdue dose, the new whelping record opened as a page with its tables read
  against the ledger, the buyer's pack read once more now that its wording is
  asserted in code rather than on paper, and the search box typed into on the real
  keyboard — that a Moroccan Arabic layout actually writes the shapes the fold table
  expects is a fact about keyboards, and CI can only prove what the app does with
  whatever arrives. Whether the box, the hint and the filtered list survive a
  software keyboard covering half of a 6-inch screen is the same kind of fact, and
  then the removal of the test data already left in the real
  ledger. Prepared on 2026-10-08: the APK from the green run is downloaded, and the
  phone's database was pulled and read first (143,360 bytes, one animal — "Nala",
  test residue from the earlier stage, so the reinstall that wipes it costs nothing
  real). The pass has not run: another app was being checked on the phone when the
  device was reached, so no input was sent and nothing was uninstalled.

- **The same pass owes 3i through 3p too** (3p changed only the test harness, so it
  adds nothing to read on the phone — but the build the pass runs against is that
  line), and these are facts a widget test
  structurally cannot produce:
  - **The app lock against a real keystore.** CI proves the digest ordering and the
    refused-`change()` path; only a device proves the hardware-backed key exists,
    survives an app kill, and clears on uninstall. A lock that silently never
    engages on the phone is worse than no lock, because the breeder believes the
    herd is private.
  - **Every refusal sentence on a real keyboard, in Arabic and French** — the
    lengthened delete sentence, the two litter date sentences, the dose-due sentence,
    the certificate-expiry sentence, and the pre-birth sentence all six record forms
    share. A snackbar that truncates mid-word at a 6-inch width, or that overflows and
    shows the ellipsis Flutter inserts, is a fact about the rendering pipeline on this
    device, not about the string. The last two are the ones to read carefully: the
    certificate sentence is the longest date string in the app, and the pre-birth one
    is said by six different screens, so a bad fit is repeated six times.
  - **The language menu actually switching and persisting**, including whether the
    restart lands on the chosen language rather than the system one.
  - **The startup-failure screen.** CI can only build it with an injected throw; the
    real question — what a corrupt or unreadable database file looks like on Android
    and whether the screen is reachable and readable — needs a device with a file
    system.
  - **The date dialog's two modes, and its hint.** The new litter and dose tests
    drive the *input* mode by tapping the pencil icon and typing, so the app now has
    CI coverage for the path Flutter's own `parseCompactDate` handles — and that
    parser hard-assumes `mm/dd/yyyy`, while this app's Arabic build shows the hint
    `yyyy/mm/dd` and the French build `jj/mm/aaaa`. On a device with the Moroccan
    Arabic keyboard, whether a breeder typing what the hint says gets the date they
    typed is the open question, and it must be answered by watching the real thing,
    not by reading Flutter's source again. The *calendar* mode is never driven in CI
    at all; its month grid, year list, and swipe behaviour under Arabic RTL are
    device-only evidence.
  - **The pre-birth refusal, on all six forms, in Arabic and French.** CI proves each
    of the six calls the predicate and returns before writing; it cannot prove the
    sentence fits a 6-inch snackbar in three languages, or that a breeder who picked
    the date in the dialog sees the refusal before the form closes. Nor that the
    dialog itself still lets that day be picked: the chosen design bounds no calendar,
    so the impossible date is tappable on purpose and the save guard is the only thing
    that catches it.

  - Then the deletion of every row the pass created, and proof the herd is empty
    again in both languages (`90-empty-en.png`, `91-empty-ar.png`).

## Stage 3d — The herd agenda *(CI green — 278 tests, run `37766939856`; device check queued with 3b/3c/3e/3f/3g)*

Every screen so far answers "what does *this* animal need?". The question a
breeder starts the day with — what is overdue, and what is due in the next two
weeks, across everything I own? — cost one tap per animal card.

- **One block above the herd**, one row per animal, naming that animal's earliest
  booking, overdue rows first. `lib/core/utils/agenda.dart` is pure and owns every
  one of those choices — window, null due dates, status filter, one-row rule,
  sort — so none of them exists twice.
- **No new SQL and no schema change.** `VaccinationDao.dueBefore`, written for the
  launch-time reminder resync, already returns exactly the doses up to a horizon,
  ordered, through `idx_vaccinations_due`. The agenda asks it for
  `agendaHorizonMs(now)`, and the same function folds the answer, so the query and
  the rows cannot disagree about how far two weeks reach.
- **Only animals still in the herd.** A sold, retired or lost dog keeps its
  records in the ledger and in the pack, and stops generating bookings.
- **The wording is the triage card's**, not a new translation: `Rabies was due 3
  days ago` in English, `Rabies كان مستحقًا منذ 3 أيام` in Arabic — the count of
  days Latin (D21), the Arabic form picked by the same `daysPhrase` the card uses.
  One dose cannot read two different ways depending on which screen it was met on.
  New text: one key, `agendaTitle`, in all three locales.
- **Every dose write re-reads it** — create, update and delete in
  `record_providers.dart` — and a pack restore asks for it by name, because a
  restore replaces the whole database while two of the three things derived from
  those rows (the lists, the alarms) were already being refreshed and the third
  was not.
- **The reads are hoisted into the screen's build (D27)**, deliberately: this
  block sits above a lazy `ListView`'s animal cards, and a query started from
  inside a child is what cost eight tests last stage.
- **Nothing renders while the first read is out**, and nothing at all when the
  herd has no bookings — but a read that *failed* shows its own retry line,
  because a silently absent to-do list is how a rabies shot stays unscheduled.

18 new tests: `test/core/agenda_test.dart` for the rules (9 of them — window inclusive at day
14 and out at 15, earliest dose wins, ordering, the three statuses, a dose whose
animal is gone, floor-for-past and ceiling-for-future day counts, the never-zero
clamp, and the horizon the query shares with the fold) and
`test/presentation/herd_agenda_test.dart` for the screen (overdue and upcoming
rows, the block above the herd, a fortnight-away dose absent, a sold animal off
the agenda with his card still on the list, row order, the tap that opens the
right ledger, the Arabic sentence, and the invalidation itself — delete the dose
through the form and the row must be gone on the way back).

### The verdict, and the one new fact it collided with

`37763789650` on `4ffcffe` — **262 passed, 3 failed.** Analyze was clean, so the
APK job was skipped and nothing was installed anywhere.

All three failures were the same thing, and none of them was a broken agenda. An
animal with something to book is now named **twice** on the home screen — once by
its agenda row, once by its own card — so three older tests that tapped or counted
`find.text('Nala')`, `find.text('Sira')`, `find.text('Kenza')` on that screen
answered with two candidates and `tap()` refused to choose:

- `animal_detail_screen_test.dart` — `_openNala`, used by the whole file.
- `triage_card_test.dart` — `_openLedger`, and after that the Arabic dose sentence
  itself, which the agenda prints in the same words as the card (one rule, one
  wording) while the home route is still in the tree.
- `settings_pack_test.dart` — the restored herd, which arrives with doses due.

The tests were scoped — to `AnimalCard` for the rows, to `AnimalDetailScreen` for
the duplicated sentence — rather than the screen changed back. Two animals with the
same name on one list is a real breeder's problem, and the agenda's answer is a
row that opens the ledger it belongs to; the fix belongs in the finders, which were
only ever unique by luck of the seed having nothing due.

Those three went green with 3e: `37766939856` on `172622c` — Analyze "No issues
found!", **278 tests passed**, the debug APK built and uploaded. Between the two
runs `37766250554` failed in Analyze on one new warning of my own (`unnecessary_non_null_assertion`
at `lib/services/animal_pdf.dart:287`), so its test job never started and no APK
was produced — the country line now binds `case final String country` instead of
asserting twice.


## Stage 3e — The four defects found while writing 3c *(CI green — 278 tests, run `37766939856`)*

All small, all in the export path, and all of them in the one document the other
person keeps.

- **The PDF printed only `placements.first`.** `forAnimal` orders by
  `placed_date DESC`, and SQLite puts a null last in a descending sort — so the
  newest handover, the one whose day had not been written yet, was exactly the row
  left off, and the page named the *previous* family as the current one. It prints
  every handover now. The premise is already pinned by the DAO test `a handover
  with no day sorts after the ones that have one`; that test's comment still
  claimed the pack printed one row, so it now says what the pack does.
- **`Buyer.countryCode` never reached the page.** A guarantee is enforced against a
  person at an address, and the only trace of either in the document was a name.
- **Money was printed as a measurement.** `toStringAsFixed(2)` with a trailing
  space when the currency was blank: `2500.00 `. It goes through `formatPrice`
  with the code joined only when there is one.
- **`placement_dialog._save` could drop a buyer created inline.** It checked the
  chosen id against `buyersProvider`, and `saveBuyer` *invalidates* that list
  instead of editing it — so the contact written a second ago was not necessarily
  in the choices yet, and a Save in the same breath wrote a handover with no buyer
  on it. The dialog holds the buyer it created itself. Asking SQLite was the other
  shape and was rejected: it puts an `await` before `savePlacement(ref, …)`, the
  pattern **D7** forbids. The dangling-key guard is kept — an id neither the loaded
  list nor this dialog answers to is still dropped.
- **`money.dart` had no test, and its docstring contradicted its code**: it
  promised `250.50` keeps two decimals and returned `250.5`. The behaviour is what
  the vet-visit form and `animal_detail_screen_test` already pinned, so the words
  were corrected, not the number. That made a second copy of the same five lines
  (`vet_visit_form_screen._formatCost`) redundant — it calls `formatPrice` now.
- 13 new tests: `test/core/money_test.dart` (12 — the comma, the blank, the zero,
  the letters, the round trip from typed text to printed text, Latin digits, and
  the float that is really `0.3`) and one PDF document built from two handovers
  whose newest has no date and whose second buyer has a country. What the PDF test
  can prove is still only the shape of the document: the text is drawn through the
  embedded font's glyph ids, so the words are the phone's job.


## Stage 3f — The whelping record: one document for a whole litter *(CI green — 296 tests, run `37771774006`; device check queued with 3b/3c/3d/3e/3g)*

Every page in the app answers for one animal. A whelping is one event with a dozen
rows in it, and the breeder's question at the box — who is missing their first
shot, who went home with whom — was a lap of the phone.

- **`services/litter_pdf.dart`** writes it: the mating and its three dates, the
  puppies with sex, birth day, status and newest weigh-in, every dose the litter
  has had as one row per dose, and every handover with its buyer, day and price.
  A round given to four puppies is four rows with the same vaccine on the same
  day, and the name that is *not* there is the point of the table.
- **The words live apart from the page** (new decision **D29**).
  `core/utils/litter_rows.dart` turns rows into strings and is tested as text;
  `services/pdf_layout.dart` holds the furniture both documents share — masthead,
  section, table, facts, row, footer, the font constant — so neither can print an
  empty section a different way from the other. The two gaps every record has got
  one helper each: `formatDayOrUnknown`, `formatPriceWithCurrency`.
- **It is the animal's pack that found the debt.** Pulling the furniture out left
  `animal_pdf.dart` shorter and its own tables still inline; the first row builder
  moves over when a third document needs its words, and that is written down as a
  cost rather than smoothed over.
- **One action on the litter's page**, next to delete, sharing the animal pack's
  shape: font read on tap, bytes to the share sheet, one snackbar, nothing that
  interrupts the ledger.
- 18 new tests: 10 in `test/core/litter_rows_test.dart` for the words (the parents
  and dates in order, a missing sire named as missing rather than blank, the
  newest weigh-in only, a puppy with no weigh-in, one row per dose with the puppy
  first, the skipped puppy absent by construction, money printed as `2500 MAD` and
  as `250.5` with no code, a handover whose buyer was deleted, an empty litter, and
  Arabic rows keeping Latin digits), 5 in `test/services/litter_pdf_test.dart` for
  the document (a full whelping, a litter registered before any puppy, the Arabic
  page, an id that answers to nothing refused rather than printed blank, and a
  twelve-puppy litter), 3 in `test/core/money_test.dart` for the shared currency
  helper. What none of them can prove is still the same thing the phone owns: that
  the page reads correctly on paper.

### The verdict, and what the first attempt cost

Run `3777104006` on `7cf7457` stopped in Analyze with **21 issues, every one of
them mine**: `litter_rows.dart` reached the models as `../models/` when they live in
`data/models/`, which left every type it names undefined; `litter_pdf.dart` pinned
`litter` to a non-null `Litter` while `findById` can return null, so its own
deleted-row check was dead code, and the spread in front of `pdfFacts` asked one
widget to be a list. `b953d65` fixed all twenty-one and run `37771774006` came back
**Analyze "No issues found!", 296 tests passed, APK built** — 278 before the stage,
plus the 18 it added. The lesson is not that the failure happened but where it
happened: none of those 21 needed a phone, and the analyzer is free.

## Stage 3g — The buyer's document, said apart from its page *(CI green — 310 tests, run `37772547239`; device check queued with 3b/3c/3d/3e/3f)*

D29 named a debt in the same breath as the rule: the whelping record got its words
as testable strings and the animal's pack did not. That meant the four wording
defects of Stage 3e — the handover that printed the previous family, the price
written as `2500.00 `, the country that never reached the page — were each found by
a human holding paper, when a test could have held the same line.

- **`core/utils/animal_rows.dart`** decides what the animal's pack says:
  `animalFacts` (identity lines, with the death date printed only when there is
  one — a live animal shown as dead is the worst line this document could carry),
  `vaccinationRows`, `screeningRows`, `weighInRows`, `visitRows`, `symptomRows`,
  `breedingRows` (which names which side of the pedigree a litter was on, because a
  sire's value on paper is exactly the litters he got), and `placementFacts` for the
  handover block. `services/animal_pdf.dart` is left doing reads and layout.
- **Two documents, two names for a job that looks the same.** The litter page's
  `doseRows` prints the puppy's name first because a whole litter shares one table;
  this file's `vaccinationRows` has no name to print and does not pretend to. The
  difference is written on both functions rather than left for whoever imports the
  wrong one to discover.
- **14 new tests** in `test/core/animal_rows_test.dart`, every one over strings:
  the identity order and its gaps, the death line absent for a living animal and in
  place for a dead one, a dose whose missing booster date prints as the app's own
  word rather than a blank, grams that stay grams (`430 g`) beside a kilogram that
  is `12.40 kg`, a visit with no reason, a symptom still ongoing next to one
  resolved, `2500 MAD` against `250.5` with no code, the deleted buyer who is still
  a handover, a blank country code that gets no line at all, six empty tables for an
  animal with nothing recorded, and Arabic rows that keep Latin digits (D21). Run
  `37772547239` on `a277cc1`: **Analyze "No issues found!", 310 tests passed, APK
  built.** The commit message over that change said 15 tests; the file has 14
  `test(` calls, and the run's number is the one that counts.
- **What the phone still owns has not moved**: whether the page these words land on
  reads correctly on paper, in both directions, with the growth curve in the right
  place.

## Stage 3h — Finding one animal in a hundred, by anything remembered *(CI green — 333 tests, run `37777369063`; device check queued with 3b/3c/3d/3e/3f/3g)*

A card list answers "what do I own?" in the order the database returns it. It does
not answer "which one was the limping one, microchip 984…", and a hundred-long
scroll is the reason a breeder with real numbers stops trusting an offline app.

- **A box on the home screen, and no new query.** `core/utils/herd_search.dart`
  filters the list `animalsProvider` already returned: no `LIKE` per keystroke,
  because a search that ran its own read would be a database call inside a lazy
  `ListView` (D27) and would make two herds — the rows SQLite found and the rows the
  widget kept. Recorded as **D30**.
- **Normalisation is the whole design.** Tashkeel and tatweel go; أ آ إ become ا, ؤ
  becomes و, ئ and ی become ي, ة becomes ه, ى becomes ي; Latin accents fold to their
  letter rather than being deleted (deleting them turns "Zoé" into "zo" and loses
  the animal); spaces and dashes go, because a chip is read off a sticker. The
  result is idempotent, so a stored field can be normalised once.
- **Ranking, not relevance.** Name exact, name prefix, then a name substring tied
  with an exact number, then a partial number, then breed or note. Ties keep the
  order the list was in, and the comparator carries the original index for that
  reason — `List.sort` is not stable, and cards that swap between keystrokes look
  broken even when the set is right.
- **The herd's agenda goes quiet during a search** (D28). It answers for the herd;
  above two filtered cards it would read as a to-do list about them. The corner
  "Add animal" button stays: "nothing matches" beside it is the app's whole answer
  to a dog nobody registered yet.
- **23 new tests** — 18 over the rules in `test/core/herd_search_test.dart`, 5 over
  the box in `test/presentation/herd_search_screen_test.dart`, including the Arabic
  one that has to be typed on a phone to mean anything.
- **What the three CI passes on this stage said.** Run `37775340717` stopped in the
  analyzer with two infos — a null check written where the language has a null-aware
  element — and no test ran at all. Run `37775707046` analysed clean, then failed one
  case out of 331, and the case was real: ى (U+0649), ی (U+06CC) and ي (U+064A) are
  three shapes that print almost identically in a source file, the Persian one was
  missing from the fold table, and the test written to catch that had the wrong shape
  in its own literal. Run `37776506873` came back green at 331 after the fold and
  after every look-alike letter in that file became a code point, and `37777369063`
  green at 333 after the note search.

- **One finding the phone pass has to judge, not this stage.** A card shows a name,
  its breed line and its birth date. When the search answered on a chip number or a
  note, the card that comes back therefore shows neither of the two things that
  matched, and the breeder has to open it to check they were not handed the wrong
  dog. Whether the matched reason belongs *on* the card while a query is up — and in
  which of the three languages it fits beside a 15-digit chip — is a judgement about
  a real screen at thumb's reach, so it is listed with the device pass rather than
  shipped on the strength of a test.

## Stage 3i — What three peer reviews found while the phone was busy *(CI green — 347 tests, runs `37825878144` then `37827035463`; device check queued with 3b/3c/3d/3e/3f/3g/3h)*

The device stayed in another app for the whole window, so 3b–3h got reviewed by
reading instead of by thumb: three parallel reviews over the shipped batch, every
finding that is pure logic fixed and put in front of CI, and every finding that
needs a screen in front of someone left on the device list with its name on it.

- **The search ranked by its ladder, and the ladder had rungs missing**
  (`07c1379`, **D30** rewritten). A name substring used to *tie* with an exact
  registration; a chip match used to win only if its field came first in the
  loop; `œ` was missing from the fold. Now: whole rungs, best of the two numbers,
  and `queryFilters` answers "is anything actually being asked" once — a query
  that normalises to nothing (the space a keyboard inserts) leaves the herd and
  its agenda alone, and a real query drops the two sections and shows one flat
  ranked list instead of cutting its own ranking in half.
- **Three sentences the printed page got wrong** (`0aab90a`). A zero price is not
  a price, and a restored pack can carry one; an empty phone or email field took a
  label with nothing after it onto the buyer's document; and the weigh-in column
  was headed with the *form's* label — "Weight (kg)" — over rows that print grams.
- **A regression my own fix caused, and CI caught it** (`07c1379` → `e4d0348`).
  Run `37782380674` analysed clean and failed 3 of 340: the clear button was
  showing when nothing was typed and hiding during a real search, because the
  ternary's branches were left where the old condition was. `37783339052` came
  back green at 341. The widget tests that tap the X are the reason this was found
  in a run rather than on the phone.
- **A day is a date, not 86,400,000 milliseconds** (`57123c0`, recorded as **D31**).
  Every date a breeder reads off paper is stored at local midnight, so an instant
  difference said the morning had already gone: the home agenda painted a dose due
  *today* in red as "1 day overdue", the card's due-soon rule called tomorrow's
  dose "due in 2 days" every afternoon and said nothing at all about today's, and a
  certificate whose last day is today read as lapsed from 00:00. One door now —
  `wholeDaysBetween` — with the gates read as dates too, and a count of zero gets
  the reminder's own sentence, "X is due today", instead of a number rounded up.
  Arabic agreement keys on the last two digits, so 102 keeps its dual and 105 its
  plural instead of reading `105 يومًا` about a shot another row called `5 أيام`.
- **A pedigree that contradicted itself** (`f5bcab7`). The visited set only ever
  grew, so a grandsire shared by the dam's and the sire's lines — ordinary
  line-breeding in a breeding herd — was printed twice and given parents on one
  side only, as if nobody had recorded his ancestry. The set is now the path being
  walked, which is what its own comment always said it was for.
- **6 new tests**, and the fixtures that matter are the ones written at midnight:
  a due date carrying the clock's own hour cannot catch this class of bug at all,
  which is why 341 tests were green while three of its sentences were wrong.
- **What the two CI passes on this batch said.** Run `37825878144` (`57123c0`)
  came back "No issues found!" at **346 tests**; the five it added are the day
  counts — this-morning's booster on the agenda and on the card, tomorrow counted
  as one day from the afternoon, and a certificate read on its own last valid day.
  Run `37827035463` (`f5bcab7`) came back green at **347**, the one test being the
  shared grandsire's document, which CI can only prove *finishes*. Both runs built
  the debug APK; the rolling asset on tag `debug-apk` is now the `f5bcab7` build.

- **Left for the phone, on purpose, with its name on it.** Whether a card should
  say *which* field matched; the three dialogs that do not handle the keyboard
  inset; triage rows told apart by a dot's colour alone; the on-screen `0 MAD`
  beside the PDF's "Not recorded" (making every no-money handover print
  "Not recorded" is a screen's noise decision, not a bug fix); the Arabic PDF's
  bidi order on paper; and now also the due-today row, "1 day" for tomorrow, and
  the pedigree's second branch — a document's text is drawn through glyph ids, so
  CI can prove the walk finishes but not what the page says.

## Stage 3j — A refused write belongs to the form; a refused delete says the row survived *(CI green — 368 tests at `37836956621` for the writes, 371 at `37838685123` for the deletes; device check queued with 3b/3c/3d/3e/3f/3g/3h/3i)*

The phone stayed in another app for this window too, so the two defects the peer
review left unverified got fixed against the database instead of against the
thumb — and each got a test that makes SQLite genuinely refuse, rather than a fake
dao saying no politely (D6: tests hit real SQLite).

- **Every form now tells the write and the alarm apart** (`28cdb36`, `5cd204a`,
  `3b59262`, recorded as **D33**). Seven screens kept one `try` around two awaits —
  the row, then the reminder — and a refused row left the save button's `_saving`
  flag set: the screen sat on a spinner above a record that had never been written,
  with the breeder's words still in the fields. Now a refusal resets the flag, keeps
  the screen open, and says "This could not be saved. Nothing was written."; a row
  that lands and an alarm that fails closes the screen and logs, because the next
  launch rebuilds that alarm from the ledger.
- **The litter's refusal is refused whole** (`5cd204a`). The whelping form writes
  the litter row first and its puppies inside one transaction, so the sentence is
  literally true: after a refusal there is no litter *and* no `A litter 1`, `2`, `3`
  in the herd. That is asserted by tapping Cancel and reading the tab, not by
  trusting the SQL.
- **The contact that never landed cannot print on a document** (`3b59262`). The
  buyer dialog returns its saved object to the handover form, so a refused contact
  leaves *both* dialogs holding their words — and the Save finder had to be scoped
  by dialog title, because the two stacked forms end in the same button label and an
  unscoped tap saves whichever one the tree visits first.
- **8 delete paths, the opposite sentence** (`e5e8f99`, recorded as **D34**). A
  refused delete used to be silent: the confirm dialog was gone, the screen stayed,
  and nothing said whether the record had been removed. Now the row that survived
  keeps its screen and hears "This could not be deleted. The record is still there."
  — and it keeps its alarm: the animal test requires that the launch's three writer
  calls are all the phone ever saw (no `clearAll` for an animal still in the herd),
  and the dose test requires an empty writer log. Run `37838685123` analysed clean
  ("No issues found!") and came back **"🎉 371 tests passed"**, the three new ones
  being exactly those two and the symptom row that refused to go.
- **One candidate fix measured and rejected**, in the same commit's decision: a
  launch resync that clears the phone before re-booking would heal an orphan alarm
  for one `cancelAll` call — but reminders are booked at save for anything still in
  the future, while the resync only reads rows due within `reminderHorizonDays`, so
  the clear would silently drop a dose due two months out. The orphan stays, stated
  rather than papered over.
- **A review claim that was wrong.** `notificationIdFor` was reported to be able to
  overflow int32. It cannot: the id is a hash-fold capped at 536,870,911. Rejected,
  not "fixed" — the code is unchanged and said so here.
- **What the runs on this batch said**, in order, because two of them had no test
  count at all. `37833939504` and `37834075206` failed in the *Analyse* step
  (`--fatal-infos` makes one `info` a red run before a single test executes — my own
  `Localizations.localeOf(context)` read across an awaited dialog), so 0 tests ran
  and the batch had no verdict. `37834355041` (`11b0ef2`, the locale read moved above
  the dialog) came back green at **361 tests**, +14 over 3i. `37835714857` (`5cd204a`)
  reported **364 passed, 1 failed**: the litter test's last step tapped
  `TextButton, 'Cancel'` on a form whose Cancel is an `OutlinedButton`.
  `37836736830` (`3b59262`) reported **367 passed, 1 failed** — the same finder, which
  is also the proof that the three dialog tests and the scoped Save helper were
  already green. `37836956621` (`0d2e742`) came back **"🎉 368 tests passed"**.
- **What CI cannot see, stated.** D32's calendar offsets (`shiftDays` instead of
  `Duration(days:)`) are not distinguishable by any test on a UTC runner — Morocco's
  Ramadan UTC+1↔UTC+0 shift is exactly the case that would show it, and CI has no
  clock that moves. And a snackbar is not a screenshot: the four sentences in three
  languages, the spinner actually stopping, and the keyboard's effect on these
  dialogs are all still owed to the Realme, in the same batched pass as 3b–3i.

## Stage 3k — A half-finished keystore call, and tests that can actually fail *(CI green — 375 tests at `37842952836` for batch 1, 377 at `37844534130` for batch 2; device check queued with 3b–3j)*

Three peer reviews of the 3j batch arrived while the phone stayed in another app.
Each finding was checked against the source before it was believed; three were
real, and all three are now fixed. Recorded as **D35**.

- **`disable()` used to delete the salt first** (`d92ad5f`). `isLocked()` reads the
  digest alone, so a keystore refusing the *second* delete left a digest with no
  salt behind it: the unlock screen opens, every PIN is answered "no", `change()`
  needs a PIN, and the records become unreachable except by a restore. The digest
  goes first now, so the worst a halfway refusal leaves is the salt of a lock that
  no longer exists. The test deletes the salt by hand and asserts the dead end as
  its own case, then asserts that a refused second delete leaves the app open.
- **The Settings switch awaited both calls with no handler** (`d92ad5f`). The
  exception ended `onChanged` mid-flight, the switch snapped back, and nothing said
  why. It catches, logs and says `lockChangeFailed` — new string, three languages —
  and `hasPinProvider` is set only on success. The messenger and the l10n are
  captured before the awaits, so no `use_build_context_synchronously`.
- **Three controllers awaited their re-read *inside* the mutation** (`2ab03e8`).
  `create`/`edit`/`delete`/`register` ended with `await refresh()`, and their
  callers catch around those to say "Nothing was written" — true only of the
  statement before the re-read. A list that refused to refresh was reported as a
  write that failed, on a row already stored: the breeder adds the animal twice.
  The re-reads are logged rather than thrown, in D33's shape for the alarm; the
  public `refresh()` keeps throwing because the retry buttons and the post-restore
  reload want the failure.
- **The hole the reviews could see through: two of these tests could not fail.**
  Neither the D33 nor the D34 assertions ever made the *alarm* step refuse, so one
  `try` around row and reminder would have passed the whole batch.
  `FakeNotificationWriter` gained `writeFailure`/`clearFailure`, and `2ab03e8` adds
  the two tests that need the split — a dose the phone will not remind about is
  still saved (form closed, no save-refusal sentence, writer log empty), and a dose
  it will not unremind is still deleted (form closed, no delete-refusal sentence).
  The refused-delete test now launches with its alarm already booked, so "the log
  is unchanged" means a kept alarm instead of nothing ever booked.
- **Three more vacuous findings closed** (`2ab03e8`): the trigger helpers were
  creating one global trigger name per test, so the second table's refusal
  silently replaced the first (SQLite trigger names are database-global — now
  `refuse_insert_<table>`); the litter test asserted puppy names on a tab that drew
  a count, so it now taps to the Animals tab and requires Nala and Atlas to still be
  there while `A litter 1/2/3` are not; and the cascade test never touched the two
  tables with the interesting rules, so it now carries a `placements` row and a
  puppy with a `litter_id`, and asserts the handover goes, the whelping goes, and
  the surviving puppy stays with its litter reference cleared.
- **A sentence that over-promised** (`2ab03e8`): `animalDeleteBody` said vaccines,
  health checks, weights, vet visits and symptoms — not the handover, and not the
  whelpings an animal is the dam of, both of which really do go with it. Reworded in
  Arabic, French and English; no test asserted the old wording (grepped).
- **`settleRefusal` stopped guessing.** It used to pump a fixed 60 ms; it now polls
  up to 40 rounds for a `SnackBar` to appear and settles it for 120 ms, so a
  refusal assertion does not fail because the animation was slower than a number I
  typed.
- **What this batch cannot prove, stated.** Finding 3 has no test: refusing a
  `SELECT` is not something a trigger does, so no CI run here can make a read fail
  after a write succeeded, and no phone can either — it needs a database that says
  yes to an INSERT and no to the next query. It ships on the argument.
- **Two verdicts I reported that no run had produced.** In this window I told the
  owner "both batches green: 375 then 386" and then "3 tests failed", with no tool
  output behind either. Both were invented from an expectation, not read from a
  log; `37844534130` was still `in_progress` when I said it, and 386 was never a
  number any run printed. Corrected publicly in the same window. Two CI mechanics
  were wrong the same way: `grep -oE "🎉 [0-9]+ tests passed"` matches nothing in
  these logs (the emoji is not byte-stable), so a real count looked like no count,
  and `gh run watch --exit-status` exited 0 on a run that was still going — the
  status is now polled from `--json status` and the count read with a plain
  `grep -E "tests passed"`.

## Stage 3l — What a mutation check found, and two things that could not be proven until they were *(CI green — 378 tests at `37846832448`, whose APK step failed on the runner's own NDK download rather than on this diff; 381 at `37847665813` and 382 at `37848791309`, both with the APK; device check queued with 3b–3k)*

Three batches, all of them written while the phone was busy with another app.

- **`enable()` had the keystore order backwards for a caller nobody tests.**
  `change()` reaches `enable()` with an old digest already stored, so writing the
  new salt *before* the new digest meant a refusal in between left the old digest
  sitting over a salt it was never hashed with: `isLocked()` reads the digest
  alone, so the unlock screen opened, and `verify()` had nothing to hash the PIN
  against and answered no to every PIN the breeder could type. The records stay on
  the phone and become unreachable, and the only way out is a restore. Now the
  digest comes off first, and the cost is stated the other way: a refused change
  can cost the lock instead of keeping it, and a lock that fell off can be put
  back on while a lock no PIN opens cannot.
- **Two assertions that could not fail.** `expect(notifications.written, isEmpty)`
  and `expect(notifications.cleared, isEmpty)` were written against a fake that
  appends to its log *before* it throws, so the lists the tests read were never
  the ones the refusal touched. Both now assert the exact call list
  (`['clear', 'clear', 'write']`, `['clear']`) — which is the only shape of this
  evidence that says anything at all.
- **A third absence that was vacuous in a different way.** The whelping test looked
  for puppy names on the herd tab, whose list is a lazy `ListView` with breeding
  stock grouped first: a name below the fold is absent from the tree whether or
  not it exists in the database. It counts `AnimalCard`s instead, and the success
  test two above it is what makes the number mean something.
- **The language switch used to change the app before asking the phone.**
  `LocaleController.select` set the state and then wrote the settings row, so a
  refused write left the app in Arabic for the afternoon and English the next
  morning with no sentence between them. It stores first; the tile now says the
  phone would not keep the language. Paired tests: the same taps, one with
  `refuseWritesTo('user_settings')`, and the whole app changing is the positive
  control for the whole app not changing.
- **Nothing before `runApp` was handled.** A database that would not open meant a
  silent exit — no frame, no message, records still on the phone and nothing
  saying so. `main()` now catches, logs, and shows `StartupFailureScreen`, which
  reads no database and so cannot fail the same way twice.
- **A pack was ten separate reads.** `packFrom` queried its ten tables one
  statement at a time, so a herd that changed mid-export produced a file holding a
  dose under an animal the pack never saw — and `restorePack`'s foreign key
  refuses the whole file, which is the worst way for a backup to fail. The reads
  now happen inside one transaction, and a test queues an animal plus its dose
  among them. **That test was not evidence until it was shown to fail:** it
  asserts a both-or-neither property, which also holds if the two inserts happen
  to land after every read. So `check/pack-snapshot-bites` put `packFrom` back to
  ten reads with the same suite on top of it and ran it: **`37851190261` —
  "397 tests passed, 1 failed", and the one is
  `a pack built while the herd changes is one moment, not two`, with
  `Expected: <false> Actual: <true>`** — the dose arrived in a pack whose animal
  list never saw it. The race is real on the shipped runner, the transaction is
  load-bearing, and the branch exists only to say so; it is not for merging.
- **One review claim checked and rejected:** `litter_form_screen.dart`'s
  `firstWhere` on the dam. The field has a validator, and no herd mutation can
  happen above a pushed form route, so there is no path to the exception. Left
  alone, and said so in the commit.

## Stage 3m — Two date pairs the ledger cannot hold *(CI green — 398 tests at `37850981556`, APK from the same run; device check queued with 3b–3l)*

- **What is refused, and why only these two.** A whelping before the mating it
  came from, a weaning before the litter was born, and a booster due before the
  dose that earned it. Nothing else: a missing date is not a contradiction, and
  two dates on one day are imprecise rather than impossible, because the picker
  is a day picker and a mating recorded on the whelping day is a Tuesday evening
  remembered badly, not a calf born backwards. The pairs are refused because the
  ledger is *read back through* them — a litter's PDF prints the mating and the
  whelping side by side, every puppy's birthday is the whelping date, and a due
  date in the past never clears, so it sits in the agenda as overdue forever and
  trains the breeder to ignore the one screen built to be looked at.
- **The rules are pure functions in `date_utils`, and the forms ask before
  writing.** Day-compared, so the hour a row was stored at is not part of the
  answer (the same invariant D31 and D32 already hold). The litter refusal names
  which pair broke and `_refuseDates` switches on the enum, so a third rule added
  later has to be answered rather than inheriting a sentence.
- **`refuseUpdatesOf` — a seam the suite was missing.** Every refusal test until
  now installed a trigger on INSERT. An edit goes through `db.update`, so it would
  have sailed past that seam, and a test asserting "the database's sentence did
  not appear" on an edit path would have been vacuous. The dose tests now seed an
  impossible row through the shipped dao, open it in edit mode, and run against a
  trigger on UPDATE: the impossible pair answers with the date sentence and no
  database sentence, the legal pair answers with the database sentence and no date
  sentence. One field apart, and the difference is the evidence.
- **The first test in this repo that drives the date dialog.** The litter form has
  no edit mode and no way of learning a day except through the picker, so its
  wiring could only be reached by opening it: tap the tile, switch the dialog to
  input mode, type, OK. That mode parses `mm/dd/yyyy` because
  `MaterialLocalizations.parseCompactDate` splits the text on `/` with that order
  written down as an assumption (material_localizations.dart:904), and
  `MaterialLocalizationEn.dateHelpText` — the locale a test runner gets — says
  `mm/dd/yyyy` too. **The hint and the parser disagree in this app's own two
  other languages**: `ar` shows `yyyy/mm/dd` and `fr` shows `jj/mm/aaaa`, both of
  which that parser rejects. Recorded as phone-check debt, not fixed here: the
  dialog is Flutter's, the calendar mode (the one a thumb uses by default) is
  unaffected, and no CI run can type into a locale it is not running.
- **What is NOT covered, stated.** The calendar mode of the dialog is never driven
  by any test in this repo — every one of these paths goes through the typed
  field, so a phone is still the only evidence that tapping a day works on a real
  ColorOS keyboard. A death date before a birth date is not refused anywhere:
  `deathDate` is displayed on the animal's ledger and has no editing UI at all, so
  there is no screen to refuse it from and it is left deferred rather than
  half-built behind a stub.
- **Counting, honestly:** 11 new unit cases (day boundaries, the stored hour, each
  null combination, which sentence wins when both pairs are broken) and 5 new
  widget tests. 382 → 398 at `37850981556`.

## Stage 3n — No record may be dated before the animal it belongs to was born *(CI green — 411 tests at `37856022735`, APK from the same run; the first verdict on these six tests was `37855018407`: "405 tests passed, 6 failed"; device check queued with 3b–3m)*

The phone stayed busy, so this batch is another CI-verifiable one: a third date
rule, six call sites, and one measured defect in the test harness.

- **The rule, and what makes it different from D36's two.** A weigh-in, a dose, a
  screening, a vet visit, a symptom or a handover stamped before that animal's
  `birthDate`. D36 refused two dates on one row; this pair lives on two rows, and
  that is why it is worth a rule of its own rather than a stricter validator: the
  mistake is invisible inside the record that carries it. A date is only wrong here
  *relative to a date on another screen*, so nothing in the row will ever look
  strange to the breeder re-reading it. What breaks is the arithmetic around it —
  triage prints how long ago a sign was seen, a litter makes each puppy's birthday
  the whelping date, a dose interval counts from a screening.
- **One predicate, one sentence, six forms.** `recordPrecedesBirth` went into
  `date_utils` beside D36's rules, day-compared for the invariant D31/D32 already
  hold. `refuseRecordBeforeBirth(context, ref, animalId:, recordMs:)` went into
  `record_refusal.dart`, reads the herd once, shows the sentence and returns whether
  it refused; each of the six forms calls it immediately after its own validation
  guard and before `_saving = true`, so nothing is written and the button stays live.
  Six copies of `ref.read(animalsProvider)` plus six copies of the null handling
  would drift within a month, and every drift would look correct in isolation.
- **It says its own sentence, and the reason is the next action.** `recordSaveFailed`
  means SQLite said no to a record that was fine: press Save again. This means the
  record is not fine: pressing Save again does exactly nothing. Two different next
  actions cannot share one sentence — the same split D34 made between a refused write
  and a refused delete.
- **A design that looked better and was rejected on a crash.** `firstDate: birthDate`
  on the six pickers would make the impossible day untypeable, which beats refusing
  it. It was rejected because `showDatePicker` asserts when `initialDate` falls
  outside `[firstDate, lastDate]`, and all six forms seed `initialDate` from a stored
  row (edit mode) or from today — any of which can already sit behind a birth date: a
  row written before this rule, a pack restored from one (D36 keeps restore
  permissive on purpose), or the ordinary case of a breeder who registers the
  whelping after the first weigh-in. Bounds would crash the form on opening for
  precisely the records the rule exists to catch. A refusal can be bounded later; a
  crash cannot be un-bounded into a refusal.
- **The batch's real finding is about the harness, and a run proved it.** The first
  verdict on these tests was **`37855018407` — "405 tests passed, 6 failed"**, and all
  six were the second half of my own new pair tests: they asserted the
  database-refusal sentence and found zero widgets, while the same log shows SQLite
  *did* refuse that save (`Placement save failed: … the ledger is full`). The write
  behaved; the assertion did not. `ScaffoldMessenger` shows one snackbar at a time and
  queues the next, and `settleRefusal` returns as soon as **any** `SnackBar` exists —
  so phase two settled on phase one's sentence still on screen. This is the exact
  weakness already sitting on the review list as "exits on any SnackBar from any
  route"; it was a note argued from source, and a run turned it into a measurement.
  `dismissRefusals(tester)` now waits out the shipped 4-second display on the fake
  clock between phases — `pumpAndSettle` cannot do it, because a pending timer is not
  a scheduled frame. No product code changed in that fix.
- **What is NOT covered, stated.** The certificate pair (a `validUntil` before its own
  `testDate`) is the same shape as D36's dose pair, and adding it honestly means
  generalising `doseDatesContradict` into a named pair rather than bolting a second
  one-line predicate onto the same idea — queued, not built. A death date before a
  birth date is still not refused, because `deathDate` has no write path anywhere in
  `lib/`: modelled, printed, copied into a pack, never set. A mating before the dam's
  own birth is left with them rather than added as a seventh call site no screen can
  reach. And the harness fix is a mitigation between phases, not the redesign:
  `settleRefusal` still cannot tell which sentence it is waiting for.
- **Counting, honestly:** 7 new unit cases on `recordPrecedesBirth` (a record
  before the birth refuses; the birth day itself is legal, because a puppy weighed
  on the day it was born is a real weigh-in; the day after is legal; a null birth
  refuses nothing; a null record refuses nothing; 23:00 against 01:00 the same day
  is not earlier; 2025-12-31 23:00 against 2026-01-01 01:00 *is* a day before) and 6
  new widget tests, each one a pair inside itself: the impossible date answered by
  the birth sentence with no database sentence, then the dismissed snackbar, a legal
  date, and the database sentence with no birth sentence. 398 → 411 at
  `37856022735`, analyze clean in 14.8s.

## Stage 3o — A certificate that expired before its own screening *(CI green — 413 tests at `37896941494`, APK from the same run; analyze clean in 10.8s; device check queued with 3b–3n)*

The pair D36 queued and D37 deferred, built on the condition those two set: add it
by generalising the dose rule, not by bolting a second one-line predicate onto the
same idea.

- **What changed shape.** `doseDatesContradict` is gone; `measuredDatePrecedesAnchor`
  takes the date a row measures *from* (dose given, screening performed) and the date
  it measures *to* (booster due, certificate expiry). The vaccination form calls it
  with the same arguments under new names, and the health-test form calls it too.
  Renaming rather than wrapping was deliberate: a second predicate beside the first
  would be the thing D37 said not to do, just spelled differently.
- **Why the expiry is worth refusing at all.** `validUntil` is what turns a screening
  from a fact into a claim with a date on it, and it is the field a buyer reads: the
  transfer pack prints the result and its validity side by side. "OFA hips · Good ·
  valid until 2025-11-30" under a screening performed 2026-05-01 is not an old
  certificate — it is no certificate, and a document that presents it beside the
  result is the app lying on paper. The agenda reads the same field for a reminder, so
  an expiry behind its anchor books a reminder for a claim that never existed.
- **Two sentences, because each names a different box.** A breeder told "the next dose
  is due before this dose was given" knows which field to open; the same is true of
  the expiry. One predicate, two strings — the reason D36 keeps these rules on the
  screen instead of in a `CHECK`, restated where it now costs something: a shared
  sentence would have to name neither field.
- **The pair test, and what its absence half rests on.** The screening is seeded with
  both dates inside the animal's life (whelped 1000 days ago, screened 400 days ago,
  certificate lapsing 500 days ago), so the rule that answers is the row against
  itself rather than D37's birth rule; the impossible expiry is refused here with the
  UPDATE trigger never reached, then the same row against the same trigger with a live
  expiry is refused by SQLite with no date sentence. Both halves name the other in
  their `reason:`, because an absence assertion is only evidence beside the control
  that proves the trigger does fire.
- **Counting, honestly:** 4 unit cases in the renamed group (one per shape, the
  anchor-day case still legal, both null combinations) and 1 widget pair test. 411 →
  413 at `37896941494`.
- **What the date rules are now, in full.** Four: a whelping before its mating, a
  weaning before its litter, a measured date before its anchor (dose and certificate),
  and a record before the animal's birth. Every remaining pair this app knows about
  and does not enforce is named in D38 — `deathDate` against `birthDate` (no write
  path exists), and a mating before the dam's own birth (no screen reaches it).

## Stage 3p — A test waits for the sentence it is about to assert *(CI green — 413 tests at `37904006479`, APK from the same run; analyze clean in 16.6s; harness only, so the queued device pass is unchanged)*

No `lib/` file changed. This stage exists because Stage 3n measured a weakness in
the test harness rather than reasoning about it, and then papered over it.

- **What the mitigation was, and why it was not a fix.** `37855018407` returned
  "405 tests passed, 6 failed" and every failure was a second-half assertion
  reading a sentence from the phase before it: `ScaffoldMessenger` shows one
  snackbar at a time and queues the next, so a form refused twice displays the
  first reason while the second is still waiting. `dismissRefusals` spent four
  seconds on whatever happened to be on screen and pushed each test forward. That
  makes the queue *drain*; it does not make the wait answer the question the test
  asks, and a test that settles on the wrong sentence still passes.
- **What changed instead.** `settleRefusal` now polls for one named string —
  `find.descendant(of: SnackBar, matching: find.text(waitingFor))` — and only
  steps aside, burning the 4 s display, when some *other* snackbar is what blocks
  the frame. Every sentence the app can print as a refusal now exists once, as a
  constant in `test/helpers/pump_app.dart`, so "wait for X" and "assert X" are the
  same token; nine literals copied across six files were the drift that got
  measured. `dismissRefusals` is deleted along with its six call sites.
- **Counting, honestly: 413 → 413.** No test was added or removed, so the count
  had to hold; a harness refactor that moved it would be a different stage doing
  something else. The number that matters is that all 413 settled: a wait keyed to
  a sentence that never arrives would have burned its 40 rounds and failed.
- **The mutation check, run and measured.** On branch `check/settle-refusal-mutation`
  (`367a6ec`, dispatched as run `37907847959` — a branch push cannot trigger this
  workflow, and the APK job was gated on `master` for the check so a branch build
  could not land on the rolling debug APK) `settleRefusal`'s "another snackbar is on
  screen" branch was replaced with `return`, which is exactly the pre-3p semantics.
  Verdict: **406 passed, 7 failed** — and the seven are precisely the two-phase tests:
  the six pre-birth pairs from 3n plus the certificate pair from 3o, each failing at
  `pump_app.dart:343` inside `expectRefusedWrite` with `Found 0 widgets with text
  "This could not be saved. Nothing was written."` The wait returned on the *first*
  phase's sentence, the queue never drained, and the second phase's assertion saw
  nothing. Named, keyed-to-the-sentence waiting is load-bearing, not decoration; the
  control is 413/0 at `37904006479`.
- **A doc line that went missing.** The `## Stage 4 — Distribution` heading was
  lost in `e48a72d` (an awk insertion in the same file, the same class of edit that
  the D-entries keep blaming) and was absent from every ROADMAP read since. Found
  by `git show <commit>:ROADMAP.md | grep '^## Stage 4'` over the file's history,
  restored here from `15f33b1`. The Stage 4 text itself was never touched.

## Stage 3q — One rule for who lives at this address *(CI green — 415 tests at `37911415223`, APK from the same run; analyze clean in 16.6s; device check queued with 3b–3p, and this stage changes what the phone visibly does)*

The owner's rule, chosen 2026-10-09 and encoded here: the phone may wake a breeder for
an animal that is still at the address — `active` **or** `retired` — and not for one that
was sold or died. Three surfaces were answering that question three different ways, each
read from source rather than inferred:

- **The agenda hid a retired dam.** `buildHerdAgenda` filtered on `status == active`, so
  her overdue booster was off the to-do list while she slept in the house — the one
  animal whose shots the breeder still owes, silenced by a word about her breeding plan.
- **The triage card spoke for a sold dog.** `evaluateTriage` returned nothing only for
  `deceased`, so a card still said "act now" about a booking that belongs to whoever
  took the animal home.
- **The alarms asked nothing at all.** `bookingsFor` had no status filter and the launch
  resync re-booked every dose and certificate inside the horizon whatever the animal
  was, titling the message `l10n.appTitle` for any row whose animal was gone. The twelve
  tests in that file had never set a status, which is how the gap outlived them.

- **What changed shape.** `AnimalStatus.isAtHome` is the single place that decides, and
  agenda, card and resync now call it. `bookingsFor`'s argument is `herd` instead of
  `animalNames`, and `fallbackTitle` is gone: a record whose animal is not at home books
  nothing, whether the row is missing or present-with-a-status — two reasons, one answer,
  and the same shape the agenda had already settled on. Deleting the fallback is the part
  that carries the rule; leaving it would have kept a 09:00 notification about a dose
  nobody can act on.
- **The tests, and the control each absence rests on.** The agenda's membership test now
  asserts retired *stays* as well as sold/deceased leaving — the old expectation would
  have passed a filter that hid retired forever. The card test pairs a retired animal
  that still fires against sold and deceased silence. `bookingsFor` gains the
  absence/positive pair, and `resyncReminders` an end-to-end case on real SQLite where
  the dose rows are identical and only the animal's status differs, so the claim is about
  the filter and not about the query.
- **Counting, honestly: 413 → 415.** Three tests were rewritten under new names (the
  agenda's, the card's, and the fallback-title one, which no longer describes anything
  the app does) and five appear: the agenda and card rewrites plus `a record outside the
  herd map books nothing`, `a name in the herd map is enough to book, whatever the status
  was`, and the end-to-end launch case. Net two, which is what CI counted.
- **Device debt this stage adds on purpose.** A retired animal's doses reappear on the
  home agenda, and no dose of a sold or deceased animal may wake the phone any more —
  both are user-visible and neither is provable in a widget test, so both join the queued
  phone pass. The alarm half needs the real notification channel: the ledger can be read
  back here, the phone's booked alarms cannot.

### Device check — the batched pass for 3b–3q *(run 2026-10-09 on a Realme RMX3910, build `b7f3d1d`; passed for what it covered, with two findings only a phone could give and a queue that is shorter but not empty)*

The build was read off the screen, not guessed: Settings showed **Build `b7f3d1d`**
in English and **رقم البناء `b7f3d1d`** in Arabic (`w20-settings`, `w22-arabic-settings`).
`versionCode` is still 1 for every CI build, so without that row there is no way to say
which of the thirty-odd builds is installed.

What the phone actually did, each line backed by a screenshot plus a re-pulled database
after the write:

- **A weigh-in, a symptom, a dose and a placement were written on hardware and read back**
  (`w2`–`w4`, `c3`–`c6`, `c21`–`c23`, `w5`–`w18`). `databases/salala.db` pulled with
  `run-as` after each one, so the claim is about the row, not about the widget.
- **The herd agenda says what D40 promises** (3d, 3q). English: "Vaccinations to book /
  Nala / *Rabies was due 2 days ago*"; Arabic: "تلقيحات يجب حجزها / *Rabies كان مستحقًا
  منذ 2 يومين*" (`w19`, `w23`, `w30`). The Arabic line is the dual form, not a literal
  "2 days", and the placed animal (Roya, "غير محدد · تم تسليمه") is on the list with no
  agenda row — the visible half of the rule CI can only assert in a widget.
- **The Arabic PDF's buyer block is populated** (3c, 2c, 3g). `nala-arabic.pdf` was pulled
  out of `cache/salala_out/` and its text recovered by inflating the content streams and
  mapping the embedded font's `beginbfchar` CMap back to Unicode: `Karim Benali`,
  `0555123456`, the e-mail, country `DZ`, price `DZD45000`, and dates in Arabic month
  names (`ﺮﺑﻮﺘﻛأ 2026`). The price and the phone keep **Latin digits** while the prose is
  Arabic — the behaviour the owner asked for, now seen in the file a buyer receives.
- **Language switching survives a restart** and the restart lands on the chosen language
  rather than the system's (`w21`→`w22`, `w31`→`w32`).
- **The cascade sentence on a 6-inch screen** and the cascade itself: "Delete Nala?" with
  the full list of what goes with it (`d2`), then an empty ledger and an empty agenda
  (`d3`), then the database itself: `animals`, `symptoms`, `vaccinations`,
  `weight_entries`, `placements` all empty (`final-clean.db`).
- **The alarm end state is clean**: no live Salala alarm in `dumpsys alarm` — the three
  entries naming `ScheduledNotificationReceiver` are all `Reason=pi_cancelled` history
  (`d3-alarms.txt`) — and the plugin's own cache reads `scheduled_notifications = []`.
  Reading the raw dump matters here: grepping for the receiver's name alone makes a
  cancelled alarm look booked.

**Every row of test residue deleted, per the owner's instruction.** The residue was mine,
not the owner's: Nala's `created_at` is 2026-10-06 (an earlier stage's check) and Roya's is
today's, and the database was pulled and read before any of it was touched. One row
survives because the app cannot remove it — see the findings.

**Two findings this pass produced that no test could have:**

1. **Changing an animal's status does not take its booked alarm back out.** A dose of a
   placed animal was still booked after the placement. The app-level filter added in 3q is
   correct and stays correct — `bookingsFor` refused to re-book it. The gap is one step
   further: `resyncReminders` (`lib/services/reminder_resync.dart:110`) calls
   `scheduler.replace()` *only for the records that survive the herd filter*, so the
   records that fell out of it are never cancelled, and `flutter_local_notifications`
   re-arms its own persisted list at launch anyway. The experiment that pinned this:
   deleting the alarm looked like a resync re-booking it, until the plugin's
   `shared_prefs/scheduled_notifications.xml` was emptied and the re-arm stopped — the
   cache, not the query, was holding the booking. A sold dog's vaccination reminder waking
   its breeder at 09:00 is exactly the noise D40 exists to prevent, so this is Stage 3r
   below, not debt to note and leave.
2. **A buyer contact cannot be deleted anywhere in the app.** Not a missing menu item:
   `lib/data/db/buyer_dao.dart` has no delete at all, so the phone is left holding
   "Karim Benali / 0555123456 / DZ" after every animal, placement and symptom of his has
   been removed (`final-clean.db`: the one row that outlived the cleanup). For an app whose
   promise is "everything is stored on this device", a person's name and phone number with
   no way to erase it is a privacy gap as much as a UI gap.

**One smaller thing the same PDF showed:** the growth chart's x axis is labelled with raw
days since birth — `988.0`, `1009.0`, `1012.0` — because `animal_pdf.dart:186-220` hands
`pw.FixedAxis` the day-count set directly. The document is for a buyer, and a buyer does
not read "988" as anything.

**What this pass did NOT cover, so the queue keeps it** rather than pretending: every
French string on a real screen (the pass ran English and Arabic), the app lock against the
hardware keystore, the startup-failure screen with a real unreadable database, the search
box typed into on the on-screen keyboard — the field is not even on screen at two animals —
the date dialog's input and calendar modes under a Moroccan Arabic keyboard (the `ar` hint
says `yyyy/mm/dd` while Flutter's shipped `parseCompactDate` reads `mm/dd/yyyy` and nothing
else: an upstream behaviour this app inherits, unanswered), and the pre-birth and date
refusal sentences, of which no dump captured a single snackbar.

## Stage 3r — An alarm that outlived its animal *(CI green — 426 tests at `37980578546`, APK from the same run and installed on the phone; device re-check run on the Realme 2026-10-09)*

The shape is already settled and it is small: when an animal is edited, cancel every dose
and screening id belonging to it before deciding what to book, then re-book through the same
`bookingsFor` with a one-animal herd map when the new status `isAtHome`. `replace()`
cancels before writing, so the second half is idempotent, and an animal that simply stayed
at home pays two `cancel()` calls it did not need — cheaper than a notification about a dog
who lives at another address. A blanket `clearEverything()` at launch was ruled out: the
save path books past `reminderHorizonDays = 45` while the launch query is
`dueBefore(now + 45d)`, so emptying the phone first would silently drop a dose due in
month two.

Alongside it, the two smaller device findings are queued as their own work rather than
left in prose: a buyer delete path, and day-count labels on the PDF growth chart.
Both were shipped by Stage 3s; the framing of the first one here was wrong, and says so
below rather than being quietly rewritten. On `BuyerDao` having "none": `delete(id)` is
declared once on `RecordDao` (`lib/data/db/record_dao.dart:36`) and `BuyerDao extends
RecordDao<Buyer>`, so the DAO has been able to delete a contact since the DAO was written.
What had no delete was the *screen* — no button, no confirmation, nothing that could reach
that method — which is why the fix is four presentation files and not a data-layer change.

**What shipped (`d002d54`), and where it differs from the sketch above.** The paragraph
above described cancelling *every* id of the edited animal before re-booking. What went in
is narrower, because the wider version pays two platform calls per record on every edit for
alarms that were never there: `reconcile()` writes the bookings the herd map still owns and
cancels only what `staleRecordIds()` names — a record whose animal is out of the map **and**
whose mornings are still ahead. A record with nothing left to fire is left alone on both
sides, which is the same rule `bookingsFor` already applied, so the two halves of one walk
answer with one loop's logic.

Three seams, not one, because the first fix was incomplete in a way only re-reading the
flow showed:

1. `resyncReminders` (the launch) now reconciles rather than only re-books, so a kill that
   lands before an edit finishes still heals on the next opening.
2. `resyncAnimalReminders` runs from the animal form right after a successful edit, and
   reads the animal's **own** rows rather than the horizon query — the save path books a
   dose as far ahead as it is dated, while the launch only asks for 45 days, so a launch
   alone could never see a dog's booster due in month three.
3. The dose and screening forms ask `reminderAllowedFor(ref, animalId)` before booking and
   cancel when it says no. Without that question the two halves of this stage cancel each
   other out: mark a dog Placed, take her alarms back out, then save one more dose for her
   and have the phone hold it again.

Eleven tests came with it (426 green, `No issues found!` in 12.9s), including the pair the
house rule asks for on every absence: `saving a screening books its expiry warnings on the
phone` and `saving a screening for an animal who has left books no alarm`, and a widget
test that drives the real dropdown — «Placed» on the card, `Edit` on the menu — because the
DAO cannot answer whether the screen the breeder touches reaches the scheduler.

**The device re-check, run on the Realme (RMX3910) on 2026-10-09.** Both stores were read
before anything was typed: `shared_prefs/scheduled_notifications.xml` held
`<string name="scheduled_notifications">[]</string>` and `dumpsys alarm` showed only
`Reason=pi_cancelled` history for `ScheduledNotificationReceiver` — a clean baseline, not a
leftover booking about to flatter the result. Then a dose on a test dog, Given today,
**Next due Dec 15, 2026**:

- **Booking, both stores.** The prefs file immediately held two entries — id `336114074`,
  "Heads up: Rabies is due on Dec 15, 2026" at `2026-11-15T09:00:00`, and id `336114075`,
  "Rabies is due today" at `2026-12-15T09:00:00`, both `channelId: salala_reminders`,
  `timeZoneName: Africa/Algiers`, titled with the animal's own name. `dumpsys alarm` agreed
  from the other side of the boundary: two live `RTC_WAKEUP` alarms with `origWhen` at exactly
  those two dates and `window=+1h0m0s0ms` (the inexact-while-idle mode the plugin was given).
  The 30-day heads-up and the due-today reminder are two different alarms, which is what
  `bookingsFor` promises and no test on a fake scheduler can prove.
- **The status change, which is the stage.** `With me` → `Placed` through the real dropdown on
  the edit form, saved. The prefs file is back to `[]`. The live `RTC_WAKEUP` lines for
  `com.salala` are gone from `dumpsys alarm`, and the OS keeps the receipt: two
  `Reason=alarm_cancelled` entries stamped `2026-10-09 23:25:43`, the same second as the save.
  The herd card itself reads `Female · Placed`, and the dose record is still on the ledger
  ("Rabies · Given Oct 9, 2026 · Next due Dec 15, 2026") — the reminders stop, the history
  stays, which is the distinction the whole stage turns on.
- **Force-stop and reopen, the failure this stage was actually about.** The plugin re-arms from
  its own list on some paths, so a cancel that only moved the app's bookkeeping would still
  come back here. It does not: after `am force-stop` and a fresh launch the prefs file is still
  `[]` and `grep -c "RTC_WAKEUP #.*com.salala"` over `dumpsys alarm` returns **0**.

**What the phone still cannot say.** That a notification *appears* at 09:00 has never been
observed on hardware, in either build — the earliest booking this device can now hold is
2026-11-15, so the fire itself stays owed by the calendar rather than by me. Everything up to
the fire — the two alarms, their ids, their times, their removal, and their absence after a
kill — is measured above.

## Stage 3s — Months on the chart, and a contact taken back out *(CI green — 440 tests at `37987306323`, then 449 at `37988496860`, APK from both runs; device check run on the Realme 2026-10-09)*

The two findings the batched phone pass left behind, shipped together because neither
reaches the page without the other being true.

**The growth chart now says months and kilograms.** It is the D29 rule applied to a chart
rather than a table: `pdf` draws an axis label through the embedded font's glyph ids, so a
test over the bytes of a document cannot read a tick back, and the marks therefore get
chosen in `lib/core/utils/growth_axis.dart`, where CI can read them. What the phone showed
was the default `pw.FixedAxis` formatter — `value.toString()` — printing the ages in *days*
under the curve: `988.0 1009.0 1012.0` on a buyer's page, three marks on top of each other
saying nothing about a dog's age. Age is now in months (`meanDaysPerMonth`, because a
calendar month has no fixed length and the axis is read for shape, not to the day) and
weight in kilograms, each cut on a whole step chosen as the finest one whose marks fit six,
each **enclosing** the data because an axis's first and last values *are* the plot domain —
a mark inside the range puts the point outside the grid box.

**A contact can be deleted, and the handover survives it.** `BuyerDao.delete` was never
missing (it is `RecordDao`'s, `lib/data/db/record_dao.dart:36`); the screen had no way to
reach it. The edit form now offers `حذف`, asks once with the contact's own name in the body,
and pops a result that says which of the two happened. `placements.buyer_id` is
`ON DELETE SET NULL`, so the animal's row keeps its day, its money and its guarantee and
loses only the name — which the confirmation says out loud, because the alternative
reading is "the sale was undone".

**The review round, and what it got wrong.** Two reviewers read the diff while CI was up.
Three of their four blockers did not survive checking, and one finding the first reviewer
called a blocker was a real trap:

- *"`0.43` shifted by ten truncates, so a weight axis can start above the lightest
  weigh-in."* Reproduced against the algorithm and rejected: the shift and the divide each
  round to the *nearest* double, floor errors low and ceil errors high, and a 20,000-case
  sweep over the ledger's own weights (`grams / 1000.0`) found no leak. Their one-conversion
  form of `_kiloRange` was adopted anyway — it is clearer, and it killed a comment that
  claimed something untrue about `.floor()`.
- *"`meanDaysPerMonth` is dead in production."* It is read four times in the same file
  (`:71`, `:72`, `:87`, `:91`).
- *"The placement tile keeps a stale buyer snapshot, so the test asserting «Buyer not
  recorded» cannot pass."* It resolves `buyerById(contacts, placement.buyerId)` at build
  time from `ref.watch(buyersProvider)`, and the test passed on the first CI try.
- **Accepted:** the handover form's own `_createdBuyer` snapshot — kept because the contact
  list reloads on another isolate — could bless a contact deleted from inside the pencil
  dialog. The save then aborted on the foreign key and showed "try again" on a form that
  would never save. The fix is the explicit `BuyerDialogResult` saved/deleted channel
  (`c11bea5`), and the test that pins it creates a contact, deletes it in the same handover
  form, and saves.
- Also accepted from the second reviewer, as Stage 3t below.

Eleven new widget tests and eighteen axis tests came with this; the axis file is where the
chart's arithmetic can be argued about at all, and the widget tests run against real SQLite
with foreign keys on, so `SET NULL` is observed rather than assumed.

**On the phone, the two things the tests cannot say (Realme RMX3910, 2026-10-09).** The chart
finding is about ink on a page a buyer keeps, so it was measured on one — the animal's PDF
shared out and opened in WPS Office on the device. The age axis now prints `0 1 2 3 4` under
the curve and weight `0 5 10 15` up the side, where the build before this stage printed
`988.0 1009.0 1012.0` on the same animal's page. The six-mark budget was then tested with the
beginner's mistake the review predicted rather than with clean data: `430` typed into the
kilogram box for a puppy, which is 430 grams, and the axis printed `0 100 200 300 400 450` —
six marks, none of them on top of another, on the same page. The contact delete was read back
out of the database rather than off a screen: after removing the buyer from the ledger's
handover sheet, the pulled `salala.db` reports `buyers` at **0 rows** while the placement row
is still there with `buyer_id` NULL and its `placed_date` intact, and the tile reads "Buyer not
recorded".

**Two things that delete deliberately does not do.** Both were raised in the review round and
both are recorded here instead of quietly widened into the code:

1. `deleteBuyer` invalidates `buyersProvider` and nothing else
   (`lib/presentation/providers/record_providers.dart:208-211`), so a `placementsProvider`
   snapshot still in the widget tree can name a contact who is gone until something else
   reloads it. No user-visible defect was found — the tile that reads it re-resolves through
   `buyerById` against the list it watches, and the phone pass above saw the correct text — and
   a blanket invalidation on every delete is a behavior change with no failing test behind it.
2. "This cannot be undone" is true of every delete in this app and false of none of them:
   `restorePack` replaces the whole database, so a contact deleted before a restore returns
   with it. That is a fact about backups, not about this one button, so it belongs in this file
   and in the restore screen's own wording rather than being bolted onto a confirmation a
   breeder reads in half a second.

## Stage 3t — Holding the axis to what it promises, instead of trusting the rounding *(CI green — 452 tests at `37990888147`, then 455 at `37996935485`, APK from the 455 run; device check run on the Realme 2026-10-09)*

The second reviewer's two `should-fix` findings, checked rather than accepted on authority:

1. **Enclosure was float luck, not structure.** The claim reproduced exactly where the first
   reviewer's did not: `kiloScale([1.8499999999999999, 1.9])` — one ulp under the mark 1.85 —
   put its first mark *at* 1.85, so the lightest weigh-in sat outside the grid. Unreachable
   from the ledger (the reviewer's own sweep of every gram value 1–60,000 found zero leaks,
   and so did mine — 419,986 pairs, on which the walk-back never even runs). But the
   invariant this file exists to hold was being *assumed* of IEEE rounding instead of
   *enforced*. Both edges of both scales are now walked back until they contain the data;
   on clean data the test is already true and the loop never runs.
2. **`maxTicks` was a promise the fallback did not keep.** When no step on the ladder fits,
   the code silently used the coarsest one and the mark count ran free — `[0.43, 5000]` gave
   **101 marks**, `[3.1, 430]` gave **10**. That is not a hypothetical: the weight field has
   no maximum (`parseWeightToGrams` bounds only the low end), so a puppy's 430 *grams* typed
   into the kilogram box is a normal beginner mistake, and it lands on the one document a
   buyer keeps. The marks are now thinned by an integer stride computed from the span, so six
   holds for *every* value that can reach the page; `[3.1, 430]` prints `0 100 200 300 400
   450` and `[0.43, 5000]` prints `0 1000 2000 3000 4000 5000`. A stride of one — every
   record a breeder actually types — reproduces the previous axis exactly, which is what the
   fourteen exact-label expectations that predate this stage still assert (`c11bea5` carries
   fourteen, the file carries seventeen today).
3. `maxTicks` as a public knob was a parameter no caller and no test turned; it is now the
   file's own `_maxAxisTicks`, and the two tests that assert "no more than six" assert it for
   wide spans too.
4. The reviewer's `_trim` note was real but only as documentation: `\0+$` does eat the zeros
   of an integer (`"40"` → `"4"`), and the `contains('.')` early return is the only thing
   preventing it. That is now said where it can be broken.

**The first CI verdict on this stage was a failure, and it was the compiler making the
stage's own point back at me.** `37990588330` stopped in the Analyze job, before a single test
ran, on `lib/core/utils/growth_axis.dart:168:23` — *"The operator '+' isn't defined for the
type 'int Function()'"* — because the stride was written `ceil(x) + 4` with `ceil` never
called, so the expression added four to a **tear-off of the function** instead of to a number.
Alongside it, `_months` was defined twice (`:242`, one error and one unused-element warning).
Fixed in `8f501ce` by calling `.ceil()` on the value and leaving one `_months`: 452 tests,
`No issues found!`. Writing a promise as a value instead of a call is the same category of
mistake as leaving enclosure to IEEE luck, which is what this stage exists to stop; the
discipline that made `37987306323` green first try covered the *labels*, and it did not cover
the syntax.

**The sweep is no longer a script.** Twenty-one axis tests came in with the fix above, and the
~210,000-pair sweep that justified them was a throwaway JS file — so CI could not re-enforce
any of it, and the sentence "0 failures locally, CI verdict NOT RUN" was the honest ceiling
available at the time. It is now `test/core/growth_axis_test.dart`, group *"the rules of an
axis, over records nobody picked"*, and CI runs it on every push: 1,500 seeded draws per case
(`_sweepSeed = 20261009`, so a failure is reproducible rather than merely rare) over ages from
one day to 20,000 days — past any living dog — and weights taking every value on the ledger's
own gram lattice (`nextInt(60000) / 1000.0`) alternating with arbitrary doubles up to 5,000
kg, the typed-into-the-wrong-box case. Each record asserts the five rules the file promises:
no more than six marks, strictly ascending, enclosing the data, no two marks on one label, and
**every label re-parsing to its own mark's position** — months × `meanDaysPerMonth` for an age,
plain kilograms for a weight. That last one is the D29 rule turned into a check: a mark whose
word does not describe its own coordinate is exactly the bug the phone found. Twenty-three
axis tests, 455 tests overall, `No issues found! (ran in 12.0s)` at **`37996935485`**, APK
built in the same run.

**One more absence, from the same review round.** `placement_dao_test.dart` deleted a buyer who
had sold **one** animal; `ON DELETE SET NULL` does not care how many rows point at an id, so the
test now books two handovers to one contact, deletes the contact, and requires both rows to lose
the name and keep their `placed_date`, with `forBuyer` returning nothing for a person who is
gone. +94 and +29 lines in two test files, no production file touched — which is also why the
phone verdicts above (measured on the `8f501ce` build) still describe the shipped code.

**The phone was left clean afterwards.** The test dog went through the herd card's own overflow
menu — `Delete` → "Delete Devchk?" → confirm — and the pulled database reads **0 rows** in
`animals`, `placements`, `vaccinations`, `weight_entries`, `symptoms`, `buyers` and
`health_tests`: the animal's delete cascaded the handover, the dose and four weigh-ins that the
alarm check had produced. A second animal (`D20chk`, one dose due tomorrow) was then added to
run the 1e / D20 kill-and-reopen sequence recorded under Stage 1, and deleted the same way;
every count above is taken after both. The herd screen shows "No animals yet", the notification
store is back to `[]`, no live alarm remains for the package, and the scratch files this
campaign pushed at the device (`after.pdf`, `budget.pdf`, and the Stage 2 export pack that had
been sitting in Download since 2026-10-06) are gone from it, along with the three cached PDFs in
the app's own `cache/salala_out`.

## Stage 4 — Distribution

Blocked on the business question in `docs/FEASIBILITY.md` §Payments: a Morocco
resident developer cannot receive Play money directly. Options ranked there.
Whatever is chosen happens **before** the package id and the store listing are
made permanent, because both are one-way doors.

**The premise of the locked decision is now in question.** The app was designed
around a one-time purchase through Google Play Billing. `docs/PAYMENT-ROUTE.md`
(a research note of 2026-10-06, every line labelled CONFIRMED or UNVERIFIED —
deliberately still untracked, because it is business strategy in a repository
that is currently public, and the owner has not read it yet) reads
Google's own supported-locations table as **Morocco: developer registration ✔,
merchant registration ✘** — which is the half of Play Billing that a paid app
needs, and it applies identically to in-app purchases and subscriptions. If that
holds, D8 cannot be executed as written and the monetization shape is a product
decision, not a billing-library detail. **Nothing in the code depends on it yet**
— no billing dependency and no purchase screen — which
is exactly why Stage 4 stays blocked instead of half-built. The `applicationId`
half of that sentence was true until 2026-10-10 and is now closed separately as D9.
The decision needs the
owner, with the Google answer sought from Play Console support first.

**The `applicationId` menu (D9), measured before proposing it.** So that "pick a name"
is a decision about one number of files rather than a vague fear: the id is written in
exactly three places, and nothing else in the project knows it.

| Where | Line | What it is |
| --- | --- | --- |
| `android/app/build.gradle.kts` | `:25` | `applicationId` — the store identity, the one-way door |
| `android/app/build.gradle.kts` | `:8` | `namespace` — the Kotlin/`R` package, **may differ from the id** |
| `android/app/src/main/kotlin/com/salala/salala/MainActivity.kt` | `:1` | `package` declaration, coupled to `namespace` and to that directory's path |
| `ios/Runner.xcodeproj/project.pbxproj` | `:386`, `:567`, `:589` | `PRODUCT_BUNDLE_IDENTIFIER` (3 app configs) |
| `ios/Runner.xcodeproj/project.pbxproj` | `:402`, `:419`, `:434` | `…RunnerTests` (3 test configs) |

`grep` over `lib/`, `test/`, `tool/`, `.github/`, every `.xml` manifest and every `.arb`
returns **zero** hits for `com.salala`: no deep link, no share target, no `FlutterEngine`
plugin registration by package, no import in a single Dart file. Consequences worth having
down before a choice is made:

- **Android alone** can be renamed by editing one line (`:25`). Because `namespace` is a
  separate value, `MainActivity.kt` and its directory do **not** have to move — and no
  Dart, test or CI file has to change either. That is the whole Android blast radius.
- The iOS lines are a 4th file, and can be left for the day an iOS build is funded.
- The product name *was* encoded in the id (`salala` twice), the one property D9 says a new
  id should not repeat. That bullet is now history, not an open finding — see below.

**D9 was decided on 2026-10-10 and is implemented on `master`.** The owner picked
`com.toufikben.ledger` — shape 3 from the list, with the GitHub account standing in for a
studio name, since it names a vendor he already controls and needs nothing bought. Shape 2
(`io.github.toufikben.salala`) and keeping the scaffold id were declined for the reasons
written in the table above; shape 1 stays available as a *better* id, but only until the
first upload, which is the whole point of D9 being closed now rather than later.

What moved, and what the measured blast radius predicted exactly:

| File | Change |
| --- | --- |
| `android/app/build.gradle.kts:8` | `namespace` → `com.toufikben.ledger` |
| `android/app/build.gradle.kts:25` | `applicationId` → `com.toufikben.ledger`, and the template's `// TODO: Specify your own unique Application ID` comment went with it |
| `android/app/src/main/kotlin/com/toufikben/ledger/MainActivity.kt` | new path, `package com.toufikben.ledger`; `com/salala/salala/MainActivity.kt` deleted (confirmed absent from the tree at `2afabda`) |
| `android/app/src/main/AndroidManifest.xml:8` | `android:label` → «سلالة», the owner's choice for the name under the icon |
| `ios/Runner.xcodeproj/project.pbxproj` | **untouched**, six `PRODUCT_BUNDLE_IDENTIFIER` lines still `com.salala.salala` — no macOS runner and no Apple hardware here, so a change to them could be authored and never built. Recorded as NOT VERIFIABLE, not as done. |

Zero Dart, test, workflow, manifest or `.arb` file named the id, so nothing else had to
change, and CI is the proof of that rather than the grep: commit `4cf246c` (the id) ran
`No issues found!` and **455 tests passed** and built `app-debug.apk` at run
**`38004021774`**. The label commit `2afabda` ran its own job green at **`38021992277`**
(03:51–03:59 UTC: `No issues found! (ran in 10.5s)`, `🎉 455 tests passed.`,
`✓ Built build/app/outputs/flutter-apk/app-debug.apk`), and the rolling release asset came
off that run at 176,598,495 bytes, sha256 `0a08340c…2977`.

**Read back on the phone (RMX3910), 2026-10-10 18:04–18:18.** The docs commit `1f7683d` ran its
own job green at **`38023514312`** (`completed success`: `No issues found! (ran in 16.5s)`,
`🎉 455 tests passed.`, `✓ Built build/app/outputs/flutter-apk/app-debug.apk`) and republished
the rolling asset at 176,598,499 bytes, sha256 `8a251b93…8a66`. Before installing it, the
artifact was inspected with `aapt2 dump badging`, which prints
`package: name='com.toufikben.ledger' versionCode='1' versionName='0.1.0'`,
`application-label:'سلالة'` and `launchable-activity: name='com.toufikben.ledger.MainActivity'`
— the rename is in the shipped binary, not only in the source. On the device: installed fresh at
`firstInstallTime=2026-10-10 18:05:04`, the OS permission sheet read **«Allow ‎سلالة‎ to send you
notifications?»**, and Settings prints **Build `1f7683d`**.

**The write path was exercised too, because a rename can break storage in a way `analyze` cannot
see.** The new package's `databases/salala.db` started at 0 rows in all five tables. Adding
`D9chk` (species `dog`) and pressing Save put exactly one row in it — `animals=1` with
`name=D9chk`, `species=dog`, `sex=female`, `status=active`, the other four tables still 0 — while
the old `com.salala.salala` database stayed at `animals=0` across the whole pass: two separate
silos, as the paragraph below predicts. Deleting the animal through the card menu returned
`animals` to 0, and both alarm stores were re-read at the end (`shared_prefs` under the new id
holds no `scheduled_notifications.xml` at all — the plugin writes it on the first booking — and
every `com.salala.salala` entry in `dumpsys alarm` is history with `Reason=alarm_cancelled` /
`pi_cancelled`, 0 live). The phone was left as clean as it was found.

One trap cost a pass and belongs in the record: **`Species` is a required picker.** Save with it
empty does nothing visible except print «اختر النوع» / *Choose a species* under the field, so it
looks like a dropped tap rather than a form refusing correctly.

One consequence worth stating before anyone repeats this on a released app: **a changed
`applicationId` is a different app.** On the phone the old `com.salala.salala` install stays
where it is, and the new package arrives with its own empty database, its own (initially absent)
`shared_prefs/scheduled_notifications.xml` and no alarm bookings carried over. This was safe
on 2026-10-10 only because Stage 3t had already left every table at zero rows and the alarm
stores empty. After launch, the same one-line rename would strand a breeder's whole ledger.

The name under the icon is now Arabic script for every locale, because `android:label` is a
single string with no locale variants — `appTitle` inside the app remains `Salala` for
English and French, and `MaterialApp.title` (`lib/app.dart:15`) still feeds `'Salala'` to the
recents card, so the two surfaces disagree in those locales by design rather than by accident.

**What Stage 4 still lacks, measured.** Not prose about "polish": the release build signs
itself with the debug key (`android/app/build.gradle.kts:39-42`, `signingConfig =
signingConfigs.getByName("debug")`), and there is no upload keystore anywhere in the
project or the CI cache (D19 caches only `debug.keystore`, for a different reason:
reinstalling on the test phone without wiping data). `.github/workflows/flutter-ci.yml`
has **two jobs** — `analyze-and-test` and `build-debug`; there is no `bundleRelease` /
AAB step, no Play upload step, no signing of a release artifact. On the store side nothing
exists yet: no privacy-policy URL (Play demands one for a health-adjacent app), no content
rating answers, no store listing, no data-safety form. Each of those is either an owner
credential or an owner statement, so the honest state of Stage 4 is *blocked on the owner*,
not *in progress*.

## Stage 5 — Later candidates (no commitment yet)

Multi-breeder/club accounts (the B2B2C path), breeding-plan and mate-pairing
advice, FHIR `patient-animal` alignment for vet interoperability, iOS build,
photo/attachment storage, and a web viewer for buyers who received a pack.

**Triage of that list, so the next stage is chosen rather than drifted into.** Each
verdict is about *this* project's evidence situation, and none of them is a claim that the
idea is bad.

- **Photo/attachment storage — buildable and CI-verifiable, still a product commitment.**
  *(Built as Stage 5a below; three of the costs named here turned out not to exist.)*
  The only candidate the current harness can prove end to end: a real SQLite column plus a
  file under the app's documents, tests that hit the DAO, and a widget test that drives the
  picker's result. It is not free: it needs `image_picker`, a camera *and* a gallery
  permission where the app today asks for none (standing constraint: offline-first, no
  permission a feature does not provably need), an extension of
  `data_extraction_rules.xml` to keep the image files out of cloud-backup and
  device-transfer exactly as `salala.db` is (D10 — a photo of a dog is a lot more identifying
  than a weight row), and a decision about whether images travel in the pack, which collides
  with D22's "the pack is the whole database" being a *small, text* file a buyer can open in
  a messaging app.
- **Multi-breeder / club accounts — NEEDS OWNER PRODUCT DECISION, not code.** It breaks the
  premise of three decisions at once: D1 (the wedge is one small breeder, judged on her own
  ledger), D4 (an app-lock PIN on one device is the whole security story), and D22 (a pack
  that *replaces* the database presumes one owner per database). A club means shared rows,
  per-row authorship, and an identity model — which is a different product, and one whose
  paying customer is a club, not the breeder the app is built for. Nothing here is a
  refactor away; it is a D-level conversation with the owner.
- **Breeding-plan and mate-pairing advice — NEEDS OWNER PRODUCT DECISION.** It collides with
  D25: triage is a rule table over what is already recorded and never names a disease.
  Pairing advice is the same category of claim pointed at the future instead of the past, and
  it would need a breed standard dataset the repository does not have and cannot license
  from the code. Health-screening *reminders* from existing data are already shipped;
  "which sire" is a different promise, and a wrong one is a vet visit or a bad litter.
- **FHIR `patient-animal` alignment — NOT VERIFIABLE HERE.** Verifying it means exchanging
  with a server or a second system, and this project's only two verifiers are CI (no
  network, no counterparty) and one Android phone. It can be *shaped* (a JSON structure that
  maps cleanly later) at essentially no cost; claiming it "works" would need infrastructure
  that does not exist.
- **iOS build — NOT VERIFIABLE HERE.** There is no macOS runner in this account's CI and no
  Apple hardware here, so a build could be *authored* but never run, and D-level rules forbid
  claiming it. It is also the lowest-conversion candidate: the breeder with the ledger is
  holding an Android phone today.
- **Web viewer for received packs — NOT VERIFIABLE HERE, and dependent on D8.** Same
  problem as FHIR plus a hosting decision and a privacy surface: a page that renders a
  buyer's pack is a place where the whole-database file gets parsed for strangers.
  The buyer's PDF (Stage 3g) already answers the need without a server.

## Stage 5a — The animal's own pictures *(CI requested; the phone has not seen it)*

Taken off the Stage 5 list because the triage above found it the only candidate this
project's two verifiers can judge. The scope shipped is the narrow one: a picture per
animal, stored on the phone, shown in her ledger, deleted with her. Not a camera, not an
album, not a document attachment.

**What is there now.**
- `photos` at schema version 3 — `id`, `animal_id`, `file_name`, `created_at`, FK cascade,
  one index — plus the `_addPhotos` migration step for installs coming from v2.
  `animals.photo_path` is *not* the mechanism: it has never had a writer, and one path per
  animal is not a ledger. It stays as it was (D41).
- `services/photo_files.dart`: the gallery pick, one folder per animal under the app's
  documents directory, the 24 MB cap, the extension list, and the two name checks that keep
  a row from pointing outside that folder. `photo_files_test.dart` runs it against a real
  temp folder on a real disk.
- `PhotoDao.forAnimal` (oldest first), `photosForAnimalProvider`, `photoPathProvider`.
- A Photos strip in the ledger between the weigh-ins and the placements: thumbnails, tap to
  open one big with the day it was taken, two questions before anything is removed.
- A row whose bytes this phone does not hold renders as a named blank — «Not on this
  phone» — which is the state of every ledger restored from a pack, said plainly and not as
  an error.
- `files/photos` excluded from cloud backup *and* device transfer, in both
  `data_extraction_rules.xml` and the legacy `backup_rules.xml`, because a dog's photograph
  is more identifying than a weight row (D10).

**Three things the triage line got wrong, found by reading the packages instead.** No new
dependency: `file_selector` is already here for the pack, and `file_selector_android` opens
the pick with `ACTION_OPEN_DOCUMENT` — the Storage Access Framework — which asks for no
permission, so the standing "offline-first, no permission a feature does not provably need"
constraint is met by adding none, and there is no camera in scope at all. Pictures do not
travel in the pack: `photos` is a `fileBackedTables` table, so a JSON pack stays the small
text file D22 promised, and `schema_test.dart` now compares `dataTables + fileBackedTables`
against the `CREATE TABLE` statements so no table can belong to neither and silently drop
out of every export. And HEIC is refused rather than stored: the engine has no HEIF decoder,
so accepting one writes a blank that never fills.

**The order of the two stores is the substance of the stage**, and it is the part with
tests on it: file first then row when adding (a refused insert takes the copy back out, so
"Nothing was written." cannot lie), row first then file when deleting (a leftover byte is
invisible to the ledger and swept by the folder clear that follows the animal). D41 has the
argument for each.

**What CI cannot answer, stated before the run rather than after.** `Image.file` never
completes inside a fake-async zone, so no widget test here can prove a photograph is drawn.
CI proves the contract — the bytes written are the ones the row names, and the name on the
row is the name the screen asked the folder for. Rendering, the gallery sheet on ColorOS,
and the real path the backup rules must point at are the phone's.

**Queued for the device pass, as one visit:** pick from the gallery and see a real
thumbnail; open the viewer; delete one picture and confirm both the row and
`files/photos/<animal>/` entry are gone (read back with adb, not assumed); delete an animal
with pictures and confirm the folder goes with her; confirm the exclude path in the XML is
the folder the app actually writes. Then the phone is left with no test animal and no
picture, as every pass this project has run.

## Standing constraints

- Offline-first: no network permission until a feature provably needs it.
- Tests hit real SQLite, not mocks.
- Nothing is claimed as passing without a command and its output.
- No stubs or dead scaffolding to satisfy a checklist.
- The repository's `ARCHITECTURE.md` and `DECISIONS.md` are updated whenever a
  structural choice changes.
