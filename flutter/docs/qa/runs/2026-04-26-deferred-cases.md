# Deferred QA cases — live sim follow-up

**Run date:** 2026-04-26
**Sim:** iPhone 17 (UDID `E1152EC8-6A80-4966-92D9-7D7425A81CD2`)
**Account:** `shareqa@sakinaqa.test` (uid `7fd655f4-33bd-4ed9-8974-2be27504df5d`)
**Tools:** `mcp__ios-simulator__*`, `mcp__supabase__execute_sql`

Closes the deferred items in `2026-04-26-content-history.md` rows 28, 36, 37 + audits the J-E4 code path.

## Pre-state

```sql
built_rows = 3, reflection_rows = 4, tokens = 185
```

## D-E2 — AI failure mid-build

**Spec target:** Toggle airplane mid-build → expect error snackbar, no row, counter unchanged.

**Sim limitation:** iOS sim has no programmatic airplane mode. `xcrun simctl status_bar` only changes visual state; toggling host wifi disrupts MCP sessions; `pfctl` requires sudo. None of these are clean from inside this MCP harness.

**Substitute test (kill-mid-flight proxy):** answers the same data-integrity question — was anything written or charged before the build completed?

| Step | Observed |
|---|---|
| Reset SP `built_dua_uses` to 0 (plistlib), launch app | OK |
| Duas tab → Build a Dua → "I want to feel hopeful and trust in my Lord" → tap Build | Build kicks off, loader visible |
| `xcrun simctl terminate ... com.sakina.app.sakina` 2s into build | Killed mid-flight |
| Post: `count(*) public.user_built_duas where user_id=<uid>` | **3** (unchanged — no orphan row) |
| Post: `user_tokens.balance` | **185** (unchanged — no token charge) |

**Verdict for proxy:** PASS for the data-integrity invariant. `_doBuild` (`lib/features/duas/providers/duas_provider.dart:471-538`) only writes the row + increments the counter **after** `result.breakdown.isNotEmpty` is verified — both happen on the result-page render, not during the API call. A killed/failed build leaves no orphan state.

**True D-E2 still not exercised live.** Proper coverage requires either:
- A debug feature flag to throw from `_dependencies.buildDua`, or
- A `pfctl` rule blocking `api.openai.com` for the simulator process, or
- Network Link Conditioner (Xcode Additional Tools) configured to drop traffic.

The code path itself is `try { ... } catch (e) { ... error: 'Something went wrong. Please try again.' ...}` (`duas_provider.dart:528-537`) with full state reset — looks correct on review, but live coverage of the AI-throws branch is still **deferred**.

## J-E2 — Share preview from journal detail

| Step | Observed |
|---|---|
| Journal tab → tap Reflection card "Anxious about an exam tomorrow" (Al-Mujeeb) | Detail page renders with header trash + share icons |
| Tap share icon (top-right header) | Preview screen opens cleanly |
| Preview content | "SAKINA" wordmark, Al-Mujeeb gold calligraphy, English transliteration, Arabic verse, English translation, citation "Quran 20:25-26", green "Share" CTA |
| RTL bleed check | Arabic verse + English translation in separate text widgets, no bleed into surrounding UI |
| Tap Share | Native iOS share sheet opens with **PNG document thumbnail** (mini-card visible) + "Plain Text and 1 Document" — both shareText and PNG attached, widget-to-image rendering working |

**Verdict:** PASS. Screenshots: `/tmp/sakina-qa/deferred/02-reflection-detail.png`, `03-share-preview.png`, `04-share-sheet.png`.

## J-E4 — Network failure mid-delete (code audit, no live)

**Sim limitation:** same as D-E2 — no programmatic airplane mode without disrupting the MCP session. Code audit instead.

### `deleteReflection` (`lib/features/reflect/providers/reflect_provider.dart:416-434`)

```dart
Future<void> deleteReflection(String id) async {
  final previous = List<SavedReflection>.from(state.savedReflections);
  final updated = previous.where((r) => r.id != id).toList();
  state = state.copyWith(savedReflections: updated, clearError: true);
  await _persistReflections(updated);

  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  try {
    await supabaseSyncService.deleteRow('user_reflections', 'id', id);
  } catch (_) {
    state = state.copyWith(
      savedReflections: previous,
      error: "Couldn't delete the reflection. Please try again.",
    );
    await _persistReflections(previous);
  }
}
```

**Data integrity:** PASS. Optimistic update with full rollback on server failure — local state and SP both revert.

⚠️ **UX gap (filed):** `state.error` is rendered in `reflect_screen.dart:308-318` but the **Journal tab does NOT render reflectProvider errors**. A delete-while-offline produces this user experience:

1. User taps delete → confirm dialog → tap Delete
2. Item disappears from list (optimistic)
3. Server call fails, state rolls back
4. Item reappears in list, **silently**, with no toast/snackbar/inline error

User has no way to know the delete failed. They will likely retry → same silent reappearance. Add a `ref.listen<ReflectState>(reflectProvider, (prev, next) { if (next.error != ...) showSnackBar; });` in `journal_screen.dart` or surface via `state.error` somewhere visible.

### `removeSavedBuiltDua` (`lib/features/duas/providers/duas_provider.dart:632-641`)

