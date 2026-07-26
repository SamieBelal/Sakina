-- À-la-carte cosmetic IAP grant (spec §13 item 4 — net-new non-consumable path).
--
-- Grants PERMANENT skin ownership after a RevenueCat non-consumable purchase.
-- This is distinct from premium-exclusive/subscriber-perk skins (which are
-- equippable-while-premium and never converted to ownership) and from Noor
-- unlocks (unlock_cosmetic). Only rows that are genuinely à-la-carte purchasable
-- — active, NOT premium-exclusive, with a matching iap_product_id — are grantable.
--
-- SECURITY (webhook-only design): this RPC is service_role-only. It binds
-- ownership to the PASSED p_user_id (the RC app_user_id), NEVER auth.uid().
-- An earlier draft granted TO authenticated bound to auth.uid(), which let any
-- logged-in user self-grant a paid skin for free (product ids are world-readable;
-- the only gate was a catalog match) AND was unusable by the webhook (auth.uid()
-- is null under service_role). This mirrors clawback_consumable_grant's
-- service-role-only + explicit-user pattern. NO client calls this — the client
-- restore path re-triggers RevenueCat, which re-fires the transaction to the
-- webhook, which grants under the service role.
--
-- Idempotency: a ledger keyed on the store transaction id (mirroring noor_grants
-- / consumable_clawback_events) makes a webhook retry OR an RC re-fire a safe
-- no-op. This is the seam that makes Lane B's restore-reconcile safe (DEP-2).
-- Ownership itself is also ON CONFLICT DO NOTHING on the user_cosmetics PK,
-- mirroring unlock_cosmetic.
--
-- I1 (refund-safety): the ledger records created_inventory — whether THIS grant
-- actually inserted the user_cosmetics row (vs. the user already owning the skin
-- via Noor/milestone). Task 2's clawback only revokes ownership when
-- created_inventory = true, so a refund never removes a skin the user earned
-- another way.
--
-- Product->item mapping is server-authoritative via cosmetic_catalog.iap_product_id
-- (never a client map). A partial unique index guarantees one product id maps to
-- at most one catalog row, so the reverse lookup is unambiguous.
--
-- Guard: sets the app.cosmetics_rpc GUC exactly like unlock_cosmetic /
-- equip_cosmetic so cosmetics_guard() permits the inventory write, then resets
-- it to 'off' after the write so the flag doesn't leak to the rest of the
-- transaction (N1, defense-in-depth).

-- Ledger / idempotency table. Keyed on the RC transaction id. A replay finds
-- the existing row and returns already_owned without re-inserting inventory.
-- `created_inventory` records whether THIS grant inserted the user_cosmetics row
-- (I1). `revoked_at` is set by clawback_cosmetic_iap (Task 2) on refund.
create table if not exists public.cosmetic_iap_grants (
  transaction_id    text primary key,
  user_id           uuid not null references auth.users(id) on delete cascade,
  item_type         text not null,
  item_id           text not null,
  product_id        text not null,
  created_inventory boolean not null default false,
  granted_at        timestamptz not null default now(),
  revoked_at        timestamptz
);

create index if not exists cosmetic_iap_grants_user_id_idx
  on public.cosmetic_iap_grants(user_id);

-- One product id maps to at most one catalog row (guards the reverse lookup).
-- Partial (non-null only) so the many null iap_product_id rows don't collide.
create unique index if not exists cosmetic_catalog_iap_product_id_uq
  on public.cosmetic_catalog(iap_product_id)
  where iap_product_id is not null;

-- RLS: user may SELECT their own ledger rows (parity with user_cosmetics_read);
-- no insert/update/delete policy → all writes are via the SECURITY DEFINER RPCs.
alter table public.cosmetic_iap_grants enable row level security;
drop policy if exists cosmetic_iap_grants_read on public.cosmetic_iap_grants;
create policy cosmetic_iap_grants_read on public.cosmetic_iap_grants
  for select using ((select auth.uid()) = user_id);

-- grant_cosmetic_iap: grant permanent à-la-carte skin ownership after a receipt-
-- verified purchase, to an explicit p_user_id. service_role-only. Idempotent on
-- p_transaction_id. Returns the Lane-B contract shape { granted, already_owned,
-- item_id }.
create or replace function public.grant_cosmetic_iap(
  p_user_id text,
  p_item_id text,
  p_product_id text,
  p_transaction_id text
)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid;
  v_ledger public.cosmetic_iap_grants%rowtype;
  v_item_type text;
  v_created boolean;
