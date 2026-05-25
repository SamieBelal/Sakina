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

## Arabic + English mixed in single Text widget on home screen header

**Trigger:** when polishing the home screen visuals, OR if a user reports the home greeting wraps oddly or shows reversed punctuation. Not blocking but visually fragile.

**Status:** `lib/features/feelings/screens/home_screen.dart:192` (or current equivalent — line may have shifted) mixes Arabic and English text inside one `Text` widget. Flutter's RTL rendering on the Arabic substring bleeds into adjacent layout, causing the surrounding UI to occasionally reflow in unexpected ways. CLAUDE.md's Critical Rules section forbids this pattern but a legacy violation slipped through.

**Steps when ready (~10 min):**

1. Grep `lib/` for any `Text(...)` literals containing both Arabic Unicode (U+0600–U+06FF) and ASCII letters in the same string.
2. Split each into two `Text` widgets in a `Row`, each with explicit `textDirection`. For the Arabic side use `TextDirection.rtl`.
3. Add a regression test that loads the home screen and asserts both substrings render in their own widgets (look up by key or by `find.text(...)`).

**Surfaced by:** /review on 2026-05-24.

---

## ~~Daily-loop cache key + checkin_history.date use local time, not UTC~~ ✅ DONE 2026-05-12

Shipped via PR #9 (commit `013cc73`) — `debugDailyLoopClock` seam added to
`daily_loop_provider.dart`, all three `DateTime.now()` callsites
(`_todayKey` + both `CheckInRecord.date` writes) routed through it.
`debugQuestBoundariesClock` seam added to `quests_provider.dart` so
`_weekStart()`/`_monthStart()` agree with the now-UTC `CheckInRecord.date`
they compare against. Pinned by `test/features/daily/daily_loop_utc_test.dart`
and `test/features/quests/quests_provider_utc_boundaries_test.dart`.

Plan: `docs/superpowers/plans/2026-05-12-daily-loop-utc-migration.md`.

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

## ~~TZ-flake risk on 4 service tests with local-date prefs keys~~ ✅ DONE 2026-05-25

Three of the four files had already been migrated to `DateTime.now().toUtc()`
(`daily_rewards_service_test.dart:28`, `daily_usage_service_test.dart:19`,
`gating_service_test.dart:63`). `user_data_batch_sync_service_test.dart`
already had the `todayUtcStr()` helper in place; the remaining gap was the
`usage_date` field on the fake `daily_usage` RPC payload, which still used
the local-date `todayStr()`. Production filters that field via
`_findTodayUsageRow` against `_today()` (UTC), so a local-date value would
be silently dropped under `TZ=America/New_York` CI during the local-vs-UTC
midnight window, failing `getReflectUsageToday()` / `getBuiltDuaUsageToday()`
assertions. Patched to `todayUtcStr()`.

The remaining `todayStr()` usages in that file are intentional — they back
`daily_answer_*` keys which `daily_question_provider.todayKey()` writes
using LOCAL date in production, so test and production agree.

---

## Email regex ASCII-only excludes internationalized email

**Trigger:** before localization expands beyond English (Arabic, Urdu, Malay, Turkish, French are priority languages per CLAUDE.md). Turkish/French users with diacritics in their local-part (e.g., `josé@example.com`) currently hit "Please enter a valid email" at the onboarding signup step and bounce out of the funnel.

