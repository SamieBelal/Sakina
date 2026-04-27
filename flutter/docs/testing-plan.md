# Sakina Flutter Testing Plan

Coverage-oriented plan for the Flutter app. Defines **what to test** and at **which layer** (unit, provider, widget, E2E). Pair with `manual-test-plan.md` for on-device runbooks and DB/MCP assertions — don't duplicate execution steps here.

## Release blockers

High-signal checks that gate every release:

1. **Premium + paywall** (when billing is enabled)
   - RevenueCat init succeeds with keys, fails safely without.
   - Auth signs user into RevenueCat with stable Supabase user id.
   - Onboarding paywall renders annual + weekly pricing from offerings.
   - Purchase success → entitlement granted → routed to Home.
   - Purchase cancel → stays on paywall.
   - Restore success → routed to Home. Restore with no entitlement → user-facing error.
   - Offerings load failure → recoverable error UI (not blank).
   - Webhook updates `is_premium` correctly on purchase / cancel / expiration.

2. **Legal**
   - Privacy + Terms links open.
   - Consent copy matches what's actually stored.

3. **Notification permission timing**
   - iOS system prompt fires **only** on the notification screen.
   - Account creation alone does not trigger it.
   - Skipping notifications preserves onboarding progress.

## Test pyramid

1. **Unit** — pure business rules: streak logic, XP curves, reward math, AI response parsing, RPC payload mapping, catalog validation.
2. **Provider / service** — Riverpod state transitions, SharedPreferences caching, Supabase sync, failure recovery.
3. **Widget** — rendering, enabled/disabled states, empty states, destructive confirmations, upgrade prompts.
4. **E2E smoke** — a handful of app-level flows to verify routing, persistence, and cross-feature integration.

## Section-by-section checklist

### 1. Launch and session

- Fresh install opens Welcome.
- Onboarded + signed-in opens Home.
- Signed-out but onboarded → Welcome.
- Relaunch preserves route.
- Sign-out clears scoped caches (no leak across accounts).
- Account deletion removes user-scoped data and returns to entry flow.

### 2. Welcome, auth, account creation

- Hook screen routes correctly.
- Email sign-up: name/email/password validation + happy path.
- Google + Apple sign-in happy paths.
- Existing onboarded user skips onboarding on sign-in.

Edge: invalid email, weak password, duplicate email, social auth cancellation.

### 3. Onboarding flow

Pages are enumerated in `docs/manual-test-plan.md` §3 (0–24). For every page test:
- Initial render.
- Back + continue behavior.
- Validation rules.
- State survives app kill/resume.
- `progressSegment` matches page index.
- Analytics event emitted once (no duplicates on back-then-forward).

Flow-level:
- Full happy path Welcome → Home.
- Resume from mid-onboarding after force close.
- Backtracking edits prior answers.
- Social auth stays in-flow (calls `_next`, not `_goToPaywall`).
- Paywall (last index) sits outside the progress bar.
- After paywall dismiss/complete, verify `user_profiles` row has ALL fields populated: `display_name`, `onboarding_intention`, `age_range`, `prayer_frequency`, `onboarding_quran_connection`, `onboarding_familiarity`, `resonant_name_id`, `dua_topics`, `common_emotions`, `aspirations`, `daily_commitment_minutes`, `reminder_time`, `commitment_accepted`, `onboarding_attribution`. Regression guard against the 2026-04 silent-write-failure bug where a bad column name caused the whole UPDATE to fail.

### 4. Daily core loop