```dart
Future<void> removeSavedBuiltDua(String id) async {
  final updated = state.savedBuiltDuas.where((d) => d.id != id).toList();
  state = state.copyWith(savedBuiltDuas: updated);
  await _persistBuiltDuas(updated);

  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.deleteRow('user_built_duas', 'id', id);
  }
}
```

🐛 **Bug filed: `removeSavedBuiltDua` has NO try/catch.** Compared to `deleteReflection`, this method:
- Updates local state (item gone)
- Persists local SP (item gone)
- Calls supabase delete with no error handling

If the server `deleteRow` throws (network, RLS, transient 5xx), the exception propagates **up to the caller** (`onRemove` callback on `DuaDetailPage` / `journal_screen.dart` row). Best case: user sees the item disappear, exception is silently logged, server row is orphaned (next sync_all_user_data may rehydrate the entry, or it stays deleted-locally / present-server-side, depending on the sync logic). Worst case: an unhandled async exception cascades into the gesture handler.

**Inconsistency with reflect path** — these two delete methods should follow the same pattern. Recommend porting the reflect rollback to `removeSavedBuiltDua` (and check `removeSavedRelatedDua` too).

## Findings filed today

1. **`removeSavedBuiltDua` missing try/catch** — data integrity hole on network failure during built-dua delete. Inconsistent with `deleteReflection` rollback pattern. P2.
2. **Journal does not render `reflectProvider.error`** — `deleteReflection` silently rolls back on server failure with no UI feedback. Confusing UX. P2.
3. **D-E2 still not live-exercised** — proxy via kill-mid-flight passes, but true API-throws branch needs either a debug switch in `_dependencies.buildDua` or proper network blocking tooling. Recommendation: add a `--debug-fail-build-dua` env flag in dev builds to make this testable from MCP.
4. **(Carried over) `user_daily_usage` Supabase upsert silently failing** for shareqa — local SP increments but server has no row. Noticed during D-E5 run; reconfirmed here (still 0 server rows after multiple builds today).

## Cleanup

```sql
-- no DB writes were made by this run that need reverting
```

```python
# SP counter was reset to 0 → app rehydrated to 3 again on its own (see finding 4)
```

## Status

- D-E2 free path → PROXY PASS, true live still deferred (need pfctl or debug flag)
- J-E2 share preview → PASS
- J-E4 network failure mid-delete → CODE AUDIT, 2 new findings filed (no live test)

## Fix verification (2026-04-26 follow-up)

After filing the J-E4 findings, the two real bugs were fixed and re-verified.

### Fix #1 — `removeSavedBuiltDua` rollback

**Code:** `lib/features/duas/providers/duas_provider.dart` — wrapped `deleteRow` in try/catch, restore `previous` state + SP, set `state.error` on failure. Mirrors `deleteReflection` exactly.

**Unit test:** `test/features/duas/remove_built_dua_rollback_test.dart` (2/2 PASS).
- `nextDeleteShouldThrow=true` on the fake sync service → state restored, `state.error` set, SP re-persisted with the original row.
- Success path → state empty, `state.error` null, server delete called once.

`FakeSupabaseSyncService.nextDeleteShouldThrow` flag added in `test/support/fake_supabase_sync_service.dart` for this test and any future delete-rollback coverage.

**Live verification:** not viable on sim (same airplane-mode limitation as J-E4). Unit-test coverage is the achievable bar.

### Fix #2 — Journal renders provider errors

**Code:** `lib/features/journal/screens/journal_screen.dart` — added two `ref.listen` blocks for `reflectProvider` and `duasProvider`. On error change → `ScaffoldMessenger.hideCurrentSnackBar()` + `showSnackBar(content: Text(error))`. Surfaces silent rollbacks from either provider while Journal is on screen.

**Live verification:** compile + smoke run (Reflect tab → flow completed without crashing → app stable). The error path itself can't be triggered live without a network failure, same caveat.

### Fix #3 — `user_daily_usage` upsert (NO FIX NEEDED)

**Investigation:** turned out to be a timing/visibility artifact, not a real silent failure.

**Verification (live, this run):**
1. `delete from public.user_daily_usage where user_id='7fd655f4-33bd-4ed9-8974-2be27504df5d'` → 0 rows.
2. SP `flutter.daily_usage_reflect_2026-04-26:<uid>` cleared via plistlib.
3. App relaunched → Reflect tab → "I am hopeful and want to grow closer to my Lord this Ramadan" → completed Q1 slider + Q2 "Prayer and worship" → Al-Wadud match returned.
4. `select * from public.user_daily_usage where user_id='7fd655f4-33bd-4ed9-8974-2be27504df5d'` →
   ```
   {id: a088652b-..., user_id: 7fd6..., usage_date: 2026-04-26, reflect_uses: 1, built_dua_uses: 0}
   ```

**Verdict:** the `_upsertToday` path in `lib/services/daily_usage_service.dart:78-98` (`onConflict: 'user_id,usage_date'`) works correctly. Earlier "missing row" reads during D-E5 were the upsert-not-yet-completed case (async, fires after the SP increment). The carry-over finding is **closed without code change**.

## Closing summary

- 2 real bugs (J-E4 findings) → FIXED + unit-tested.
- 1 carry-over (Fix #3) → not a real bug; closed.
- 1 still-deferred (D-E2 live AI failure) → unchanged; needs debug flag or pfctl.
