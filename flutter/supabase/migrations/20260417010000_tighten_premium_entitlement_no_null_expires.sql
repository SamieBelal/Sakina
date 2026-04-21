-- Subscription-only monetization (2026-04-17 decision) means a valid
-- premium entitlement MUST have a non-null expires_at. Previously the
-- helper treated null expires_at as "lifetime access" to accommodate the
-- removed one-time premium SKU. With subscriptions only, null means
-- "malformed webhook event" or "missing data" — NOT access.
--
-- This tightens the guard so a webhook event that somehow lands a row with
-- null expires_at (malformed RevenueCat payload, edge function bug, manual
-- insert) does NOT grant permanent free premium.

create or replace function public.has_active_premium_entitlement(target_user_id uuid)
returns boolean
language sql
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.user_subscriptions s
    where s.user_id = target_user_id
      and s.entitlement = 'premium'
      and s.expires_at is not null
      and s.expires_at > timezone('utc', now())
  );
$$;