- Daily launch overlay shows only when expected. As of 2026-04-26, the overlay has TWO live steps (`_step` 0 = streak greeting, `_step` 1 = reward claim). The legacy `_step` 2 multi-question check-in widget (`_CheckInStep`) was removed; the only muhasabah path is now Home → "Begin Muḥāsabah" → `/muhasabah` → `discoverName()`.
- Home loads streak, XP, tokens, quests.
- ~~Muhasabah questions advance.~~ (REMOVED — see above. `discoverName` skips questions and goes straight to gacha.)
- ~~Final answer triggers AI response → saves to history.~~ (REMOVED — `discoverName` writes a sentinel `q1='discover'` row with q2/q3/q4 empty.)
- Gacha reveal shows correct card with working Continue.
- Reward claims update balances.
- Achievement checks fire after completion.

Edge: ~~double-tap answer~~ (latent — `answerCheckin` has a `if (state.checkinLoading) return;` guard added 2026-04-26 with regression test in `test/features/daily/answer_checkin_reentry_guard_test.dart`; the multi-question UI is gone but the function is preserved against future reintroduction), double-tap continue on gacha, ~~background during AI loading~~ (no AI call in `discoverName`; obsolete until a meaningful loading window is reintroduced), midnight boundary (local vs UTC — verified 2026-04-26 via DB-driven date-rewind), same-day repeat does not duplicate rewards, streak freeze consumed only when needed (consume happens in `streak_service.dart markActiveToday` not in claim — verified 2026-04-26 with seed `streak_freeze_owned=true`, `last_active=current_date-2`, `current_streak=N` → post `streak=N+1`, `streak_freeze_owned=false`).

### 5. Discovery quiz

- Quiz starts only when no anchors exist.
- Each answer advances.
- Results deterministic for known inputs.
- Results persist locally + remotely.
- Settings shows saved anchors.
- Re-entering doesn't corrupt prior results.
- **DQ-E1 quit-mid-quiz** → restarts cleanly. Quiz state lives in `DiscoveryQuizNotifier` memory only; `selectedAnswers` is not persisted to SharedPreferences. Cold-launch reads `loadSavedDiscoveryQuizResults` from server; with no row, the notifier ends up `initialized: true, completed: false`, and on next entry `ensureQuizReady()` → `startQuiz()` resets to question 0. Live sim PASS 2026-04-26 (this session): answered Q1+Q2 → `xcrun simctl terminate booted com.sakina.app.sakina` → relaunch → Home (no resume), DB row count remains 0.
- **DQ-Retake** → upserts, never duplicates. `completeQuiz()` (`lib/features/discovery/providers/discovery_quiz_provider.dart:120-132`) calls `saveDiscoveryQuizResults(results)` which runs `supabaseSyncService.upsertRow('user_discovery_results', userId, {'anchor_names': encodedResults}, onConflict: 'user_id')`. `user_discovery_results` has a unique constraint on `user_id`, so the row count is bounded at 1 by DB invariant — duplicates are impossible regardless of how many times the quiz is run. **Live PASS 2026-04-26** (`docs/qa/runs/2026-04-26-discovery-retake-quit.md`): with anchors cleared as a shim, walked the full quiz with different answers; `count(*)=1` unchanged, `anchor_names` fully overwritten (As-Sabur/Al-Mujib/Al-Latif → Al-Wakil/Ar-Rabb/Al-Qayyum), originals restored from snapshot. UX gap to file with product: in shipping app, retake CTA only renders when `_anchorNames.isEmpty` — there is no user-visible Retake action once anchors exist. Add a "Retake quiz" affordance under Settings → Your Anchor Names, or strike the spec line from §8.

### 6. Reflect

- Input / loading / follow-up (slider + multi-choice) / result / off-topic states.
- Follow-up answers feed back into the final prompt.
- **Reflections auto-save on AI completion** — there is no explicit Save button. Every completed reflect appends a row to `public.user_reflections` and increments `public.user_daily_usage.reflect_uses`.
- Saved reflections render in **Journal tab** (not Home). Detail screen has Share + Delete in the header.
- Delete updates local + remote (`user_reflections` row removed).
- Token gate at `reflect_uses >= 3`: "Daily limit reached / Spend 50 tokens to continue" overlay; "Not now" dismisses without state change.
- Off-topic detection lives in `ai_service.dart` `isOffTopic()` (regex pre-filter + system-prompt fallback). On match, returns demo response + does NOT call `incrementReflectUsage()`.
- Context uses saved anchors and recent journal/check-in data.

