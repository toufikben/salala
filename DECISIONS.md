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

## D7 — No codegen (hand-written Riverpod 3 notifiers, `flutter gen-l10n`)
**Decided by the agent, 2026-10-04.**
Removes `build_runner` from the dependency graph and from CI, which on a
metered, 2-core connection is worth real time. Cost: provider wiring is manual.

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
surface, and the device check saw it render Arabic-Indic day cells
(`١٥ أكتوبر ٢٠٢٥`); `showDatePicker` takes a `locale`, but which locale tag makes
it switch numerals without losing the Arabic month names is a measurement, not a
guess. Left open deliberately until the first build with the row fix is on the
phone — if the picker and the row disagree on screen, that is the moment to decide
whether the picker is in scope.
