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

## Supabase HIBP leaked-password protection

**Trigger:** if/when you upgrade to Supabase Pro plan or above.

**Status:** Supabase Auth has a built-in HaveIBeenPwned integration that rejects compromised passwords at signup/password-change. It's **gated to Pro+ plans** — not available on Free. The advisor warning (`auth_leaked_password_protection`) will keep firing on Free; safe to ignore until upgrade.

**Action when upgrading:** Supabase Dashboard → Authentication → Policies → toggle on "Leaked Password Protection." 30-second change, no migration needed.

---

## Home-screen Premium banner (second upgrade entry)

**Trigger:** Apple re-rejects citing discoverability of subscriptions even after the Settings card ships, OR analytics on `settings_premium_cta_tapped` shows a low tap-through rate (<2% of free-user Settings opens within 30 days post-launch) suggesting Settings alone isn't pulling free users to the paywall.

**Status:** Spec `docs/superpowers/specs/2026-05-13-settings-premium-entry-design.md` (shipped 2026-05-13) added a `SettingsPremiumCard` upgrade entry inside `/settings` only. Apple's rejection diagnosis originally suggested a Home-screen banner as well, but the Home strip was explicitly deferred to keep the warm/devotional Home aesthetic clean and to ship the Settings fix first.

**What:** a small gold strip on `lib/features/home/screens/home_screen.dart` (free users only, gated on `premiumStateProvider.isPremium == false`) sitting above or below the daily check-in CTA. Copy: "Try Sakina Premium →". Tap → `context.push('/paywall')` (same route the Settings card uses; no new route plumbing).

**Why:**
- Belt-and-braces discoverability for App Review — reviewers exercise Home far more than Settings.
- Free users in the daily-check-in habit see the upgrade pitch in the flow of normal use, not buried in Settings.
- Reuses every existing piece: `/paywall` route, `premiumStateProvider`, analytics events pattern.

**Pros:** Bulletproof App Review fix. Lifts conversion (a Home-surface upgrade entry is the highest-converting placement in every paywall analytics study). ~40 LoC widget + 3-line Home insert.

**Cons:** Adds visual weight to Home, which is currently devotional and uncluttered. Risk of feeling pushy. Premium users see nothing (good), so no negative impact on paying users.

**Steps when ready (~30 min total):**
1. Create `lib/features/home/widgets/home_premium_strip.dart` — `ConsumerWidget` watching `premiumStateProvider`, returns `SizedBox.shrink()` for premium and an `InkWell`-wrapped gold strip for free users.
2. Insert into `home_screen.dart` build above the daily check-in CTA (find the right slot by scanning for the existing `Begin Muḥāsabah` block).
3. Add `home_premium_strip_tapped` to `AnalyticsEvents`; fire on tap before push.
4. Add widget test under `test/features/home/widgets/` covering both states + tap behavior.
5. Verify on iPad Air M3 (the original App Review device) that the strip renders correctly.

**Surfaced by:** /plan-eng-review on the Settings Premium Entry design (2026-05-13).

## Drop the 1-arg reserve_ai_bypass shim after IPA drain

**Trigger:** when ≤1% of `reserve_ai_bypass` calls come from app versions older than the first version shipped with PR #26 (i.e., pre-idempotency-key clients have drained from the install base). Track via Mixpanel app-version segmentation on the `reserve_ai_bypass` event. Realistic window: 60+ days after PR #26 hits the App Store, longer if any holdout cohort persists.

**Status:** PR #26 kept the 1-arg `reserve_ai_bypass(text)` as a backwards-compat shim that auto-generates a server-side idempotency key. Old IPAs lose idempotency (each call generates a fresh key on the server), keeping their original double-debit bug. Acceptable transitional state — should not be permanent.

**What to do:**

1. Confirm the adoption threshold in Mixpanel (≤1% of calls from pre-PR-26 versions).
2. Write a follow-up migration that drops the 1-arg overload, leaving only the canonical 2-arg `reserve_ai_bypass(text, idempotency_key)` signature.
3. Add a `raise exception` or NOTICE to the dropped function path during a soft-deprecation window so we catch any unexpected callers before the hard drop.
4. Verify no Edge Function or other Postgres code still invokes the 1-arg form.

**Pros:** Single canonical signature. Cleaner schema. Forces upgrades for the holdouts (who would have lost idempotency anyway on the shim path).

**Cons:** Any user still on a pre-PR-26 IPA after the drop will see silent failure on their bypass action. Pick the threshold carefully.

**Context:** the original shim ships with a note in `supabase/migrations/20260524010000_reserve_ai_bypass_idempotency.sql` explaining when to drop it. Originally tracked in `TODOS.md` under "P1 — Deferred follow-ups from PR #26"; consolidated into this file on 2026-05-25.

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

**Depends on / blocked by:** Ship the cancellation-feedback feature first; reuse
its detection (`expires_at` episode) and the `CancellationFeedbackSheet` surface.

**Surfaced by:** `/plan-eng-review` of the cancellation-feedback spec, 2026-05-31.

## Remove sandbox gate on cancellation survey push (at launch)

**What:** `supabase/functions/revenuecat-webhook/index.ts` `sendCancellationSurveyPush`
has a temporary gate `if (payload.environment !== "SANDBOX") return;`.

**Why:** Pre-launch, production users don't have the survey UI / the
`sakina://cancellation-feedback` deep link, so a push would dead-end at home.
The gate restricts the push to SANDBOX (test devices) so no real user gets a
useless notification.

**Trigger:** The App Store release containing the cancellation-feedback survey is
LIVE.

**How:** Delete the `payload.environment !== "SANDBOX"` early-return and redeploy
the edge function (server-only; NO App Store update needed). Then production
cancellations fire the push → deep link → survey.

**Surfaced by:** Physical-device Test 3 setup, 2026-05-31.

## Formalize the design system: /design-consultation → DESIGN.md

**What:** Run `/design-consultation` and capture the result as a repo `DESIGN.md`:
palette (incl. the new `sacredCanvas*` token block), typography stack, spacing
philosophy, motion vocabulary (beat-advance transition), and the on-canvas rules
("gold is a non-text accent only — it fails 4.5:1 contrast on emerald"; "cream
`sacredInk` for functional text").

**Why:** The 2026-07-14 bite-sized-AI-text design review had to derive the system
from CLAUDE.md prose + one mockup. The sacred canvas is the app's second surface
identity — the point where undocumented systems start drifting (the next emerald
becomes `#1A6B4B`).

**Trigger:** Before designing the next net-new surface (widget, gift moment,
onboarding refresh) — or whenever a second contributor starts doing UI work.

**Depends on / blocked by:** Nothing. Cross-link DESIGN.md from CLAUDE.md's design
section so the two don't drift.

**Surfaced by:** `/plan-design-review` of the bite-sized-AI-text spec, 2026-07-14.
