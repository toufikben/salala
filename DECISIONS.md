# Salala — decisions

Each entry is a choice that costs real money or real rework to undo, plus the
reason it was made. Re-open an entry only with new evidence.

## D1 — Wedge: small-scale breeders, not pet owners
**Decided 2026-10-04 by the project owner.**
General "pet health record" apps are a crowded, low-retention category with no
paid conversion. Breeders have a hard deadline (a litter), a document they must
hand over (the transfer pack), a legal-ish record set (health screenings,
vaccination dates, pedigree), and money in the transaction. The lineage and
placement tables exist only because of this choice.

## D2 — AI scope: rule-based triage + small intent classifier, not an LLM
**Decided 2026-10-04 by the project owner.**
The original brief claimed on-device generative AI. That was corrected during
the feasibility study: measured `.litertlm` model sizes on this hardware class
(586 MB for Qwen3-0.6B) plus a 2-core/4GB build machine make an LLM feature
unbuildable and unsellable here. Deterministic rules over the *stored record*
answer "is this urgent" with auditable reasoning, which is also what a breeder
trusts and what a regulator would not object to. A small intent classifier for
free text is allowed later, gated on a measured benchmark (Stage 3).

## D3 — Monetization: one-time purchase via Google Play Billing
**Decided 2026-10-04 by the project owner. CONTRADICTED BY D8 — needs re-confirmation.**
Chosen over subscriptions (breeder interest ends when the puppies go home) and
over free+ads (destroys trust in a health record).

## D4 — App-lock PIN without SQLCipher in Phase 0–2
**Decided 2026-10-04 by the project owner.**
SQLCipher means a licence/compliance decision, a heavier native build on a
machine that cannot build natively, and a migration risk, to defend against a
stolen unlocked phone — which the OS screen lock plus the app PIN already
covers. The PIN is stored only as a per-device salted SHA-256 digest in
`flutter_secure_storage`; comparison is constant-time.

## D5 — Three layers instead of the brief's clean architecture
**Decided by the agent, 2026-10-04.**
`domain/usecases/repositories` over a single-device SQLite app is one
pass-through class per table with no second implementation to justify it. The
DAO is the repository; the model is the entity. The DAO boundary is the seam to
abstract later if sync ever appears.

## D6 — Real SQLite in tests (temp files), not in-memory fakes
**Decided by the agent, 2026-10-04.**
The value of these tests is exercising the actual SQL — FKs, cascades, indexes,
ordering. A fake DAO would test the mock. Constraint discovered the hard way:
SQLite on Windows honours only the exact string `:memory:`, so per-test
in-memory names fail with error 14; each test gets its own temp file, deleted
in `addTearDown`.

Second constraint, same family: sqflite answers from a background isolate, which
`testWidgets`' fake-async zone cannot advance. A widget test that awaits a real
query hangs forever **without tripping its own timeout**, so the harness drives
such work through `tester.runAsync` (`settleRealIo` in
`test/helpers/pump_app.dart`) and asserts on outcomes rather than on elapsed
frames.

Third constraint, found the hard way across runs `37383228340` and `37431948933`:
a widget test needs to distinguish *slow* from *stuck*, and a fixed round count
cannot. The first guess was that ten rounds were not enough for a section that
resolves behind seven sequential round trips. Wrong — with forty more rounds of
real time on offer the bar was still up, and that is the point of keying the wait
on the bar and then stating it: the second run said "a database-backed widget
never finished loading" twenty times instead of leaving nineteen screens to fail
as `pumpAndSettle timed out`, which is what an indeterminate bar looks like from
the outside and tells you nothing about why.

Fourth constraint, and the actual cause of those twenty: **an asset read from
inside a provider body never lands under `testWidgets`, while the identical
read from a test body lands fine.** `rootBundle.loadString` awaited by a
provider left the bar up even in a tree of one `Consumer` with no database, no
ledger page and nothing else in it (run `37435525579`, whose 22nd test was
exactly that tree). So the harness supplies the table itself and hands the
file's own contents to the tree through an override of `triageRulesProvider`.
Nothing is stubbed — the parse still runs, the thresholds are the shipped ones.

