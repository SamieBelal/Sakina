-- Extends upsert_user_subscription_if_newer for the cancellation-feedback push:
--   1. Persists period_type (trial vs paid) for the survey copy.
--   2. Returns jsonb { written, cancellation_started } instead of a bare bool,
--      so the webhook can fire the "why did you leave?" push exactly once — on
--      the canceled_at null -> set transition, not on every redelivery.
--
-- The return type changes, so the function must be dropped and recreated.

drop function if exists public.upsert_user_subscription_if_newer(jsonb);

create function public.upsert_user_subscription_if_newer(payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  row_written int;
  old_canceled_at timestamptz;
  new_canceled_at timestamptz := nullif(payload ->> 'canceled_at', '')::timestamptz;
begin
  -- Capture the prior cancellation state to detect a fresh cancellation. A
  -- concurrent redelivery could race this read, but the freshness WHERE clause
  -- keeps the row correct and the only consequence of a race is at most one
  -- duplicate push — benign and rare.
  select s.canceled_at
    into old_canceled_at
  from public.user_subscriptions s
  where s.user_id = (payload ->> 'user_id')::uuid
    and s.entitlement = payload ->> 'entitlement';

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
    period_type,
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
    new_canceled_at,
    nullif(payload ->> 'billing_issue_detected_at', '')::timestamptz,
    payload ->> 'period_type',
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
    period_type = excluded.period_type,
    last_event_type = excluded.last_event_type,
    last_event_at = excluded.last_event_at,
    updated_at = excluded.updated_at
  where
    public.user_subscriptions.last_event_at is null
    or (
      excluded.last_event_at is not null
      and excluded.last_event_at >= public.user_subscriptions.last_event_at
    );

  get diagnostics row_written = row_count;

  return jsonb_build_object(
    'written', row_written > 0,
    -- A genuinely new cancellation: the write landed, it was not already
    -- cancelled, and this event carries a cancellation timestamp.
    'cancellation_started',
      row_written > 0 and old_canceled_at is null and new_canceled_at is not null
  );
end;
$$;

revoke all on function public.upsert_user_subscription_if_newer(jsonb) from public;
grant execute on function public.upsert_user_subscription_if_newer(jsonb) to service_role;