**Status:** `lib/features/onboarding/screens/sign_up_email_screen.dart:30` uses an ASCII-only regex (`^[a-zA-Z0-9...]+@[a-zA-Z0-9...]+\.[a-zA-Z0-9]+$`). Supabase auth itself accepts Unicode emails — only the client validation rejects them. Net effect: no security issue (we'd just allow the value to be sent), but real users get a confusing client-side error.

**Steps when ready (~10 min):**

1. Replace the regex with either:
   - `^[^\s@]+@[^\s@]+\.[^\s@]+$` (loose — matches what Supabase actually accepts), OR
   - `RegExp(r'^[\p{L}\p{N}._%+\-]+@[\p{L}\p{N}.\-]+\.[\p{L}]{2,}$', unicode: true)` (Unicode-aware, stricter)
2. Add 3-4 test cases to `test/features/onboarding/sign_up_email_screen_test.dart` (or wherever validation tests live) covering `josé@example.com`, `用户@例え.jp`, and a deliberately-invalid `not@an@email`.

**Surfaced by:** Subagent paywall review during the 2026-05-24 master review.

---

## Session-race recovery on signup loops users back to the same error

**Trigger:** if support tickets show a pattern of "I'm stuck on the password screen, retried but it keeps failing" specifically on slow networks. Has not been observed in production yet but is structurally present in the code.

**Status:** `lib/features/onboarding/screens/sign_up_password_screen.dart:84` handles the rare race where `supabase.auth.signUp()` returns success but `Supabase.instance.client.auth.currentUser` is still null on the next read (network reordering). The current behavior is: show snackbar "tap Continue to finish signing in" and return. But tapping Continue re-runs `signUpWithEmail()` against the same email/password, which on Supabase returns "User already registered" — looping the user with no recovery path other than backing out and changing email.

**Steps when ready (~20 min):**

1. On session-race, instead of just returning, retry `Supabase.instance.client.auth.currentUser` once after a 500ms delay before showing the snackbar. If it's now populated, proceed to persist + advance.
2. If still null after the retry, call `Supabase.instance.client.auth.signInWithPassword(email, password)` to recover the session rather than re-invoking `signUp`.
3. Only show the snackbar if both fallbacks fail — at that point the user genuinely needs to manually retry, and the snackbar copy can be honest about it.
4. Add a regression test that mocks the race (signUp returns success, currentUser returns null, then on retry returns the user) and asserts the password screen completes.

**Surfaced by:** Subagent paywall review during the 2026-05-24 master review.

---

## Tripwire + producer-pin coverage gaps

**Trigger:** before the next polish pass on the AI-bypass funnel OR after the next IPA-2-to-sub upsell experiment iteration. Not blocking anything today.

**Status:** Two gaps in the analytics + release-tripwire infra surfaced during the 2026-05-24 master review:

1. **Producer-pin only covers `iapToSubBannerShown`.** The structural test at `test/widgets/iap_to_sub_upsell_banner_test.dart:686-699` scans `lib/` for at least one producer of `iapToSubBannerShown`. Good — pins finding P0-5. But the paired events `iapToSubBannerDismissed` and `iapToSubBannerDismissFailed` (added in P2-4) have no equivalent producer-pin. A refactor that removed the producer for either would slip through silently, recreating the original P0-5 class of bug (event declared but never emitted).

2. **`scripts/check_no_fake_strings.sh` covers only `FAKE_DO_NOT_SHIP_` placeholders.** It doesn't catch the next P2-2-class regression (the IAP→sub banner once had a fabricated-dollar `$X spent` figure). The shape of that bug — copy claiming a specific monetary value not backed by real accounting — is exactly what FTC endorsement rules + Apple 3.1.1 care about. The current tripwire is too narrow.

**Steps when ready (~30 min total):**

1. **Extend the producer-pin test** (test/widgets/iap_to_sub_upsell_banner_test.dart) to enumerate all 4 banner events (shown / tapped / dismissed / dismissFailed) in a loop, asserting each has ≥1 producer file in `lib/`. Same scan pattern as the existing test, just iterate the constants.
2. **Add a second guard to `scripts/check_no_fake_strings.sh`** that greps `lib/widgets/iap_to_sub_upsell_banner.dart` (or all `lib/widgets/`) for any literal string matching `\$\d+\s*(spent|saved)` or "You.?ve spent" patterns. Fails the build if found — forces the dev to either (a) hard-code "you've used N bypasses" style copy without monetary claims, or (b) wire a real accounting integration.
3. Run `./scripts/check_no_fake_strings.sh` locally to confirm clean.

**Surfaced by:** /plan-eng-review on PR #28 (testing specialist subagent).

---

## SQL hygiene grab-bag

**Trigger:** before the next significant Supabase schema change, OR if a security audit (internal or external) is ever scoped. None of these are exploitable today; they're posture + readability improvements.

**Status:** Four small SQL items surfaced during the 2026-05-24 master review:

1. **`cancel_ai_bypass` original vulnerable body in `20260523213854_ai_bypass_reservations_and_rpcs.sql:337`** is fine in practice (patched by the `20260524154019_ai_bypass_p1_security_bundle.sql` migration) but anyone reading the migrations chronologically sees the vulnerable body first. Add a one-line header comment to the earlier migration pointing forward to the P1 bundle to prevent confused readers / accidental reverts.

2. **`grant_winback_tokens(uuid, int)` in `20260523213854_ai_bypass_reservations_and_rpcs.sql:589`** has `revoke execute ... from public, anon, authenticated` but no explicit `grant ... to service_role`. Works today via default ACL (service_role inherits postgres's grants), but explicit grants defend against a future `revoke all on schema public from service_role` blast radius. Append `grant execute on function public.grant_winback_tokens(uuid, int) to service_role;`.

3. **Local cron stub `20260416080000_local_dev_cron_stub.sql:49`** only implements the 3-arg `cron.schedule(jobname, schedule, command)` overload. Real pg_cron also supports the 2-arg form. No current migration uses 2-arg, but the next one to use it will fail only locally / in CI while passing on prod. Add the 2-arg overload to the stub.

4. **`get_eligible_notification_users` in `20260512212403_daily_reminder_uses_user_reminder_time.sql:46`** is `SECURITY DEFINER` with `set search_path = public, auth`. The function joins `auth.users` (already qualified inline), so the wider `auth` in search_path isn't strictly needed. Tightening to `set search_path = public, pg_temp` matches the project convention and narrows the trust surface. Verify the qualified `auth.users` references still resolve after the tighten.

**Steps when ready (~20 min total):**

Bundle into a single follow-up migration `<timestamp>_sql_hygiene_grab_bag.sql` that applies all 4 changes. Comment header should reference this TODO entry.

**Surfaced by:** Subagent migration review during the 2026-05-24 master review.

## Localize win-back push

Push template `win_back_tour_replay` (see `docs/runbooks/onesignal-segments.md`) is EN only — localize when project i18n infrastructure exists.