Fifth constraint, which is what the first version of that remedy cost: **the
asset bundle cannot be read inside `tester.runAsync` either.** Run
`37437885813` moved the `rootBundle` call into the harness's existing `runAsync`
block and added one test that read the shipped provider the same way; that test
hung for ten minutes, and because a pending `runAsync` denies the next one, the
three ledger tests behind it failed with `Reentrant call to runAsync() denied`
at a line they never touched — 4 failures where 1 was real, 41 minutes where the
suite takes two. So the table is read the way the engine test has always read
it: `File('assets/triage/rules.json').readAsStringSync()`, no zone, no clock, no
channel. The one thing left without harness coverage is the provider's own
`await rootBundle` — a line that cannot be executed inside this harness at all,
which is what the phone is for.
Three diagnoses were published and retracted before this one: a round budget
that was too small, the `ref`-after-`await` hazard in D7 below, and reading the
bundle from `runAsync`. The second is a real hazard and still wrong about *this*
symptom, which is why D7 keeps it as hygiene rather than as a fix.

Adjacent trap, recorded because it nearly made that fix a no-op: `find.byType`
compares `runtimeType` exactly and does **not** match subtypes
(`flutter_test/lib/src/finders.dart:1642`), so `find.byType(ProgressIndicator)`
finds neither `LinearProgressIndicator` nor `CircularProgressIndicator`. Asking
for a base class here means `find.bySubtype<ProgressIndicator>()`.

## D7 — No codegen (hand-written Riverpod 3 notifiers, `flutter gen-l10n`)
**Decided by the agent, 2026-10-04.**
Removes `build_runner` from the dependency graph and from CI, which on a
metered, 2-core connection is worth real time. Cost: provider wiring is manual.

Rule that came out of paying for it: **in an async provider body, every use of
`ref` goes before the first `await`.** `Ref.mounted` is
`identical(_element.ref, this)` (riverpod 3.4.3 `lib/src/core/ref.dart:112`), and
when a watched dependency changes while the body is suspended, the element
re-runs and installs a new `Ref`; the abandoned continuation's `ref.watch` then
throws `UnmountedRefException` (`ref.dart:232-242`, reached from the guard in
`element.dart:989`). Riverpod's retry path renders a thrown `Exception` as
*loading, retrying*, so the UI shows a spinner and never an error, and reaching
the error would take roughly 41 seconds of escalating retries that no widget test
ever waits out. The provider that found this watched its rule table after a
database round trip — the watch succeeding is exactly the event that invalidated
the run. This shape is a real hazard and is fixed on sight
(`lib/presentation/providers/triage_providers.dart`), but it was **not** what
left the ledger pages spinning: the asset read in the watched provider was, and
that fails the same way with no `ref` anywhere near an `await` (see D6). Do not
reach for this rule again to explain a stuck bar without a test that separates
the two. Registering the dependency first costs one extra run of the body,
early, while nothing else is in flight. This is a typing-level hazard the
analyzer cannot see: `ref` is in scope after an `await` and using it there
compiles quietly.

## D8 — Payments from Morocco: an unresolved blocker on D3
**Open. Owner decision required before Stage 4.**
Google Play does not offer a payments merchant profile to individual developers
resident in Morocco, so "one-time purchase via Play Billing" as decided in D3
cannot be executed from this account as-is. Ranked responses, from the
feasibility study:

1. **Foreign company (LLC/Ltd) + Play Billing.** Highest revenue ceiling, and
   the only version where D3 works literally. Cost: formation + annual filing
   + a director abroad or an agent service; weeks of paperwork; the payment
   profile becomes permanent.
2. **B2B2C — sell the pack/records workflow to breeding clubs, transfer
   agencies and clinics** (per-seat annual price, invoice or a global
   processor). Fewest install-monetisation requirements, and the smallest
   audience needed for a meaningful amount of money. Best odds for a solo
   beginner.
3. **Sell the travel/transfer document pack off-store** (one-time price paid
   out-of-app; the APK distributed as a direct download) or iOS IAP, which has
   no Morocco payout problem.
4. **Defer money.** Make the KPI 100 real installs plus 100 expressed-interest
   emails, then let the demand decide which of 1–3 to buy.

