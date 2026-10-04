# Salala — structural feasibility study

Object of study: `C:\Users\Administrator\Downloads\البرومبت الكامل.txt` (968 lines), a
specification for an offline-first, no-account, encrypted pet-health app with a
nine-agent on-device AI "vet assistant", OCR of veterinary certificates
(including Arabic), bundled reference datasets, PDF/QR/structured export, and a
nine-stage roadmap ending at **$500K/year and 10,000+ paying users**.

Study date: 2026-10-04. The owner granted explicit permission to correct or
verify any claim in the spec, and to propose better product wedges. Six of the
spec's load-bearing claims did not survive that check. They are listed first,
because a build plan that ignores them produces an app that cannot install,
cannot legally ship its content, and cannot charge.

## 1. Claims tested

| Spec claim | Verdict | Evidence |
|---|---|---|
| On-device LLM under 200 MB RAM, app+models <500 MB, Android 8+/iOS 14+, <3s response | **Impossible as written** | A usable small LLM needs ~1.5–3 GB RAM; Google's edge stack requires Android 12 / iOS 16.5+; the smallest practical instruct model measured in this workspace is 586 MB (Qwen3-0.6B `.litertlm`). The four constraints cannot hold simultaneously. |
| Nine AI agents diagnose skin / eye / dental / stool / wounds | **No such models exist publicly** | Academic vet-derm sets are small and closed; the commercial ones (Tably, PetMedix, Vetdia) are cloud-only and do not license weights. A solo developer needs 5–20k labelled images *per class* plus veterinary cooperation. |
| Scan an Arabic vaccination certificate offline with ML Kit | **Dead end** | ML Kit Text Recognition v2 has no Arabic support. Tesseract `ara` is weak on camera photos. Manual entry or a different pipeline is required. |
| Bundled poison/toxin, parasite-risk, breed and drug reference content | **Licensing blocks most of it** | Red: ASPCA toxin DB, CAPC risk maps, AKC/FCI/CFA/ARBA breed text and photos, Plumb's/Merck drug content. Green: Wikidata (CC0), GBIF/ITIS (CC-BY), EU/DEFRA/USDA pet-movement data (public/OGL), FDA CVM animal-drug data. |
| Export to "OVF, a documented standard any compliant app can import" | **Misleading** | `vetformat.org` / `github.com/vetformat/ovf` already uses that name (Apache-2.0) with near-zero adoption, so "any compliant app" is false. The honest target is HL7 FHIR's `patient-animal` extension, described as an alignment, not a standard we own. |
| No payments, no backend, no external API — while success = paid users and $500K/yr | **Self-contradictory** | The appendix forbids the very mechanism the revenue target requires. Resolved by decision D3 (Play Billing) — which then hit the payment-geography problem in §5. |

## 2. Market structure and the wedge

**Privacy is not a purchase driver in this category.** The pet-health apps that
succeed are cloud freemium, because what owners pay for is reminders and
multi-device sync, not secrecy. A no-account offline app therefore has to be
judged against a *specific* job, not a general audience.

**Breeders are that job** (owner-confirmed wedge, D1). Evidence for willingness
to pay: `Breedera` charges £9.99/month and there are several competing paid
tools (BreederCloudPro, BreedTools, BreederBuddy). The pain is concrete and
document-shaped: pedigree, health screenings, vaccination dates, and a pack that
transfers to the puppy buyer with a health guarantee. Distribution is cheap —
Facebook/Instagram breeder groups, days-long sales cycle.

Counter-evidence that shaped scope: shelters barely pay (ShelterLuv charges $2
*per adoption*), and pet insurers require *clinic* records, so an owner-side
"claims evidence pack" has no B2B buyer. The Morocco/Algeria geography also
favors document-and-transfer value over subscription value, because card payment
penetration is low.

## 3. Build feasibility

The development machine is 2 cores / 4 GB RAM / HDD. **Gradle cannot build an APK
locally**, and any Flutter dependency needing the NDK or C++ toolchain is
CI-only. Consequences accepted in the architecture: no `build_runner` (D7), no
SQLCipher in Phase 0–2 (D4), no native AI runtime, and GitHub Actions as the only
compiler and only verifier of Android artifacts.

That is a real constraint, not an excuse: every "it compiles" claim must come
from a CI run id, and every "it works" claim must come from a screenshot on the
physical device.

## 4. What is genuinely buildable, and is also the product

The record core — animals, litters, vaccinations, health tests, weights, vet
visits, buyers, placements, reminders, and an exportable PDF/JSON pack — is
pure Dart + SQLite, needs no network, no licence, and no model. It is the part
the breeder pays for, and it is 100% within current build capacity. This is why
Stage 0–2 come before any AI work.

