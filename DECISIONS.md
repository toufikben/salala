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

## D27 — A section of a lazy list does not start its own database read

**Date:** 2026-10-07. **Status:** in force.

Every widget that is a child of a scrolling list gets its record lists handed
down by the screen, watched in the screen's `build`. A section is never allowed
to call `ref.watch` for a query the first time it scrolls into view.

**Why.** The Placements section added to the animal ledger did exactly that, and
run `37560315166` lost eight tests to it. Every failure was `pumpAndSettle timed
out` on the line *after* a scroll, and every one was preceded by sqflite's own
`Warning database has been locked for 0:00:10.000000`. The mechanism is not
subtle: `ListView(children: [...])` hands its children to a sliver delegate that
builds them only as they approach the viewport, so the five older sections' rows
were simply not on screen yet — but *their* queries had already started, because
the screen's `build` watches them. The new section was the first one whose query
lived inside its own `build`, so the read began midway through a scroll, in the
fake-async zone, where SQLite's other isolate can no longer be given real time to
answer (`settleRealIo` exists precisely to open that window, and it runs before
the scroll, not during it). The section was then stuck on a spinner forever, and
a spinner is an animation that never settles.

**How to apply.** In a screen with a lazy list, `ref.watch` every list its
sections show, in the screen's `build`, and pass the `AsyncValue` down; a section
that needs two lists takes two `AsyncValue`s and one retry callback that covers
both. The rule is not a test concession — the deferred version was also the only
section on the page that rendered `ref.watch(x).value ?? []`, which turns a
contact list that failed to read into a page of "no buyer" rows about people who
are in the ledger. Both halves of that are the same mistake: a section deciding
its own data state instead of showing what the screen already knows.

**Cost, stated.** The screen reads every list it will show even for the part of
the page the breeder never scrolls to, so a cold open costs one query per section
rather than one per section *seen*. That is already true of the five older
sections, and at herd sizes it is nothing. What the rule does cost is a little
ceremony in `animal_detail_screen.dart`, where four arguments now travel to
`_PlacementSection`; and it means a section cannot be dropped into another
screen without also wiring that screen's reads, which is the point.

## D28 — The home screen answers for the herd, not only for the animals

**Date:** 2026-10-08. **Status:** in force.

The animal list carries one agenda block above the herd: every dose due within
`agendaWindowDays` (14), *plus* everything already overdue, one row per animal,
naming that animal's earliest booking, for animals whose status is `active` only.
Tapping a row opens the ledger it belongs to. The block renders nothing when
there is nothing to book.

**Why.** Everything before this answered "what does *this* animal need?", and the
question a breeder actually starts the day with — "what is overdue, and what is
due in the next fortnight, across everything I own?" — cost one tap per card. The
paid pack is per animal; the day is per herd, and the herd had no surface. A
fortnight because it is the span someone can act on: a dose due in March is not
this week's booking, and a window wide enough to include it turns an agenda into
the calendar this app does not have. One row per animal because the ledger shows
the whole history, and the block's value is that nothing needs opening.

**How to apply.** `buildHerdAgenda` in `lib/core/utils/agenda.dart` is pure and
owns every one of those choices — the window, the null due dates, the status
filter, one-row-per-animal, the sort — and it is the only place that decides them.
`agendaDosesProvider` returns the raw rows from `VaccinationDao.dueBefore` rather
than finished items: the animals have to be folded in as well, and a provider that
watched `animalsProvider` would rebuild the agenda on any edit to any animal and
merge two reads that the screen can time on its own (D27). `agendaHorizonMs` is
shared by the query and the fold so they cannot disagree about the fortnight.
Any new dose write path invalidates `agendaDosesProvider` next to the family it
already invalidates — and a restore replaces the whole database, so it asks for
the agenda by name; `test/presentation/herd_agenda_test.dart` is the enforcement
for the delete path. Day counts are the triage counts (D31: whole calendar days,
zero meaning today) and the sentences are the triage dose messages plus the
reminder's own "is due today", so a dose the two screens do mention is never
counted two different ways. They are not the same list: the agenda books anything
past its date, while `dose_overdue` waits out a three-day grace — a shot two days
late is a row on the home screen and nothing on the card, which is the to-do list
doing its job and the medical rule not nagging yet.

**Cost, stated.** A dose due in three weeks is invisible until day 14 — the agenda
is a window, not a forecast, and that is deliberate. Reusing the triage wording
means an edit to `triageDoseOverdue` changes the home screen too. The herd-wide
query runs on every cold open of the home screen; it is the read
`VaccinationDao.dueBefore` already makes at launch for the reminder resync, and
`idx_vaccinations_due` covers it, so the agenda costs the screen one indexed
range scan rather than a new one. And an animal with something to book is named
twice on the home screen, by its row and by its card: that is the block working,
and it is why a test on that screen selects `AnimalCard`'s row rather than counting
a name.

