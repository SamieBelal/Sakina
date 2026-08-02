# Finding: guided-tour `tour_anchor_timeout` fires ~31% of tour starts

- **Found:** 2026-06-01, corroborated by Lane A (tour run) + growth-reengagement analytics audit
- **Severity:** Medium (UX reliability — degrades the tour for ~1 in 3 users)
- **Status:** Open — investigate
- **Component:** guided tour anchor resolution (`lib/features/tour/`)

## What

`tour_anchor_timeout` is a *designed* graceful fallback that fires when the tour can't locate its target
anchor widget within the timeout. Over 30 days it fired **22 times against ~70 `tour_started` (~31%)**.
A ~31% anchor-miss rate means roughly one in three tour sessions hits at least one step where the
spotlight/cutout can't find its anchor — the tour still proceeds (no crash) but the affected step
degrades (no ring/cutout on the intended element).

This is the instrumentation working correctly (good that we can see it) revealing a **reliability problem
in anchor resolution**, likely related to timing (anchor not yet laid out / off-screen / behind a route
transition) — consistent with Lane A's observation that step-13's banner didn't render on a
saved-catalog-dua route (F-06).

## How to reproduce / quantify
```
Mixpanel Run-Query (project 4013350, insights, 30d):
  tour_anchor_timeout = 22   vs   tour_started = ~70   → ~31%
```
Break down `tour_anchor_timeout` by `step_index`/`step_name` to find WHICH steps miss most (the anchor
resolution for those steps needs a longer wait, a post-layout callback, or a scroll-into-view before arming).

## Recommendation
- Break down timeouts by step to localize the offending anchors.
- For the worst steps: defer arming until after the target's first layout (`addPostFrameCallback` / ensure
  the anchor `GlobalKey` is mounted + visible), and scroll-into-view before showing the cutout.
- Re-measure: target < 5% timeout rate.
- Related: F-06 (step-13 banner route mismatch).
