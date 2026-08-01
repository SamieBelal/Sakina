# One Ship W5 — the gate and the free tier

**Status: BUILT — Waves B (code half), C and D are shipped and green. Wave A is date-gated to 2026-08-04. §7's open decision is CLOSED.**

> **⚠️ Read this before using the document below as a checklist (2026-08-01).**
> The body is preserved as the plan *as written on 2026-07-31* — it is the
> record of what was decided and why, not a description of the tree. Three of
> its statements are now false, and a reader taking them at face value would
> re-do or mis-order shipped work:
>
> | The plan says | Actually |
> |---|---|
> | "PLAN — ready to build" | Built. 17 commits; full suite green. |
> | `consume_weekly_allowance` has **zero** client references | Called by `GatingService._consumeWeeklyPool`; the weekly pool is live. |
> | the `warmup_discover_name_size` dial "does not exist" / is inert (§6b, §7) | Shipped in `20260731090000`, seeded **3** in prod, and read through `warmupBudgetFor`. §7 is closed. |
>
> **Wave A update (2026-08-01):** the CLIENT half is built and committed — the
> three source files, `_defaultPaywallArm`/`_defaultTrialExpired`, the orphaned
> `tourBucket`/`assignTourVariant`, and `refreshTrialPremiumCache` are gone;
> `softPaywallPlacement` and `paywallArm` are frozen constants and
> `paywall_exp_arm` / `flag_reverse_trial_exp` are explicitly unregistered at
> bootstrap. `TourVariant` itself did NOT die with them, contrary to §4 A.4 —
> `OnboardingTourState.variant` still selects a step list. **The date gate is
> unchanged and still binds SHIPPING, not editing:** step A.2's
> `count(*) where trial_premium_until > now()` must return 0 before any build
> carrying this goes out. The `app_config` flip that stops the date from sliding
> is staged at `supabase/staged/reverse_trial_close.sql` and is safe to run now.
>
> **Still outstanding, and genuinely so:** Wave A's server half (the staged flip
> + the post-expiry key deletion), the ASC 3→7-day trial change (Wave B.1-B.2 —
> store config, not code), and the T0 flip
> (`supabase/staged/t0_flip_all_to_reel_v1.sql`).
**Date:** 2026-07-31
**Branch/worktree:** `feat/reel-first-w2-onboarding` at `/Users/appleuser/CS Work/Repos/sakina-reel-first`
**Parents:** `2026-07-23-conversion-refactor-changes-and-implementation.md` §W5 + **D10** · `2026-07-26-one-ship-01-data-layer.md` (built the server side this consumes)
**Approved content:** [`../content/2026-07-25-paywall-DRAFT.md`](../content/2026-07-25-paywall-DRAFT.md) — copy locked, freezes at T0
**Mock:** [`../mocks/2026-07-31-paywall-visual-mock.html`](../mocks/2026-07-31-paywall-visual-mock.html)

W5 replaces the single-page paywall with the approved 3-page gate, wires the client to the
tightened free tier W1 already built server-side, moves the real store trial from 3 days to 7,
and closes out the reverse-trial experiment.

**Non-goals:** any currency work — the tokens→Noor merge is **DEFERRED to the softener wave**
(`2026-07-31-one-currency-noor-merge.md`, tracked in `TODO.md`) · the **$59.99 price rise, CUT**
(D10①; annual stays $49.99) · instrumentation (W6) · the softener wave itself (post-keep) ·
deleting the legacy flow (post-keep).

---

## 1. The surprise: W1 already built most of the server side, and prod already has it

Read against production 2026-07-31. **This materially shrinks W5** — the plan's W5 bullet
reads as though `gating_service` + `daily_usage_service` + new RPCs are all ahead of us. They
are not.

**Already applied to prod (migration `20260727100200`):**

- Columns on `user_profiles`: `free_tier_cohort` (`'reel_v1'|'legacy'`, **server-assigned in
  `handle_new_user`**, never client-writable), `weekly_pool_used`, `weekly_pool_week_start`,
  `weekly_pool_reset_at`, `softener_notice_ends_at`.
- **`consume_weekly_allowance(p_feature text) → jsonb`**, SECURITY DEFINER. Exists and works.
- Freemium-guard triggers rejecting client writes to every one of those columns, on both
  UPDATE and INSERT.
- `app_config` dials, live: `warmup_reflect_size = 3`, `warmup_built_dua_size = 3`,
  `weekly_pool_size = 3`, `new_signup_cohort = 'legacy'` (flips at T0),
  `reel_first_onboarding_enabled = true`.

