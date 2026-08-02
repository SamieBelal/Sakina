# Core Loop Bug Fix Plan — 2026-04-22

> ## Status (verified 2026-04-26)
>
> | Finding | Severity | Code change | Live verified | Tests | Status |
> |---|---|---|---|---|---|
> | F9 off-topic classifier | P1 | partial — regex pre-filter (#3) added; system-prompt rules tightening (#1,#2) and classifier logging (#4) deferred | ✅ "best pizza recipe" → off-topic demo path, no counter burn | covered by live MCP run (no unit test) | **FUNCTIONALLY PASS, hardening deferred** |
> | F3 gacha eager-dismiss | P0 | reclassified — outer GestureDetector phase gate raised from `>= 2` to `>= 3` (Continue button's own GD already existed; CLAUDE.md note was stale) | ✅ phase-2 tap now absorbed; phase-3 single-tap on Continue advances | n/a | **DONE** |
> | F1/F5 SharedPrefs cache | P1 | new `reconcileDailyRewardsFromServer()` called from `shouldShowDailyLaunch()` + provider `reload()`; resets local launch gate only when local↔server conflict (avoids regression on dismissed-without-claim case) | ✅ wipe `user_daily_rewards` server-side → cold-launch → overlay reappears | ✅ launch_gate_service_test (3 tests) all pass | **DONE — items #2 (`/__debug/reset-local` route) and #3 (server-aware Settings reset) deferred** |
> | F2 fresh-today muhasabah | P2 | reclassified — intentional design (`muhasabah_screen.dart:173-178` explicitly auto-triggers `discoverName()` to skip questions). Documented in CLAUDE.md + manual-test-plan.md §5 | n/a | n/a | **DONE (docs)** |
> | F4 token pill stale | P3 | `ref.invalidate(dailyLoopProvider, tierUpScrollProvider, dailyRewardsProvider)` on Return to Home tap in muhasabah_screen.dart | ✅ Home pill = DB (1137 = 1137) immediately after loop, no relaunch | n/a | **DONE** |
> | F6 activity_log silent | P1 | `await logActivity()` added to `_markStreakAndHandleMilestones` in daily_loop_provider.dart | ✅ `user_activity_log` count today: 0 → 1 after muhasabah | n/a | **DONE** |
> | F7 daily quest not progressed | P1 | reclassified — daily quests rotate 3-of-9 per day; "Complete a Muhasabah" wasn't in today's rotation, so `_tryComplete` no-op was correct. Logged in run-log | n/a | n/a | **DONE (clarified)** |
> | F8 manual save docs | P3 | manual-test-plan.md §6 + testing-plan.md §6 updated to describe auto-save and Journal-only share | n/a | n/a | **DONE — items #3 (remove D4) and #4 (toast UX) deferred** |
> | Schema drift docs | P2 | manual-test-plan.md swept for table/column names (8 places). Migration banner + auto-gen-from-list_tables deferred | n/a | n/a | **DONE — process improvements deferred** |
>
> **Test suite:** 331/331 passing. 1 regression I introduced (`launch_gate_service_test.dart`) caught + fixed during F1/F5; 3 pre-existing failures from prior commit `543fdfe` (stale `_FakeAuthService` mocks + age-range analytics expectation) also fixed during this verification pass.
>
> **Blocked tests follow-up:**
> - **B1** double-tap submit: now reachable via DailyLaunchOverlay path (which calls `answerCheckin` with the 4-question flow). Not yet exercised.
> - **B3** background during AI: still no MCP primitive — needs an `xcrun simctl` wrapper or AppleScript ⌘H.
> - **B4** midnight boundary, **B6** freeze: now testable thanks to F1/F5 fix (server-side `last_claim_date = (current_date - 1)` + cold-launch should drive the overlay through the missed-day path). Not yet re-run.
> - **B7** premium multiplier: still requires physical device.
> - **D2** AI failure: still requires network intercept.
>
> **Files changed in this fix wave:**
> - `lib/features/daily/widgets/name_reveal_overlay.dart` (F3)
> - `lib/features/daily/screens/muhasabah_screen.dart` (F4)
> - `lib/features/daily/providers/daily_loop_provider.dart` (F6)
> - `lib/features/daily/providers/daily_rewards_provider.dart` (F1/F5)
> - `lib/services/daily_rewards_service.dart` (F1/F5)
> - `lib/services/launch_gate_service.dart` (F1/F5)
> - `lib/services/ai_service.dart` (F9)
> - `CLAUDE.md` (F2 docs + F3 stale-bug-note correction)
> - `docs/manual-test-plan.md` (F8 + schema drift + F2 docs)
> - `docs/testing-plan.md` (F8)
> - `test/features/onboarding/completion_integration_test.dart` (pre-existing test fix)
> - `test/services/auth_service_onboarding_persist_test.dart` (pre-existing test fix)
> - `test/features/onboarding/screens/age_range_screen_test.dart` (pre-existing test fix)
> - `pubspec.yaml` — LOCAL ONLY, must be reverted before commit
>
> The original plan below is unchanged for historical reference.
>
> ---


Source run: `docs/qa/runs/2026-04-22-core-loop.md`. Account under test: `verify20260422b@sakinaqa.test` (uid `a55cc84f-c916-496f-8623-ef24cc89eca4`). Sim: iPhone 17 UDID `E1152EC8-6A80-4966-92D9-7D7425A81CD2`.

Each bug has: **severity**, **root-cause pointer**, **proposed fix**, **MCP verification steps**.

Severities: **P0** ships-blocker, **P1** fix before next release, **P2** fix next sprint, **P3** backlog.

---

## F9 — Off-topic classifier too lenient [P1]

**Symptom:** "best pizza recipe for a dinner party tonight" routed through full Reflect AI flow → Ar-Razzaq (The Provider) with verses + dua. `user_daily_usage.reflect_uses` incremented (1 → 2). No off-topic-detection gate fired.

**Blast radius:** Every off-topic prompt charges a free reflect slot. At scale, this is (a) wasted OpenAI cost on recipe/weather/code queries, (b) broken free-tier fairness, (c) potential abuse vector (scrape the AI via free reflects), (d) dilutes the product's positioning as a spiritual wellness tool.

**Root cause:** per `reflect_provider.dart`, the off-topic branch is driven by `response.offTopic` returned by the model. The model's system prompt apparently allows the AI to find any tangential spiritual angle rather than refusing. Model: `gpt-4o-mini` per CLAUDE.md.

**Fix:**
1. Tighten the system prompt. Add explicit examples of rejection:
   - `{"input":"pizza recipe","offTopic":true,"reason":"practical task, not emotional state"}`
   - `{"input":"python code help","offTopic":true}`
   - `{"input":"what's the weather","offTopic":true}`
   - Also add positive examples (feelings, emotions, life struggles).
2. Require the model to return `offTopic:true` unless the input contains at least one of: a first-person emotion verb, a struggle description, a question about meaning/purpose, or a specific life event (illness, loss, relationship, work stress, spiritual doubt).
3. Add a pre-filter (cheap): run a small keyword classifier client-side before the API call. Block obvious non-emotional queries locally. Saves latency and cost when the pre-filter is confident.
4. Log every off-topic decision to Supabase for dataset review (new table `reflect_classifier_log(user_id, user_text, off_topic, model_reason, created_at)` with short TTL).

**Verification (MCP):**
```
Given: user_daily_usage.reflect_uses = 0
When:  sim types "best pizza recipe for a dinner party tonight" and taps Reflect
Then:  off-topic response UI shown
       user_daily_usage.reflect_uses still 0 (no counter burn)
       no row inserted into user_reflections
       classifier_log shows off_topic=true, model_reason set
```
Repeat with 10 off-topic seeds + 10 on-topic seeds (assert 100% precision on off-topic, acceptable recall on on-topic — tune threshold).

---

## F3 — Gacha Continue button has no GestureDetector [P0]

**Symptom:** First tap on the "Continue" pill inside NameRevealOverlay is a no-op. Second tap anywhere on the overlay dismisses (because the parent overlay has an `onTap`). This means new users' very first daily reward collection feels broken.

**Root cause:** `lib/features/daily/widgets/name_reveal_overlay.dart` — Continue button is a plain `Container` relying on the parent overlay tap handler. Already documented in CLAUDE.md as a known bug.

**Fix:** wrap Continue in a `GestureDetector`:
```dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: _handleContinue,
  child: Container(/* existing */),
)
```
Also audit the overlay for a `Stack` where the button sits under a transparent region — verify `HitTestBehavior` on the outer `GestureDetector` so the bubbling still works for background dismiss if that's intended, OR remove the parent tap handler entirely to avoid the accidental-dismiss pattern.

**Verification (MCP):**
```
Seed: user_daily_rewards cleared + Settings › Reset Daily Loop to wipe SharedPrefs
When: trigger the overlay (tap Begin Muḥāsabah on fresh state)
      ui_tap once at Continue button logical center (201, 773)
Then: overlay dismisses (next screen visible)
      single tap sufficient (describe_all shows new screen, not overlay)
      user_card_collection: exactly 1 new row (not 0, not 2)
      user_tokens.balance incremented exactly once
```
Regression suite should also cover the "double-tap" case: two rapid taps must not yield two card grants.

---

## F1/F5 — Daily overlay + claim state cached in SharedPreferences [P1]

**Symptom:** Resetting `user_daily_rewards.last_claim_date = null, current_day = 0` on the server then cold-launching does NOT re-trigger the DailyLaunchOverlay. The app reads local `DailyRewardsState.claimedToday` first. Bottom banner on Home still shows "Day 1/7 claimed" while DB disagrees. Freeze-consume path (B6) unreachable without SharedPrefs wipe.

**Blast radius:** QA can't exercise the freeze/midnight/multi-device-double-claim paths via DB manipulation. Also any cross-device session where Device A claims and Device B is offline — Device B can show stale "claimed" state and block legit re-claim on server-truth.

**Root cause:** `daily_rewards_service.dart:303` does `if (userId != null) { fetchRow(...) }` BEFORE reading local state, but the overlay gate itself reads only local. Initializer hydrates SharedPrefs from the last known server row but on-relaunch we trust the cache.

**Fix (three changes):**
1. **Cache invalidation on mount.** Daily overlay's Riverpod provider should call a `hydrateFromServer()` on app-resumed-cold. Currently only the manual claim path hits the server. Force a server read if `lastHydratedAt` is older than the current calendar day.
2. **Debug-only test hook.** Add a route `/__debug/reset-local` behind a build flag (`--dart-define=QA=true`) that wipes `user_daily_rewards_*` and `daily_usage_*` SharedPrefs keys and restarts the provider. Keeps production binary clean.
3. **Ship the existing Settings › Reset Daily Loop hook to be server-aware.** It currently calls `dailyLoopProvider.notifier.resetToday()` which wipes local; it should also null out the DB row OR explicitly trigger re-hydrate-from-server.

**Verification (MCP):**
```
Given: SQL update user_daily_rewards set last_claim_date=null, current_day=0 where user_id='<uid>'
When:  launch_app terminate_running=true
Then:  DailyLaunchOverlay appears (ui_describe_all shows "1 day streak" heading OR reward-claim step)
       tap Begin Muḥāsabah → gacha → rewards
       user_daily_rewards.last_claim_date = current_date (DB was written)
       user_daily_rewards.current_day = 1
```

Plus a debug-hook test:
```
Call: POST to /__debug/reset-local (or invoke from Settings)
Then: launch_app returns to expected overlay state
      SharedPrefs daily_* keys absent (verify via xcrun simctl get_app_container data + plutil)
```

---

## F2 — Fresh-today state skips multi-question muhasabah [P2]

**Symptom:** First check-in after server reset wrote `user_checkin_history` row with `q1="discover", q2="", q3="", q4=null`. The 3-question muhasabah sequence documented in the plan (and implied by `muhasabah_screen.dart`) never appeared. Instead the user saw: Gacha → Reflection preview → AI result → Story → Dua → Complete.

**Blast radius:** Intended daily-reflection data collection is incomplete. If the business logic expects q1/q2/q3 answers for downstream personalization, every fresh user generates empty records. Also the "reward comes from reflection" mental model is broken — the reward appears BEFORE the reflection.

**Root cause:** Not confirmed by code read yet. Hypothesis: `daily_loop_provider.dart:461-620` branches on `current_streak === 0` or on whether `daily_questions` has been served to this user before. On first ever check-in with streak=0 and no prior answers, it fast-paths to the reward + auto-reflection path and sets `q1="discover"` as a default sentinel.

**Fix:**
1. Read `daily_loop_provider.dart` answerCheckin function and find the branch that produces `q1="discover"`. Confirm whether this is intended "first-time new-user experience" or a bug.
2. If intended: document it in CLAUDE.md and update `docs/manual-test-plan.md` §5 to note the branch. Add a test case for returning-user flow (`current_streak > 0`) that DOES walk questions.
3. If unintended: always run the question sequence. Default q1 for fresh users can be `daily_questions.random_order_by_id LIMIT 1`, not a sentinel string.

**Verification (MCP):**
```
Pre-reset: 
  update user_streaks set current_streak = 5, last_active = (current_date - 1)::date where user_id = '<uid>';
  delete from user_checkin_history where user_id = '<uid>' and checked_in_at::date = current_date;
  (plus Settings › Reset Daily Loop to wipe local)
When:  cold launch → tap Begin Muḥāsabah
Then:  observes the 3-question sequence (q1/q2/q3 prompts visible)
       user_checkin_history row has non-empty q1, q2, q3 after completion
```

---

## F4 — Token pill UI stale after check-in [P3]

**Symptom:** Immediately after completing A, Home token pill showed 1004 while DB showed 1059. Cold relaunch fixed it — so it's a refresh-timing issue, not persistent drift.

**Root cause:** Home token pill reads from `user_tokens` provider that isn't invalidated when muhasabah completes. Reward-claim code paths update token balance server-side but don't `ref.invalidate(userTokensProvider)` on return-to-home.

**Fix:** in the navigation return path from muhasabah-complete screen, call `ref.invalidate(userTokensProvider)` (and `userXpProvider`, `userStreaksProvider`, `userCardCollectionProvider`) before popping. Or use Riverpod listeners on the reward-granted event.

**Verification:**
```
When: complete daily loop via sim taps, return to Home
Then: ui_describe_all shows token pill value = DB value (no 20-second stale cache)
```
Regression: take two screenshots back-to-back without cold relaunch and diff token values — should match DB immediately.

---

## F6/F7 — user_activity_log and user_quest_progress not wired for check-ins [P1]

**Symptom:** After a full muhasabah completion: `user_activity_log` has 0 rows for today, `user_quest_progress where cadence='daily' and period_start=current_date` has 0 rows. Yet the Home "Quests" card was visible and streak incremented to 1.

**Blast radius:** If analytics or retention reports count activity-log rows, they undercount. Daily quest rewards cannot be claimed because nothing ever increments the progress. New users never see quest progress advance from check-ins, only from other actions.

**Root cause:** Likely missing `insertActivityLog()` and `incrementDailyQuest()` calls in the muhasabah-completion path (daily_loop_provider.dart after `saveCheckinRecord`). Service layer may have those functions but they're not invoked from the daily loop.

**Fix:**
1. Add activity-log insert in the completion handler: `insert into user_activity_log (user_id, active_date) values (auth.uid(), current_date) on conflict do nothing;`
2. For each daily quest that matches "daily check-in" criteria, call `incrementQuestProgress(quest_id)`. Define which quest ids qualify (most likely `first_checkin`, `daily_checkin_streak_*`).

**Verification:**
```
Pre: counts=0 for both tables today
When: complete daily loop via sim
Then: user_activity_log count for today = 1
      user_quest_progress has >= 1 row with cadence='daily', period_start=current_date, progress > 0
      relevant quest(s) show progress in Quests tab UI
```

---

## F8 — No manual Save affordance on reflect result [P3 / documentation]

**Symptom:** Plan/docs describe a user-taps-Save step. Reality: reflect result auto-saves the moment AI completes. No Save button exists anywhere in the Reflect flow.

**Blast radius:** None technically — auto-save is actually nicer UX — but documentation divergence confused the plan author (me) and will confuse future QA/onboarding.

**Fix:**
1. Update `docs/manual-test-plan.md` §6 to reflect auto-save behavior.
2. Update `docs/testing-plan.md` §6 likewise.
3. Remove D4 "save-limit gate" test case (there is no limit because nothing is manually saved; counter is at the daily free-reflect level, already covered by D3).
4. Consider adding a visible "Saved to Journal ✓" confirmation toast post-AI so users know it's stored.

**Verification:** documentation PR review. No MCP needed.

---

## Schema drift between manual-test-plan.md and actual DB [P2 / documentation]

**Tables:** `user_checkin_history` (not `checkin_history`), `user_card_collection` (not `user_cards`), `user_quest_progress` (not `user_quests`), `user_xp(total_xp)` (not `xp.current_xp`/level), `user_tokens` (not `tokens`), `user_streaks.last_active` (not `last_checkin_date`), `user_daily_rewards.streak_freeze_owned` boolean (not `streaks.freezes_available` int), `user_daily_usage` (not `daily_usage`).

**Fix:** single sweep through `docs/manual-test-plan.md` replacing every stale name. Add `supabase/migrations/` version banner at top of the doc. Consider generating this doc section from `mcp__supabase__list_tables` output for future accuracy.

---

## Blocked tests — infrastructure work required

| Test | Blocker | Needed to unblock |
|---|---|---|
| B1 double-tap submit | Multi-question muhasabah flow not reached (F2) | Fix F2 first |
| B3 background during AI | ios-simulator MCP has no home-button primitive | Either (a) use `xcrun simctl spawn <UDID> notifyutil -p "com.apple.SpringBoard.exitbackground"` via Bash, (b) use AppleScript to invoke ⌘H on Simulator.app, or (c) accept as manual-only test |
| B4 midnight boundary | Same SharedPrefs gating as F1 | Fix F1 |
| B6 streak freeze consume | Same SharedPrefs gating as F1 | Fix F1 |
| B7 premium multiplier | Platform: RevenueCat sandbox unavailable on iOS sim | Run on physical device; skip in sim-only QA runs |
| D2 AI failure | No MCP for network conditions | Options: (a) set sim to airplane mode via `xcrun simctl bash`, (b) use a local MITM proxy on the dev machine and reject OpenAI domain, (c) injection-test via app-level flag like `FLUTTER_FLAVOR=reject_ai` |

---

## Execution order for fixes

1. **P0:** F3 (gacha Continue) — single-file change, high user impact, low risk.
2. **P1 block:** F9 (off-topic), F1/F5 (cache), F6/F7 (activity log). These three together cover the biggest product health / QA-tooling / cost issues.
3. **P2 block:** F2 (muhasabah branch behavior), schema drift doc sweep.
4. **P3:** F4 (token pill refresh), F8 (doc-only).
5. **Infra:** pick ONE of {xcrun simctl wrapper script, proxy-based network control} to unblock B3/D2 for future runs.

Each fix is small enough to ship as its own PR. Suggest bundling F1/F5 with the debug reset hook since they share the SharedPrefs concern.

---

## Verification harness (one-shot script)

Propose a `docs/qa/runs/_verify.sh` that wraps the common MCP calls:

```bash
# usage: _verify.sh <test-id>
# examples: _verify.sh F3   # runs the F3 regression via sim MCP + Supabase MCP
```

Too much to write inline here; skeleton would:
1. Reset test account to known state (SQL + Settings reset)
2. `launch_app terminate_running=true`
3. Dismiss the iOS notifications dialog
4. Drive through the test via `ui_tap` sequence (coords from `docs/qa/ui-map.md`)
5. Query DB for expected rows
6. Exit 0 on pass, 1 with diff on fail

This is future work — not this PR. But it's what makes these fixes re-verifiable without re-driving everything by hand.
