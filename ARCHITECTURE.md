# Salala — architecture

Salala (سلالة, "lineage") is an offline-first Android app that keeps health,
lineage and placement records for small-scale dog and cat breeders, and exports
a transferable document pack for puppy buyers. No account, no server, no
network permission in Phase 0–2.

## Layers

```
lib/
  main.dart              bootstrap: open DB, read settings, seed providers, runApp
  app.dart               MaterialApp.router + locale + themes
  core/                  things with no domain knowledge
    build_info.dart      the CI-stamped build tag, shown on Settings → About
    l10n/                .arb sources + generated AppLocalizations + enum labels
    router/              go_router config, route paths, PIN-gate redirect
    theme/               Material 3 seed, light/dark, 48px touch targets
    utils/               date formatting through intl, gestation arithmetic
  data/
    models/              plain Dart value objects (Equatable), fromMap/toMap
    db/                  schema, open/migrate, DAOs
  services/              non-DIO platform services (app-lock PIN)
  presentation/
    providers/           Riverpod providers + Notifiers (the only state layer)
    screens/             one file per route
    widgets/             reusable pieces used by screens
```

Dependency direction is one-way: `presentation → data/services → core`. Nothing
in `data/` imports Flutter widget code; nothing in `core/` imports `data/`.

### Why three layers and not the spec's clean architecture

The original brief asked for `domain/ usecases/ repositories/ data/` folders.
For a single-developer, single-device SQLite app that split would add a
pass-through class per table with no second implementation to justify it. The
DAO *is* the repository; the model *is* the entity. If a sync or second storage
backend ever appears, the DAO boundary is already the seam to abstract over.

`ai/` is intentionally absent: the agreed AI scope is rule-based triage plus a
small intent classifier, and rule-based triage lives in `data/models` (a
`Vaccination.isOverdue(nowMs)` style predicate) until there is a real model to
wrap. No placeholder files.

## Data

One SQLite database (`salala.db`) opened by `AppDatabase.openAt`. Nine tables,
schema version 1, declared once in `data/db/schema.dart`:

`animals` `litters` `vaccinations` `health_tests` `weight_entries`
`vet_visits` `buyers` `placements` `user_settings`

Decisions encoded in the schema:

- **No `owners` table.** The breeder *is* the app user; `buyers` is the only
  external-person table, and it exists because the transfer pack has to name
  the new owner. Modelling owners generically would be speculative structure.
- `litters.sire_id` is `ON DELETE SET NULL`, `litters.dam_id` and every
  animal→record foreign key is `ON DELETE CASCADE`. A sire can be unknown or
  removed without destroying the litter; a dead animal's records go with it.
- Timestamps are Unix milliseconds in INTEGER columns. There is no timezone
  stored anywhere — the app is single-device, local-time by definition.
- `animals.species` is free text, not an enum. Breeders mix dogs, cats, and
  later rabbits or birds; an enum would need a migration for each new species.
- `weight_entries.weight_grams` is an integer. Floats accumulate drift and a
  gram is finer than anyone measures.
- `user_settings` is a key/value table, not columns, so settings never need a
  migration.

### Migrations

`AppDatabase.runMigrations(db, from, to)` steps one version at a time and throws
`StateError` if a version in the gap has no registered step. A silent schema
skip would corrupt a breeder's ledger, so the failure is loud by design. Steps
register in `_migrations` keyed by target version; `registerMigration` is
`@visibleForTesting` today and becomes the real registry when version 2 lands.

### DAOs

`RecordDao<T>` is the shared base: `create` (assigns a UUID and stamps
`created_at`/`updated_at` when the columns exist), `update`, `delete`,
`findById`, `all`, `byColumn`. It stamps at the **map** level, not the model
level, so the DAO can set an id without rebuilding an Equatable value object.

Subclasses add only real queries: `AnimalDao.findAll(species:, status:)`,
`findBreedingStock()`, `findOffspring(litterId)`; `VaccinationDao.dueBefore(cutoffMs)`;
`WeightDao.forAnimal` (ascending, for charts) and `latestFor`;
`LitterDao.forDam`/`recent`; `PlacementDao.forAnimal`/`forBuyer`.

## State

Riverpod 3 with hand-written notifiers — no codegen, so `build_runner` is not in
the dependency graph and CI has no generation step.

- `databaseProvider` is the injection point: `main()` overrides it with the real
  file database, tests override it with a temp-file database. Everything else
  derives from it (`daosProvider`, `settingsDaoProvider`).
- `AnimalsController extends AsyncNotifier<List<Animal>>` is the only list
  controller so far. Mutating methods re-read via `refresh()`
  (`invalidateSelf()` then `await future`) so the UI never shows a stale herd.
  Its update method is named `edit`, because `AsyncNotifier` already owns
  `update()`.
- `LockGate` and `HasPin` are synchronous `Notifier<bool>`s. The router redirect
  must decide synchronously on every navigation, so the async PIN digest check
  happens in `main()`/the gate screen and only its *result* is stored here.
