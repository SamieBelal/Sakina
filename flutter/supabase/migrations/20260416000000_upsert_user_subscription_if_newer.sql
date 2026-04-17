-- Atomic upsert for RevenueCat webhook events.
--
-- Collapses the "check stored last_event_at" and "write new row" into a single
-- statement to prevent a race where two concurrent webhook deliveries both read
-- the same stale timestamp and both write. The WHERE clause on the ON CONFLICT
-- branch ensures older events cannot clobber newer ones.
--
-- Returns true if a row was written (or updated), false if the incoming event
-- was older than the stored last_event_at and therefore ignored.

create or replace function public.upsert_user_subscription_if_newer(payload jsonb)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  row_written int;
begin
  insert into public.user_subscriptions (
    user_id,
    entitlement,
    product_id,
    store,
    environment,
    revenuecat_app_user_id,
    revenuecat_original_app_user_id,
    aliases,
    expires_at,
    canceled_at,
    billing_issue_detected_at,
    last_event_type,
    last_event_at,
    updated_at
  )
  values (
    (payload ->> 'user_id')::uuid,
    payload ->> 'entitlement',
    payload ->> 'product_id',
    payload ->> 'store',
    payload ->> 'environment',
    payload ->> 'revenuecat_app_user_id',
    payload ->> 'revenuecat_original_app_user_id',
    coalesce(payload -> 'aliases', '[]'::jsonb),
    nullif(payload ->> 'expires_at', '')::timestamptz,
    nullif(payload ->> 'canceled_at', '')::timestamptz,
    nullif(payload ->> 'billing_issue_detected_at', '')::timestamptz,
    payload ->> 'last_event_type',
    nullif(payload ->> 'last_event_at', '')::timestamptz,
    timezone('utc', now())
  )
  on conflict (user_id, entitlement) do update set
    product_id = excluded.product_id,
    store = excluded.store,
    environment = excluded.environment,
    revenuecat_app_user_id = excluded.revenuecat_app_user_id,
    revenuecat_original_app_user_id = excluded.revenuecat_original_app_user_id,
    aliases = excluded.aliases,
    expires_at = excluded.expires_at,
    canceled_at = excluded.canceled_at,
    billing_issue_detected_at = excluded.billing_issue_detected_at,
    last_event_type = excluded.last_event_type,
    last_event_at = excluded.last_event_at,
    updated_at = excluded.updated_at
  -- Update only when the incoming event is at least as new as what we have.
  -- A null stored timestamp means "first write" or a backfilled row, so we accept.
  -- A null incoming timestamp means a malformed event, so we refuse to overwrite
  -- a timestamped row (protects against malformed events clobbering good state).
  where
    public.user_subscriptions.last_event_at is null
    or (
      excluded.last_event_at is not null
      and excluded.last_event_at >= public.user_subscriptions.last_event_at
    );

  get diagnostics row_written = row_count;
  return row_written > 0;
end;
$$;

revoke all on function public.upsert_user_subscription_if_newer(jsonb) from public;
grant execute on function public.upsert_user_subscription_if_newer(jsonb) to service_role;