**The gap: the client uses none of it.** — ✅ **CLOSED 2026-08-01. Every bullet
below was true on 2026-07-31 and is false now:** `_consumeWeeklyPool` calls the
RPC, `warmupBudgetFor` reads all three dials, and the discover key exists and is
seeded 3. This is the *starting* survey, not the current state.

- **Zero** references to `consume_weekly_allowance` anywhere in `lib/` or `test/`.
- `gating_service.dart:133` still hardcodes `warmupBudget = {reflect: 10, builtDua: 10,
  discoverName: 5}` and **never reads `app_config`**. The 3/3 dials are live and ignored.
- There is **no `warmup_discover_name_size` key** — D10② needs one (see §7).

So W5's free-tier work is **almost entirely client**. The server contract is built, tested,
and idle.

> **⚠️ Two of the three gaps above CLOSED the same day (2026-07-31) — this section is a
> snapshot, not current state.** Commits `0823b5e` (warmup budgets become server dials),
> `88db130` (dials primed at boot in `main.dart`) and `41da747` landed after this was
> written:
>
> - **"`gating_service.dart:133` … never reads `app_config`" is now FALSE.** `gating_service`
>   carries `warmupSizeConfigKey` and an async `warmupBudgetFor()`; the hardcoded
>   `warmupBudget` map survives only as the documented offline fallback. **§4.D.1 is done.**
> - **`warmup_discover_name_size` now exists in code** (`gating_service.dart:166`,
>   `main.dart:257`) with a committed migration `20260731090000_warmup_discover_name_size.sql`
>   seeding it to `3` — which answers §7's open decision in the recommended direction.
> - **But that migration is NOT applied to production.** Re-checked 2026-07-31: `app_config`
>   holds `warmup_reflect_size=3`, `warmup_built_dua_size=3`, `weekly_pool_size=3` and **no
>   `warmup_discover_name_size` row.** Until it is applied, the client reads a missing key and
>   silently takes the offline fallback (`discoverName: 5`) — i.e. the D10② 3-re-roll warmup
>   is not actually in force. **Apply before T0.**
>
> Still true and unchanged: **zero** references to `consume_weekly_allowance` in `lib/` or
> `test/` (re-verified after these commits).
>
> Also closed: §5's "extend `scripts/check_no_fake_strings.sh` with the firewall patterns"
> shipped as `cb9251f`.

## 2. Verified baseline — everything else

**Paywall.** `lib/features/onboarding/screens/paywall_screen.dart`, **1,741 lines**, one page.
Reached from **13** `push('/paywall')` call sites plus 3 router builders and
`onboarding_screen.dart:1044`. `_closeButtonRevealDelay = Duration(seconds: 3)` is still live
(`:119`, `:312`). `_planHasTrial` (`:234`) checks whether the **product** has an intro offer,
never whether **this user** is eligible.

> **Corrected 2026-07-31 (second pass) — the `placement` claim above was wrong.** This
> plan's first draft said "**none of them pass a placement**, because the parameter does not
> exist." **The parameter exists and has shipped.** Verified against the committed tree:
>
> | Claim | Truth |
> |---|---|
> | "the parameter does not exist" | `PaywallScreen.placement` is declared at `paywall_screen.dart:34` (optional, `= AnalyticsEvents.placementSoftInApp`), documented at `:43-48`, and stamped onto **every** analytics event the screen emits (`propPlacement`, ~15 sites) |
> | "none of them pass a placement" | all **3 router builders** pass one explicitly — `/paywall` → `placementSoftInApp` (`router.dart:168`), `kOnboardingPaywallPath` → `placementHardWall`, `kOnboardingSoftPaywallPath` → arm-aware; and `onboarding_screen.dart:1045` passes `placementOnboarding` |
> | four constants, not two | `analytics_event_names.dart` carries `placementOnboarding`, `placementHardWall`, `placementSoftInApp`, `placementPostTrialSoft` |
> | "14 push call sites" | **13** real `push('/paywall')` call sites; the 14th grep hit is a comment in `iap_to_sub_upsell_banner.dart` |
>
> **What is actually true, and what W5 therefore has to do.** The 13 in-app pushes cannot
> carry a placement — a `context.push('/paywall')` by path constructs the widget through the
> router builder, which hardcodes `soft_inapp`. So every in-app upsell collapses into one
> undifferentiated placement, and the default makes a missed placement silent rather than a
> compile error. §4.C.1 below is therefore **not "introduce `placement`"** — it is: give the
> push sites a typed way to carry one, and make the parameter **required** so the default
> can no longer swallow a miss.
>
> Also drifted, not wrong: `:115`/`:308`/`:230` above were off by four lines against the same
> 1,741-line file; corrected inline. Grep the symbols, never the line numbers.