Edge: AI failure does not consume free usage, off-topic does not consume free usage, very long input, duplicate tap while loading, share/export graceful failure.

### 7. Duas

- Browse list + favorite toggle.
- AI dua builder happy path persists output.
- Related duas save/unsave.
- Names-invoked tracking updates.
- Token gate after free limit.
- **Off-topic build does NOT consume free usage.** Off-topic is signaled by `BuiltDuaResponse.breakdown.isEmpty` (server-side filter or unparseable response). The same signal drives the off-topic UI (`duas_screen.dart _buildStepViewer`) and the `incrementBuiltDuaUsage()` gate in `duas_provider.dart submitBuild`. Test both stay in sync. Regression for `2026-04-26-build-dua-offtopic-counter`.
- **`resetBuild()` clears the input controller.** Try Again on the off-topic UI and Build Another Dua on the result screen both call `resetBuild()`, which wipes provider `buildNeed`. The UI listens via `ref.listen<DuasState>` and clears `_buildController` when buildNeed transitions non-empty → empty. Regression for `2026-04-26-build-dua-tryagain-no-clear`.

Edge: AI failure leaves state intact, off-topic doesn't consume usage, saved/built duas survive relaunch, cross-user cache isolation.
- **D-E5 double-tap on Build (live PASS 2026-04-26, fix upgraded mid-session)**: synchronous instance flag `_submitInFlight` at `lib/features/duas/providers/duas_provider.dart:422`, set BEFORE any `await` and cleared in `finally`. Both `submitBuild` (line 425) and `submitBuildWithToken` (line 441) check `if (_submitInFlight || state.buildLoading) return;`. **Original `state.buildLoading` guard alone was insufficient**: `buildLoading` is only set inside `_doBuild` AFTER the async `canBuildDuaFree()` check, so two synchronous taps both passed the check and both incremented the counter (sim-caught with `built_dua_uses=2`). Upgrade landed same session; sim re-verified `built_dua_uses=1` on rebuilt app. Unit tests in `test/features/duas/submit_build_reentry_guard_test.dart` (3/3 PASS): post-loading race, **pre-loading race** (the new test pinning the exact failure mode), and the token-spend path. Run log: `docs/qa/runs/2026-04-26-build-dua-de5-live.md`.
- **D-E2 AI failure mid-build**: `_doBuild` catch arm at `lib/features/duas/providers/duas_provider.dart:522-531` clears `buildLoading`, `buildResult`, `buildProgress`; sets `error = 'Something went wrong. Please try again.'`. **No** `incrementBuiltDuaUsage()` call (the consume only fires on `result.breakdown.isNotEmpty` after a successful `await`). Covered by unit test `test/features/duas/duas_provider_test.dart:203-220` (fake `buildDua` throws). Live sim verification not run this session — `xcrun simctl` lacks a reliable airplane-mode toggle (`status_bar` spoofs the icon only); the unit test deterministically exercises the catch path. Promote to live sim run if Network Link Conditioner integration becomes available.

### 8. Journal

