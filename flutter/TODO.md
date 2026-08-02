# TODO

Deferred work — needed before specific future milestones rather than today. Each item names its trigger so it's clear when it becomes urgent.

**Shipping 1.3.0? Start with the [ship checklist](#ship-checklist--130-w5--one-ship).** Several sections below have triggers that 1.3.0 fires; the checklist collects them in the order they have to happen and links to each recipe. Delete the checklist once 1.3.0 is out — the recipe sections stay.

## Ship checklist — 1.3.0 (W5 / One Ship)

**Trigger:** this release. Every item is a link to its own section below — the recipes
live there, not here. The five buckets are ordered and **not interchangeable**; buckets
4 and 5 are *wrong* if done early.

> **⚠️ Hard date — 1.3.0 cannot reach users before 2026-08-04, ~19:44 UTC.**
> The build deletes the reverse-trial client code, and **20 app-granted trials are still
> in flight**; the last expires **2026-08-04 19:43:30 UTC** (re-verified in prod
> 2026-08-02 01:52 UTC).
>
> **⚠️ CORRECTION — an earlier version of this line said the horizon was "frozen" at
> 17:18 UTC the moment `reverse_trial_experiment_enabled` flipped to `false`. That was
> wrong, and prod proved it.** The flag flipped at 2026-08-01 18:11 UTC and a trial was
> still minted at **19:43:30 UTC — 92 minutes later**, pushing the horizon out by 2h26m.
>
> The cause: `AppConfigService` caches config **for 6 hours**
> (`app_config_service.dart:60`). A client holding a stale `true` keeps minting until its
> own cache expires, so a flag flip propagates over a 6-hour tail, not instantly. All
> caches from that flip were stale by ~00:11 UTC on 2026-08-02, and the horizon has held
> since — but the general lesson stands:
>
> **Treat any recorded expiry as a FLOOR, never a fact. Re-query the gate immediately
> before you press Release.** That is what bucket 3 is for, and it is why it says "do not
> trust a previously recorded one" — advice this very line failed to follow.
>
> Submit whenever you like; **hold the release** (1.2.0 used `releaseType: MANUAL`, so you
> control the moment) until the gate in bucket 3 reads 0.

### 0 — Prep that does not wait for the build

- [x] **[W6 instrumentation](./docs/superpowers/plans/2026-08-01-one-ship-06-instrumentation.md) is IN 1.3.0** — decided 2026-08-01, in
  progress. It was unbuilt as of that morning (neither `reel_hook_source` nor
  `acquisition_problem_category` existed in `lib/`; `onboarding_flow`, `contract` and
  `free_tier_cohort` existed as values but were registered with Mixpanel nowhere). Wave A
  must land first and alone — every later event depends on the super properties it
  registers. Its post-release check is in bucket 5 and is now live, not conditional.
- [x] **`ONE_WEEK` confirmed available on the weekly SKU** — probed against ASC
  2026-08-01 and **accepted**, so 7 days ships on both plans as decided. The probe also
  established that offers hand over **by date with no gap**, which removes the riskiest step
  from launch day. See
  [the trial section](#app-store-lengthen-the-intro-free-trial-3-days--7-days).
- [ ] **Write the ~175-territory flip script** —
  [pre-release prep](#app-store-lengthen-the-intro-free-trial-3-days--7-days) even though
  the flip itself is bucket 4. This is now the only thing that consumes launch day.

### 1 — In the build (before you cut it)

- [ ] **Land the branch — nothing else in this checklist can happen until it does.**
  Verified 2026-08-01: `feat/reel-first-w2-onboarding` is **92 commits ahead of its
  own remote** and **no PR exists** (`gh pr list --head … --state all` → empty). W2 and W5
  are both sitting local. The remote branch ref exists but is 92 commits stale, so "it's
  pushed" is not the same as "it's shipped".

- [x] **[`reel_hook` measurement gap](#reel_hook-close-the-reel-source-measurement-gap)** —
  closed by One Ship W6. `reel_hook`/`reel_hook_source` are registered as super properties
  (with provenance: `unknown` at entry → `deep_link` on a drained reel link → `self_report`
  on the source screen); the event name was reconciled to the shipped `reel_source_selected`
  rather than renamed. Only step 3 (ASC Campaign Links, an ops task) remains open — see the
  section below.
- [ ] **[OpenAI Edge Function proxy](#openai-edge-function-proxy)** — trigger reads "before
  any external TestFlight build or **App Store release**". The risk was consciously accepted
  to ship 1.2.0; 1.3.0 is a second App Store release, so this is a **decision to re-take on
  the record, not an item to skip silently**. `OPENAI_API_KEY` is still baked into the IPA.
- [ ] `flutter test` and `flutter analyze` green. Note the two known-flaky tests
  (`purchase_service_premium_started`, `find_duas` eval) fail on a clean baseline — the
  suite exits non-zero even untouched, so read failures individually rather than trusting
  the exit code.
- [ ] Confirm the build number. `pubspec.yaml` is at **`1.3.0+8`**; builds 2, 5 and 9 are
  already uploaded historically, so verify `+8` is not rejected as a duplicate before you
  spend an archive on it.
- [ ] **Four things only a device or a human can settle** (surfaced by the
  comprehensive PR review, 2026-08-02 — all traced in logic, none exercised):
  - **The Sunday 23:59 → Monday 00:01 week rollover**, in a user's own
    timezone. The weekly pool resets on the local ISO Monday; the reviewer read
    the logic and did NOT hand-test the boundary.
  - **A live timezone change mid-week** — fly, or move the device zone. Reveal
    and gating resolve "today" through a memoised/cached zone while
    `streak_service`'s `_todayLocalString()` uses the live device clock, so the
    two can disagree for a window after travel. Verify a streak day is neither
    gained nor lost.
  - **The value-depth and trial-timeline paywall pages against the copy
    firewall.** `check_no_fake_strings.sh` scans purchase surfaces only, by
    design (W7 owns the full sweep), and nobody has read those two pages
    against the rules.
  - **A second account on the same device.** Four cross-user leaks of one shape
    were fixed on this branch; sign out, sign in as someone else, and confirm no
    Name, streak, cohort, onboarding state, or widget content carries over.

- [ ] **Physical-device StoreKit pass** (W5 plan §5 — the simulator cannot complete a
  purchase, so this is the only place these are provable): trial start · a
  previously-trialed account gets the **"Subscribe"** variant and never "7 days free" ·
  restore · dismissal → always-free card → home. Note the trial still reads **3 days** until
  bucket 4 runs, so verify the *mechanism*, not the number.

### 2 — At submission (App Store Connect metadata)

- [ ] **Create the 1.3.0 version record in App Store Connect — it does not exist yet.**
  Verified 2026-08-01: the newest version in ASC is **1.2.0 (`READY_FOR_SALE`)**. App id
  `6762153820`. Several items below need the version to exist in
  `PREPARE_FOR_SUBMISSION` first.
- [ ] **[Duʿā Times location permission](#app-store-duʿā-times-location-permission-privacy-label--review-notes)**
  — privacy nutrition label + review notes. 1.3.0 is the first build carrying
  `NSLocationWhenInUseUsageDescription`, which is exactly its trigger.
- [ ] **Screenshots + "What's New".** *Not verified against the live assets — check before
  assuming either way.* The onboarding and paywall were both rebuilt in W2/W5, so any
  screenshot depicting them is stale. This is not a compliance item; it is the store page
  for a release whose whole thesis is the new onboarding.
- [ ] Run `./scripts/check_no_fake_strings.sh` (pre-release tripwire).
- [ ] ~~Export-compliance declaration~~ — **already handled, recorded so nobody re-checks.**
  `ITSAppUsesNonExemptEncryption` is `false` in `ios/Runner/Info.plist`, and every uploaded
  build reports `usesNonExemptEncryption: false`. ASC will not prompt.

### 3 — After approval, **before** you press Release

- [ ] **⚠️ SNAPSHOT THE PRE-T0 BASELINE. This one cannot be recovered later.**
  Master plan Phase 2 step 1. Pull the trailing-90-day new-signup cohort numbers —
  signup→paid, D1/D7, paywall-encounter rate, review velocity, refund rate — and write
  them into
  [the readout doc](./docs/analytics/funnel-flags-and-querying.md), then declare T0.
  **Every read in bucket 5 compares against this, and after T0 there is no pre-T0
  population left to measure.** Miss it and the keep decision has nothing to be a
  decision against: the methodology is explicitly pre/post with no control arm, so the
  "pre" has to be captured while it still exists. Apply the test-ID exclusion list at
  `docs/qa/mixpanel-orphaned-distinct-ids.json` (read the file — its own count key has
  drifted before).

- [ ] **[Reverse-trial gate: the query must return `0`](#server-sql--the-130--t0-runbook)**
  (step 2a of `supabase/staged/reverse_trial_close.sql`). Re-query it — do not trust the
  timestamp above, and do not trust a previously recorded one: the horizon already moved
  once. This is the gate on the hard date at the top of this checklist.

### 4 — After READY_FOR_SALE (**not** at submission)

The two items here are independent of each other — order between them doesn't matter. Both
are wrong before the build is live.

- [ ] **[Run `t0_flip_all_to_reel_v1.sql`](#server-sql--the-130--t0-runbook)** — this is
  what actually turns the new free tier on. Until it runs, `new_signup_cohort` is `'legacy'`
  and the tightened tier reaches **nobody**. Running it *before* the build is live tightens
  limits on people still using the old app, and the warmup clamp is one-way.
- [ ] **[Lengthen the intro free trial 3 → 7 days](#app-store-lengthen-the-intro-free-trial-3-days--7-days)**
  — must wait until 1.3.0 is actually live. Doing it at submission means the store still
  serves 1.2.0, whose paywall hardcodes "3 days", for the whole review window: every new
  subscriber would get four extra free days that nothing advertises.

### 5 — After release

- [ ] **T0+24h: super-property coverage check.** Required by the W6 plan §6, which says
  explicitly to put it on the T0 checklist rather than leave it in the plan. Check the share
  of `onboarding_started` events carrying `onboarding_flow`, `contract` and
  `reel_hook_source`; **anything below ~95% is an ordering bug, not a sampling artifact.**
  Separately confirm `free_tier_cohort` is present on `paywall_viewed` and `daily_cap_hit`.
  **W6 is shipping in 1.3.0, so this check is live, not conditional** — and it is the
  mitigation for the wave's characteristic risk: an event whose absence stays invisible
  until the keep read.
- [ ] **[Decide on crash reporting](#crash-reporting-decide-dont-default)** — adopt it or
  record that the blind spot was accepted. Not a blocker; a decision that otherwise never
  gets taken. Until it exists, a crash and a quit are indistinguishable in every drop-off
  number this release is judged on.
- [ ] **Delete the retired `reverse_trial_experiment_enabled` key** — step 2b of
  `reverse_trial_close.sql`, currently commented out. Pure hygiene, no urgency; a retired
  key costs nothing.
- [ ] **Sanity-check the satisfaction thresholds against the real baseline —
  before the T0+6wk read, not during it.** W6 Wave E shipped four "what bad looks like"
  numbers (rating-gate accept rate, churn reasons, D1, and D7 as *the guardrail that
  vetoes a conversion win*), and they are labelled **proposed, not verified**: T0 had not
  shipped, so no baseline was queryable when they were written. They were picked to exceed
  plausible week-to-week noise at ~21 signups/day, not derived from data. Adjust them once
  the bucket-3 snapshot exists. See the satisfaction section of
  [the readout doc](./docs/analytics/funnel-flags-and-querying.md).

- [ ] T0+6wk: the **keep decision**, which in turn triggers the
  [softener wave](#one-currency-merge-tokens--tier-up-scrolls-into-noor).

---

## Three intake answers that go nowhere — a product call

**Trigger:** none. It is a decision, and it has been open since 2026-07-31.

`toldAnyone` (H3), `dailyTime` (H6) and the free-text `intakeNote` (H7) are
collected, stored in the local onboarding blob, and deleted when onboarding
completes. The functions written to surface them —
`toldAnyonePlanLine`, `toldAnyoneFirstNotificationBody` (`intake_questions.dart`)
— exist and are called from nowhere. Already documented in place at
`queue_plan_screen.dart:44-59`.

**What changed 2026-08-02:** W6 Wave F now emits all three to analytics, so the
answers are no longer *lost* — you can read the distribution. They still produce
no visible consequence for the user, which is what Wave H's own binding rule
("every intake question must produce a visible consequence, asserted by test")
forbids. Asking someone to write a personal note that visibly does nothing has
its own cost.

Two honest options: **surface them** (wire the two consequence functions), or
**stop asking** (drop the screens and shorten the flow). Either is defensible;
leaving it as-is is the one that isn't.

---

## Known limitation: the warmup race is only half-closed

**Not a bug to fix — a property to remember when reading the numbers.**

`consume_warmup_allowance` (applied to prod 2026-08-02) makes the warmup
decrement atomic, replacing a client-computed absolute that two devices could
each push identically, leaking one real AI use per race.

**But every already-shipped binary keeps the old absolute-push path forever.**
So the race is closed new-client-to-new-client only: an old device racing a new
one still loses a decrement until that user updates. Strictly better, never
worse — and not a retirement of the bug on the day 1.3.0 ships.

Practical consequence: warmup consumption counts will read slightly LOW during
the 1.2.0→1.3.0 adoption tail, and the effect disappears on its own as users
update. Do not chase it as a data bug.

---

## Crash reporting: decide, don't default

**Trigger:** not a ship blocker for 1.3.0 — a decision to take on the record, because
defaulting to "no" silently is how it stays "no" forever.

**Status:** there is **none**. Verified 2026-08-01:
`grep -rniE "sentry|crashlytics|runZonedGuarded|FlutterError.onError" lib/ pubspec.yaml`
returns zero matches. No crash reporter, no zone guard, no `FlutterError.onError` handler.

**Why it matters for THIS release specifically.** 1.3.0's whole thesis is a rebuilt
onboarding, and the keep decision is read off drop-off numbers. With no crash reporting,
**a crash and a deliberate quit are indistinguishable by construction** — every drop-off
figure in the W6 readout carries an unmeasured crash component, and `app_opened` /
`session_started` counts silently include crash-truncated sessions with no denominator
correction. A genuinely bad build would read as a genuinely bad flow, and the response to
those two is not the same.

W6 documented the caveat wherever a drop-off number is quoted. A caveat is not a fix.

**The decision, either way, deserves a dated line here:**
- **Adopt** — a new third-party dependency (SDK, dSYM/symbol upload, a privacy-manifest
  entry, and a review of what gets sent). Real work, and it should not ride into a release
  under the heading "instrumentation", which is why W6 split it out rather than absorbing
  it.
- **Accept the blind spot** — legitimate at this stage and this volume. Write down that it
  was chosen, so the next person reading a drop-off chart knows the gap is known rather
  than overlooked.

**Related, already resolved — recorded so it is not re-investigated:** the "two RevenueCat
apps" concern from the W5 audit is a non-issue. The second app is RevenueCat's built-in
**Test Store** sandbox (`app75ffdc6cad`), not a second storefront; its SKUs legitimately
carry no trial. The real app is `Sakina (App Store)` (`app776fe1ae80`, bundle
`com.sakina.app.sakina`), with the ASC API key and subscription key both configured.

---

## Server SQL — the 1.3.0 / T0 runbook

**Trigger:** this release. Scripts live in
[`supabase/staged/`](./supabase/staged/) — deliberately **outside** `supabase/migrations/`
so neither `supabase db push` nor CI can ever run them by accident. `README.md` in that
directory is the authority; this section is the release-day ordering.

**Verified against production 2026-08-01:** both W5 migrations applied, all dials seeded
(`warmup_reflect/built_dua/discover_name_size` = 3/3/3, `weekly_pool_size` = 3,
`post_tour_paywall_mode` = `soft`), all 10 W1/W5 columns and the freemium guard present.
Nothing is missing from the schema. What follows is data/config operations only.

| # | When | Script | Applied? |
|---|---|---|---|
| 1 | ~~Now~~ | `reverse_trial_close.sql` **step 1** — stop minting trials | ✅ **DONE** 2026-08-01 18:11 UTC |
| 2 | Before you press Release | `reverse_trial_close.sql` **step 2a** — the gate, read-only | ☐ |
| 3 | Launch day, after the build is live | `t0_flip_all_to_reel_v1.sql` | ☐ |
| 4 | Any time after rollout | `reverse_trial_close.sql` **step 2b** — delete the key | ☐ |
| — | **Never** (for the free tier) | `softener_1_notice.sql`, `softener_2_flip.sql` | superseded by D12 |

**Why the softener scripts are dead here:** D12 replaced the 30-day-notice migration with
"everyone tightens at T0". `softener_2_flip.sql` is gated on `softener_notice_ends_at <=
now()`, nothing stamps that column any more, so it matches **zero rows** — and it clamps
only two of the three warmup counters. They are kept, not deleted, because the softener
wave still exists for the [tokens→Noor currency merge](#one-currency-merge-tokens--tier-up-scrolls-into-noor).

**What #3 actually does, and why it can't be undone.** It is one statement: backfill
`free_tier_cohort = 'reel_v1'` on every account, clamp the three warmup counters with
`least(…, 3)`, zero the weekly pool, then flip `new_signup_cohort`. Two things to know
before you run it:

- **The backfill is unqualified on the cohort value, on purpose.** In prod
  `free_tier_cohort` is **NULL on 1,262 of 1,374** accounts — the column was added after
  most users signed up. A `where free_tier_cohort = 'legacy'` filter would touch 112 rows
  and silently leave 92% of the base on the old tier.
- **The clamp is lossy, and that is the decision, not a defect.** `least()` only moves
  numbers down, so nobody who already spent their warmup is handed uses back — but the
  surplus is gone. **~1,366 accounts drop from 10 remaining reflect uses to 3 between one
  launch and the next, with no notice.** Rolling back `free_tier_cohort` to `'legacy'`
  restores the legacy economy but **not** the counters. The script snapshots them into
  `warmup_pre_t0_snapshot` first; that table is the only way back. Drop it after the keep
  decision.

**How to execute:** move the script content into a normal timestamped migration file and
apply through the standard flow — not MCP-only SQL without a repo file, so the operation
leaves a record. Stamp it with a fresh timestamp. All scripts assert they run as
`postgres` / `service_role` / `supabase_admin`; the freemium guard blocks these columns for
everyone else, and a half-applied flip under a restricted role is worse than a loud failure.

**Note on migration version drift:** applied migrations carry different version stamps than
the local filenames (e.g. local `20260731090000_warmup_discover_name_size` ↔ remote
`20260801015832`), because they were applied via `apply_migration` rather than `db push`.
Consequence: `supabase db push` would treat several local files as unapplied and re-run
them. They are idempotent (`create or replace`, `on conflict`), so it would be harmless —
but do not read a `db push` diff as evidence that something is missing.

**Surfaced by:** D12 free-tier timing decision + production verification, 2026-08-01.

## Android release signing

**Trigger:** before any Play Store submission (internal track, beta, or production). Not needed for iOS-only releases.

**Status:** `android/app/build.gradle.kts` currently signs `release` builds with the **debug keystore**. Play Store will reject any AAB signed with debug keys. We can run Android in debug locally and produce unsigned/debug builds today, but `flutter build appbundle --release` produces an artifact that's not Play-acceptable.

**Steps when ready (~20 min total):**

1. **Generate upload keystore (human, ~5 min).** This step is interactive and security-critical — passwords and the keystore file must not pass through Claude.
   ```bash
   keytool -genkey -v -keystore ~/sakina-upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias sakina-upload
   ```
   Pick strong distinct passwords for the store and the key. Write them somewhere durable (1Password / secure vault). **Losing this keystore permanently blocks app updates on Play Store** — there is no recovery path short of Google Play App Signing's reset flow (which requires you to have enrolled in App Signing in the first place).

2. **Back up the keystore file twice** (1Password attachment + encrypted drive, or whichever two-place strategy you trust). Same logic: gone = bricked.

3. **Wire up build (Claude can do, ~10 min):**
   - Create `android/key.properties` (gitignored) with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`.
   - Edit `android/app/build.gradle.kts` to read `key.properties` and add `signingConfigs.create("release")` pointed at it.
   - Switch `buildTypes.release.signingConfig` from `signingConfigs.getByName("debug")` to `signingConfigs.getByName("release")`.
   - Add `android/key.properties` and `*.jks` to `.gitignore`.

4. **Verify (Claude can do):** `flutter build appbundle --release --dart-define-from-file=env.json` produces a signed AAB. Inspect with `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`.

5. **(Optional but recommended) Enroll in Google Play App Signing** in Play Console → Setup → App integrity. Upload your upload-key certificate (`.pem` extracted from the keystore). Play then re-signs the AAB with its own managed signing key for distribution, and you can reset the upload key if it's ever compromised. This is the canonical Android signing setup as of 2026.

**Until then:** Android dev/debug builds work as-is. Don't run `flutter build appbundle --release` and expect it to be Play-ready.

---

## OpenAI Edge Function proxy

**Trigger:** before any external TestFlight build (i.e. handing the build to anyone outside your Apple ID's individual testers) or App Store release.

**Status:** `OPENAI_API_KEY` is currently a `String.fromEnvironment` compile-time constant injected via `env.json`. It's baked into the Dart snapshot in the signed IPA — harder to extract than a plain text asset, but `strings` / Hopper / Ghidra on an extracted IPA still recovers it. **A bad actor with one IPA can drain OpenAI credit.**

**Plan exists at:** `docs/superpowers/plans/2026-04-27-openai-edge-function-proxy.md`

**Summary of work (Claude can do most, you need to do the key rotation + secret config):**

1. **Assume the key is compromised. Rotate it in OpenAI dashboard before doing anything else.** Old key stays valid until you rotate — if the new IPA ever ships before rotation, the old key is in the wild forever.
2. Create Supabase Edge Function `openai-proxy` (auth-gated, validates user JWT, proxies to OpenAI Chat Completions).
3. Store the new key as a Supabase Edge Function secret (never in `env.json`).
4. Update all 5 `ai_service.dart` call sites (lines 451, 607, 896, 1016, 1335) to call the proxy instead of OpenAI directly.
5. Drop `OPENAI_API_KEY` from `env.json`, `env.example.json`, and `lib/core/env.dart`.
6. Verify in TestFlight build that AI features still work; verify with `strings` that the key is no longer in the IPA.

**Why this is the right design:** mirrors the proven `revenuecat-webhook` pattern. The function runs server-side, holds the key in its server-side env, and the client just sends authenticated requests. RLS / auth gating prevents abuse by unauthenticated callers. Standard OWASP API security pattern.

---

## Localize win-back push

Push template `win_back_tour_replay` (see `docs/runbooks/onesignal-segments.md`) is EN only — localize when project i18n infrastructure exists.

## Win-back offer on subscription cancellation

**What:** When a cancellation is detected, present a retention / win-back offer
(discount, free period, or pause) to recover the churned subscriber.

**Why:** The cancellation-feedback feature (spec:
`docs/superpowers/specs/2026-05-31-cancellation-feedback-design.md`) captures *why*
users leave. A win-back offer acts on it. Deliberately deferred out of the
feedback-only v1 so the offer can be designed against real cancellation-reason
data rather than guessed.

**Constraints / decisions to make first (needs its own brainstorm + spec):**
- Offer mechanism: Apple **Win-back offers** vs RevenueCat **promotional offers**
  vs a discounted product. All require App Store Connect + RevenueCat dashboard
  config and offer signing; a **physical device** is required to test (simulator
  can't complete StoreKit).
- Same interception limit as the survey: we can't catch the cancel tap inside
  Customer Center on Flutter, so this is a post-cancellation "come back with a
  discount" offer (which is exactly what Apple Win-back offers target), not a
  pre-cancel deflection.
- Eligibility / abuse: once per user per cancellation episode; must respect the
  `referral_premium_until` / `gift_premium_until` premium sources and the
  freemium-guard triggers — never grant overlapping/duplicate premium.
- Placement: inside the cancellation-feedback sheet (after submit) vs a separate
  screen; distinct copy for trial vs paid.
- Analytics: offer shown / accepted / declined funnel (Mixpanel).

**Surfaced by:** `/plan-eng-review` of the cancellation-feedback spec, 2026-05-31.

## App Store: Duʿā Times location permission (privacy label + review notes)

**Trigger:** before the App Store submission of the first version (≈1.3.0) that
ships the Duʿā Times feature — i.e. the first build containing
`NSLocationWhenInUseUsageDescription`.

The feature adds a coarse, lazy, on-device-only location permission for
prayer-time math. Apple scrutinizes location, so before submitting:

1. **Privacy Nutrition Label** (App Store Connect → App Privacy): declare
   location = **Data Not Collected**. Rationale: lat/lon is computed on-device
   and only cached locally / written to the App Group — it is NEVER transmitted
   to Supabase, analytics, or any third party. (Verify this stays true if the
   schedule payload ever changes.)
2. **App Review Notes** (Version → App Review Information): paste —
   "This version adds an optional coarse-location permission used only to
   compute Islamic prayer times on-device for the 'best times for duʿā' feature.
   Location is never transmitted off-device; it's cached locally and used only
   for prayer-time math. If denied, the feature degrades to calendar-only."
   (Can be set via asc-mcp `app_versions_set_review_details` once the version
   exists in `PREPARE_FOR_SUBMISSION`.)
3. Confirm the 5.1.1-satisfying posture: coarse accuracy, lazy prompt (only on
   the "Turn on precise times" tap), graceful degrade. Re-read the `Info.plist`
   purpose string.

**Surfaced by:** Duʿā Times feature (PR #51), 2026-07-16.

## App Store: lengthen the intro free trial (3 days → 7 days)

**Trigger:** **after** 1.3.0 reaches `READY_FOR_SALE` — not at submission, not before.
1.3.0 is the first build whose paywall copy derives the duration from the store; until
it is actually live, the store serves 1.2.0.

**Why the ordering is the whole item.** On master (= shipped 1.2.0) the trial length is
written into Dart — `paywallCtaTrial` ("Try Sakina Free for 3 days"),
`paywallTrialMicrocopyTemplate`, `paywallHonestBillingAnnual` ("Day 3: {price}/year
unless cancelled"). Flip the store early and every new subscriber gets four extra free
days while the app advertises three, for the entire review window: you pay the full cost
of the longer trial and capture none of the marketing upside. It is not a user-harm or
3.1.2 problem — under-promising is safe — it is simply money spent for nothing. From
1.3.0 forward every duration comes from `TrialOffer` (`lib/features/paywall/
trial_offer.dart`) through a `{trial}` placeholder, so **the flip needs no app release**;
the copy follows the store on its own.

**Current state (verified 2026-08-01).** ASC subscription `6762153970`
(`sakina_sub_annual`): `offerMode: FREE_TRIAL`, `duration: THREE_DAYS`,
`numberOfPeriods: 1`, `startDate: 2026-04-29`, `endDate: null`, in every territory.
`sakina_sub_weekly` matches. RevenueCat mirrors both as `trial_duration: P3D`.

**Both subscription ids, so nobody has to look them up again** (group `22030855`,
"Sakina Premium", app `6762153820`):

| Name | Product id | ASC id | Period | State |
|---|---|---|---|---|
| Sakina Annual | `sakina_sub_annual` | `6762153970` | `ONE_YEAR` | `APPROVED` |
| Sakina Weekly | `sakina_sub_weekly` | **`6762154204`** | `ONE_WEEK` | `APPROVED` |

**Decided (founder, 2026-08-01): 7 days on BOTH SKUs**, matching the approved deck. The
cost is understood and accepted — 7 days on a $4.99/week plan gives away that plan's
entire first billing period; a split (7-day annual / 3-day weekly) was raised and not
taken. Separately, the deck's **$59.99/yr anchor was deliberately declined** — annual
stays **$49.99**, so change the trial and nothing else.

**✅ The open technical unknown is CLOSED — ASC accepts `ONE_WEEK` on the P1W weekly
subscription.** Probed empirically 2026-08-01 against `sakina_sub_weekly` (`6762154204`) in
Nauru: `intro_offers_create` with `duration: ONE_WEEK`, `offer_mode: FREE_TRIAL`,
`number_of_periods: 1` returned **success**. Apple does not constrain a weekly subscription
to 3 days. **7 days is available on both SKUs**, so the founder decision ships as approved
and no per-plan duration split is needed.

**Two hard-won facts about the API, worth more than the answer itself:**

1. **Offers cannot overlap in a territory, and today's offers are open-ended.** Every
   territory carries one offer with `endDate: null`, which the API represents as
   `+999999999-12-31` — it occupies *every* future date. A naive
   `intro_offers_create` for a future window therefore fails with **`409 STATE_ERROR:
   DateRange … overlaps with existing offer's DateRange`**. That 409 is an *overlap*
   rejection and says nothing about duration validity — do not misread it as "ASC refused
   7 days". Spot-checked: USA, RUS, CHN, TUR and NRU all carry the same open-ended offer,
   so there is no empty territory to probe in.
2. **`end_date` IS clearable.** `intro_offers_update` documents only `end_date` as
   mutable and gives no explicit way to null it — but **calling it with `end_date` omitted
   restores `endDate: null`.** This is what makes the dated-handover strategy fully
   reversible, and it is not written down anywhere in Apple's docs. Verified by round-trip:
   set `2029-12-31`, then cleared it, and the offer returned byte-identical to its original
   state.

**Split this item: the script is pre-release work; only the flip waits.**

- ~~Probe `ONE_WEEK`~~ — **done 2026-08-01**, see above. Method, for the record: end-date
  the existing offer in one tiny territory to `2029-12-31`, create the probe at
  `2030-01-01`, read the response, delete the probe, clear the end date. Nothing was ever
  served to a user (the 3-day offer ran unchanged throughout), and the territory was
  restored exactly.
- **Do before release — write the script.** ~175 territories × 2 SKUs is what actually
  consumes launch day. Pure prep, zero live effect.
- **Wait for release — the flip itself.** Unchanged, for the reason above.

**Do NOT pre-date the handover**, tempting though the risk table below makes it sound. The
API does support it (`intro_offers_create` takes `start_date`/`end_date`; `update` can set
`end_date`), so you *could* end-date the 3-day offers and start-date the 7-day ones — but
you do not know the release date. It is manual, and gated on both App Review timing and the
in-flight-trial horizon. The failure is one-sided and worth understanding: because 1.3.0
derives duration from the store, there is **no copy-mismatch risk in either direction** once
it is live — the app renders whatever the store says, so a mis-dated offer cannot create a
false promise. The only cost is money — a 7-day offer that starts while 1.2.0 is still being
served gives away four free days nothing advertises. Pre-dating buys convenience and
re-introduces precisely the risk the ordering exists to remove.

**Current offer state (verified 2026-08-01, USA):** both SKUs have exactly **one** offer —
`FREE_TRIAL` / `THREE_DAYS` / `numberOfPeriods: 1` / `startDate: 2026-04-29` /
**`endDate: null`** (open-ended). Offer ids are opaque base64 blobs encoding
subscription + territory, so re-list per territory rather than trying to construct them.

**Recipe:**

1. It is not an edit. `intro_offers_update` can only change `end_date`; changing duration
   means a new offer (`intro_offers_create` with `duration: ONE_WEEK`,
   `offer_mode: FREE_TRIAL`, `number_of_periods: 1`).
2. **Hand over by date — do NOT delete-then-create.** This supersedes the older
   delete+recreate reading, and it is the whole reason the probe was worth running. Per
   territory: `intro_offers_update` the existing 3-day offer with `end_date: <day X>`, then
   `intro_offers_create` the 7-day offer with `start_date: <day X+1>`. Adjacent dates are
   accepted (verified — `2029-12-31` → `2030-01-01` created cleanly), so coverage is
   **continuous and there is no gap at all**. Users on day X still get 3 days; day X+1
   onward they get 7. If a territory goes wrong mid-run, clearing `end_date` (omit the
   field) puts it straight back.
3. Offers are **per-territory**: ~175 territories × 2 SKUs ≈ 700 calls. **Script it** —
   but note that with the dated handover, a slow or partial run is no longer dangerous, only
   untidy. Each territory is independently correct at every moment.
4. ~~**Mind the gap.**~~ **No longer applicable** with the dated handover above, and kept
   only so nobody reinstates delete+recreate from memory. For the record, the old hazard
   was: between delete and create no offer exists, and while 1.3.0 degrades correctly
   (`TrialOffer.fromProduct` returns `null` → "Subscribe" + non-trial copy, so no false
   promise), **every signup inside that window would silently lose its trial**. The dated
   handover removes the window entirely — take it.
4. Verify after: RC `list-offerings` shows `trial_duration: P1W` on both products, and
   the paywall renders "7 days" with no rebuild.

**⚠️ The verification in step 4 will look like it failed, and it won't have.** Verified
2026-08-01: the `$rc_annual` package has **two** products attached, not one —

| Product | `store_identifier` | RC app | `trial_duration` |
|---|---|---|---|
| `prod5d104714bd` | `sakina_sub_annual` | `app776fe1ae80` (App Store) | `P3D` ← **the real one** |
| `prod076d4258c1` | `yearly` | `app75ffdc6cad` (**Test Store**) | `null` ← stale, never loads |

`$rc_weekly` is clean (one product, `sakina_sub_weekly`, App Store, `P3D`). So after the
flip, `list-offerings` will show `P1W` on `sakina_sub_annual` and still `null` on `yearly`.
That is correct output, not a half-applied change — the Test Store product is inert on the
`appl_` key and never reaches a device. **Read `trial_duration` per `store_identifier`, not
per package.** Detaching the stale product is optional cleanup, unrelated to this item.

**Surfaced by:** paywall copy/store reconciliation, 2026-08-01. Weekly subscription id
resolved 2026-08-01 (see table above) — that open gap is closed.

## Extend the dua_windows seed before its horizon (2027-06-20)

**Trigger:** by ~Q1 2027, OR when the in-app seed-horizon health check warns
(`dua_windows_meta.last_seeded_through` within ~90 days of now). After this date
the feature shows no *dated* windows (Friday + precise windows still work).

Recipe:
1. Re-verify Umm al-Qura Gregorian dates for the next window set (Ramadan 1449,
   Dhul-Ḥijjah 1449 + ʿArafah/Eid, ʿAshura 1450, monthly White Days) — validate
   row-by-row against the Umm al-Qura calendar (as done 2026-07-16).
2. Add rows via a new migration to `public.dua_windows` and bump
   `dua_windows_meta.last_seeded_through`.
3. Keep the bundled fallbacks in sync: `assets/dua_calendar/dua_windows.json`
   AND `ios/SakinaWidget/dua_calendar.json`.

**Surfaced by:** Duʿā Times feature (PR #51), 2026-07-16.

## Milestone cosmetic unlocks (streak → free skin)

**Trigger:** whenever streak retention is next worked on. Not blocking any
release — nothing is broken today, this is an unbuilt feature, not a defect.

**What:** award a *specific* cosmetic free when the user reaches a streak
milestone, and show it visible-but-locked in the wardrobe beforehand
("Unlock at a 30-day streak") so it pulls the user toward the streak.

**Why it matters:** the lantern-cosmetics spec
(`docs/superpowers/specs/2026-07-25-lantern-cosmetics-design.md` §49) named this
"the streak-coupling; **strongest retention lever**". It is the one part of the
cosmetics design that never shipped.

**What exists instead:** the Noor economy. Milestones mint *currency*
(40/75/150/250/400 at days 7/14/30/60/90 via `claim_streak_milestone` →
`award_noor`) and Noor buys cosmetics. So the streak does pay out — fungibly,
not as a specific item, and with no "you're 4 days from earning THIS lantern"
pull.

**Status — the metadata was removed, deliberately.** `cosmetic_catalog.milestone_day`
existed but gated nothing, so it was dropped
(`20260727120000_drop_inert_cosmetic_milestone_day.sql`, applied to prod
2026-07-27). Do not read that as the feature being cancelled — the column was
removed *because* a schema that implies a rule it does not enforce is worse than
one that stays quiet. Re-adding the column is the trivial part of this work.

**Steps when ready:**

1. **Server grant path — this is the real work.** Nothing writes
   `user_cosmetics.acquired_via = 'milestone'` today, though the CHECK already
   admits it. Add a SECURITY DEFINER routine that inserts the ownership row on a
   *verified* claim. Fold it into `claim_streak_milestone` so it is atomic with
   the claim and the Noor mint, exactly as the Noor grant was folded in
   (`20260726000700`) — a separate RPC re-opens the lost-grant race that
   migration closed.
2. **Re-add `cosmetic_catalog.milestone_day`** (nullable int) and seed it on the
   chosen rows.
3. **Remove `noor_price` from those rows.** Non-obvious and load-bearing: the
   wardrobe's teaser arm only renders when the price is null-or-zero, so a
   milestone row that is *also* priced falls through to the purchase arm and the
   teaser never appears. That is precisely why the original copy was dead.
4. **Restore the teaser** — `WardrobeAction.unavailableTeaser` was
   `milestoneTeaser` before the cleanup; give it back its streak-aware copy, or
   add a distinct arm.
5. **Emit `milestone_skin_unlocked`** — the analytics constant already exists in
   `analytics_event_names.dart` and has never been fired.
6. **pgTAP** the grant: idempotent per (user, item), refuses an unreached day,
   and does not double-grant on a streak rebuild.

**Surfaced by:** independent review of PR #61 (lantern cosmetics), 2026-07-27.

---

## Duʿā Rain Window (Phase 2) — PARKED

This is a deliberately **PARKED** plan (eng-reviewed 2026-07-16), NOT committed
work — maybe never. Only un-park on a genuine product signal.

**What:** Surface a duʿā prompt when it's currently raining at the user's
location (an authentic time for duʿā that is not turned back). It would be the
FIRST feature to break the Duʿā Times "location never leaves the device"
invariant — it needs a live weather backend (recommended: Apple **WeatherKit**
via a Supabase Edge Function proxy).

**Trigger:** a product signal — e.g. a rainy-market push or a seasonal campaign.

**Depends on / shares:** a Supabase Edge Function proxy — the SAME infrastructure
dependency as the pending **"OpenAI Edge Function proxy"** item above in this
file. Build/share that proxy pattern rather than duplicating it.

**Plan:** `docs/superpowers/plans/2026-07-16-dua-rain-window.md`

---

## Re-enable push_enabled_last_verified_at cron freshness filter (defense-in-depth)

**Trigger:** a second `push_enabled`-drift incident, OR before relying on the
cron freshness filter as a defense-in-depth layer.

**Status:** The `push_enabled_last_verified_at` column + its partial index exist
in prod and are now also captured in a committed migration
(`20260726120000_reconcile_push_enabled_verified_at_column.sql`). BUT the cron
RPC `get_eligible_notification_users` has **no freshness filter** — it was
clobbered by `20260512212403_daily_reminder_uses_user_reminder_time` and never
restored. As of 2026-07-26 only **37 of 1,239** push-enabled users have a fresh
`verified_at` (1,106 are NULL), so re-adding
`AND push_enabled_last_verified_at > now() - interval '7 days'` today would drop
eligibility to 37 and **silently suppress pushes for ~1,200 users**. The filter
must not be re-added until the column is broadly populated.

**Steps when ready:**

1. **Broaden client stamping** in `notification_service.dart` to stamp
   `verified_at` on every `AppLifecycleState.resumed` (currently it only stamps
   on optIn success + one reconcile branch).
2. **Backfill** all existing `push_enabled = true` rows' `verified_at = now()`
   via a migration, so the freshness window starts from a populated baseline.
3. **Only THEN** `CREATE OR REPLACE get_eligible_notification_users` re-adding
   the `AND push_enabled_last_verified_at > now() - interval '7 days'` clause.
4. Add a pgtap test asserting stale rows are excluded and fresh rows included.

**Surfaced by:** push_enabled-drift QA finding, 2026-07-26.

---
## Reel deep links: give them somewhere to be tapped from

**Trigger:** when you want `sakina://reel/<id>` or `sakina://feel/<emotion>` to actually
reach users — i.e. when a reel is posted that names its two Names on camera and you
want those exact Names revealed.

**Status:** the **in-app half is done and shipped.** `reel_deep_link_service.dart`
parses both links, `?name_ids=12,34` overrides the pair the hook chip would have
resolved, capture happens in `main.dart` before `runApp`, the drain happens at the
onboarding entry, and the `sakina` URL scheme is already registered in
`ios/Runner/Info.plist` (under `com.sakina.app.referral` — scheme registration covers
every `sakina://` host, so no plist change is needed).

**What is missing is entirely outside the app, and it is the part that matters for
organic Instagram:**

- **A custom scheme does nothing for a user who does not have the app.** Tapping
  `sakina://reel/12` in Instagram on a device without Sakina fails silently — no App
  Store redirect, no install. So today these links only work for **warm** traffic
  (existing users), which is not the acquisition case.
- **Nothing emits them.** There is no bio link, landing page, or QR that contains one.

**Steps when ready:**

1. **Cheapest path — a redirecting landing page (no domain purchase required).** Host
   `/<reel-slug>` anywhere you control. On load, attempt `sakina://reel/<id>?name_ids=…`
   and fall back to the App Store URL after ~1s. Installed users deep-link; everyone
   else installs. Does NOT carry the reel id through a cold install (the App Store
   breaks the chain) — accept that, or use step 2.
2. **Universal links (needs the domain).** Acquire `sakina.app`, host
   `/.well-known/apple-app-site-association`, add the `associated-domains` entitlement
   (`applinks:sakina.app`), and add an `https://sakina.app/reel/<id>` handler alongside
   the custom-scheme parser. This is the plan's Phase 2 item — deliberately out of
   scope for v1.
3. **Do NOT buy an attribution SDK for this** (Branch/AppsFlyer/Adjust). It is the only
   thing that carries a reel id through a cold install, but at ~21 signups/day the plan
   already declares audience dimensions directional-only and bars them from the keep
   decision. You would be paying for precision you have agreed not to act on.

**Surfaced by:** W2 completeness audit, 2026-07-29.

---

## `reel_hook`: close the reel-source measurement gap

**Trigger:** W5 instrumentation, before T0. The plan calls reel-source capture "the
plan's biggest measurement hole."

**Status — CLOSED except step 3.** One Ship W6 (2026-08-01) landed steps 1, 2 and 4.
`reel_hook`/`reel_hook_source` are registered as super properties at onboarding entry
(`unknown`/`unknown`) and upgraded to `deep_link` (a drained `sakina://reel/<id>`) or
`self_report` (the source screen, `source_question_screen.dart`) — always together, from
one call site each, so the two can never disagree. The event name was reconciled by
**amending the plan to the shipped `reel_source_selected`**, not by renaming the code —
see D1 in `docs/superpowers/plans/2026-08-01-one-ship-06-instrumentation.md` for why a
rename would have cost a permanent two-name union for zero information gained. `contract`
was adopted as the **primary** reel-of-origin dimension (D3), registered alongside
`acquisition_problem_category` at hook-selection time; `reel_hook` is corroboration and the
only thing that can separate two future reels making the same promise. Full detail:
[`docs/analytics/funnel-flags-and-querying.md`](./docs/analytics/funnel-flags-and-querying.md).

**Steps:**

1. ~~Register `reel_hook` as a super property, with its provenance stated~~ — **done**, W6.
2. ~~Reconcile the event name with the plan~~ — **done**, W6 (plan amended, code kept).
3. **App Store Connect Campaign Links, per reel (free, first-party). Still open.**
   Generate one per reel behind the bio link; App Analytics then reports App Store views and
   downloads per campaign. This answers "which reel drives installs" — the actual creative
   question. Aggregate only: it cannot be joined to a Mixpanel `distinct_id`, so it informs
   creative decisions, not per-user attribution. Runbook:
   [`docs/analytics/funnel-flags-and-querying.md`](./docs/analytics/funnel-flags-and-querying.md#asc-campaign-links-runbook).
4. ~~Consider `contract` as the better proxy for reel-of-origin~~ — **done**, W6 (D3);
   `contract` is now the primary dimension, `reel_hook` corroborates it.

**Not needed:** the install-id join. `InstallIdService` already mints a stable id at
first boot and registers it as BOTH a Mixpanel super property and a RevenueCat
subscriber attribute (`purchase_service.dart:77`), deliberately not
`$mixpanelDistinctId` — Mixpanel's distinct id changes at `identify()` under Simplified
ID Merge while the install id never does. It is a **join key, not an identity alias**:
join RC and Mixpanel on `install_id`; do not expect Mixpanel to have merged the
identities. Nothing external is required. Note a reinstall mints a new id, so reinstalls
appear as fresh arrivals in any reel→purchase join.

**Surfaced by:** W2 completeness audit, 2026-07-29.

---

## One currency: merge tokens + tier-up scrolls into Noor

**Trigger:** the **softener wave** (post-T0+6wk keep decision, completed before
Ramadan prep). Not before. That wave already sends a 30-day notice, already
migrates every legacy free user, and already deletes the bypass subsystem —
which touches the same functions this work converts. Doing it there costs one
extra sentence in a message you are already sending; doing it earlier costs a
second disruption and a currency change inside the window you are measuring
conversion in.

**Full plan (do not re-derive — the research is expensive):**
[`docs/superpowers/plans/2026-07-31-one-currency-noor-merge.md`](./docs/superpowers/plans/2026-07-31-one-currency-noor-merge.md)

**What:** Sakina runs three soft currencies — tokens, tier-up scrolls, Noor —
against three separate sinks, which is why none of them is liquid. Collapse
them into Noor.

**Why it is NOT urgent (verified 2026-07-31, so nobody re-panics about it):**

- **Nothing is false.** After W5 removes the AI bypass, tokens still buy streak
  restores (100/250/500 by pre-lapse streak) and scrolls still buy card
  tier-ups. `paywallPremiumBenefit4` ("A monthly gift of tokens & scrolls")
  stays *true* — weaker, not a lie. No copy-firewall problem.
- **Nobody loses what they paid for.** The bypass removal is cohort-scoped, so
  every existing token holder keeps the bypass until this same wave. New-cohort
  users never had it and never bought tokens for it.
- **The economy was already inert.** 348,024 tokens outstanding across 1,362
  accounts; **2,775 ever spent, by 31 users.** 0.8% of everything ever minted.
  Removing the bypass did not break a working economy.

**The two things that will bite whoever picks this up:**

1. **Scrolls cannot be scoped out.** `tier_up_scrolls` is a *column on
   `user_tokens`*. Leaving scrolls behind means keeping that table alive as a
   one-column vestige.
2. **The price ladders do not line up.** A tier-up costs **5 scrolls**; a
   lantern skin costs **120–300 Noor**. Merge scrolls 1:1 and every card upgrade
   in the game becomes free. Converting scrolls therefore *requires* repricing
   tier-ups onto the Noor ladder first — and at the obvious repricing
   (100/200 Noor) the combined backfill hands **~704,000 Noor** to the base,
   roughly two to four free cosmetics each. That giveaway is the real cost of
   this work, and it is an economics decision, not an engineering one. The plan
   recommends 1:1 on tokens **with a per-account cap**.

**Two decisions still open** (§3 of the plan): whether scrolls fold in, and the
conversion rate.

**⚠️ Re-read the numbers before acting.** Balances grow daily from signup grants
and daily rewards, so the ~704k backfill exposure only moves one way. The
figures above are a 2026-07-31 snapshot, not a constant.

**Steps when ready:** §5 of the plan — decide → server functions converted
(**12 live**; only 3 — `reserve_ai_bypass` / `cancel_ai_bypass` /
`_replay_reservation_response` — are deleted with the bypass. Corrected
2026-07-31: an earlier "~10 live, five deleted" also subtracted `spend_tokens`
and `sync_all_user_data`, which only lose a *branch* and still need converting)
→ one idempotent stamped
backfill (`user_tokens` retained read-only as the audit trail) → client swap +
Store SKU retirement (gated on a Mixpanel `pack_purchased` check, test IDs
excluded) → one plain sentence in the softener notice → drop the table one
release later, inside the legacy-deletion sweep already scheduled for then.

## Journal refactor to follow couples app UI
