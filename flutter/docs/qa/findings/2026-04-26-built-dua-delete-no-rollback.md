# `removeSavedBuiltDua` has no try/catch — silent data drift on delete failure

**Severity:** P2 (data integrity)
**Discovered:** 2026-04-26 during deferred-cases code audit (J-E4)
**Status:** FIXED 2026-04-26

## Resolution

Fix shipped: `lib/features/duas/providers/duas_provider.dart` — `removeSavedBuiltDua` now snapshots `previous`, wraps `deleteRow` in try/catch, restores state + SP and sets `state.error` on failure (same pattern as `deleteReflection`).

Regression test: `test/features/duas/remove_built_dua_rollback_test.dart` (2/2 PASS) covers both the rollback-on-throw and the success paths. `FakeSupabaseSyncService.nextDeleteShouldThrow` flag added in `test/support/fake_supabase_sync_service.dart`.

Live verification not viable on simulator (no programmatic airplane mode); unit-test coverage is the achievable bar.

## Bug

`removeSavedBuiltDua` in `lib/features/duas/providers/duas_provider.dart:632-641` updates local state and SharedPreferences, then calls `supabaseSyncService.deleteRow('user_built_duas', 'id', id)` with **no error handling**. If the server delete throws (network failure, RLS rejection, transient 5xx), the exception bubbles up while local state already says the item is gone.

```dart
Future<void> removeSavedBuiltDua(String id) async {
  final updated = state.savedBuiltDuas.where((d) => d.id != id).toList();
  state = state.copyWith(savedBuiltDuas: updated);
  await _persistBuiltDuas(updated);

  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.deleteRow('user_built_duas', 'id', id);
    // ☝️ no try/catch
  }
}
```

## Why it matters

A user who taps delete on a saved Personal Dua while offline (or during a transient backend issue):
- Sees the item disappear from Journal.
- Local SharedPreferences cache is updated.
- Server still has the row.
- Next time `sync_all_user_data()` runs, the row may rehydrate — item reappears with no explanation.
- Or, the local delete sticks but the server row is orphaned.

Either outcome is confusing and slowly accumulates ghost rows in `public.user_built_duas` for users on flaky connections.

## Compare to `deleteReflection` (the right pattern)

`lib/features/reflect/providers/reflect_provider.dart:416-434` does this correctly:
1. Snapshot `previous` state.
2. Optimistic update.
3. Try server delete in a `try { } catch (_)` block.
4. On catch → rollback state + SP + set `state.error`.

That's the pattern `removeSavedBuiltDua` should follow.

## Fix

```dart
Future<void> removeSavedBuiltDua(String id) async {
  final previous = List<SavedBuiltDua>.from(state.savedBuiltDuas);
  final updated = previous.where((d) => d.id != id).toList();
  state = state.copyWith(savedBuiltDuas: updated);
  await _persistBuiltDuas(updated);

  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  try {
    await supabaseSyncService.deleteRow('user_built_duas', 'id', id);
  } catch (_) {
    state = state.copyWith(
      savedBuiltDuas: previous,
      error: "Couldn't delete the dua. Please try again.",
    );
    await _persistBuiltDuas(previous);
  }
}
```

Also audit `removeSavedRelatedDua` (same provider) for the same pattern.

## Evidence

- Run log: `docs/qa/runs/2026-04-26-deferred-cases.md`
- Companion finding (`reflectProvider.error` not rendered in Journal): same run log section §J-E4.
