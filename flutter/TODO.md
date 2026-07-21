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

---

## Back the paywall's premium-benefit claims (Emerald cards + streak protection)

**Trigger:** before the next App Store submission that ships the updated
onboarding paywall (commit on `feat/paywall-benefits`). Two of the five
advertised premium benefits are NOT yet backed by a real entitlement. Shipping
the copy ahead of the mechanic is a deliberate, owner-approved call
(2026-07-20), but it's **App Store 3.1.1 exposure** (advertising IAP benefits
that don't function) and a trust risk for paying users. De-risk soon.

### 1. Emerald cards — advertised "Exclusive Emerald cards for every Name", currently unearnable

The Emerald tier (tier 4) is fully built as a **shell** — `CardTier.emerald`
(`lib/services/card_collection_service.dart:28`), tier↔int↔string maps, and
render/preview widgets labelled "Premium Exclusive"
(`lib/features/collection/widgets/emerald_card_preview.dart`,
`emerald_ornate_card.dart`) — but there is **no grant path**. Daily gacha caps
at Gold (`card_collection_service.dart:2042`, `else if (currentTier < 3)`), the
store only upgrades Bronze→Silver→Gold (`store_screen.dart:551`), and no
referral / purchase / premium path awards tier 4.
`lib/services/analytics_event_names.dart:583`: *"gold is the current ceiling,
engageCard never produces emerald."*

**Recipe (~small):**
1. Let PREMIUM users tier past Gold to Emerald: gate the tier-up cap in
   `card_collection_service.dart` (~line 2042) on `PurchaseService.isPremium()`
   — premium re-encounters reach tier 4 (`currentTier < 4`), free stays `< 3`.
2. Decide the exact rule: the copy says "for every Name" — confirm whether
   premium unlocks Emerald across the whole set or must tier each card up.
3. The collection screen already renders earned Emerald tiles (display path at
   `:1917` handles `maxTier >= 4`); verify it.
4. Test: premium user reaches Emerald; free user still caps at Gold.
5. Collection is client-side (SharedPreferences), so no economy-table/RPC
   change is needed — but respect the freemium-guard invariants if it ever
   moves server-side.

### 2. Streak protection — advertised "so you never lose progress", not premium-exclusive

Free users already get the same single streak-freeze slot
(`lib/services/streak_service.dart:296`; `daily_rewards_service.dart:85` returns
the freeze reward unchanged for premium). To make the claim true, make streak
protection a genuine premium differentiator — e.g. premium-only auto-freeze, a
larger / refilling freeze allowance for premium — then wire + test it. (Or
reword the benefit.)

**Surfaced by:** `/review` claim-accuracy pass (Codex adversarial), 2026-07-20.

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
