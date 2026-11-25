# Salala — payment route study (the gate before revenue)

Research date: **2026-10-06**. Every fact below is labelled **CONFIRMED** (read this session
from the cited official page) or **UNVERIFIED** (memory, a blog, a community thread, or a
page that could not be reached). Nothing UNVERIFIED is presented as a solution. This is
market/payments research, not legal or tax advice.

## 1. The constraint in one paragraph

The owner is a resident of Morocco. Google Play's own "Supported locations for developer and
merchant registration" table (CONFIRMED, read 2026-10-06 from
<https://support.google.com/googleplay/android-developer/answer/9306917>) shows **Morocco:
developer registration ✔, merchant registration ✘, developer default currency ☆ ("Location
does not support merchants")**. So a Moroccan resident **can create a Play Console developer
account, but cannot create the payments profile (merchant account) that any paid app,
one-time in-app purchase or subscription requires**. This applies identically to paid apps and
to subscriptions — they all run on the same merchant rails (CONFIRMED from the same table:
monetization is tied to the merchant column, not the product type). Stripe is also not
available for merchants in Morocco: Morocco, Algeria, Tunisia and Egypt appear nowhere in the
supported-country content of <https://stripe.com/global>, while Nigeria and South Africa do
(CONFIRMED by inspecting the page source 2026-10-06; note neighbouring **Algeria and Tunisia
are ✔✔ merchant countries for Play**, which matters for entity choices). The blocker in
FEASIBILITY.md §5 is therefore real, current as of today, and unchanged by any community
rumour about a pending rollout.

## 2. Ranked options (best evidence + fastest first dollar at top)

### Rank 1 — Sell from a website with a Merchant-of-Record that pays out to Morocco (Polar or Lemon Squeezy; Paddle as the "anywhere" alternative)
The product sold is **web-side**: the PDF transfer/travel pack, a licence key for the app, or
the APK itself. The app on Play stays free (or the paid version is delivered off-Play).

- **How it works**: MoR creates a checkout link; buyer pays by card; the MoR is the merchant,
  handles VAT/sales tax; you receive a bank payout.
- **Polar** — CONFIRMED from <https://polar.sh/docs/merchant-of-record/supported-countries>:
  payouts go to "residents or businesses" in a Stripe-Connect-Express country list that
  **includes Morocco (🇲🇦)**; page explicitly answers "Stripe isn't available in my country —
  can I still use Polar? Yes, as MoR… all you need is a country supported by Stripe Connect
  Express for payouts." Fees CONFIRMED from
  <https://polar.sh/docs/merchant-of-record/fees>: Starter plan **free, 5% + 50¢ per
  transaction** (paid plans from $20/mo lower the rate). Time-to-first-sale: **days**.
- **Lemon Squeezy** — CONFIRMED from
  <https://docs.lemonsqueezy.com/help/getting-started/supported-countries>: "Bank payouts
  supported in the following countries" list **includes Morocco**; PayPal payouts in 200+
  countries. Fees CONFIRMED from <https://docs.lemonsqueezy.com/help/getting-started/fees>:
  example breakdown "$0.50 + 5% of total + 1.5% international payment". **Caveat**: after the
  Stripe acquisition (official blog <https://www.lemonsqueezy.com/blog/stripe-acquires-lemon-squeezy>),
  Stripe is pushing "Stripe Managed Payments" (35+ countries) as the successor and tells
  merchants outside supported countries to use Stripe Atlas —
  <https://www.lemonsqueezy.com/blog/2026-update>. Morocco being on LS's payout list does not
  guarantee new Moroccan sign-ups still get approved. UNVERIFIED.
- **Paddle** — CONFIRMED from
  <https://www.paddle.com/help/legal/sanctions/which-countries-are-supported-by-paddle>: "Paddle
  works with software businesses **anywhere in the world** with the exception of the
  unsupported countries listed below" — **Morocco is not on that list**. Pricing CONFIRMED
  from <https://www.paddle.com/pricing>: **5% + 50¢ per transaction** (Checkout). Payout
  currency CONFIRMED from
  <https://www.paddle.com/help/manage/get-paid/can-i-be-paid-in-my-local-currency>: payouts in
  13 currencies (USD, EUR, GBP…), **MAD not supported**; "If your local currency isn't
  supported we can send the payout in the most competitive Default Currency and your bank will
  convert" — i.e. USD/EUR wire to a Moroccan bank. Paddle onboarding is manual-reviewed and
  historically favours established SaaS; a brand-new solo seller may be slow-rolled or
  declined. UNVERIFIED.
- **Works for a one-time purchase inside an Android app?** **NO** — and this is the honest
  part. Google Play's Payments policy CONFIRMED from
  <https://support.google.com/googleplay/android-developer/answer/10281818>: "Google Play's
  billing system is **required** for developers offering in-app purchases of digital goods and
  services distributed on Google Play", including "App functionality or content… not
  available in the free version". A MoR checkout *inside* a Play app for the same unlock is a
  policy violation and a suspension risk. These options only work **outside** the Play
  purchase flow (web sales, licence keys, PDF packs, APK distribution — the same FAQ confirms
  "you can distribute your app however you like", other stores and your website included).
- **What could kill it**: chargebacks/fraud review; Gumroad-style payout surprises; Morocco's
  **exchange-office rules** on receiving/keeping foreign currency (see §4 UNVERIFIED list —
  this affects all of Rank 1 and must be checked with a comptable before volume grows).

### Rank 2 — Direct APK sale off-store (app never depends on Play payments), with the same MoR rails
Sell "Salala full version" as a downloadable APK + unlock key from the website via
Polar/LS/Paddle (same fees/countries as Rank 1). Target buyers who don't use Play (breeder
groups, WhatsApp/Telegram distribution — fits the Morocco/Algeria low-card-penetration market
in FEASIBILITY.md §2, though card-penetrating Western buyers are the paid target).
- **Constraint added in 2026**: Android **developer verification** now extends beyond Play.
  CONFIRMED from <https://support.google.com/android-developer-console/answer/16561738>:
  effective September 30, 2026 in Indonesia, Singapore and Thailand, expanded by Google to
  "all apps on certified Android devices" **in 2027**; unverified developers' apps become
  "unavailable for new installation on certified Android devices in applicable countries";
  sideloading survives ("Sideloading is fundamental to Android, and it's not going anywhere"),
  and there is a free limited-distribution account type (up to 20 devices, no government ID).
  So direct-APK sales to Western users still work **today**, but the paid APK route inherits
  Google's verification regime globally in 2027 — register early either way.
- **Time to first dollar**: days (checkout link) + one Play-free build variant.
- **What could kill it**: 2027 verification global rollout (CONFIRMED as a plan, mechanics for
  Morocco-based registration UNVERIFIED), user friction of installing APKs, piracy of keys.

### Rank 3 — Foreign entity + full Google Play monetization (the only route where "one-time IAP on Play" literally works)
- **US LLC**: Stripe Atlas forms a Delaware LLC for **$500 one-off** (CONFIRMED,
  <https://stripe.com/atlas>). A US merchant profile exists (US = ✔✔ USD, CONFIRMED from the
  supported-locations table). Play **organization** verification requires, per
  <https://support.google.com/googleplay/android-developer/answer/10841920> (CONFIRMED):
  D-U-N-S number (free via Dun & Bradstreet, "can take up to 28 days", CONFIRMED also from the
  Android verification FAQ <https://support.google.com/android-developer-console/answer/16561738>),
  official government ID of a representative, official organization document, website
  verification and phone verification. A US business bank for a Morocco-resident owner
  (Mercury/Relay/Brex etc.) is the known choke point: Mercury's eligibility article
  (<https://support.mercury.com/hc/en-us/articles/28770467511060>) could not be read in this
  session — **UNVERIFIED whether a Morocco-resident sole owner qualifies**. Annual US
  filings/registered agent ≈ $150–500/yr — UNVERIFIED, professional question.
- **UK LTD**: incorporation **£100 online** and confirmation statement **£50/yr** CONFIRMED
  from <https://www.gov.uk/government/publications/companies-house-fees/companies-house-fees>
  (updated 25 Sep 2026). UK merchant = ✔✔ GBP (supported-locations table). But a UK Ltd needs
  a business bank; Wise Business — the usual fintech answer — **will not let Moroccan residents
  hold money at all**: CONFIRMED from
  <https://wise.com/help/articles/2813542/where-do-i-need-to-live-to-hold-money-with-wise>,
  the supported-residency list does **not include Morocco**. UK bank accounts for
  Morocco-resident directors at traditional banks: UNVERIFIED and commonly refused.
- **Estonia e-Residency**: application fee **€150** shown on the official page
  (<https://www.e-resident.gov.ee/become-an-e-resident/>, CONFIRMED), then OÜ formation; EU
  merchant profile exists (Estonia ✔✔, supported-locations table). Banking for e-resident OÜs
  owned by Morocco residents is the weak link — UNVERIFIED.
- **Entity-in-Algeria/Tunisia**: both are Play merchant countries (✔✔ USD, CONFIRMED from the
  table) — but opening and *operating* a foreign entity next door while resident in Morocco
  adds its own exchange-control problems; not recommended, and out-of-country business
  ownership by Moroccan residents has reporting duties — professional question.
- **Taxes/identity, all entities**: non-US merchants file **W-8BEN** for Play; US merchants
  file US forms — CONFIRMED from the Play payments FAQ
  (<https://support.google.com/googleplay/android-developer/answer/7161649>).
- **Time-to-first-sale**: 4–10 weeks (formation → EIN/D-U-N-S 28 days → bank → Play org
  verification → payment profile). **What could kill it**: bank refusal to the Morocco-resident
  owner (the single real gate), Play rejecting profile/bank mismatch, ongoing filing costs
  dwarfing early revenue.

### Rank 4 — Play Billing-choice / external-web-link programs inside the Play app (interesting, but almost certainly not usable from Morocco today)
- The landscape changed in 2026 and FEASIBILITY.md should reflect it: Google's official blog
  <https://developer.android.com/blog/posts/expanded-billing-choice-and-lower-fees-on-google-play>
  and help <https://support.google.com/googleplay/android-developer/answer/17161464> (both
  CONFIRMED) describe a **billing choice program**: from **June 30, 2026** (US, UK, EEA) and
  **September 30, 2026** (AU, JP), developers may route users **to the developer's own website
  checkout** (i.e. past a MoR) with a service fee of **10% on the first $1M / 20%
  thereafter** and no 5% billing fee for external transactions (CONFIRMED from the help page;
  fee model CONFIRMED from <https://support.google.com/googleplay/android-developer/answer/16954621>).
  Published eligibility is market-based ("your app must be… in available markets"), with **no
  developer-country restriction stated** on the enrollment page.
- **Why it ranks 4 anyway**: the program **requires offering Google Play Billing side-by-side**
  (CONFIRMED: "You must offer users a choice of Google Play Billing alongside…"). With merchant
  registration ✘ in Morocco, a Moroccan-address account cannot enable the Play Billing half of
  the bargain, and Google nowhere documents enrollment for developers without a payments
  profile. The Japan predecessor explicitly required the developer to be "registered as a
  business" (CONFIRMED,
  <https://support.google.com/googleplay/android-developer/answer/16787536>) and stopped
  accepting new enrollments on 2026-09-30. Treat "can a Morocco-registered developer account
  join billing choice?" as an **open question to ask Google via Play Console support**, not a
  plan. If he later gets a US/UK/EU entity (Rank 3), this becomes the cheapest Play route.
- One-time licence inside a Play app via MoR without the program: **policy violation** —
  CONFIRMED (Payments policy, answer 10281818).

### Rank 5 — Payoneer as the receiving rail (adjunct to Ranks 1–3, not a payment solution by itself)
- Payoneer publishes Morocco-facing workforce/payroll guides
  (<https://www.payoneer.com/resources/workforce-management/hiring-guides/morocco/>), so
  Morocco is a serviced market for Payoneer, but the static country pages could not confirm
  resident sign-up in this session; the widely repeated freelancer claim comes from a
  third-party blog (<https://grey.co/blog/wise-vs-paypal-vs-payoneer-which-works-better-for-moroccans>,
  **UNVERIFIED**) and a Reddit thread titled "Impossible to open payoneer account with my
  morocco…" (<https://www.reddit.com/r/Morocco/comments/1hkoxe4/>, **UNVERIFIED**).
- Against Google's rules, Payoneer's **US receiving account details** look like a bank account
  in the US; Play's FAQ (CONFIRMED, answer 7161649) requires the bank to be *in the same
  country as the payments profile* and in that country's local currency, and test deposits
  fail otherwise. That means: a Payoneer USD detail could plausibly pair with a **US-entity**
  payments profile (Rank 3), and cannot rescue a Moroccan profile (which doesn't exist — ✘
  merchant). Google publishes **no** policy about third-party/virtual IBANs in this session's
  sources: **UNVERIFIED**; do not build the plan on it.
- **Wise is dead as a receiving account for a Morocco resident** — CONFIRMED (not on the
  hold-money residency list, wise.com article above).

### Rank 6 — iOS / App Store (do not trust the "iOS has no Morocco problem" line until verified)
- CONFIRMED only that Morocco is an App Store *sales region*: it appears in Apple's official
  financial-report regions/currencies list
  (<https://developer.apple.com/help/app-store-connect/reference/reporting/financial-report-regions-and-currencies/>).
- **UNVERIFIED and decision-critical**: whether App Store Connect accepts a **Moroccan bank
  account** under the Paid Applications agreement (Apple's per-country banking list could not be
  reached this session; the generic "banking information" help page does not enumerate
  countries). The FEASIBILITY.md claim "iOS IAP has no Morocco payout problem" is **not
  supported by anything read today** — check it inside App Store Connect (a $99/yr account)
  before believing it. Also: an iOS port doubles the build surface while the Android wedge is
  the stated market.
- Apple developer program requires its own $99/yr fee (price UNVERIFIED this session).

### Rank 7 — Gumroad (works on paper, weakest payout evidence)
- Fees CONFIRMED from <https://gumroad.com/pricing>: **10% + $0.50** per transaction (30% via
  Discover), Gumroad is MoR for tax since 2025. Supported-payout-country documentation was
  unreachable this session; a Morocco sale therefore depends on **PayPal receiving working in
  Morocco**, and third-party sources say PayPal Morocco accounts must withdraw to a Moroccan
  bank within 30 days (<https://grey.co/blog/wise-vs-paypal-vs-payoneer-which-works-better-for-moroccans>,
  **UNVERIFIED**). Lower-ranked than Polar/LS/Paddle because Rank 1 providers have *official*
  Morocco-on-the-payout-list pages.

### Dead ends, stated plainly
- **Play one-time IAP from a Moroccan personal account**: dead. Merchant registration ✘ is
  Google's own table, today (CONFIRMED). Nothing read this session hints at Morocco being added.
- **Paid app on Play from Morocco**: same rails, same ✘ — dead for the same reason.
- **Play subscriptions from Morocco**: same merchant requirement — dead.
- **Stripe (direct) as a Moroccan resident merchant**: not supported — CONFIRMED absence from
  stripe.com/global.
- **"FastSpend"**: no such merchant of record found; the intended provider was almost certainly
  **FastSpring** — its country-support help article 404'd this session, so FastSpring's Morocco
  status is **UNVERIFIED** (its pricing page is not public: "One flat rate", details only in
  sales contact).

## 3. If he wants the fastest revenue, do this next (order, not options)

1. **Today**: create a Polar account (free plan, 5%+50¢), list the **transfer/travel document
   pack (PDF)** and a **"full-version licence + APK" SKU**, publish checkout links to one
   breeder group. Payout to Morocco is on their official list. No Play dependency, no entity.
   Parallel-sign-up Lemon Squeezy only as fallback (onboarding status for new sellers
   UNVERIFIED).
2. **This week**: open Play Console anyway as an **individual** from Morocco (registration is
   supported ✔; identity verification is a government ID + device verification, CONFIRMED) and
   publish the **free** app for distribution and reviews. Money lives in Rank 1/2 for now.
   Note the $25 registration fee is UNVERIFIED this session (memory).
3. **This week, one question to Google** (Play Console > Help): "Can a developer account with
   a Moroccan address enroll in the billing choice program to point users in the US/UK/EEA to
   my own website checkout, given I cannot create a payments profile?" If Google says yes,
   Rank 4 quietly becomes Rank 1 for in-app sales. Do not build it before the answer.
4. **Only if Rank 1–2 revenue justifies it** (say, >$200/mo sustained), start Rank 3 (US LLC
   via Atlas $500 + EIN + D-U-N-S + a US bank the owner can actually open). Verify bank
   eligibility for Morocco-resident owners **before** paying formation fees.
5. Before the first payout lands, take the Office des Changes question to a local accountant:
   what a resident may keep in foreign-currency accounts and what must be repatriated when the
   income is services exports paid abroad (see §4). This can change the ranking of any option
   that pays into Morocco directly.

## 4. UNVERIFIED / needs-a-professional list

- **Moroccan exchange-office (Office des Changes) rules** — can a Moroccan tax resident receive
  MoR payouts (EUR/USD wires) to a local account, must proceeds be repatriated, may they be
  retained in a devise account: oc.gov.ma was unreachable this session
  (<http://www.oc.gov.ma/fr/comptes-en-devises> is the right page to read); a 2026 third-party
  summary of the IGOC reform exists (<https://www.upsilon-consulting.com/igoc-statuts-change/>,
  **UNVERIFIED**). **No legal advice here — this is the top item for a professional.**
- Local Moroccan banks' ability/fees to receive small USD/EUR SWIFT wires (claimed up to ~MAD 20
  receiving fee by a blog — UNVERIFIED).
- Payoneer resident sign-up from Morocco today (official pages inconclusive this session).
- PayPal receiving-account mechanics for Morocco, incl. the 30-day forced-withdrawal rule
  (third-party only).
- Whether Polar/LS/Paddle actually approve and pay a brand-new *Morocco-resident individual*
  seller (their lists say the country is supported; account review is discretionary).
- Whether a Morocco-address Play developer account can enroll in the 2026 billing choice
  program without a payments profile (Google answer needed).
- Apple Paid Applications bank-account support for Morocco (App Store Connect check required).
- Mercury/Relay acceptance of a US LLC solely owned by a Morocco resident (eligibility article
  unreadable this session).
- Play Console $25 individual registration fee and "account country cannot be changed later"
  (community-sourced, not re-read this session).
- FastSpring's seller-country support (page 404 this session). ("FastSpend" = no such provider.)
- Paddle's willingness to onboard a micro-solo seller and its AUP position on app-store licence
  sales (AUP page body not extractable this session).
- Whether Lemon Squeezy still opens new stores with bank payouts to Morocco now that Stripe is
  migrating merchants to Managed Payments (35+ countries, Morocco not checked in that list).

## 5. Dated source list (all read 2026-10-06)

**Google (official)**
1. Supported locations for developer and merchant registration —
   <https://support.google.com/googleplay/android-developer/answer/9306917> — Morocco ✔/✘/☆;
   Algeria, Tunisia, Mauritania-region peers ✔/✔ USD. CONFIRMED.
2. Payments profile FAQ (test-deposit rules, W-8BEN, EFT/Wire) —
   <https://support.google.com/googleplay/android-developer/answer/7161649>. CONFIRMED.
3. Understanding Google Play's Payments policy (Play Billing required for digital in-app
   goods; free distribution elsewhere; India/Korea/EEA/US exceptions) —
   <https://support.google.com/googleplay/android-developer/answer/10281818>. CONFIRMED.
4. Enrolling in the billing choice program (markets, dates, fees, side-by-side Play Billing
   requirement) — <https://support.google.com/googleplay/android-developer/answer/17161464>. CONFIRMED.
5. Enrolling in the external payments program, Japan (business-developer requirement; enrollment
   closed 2026-09-30) — <https://support.google.com/googleplay/android-developer/answer/16787536>. CONFIRMED.
6. Understanding Google Play's lower service fees (10% first $1M; +5% billing fee US/UK/EEA/JP/AU) —
   <https://support.google.com/googleplay/android-developer/answer/16954621>. CONFIRMED.
7. Expanded billing choice and lower fees (announcement, Paul Feng, June 2026) —
   <https://developer.android.com/blog/posts/expanded-billing-choice-and-lower-fees-on-google-play>. CONFIRMED.
8. Understanding Android developer verification (Sept 30 2026 launch countries, 2027 global,
   sideloading survives, D-U-N-S free/up-to-28 days, limited-distribution free account) —
   <https://support.google.com/android-developer-console/answer/16561738>. CONFIRMED.
9. Verify your developer identity information (individual: government ID + device verification;
   organization: D-U-N-S + org document + website/phone verification; payments profile linkage) —
   <https://support.google.com/googleplay/android-developer/answer/10841920>. CONFIRMED.
10. Required information to create a Play Console developer account —
    <https://support.google.com/googleplay/android-developer/answer/13628312>. CONFIRMED.
11. Play Billing external payment links (Japan program, side-by-side UX) —
    <https://developer.android.com/google/play/billing/externalpaymentlinks>. CONFIRMED.

**Providers (official)**
12. Polar — MoR supported countries (payouts incl. Morocco via Stripe Connect Express) —
    <https://polar.sh/docs/merchant-of-record/supported-countries>. CONFIRMED.
13. Polar — MoR fees (Starter free: 5% + 50¢) — <https://polar.sh/docs/merchant-of-record/fees>. CONFIRMED.
14. Lemon Squeezy — Supported countries (bank payouts incl. Morocco; PayPal 200+) —
    <https://docs.lemonsqueezy.com/help/getting-started/supported-countries>. CONFIRMED.
15. Lemon Squeezy — Fees ($0.50 + 5% + 1.5% international) —
    <https://docs.lemonsqueezy.com/help/getting-started/fees>. CONFIRMED.
16. Lemon Squeezy — 2026 Update: Lemon Squeezy + Stripe Managed Payments (35+ countries; Atlas
    pointer) — <https://www.lemonsqueezy.com/blog/2026-update>. CONFIRMED (as to what it says).
17. Paddle — Which countries are supported by Paddle? (exclusion list; Morocco absent) —
    <https://www.paddle.com/help/legal/sanctions/which-countries-are-supported-by-paddle>. CONFIRMED.
18. Paddle — Pricing (5% + 50¢) — <https://www.paddle.com/pricing>. CONFIRMED.
19. Paddle — Can I be paid in my local currency? (13 payout currencies, no MAD; bank/wire
    fallback with bank-side conversion) —
    <https://www.paddle.com/help/manage/get-paid/can-i-be-paid-in-my-local-currency>. CONFIRMED.
20. Paddle — developer docs: sell in 200+ countries (buyer side) —
    <https://developer.paddle.com/concepts/sell/supported-countries-locales/>. CONFIRMED.
21. Gumroad — Pricing (10% + $0.50; 30% Discover; MoR tax since 2025-01-01) —
    <https://gumroad.com/pricing>. CONFIRMED.
22. Stripe — global availability (no Morocco/Algeria/Tunisia/Egypt; Nigeria/SA present) —
    <https://stripe.com/global>. CONFIRMED (by content inspection).
23. Wise — Where do I need to live to hold money with Wise? (Morocco not on the list) —
    <https://wise.com/help/articles/2813542/where-do-i-need-to-live-to-hold-money-with-wise>. CONFIRMED.
24. Payoneer — Morocco hiring/payroll guides (serviced market, not payout proof) —
    <https://www.payoneer.com/resources/workforce-management/hiring-guides/morocco/>. CONFIRMED (as to what it says).
25. PayPal — country profiles (Morocco listed as a PayPal locale) —
    <https://www.paypal.com/webapps/mpp/country-profiles>. CONFIRMED (existence only).

**Entities / other official**
26. Companies House fees — incorporation £100 online; confirmation statement £50 (updated
    2026-09-25) — <https://www.gov.uk/government/publications/companies-house-fees/companies-house-fees>. CONFIRMED.
27. Estonia e-Residency — application €150 fee on official flow page —
    <https://www.e-resident.gov.ee/become-an-e-resident/>. CONFIRMED (as shown).
28. Stripe Atlas — $500 one-time formation price — <https://stripe.com/atlas>. CONFIRMED.
29. Apple — Financial Report regions and currencies (Morocco is an App Store sales region) —
    <https://developer.apple.com/help/app-store-connect/reference/reporting/financial-report-regions-and-currencies/>. CONFIRMED (banking support NOT verified).

**Third-party / community (low trust, flagged where used)**
30. Play developer forum: "Monetizing Apps in Morocco" —
    <https://support.google.com/googleplay/android-developer/thread/308550646> (body not
    renderable this session; kept from FEASIBILITY.md). UNVERIFIED.
31. grey.co — Wise vs PayPal vs Payoneer for Moroccans (2025-10-31) —
    <https://grey.co/blog/wise-vs-paypal-vs-payoneer-which-works-better-for-moroccans>. UNVERIFIED.
32. r/Morocco — "Impossible to open payoneer account with my morocco…" —
    <https://www.reddit.com/r/Morocco/comments/1hkoxe4/>. UNVERIFIED.
33. change.org petition to enable Play merchant registration for Morocco (cited in
    FEASIBILITY.md; not re-read). UNVERIFIED.
34. upsilon-consulting — IGOC 2026 summary of Moroccan exchange-control statutes (French) —
    <https://www.upsilon-consulting.com/igoc-statuts-change/>. UNVERIFIED, professional question.