**Store.** ASC `sakina_sub_annual` (subscription `6762153970`): `FREE_TRIAL / THREE_DAYS`,
`numberOfPeriods 1`, `startDate 2026-04-29`, `endDate null`, **configured per territory**
(~175 rows). Annual price **$49.99** (AED 199.99 in the AE tier). RC mirrors `P3D` on both
`sakina_sub_annual` and `sakina_sub_weekly`. RC snapshot: 19 active subs, MRR $154, 1 active
store trial.

**"3 days" is hardcoded in Dart, not read from the store** — `paywallCtaTrial`,
`paywallTrialMicrocopyTemplate`, `paywallTrialMicrocopyWeeklyTemplate`,
`paywallExitOfferAccept`, `paywallExitOfferBody`, plus `lapsed_trial_sheet.dart:5` and `:107`.

**Reverse trial — the close-out is date-gated and the date is imminent.** 24 accounts hold an
**active** app-granted `trial_premium_until`; 457 ever did; **the last one expires
2026-08-03 20:45 UTC.**

> **Corrected 2026-07-31 — this plan's first draft got two facts wrong.** It claimed
> `reverse_trial_onboarding.dart` was "already deleted" and put `assignPaywallArm` in
> `app_session.dart`. Both came from grepping the wrong directory. The truth, verified:
>
> | Symbol / file | Actually at | Note |
> |---|---|---|
> | `reverse_trial_onboarding.dart` | **`lib/features/paywall/`** — **still present**, 6,071 bytes | also declares `paywallExperimentAssignedBaseKey` + `resolveAndApplyPaywallExperiment` |
> | `assignPaywallArm` | **`lib/features/paywall/paywall_experiment.dart:47`** | with the `PaywallArm` enum + `analyticsValue` |
> | `_defaultPaywallArm` (the *reader*) | `app_session.dart:699-708` | **also wired as a constructor default at `:79`** — removal touches both |
> | `trial_expiry_service.dart` | `lib/services/` | as stated |
>
> **And one consequence the plan missed:** `paywall_experiment.dart:1` imports `tourBucket`
> from `onboarding_tour_step.dart:438`, which is documented at `:449` as "kept because
> `tourBucket` backs `assignPaywallArm`". The tour A/B concluded in July, so **deleting
> `assignPaywallArm` orphans `tourBucket` + `assignTourVariant` + `TourVariant`** — both
> experiments' bucketing machinery dies together. Fold that sweep into Wave A rather than
> leaving it behind. Tests pin the hash, so they come out too.

**Cap sheets.** `DailyCapSheet` renders "Unlock unlimited" → `/paywall`, a 25-token bypass
middle slot, and "Maybe later"; **no route to buying tokens** — under 25 the button is dead.
Both sheets' body copy promises a **daily** reset (D10③) and goes false under a weekly pool.

**Missing entirely:** the one-time "always free" dismissal card (D6 says build it with W5).

---

## 3. Ordering constraints (read before scheduling)

1. **Wave A cannot start before 2026-08-04** — the last in-flight reverse trial must expire.
2. **Wave B's store change and its copy change must ship together.** The duration lives in
   Dart strings, so a build that says "7 days" against a `P3D` product, or the reverse, lies
   at the moment of payment. Create the 7-day ASC offers **first, dated**, then ship the build.
3. **Wave C before Wave D's routing.** The cap sheet's upgrade CTA must land on the condensed
   `soft_inapp` placement, which C creates.
4. **Nothing in W5 touches currency.** See non-goals.

---

## 4. The waves

### A — Reverse-trial close-out *(unblocks 2026-08-04)*

1. Write the readout addendum (`docs/analytics/reverse-trial-experiment-readout.md`) —
   what the arms showed, and that the app-granted `trial_activated` was **never** a
   RevenueCat trial and never counted as revenue.
2. Confirm zero rows with `trial_premium_until > now()` before deleting anything. In-flight
   trials are honored to expiry; there is no early revocation.