Until this is settled the app stays network-free and payment-free — nothing in
the codebase depends on D3, so no rework is risked by deciding late.

## D9 — `applicationId` is not finalised
**Open. Owner decision required before the first Play upload.**
The scaffold generated `com.salala.salala`. A package name is a one-way door on
Google Play (it is permanently tied to the developer account and cannot be
changed after upload), and it also blocks option 3 in D8 if the app is ever
distributed under a different vendor. So it is deliberately left unchanged
rather than "fixed" quietly. The candidate is a neutral id that does not encode
the current product name.

## D10 — Backup and device transfer are disabled
**Decided by the agent, 2026-10-04.**
An offline-first health ledger whose PIN digest silently restored onto a new
phone would be a privacy defect. `allowBackup="false"` plus
`data_extraction_rules.xml` excluding `salala.db` and both
`flutter_secure_storage` preference files from `cloud-backup` and
`device-transfer`. Android's documentation confirms `allowBackup="false"` alone
does not reliably block manufacturer device-to-device transfer, so the rules
file is load-bearing, not decorative. Export/import (Stage 2) is the deliberate,
user-initiated replacement.

## D11 — Forms use `SingleChildScrollView` + `Column`, never a lazy `ListView`
**Found by a test, 2026-10-04.**
`Form.validate()` only visits *mounted* `FormField`s. Inside a `ListView`, a
field outside the cache extent is not in the tree, so validation silently
skipped it: the animal form would have saved a nameless animal whenever the user
had scrolled down to the Save button. The form is short and fixed-size, so
laziness bought nothing and cost correctness. Rule for every future form screen
(health tests, vaccinations, placements): scroll the content, do not virtualise
it.

## D12 — A missed tap must fail the test
**Decided by the agent, 2026-10-04.**
`WidgetController.hitTestWarningShouldBeFatal = true` in the widget suite. The
same test once passed green while saving nothing: the tap landed on the scroll
view instead of the button, and the only assertion was `find.text('Nala')` —
which matched the form's own text field. Assertions now also prove the route
popped (`find.byType(AnimalFormScreen), findsNothing`), so "it saved" is
falsifiable rather than assumed.

## D13 — The debug APK ships as a release asset, not an Actions artifact
**Forced by the account, 2026-10-04.**
CI's first run built everything green and then failed on `Upload debug APK`:
*"Artifact storage quota has been hit"*. The cap (~500 MB on this plan) is
account-wide, and stale builds from other repositories already fill it — nothing
`salala` does can fix that. The workflow now publishes the APK to one rolling
`debug-apk` prerelease with `--clobber`, which uses a separate storage budget and
keeps exactly one debug build per channel instead of growing with every push.
Fetch it with `gh release download debug-apk -p "*.apk"`.

## D14 — A whelping and its puppies are written in one transaction
**Decided by the agent, 2026-10-04.**
`LitterDao.createWithPuppies` inserts the litter and its animals inside
`db.transaction`, and stamps `litter_id`, `dam_id` and `sire_id` itself rather
than trusting the caller. Two reasons: a half-written whelping (litter with no
puppies, or puppies pointing at a litter that was never saved) is precisely the
record a paper ledger cannot produce, and the lineage columns are the one thing
every later feature — pedigree, transfer pack, health inheritance — reads. The
rollback is tested by making the second puppy collide with an existing primary
key and asserting the litter row is gone.

## D15 — Three screens, three plain nav bars, no shell route
**Decided by the agent, 2026-10-04.**
`SalalaNavBar` is carried by each top-level screen and navigates with
`context.go`. A `StatefulShellRoute` would preserve a navigation stack per tab,
which nothing needs at three lists, and it makes every screen harder to pump in
isolation — the widget tests drive the real app, so the simpler frame is also
the more testable one.

## D16 — Expected whelping dates are shown only for species we can name
**Decided by the agent, 2026-10-04.**
`gestation.dart` knows dog (63 days) and cat (65). An unlisted species returns
null and the UI shows no estimate. Guessing 63 days for a rabbit or a breeder's
unusual species would put a wrong date in the place of an honest absence, and a
wrong due date is the kind of thing that costs a litter.