begin
  if p_user_id is null or length(trim(p_user_id)) = 0 then
    raise exception 'missing user id';
  end if;
  v_uid := p_user_id::uuid;  -- validates the uuid shape; bad input raises.
  if p_transaction_id is null or length(trim(p_transaction_id)) = 0 then
    raise exception 'missing transaction id';
  end if;

  -- Idempotency: a prior grant for this transaction returns already_owned
  -- WITHOUT touching inventory (webhook retry / RC re-fire).
  select * into v_ledger from public.cosmetic_iap_grants
    where transaction_id = p_transaction_id;
  if found then
    return jsonb_build_object(
      'granted', false,
      'already_owned', true,
      'item_id', v_ledger.item_id);
  end if;

  -- Server-authoritative verification: the (item_id, product_id) pair must be a
  -- genuinely à-la-carte purchasable catalog row — active, NOT premium-exclusive,
  -- with a matching non-null iap_product_id. A Noor-only row (null iap_product_id)
  -- never matches; a premium-exclusive row is excluded; an unknown/mismatched
  -- product id finds no row. All rejections land here.
  select item_type into v_item_type from public.cosmetic_catalog
    where item_id = p_item_id
      and iap_product_id = p_product_id
      and iap_product_id is not null
      and not is_premium_exclusive
      and active;
  if v_item_type is null then
    raise exception 'item not IAP-purchasable or product/item mismatch';
  end if;

  -- Insert ownership under the guard flag. ON CONFLICT DO NOTHING mirrors
  -- unlock_cosmetic — a user who already owns the skin (e.g. earned it another
  -- way) keeps their single row. The RETURNING probe tells us whether THIS grant
  -- created the row (I1): if a row comes back, we inserted it; if the CTE is
  -- empty, ON CONFLICT fired and the user already owned the skin.
  perform set_config('app.cosmetics_rpc', 'on', true);
  with ins as (
    insert into public.user_cosmetics(user_id, item_type, item_id, acquired_via)
      values (v_uid, v_item_type, p_item_id, 'iap')
      on conflict (user_id, item_type, item_id) do nothing
    returning 1
  )
  select exists (select 1 from ins) into v_created;
  -- N1: reset the guard flag so it doesn't leak to the rest of the transaction.
  perform set_config('app.cosmetics_rpc', 'off', true);

  -- Record the ledger row (dedup anchor + created_inventory for I1). A concurrent
  -- replay collides on the PK and raises unique_violation → translate to
  -- already_owned.
  begin
    insert into public.cosmetic_iap_grants(
      transaction_id, user_id, item_type, item_id, product_id, created_inventory)
      values (p_transaction_id, v_uid, v_item_type, p_item_id, p_product_id, v_created);
  exception when unique_violation then
    return jsonb_build_object(
      'granted', false, 'already_owned', true, 'item_id', p_item_id);
  end;

  -- granted reflects whether this call created inventory; a pre-owned skin
  -- returns already_owned=true (I1) even though the ledger row is new.
  return jsonb_build_object(
    'granted', v_created,
    'already_owned', not v_created,
    'item_id', p_item_id);
end $$;

revoke all on function public.grant_cosmetic_iap(text,text,text,text) from public, anon, authenticated;
-- service_role-only: the webhook grant path (index.ts) is the ONLY caller. No
-- client may execute this — the client restore path re-triggers RevenueCat,
-- which re-fires the transaction to the webhook (mirrors clawback_consumable_grant).
grant execute on function public.grant_cosmetic_iap(text,text,text,text) to service_role;

comment on function public.grant_cosmetic_iap is
  'Grants permanent à-la-carte skin ownership to an explicit p_user_id after a '
  'receipt-verified non-consumable purchase. service_role-only (webhook path). '
  'Idempotent on transaction_id. Records created_inventory (whether this grant '
  'inserted the row) so a refund only revokes ownership it created. Verifies '
  'product->item against cosmetic_catalog.iap_product_id (à-la-carte only; rejects '
  'premium-exclusive / Noor-only / unknown SKUs). Sets+resets app.cosmetics_rpc '
  'for the guard. Returns { granted, already_owned, item_id } (Lane B contract).';
