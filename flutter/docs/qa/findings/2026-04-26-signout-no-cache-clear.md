# Phase-4-F3: Sign-out does not clear scoped SharedPrefs

**Severity:** Medium
**Surface:** sign-out flow in `lib/features/settings/screens/settings_screen.dart` + auth service
**Found:** 2026-04-26 settings/push QA run

## Observation

Pre sign-out: 38 user-scoped Flutter SharedPrefs keys (`flutter.<key>:<uid>`) on disk for `a55cc84f-c916-496f-8623-ef24cc89eca4`.

Action: tap Sign Out, confirm dialog → app routes to `/welcome` ✅.

Post sign-out: same 38 keys still present in `Library/Preferences/com.sakina.app.sakina.plist`.

CLAUDE.md and `manual-test-plan.md` §14 both state: "scoped caches cleared" on sign-out. They are not.

## What is preserved (38 keys)

Daily loop, daily usage (reflect + built-dua) for multiple dates, first-steps quest state, quests progress, achievements, activity log, card collection, card seed, card seen, checkin history, current/longest streak, daily rewards, discovery quiz results, last_active, names invoked, all 6 notification prefs, streak milestones, tier-up scrolls, title auto-mode, tokens, total_tokens_spent, total_xp, saved_built_duas, saved_reflections, tier_ups_log_v1.

Plus 4 obsolete date-scoped daily_loop / daily_usage keys from 2026-04-22 still on disk 4 days later.

## Why it matters

1. **Privacy:** signed-in spiritual content (saved_reflections, saved_built_duas, names_invoked) remains in plist after sign-out. iOS file system protections still apply, but the app's own contract says it's gone.
2. **Storage growth:** date-scoped keys (`daily_loop_2026-04-22:<uid>`) accumulate forever. No GC.
3. **Stale-state risk on re-login:** when the same user signs back in, the local cache loads first and the server reconcile may not catch every column. Behavior diverges from "fresh sign-in" assumption.
4. **Cross-user safety is preserved by user-UUID scoping** — User B reads their own keys, not User A's. So this is not a leak. But that scoping is the *only* thing preventing it.

## Fix recommendation

In sign-out flow:
1. After clearing the auth session, iterate `prefs.getKeys()` and remove every key matching `:<uid>` suffix (or use the `supabaseSyncService.scopedKey` predicate inversely).
2. Optionally: also remove date-scoped keys for prior dates (`daily_loop_*`, `daily_usage_*`) that don't match today.
3. Add a unit test that signs in as User A, writes a scoped key, signs out, asserts `prefs.getKeys().where((k) => k.contains(uidA)).isEmpty`.

Belt-and-braces: server-side `delete_own_account` already wipes server rows; sign-out is the gentler local mirror of that contract.

## Status: FIXED 2026-04-26

`lib/services/auth_service.dart` — extracted top-level
`clearScopedPreferencesForUser(prefs, uid)` helper that filters
`prefs.getKeys()` for the `:<uid>` suffix and removes each. `signOut()` now
captures the uid before `_supabase.auth.signOut()` and calls the helper after.
Cross-user safety preserved: only keys matching the suffix of the
signing-out user are removed; user B keys and unscoped global keys survive.

Tests added in `test/services/auth_service_signout_clear_prefs_test.dart`:
- "removes only keys ending with :<uidA>, preserves uidB and globals"
- "returns 0 and is a no-op when uid is empty"
- "returns 0 when no scoped keys exist for the given uid"

Date-scoped keys for prior days (`daily_loop_2026-04-22:<uid>`) are also
removed by this fix since they share the suffix. Date-scoped keys for
not-yet-signed-out users (User B) are preserved.
