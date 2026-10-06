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

### 1e — The launch that rebuilds the alarms (CI green; device proof pending)

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

Pending on the device, in this order, once the phone is free: install this build,
book a dose due tomorrow, read the alarm in `dumpsys alarm`, `am force-stop`,
read zero alarms, reopen Salala, read the alarm again. That last pair *is* D20.
Then the overnight delivery watch from 1d, on the same untouched booking.

Gate: a reminder that was lost comes back by itself on the next launch — **proved
in tests, not yet on the phone.**

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

- **3a — the rule table and the card: red on CI, then fixed in the test harness.**
  Nine rules in `assets/triage/rules.json` over `core/utils/triage.dart`, one card on the
  animal's ledger, and the explicit non-claim under it. 34 rule and table tests in
  `test/core/triage_test.dart`, four in `test/presentation/triage_card_test.dart`
  that pump the real app — including the one that proves the bundle serves the
  same table the repository holds. D25 records what "rules are data" does and does
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
  finished loading"** — a section that *never* resolves, not a slow one. The cause
  was one line of the new provider: it watched the rule table *after* awaiting a
  database row, and that watch resolving is the event that re-runs the element and
  makes the abandoned `ref.watch` throw, which Riverpod paints as retrying-loading
  rather than as an error. D7 now carries the rule; the card, the engine and the
  table were not at fault in either run.
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
