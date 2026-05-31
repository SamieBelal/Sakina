-- 2026-04-26 backend QA found that EXPIRATION webhook events were wiping
-- `canceled_at` from a prior CANCELLATION. Root cause: the upsert read
-- `payload->>'canceled_at'` for missing keys as null and overwrote the stored
-- timestamp. Cancellation history was lost at expiry — analytics regression
-- only (entitlement state was still correct).
--
-- Fix: preserve stored `canceled_at` and `billing_issue_detected_at` when the
-- incoming JSON payload OMITS the key. An explicit null in the payload still
-- clears the column (active-lifecycle events depend on this).
--
-- See docs/qa/findings/2026-04-26-backend-rls-pass.md.

create or replace function public.upsert_user_subscription_if_newer(payload jsonb)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $function$
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
    -- Key-presence-aware: preserve stored value when the key is omitted from
    -- the payload (e.g. EXPIRATION leaves canceled_at unset to keep history).
    -- Explicit null in the payload still overwrites (active-lifecycle clear).
    canceled_at = case
      when payload ? 'canceled_at' then excluded.canceled_at
      else public.user_subscriptions.canceled_at
    end,
    billing_issue_detected_at = case
      when payload ? 'billing_issue_detected_at' then excluded.billing_issue_detected_at
      else public.user_subscriptions.billing_issue_detected_at
    end,
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
  return row_written > 0;
end;
$function$;