3. Delete, in this order (**grep for the symbol — do not trust these line numbers, three
   agents were editing concurrently when they were recorded**):
   - `lib/features/paywall/reverse_trial_onboarding.dart` — including
     `paywallExperimentAssignedBaseKey` and `resolveAndApplyPaywallExperiment`
   - `lib/features/paywall/paywall_experiment.dart` — `assignPaywallArm`, `PaywallArm`,
     `analyticsValue`
   - `lib/services/trial_expiry_service.dart`
   - `_defaultPaywallArm` in `app_session.dart` — **both** the function body and the
     constructor default that references it
   - the `reverse_trial_experiment_enabled` config key — **only after the build that stops
     reading it is live**, never before
4. **Sweep the orphaned bucketing.** `tourBucket` / `assignTourVariant` / `TourVariant` in
   `onboarding_tour_step.dart` survive solely because they backed `assignPaywallArm`; the
   tour A/B itself concluded 2026-07-25. With the paywall arm gone they are dead. Delete
   them and the tests that pin the hash, and drop the `:39` dependency note.
5. Freeze `paywall_exp_arm` as Mixpanel history — historical events only, never re-added,
   never recycled for a future paywall experiment. `onboarding_flow` is a *different*
   property and must never be unioned with it. Precedent: `flag_tour_ab`, retired the same
   way 2026-07-25.

**Done when:** `grep -rn "assignPaywallArm\|tourBucket\|PaywallArm" lib` is empty and the
suite is green.

### B — The trial: 3 days → 7 days

1. **ASC, first.** Create 7-day `FREE_TRIAL` introductory offers across all territories with
   an explicit start date; end the 3-day offers on the day before. **A gap means no trial at
   all** while the app promises one — verify continuity per territory, not just for USA.
2. Verify RC reflects `P7D` on both SKUs before shipping any build.
3. **Fix the eligibility bug — this is the real defect, and it predates W5.** Apple grants one
   introductory offer per Apple ID per subscription group, ever. Anyone who used the 3-day
   trial is **ineligible** for the 7-day one, and today's `_planHasTrial` cannot tell. Read
   RevenueCat's per-user intro eligibility and render non-trial copy + a "Subscribe" CTA when
   the user does not qualify. Shouting "Start my 7 days free" at someone who will be charged
   instantly is the version of this bug that costs refunds.
4. **Derive the duration from the store, not from a constant** —
   `intro.periodNumberOfUnits` / `periodUnit` — so copy can never again disagree with what
   StoreKit will grant. Then update the string sites in §2 to render from it.
5. `LapsedTrialSheet`: 3-day → 7-day (`:5`, `:107`), wired to RC trial-lapse.

> **Closed 2026-08-01 — B.5 was the one wave item that did not land, and it had grown a
> second defect.** Found by auditing the wave rather than by a test; nothing pinned it.
>
> - **It does not swap 3 → 7. It stops naming a duration at all.** "In your trial, you showed
>   up N times…" is true at 3 days, at 7, and at whatever ASC sets next. Swapping the numeral
>   would have re-created the exact coupling `TrialOffer` was built in B.4 to remove, on a
>   string that renders *after* the store has already decided. The new
>   `no cohort names a trial LENGTH` test greps the rendered copy for `3-day`/`7-day`/`3
>   day`/`7 day` across both cohorts and all three body shapes.
> - **D12 broke it a second way, in a place D12 never looked.** The sheet promised *"One
>   reflection a day is yours forever"* and headlined *"Welcome back to one a day"* — the
>   **legacy** tier. Both cap sheets were made cohort-aware in Wave D; this one was missed
>   because it is not a cap sheet and fires from `progress_screen`, not from a gate. Once
>   every account is `reel_v1` at T0, it promised a daily reflection to a population that
>   gets three a week. It now takes `isNewCohort` (resolved through the same
>   `resolveNewCohortForSheet` helper the cap sheets use) and names the Monday reset.
> - **It survives Wave A.** It fires off RevenueCat `hadTrial()`, not the app-granted
>   `trial_premium_until`, so deleting the reverse-trial machinery leaves it standing — and
>   the 7-day flip makes it *more* trafficked, not less.
> - **Known and NOT fixed here:** `_resolveActivity` counts **today only**, so
>   `daysActiveDuringTrial` is only ever 0 or 1 — someone who showed up every day of a 7-day
>   trial still reads "across 1 day". The service comment claimed a 3-day window it never
>   implemented; that comment is now corrected in place. Widening it to the real window is a
>   Supabase read of `user_daily_usage`, i.e. a data change, and it *understates* engagement
>   rather than overstating it, so it is safe to defer — but it is deferred, not solved.

