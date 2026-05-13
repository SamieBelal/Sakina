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

## ~~Production telemetry for unknown-name fallback~~ ✅ DONE 2026-05-12

Shipped via migration `20260512000000_create_reflect_unknown_name_log.sql` +
`onFallback` callback on `normalizeApprovedVerses` (`reflection_verse_catalog.dart`)
wired to fire-and-forget `_logUnknownNameFallback` in `ai_service.dart`
(mirrors `_logClassifierDecision`). User-scoped RLS (INSERT-own + SELECT-own),
no PII columns. Callback wrapped in try/catch so a misbehaving logger can
never break the reflect flow — pinned by `reflection_verse_catalog_unknown_name_callback_test.dart`.

Migration applied + smoke-verified on remote (insert lands, RLS isolates
owner from other users, indexes in place).

**Weekly review query** (run in Supabase SQL editor or via MCP):

```sql
select ai_returned_name, count(*) as hits, max(created_at) as last_seen
from public.reflect_unknown_name_log
where created_at > now() - interval '7 days'
group by 1
order by hits desc
limit 25;
```

If the same non-canonical spelling shows up repeatedly, either add it to the
canonical-name alias map or expand `approvedReflectVersesByName` in
`lib/features/reflect/data/reflection_verse_catalog.dart`.

---

## Daily-loop cache key + checkin_history.date use local time, not UTC

**Trigger:** next time a user reports "I did my muhasabah but the streak didn't update" or "I lost my daily progress crossing midnight". Also good to bundle into the next correctness pass on the daily flow.

**Status:** `lib/features/daily/providers/daily_loop_provider.dart` keys SharedPrefs and writes `user_checkin_history.date` from `DateTime.now()` (LOCAL), while `daily_rewards_service` (`_today()`/`_yesterday()`) and `streak_service` (`_todayString()`) both key by UTC. Pre-existing — commit `8d135808` from 2026-04-03 introduced the local-time key. Unrelated to the daily-launch fix shipped on 2026-05-12 but the same bug shape.

Specific lines on master (`fix/2026-05-12-daily-launch-overlay` HEAD shows the same):
- `daily_loop_provider.dart:254` — `String get _todayKey` builds the SharedPrefs cache key from local date. Used at lines 710, 984, 993. Effect: a user crossing local midnight on the same UTC day re-loads with empty "daily loop" state (questions un-answered, fresh muhasabah) even though the streak/reward services already counted the cycle.
- `daily_loop_provider.dart:445, 610` — both `final today = DateTime.now();` write into `user_checkin_history.date` as a local-date string. Server-side queries that compare `user_checkin_history.date` against `user_streaks.last_active` (UTC) will mismatch in the same window.

**Steps when ready (~20 min total):**

1. Apply the same `debugRewardsClock`-style seam pattern (`lib/services/daily_rewards_service.dart:215-222`) to a new top-level `debugDailyLoopClock = () => DateTime.now().toUtc()` in `daily_loop_provider.dart`.
2. Replace the three `DateTime.now()` callsites (254, 445, 610) with `debugDailyLoopClock()`.
3. Decide on a migration story for the SharedPrefs key. On first load post-upgrade, the user's existing `daily_loop_<local-date>` key won't match the new `daily_loop_<UTC-date>` key, so they'll see one "fresh muhasabah" state. Acceptable — it's a one-time blip and the server-side streak/reward is unaffected.
4. Decide whether to backfill `user_checkin_history.date` rows whose `date` disagrees with the `checked_in_at` UTC date. Probably not worth it — historical analytics only.
5. Add a regression test mirroring `test/services/launch_gate_state_utc_test.dart` that mocks the new seam and pins both the SharedPrefs key shape and the `user_checkin_history.date` write.

**Surfaced by:** /review on the `fix/2026-05-12-daily-launch-overlay` branch — adjacent code path with the same class of bug as the launch-gate UTC fix that shipped in that PR.

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
