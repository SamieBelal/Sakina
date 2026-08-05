# Finding: `paywall_flow_*` analytics events defined but never wired

- **Found:** 2026-06-01, onboarding-analytics audit (Mixpanel `Run-Query` + code grep)
- **Severity:** Medium (analytics gap — the paywall-rebuild's intended granular funnel is uninstrumented)
- **Status:** FIXED (verified 2026-07-26) — all paywall-flow events now wired in `lib/features/onboarding/screens/onboarding_screen.dart` (loader/plan/journey shown + advanced/continued + `paywallFlowDropoff`).
- **Component:** `lib/services/analytics_events.dart:35-41` + paywall flow screens (pages 22–26)

## What

The paywall rebuild (PR #15, `df5f9d5`) defined granular paywall-flow funnel events:
`paywall_flow_loader_shown`, `paywall_flow_loader_advanced`, `paywall_flow_plan_shown`,
`paywall_flow_plan_continued`, `paywall_flow_journey_shown`, `paywall_flow_journey_continued`,
`paywall_flow_dropoff`.

**None are wired** — `grep` finds 0 `track()` call sites for any of them, and Mixpanel shows
**0 events** over 30 days. The intended loader→plan→journey→dropoff funnel (pages 22–26) cannot be
analyzed. Only the coarse `paywall_viewed` (144/30d) and `paywall_plan_selected` fire.

## How to reproduce
```bash
# 0 call sites:
grep -rn "paywallFlowLoaderShown\|paywallFlowPlanShown\|paywallFlowJourneyShown\|paywallFlowDropoff" lib/ | grep -v analytics_events.dart
# 0 events (Mixpanel Run-Query, project 4013350, insights, eventName='paywall_flow_loader_shown', 30d) → no rows
```

## Fix
Wire each event in the paywall-flow screens with `{variant_id, page_index}`:
- loader screen (p22) → `paywall_flow_loader_shown` on build, `_advanced` on auto-advance
- plan screen (p23) → `paywall_flow_plan_shown` / `_continued`
- journey screen (p24) → `paywall_flow_journey_shown` / `_continued`
- any exit before purchase → `paywall_flow_dropoff` with `last_step`

Add a wiring test so the constants can't silently drift again. See implementation plan:
`docs/superpowers/plans/2026-06-01-onboarding-analytics-instrumentation.md` (G1 / P0-1).
