# Daily-loop edge cases QA — 2026-04-26

Covers manual-test-plan §5 edge cases B1, B3, B4, B6. Plan source: tightened plan-eng-review with three accepted recommendations (Q1=widget-test, Q2=AppleScript, Q3=plutil; widget test was downgraded mid-execution to a code finding due to a DI blocker — see B1 below).

## Subject

- Sim: iPhone 17, UDID `E1152EC8-6A80-4966-92D9-7D7425A81CD2`
- App build: Sakina 1.0.0+2 (`com.sakina.app.sakina`)
- Test user: `qa20260426@sakinaqa.test` / uid `327f07b0-ef49-48b4-b93d-af9ee287560f`
- App data dir: `/Users/.../B01ECE49-0F99-485E-8BC6-C3884B8CB12E/Library/Preferences/com.sakina.app.sakina.plist`

## Phase results

| # | Case | Result | Notes |
|---|---|---|---|
| 0 | Pre-flight | PASS | Sim booted, plist resolved, password reset for qa user, sign-in OK. |
| 1 | B1 — double-tap final answer | **OBSOLETE_BY_DESIGN** | The multi-question check-in flow has been removed from the launch overlay (`_step` never reaches 2). `_CheckInStep` widget is dead code. The race in `answerCheckin` is real but unreachable from production UI. Filed as finding — see Findings F1. |
| 2 | B3 — background during AI loading | **OBSOLETE_BY_DESIGN** | Same root cause as B1. Production muhasabah is `discoverName()` which has no AI call → no meaningful loading window to background. Filed as plan-update finding F2. |
| 3 | B4 — midnight boundary | **PASS** | Forced last_claim_date and last_active to yesterday on both server + scoped SharedPrefs. Cold-launch → DailyLaunchOverlay re-appeared with streak=8. Completed full flow (Begin → Claim → Continue → Begin Muḥāsabah → gacha → Continue). Post-state: streak 8→9, last_active yesterday→today, last_claim D1→D2, +1 history row. No duplicate state. |
| 4 | B6 — streak freeze auto-consume | **PASS** | Seeded freeze=true + last_claim=2 days ago + last_active=2 days ago + current_streak=9. Cold-launch → claim ran (calendar reset to Day 1, freeze still owned at this point — claim path does not consume). Begin Muḥāsabah → discoverName → `_markStreakAndHandleMilestones` → `markActiveToday` consumed the freeze via `consume_streak_freeze` RPC. Post-state: streak=10 (+1, NOT reset to 1), freeze=false, last_active=today. |
| 5 | Run log + findings | DONE | This file + 2 findings + plan/test-plan updates. |

## Pre/post state captures

### B4 (midnight boundary)

| Field | Pre | Post | Expected |
|---|---|---|---|
| `user_streaks.current_streak` | 8 | 9 | pre+1 ✓ |
| `user_streaks.last_active` | 2026-04-25 | 2026-04-26 | today ✓ |
| `user_daily_rewards.last_claim_date` | 2026-04-25 | 2026-04-26 | today ✓ |
| `user_daily_rewards.current_day` | 1 | 2 | next pip ✓ |
| `user_checkin_history` (today) | 0 rows | 1 row | +1 ✓ |

### B6 (freeze auto-consume)

| Field | Pre | Post | Expected |
|---|---|---|---|
| `user_streaks.current_streak` | 9 | 10 | pre+1, NOT reset to 1 ✓ |
| `user_streaks.last_active` | 2026-04-24 | 2026-04-26 | today ✓ |
| `user_daily_rewards.streak_freeze_owned` | true | **false** | consumed ✓ |
| `user_daily_rewards.last_claim_date` | 2026-04-24 | 2026-04-26 | today ✓ |
| `user_daily_rewards.current_day` | 8 | 1 | calendar reset (>1 day gap) — expected behavior |
| `user_checkin_history` (today) | 0 rows | 1 row | +1 ✓ |

## Mechanism notes (carry to ui-map.md / future runs)

- **plist colon-key edits**: `plutil -remove flutter.foo:UID` does NOT work — plutil treats `:` as a key-path separator, mangling the actual scoped-key. Use Python `plistlib`:
  ```python
  import plistlib, json
  with open(path,'rb') as f: d = plistlib.load(f)
  del d['flutter.sakina_launch_gate:UID']
  with open(path,'wb') as f: plistlib.dump(d, f)
  ```
- **Always terminate the app before plist surgery** (`xcrun simctl terminate booted com.sakina.app.sakina`) — iOS may overwrite mid-edit.
- **Local SharedPrefs override server**: the app hydrates from cache first. Server-side seeding alone is insufficient — must also rewrite `flutter.sakina_daily_rewards:<uid>`, `flutter.sakina_last_active:<uid>`, `flutter.sakina_current_streak:<uid>`, and clear `flutter.sakina_launch_gate:<uid>` for date-based flows. Also wipe today's entries from `flutter.sakina_checkin_history:<uid>` to avoid duplicate-day collisions.
- **`last_claim_date` is a `date` column, not text** — manual-test-plan §5 (line 248) had `(current_date - 1)::text` which fails with `column "last_claim_date" is of type date but expression is of type text`. Drop the cast.
- **B6 freeze trigger**: not in `claimDailyReward()` — that path leaves freeze owned. Freeze is consumed in `streak_service.dart:272` (`markActiveToday()`) which is called from `_markStreakAndHandleMilestones` after the muhasabah completes. Manual-test-plan §5 implied claim consumes it; this is wrong — the claim-time freeze path in `daily_rewards_service.dart` is reachable but only when `lastClaimDate != yesterday AND >1 day gap`. The streak-time path fires regardless and is the actual primary consumer.
- **Notification permission system dialog** appears on every fresh app launch when iOS perms are denied. Cancel dismisses, AppleScript is unnecessary — there is a Cancel button at logical (127, 511).

## Findings filed

| ID | Severity | Title | File |
|---|---|---|---|
| F1 (B1) | P1 (latent) | `answerCheckin` has no re-entry guard; race fires duplicate `user_checkin_history` rows under concurrent invocation | docs/qa/findings/2026-04-26-answercheckin-no-reentry-guard.md |
| F2 (B1+B3) | Low (plan/code cleanup) | `_CheckInStep` widget in `daily_launch_overlay.dart` is unreachable (dead code); manual-test-plan §5 documents Path A multi-question flow that no longer exists | docs/qa/findings/2026-04-26-launch-overlay-dead-checkinstep.md |
| Plan patch | Low (doc) | manual-test-plan §5 — `(current_date-1)::text` cast errors on date column | patched inline |

## Verdict

**DONE_WITH_CONCERNS** — 4/4 cases resolved. B4 + B6 PASS on simulator. B1 + B3 obsolete-by-design (production code path no longer exists), filed as findings F1 + F2 with proposed fixes. Pending the F1 re-entry guard + F2 dead-code cleanup, manual-test-plan §5 must drop the multi-question Path A references.