- Empty state.
- Mixed saved content.
- Reflection and dua detail pages render correctly.
- **Delete confirmation dialog appears before destructive action** at all 5 entry points: reflection detail header, dua detail header, and the inline `_removeButton` on Journal list cards (3 callers: reflection / built dua / saved related dua). Cancel preserves the row, Delete removes it. Regression for `2026-04-26-journal-delete-no-confirm`. Backed by `confirm_delete_dialog.dart` shared helper — widget tests should assert the dialog appears, Cancel does NOT invoke `onRemove`, and Delete invokes `onRemove` exactly once.
- Delete removes only the tapped item.
- **J-E4 network failure mid-delete**: `ReflectNotifier.deleteReflection` (`lib/features/reflect/providers/reflect_provider.dart:411-431`) is now optimistic-with-rollback. Snapshots `previous` synchronously, mutates local list + `_persistReflections(updated)`, then calls `supabaseSyncService.deleteRow('user_reflections', 'id', id)` inside `try/catch`. On exception: restores `state.savedReflections = previous`, re-persists, surfaces `error = "Couldn't delete the reflection. Please try again."` for snackbar. `@visibleForTesting void debugSeedReflections(...)` added at `:437` to skip the load path in tests. Covered by 2 unit tests in `test/features/reflect/delete_reflection_network_failure_test.dart`: throwing fake `deleteRow` → list reverted + error set; happy-path fake → row removed + no error + exactly one `deleteRow` call. **Live sim mid-request airplane-mode toggle is not reliably triggerable** — `xcrun simctl status_bar` only spoofs the icon, real network drop needs Network Link Conditioner (manual). Unit tests are the strongest available signal. Known small polish item: catch arm uses `catch (_)` and does not log the exception type — add `debugPrint` for future telemetry.
- **J-E2 share/export from journal detail**: last live PASS in `docs/qa/findings/2026-04-26-share-export-pass.md` covers reflection share preview, personal dua share, reflect-result share, and native share-sheet cancel-no-crash. The share/export code path (`lib/widgets/share_card.dart`, journal detail pages) was not touched by D-E5 / J-E4 fixes; treat the prior PASS as authoritative until those files change.

Edge: long content truncates in list but shows full on detail, share failures surface safely.

### 9. Collection and card economy

- First discovered name unlocks.
- Existing name progresses through tiers.
- Tier-up scroll spend updates once.
- Grid + detail render correct tier visuals.
- Premium celebration overlay only after verified premium success.

Edge: duplicate engage calls produce one mutation, tier upgrade failure presented, share/export from ornate card works.

### 10. Quests, XP, titles, streaks

- First Steps quests progress on correct actions.
- Rewards granted once.
- XP level changes update title + UI.
- Streak milestones trigger at correct thresholds.
- Manual and auto title both persist.

Edge: multiple quest completions in one frame each grant once, broken streak → `current_streak` resets to 1 on next check-in, `longest_streak` preserved.

### 11. Settings and notifications

- Profile card renders `user_profiles.display_name` (not email twice). Falls back to `auth.userMetadata['full_name']` then email then `'Guest'`. Pure resolver `resolveProfileDisplayName` in `lib/features/settings/screens/settings_screen.dart` covered by `test/features/settings/resolve_profile_display_name_test.dart` (F1 fix landed 2026-04-26).
- Notification toggle reads server state.
- Toggle writes local + Supabase.
- Push opt-in/out updates delivery state.
- **Push enabled reconciles with iOS perm (F2 fix 2026-04-26)**: when `getNotificationPreferences` finds `push_enabled=true` on the server but `OneSignal.Notifications.permission == false` locally, the client writes `push_enabled=false` back. Stops the cron from dispatching ghost pushes after OS-level permission revocation. Tests in `test/services/notification_service_test.dart` cover both branches.
- **Option B verified_at stamping (2026-04-26)**: client stamps `push_enabled_last_verified_at = now()` from `optIn()` on success and from `getNotificationPreferences` when push is enabled and iOS perm is granted. Cron RPC `get_eligible_notification_users` requires the stamp to be within 7 days. Schema migration `add_push_enabled_last_verified_at_with_cron_filter` applied + 4 unit tests.
- Sign-out clears scoped SharedPrefs (F3 fix 2026-04-26). `AuthService.signOut` calls `clearScopedPreferencesForUser(prefs, uid)`; covered by `test/services/auth_service_signout_clear_prefs_test.dart`.
- Timezone sync runs after auth.
- Reset daily loop + clear collection confirmations work.
- Delete account requires explicit type-DELETE confirmation (2-step dialog: warning + type-confirm; button stays disabled until trimmed input equals `DELETE`). Dialog helpers extracted to `lib/features/settings/widgets/delete_account_dialogs.dart` with 8 widget tests covering both Cancel paths, button-enable gating, and trim behavior.

