# TODO

Deferred work — not blocking the current iOS submission, but needed before specific future milestones. Each item names its trigger so it's clear when it becomes urgent.

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
