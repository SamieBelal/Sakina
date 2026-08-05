# Journal swallows `deleteReflection` failures silently

**Severity:** P2 (UX)
**Discovered:** 2026-04-26 during deferred-cases code audit (J-E4)
**Status:** FIXED 2026-04-26

## Resolution

Fix shipped: `lib/features/journal/screens/journal_screen.dart` — added two `ref.listen` blocks for `reflectProvider` and `duasProvider`. On error change → `ScaffoldMessenger.hideCurrentSnackBar()` + `showSnackBar(content: Text(error))`.

The `duasProvider` listener pairs with the companion fix for `removeSavedBuiltDua` rollback (`2026-04-26-built-dua-delete-no-rollback.md`), so a failed Personal Dua delete also surfaces a snackbar in Journal.

Live verification not viable on simulator (no programmatic airplane mode); compile + smoke run on real Reflect flow shows app stable, no regression.

## Bug

`deleteReflection` (`lib/features/reflect/providers/reflect_provider.dart:416-434`) correctly rolls back on server delete failure and sets `state.error = "Couldn't delete the reflection. Please try again."`. But that error is **only rendered in `lib/features/reflect/screens/reflect_screen.dart:308-318`** — the Reflect input screen — not in Journal.

A user who deletes a reflection from Journal while offline experiences:
1. Tap delete → confirmation dialog → tap Delete.
2. Item disappears from list (optimistic).
3. Server call fails, state rolls back (data is safe).
4. Item silently reappears in the list.
5. **No toast, no snackbar, no explanation.**

User assumes the app is buggy and likely retries → same silent reappearance.

## Why it matters

The data-integrity rollback is excellent — the right call. But the silent UX undermines user trust. Users who are intermittently offline (commute, weak wifi) will see this regularly and have no idea why deletes "don't work."

## Fix

Add a listener in `lib/features/journal/screens/journal_screen.dart` that surfaces `reflectProvider`'s error via SnackBar:

```dart
ref.listen<ReflectState>(reflectProvider, (prev, next) {
  if (next.error != null && next.error != prev?.error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next.error!)),
    );
  }
});
```

Same pattern needed for `duasProvider` once `removeSavedBuiltDua` gets its try/catch (companion finding `2026-04-26-built-dua-delete-no-rollback.md`).

Bonus: the same error surfacing should work for the inline `_removeButton` on Journal list cards, not just the detail-page header trash icon.

## Evidence

- Run log: `docs/qa/runs/2026-04-26-deferred-cases.md` §J-E4.
- Code reference: `lib/features/reflect/providers/reflect_provider.dart:416-434` (correct rollback) vs `lib/features/journal/screens/journal_screen.dart` (no error listener).