- `LocaleController` writes the choice to `user_settings` and publishes a
  `Locale?`; `initialLocaleProvider` is seeded at startup so a restart does not
  flash the wrong language.
- `RemindersResynced` is a `Notifier<bool>` one-shot: `claim()` answers true to
  the first caller of a launch. It is a provider rather than widget state
  because the nav bar moves with `go` and rebuilds the animal list on every
  return (D15), which would otherwise rebuild the alarms on every tab switch.

## Reminders

A dose's `next_due_date` and a screening certificate's `valid_until` are the only
dates this app interrupts a person for. Three files own the mechanism, and none
of them needs a notification channel to be tested:

- `core/utils/reminders.dart` is the policy and nothing else: two reminders per
  due date (a month ahead, and the due morning at `reminderHour`), mornings that
  have already gone dropped, and the record's uuid folded into the two 32-bit
  ids Android identifies a notification by.
- `services/reminder_scheduler.dart` is the only place in the app allowed to name
  `flutter_local_notifications`, and it does so through a seam the app owns —
  `abstract class NotificationWriter`. The seam is not stylistic: the plugin's
  constructor is a `factory`, so it cannot be subclassed and no test double can
  be written without an interface. `replace()` clears the record's own two ids
  before writing them, which is what makes a save and a launch rebuild idempotent.
- `services/reminder_resync.dart` rebuilds the near future from the ledger once
  per launch, because Android drops an app's pending alarms when it is
  force-stopped or cleared away and cannot be woken to notice (D20).

Alarms are scheduled `AndroidScheduleMode.inexactAllowWhileIdle` deliberately: an
exact one needs `SCHEDULE_EXACT_ALARM`, which Google Play audits, for a message
whose only deadline is "somewhere in that morning". The notification channel is
created by the plugin at first delivery, not at startup, so it cannot be observed
on a device before an alarm has actually fired.

## The transfer pack

The paid deliverable is a file that leaves the phone: a PDF for a buyer, a JSON
pack of the whole ledger for the breeder's own backup. Three files, and only the
last one needs a device:

- `services/data_pack.dart` writes and reads the pack against real SQLite. It is
  generic over `dataTables` rather than over the models, so a new table is one
  line in `schema.dart` plus the drift test that compares that list with the
  `CREATE TABLE` statements. Restore runs inside one transaction with
  `PRAGMA defer_foreign_keys = ON`, because `animals.litter_id` and
  `litters.dam_id` point at each other and no insertion order can satisfy both.
  Deferring moves the check to COMMIT, and a rejected COMMIT is not a clean end —
  the handle stays inside the transaction and the next call on it waits forever,
  which is how CI found this. So `restorePack` asks SQLite itself with
  `PRAGMA foreign_key_check` before finishing and throws while a rollback still
  works: a pack that would leave half a ledger changes nothing (D22).
- `services/pack_files.dart` is the whole platform surface: write the bytes where
  the share sheet is allowed to reach them, open the sheet, read a picked file
  back. It is small and it has no logic, which is what leaves the flow above it
  testable (D23).
- `presentation/screens/settings_screen.dart` is the only place that asks before
  it replaces, and it names the counts it is about to destroy first. A restore
  re-arms the alarms afterwards, because the phone holds a different ledger and
  nothing else would tell the alarm manager about it.
- `services/animal_pdf.dart` is the buyer's document: one animal's identity, three
  generations of pedigree, its doses, screenings, weigh-ins with a growth curve,
  visits, the litters it produced or sired, and the placement. It reads the
  ledger through `Daos` and needs no device, so it is CI-testable in every
  shipping language; only the share sheet it hands the bytes to is `pack_files`
  again. It builds its whole widget list before describing the page, because
  `MultiPage`'s `build` callback is synchronous and cannot await a database.
  The font it embeds and the compile-time switch that makes Arabic legible in it
  are D24.
- `services/pdf_layout.dart` is that document's page furniture, shared: masthead,
  section, table, facts grid, row, footer and the font asset constant. Two
  documents restating a font size or the sentence for an empty section is a defect
  someone finds on paper (D29).
- `services/litter_pdf.dart` is the whelping record — one page for a whole litter:
  the mating and its dates, the puppies with their newest weigh-in, every dose the
  litter has had, and who took which puppy home. It is the record of an event
  rather than of an animal, which is why it is not a second call to
  `animal_pdf.dart`.
- `core/utils/litter_rows.dart` decides what those tables say, as plain strings,
  apart from any page. That split exists because a PDF cannot be read back in a
  test: the words are CI-checkable here and only the layout is checked as bytes.

Photos are deliberately not in a pack: `photo_path` is a path on *this* phone, so
copying it would ship a broken reference — the PDF pack is where an image belongs.
The PIN digest is not in a pack either (it lives in the keystore, not in
`user_settings`), so a restored file can neither leak it nor lock anybody out.

