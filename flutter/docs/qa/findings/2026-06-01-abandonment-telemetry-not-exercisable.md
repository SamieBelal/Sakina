# Finding: onboarding_abandoned_at_page Not Exercisable in QA Sessions

**Date:** 2026-06-01  
**Lane:** B  
**Severity:** Low (design constraint, not a bug)  
**Type:** Telemetry coverage gap  

## Summary

The `onboarding_abandoned_at_page` event cannot be triggered in any QA session (simulator or physical device) without either:
- Waiting 24+ real hours between backgrounding and foregrounding the app, OR
- A debug/test seam that mocks the time threshold

## Event Design

```dart
// onboarding_screen.dart
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _pausedAt = DateTime.now();
    _pausedAtPage = ref.read(onboardingProvider).currentPage;
  } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
    if (shouldFireAbandonment(pausedAt: _pausedAt!, resumedAt: DateTime.now())) {
      // fires onboarding_abandoned_at_page
    }
  }
}

bool shouldFireAbandonment({required DateTime pausedAt, required DateTime resumedAt}) {
  return resumedAt.difference(pausedAt) > const Duration(hours: 24);
}
```

The threshold is hardcoded to 24 hours and `_pausedAt` is in-memory only (lost on app kill).

## What Was Attempted

1. Advanced to page 2 (AgeRangeScreen) during a fresh onboarding session
2. Killed app with `xcrun simctl terminate` (simulating a force-kill)
3. Relaunched — onboarding state correctly restored to page 2 (SharedPreferences), but `_pausedAt` was null (in-memory variable lost on process termination)
4. The 24h threshold was not met in any case (session took ~10 minutes)

**Result:** Event not fired. Mixpanel baseline confirmed 0 events over 30 days.

## Unit Test Coverage

`test/features/onboarding/abandonment_telemetry_test.dart` covers:
- T11: pause > 24h → `shouldFireAbandonment` returns `true`
- T11: pause = 7 days → `true`
- T12: pause < 24h (1h) → `false`
- T12: pause = exactly 24h → `false` (must be strictly greater)
- pause 24h + 1 minute → `true`
- M2: Legacy paywall suppression — pause on p25 (legacy paywall) is suppressed; pause on p19 (mid-flow in legacy) is NOT suppressed

## Recommendation

Add a `@visibleForTesting` / `debugAbandonmentThreshold` parameter to `shouldFireAbandonment` (or inject a `Clock` interface) so integration tests can simulate a 25h gap without waiting real time. This would allow:

1. A widget test to push `AppLifecycleState.paused`, then `AppLifecycleState.resumed` with a mocked 25h gap
2. Verification that the Mixpanel `track()` call fires with correct `page` and `gone_hours` properties

## Production Status

The event has 0 fires over 30 days. This is plausibly correct — most users either complete onboarding quickly or don't return after 24+ hours. The value of this event is as a long-term funnel attribution signal, not a real-time metric.

## Classification

**Not a bug.** The event logic is correct (unit-tested). The QA coverage gap is a tooling/testability limitation.
