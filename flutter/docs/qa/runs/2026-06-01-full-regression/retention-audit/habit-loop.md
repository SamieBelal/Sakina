# Habit-Loop / Retention Analytics Coverage Audit

**Date:** 2026-06-01
**Scope:** Daily-habit retention engine — daily muḥāsabah (both paths), streaks, notifications/reminders, quests/XP/daily reward, reflect, build-a-dua.
**Method:** Code (`lib/features/`, `lib/services/analytics_events.dart`) + wiring grep + Mixpanel `Run-Query` (project 4013350, 30d, math total/unique).
**Verdict:** **Severe under-instrumentation.** The activation event (`first_checkin_submitted`) and a cold-start `app_opened` fire, but **the entire daily retention loop after activation is dark.** There is no daily-check-in-completed event, no streak telemetry, no notification-open event, no quest/reward/feature-usage events, and no warm-start/session signal. We cannot currently measure habit formation, notification-driven re-engagement, or feature-usage frequency.

---

## Coverage matrix

Legend — Defined? = constant exists in `analytics_events.dart`. Wired? = ≥1 real callsite emits it. Firing = Mixpanel total events, 30d.

| Surface | Event (actual or *needed*) | Defined? | Wired? | Firing (30d) | Sufficient? | Gap |
|---|---|---|---|---|---|---|
| App lifecycle | `app_opened` | Yes | Yes (`main.dart:183`, cold start only) | 608 total / 199 unique | **No** | Fires only in `main()` at cold start. App **resume** (`app_lifecycle_observer.dart:86`) only invalidates premium state — no event. ~3 opens/user/mo ≠ real DAU. |
| App lifecycle | *`app_resumed` / `session_started`* | No | No | — | — | **MISSING.** No warm-start/foreground signal → no true DAU/return-visit. |
| Daily muḥāsabah (Home → `/muhasabah` `discoverName`) | *`daily_checkin_completed` (with streak_count, path)* | No | No | — | — | **MISSING.** `discoverName()` (`daily_loop_provider.dart:449`) writes history + marks streak + handles milestones but emits **zero** analytics. Primary daily loop completion is dark. |
| Daily muḥāsabah (`DailyLaunchOverlay` `answerCheckin`) | *`daily_checkin_completed` (path=questions)* | No | No | — | — | **MISSING.** `answerCheckin()` (`daily_loop_provider.dart:605`) — no analytics. Can't compare the two muhasabah paths. |
| Activation / aha | `first_checkin_submitted` | Yes | Yes (`first_checkin_screen.dart:214`) | 151 | Partial | Onboarding-only aha. Good. But it's the *only* check-in event in the whole app — there is no recurring daily equivalent. |
| Streaks | *`streak_extended` (current/longest)* | No | No | — | — | **MISSING.** `markActiveToday()` (`streak_service.dart:232`) — no event. Can't measure streak progression / habit formation. |
| Streaks | *`streak_milestone_reached` (days, xp, scrolls)* | No | No | 0 | — | **MISSING.** Milestone logic fully built (`_markStreakAndHandleMilestones` → `streakMilestone*` state, `streak_service.dart:73`) but unInstrumented. |
| Streaks | *`streak_freeze_consumed`* | No | No | — | — | **MISSING.** `consumeStreakFreeze()` (`streak_service.dart:272`) — no event. Can't measure freeze save-rate / churn-prevention value. |
| Notifications | `notification_permission_result` | Yes | Yes (`notification_screen.dart:40,152`) | 132 | Yes | Grant/deny outcome captured. Good. |
| Notifications | *`notification_opened` (type)* | No | No | 0 | — | **MISSING — highest priority.** Click listener (`notification_service.dart:492`) routes by type (`daily_reminder`, `streak_risk`, `streak_milestone`, `reengagement`, `weekly_reflection`, `tour_replay`) but emits **no event**. **No notification→re-engagement attribution possible.** |
| Notifications | *`notification_sent` (server-side)* | No | No | — | — | **MISSING.** Edge fn `send-scheduled-notifications` dispatches 4 categories with no analytics emission → no sent→open→session funnel; can't compute notification CTR. |
| Notifications | *reminder time set / changed* | No | No | — | — | Partial. Onboarding reminder time piggybacks on `onboarding_answer_captured` (`reminder_time_screen.dart:96`). No standalone event, and **no Settings-side reminder-time-changed event**. |
| Quests | *`quest_completed` (id, cadence)* | No | No | 0 | — | **MISSING.** `completeQuest()` (`quests_provider.dart:914`) + ~10 `on*Completed` triggers — no analytics. Can't measure quest engagement as a retention lever. |
| XP / Levels | *`xp_awarded` / `level_up`* | No | No | — | — | **MISSING.** `_handleXpAward` (`daily_loop_provider.dart:381`) — no event. No progression telemetry. |
| Daily reward | *`daily_reward_claimed`* | No | No | 0 | — | **MISSING.** `claim()` (`daily_rewards_provider.dart:19`) — no event. Daily-reward is a core return-visit hook; its pull is unmeasured. |
| Reflect | *`reflect_completed`* | No | No | 0 | — | **MISSING.** `reflect_provider.dart` only has bypass-reservation tracking (`:454`), no feature-usage event. |
| Build-a-Dua | *`dua_built` / `dua_saved`* | No | No | 0 | — | **MISSING.** `duas_provider.dart` — only bypass reservation + internal `_trackNamesInvoked` (catalog, not Mixpanel). No completion event. |
| Guided tour | `tour_completed` (+ tour_* family) | Yes | Yes | 14 | Yes | Fully instrumented. Reference example of how the rest should look. |
| Ramadan gift | `ramadan_gift_claimed` (+ shown/expired) | Yes | Yes | 1 | Yes | Instrumented. |

