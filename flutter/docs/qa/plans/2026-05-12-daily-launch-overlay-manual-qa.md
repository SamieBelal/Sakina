# Daily Launch Overlay — Manual QA Verification (2026-05-12)

Run this manually against a physical iOS device OR the simulator via
`mcp__ios-simulator__*` tools. Each scenario reproduces a user-reported
symptom and asserts the post-fix behavior.

## Setup

1. Test account: `yoyoyo@gmail.com` (or a fresh disposable account).
2. Reset server state via SQL:
   ```sql
   update public.user_daily_rewards
   set current_day = 0, last_claim_date = null, streak_freeze_owned = false
   where user_id = '<uid>';
   ```
3. Boot iOS simulator: `mcp__ios-simulator__open_simulator`,
   `mcp__ios-simulator__get_booted_sim_id`.

## Scenario A — Same-day reinstall, already claimed

**Repro of:** "It constantly shows up even if I already have claimed the reward
for that day, usually when I delete and then reinstall."

1. Build + install the app: `flutter run --dart-define-from-file=env.json`.
2. Sign in, complete onboarding, claim today's reward (Day 1).
3. `mcp__ios-simulator__ui_tap` Home button, force-close the app.
4. Uninstall: `xcrun simctl uninstall <sim_id> com.sakina.app`.
5. Reinstall + relaunch: `mcp__ios-simulator__install_app` then
   `mcp__ios-simulator__launch_app`.
6. Sign in. Wait for hydration.

**Expected (post-fix):** No "Daily Reward" overlay appears. Home screen renders directly.

**Take screenshot:** `mcp__ios-simulator__screenshot` — attach to QA log.

## Scenario B — Day shown matches day claimed

**Repro of:** "It showed Day 2 but I claimed the reward of Day 4."

1. Reset server: `current_day = 2`, `last_claim_date = <UTC yesterday>`.
2. Wipe local: uninstall + reinstall the app.
3. Sign in. When the overlay appears, tap "Begin".
4. On the rewards screen, **before tapping Claim**, take a screenshot
   showing the highlighted day chip and the "Day N reward" string.
5. Tap Claim. Observe the "Reward Claimed!" success card.

**Expected (post-fix):** Pre-claim screen highlights **Day 3** and reads
"Day 3 reward". Post-claim success card and "Come back tomorrow for Day 4"
both reference Day 3 / Day 4 — never Day 1 / Day 2.

## Scenario C — UTC midnight cross-over

**Repro of:** "Overlay re-fires the morning after I claimed late at night."

1. Set the simulator clock manually to a local time where local date and
   UTC date disagree. Simulator > Features > Time > Custom: set device to
   `2026-05-12 23:30` in a UTC-5 timezone (so UTC is already `2026-05-13`).
   (Note: modern simulators may not expose a custom clock UI. If unavailable,
   use a wrapper that calls `xcrun simctl spawn <sim_id> date <yyyymmddhhmm>` —
   or skip this scenario and rely on the unit test in
   `test/services/launch_gate_state_utc_test.dart` which pins the UTC behavior
   deterministically.)
2. Open app. Claim today's reward.
3. Force-close.
4. Advance the simulator clock to `2026-05-13 00:15` local (UTC `2026-05-13
   05:15` — same UTC day).
5. Cold-launch the app.

**Expected (post-fix):** No overlay re-fires — marker was stored as UTC
`2026-05-13`, today's marker is still UTC `2026-05-13`, gate skips. Take a
screenshot of the home screen on first paint.

## Sign-off checklist

- [ ] Scenario A — no overlay on same-day reinstall after claim
- [ ] Scenario B — pre-claim Day == post-claim Day == server day
- [ ] Scenario C — no re-fire across local midnight when same UTC day

Attach screenshots and the timestamps of each step to
`docs/qa/runs/2026-05-12-daily-launch-overlay-manual-qa.md`.