Edge: Supabase unavailable during toggle, notification tap routes to correct screen (verified 2026-04-26 for daily/streak/weekly/reengagement), foreground notification does not crash current screen.

### 12. Share and export

- Reflect, built-dua, and journal detail share previews export a card image.
- Cards render correct verse count, text, branding.
- **Export failure surfaces a user-facing snackbar, not a silent `debugPrint` (F6 fix 2026-04-26).** `_share()` in `lib/widgets/share_card.dart:210-218` catches export errors and calls `ScaffoldMessenger.of(context).showSnackBar(...)` with "Couldn't share that — please try again."; `finally` removes the overlay and resets `_exporting`. The widget builds inside a `Scaffold` (`_SharePreviewScreen.build`, line 227) so `ScaffoldMessenger.of` is always safe.

Edge: native share cancel, long content still fits core card content.

### 13. Public catalog and RLS

- Bundled snapshots bootstrap correctly.
- Remote public catalog refresh validates shape before overwrite.
- Batch RPC hydrates all user caches.
- User-owned data respects RLS — one user cannot read another's reflections, history, rewards, or discovery results.

### 14. Edge functions and SQL

Automated coverage:
- `flutter/supabase/tests/rpc_eligibility_test.sql` (pgTAP, runs via `supabase test db`) — scheduled notification eligibility + dedup windows.
- `flutter/supabase/tests/backend_rls_test.sql` (plain SQL, runs via `mcp__supabase__execute_sql` — no CLI/pgTAP needed) — 47 assertions covering `sync_all_user_data` payload contract + auth gate, `delete_own_account` FK cascade across 18 scoped tables, `grant_premium_monthly` (grant / idempotent / non-premium / unauth + token+scroll deltas), public catalog anon read, cross-user RLS, and the RLS-on + has-policy audit.
- `flutter/supabase/functions/revenuecat-webhook/index.test.ts` (Deno, `deno test --no-check`) — 14 cases including 401/405/400, anonymous + non-premium skip, INITIAL_PURCHASE upsert, alias-fallback user resolution, CANCELLATION + BILLING_ISSUE access semantics, EXPIRATION inactive, stale-event rejection, RPC throw → 500, plus a regression guard for the EXPIRATION→`canceled_at` clobber (P3 in `docs/qa/findings/2026-04-26-backend-rls-pass.md` — flip the assertion when the upsert is fixed to coalesce missing keys).

Latest live verification: 2026-04-26 — see `docs/qa/findings/2026-04-26-backend-rls-pass.md`. All 47 SQL assertions and 14 Deno tests green.

Targets:
- Scheduled notification eligibility for daily, streak, re-engagement, weekly.
- **`push_enabled_last_verified_at` 7-day freshness filter (Option B, added 2026-04-26)**: the cron RPC requires the stamp to be non-null AND newer than `now() - interval '7 days'`. Catches `push_enabled=true` rows that drifted without recent client-side reverification. Verified end-to-end 2026-04-26: aging the column to 8 days excludes the user even when all other gates pass; restoring to `now()` makes them eligible again. Tracked in `docs/qa/findings/2026-04-26-push-cron-defense-in-depth-followup.md`.
- Deduplication windows work — daily / streak / weekly use `last_*_sent_at` per-day comparison in user's local timezone; reengagement uses 7-day dedup. Verified 2026-04-26 (sent_today=ineligible, sent_yesterday=eligible, never_sent=eligible for daily).
- Partial OneSignal send failure tolerated.
- `delete_own_account` removes dependent data (FK CASCADE-only — schema relies entirely on cascade).
- `sync_all_user_data()` returns complete, stable payloads with the documented 11-key contract: `xp, tokens, streak, daily_rewards, profile, built_duas, reflections, achievements, card_collection, checkin_history, discovery_results`.
- `revenuecat-webhook` rejects unauthorized requests (401) and non-POST (405).
- Webhook resolves stable user id via alias / `original_app_user_id` fallback.
- Initial purchase, cancellation, billing issue, expiration events persist correct `public.user_subscriptions` state. Cancellation history (`canceled_at`) is preserved through EXPIRATION (key-presence-aware upsert in migration `20260426000000_preserve_canceled_at_on_absent_key.sql`).
- `grant_premium_monthly()` grants only to active premium users, only once per month (keyed on `user_daily_rewards.last_premium_grant_month`), rejects non-premium callers, raises on unauthenticated.