## D29 — A document's words are chosen apart from its page

**Decision.** The PDF services lay out; they do not decide what a line says. The
text goes through two shared halves: the page furniture in
`lib/services/pdf_layout.dart` (masthead, section, table, facts, row, footer, and
the font asset constant) and the rows themselves in a pure function beside the
model they describe — `lib/core/utils/litter_rows.dart` for the whelping record.
The two gaps every record has are also shared: `formatDayOrUnknown` in
`core/utils/date_utils.dart` and `formatPriceWithCurrency` in
`core/utils/money.dart`.

**Why.** This app has two verifiers: GitHub CI and one phone. A PDF cannot be read
back by either from the repository — `pdf` draws through the embedded font's glyph
ids, so a test over the bytes can prove only that a document came out. That made
every wording bug in Stage 3e (the handover that printed the previous family, the
price written as `2500.00 `, the country that never reached the page) a device
discovery, and the device is the scarcest thing here. Strings chosen apart from the
page are strings CI can assert. The shared furniture is the same argument in
layout form: two documents that answer "nothing recorded" differently, or disagree
about what an empty table prints, produce paper that reads as two products.

**How to apply.** A new document calls `pdfMasthead`, `pdfSection`, `pdfTable`,
`pdfFacts`, `pdfFooter` and takes `pdfFontAsset` — it does not restate a font size,
a border or the sentence for an empty section. Its rows come from a pure function
that takes `AppLocalizations` and a locale tag (never a `BuildContext`: the page is
built after the reads, which is why `formatDayFor` sits beside `formatDay`
), and that function is tested as text before any bytes exist. Dates and
money go through the two helpers above so a missing value is always the app's own
word, never a blank the reader has to interpret.

**Cost, stated.** The animal's own pack used to build most of its tables inline — it
grew section by section and forty tests were pinned to that shape. Two shapes for
one kind of document is real debt, and it was paid down in the same batch it was
named: those rows are now `core/utils/animal_rows.dart`, tested as text, and
`animal_pdf.dart` only reads and arranges. What stays inside a service is stated
rather than hidden — the pedigree, whose lines *are* its nesting, and the growth
chart, which is a picture and not a sentence. The row functions also take l10n and
a locale tag everywhere, which is more parameters than a screen would pass, and the
fixtures exist twice: once as text in `test/core/litter_rows_test.dart` and
`test/core/animal_rows_test.dart`, once as rows in `test/services/litter_pdf_test.dart`.

## D30 — The home screen filters the herd it already has

**Date:** 2026-10-08. **Status:** in force.

Searching the herd is a pure function over the list the screen is already showing:
`core/utils/herd_search.dart` normalises both sides, scores each animal, and
returns the matches strongest-first, ties keeping the order the list was in. The
screen holds the typed text as its own state and calls that function in `build`.
There is no search query, no debounce, and no second list of animals.

**Why.** A card list answers "what do I own?" in the order the database happens to
return it, and at a hundred animals that is the scroll which makes a breeder stop
trusting an offline app. The alternative — `LIKE` per keystroke — puts a database
read inside a lazy `ListView`, which is the shape D27 exists to forbid, and makes
two sources of truth for one herd: the rows SQLite found and the rows the widget
kept. The read the screen already made *is* the whole herd, so filtering it costs
nothing and cannot disagree with anything. Normalisation is the other half of the
decision, and the reason the rules are not SQL: a phone keyboard writes أ where the
ledger wrote ا, an accent is typed or not typed depending on whose phone it is, and
the digits of a microchip come off a sticker with spaces and dashes in them. A phone
set to Arabic numerals also writes `٢٥٠` into a field the ledger holds as `250`:
D21 is a rule about what this app paints, not about which keys sit next to it. SQLite
folds none of that, and a search that misses "أسود" because the query was typed
"اسود" is indistinguishable, on screen, from a herd that does not contain the dog.
The first run of these tests proved the point twice over: `ى`, `ی` and `ي` print
almost identically in a source file, one of the three was missing from the fold
table, and the test that should have said so was itself written with the wrong
shape in it. Anything in `test/core/herd_search_test.dart` that has to tell
look-alike letters apart is written as a code point for that reason.

