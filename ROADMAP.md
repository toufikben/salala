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
- **A buyer has no delete, on purpose.** `placements.buyer_id` is
  `ON DELETE SET NULL`, so removing a contact would silently blank the buyer of a
  document already handed to a family.
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
— no billing dependency, no purchase screen, no `applicationId` commitment — which
is exactly why Stage 4 stays blocked instead of half-built. The decision needs the
owner, with the Google answer sought from Play Console support first.

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