## Triage

One card on the animal's ledger answers "what now?" from the record alone. Two
files, and the split between them is what makes the answer testable:

- `core/utils/triage.dart` is the engine: `LedgerFacts` (the animal, its doses,
  weigh-ins and screenings, the litters it stands on, and `nowMs`), one predicate
  per `TriageRuleId`, and `evaluateTriage` which applies the table and returns the
  findings worst-urgency-first. It reads no database, no asset and no clock it was
  not handed, so every rule is a function call in a test.
- `assets/triage/rules.json` is the table: which rules are on, how urgent each
  one is, and every threshold they compare against. `parseRules` refuses a table
  that disagrees with the engine in either direction (D25).

Above them sit `presentation/providers/triage_providers.dart` — the only file that
touches `rootBundle` for the table — and `presentation/widgets/triage_card.dart`,
which takes a `List<TriageFinding>` and renders it, so the wording can be shown to
a widget test without a database. `core/l10n/triage_labels.dart` holds the switch
from rule to sentence; it is exhaustive over the enum, which is what stops a new
rule from shipping with no text in three languages.

## Routing and the PIN gate

`app_router.dart` holds a `refreshListenable` that subscribes to
`lockGateProvider` through `ref.listen`, so a redirect re-runs when the lock
state changes. The redirect is two rules and nothing else:

1. PIN exists and gate is closed and not already on `/lock` → `/lock`.
2. Gate is satisfied (or no PIN exists) and on `/lock` → `/animals`.

There is no "back to lock" edge case because rule 1 is a *not-on* check rather
than a prefix list: any new route — litter detail, an animal's ledger, a record
form — is covered the moment it exists, and rule 2 only ever sends a satisfied
user to `/animals`.

Below the three tabs, detail and form screens are plain nested `GoRoute`s, which
go_router pushes as pages over the tab that opened them. That is deliberate: no
`StatefulShellRoute` (D15), so a tab switch from a pushed route is impossible —
the nav bar belongs to the list screen, and the back button is the only way out.
Static segments are declared before their parameterised siblings
(`/animals/new` before `/animals/:id`, `vaccinations/new` before
`vaccinations/:recordId`) so the word `new` is never read as an id.

## Security model (Phase 0–2)

- The database is **not** encrypted at rest (SQLCipher deliberately deferred:
  it costs a licence decision and a build complexity spike, and the threat it
  answers — a stolen, unlocked phone with the app opened — is already answered
  by the Android screen lock plus the app PIN).
- The PIN is stored as a **salted SHA-256 digest** (16 random bytes from
  `Random.secure()`, per-device salt) inside `flutter_secure_storage`, never as
  plaintext, never in SQLite. Comparison is constant-time over the hex digest.
- `enable()` rejects a PIN shorter than 4 digits *before* writing anything, so a
  rejected attempt leaves no partial state.
- Backup surfaces are closed: `android:allowBackup="false"` plus
  `data_extraction_rules.xml` excluding `salala.db` and the two
  `flutter_secure_storage` preference files from both `cloud-backup` and
  `device-transfer`. Verified against Android's own docs: `allowBackup=false`
  does not reliably block manufacturer device-to-device transfer, which is why
  the extraction rules are not redundant.

## Tests

Tests open a **real** SQLite database through `sqflite_common_ffi` in a temp
file, one per test, deleted in `addTearDown`. That was chosen over an in-memory
fake because the point of these tests is the SQL: foreign keys, cascade rules,
index creation, and ordering. `:memory:` with a per-test suffix does not work —
SQLite on Windows only treats the exact string `:memory:` as in-memory, so
distinct in-memory names fail with error 14.

- `test/data/db/` — schema (tables, indexes, `user_version`, cascade, SET NULL,
  orphan rejection, migration gap throws) and per-DAO behaviour.
- `test/services/` — PIN hashing/gate against an in-memory fake secure storage
  whose `read/write/delete` signatures match the plugin exactly.
- `test/presentation/` — list states, grouping, form validation and save, the
  lock redirect, and Arabic RTL measured off the rendered `Directionality`.

Widget tests keep the real database but cannot simply `await` it: sqflite answers
from a background isolate, and `testWidgets`' fake-async zone never advances it.
`test/helpers/pump_app.dart` therefore exposes `settleRealIo(tester)`, which
alternates a fake-clock pump with a short `tester.runAsync` real wait, then
finishes with bounded pumps instead of `pumpAndSettle` (which hangs while any
infinite animation, such as the loading spinner, is on screen). Missed taps are
fatal in this suite, and the save test asserts that the form route actually
popped — an earlier version passed green while saving nothing.

Two UI rules follow from that: forms scroll with `SingleChildScrollView` +
`Column` and never a lazy `ListView` (`Form.validate()` skips unmounted
fields), and no widget test awaits database work outside `runAsync`.