## D17 — A record list is an `autoDispose` family provider, not a controller
**Decided by the agent, 2026-10-04.**
`vaccinationsForAnimalProvider` and `weightsForAnimalProvider` are
`FutureProvider.autoDispose.family<…, String>` keyed by animal id, and the four
mutating helpers (`saveVaccination`, `deleteVaccination`, `saveWeight`,
`deleteWeight`) write through the dao and invalidate that one key. Herds are
open-ended — a controller per animal would hold every animal's history in memory
for the whole session, and a `FamilyAsyncNotifier` is a class per table per
screen for the same result. Animals and litters keep their `AsyncNotifier`
controllers because those two lists are also read by *other* screens; a dose
belongs to exactly one ledger.

## D18 — Weigh-ins are stored in grams, typed in kilograms, and never edited
**Decided by the agent, 2026-10-04.**
`weight_grams` is an integer (no float drift, no unit column, no ambiguity in a
chart). The form asks for kilograms because that is what a scale and a person
say — `parseWeightToGrams` converts and rejects anything that is not a positive
weight, and `formatWeight` switches unit at one kilogram, which is where breeders
switch it in speech: a 430 g puppy is never "0.43 kg" out loud. A stored weigh-in
is append-only, so a mis-typed row is deleted and measured again rather than
edited: a correction silently overwriting a measurement is the failure mode that
matters once the curve is shown to a buyer or a vet. The weigh-in form now says
that out loud (`weightAppendOnlyHint`), because the form is exactly where a
breeder looks for the edit button the ledger does not have.

## D19 — The CI debug key is cached, not committed
**Decided by the agent, 2026-10-04.**
The first two device installs proved the problem: `INSTALL_FAILED_UPDATE_INCOMPATIBLE`,
because every GitHub Actions runner generates its own `debug.keystore` — under
`~/.config/.android/`, measured on run 37353640524's probe, not the `~/.android`
the docs suggest — so build N and build N+1 of the same app are signed by
different keys and Android
will not update one over the other. The fix could have been a committed
`debug.keystore` (the template gitignores `**/*.keystore` for a reason) or a
repo secret (a credential in someone else's account, and a build that fails
loudly when it is missing). `actions/cache` on the generated file gives a stable
key with nothing to protect and nothing to leak: if the cache is ever evicted the
next build simply needs one `adb uninstall` first, which is what was happening on
every install anyway. Release signing is untouched — there is no release key yet,
and Stage 4 decides that one deliberately.

## D20 — A launch rebuilds the alarms; the ledger is the durable copy
**Decided with the owner, 2026-10-05.**
Measured on the test phone: `am force-stop com.salala.salala` took every booked
reminder out of AlarmManager while the ledger rows survived untouched. Android is
allowed to do that — an app's pending alarms are not durable state — and there is
no way to be woken to notice, so the only moment left to repair them is the next
time the person opens the app. `resyncReminders` therefore runs once per launch
from the animal list, reads the doses and certificates due inside
`reminderHorizonDays` (the month-ahead lead plus a fortnight), and hands each one
to the same `ReminderScheduler.replace` a save uses, which clears the record's own
ids before writing so a rebuild cannot double-book.

Deliberately *not* done: re-booking every due date in the ledger (a five-year
breeding plan is not a pending alarm, and a launch should not walk it), and asking
for a foreground service or a battery-optimisation exemption — that is a Play
policy argument Stage 4 has with measured delivery evidence in hand, not a spike
guessing at one.

## D21 — One numeral system on screen: Latin digits, in every language
**Decided with the owner, 2026-10-05.**
Device finding 6: the Arabic ledger mixed two numeral systems inside one row —
`18.50 كغ` in Latin digits next to `٥ أكتوبر ٢٠٢٦` in Arabic-Indic — because dates
go through `intl`, which gives Arabic its CLDR-default digits, while
`formatWeight` writes ASCII. The owner chose Latin digits for every language,
over Arabic-Indic and over a settings toggle. The reason is the thing this app
exists to produce: a dose date gets read against a veterinary certificate typed
in Latin digits, and Maghrebi paperwork is Latin-numeral even when the
conversation is Arabic. Month and day *names* stay Arabic, so the row reads
`6 أكتوبر 2026` — only the digits move. One place does the work: `formatDayFor`
is the app's only `DateFormat` call, so every screen, notification body and
future export inherits the rule. A toggle was rejected deliberately — it would
double the formatting surface (dates, weights, money) to postpone a decision the
ledger is allowed to just make.