## Automated gate before shipping

On every PR:

```bash
flutter analyze
flutter test
```

Plus a fresh-checkout build (manual-test-plan §18) on any PR that touches
`pubspec.yaml`, `.env*`, or `lib/main.dart` dotenv loading:

```bash
DEST=/tmp/sakina-fresh-$(date +%Y%m%d-%H%M%S)
git clone <repo> "$DEST" && cd "$DEST/flutter"
flutter pub get
flutter build web --debug   # must NOT fail with "No file or variants found for asset: .env"
```

Last verified 2026-04-26 against HEAD `3fc53d0` — see `docs/manual-test-plan.md` §18 for the full runbook and the regression that drove this gate (the `.env`-as-gitignored-but-listed-as-asset bug).

Focused E2E smoke coverage:
- Welcome → onboarding → Home.
- Home → daily loop → reveal.
- Reflect submit → save → Journal.
- Onboarding paywall → purchase or restore → Home.
- Discovery quiz → anchors saved.
- Settings → notification toggles → sign out.

## Manual regression before release

See `manual-test-plan.md` for full on-device steps, DB assertions, and MCP calls. Minimum pass on iOS simulator + one physical device:

- New user onboarding.
- Returning user login.
- Daily loop.
- Reflect.
- Dua builder.
- Discovery quiz.
- Journal review + delete.
- Settings notification toggles.
- Account deletion.

When premium is enabled, also: purchase, restore, relaunch with entitlement, monthly premium grant, webhook-driven subscription refresh.

### Daily-loop edge cases — last verified 2026-04-26

Run log: `docs/qa/runs/2026-04-26-daily-loop-edges.md`. Coverage on iPhone 17 sim against `qa20260426@sakinaqa.test`:

- B1 (double-tap final answer): **OBSOLETE_BY_DESIGN**. UI removed; latent guard added to `answerCheckin` and pinned by `test/features/daily/answer_checkin_reentry_guard_test.dart` (2 tests).
- B3 (background during AI loading): **OBSOLETE_BY_DESIGN**. `discoverName` has no AI call.
- B4 (midnight boundary): **PASS**. Server + plist forced to yesterday → cold-launch re-shows overlay → completion → streak +1, `last_active`/`last_claim_date` advance to today, +1 history row.
- B6 (streak freeze auto-consume): **PASS**. Seeded `streak_freeze_owned=true` + 2-day gap → post-muhasabah, freeze=false, streak=pre+1 (NOT reset to 1).

Mechanism notes (apply to future date-driven runs):

- Use Python `plistlib` to mutate scoped SharedPrefs keys with `:` in them (`plutil -remove` mishandles colon-containing keys). Always `xcrun simctl terminate booted <bundle>` before plist surgery.
- `user_daily_rewards.last_claim_date` is `date`, not text — write `current_date - 1`, no `::text` cast.
- After rebuild, `xcrun simctl get_app_container booted <bundle> data` returns a new container UUID; re-resolve before each plist edit.