**Done when:** a device StoreKit run grants 7 days, and a previously-trialed sandbox account
sees the non-trial variant.

### C — The 3-page paywall

1. **Make `placement` required, and let the push sites carry one** — *not* "introduce" it;
   see the correction in §2, the parameter already exists with a `soft_inapp` default.
   Drop the default so a miss is a compile error, give the **13** `push('/paywall')` sites a
   typed way to pass one (they currently route through the builder and all collapse to
   `soft_inapp`), and keep the 3 router builders + `onboarding_screen.dart:1044` passing
   theirs. This is mechanical but touches the most files; do it first and alone.
2. Build the three pages against the approved copy and the mock: `value_depth` (contract-keyed,
   renders **the actual Silver card widget** — not a re-draw; the reveal awards a deterministic
   Silver and the two surfaces must not disagree) → `trial_timeline` → `plan_select` (the five
   shipped `paywallPremiumBenefit1-5` strings verbatim, $49.99/yr, $0.96/wk, weekly as a
   de-emphasized text row).
3. **`soft_inapp` is a condensed single screen**, never the 3-page ceremony mid-task:
   trigger-specific value line + plan cards + plain terms.
4. **Delete `_closeButtonRevealDelay`.** ✕ visible from page one, ≥44pt hit area on every page.
5. Build the one-time **"always free" dismissal card** → home. Re-present ≤1/session start,
   ≤2 offer surfaces/week.
6. House rules, from the mock's audit: no drop shadows on chrome, card radius 14 / control
   radius 12, titles at `displayLarge` 34/700/−0.02em, gold as fill only (`goldInk` for any
   gold text), 450ms `easeOutCubic` staggered entry, every page scrollable on <812pt frames
   with the CTA pinned and **Restore / Terms / Privacy reachable** (a hidden Restore is an App
   Store review risk).
7. Firewall check on every string: no "sign"/"meant for you" near a price, no countdown UI, no
   arc-count, no guilt framing, no tier word beside a Name.

### D — The free tier, client side

1. **Read the dials.** `gating_service` stops hardcoding `warmupBudget` and reads
   `warmup_reflect_size` / `warmup_built_dua_size` (+ the new discover key, §7) from
   `app_config`, with the current constants as offline fallbacks.
2. **Call `consume_weekly_allowance`** for `reflect` and `builtDua` on the `reel_v1` cohort,
   replacing the local daily cap. Server is the authority; the local counter becomes a cache.
   `discoverName` is **exempt from the pool** and stays on its own path.
3. **`discoverName` → a genuine 1/day (D10②).** The day-open check-in stays **free and
   consults no gate** — the marker in `daily_loop_provider.dart:1425` is the mechanism and
   must not be touched. Re-rolls become premium after a **3-use lifetime warmup**. This is
   `reel_v1` only; legacy keeps today's effective 2/day.
4. **Remove the bypass for `reel_v1`** — `claimFirstBypass` included. The `DailyCapSheet`
   middle slot disappears; the sheet becomes headline + "Unlock unlimited" → **`soft_inapp`**
   + "Maybe later". Legacy keeps the bypass until the softener wave. Retire the IAP→sub banner
   trigger for the new cohort. **Keep the premium short-circuit at `gating_service.dart`
   intact** — premium must never reach `reserveBypass`.
5. **Fix the two false strings (D10③), blocking on the pool:**
   `DailyCapSheet._body` — *"Tomorrow's reflection is on us…"* — and
   `WarmupExhaustedSheet._body` — *"From tomorrow you'll get one a day…"*. Under a Monday-reset
   weekly pool, tomorrow is not on us and you do not get one a day. New copy must state the
   real reset, and the cohort branch means **both variants have to exist** while legacy users
   are still on daily.
6. **Settings → Danger Zone must still never clear `daily_free_reveal_*` / `daily_usage_*`.**
   It is not debug-gated; clearing them ships unlimited free reveals.

---

## 5. Tests

- **pgtap:** none new — the server is built and covered. Re-run the existing weekly-pool and
  guard suites after any client change that writes near those columns.
- **Unit:** cohort branching in `gating_service` both ways · warmup falls back to constants
  when `app_config` is unreachable · `discoverName` day-open consults no gate (mutation: make
  it consult one, the test must fail) · re-roll warmup decrements exactly once under
  double-tap · `consume_weekly_allowance` failure fails **open**, never charging twice.
