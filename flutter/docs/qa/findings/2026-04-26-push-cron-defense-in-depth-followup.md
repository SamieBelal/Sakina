# Follow-up: cron-side defense in depth for push_enabled drift

**Severity:** Low (tracked follow-up; F2 root cause already fixed)
**Surface:** `supabase/functions/send-scheduled-notifications/index.ts` + `public.get_eligible_notification_users` RPC
**Filed:** 2026-04-26 alongside F2 fix

## Why file this

F2 fixed the **client-side** cause of `push_enabled` drift on 2026-04-26: the
Flutter app now reconciles `push_enabled=false` whenever iOS notification
permission is denied. That closes the known regression where the cron
dispatched undeliverable pushes and silently wrote `last_*_sent_at`.

The cron's eligibility query in `get_eligible_notification_users` still
trusts `n.push_enabled = true` as the only push-readiness signal. If that
column drifts back to true for any **future** unknown reason — race, manual
DB write, regression in onboarding/auth flow, RLS bypass — the cron resumes
ghost-dispatching with no observable failure. Defense in depth would catch
those unknowns.

## Proposed designs (pick one in a future pass)

### Option A — OneSignal subscription mirror

New table `public.onesignal_subscriptions(user_id, onesignal_id,
notification_types, subscribed_at, updated_at)`, populated by a OneSignal
webhook on every subscription state change. Cron joins it and adds:

```sql
JOIN public.onesignal_subscriptions os ON os.user_id = n.user_id
WHERE os.notification_types > 0
```

Most thorough — actually checks the device-side truth. Requires:
- Schema migration + RLS policies
- New OneSignal webhook handler edge function
- Backfill for existing users via OneSignal export API

### Option B — Client-stamped verification timestamp

Add column `public.user_notification_preferences.push_enabled_last_verified_at`.
Client writes it on every `AppLifecycleState.resumed` while iOS perm is
granted (and on signed-in bootstrap). Cron adds:

```sql
AND n.push_enabled_last_verified_at > now() - interval '7 days'
```

Stale rows where the device hasn't reconfirmed in a week stop receiving pushes
even if `push_enabled=true` lies. Requires:
- Schema migration (single column add)
- Client lifecycle hook in `notification_service.dart`
- Cron RPC SQL update

Smaller blast radius than A, no new infra. Trades absolute correctness for
simplicity (a long-idle but properly-permitted user gets a 7-day grace
period).

## Why not now

F2 client-side fix shipped 2026-04-26 with 2 unit tests. The remaining risk
surface is "future unknown drift causes" — by definition speculative. Either
A or B is real schema work that benefits from a design pass and explicit
prioritization, not a tail-end bolt-on after a QA run.

## Trigger to revisit

- A second push_enabled-drift incident after the F2 client fix lands in
  production.
- Mixpanel funnel discrepancy where `last_daily_sent_at` is populated but
  user retention shows no notification opens.
- OneSignal dashboard showing high "subscribed but undeliverable" count.

Any of those three signals = stop deferring, pick A or B, design pass, ship.

## Status: Option B IMPLEMENTED 2026-04-26

Migration `add_push_enabled_last_verified_at_with_cron_filter`:

- Added `public.user_notification_preferences.push_enabled_last_verified_at TIMESTAMPTZ`.
- Backfilled all 29 existing `push_enabled = true` rows to `now()`. Each user
  has a fresh 7-day grace window from rollout.
- Added partial index `idx_user_notification_preferences_verified` on
  the new column where `push_enabled = true`.
- Replaced `public.get_eligible_notification_users` with a version that
  adds `n.push_enabled_last_verified_at IS NOT NULL AND
  n.push_enabled_last_verified_at > now() - interval '7 days'` to the
  WHERE clause. All other behavior unchanged.

Client (`lib/services/notification_service.dart`):

- New private helper `_writePushEnabledVerifiedAtToSupabase()` upserts
  `push_enabled_last_verified_at = now()` for the current user.
- Called from `optIn()` after a successful permission grant.
- Called from `getNotificationPreferences()` when the server reports
  `push_enabled = true` AND the device has iOS perm currently granted
  (the F2 reconcile branch already wrote `push_enabled = false` in the
  perm-denied case; verified_at stays untouched there so the cron skips
  the user as intended).

Tests added in `test/services/notification_service_test.dart`:

- "stamps push_enabled_last_verified_at when push_enabled=true and iOS perm is granted (Option B defense in depth)"
- "does NOT stamp verified_at when iOS perm is denied"
- "optIn stamps push_enabled_last_verified_at on success"
- "optIn does NOT stamp verified_at when iOS denies permission"

End-to-end verified via Supabase MCP:

- Backfill: 29/29 push_enabled rows have non-null verified_at, all within
  the 7-day window, eligibility count = 29.
- Aged a single row's verified_at to `now() - interval '8 days'`,
  confirmed the filter excluded that user (eligible_under_filter = 0).
  Restored to `now()`. Final count back to 29 eligible.

Suite: 360/360 pass (was 356, +4 new). `flutter analyze` clean on changed files.

What this catches: any future drift of `push_enabled = true` that is not
accompanied by a fresh client-side verification within 7 days. The cron
will skip those users until the device foregrounds with iOS perm granted
and stamps verified_at again. F2's known cause is closed by the client
reconcile; this catches unknown future causes.

What this does NOT catch: a future client bug that incorrectly stamps
verified_at without checking iOS perm. That would route around both
locks. Detection still relies on funnel monitoring (last_*_sent_at vs
notification_opened events).