D21 covers the digits Salala writes. The Material date picker is Flutter's own
surface, and the device check saw it disagree **with itself**: its day cells
paint `1 2 3…` (they go through `MaterialLocalizations.formatDecimal`, which
gives Latin digits for `ar`) while its header and month label paint
`الثلاثاء، ٦ أكتوبر` and `أكتوبر ٢٠٢٦`, and the tile behind it reads
`6 أكتوبر 2026`. That is the disagreement D21 said would settle the question, so
the picker is in scope: a date is chosen in one numeral system and confirmed in
another, inside one dialog, on the way into the ledger.

What the dependency ruled out, read rather than guessed: `ar_DZ` is the only
other Arabic tag `intl` ships besides `ar` and `ar_EG`, and its month names are
Algerian (`جانفي، فيفري، أفريل، ماي`) — it would silently rewrite every label;
`ar_EG` is the one whose `DateSymbols` carries `ZERODIGIT: '\u0660'`, i.e. the
Arabic-Indic digits themselves. So no `showDatePicker(locale: …)` value fixes
this, and `ar` — the tag the app already uses — is the one that keeps the words.

What shipped is `intl`'s own switch, called once in `main()` beside
`initializeDateFormatting()`: `DateFormat.useNativeDigitsByDefaultFor('ar',
false)`. One line, every Flutter surface that formats a date rather than only
the picker, and it cannot change a word — only the digits. **The verification is
the phone's screenshot of that same dialog.** A scratch `DateFormat` run against
the resolved `intl` 0.20.3 printed Latin digits for `ar`, which is the opposite
of what the build on the phone painted; the dependency source and the device
disagree here, so only the device counts, and if the picker still shows
`٢٠٢٦` the line comes back out and the deviation is recorded as open instead of
papered over.

## D22 — The pack is the whole database, and restoring means replacing it
**Decided here, 2026-10-05.**
The question behind "what if I lose my phone" has one honest offline answer: a
file that holds everything, and a restore that puts it back. So a pack is every
row of every table in `dataTables`, in one JSON document, and importing one
**replaces** the ledger rather than merging into it.

Merge was rejected on purpose. Merging needs a rule for "same id, different
row" — a phone that has been used since the export has edits the pack does not
know about, and no offline app can decide which side wins without a field-level
diff the breeder cannot audit. Replace needs no such rule: the pack is a snapshot
of a device at a moment, and the dialog names the animal count, the record count
and the day it was made before anything is destroyed. The breeder compares that
against what they expect and presses Replace.

The restore is all-or-nothing, and not by hand-written validation. `animals` and
`litters` reference each other, so no insertion order satisfies both; the
transaction opens with `PRAGMA defer_foreign_keys = ON`, which moves every
foreign-key check to COMMIT. A pack with a dangling reference — or a column this
build does not have — therefore fails at COMMIT, SQLite rolls the whole thing
back, and the phone keeps the ledger it had. Three tests pin this instead of a
paragraph claiming it: a missing dam, an unknown column, and a clean round trip
fingerprinted table by table.

Two refusals are also deliberate. A pack that names a table this build does not
know, or is missing one it does, is rejected rather than half-read: a silent
partial restore is how a backup quietly loses a puppy. A pack whose `formatVersion`
or `schemaVersion` is newer than this build is rejected too — a newer app knows
things this one cannot, and "restore anyway" would destroy rows to write nothing.

Not in the pack: photos, because `photo_path` points at a file on *this* phone and
copying a path would ship a broken reference (the PDF pack is where an image
belongs); and the PIN, because the digest lives in the device keystore rather than
in `user_settings`. A restored file can therefore neither hand over the PIN nor
lock its owner out of the app.