- **Widget:** each paywall page renders at 390×844 and 440×956 · ✕ present on page one from
  frame zero · Restore/Terms/Privacy inside the viewport · the ineligible-user variant renders
  "Subscribe", never "7 days free".
- **Copy tripwire:** extend `scripts/check_no_fake_strings.sh` with the firewall patterns
  (price adjacency, countdown, guilt, arc-count, tier-word+Name) — W7 owns the full sweep, but
  the paywall patterns should land with the paywall.
- **Device (physical, StoreKit):** 7-day trial start · previously-trialed account · restore ·
  dismissal → always-free card → home.

---

## 6. Risks

| Risk | Mitigation |
|---|---|
| ASC territory gap → no trial while the app promises one | Create dated 7-day offers before ending the 3-day ones; verify per territory |
| Build and store disagree on duration | Ship together (§3.2); derive from `periodNumberOfUnits` so it cannot recur |
| Ineligible user charged instantly after "7 days free" | B.3 — per-user RC eligibility, non-trial variant |
| Weekly-pool RPC fails → user charged twice or locked out | Fail open; local cache reconciles on next sync |
| A placement is missed at one of the 17 entry points (13 pushes + 3 builders + onboarding) | Make `placement` **required** — today's `soft_inapp` default means a miss is silent, not a compile error |
| Cap-sheet copy ships false | D.5 is a blocker on the pool, not follow-up |

---

## 6b. ⚠️ The `warmup_discover_name_size` dial is INERT on its own (found 2026-07-31, review)

> **RESOLVED 2026-08-01.** The dial shipped WITH its consumer, exactly as this
> section demanded: `20260731090000` applied, `20260731100000` teaches
> `handle_new_user` to stamp it, prod seeds it at **3**, and `warmupBudgetFor`
> reads it. It is no longer inert. Kept because the *rule* it states — never
> apply a dial ahead of the code that reads it, because inert-but-applied
> invites the belief that the decision shipped — is the durable part.

**Applying the migration achieves nothing by itself.** Verified against production:

- `handle_new_user` reads `warmup_reflect_size` but **not** `warmup_discover_name_size`, and
  never stamps `warmup_discover_name_remaining`.
- That column's default is **5** — the legacy number, not D10②'s 3.
- `sync_all_user_data` returns the column on every launch and `hydrateFromProfile` writes it
  straight into prefs. Batch sync runs before any re-roll gate, so the local counter is **5**,
  and a stored counter short-circuits the dial read entirely.

So the client reads 3 from `app_config` only in the pre-sync window, and after the
`pushToServer` fix (`70d05cb`) it does not even persist that. **D10②'s 3-re-roll warmup is
not in force, with or without the migration.**

Completing it needs a **server** change: either stamp the column from the dial in
`handle_new_user`'s `reel_v1` branch, or lower the column default. Both touch the signup
trigger and both interact with the cohort branching this plan assigns to D.2/D.3 — so this
belongs **in D.2/D.3, not as a standalone migration**. Apply
`20260731090000_warmup_discover_name_size.sql` together with that work, not before it: alone
it is inert, and inert-but-applied invites the belief that the decision has shipped.

Two lesser findings from the same review, recorded so they are not rediscovered:

- **`_refresh` never stamps a timestamp for a key absent from `app_config`**, so `stale` stays
  true forever and every `getInt` on a missing key fires a detached network call. Bounded and
  pre-existing (shared with `getBool`/`getString`), but it is live *right now* for
  `warmup_discover_name_size` precisely because that key is deliberately unapplied.
- **Read-modify-write race on the warmup counter** — two concurrent `markUsed` calls decrement
  once, not twice. Pre-existing, fails open (one extra free use), and already tracked as D.3
  test work ("decrements exactly once under double-tap"). Fixing it needs a mutex on the hot
  path.

## 7. Open decision — ✅ CLOSED 2026-07-31

> **Founder chose the `app_config` dial.** Seeded **3** in production and read
> through `warmupBudgetFor`, like its two siblings. Nothing here is open; the
> text below is the question as it was asked.

**The `warmup_discover_name_size` dial does not exist.** D10② chose option (a) — 3 re-roll
warmups — but `app_config` carries only `warmup_reflect_size` and `warmup_built_dua_size`, and
the client's hardcoded `discoverName: 5` governs re-rolls today. Confirm the value is **3** and
it ships as an `app_config` key like its siblings (recommended — it is a permanent tuning knob,
not a flag, and it needs no deletion date). If it should instead be a constant, say so; the
difference is whether it is tunable after T0 without a release.
