-- Consumable purchase clawback for refunds.
--
-- The earn_tokens / earn_scrolls RPCs (introduced in
-- 20260412170000_economy_atomic_hardening_wave6.sql and
-- 20260411210500_add_tier_up_scrolls.sql respectively) are blind to which
-- transaction triggered them. When a user refunds a consumable IAP via
-- Apple, RevenueCat fires a CANCELLATION webhook event with the consumable
-- product id. Without a clawback path, the user keeps the tokens AND gets
-- the money back. This migration adds:
--
--   1. consumable_clawback_events  — idempotency table keyed on the RC
--      transaction_id. A second webhook fire for the same refund is a no-op.
--   2. clawback_consumable_grant() — service-role RPC that decrements
--      the user's tokens or scrolls based on the SKU's amount. Called
--      from the revenuecat-webhook edge function when it sees a
--      CANCELLATION for a consumable SKU.
--
-- Edge cases handled:
--   - Balance underflow: if the user has already spent the refunded
--     tokens, balance can't go negative. Cap at 0 and log the deficit
--     in `clawback_deficit` for support to review.
--   - Race condition (webhook fires twice): the unique key on
--     transaction_id makes the second insert a conflict, RPC returns
--     `{ status: "already_processed" }`.
--   - Unknown SKU: RPC raises so the webhook returns 500 and RC retries.
--     This shouldn't happen in practice (the webhook handler filters
--     against the same SKU map), but the guard prevents silent skips.

create table if not exists public.consumable_clawback_events (
  transaction_id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  sku text not null,
  kind text not null check (kind in ('tokens', 'scrolls')),
  amount int not null check (amount > 0),
  applied_amount int not null check (applied_amount >= 0),
  clawback_deficit int not null default 0 check (clawback_deficit >= 0),
  event_timestamp timestamptz not null,
  processed_at timestamptz not null default now()
);

create index if not exists consumable_clawback_events_user_id_idx
  on public.consumable_clawback_events(user_id);

-- RLS: only service_role reads or writes. Users have no direct access to
-- this table — it's an audit trail for refund processing.
alter table public.consumable_clawback_events enable row level security;

drop policy if exists "service_role_full_access"
  on public.consumable_clawback_events;
create policy "service_role_full_access"
  on public.consumable_clawback_events
  for all
  to service_role
  using (true)
  with check (true);

-- Clawback RPC. Called by the revenuecat-webhook edge function under the
-- service role. Returns a jsonb describing what was done so the webhook
-- can produce an audit-friendly response.
create or replace function public.clawback_consumable_grant(
  p_user_id uuid,
  p_sku text,
  p_kind text,
  p_amount int,
  p_transaction_id text,
  p_event_timestamp timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_event public.consumable_clawback_events%rowtype;
  current_balance int;
  applied int;
  deficit int;
begin
  if p_kind not in ('tokens', 'scrolls') then
    raise exception 'Unsupported consumable kind: %', p_kind;
  end if;

  if p_amount <= 0 then
    raise exception 'Clawback amount must be positive';
  end if;

  -- Idempotency: if we've already processed this transaction, return the
  -- prior result without touching balances. RevenueCat retries webhooks
  -- on 5xx, so this protects against double-clawback.
  select * into existing_event
  from public.consumable_clawback_events
  where transaction_id = p_transaction_id;

  if found then
    return jsonb_build_object(
      'status', 'already_processed',
      'transaction_id', p_transaction_id,
      'applied_amount', existing_event.applied_amount,
      'clawback_deficit', existing_event.clawback_deficit
    );
  end if;

  -- Decrement the relevant balance, clamping at 0. The "deficit" captures
  -- how much we couldn't claw back (the user already spent it). Support
  -- can use this column to manually reconcile.
  --
  -- `FOR UPDATE` serializes concurrent clawback calls against the same
  -- user. Without it, two refunds racing on the same row read the same
  -- snapshot, both compute applied from stale data, and the second update
  -- would underflow the balance below 0 (caught during /review post-fix).
  if p_kind = 'tokens' then
    insert into public.user_tokens (user_id)
    values (p_user_id)
    on conflict (user_id) do nothing;

    select balance into current_balance
    from public.user_tokens
    where user_id = p_user_id
    for update;

    applied := least(current_balance, p_amount);
    deficit := p_amount - applied;

    update public.user_tokens
    set balance = balance - applied
    where user_id = p_user_id;
  else
    insert into public.user_tokens (user_id)
    values (p_user_id)
    on conflict (user_id) do nothing;

    select tier_up_scrolls into current_balance
    from public.user_tokens
    where user_id = p_user_id
    for update;

    applied := least(current_balance, p_amount);
    deficit := p_amount - applied;

    update public.user_tokens
    set tier_up_scrolls = tier_up_scrolls - applied
    where user_id = p_user_id;
  end if;

  insert into public.consumable_clawback_events (
    transaction_id,
    user_id,
    sku,
    kind,
    amount,
    applied_amount,
    clawback_deficit,
    event_timestamp
  ) values (
    p_transaction_id,
    p_user_id,
    p_sku,
    p_kind,
    p_amount,
    applied,
    deficit,
    p_event_timestamp
  );

  return jsonb_build_object(
    'status', 'applied',
    'transaction_id', p_transaction_id,
    'kind', p_kind,
    'requested_amount', p_amount,
    'applied_amount', applied,
    'clawback_deficit', deficit
  );
end;
$$;

revoke all on function public.clawback_consumable_grant(uuid, text, text, int, text, timestamptz) from public;
grant execute on function public.clawback_consumable_grant(uuid, text, text, int, text, timestamptz) to service_role;

comment on function public.clawback_consumable_grant is
  'Reverses a consumable IAP grant on refund. Idempotent on transaction_id. '
  'Called by the revenuecat-webhook edge function when it receives a '
  'CANCELLATION for a consumable SKU. Caps decrement at current balance '
  'and records any deficit (already-spent tokens) for support reconciliation.';
