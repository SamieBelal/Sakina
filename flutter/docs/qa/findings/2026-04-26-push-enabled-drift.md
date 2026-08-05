# Phase-2-F2: push_enabled drifted true with iOS perm denied

**Severity:** Medium
**Surface:** `user_notification_preferences.push_enabled` write path
**Found:** 2026-04-26 settings/push QA run

## Observation

When the QA run started, the test user `verify20260422b@sakinaqa.test` had:
- DB `user_notification_preferences.push_enabled = true`
- iOS notification permission **denied** for the app (proven by the recurring "Open Settings" prompt on every cold launch).

The Settings page master toggle now correctly refuses to set `push_enabled=true` when iOS perm is denied (it shows the "Open Settings" dialog and leaves DB `push_enabled=false`). So the current write path is sound — yet the DB row was already drifted into the bad state at some prior point.

## Why it matters

When `push_enabled=true` while iOS perm is OFF, the backend cron believes the user wants pushes and dispatches them to OneSignal. The device never receives them. The DB columns `last_daily_sent_at`, `last_streak_sent_at`, `last_weekly_sent_at` get written even though zero pushes are delivered, masking the silent failure. This makes funnel/retention analytics blind to a class of dead-channel users.

## Likely sources

1. Pre-fix code path that wrote `push_enabled=true` without consulting iOS perm. Now closed for the master toggle, may still exist for onboarding flow (notification page) or backend RPC.
2. iOS perm was granted, app wrote `push_enabled=true`, user later revoked OS perm in Settings. App never re-checks on launch and reconciles DB.

## Fix recommendation

On every `AppLifecycleState.resumed` (or a fresh signed-in session bootstrap), check `OneSignal.Notifications.permission` (or the equivalent `permissionNative` API) and if false, write `push_enabled=false`. This makes the iOS layer authoritative for the gate.

Backend belt-and-braces: cron should skip dispatch if no OneSignal subscription is `notification_types > 0`, regardless of `push_enabled` value.

## Status: FIXED 2026-04-26

`lib/services/notification_service.dart` — `getNotificationPreferences` now
reconciles after the server fetch: if `push_enabled=true` but
`_client.isPermissionGranted` is false, it writes `push_enabled=false` back
to Supabase via the existing `_writePushEnabledToSupabase` helper. The cron
filters on `push_enabled`, so dispatch stops until the user re-enables (which
calls `optIn()` and re-checks iOS perm).

Tests added in `test/services/notification_service_test.dart`:
- "getNotificationPreferences reconciles push_enabled=false when iOS permission is denied (F2)"
- "getNotificationPreferences leaves push_enabled=true intact when iOS permission is granted"

Backend belt-and-braces (cron-side filter on subscription notification_types) is still
recommended as a separate hardening pass.