**How to apply.** `normalizeForSearch` is idempotent, which is what makes a query
and a stored field comparable at all; it is *not* cached per animal, and the cost
of that is stated below rather than hidden behind a promise. A field becomes
searchable by adding it to `_score` with a strength and pinning it in
`test/core/herd_search_test.dart`; the widget never learns about it. The ladder has
whole rungs: name exact, name prefix, name substring, then an exact registration or
chip (the best of the two numbers, not the first that answered), then a partial
number, then breed or note. A name is what someone types, so any name hit outranks
any number hit; a number is what settles which dog is on the table. The comparator
carries the original index because `List.sort` is not stable, and cards that
rearrange two equal matches between keystrokes look broken even when the set is
right. A query that normalises to nothing — the space a keyboard inserts, the dash
typed before a number nobody stored with one — is answered by `queryFilters`, and
the screen asks it once: the agenda (D28) is hidden and the sections are dropped
only when that says something is actually being asked. While it does, the matches
come back as **one flat ranked list**: the two sections exist to give shape to
everything a breeder owns, and splitting a search by breeding stock prints a weak
note hit above the dog whose name was typed in full, which is the ranking thrown
away.

**Cost, stated.** This works because the herd is already in memory, and it stops
working at the size where that stops being true — a few thousand animals, when the
list itself becomes the problem before the search does. At that point the fold
tables move into a DAO that normalises, and the screen keeps its shape; the scoring
stays where it is. The query is the screen's own state, so leaving home and coming
back shows the whole herd again rather than a word typed days ago. Dropping
punctuation makes "984-2" and "9842" the same search, which is what a sticker asks
for and also why a mistyped digit can bring up two animals. The search covers name,
registration, chip, breed and the animal's own note, because a note sits on the row
that is already in memory and costs nothing to read. What it does not reach is the
symptom log: "the one that limped" finds the dog only if somebody also wrote that in
its notes, and a record that lives in another table would be a second read inside a
screen that deliberately has one (D27).

## D31 — A day is a date, not 86,400,000 milliseconds

**Date:** 2026-10-08. **Status:** in force.

Every date a breeder reads off paper — a booster's due day, a certificate's last
valid day, a mated day, a birth day — is stored at **local midnight**, because it
comes off a day picker (`msFromDay`). So a count of days between two of them is a
count of *dates*: `wholeDaysBetween(fromMs, toMs)` in
`lib/core/utils/date_utils.dart`, negative while the first is still ahead, and
**zero when both fall on today**.

**Why.** Compared as instants against `DateTime.now()`, the elapsed time between
this morning's midnight and lunchtime is half a day, and each rule rounded that
half-day its own way. The home agenda painted a dose due today in red as "1 day
overdue"; the card's `dose_due_soon` called tomorrow's dose "due in 2 days" from
lunchtime onwards and said nothing at all about today's; `health_test_expired`
read a certificate whose last day is today as lapsed from 00:00. None of it was
tested, because every fixture built its due date by adding whole days to a clock
time: the midnight shape the app actually writes had no test in it anywhere. A day
count a breeder can disprove with a
calendar is the most expensive number in an offline ledger — D21 exists for the
same reason.

**How to apply.** Any new day count calls `wholeDaysBetween` instead of dividing a
millisecond difference, and the *gates* read as dates too:
`if (facts.daysSince(until) < 1)` means "the date has not gone past", which is not
the same test as `until < nowMs`. A count of zero is a sentence, never a number
rounded up: `dose_due_soon` and the agenda row both branch on `days == 0` into
`reminderDueBody` ("Rabies is due today", the wording the notification already
used) before the overdue/soon messages. `LedgerFacts.daysSince` is the only
day-counting door a rule may use, which is what keeps the card, the agenda and the
reminder saying one thing about one date (D28). Tests that care about a boundary
construct the midnight shape on purpose — `_todayMidnight` in
`test/core/agenda_test.dart` and `test/core/triage_test.dart` — because a fixture
whose due date carries the clock's own hour cannot catch this class of bug at all.

**Cost, stated.** `daysSince` also reads *timestamps*, so a symptom logged at
23:00 is "1 day ago" at 01:00, and a puppy born at 23:00 yesterday is one day old
this morning; the log prints the hour beside the date, so the count and the record
can still be checked against each other. The division is rounded, not floored, and
that is what makes Morocco's clock shifts survivable: two local midnights either
side of a 23- or 25-hour day still count as one day, where an instant difference
would drift by an hour and move a due date into the wrong week. The day count is
still local, not UTC, so a pack restored on a phone in another timezone recomputes
ages from *its* midnight — true of every date in this app, and stated in D22's
restore rather than fixed here.
