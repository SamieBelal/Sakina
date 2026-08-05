# §18 Lifecycle + Offline — Findings (2026-04-26)

Driver: Claude Code, programmatic via ios-simulator MCP + bash wrappers.
Plan: `docs/superpowers/plans/2026-04-26-§18-lifecycle-offline-testing.md`.
Sim: iPhone 17 (UDID `E1152EC8-6A80-4966-92D9-7D7425A81CD2`), bundle `com.sakina.app.sakina`.

## Pre-flight

| Check | Result | Notes |
|---|---|---|
| Sim booted | ✓ | iPhone 17 |
| App installed | ✓ | bundle `com.sakina.app.sakina` |
| sudo cached | ✗ | airplane tests deferred until user primes |
| `flutter run` attached | ✗ | falling back to UI screenshots + Supabase logs |
| Onboarding persistence | ✓ | `_saveToPrefs()` writes after every state change; `currentPage` clamped on load |
| pfctl smoke-check | TBD | will run before §18.2 |

## Results

| Case | Status | Evidence |
|---|---|---|
| §18.1 Reflect (stateful form) bg/fg | **PASS** | Sentinel "lifecycle test sentinel feeling 26" preserved across 6s bg → fg. No nav reset, cursor retained, button state unchanged. `/tmp/reflect-before-bg.png` vs `/tmp/reflect-after-fg.png`. |
| §18.1 Names browser (Collection cards) bg/fg | **PASS** | Tab "New 4" still selected post-resume, same 4 cards in same positions (Ar-Rahman, Al-Wadud, Ar-Rasheed silver, Ar-Rasheed gold). `/tmp/collection.png` vs `/tmp/collection-after-fg.png`. |
| §18.1 Onboarding mid-flow bg/fg | **PASS** | Reinstalled app, drove fresh signup through page 7 (Resonant Name picker, "Tester", 25-34, Spiritual Growth, Some days, Weekly, Just Getting Started). Backgrounded 6s → resumed. Page 7 still selected, same Ar-Rahman card in carousel, name input retained. |
| §18.4 Memory warning + terminate during onboarding | **PARTIAL PASS** | Forced terminate (`simctl terminate`) at page 7. Cold relaunch routes to /welcome (router behavior — `lib/core/router.dart:32` `initialLocation: appSession.hasOnboarded ? '/' : '/welcome'`). Tap Get Started → onboarding restores to page 7 with Ar-Rahman pre-selected (`/tmp/ob-after-get-started.png`). SharedPreferences-backed `_saveToPrefs()` persistence works. **UX gap (not P1):** cold launch should arguably skip Welcome when mid-flow onboarding state exists. Memory-warning script (`sim-memory-warn.sh`) updated for Xcode 26 — menu moved from Features to Debug. |
| §18.2 Airplane on Home (cached read + action error) | **FAIL** | Cached Home content (Today's Name, streak, level) renders fine — read path is good. Tap "Continue Muḥāsabah" while offline → infinite "Finding your reflection..." spinner. No timeout, no error surface. Action only resolves once network returns (advances to Prophetic Story). `/tmp/sakina-airplane-075336/18.2-{1..4}.png`. |
| §18.3 Reflect retry-after-online | **FAIL** | Same root cause as §18.2. "offline test 27" typed, tap Reflect offline → infinite spinner. After airplane off, advances to emotion picker (call eventually completed once network returned). No error feedback to user during offline window. `/tmp/sakina-airplane-075336/18.3-{1..3}.png`. |
| §7 D-E2 AI failure mid-build (Dua Builder) | **PASS** | Tap Build offline → red snackbar `"Something went wrong. Please try again."` Retry post-online builds the dua successfully. This is the correct shape: clear error, idempotent retry. `/tmp/sakina-airplane-075336/7-de2-{1..3}.png`. |
| §9 J-E4 mid-delete network failure | **P0 CRITICAL** | Swipe-to-delete a saved reflection offline → entry disappears from list, header counter still says "1 entries" but body shows "No reflections yet" empty state. State stays inconsistent post-recovery. No error toast. No rollback. Local UI confidently lies that the delete succeeded. `/tmp/sakina-airplane-075336/9-je4-{1..3}.png`. |

## §18.1 sample summary

3/3 sampled screens PASS. The `AppLifecycleObserver` resume hook (`lib/core/app_lifecycle_observer.dart`) only invalidates `isPremiumProvider` + `billingIssueProvider` and does NOT cascade into screen-local state — Reflect text controller, Collection tab selection, and onboarding page index all survive bg/fg cycles cleanly. Matches the eng-review prediction.

## §18.4 notes

- **Persistence is real:** `_saveToPrefs()` in `onboarding_provider.dart` (lines 234, 240, 245, 250, 260, 265, 270) writes after every state change; `currentPage` is in the JSON and clamped to `[0, onboardingLastPageIndex]` on load.
- **Cold-launch UX gap:** the router unconditionally sends non-onboarded users to /welcome. Mid-flow restoration only kicks in once they tap Get Started → /onboarding. Not a data-loss bug, but a UX paper-cut worth a follow-up — consider routing to /onboarding directly when `currentPage > 0` is in SharedPreferences.
- **Xcode 26 menu rename:** `Simulate Memory Warning` moved from `Features` to `Debug`. Updated `sim-memory-warn.sh` to try Debug → Features → Device in order, with a printed hint when all three fail.

## Tooling caveat surfaced

`sim-memory-warn.sh` initially failed because the original menu lookup (`Features` then `Device`) is stale on Xcode 26. The fix-forward pattern (try Debug first, fall back, log which path succeeded) means a future Apple rename will be visible immediately rather than discovered weeks later.

## Offline-mode bugs (root-causes)

### P0 — Journal delete swallows exceptions (file as P0)

`lib/services/supabase_sync_service.dart:128-136`:

```dart
Future<bool> deleteRow(String table, String column, dynamic value) async {
  try {
    await Supabase.instance.client.from(table).delete().eq(column, value);
    return true;
  } catch (e) {
    debugPrint('[SupabaseSyncService] deleteRow($table) failed: $e');
    return false;
  }
}
```

`lib/features/reflect/providers/reflect_provider.dart:416-434` does optimistic delete + try/catch rollback **expecting `deleteRow` to throw**, but `deleteRow` swallows the exception and returns `false`. The catch never fires → no rollback, no error snackbar. Pattern is exactly the kind of bug the docstring at `reflect_provider.dart:412-415` was written to prevent.

**Fix options:**
1. Make `deleteRow` rethrow (cleanest — let callers decide).
2. Check the bool return in `reflect_provider.dart:426`: `final ok = await ...deleteRow(...); if (!ok) { throw ...; }` to keep the existing rollback wired up.

Same pattern likely affects every call site that wraps `deleteRow` in try/catch — audit `card_collection_service.dart:2106`, `dev_tools_service.dart:140/156/190`, `checkin_history_service.dart:125`.

### P1 — Reflect AI call hangs forever offline

`lib/features/reflect/providers/reflect_provider.dart:457`:

```dart
final response = await _dependencies.reflect(text);
```

No `.timeout()` on this call. When Supabase/OpenAI calls fail because of DNS/TCP block, the future never completes — UI sits on "Finding your reflection..." (`lib/widgets/reflect_loading.dart`) until network returns. Same affects `_reflect()` callers in the daily-loop / muhasabah path.

**Fix:** wrap with `.timeout(const Duration(seconds: 15), onTimeout: () => throw TimeoutException(...))` and surface a "No connection" snackbar via the existing error channel (`reflect_provider.dart:_setError` if it exists, otherwise `state.copyWith(error: ...)`). Alternatively, set a default httpClient timeout when constructing the Supabase client and ride that through.

### Why §7 D-E2 PASSES while §18.3 FAILS

Both go through similar AI calls. The Dua Builder error path *does* surface "Something went wrong. Please try again." in red, suggesting Dua Builder either:
- Has its own timeout, or
- Goes through a different RPC that throws cleanly on offline.

Worth a 5-min diff between `dua_builder` and `reflect` providers to see what Dua does right that Reflect doesn't, then port the pattern.

## Verdicts summary

- §18.1 (background/foreground): 3/3 PASS
- §18.4 (memory + cold relaunch onboarding): PARTIAL PASS (router UX gap, not data loss)
- §18.2 (Home offline action): FAIL → P1 timeout fix
- §18.3 (Reflect offline action): FAIL → P1 timeout fix
- §7 D-E2 (Dua Build offline): PASS
- §9 J-E4 (Journal delete offline): **P0** swallowed-exception bug

Two P-rated bugs, both small fixes. The §9 bug is the kind of thing that erodes trust silently — fix first.
