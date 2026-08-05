# Finding: `get_eligible_notification_users` is anon-executable → user enumeration / PII exposure

- **Found:** 2026-06-01, Gate 0 security sweep (full-regression run), via `get_advisors security` + function-body + grant inspection
- **Severity:** **High (P1)** — unauthenticated PII disclosure + user enumeration on production
- **Status:** ✅ RESOLVED 2026-06-01 — migration `revoke_public_execute_on_get_eligible_notification_users_v2` applied (revoked from PUBLIC/anon/authenticated, granted service_role). Verified: `anon=false, authenticated=false, service_role=true`. Regression test added: `supabase/tests/notification_eligibility_grant_test.sql`. **Root cause of the first failed attempt:** EXECUTE came from the implicit `PUBLIC` grant, so revoking from `anon` alone was a no-op — must revoke from `PUBLIC`.
- **Confirmed by:** `has_function_privilege('anon', …, 'EXECUTE') = true` and function body has no `auth.uid()` guard

## What

`public.get_eligible_notification_users(p_pref_column, p_sent_column, p_target_hour, p_requires_streak,
p_inactive_days, p_day_of_week, p_use_user_reminder_time)` is:

- `SECURITY DEFINER`, runs with owner privileges
- **executable by the `anon` role** (confirmed: `anon_exec = true`) and reachable at
  `POST /rest/v1/rpc/get_eligible_notification_users` with just the public anon key
- has **no identity / authorization check** in its body

It returns, for every push-enabled user matching the supplied criteria:

```
user_id (uuid), timezone, display_name, current_streak, last_active
```

The only gate is that `p_pref_column` / `p_sent_column` must be in a hard-coded allowlist that is
**visible in the migration source** (`notify_daily`, `last_daily_sent_at`, …). An unauthenticated
attacker can therefore call it directly and, by iterating `p_target_hour` 0–23 (and timezones/days),
**enumerate the push-enabled user base** — harvesting `user_id`, `display_name`, timezone, and streak.

## Why it's reachable despite earlier revokes

`20260509000000_revoke_anon_rpc_execute.sql` revoked anon EXECUTE broadly, but the grant is present
again now. Most likely re-introduced by a later `CREATE OR REPLACE` redefinition
(`20260512212403_daily_reminder_uses_user_reminder_time`) and/or codified by
`20260531200000_reconcile_anon_rpc_grants` ("reconcile anon RPC grants to match prod") — i.e. prod
drift was reconciled *toward* the insecure state.

## Blast radius / caller analysis

- **Only legitimate caller:** `supabase/functions/send-scheduled-notifications/index.ts:190`, which runs
  as **`service_role`** and bypasses GRANT checks entirely.
- The Flutter client does **not** call it (`lib/services/notification_service.dart:237` is only a comment).

→ Revoking EXECUTE from `anon` (and `authenticated`) does **not** break the notification cron.

## Fix

New migration:

```sql
revoke execute on function public.get_eligible_notification_users(
  text, text, integer, boolean, integer, integer, boolean
) from anon, authenticated;
```

(Defense-in-depth: also add an early `if auth.role() <> 'service_role' then raise exception …` guard so a
future accidental re-grant can't re-open it.)

## Verify after fix

```sql
select has_function_privilege('anon', 'public.get_eligible_notification_users(text,text,integer,boolean,integer,integer,boolean)', 'EXECUTE'); -- expect false
```
Then confirm `send-scheduled-notifications` still dispatches (service_role unaffected) and re-run
`get_advisors security`.

## Related (lower severity, no action required)

`claim_sakina_gift(uuid,text)` is also anon-executable, **but its body rejects anon**
(`if auth.uid() is null or auth.uid() <> p_user then return unauthorized`) and enforces the occasion
window + idempotency. Not exploitable; advisor WARN is a false positive. Revoking anon EXECUTE there
would be tidy defense-in-depth but is optional.