## D23 — Files move through the system share sheet and the system picker
**Decided here, 2026-10-05.**
Export hands the pack to Android's own share sheet; import opens Android's own
file picker. There is no account, no upload and no cloud package in `pubspec.yaml`,
which is what makes the offline promise checkable rather than a claim: the backup
leaves the phone through the breeder's own hands, into WhatsApp or Drive or a USB
stick, whichever they already trust.

Two platform facts shaped the code, both read out of the plugins' own sources
rather than guessed.

- `share_plus` 13 bundles a `FileProvider` that publishes **only**
  `<cache>/share_plus/`. A file anywhere else cannot be granted to another app, so
  the pack is written where the sheet is allowed to reach, not where it is tidy.
  The cache is also evictable, which is fine here: the pack is a handoff, the
  ledger is the durable copy.
- `file_selector` is called with **no** `acceptedTypeGroups`. A pack that was
  renamed, emailed, or copied off a stick arrives as `text/plain` or with no type
  at all, and a filter that hides the file reads to the breeder as the app
  refusing their backup. Whether a picked file is a pack is then decided by
  `parsePack`, with a message that says which of the refusals it met.

Open, and to be measured on the device rather than guessed at: the Android picker
returns the chosen file's whole bytes in memory (`XFile.fromData`), so a large
ledger is held twice at once — once as text, once decoded. A pack of a few hundred
animals is small enough not to matter, and the device pass will say what "few
hundred" costs in megabytes before any streaming reader is justified.

## D24 — The buyer's PDF embeds one Arabic font, and CI builds with shaping on
**Decided here, 2026-10-05.**
The per-animal pack a buyer keeps has to be readable in the language the breeder
sold in. `pdf` 3.13.1 has no text shaping engine: `obj/ttffont.dart` maps each
codepoint through the font's `cmap` and draws that glyph, nothing more. Arabic
therefore cannot be fixed by a smarter writer — it needs a font whose `cmap`
already carries the presentation forms the shaped text lands on.

So the app bundles **Amiri** (`google/fonts` `ofl/amiri/Amiri-Regular.ttf`, 431 KB,
SIL OFL 1.1, licence text committed beside it), measured rather than assumed:

- 1699 mapped codepoints; Arabic block `0600–06FF` 255; Presentation Forms-A
  `FB50–FDFF` 611; Presentation Forms-B `FE70–FEFF` 140.
- Every codepoint `pdf`'s own `arabic.convert()` emitted for eleven realistic
  Arabic strings was present in that `cmap` — the test that decided the font,
  because a form the file lacks is drawn as an empty box, silently.
- Latin letters and Latin digits are in the same file, so one font covers `ar`,
  `en` and `fr` and the document never mixes faces mid-line.

Two consequences are written down because they are the parts that can rot:

- Shaping is a **compile-time** switch inside the package
  (`use_arabic`, default `!use_bidi`, i.e. off). CI passes
  `--dart-define=use_arabic=true` to both `flutter test` and `flutter build apk`,
  so the tests verify the binary the phone runs. Built without it, Arabic pages
  come out unshaped and the code still reports success.
- The direction has to be set on the page (`MultiPage(textDirection:)`), because
  `text.dart` only calls `arabic.convert` when the resolved direction is RTL. The
  writer derives it from `AppLocalizations.localeName`, not from a parameter a
  caller can get wrong.

The font is loaded from `assets/`, not declared as the app's typeface: the
screens keep the platform font, and 431 KB is worth carrying only for a document
that has to look the same on a printer as on the phone.

## D25 — Triage is a rule table over the record, and it never names a disease
**Decided here, 2026-10-05.**

The ledger already holds the facts that matter on the day a puppy is due or a
rabies shot slipped: dates, ages, weights. A deterministic table can turn those
into "how fast to move" without pretending to know what is wrong. That is the
whole of Stage 3's first half, and the limit is the point — the three answers
`TriageUrgency` allows are **act now**, **keep watching** and **routine vet
visit**. There is no fourth, because a rule over a record nobody verified cannot
honestly produce a diagnosis.