**Mixpanel confirmation:** A batched query of the 8 candidate missing events (`daily_checkin_completed`, `muhasabah_completed`, `streak_milestone_reached`, `quest_completed`, `notification_opened`, `daily_reward_claimed`, `reflect_completed`, `dua_built`) returned **empty results** — none exist in the project. Defined-and-wired events (`app_opened`, `first_checkin_submitted`, `notification_permission_result`, `tour_completed`, `ramadan_gift_claimed`) all fire.

---

## Prioritized missing events (with the retention decision each informs)

### P0 — blocks core retention measurement

1. **`notification_opened`** `{type, route}` — wire in `notification_service.dart:492` click listener (one line per route already known).
   → *Decision:* Which push categories drive re-engagement? Is the notification program worth its cost? **Without this we have zero notification→session attribution** — the #1 retention driver is a black box.

2. **`daily_checkin_completed`** `{path: "discover"|"questions", streak_count, is_new_card, tier_changed}` — wire in both `discoverName()` (`:449`) and `answerCheckin()` (`:605`).
   → *Decision:* DAU of the core loop, D1/D7/D30 retention curves, habit-formation rate, and which muhasabah path retains better. This is the single most important recurring engagement event and **does not exist.**

3. **`app_resumed` / `session_started`** — emit from `app_lifecycle_observer.dart:86` (`resumed`) in addition to cold-start `app_opened`.
   → *Decision:* True DAU / return-visit / stickiness (DAU÷MAU). Current `app_opened` (cold-start only, 608/199 ≈ 3 per user per month) drastically under-counts real opens and **cannot serve as the DAU metric.**

### P1 — habit-formation & re-engagement depth

4. **`streak_extended`** `{current_streak, longest_streak, used_freeze}` — `streak_service.dart:232 markActiveToday`.
   → *Decision:* Streak progression = the clearest habit-formation proxy; where do users fall off the streak ladder?

5. **`streak_milestone_reached`** `{days, xp, scrolls}` — `_markStreakAndHandleMilestones` (`daily_loop_provider.dart`); state already carries the values.
   → *Decision:* Do milestone rewards actually re-motivate? Milestone→next-day-return lift.

6. **`notification_sent`** (server, edge fn `send-scheduled-notifications`) `{type, user_id}`.
   → *Decision:* Notification CTR (sent→opened) and per-category effectiveness; pair with #1 to close the full push funnel.

7. **`streak_freeze_consumed`** `{streak_saved}` — `streak_service.dart:272`.
   → *Decision:* Churn-prevention value of the freeze mechanic; save-rate.

### P2 — feature-usage frequency & gamification pull

8. **`daily_reward_claimed`** `{day_index, reward}` — `daily_rewards_provider.dart:19`.
   → *Decision:* Daily-reward as a return-visit hook — claim frequency vs. retention.

9. **`quest_completed`** `{quest_id, cadence}` — `quests_provider.dart:914`.
   → *Decision:* Quests as a retention lever; which cadence (daily/weekly/beginner) correlates with retention.

10. **`reflect_completed`** / **`dua_built`** `{...}` — reflect & duas providers.
    → *Decision:* Per-feature usage frequency; which secondary features deepen the habit vs. are dead weight.

11. **`xp_awarded` / `level_up`** — `_handleXpAward` (`daily_loop_provider.dart:381`).
    → *Decision:* Progression pacing; does leveling correlate with retention.

12. **`reminder_time_changed`** (Settings side) — give the onboarding reminder-time its own standalone event too.
    → *Decision:* Do users who tune reminders retain better; reminder-time distribution for send-time optimization.

---

## Architecture note

Service-layer providers (daily loop, streaks, quests, reflect, duas) have **no Riverpod/analytics access** today — the same constraint already solved for the AI-bypass funnel via static hook indirection (`GatingService.onAnalyticsEvent`, `DailyCapSheet.onAnalyticsEvent` wired in `main.dart:191-194`). The P0–P2 events should reuse that exact `onAnalyticsEvent` static-hook pattern rather than threading an analytics dependency through each service. `tour_*` and `ramadan_gift_*` are good reference implementations of fully-wired event families to copy.