The AI slice that survives: **rule-based triage over the stored record** (age,
species, breed risk, last vaccination, test expiry) returning
act-now / watch / routine-vet, plus optionally a small on-device intent
classifier for free-text symptoms. Rules are auditable, shippable, testable, and
do not claim diagnosis. That is Stage 3, behind a measured benchmark.

## 5. Payments — the open blocker

D3 chose a one-time purchase through Google Play Billing. Checking it against
Google's own merchant-registration geography produced a problem the spec never
addressed:

- Google Play's supported-locations list for merchant registration does not
  include Morocco (the community is loud about this: a support thread asking how
  to monetize from Morocco, and a change.org petition to enable merchant
  registration there).
- A developer cannot receive Play payments directly from a Moroccan resident
  account; the usual answer is a company in a supported country.

Ranked responses, best-odds first for a solo beginner:

1. **B2B2C to breeding clubs, transfer agencies and clinics** (~€99/year per
   organisation, invoiced or via a global processor). 15 clients ≈ €1,485/year.
   Needs the fewest installs to matter, and no Play payment profile.
2. **Sell the transfer/travel document pack off-store** — a one-time ~$24 price
   paid outside Play (direct-download APK), or iOS IAP, which has no Morocco
   payout problem.
3. **Foreign LLC/Ltd + Play Billing.** Only route where D3 works literally, and
   the highest ceiling: at $39.99/year and Play's 15% small-business fee,
   roughly 8,000 installs would net ~$2,000–2,700/year — after formation,
   annual filings, and a registered agent abroad. Weeks of paperwork, and the
   payment profile plus the package name become permanent.
4. **Defer money entirely**: make the KPI 100 real installs plus 100
   expressed-interest emails, then let demand pick 1–3.

Nothing in the codebase depends on this choice yet (no network permission, no
billing package), so deciding late costs no rework. It must be decided before
Stage 4, and before the `applicationId` is burned into Play (D9).

## 6. Honest ceilings

| Target | Assessment |
|---|---|
| 100 installs in 12 months | Achievable with breeder-group distribution |
| 100 paying customers in 12 months | Hard. Requires the wedge, the pack, and a working payment route |
| ~$300–2,000/month | The realistic band if the paid wedge lands |
| 10,000 paying users / $500K/year | Not reachable by a solo beginner on this product in this timeframe. Treat as a multi-year, multi-person outcome, not a milestone |

## 7. Structural risks

| Risk | Why it bites | Mitigation in the design |
|---|---|---|
| Data loss = loss of the product | A breeder's ledger on one phone | JSON export/import (Stage 2) as the deliberate, user-initiated backup; backup/device-transfer explicitly disabled (D10) so there is no silent half-copy |
| Building features nobody pays for | Privacy alone does not sell | PDF transfer pack first (Stage 2), which is the artifact buyers and breeders both ask for |
| AI scope creep | The spec's core promise | Triage is rules with tests; a classifier ships only behind a measured benchmark (Stage 3 gate) |
| Content legal exposure | Bundled datasets are copyrighted | Only CC0/CC-BY/public-government sources may be bundled; anything Red is excluded, not paraphrased |
| One-way-door mistakes | Package id, payment profile, store listing | Both are owner decisions, recorded as open (D9, §5), and deliberately not touched by scaffolding |
| Unverifiable claims | 2-core machine cannot build | CI is the only compiler; every completion claim carries a command and its output, plus a device screenshot for UI |

## 8. Verdict

**Conditionally feasible — and feasible precisely because the spec was cut down.**
As written it is not buildable, not shippable, and not payable. As
scoped here — offline breeder ledger + transferable document pack + rule-based
triage — it is buildable by one person inside the available hardware, has a
demonstrated paying wedge, and has a real (if modest) revenue path whose choice
is a business decision, not an engineering one.

The blocking unknown is not technical: it is §5. The next technical risk is
Stage 1's reminder scheduling, which needs a plugin spike rather than an argument.

Sources for §1 and §5: [ML Kit text recognition language support](https://developers.google.com/ml-kit/vision/text-recognition/v2),
[HL7 FHIR `patient-animal` extension](https://build.fhir.org/extension-patient-animal.html),
[OVF / vetformat](https://github.com/vetformat/ovf),
[Play supported locations for developer and merchant registration](https://support.google.com/googleplay/android-developer/answer/9306917?hl=en),
[monetizing apps in Morocco — Play developer forum](https://support.google.com/googleplay/android-developer/thread/308550646/seeking-advice-monetizing-apps-in-morocco-with-in-app-products-and-subscriptions?hl=en),
[petition to enable Google Play merchant registration for Morocco](https://www.change.org/p/enable-google-play-merchant-registration-for-morocco).