**Rules are data, predicates are code.** `assets/triage/rules.json` carries each
rule's id, urgency, on/off switch and thresholds; `lib/core/utils/triage.dart`
holds one predicate per rule, keyed by a `TriageRuleId` enum. `parseRules` refuses
a table that drifts from the engine in either direction: an id nobody wrote a
predicate for, a rule the engine has that the table left out (a silent gap in the
answer), the same rule twice, an urgency outside the three, and a threshold typed
under a name the predicate does not read — the last one matters most, because a
silently ignored `maxDays` would keep firing at the number nobody meant.

"Editable without a rebuild" is written down honestly here: the numbers and the
switches are one file a release retunes without touching the engine, but **adding
a new rule still needs a build**, because a predicate is code. The alternative —
an expression interpreter inside a vet ledger — buys a flexibility nobody asked
for and spends the one thing the app has, which is that its output is auditable.

**What the table may not read.** Vet visits are not inputs: `reason` and
`outcome` are free text, so a rule over them would be guessing at what "check
again" meant three weeks ago, and a wrong "act now" costs more trust than a
missing one. Breed-specific risk, which the roadmap listed, is **not**
implemented: `breed` is free text too, and a table keyed on breed names would
assert a health claim this app has no way to check. It stays an open item.

**Where the record is thin, the table keeps quiet.** A missing birth date
silences every age-dependent rule rather than assuming an age. A weight drop on
an animal of unknown age reads as the adult case ("watch"), since "act now" is
reserved for the young, who dehydrate in a day. A health test result is only
treated as clear when it is one of six words a breeder types for "nothing found"
(`clear`, `normal`, `negative`, `free`, `unaffected`, `0`); anything else is
quoted back as typed, because the app does not know what "Grade 2" means. A
deceased animal gets no findings at all, said once in the engine rather than in
nine predicates.

**Wording is checked by the compiler.** `triageMessage` switches over
`TriageRuleId`, so a rule added to the engine without a sentence does not
compile. Numbers reach those sentences as ASCII strings, never as `int`
placeholders through `intl`, which would render "١٢" in Arabic and break D21
mid-card.

**A counted noun is picked in Dart, not by `intl`.** The same D21 rule that
keeps the digits Latin rules out `Intl.plural`, because plural logic renders the
number itself through the locale's number format. So the day count lives in
`daysSingle`/`daysDual`/`daysPlural` ARB entries that take a `String`, and
`daysPhrase` chooses among them. That is also the only place the app's Arabic
grammar is written down: 2 takes the dual, 3-10 the plural, 1 and 11-99 the
singular accusative. English and French need only the first and the third, and
say so by filling the three keys with two distinct phrases. The alternative —
embedding " days" in each rule's sentence — shipped "due in 1 days" to a phone
screen, which is what put this here.

The small intent classifier the same roadmap stage mentions is **not** in this
batch: there is no labelled Arabic symptom data in hand and no measured
benchmark, and a classifier without either is a second, less auditable opinion
beside the table.

## D26 — A derived screen watches what it derives from

**Date:** 2026-10-06. **Status:** in force.

A screen that computes something over stored rows must read those rows through
the providers that show them, not through the DAOs underneath.

**Why.** The triage card did the opposite, and a phone found it: saving a Rabies
dose updated the Vaccinations section on the same screen and left the card above
it saying "Nothing in this record calls for a next step" until the breeder
navigated away and back. The verdict had been a snapshot of the instant the page
opened. Every write path in `record_providers.dart` already invalidates the list
it touched, so the card was one `watch` away from being correct — and, more to
the point, one `watch` away from staying correct for any record type written
later that nobody remembers to add an invalidation for.

**How to apply.** Read facts off `ref.watch(...future)` for the providers the
screen already keeps, and put every `ref` use before the first `await` (D7). The
alternative fix — a matching `ref.invalidate(triageForAnimalProvider(id))` at
each of the ten write sites — was rejected because it is a rule with no
enforcement: the next record type added to the ledger would silently reproduce
the bug, and 195 tests would stay green while it did.

**Cost, stated.** The card now re-runs on any herd or litter refresh, and it
reads the whole herd and litter lists where it once asked for one row by id. At
the sizes this app's users work at that is nothing; at a herd of thousands it
would be a query to revisit.
