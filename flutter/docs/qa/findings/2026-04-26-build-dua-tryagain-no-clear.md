# Finding: Build-a-Dua "Try Again" preserves stale text in input field

**Severity:** Low (UX — confusing, blocks legitimate retry)
**Discovered:** 2026-04-26 during §7 D-E5 QA run

## What

When the off-topic UI appears after submitting Build-a-Dua and the user taps "Try Again", the previously-entered text remains in the input field. Subsequent typing appends to the rejected text instead of replacing it.

## Reproduction

1. Duas tab → type "pizza recipe" → Build My Dua → off-topic UI appears.
2. Tap "Try Again".
3. Text field shows: `pizza recipe`.
4. Type "strength to forgive someone who hurt me".
5. Field now shows: `pizza recipestrength to forgive someone who hurt me` (concatenated, no space).
6. Tap Build → regex pre-filter matches "pizza recipe" again → off-topic UI re-shown.
7. User is stuck unless they manually clear the field.

## Why it matters

Users who got the off-topic warning are probably realizing they should rephrase. The friction of having to manually clear the entire field — when the system already knows the prior content was rejected — discourages retries and may push users to abandon the feature.

It also contributed to a side-effect during testing: the regex pre-filter caught the combined string client-side, which means we couldn't reliably test the rapid double-tap-on-Build edge case (D-E5).

## Fix

When transitioning from the off-topic state back to the input state (Try Again handler in the duas notifier), clear `_buildController` text:

```dart
// In duas_screen.dart's Try Again handler or duas_provider.dart's reset
_buildController.clear();
```

## Evidence

- Run log: `docs/qa/runs/2026-04-26-content-history.md` D-E5 row
- Screenshot: `14-de5-state.png` shows the concatenated input
