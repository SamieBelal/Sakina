-- À-la-carte cosmetic IAP refund edge cases: I-1, I-2, N-1.
--
-- Source: "Pre-store-enablement follow-ups" in
-- docs/superpowers/plans/2026-07-25-lantern-cosmetics-01b-iap-grant-webhook.md.
-- All three are P1 — they must close before the skin SKUs are enabled on the
-- store, because each either destroys ownership the user legitimately holds or
-- silently drops a refund. Pinned by supabase/tests/cosmetic_iap_refund_edges_test.sql.
--
-- I-1  `created_inventory` records ROW CREATION, not entitlement PROVENANCE.
--      clawback_cosmetic_iap deleted the user_cosmetics row whenever the matched
--      ledger row had created_inventory = true, which breaks two ways:
--        (a) the IAP created the row, the user later earns the same skin via
--            Noor/milestone → refunding the IAP deletes the earned ownership;
--        (b) IAP-A created the row, IAP-B for the SAME skin recorded
--            created_inventory=false → refunding A deletes ownership even though
--            B is paid for and unrefunded.
--      The delete is now PROVENANCE-based instead: ownership is removed only
--      when no OTHER unrevoked IAP grant covers the same (user, item) AND the
--      user_cosmetics row is itself iap-provenance.
--
--      DELIBERATE DEVIATION from the letter of the review note, which proposed
--      keeping `created_inventory` as a precondition and merely ADDING the two
--      skip conditions. That leaves sequence (b) half-fixed: refund A (skipped,
--      B stands) then refund B (created_inventory=false → also skipped) and the
--      user keeps a skin whose every purchase was refunded. Dropping
--      created_inventory as a gate closes that while still honouring both stated
--      skip conditions, and it keeps cosmetic_iap_clawback_test's subtest 10
--      green (that fixture pre-owns via 'noor', so the provenance guard fires).
--
--      `revoked_inventory` is added to the ledger so N-1 can restore exactly
--      what a given clawback removed, rather than re-deriving it from
--      created_inventory (which, post-I-1, no longer implies the delete ran).
--
-- I-2  A refund arriving BEFORE its grant was permanently lost: the clawback
--      found no ledger row, returned not_found and wrote NOTHING, so a later
--      grant retry (RevenueCat redelivering the purchase) re-granted the skin
--      after the refund. The clawback now writes a TOMBSTONE ledger row keyed by
--      the refunded transaction id, and the grant path honours it. Clawback and
--      grant become order-independent. The returned status stays 'not_found' —
--      the webhook does not branch on it and cosmetic_iap_clawback_test pins it
--      — with an added `tombstoned` flag for observability.
--
-- N-1  REFUND_REVERSED (Apple reinstating a refunded purchase) had no handler,
--      so ownership stayed revoked. Re-running the grant does NOT fix it: the
--      revoked ledger row short-circuits grant_cosmetic_iap. reinstate_cosmetic_iap
--      is therefore a dedicated path.

-- ---------------------------------------------------------------------------
-- Ledger schema: tombstones + revoked-inventory bookkeeping.
-- ---------------------------------------------------------------------------

-- A tombstone is a refund we received before (or without) its grant, so the
-- user/item/product may be unknown. Those columns become nullable, and a CHECK
-- keeps them mandatory for every REAL grant row.
alter table public.cosmetic_iap_grants
  add column if not exists tombstone boolean not null default false,
  add column if not exists revoked_inventory boolean not null default false;

alter table public.cosmetic_iap_grants alter column user_id    drop not null;
alter table public.cosmetic_iap_grants alter column item_type  drop not null;
alter table public.cosmetic_iap_grants alter column item_id    drop not null;
alter table public.cosmetic_iap_grants alter column product_id drop not null;

alter table public.cosmetic_iap_grants
  drop constraint if exists cosmetic_iap_grants_identity_ck;
alter table public.cosmetic_iap_grants
  add constraint cosmetic_iap_grants_identity_ck check (
    tombstone or (
      user_id is not null and item_type is not null
      and item_id is not null and product_id is not null
    )
  );

-- A tombstone only ever exists to record a refund, so it is revoked by
-- construction and can never claim inventory.
alter table public.cosmetic_iap_grants
  drop constraint if exists cosmetic_iap_grants_tombstone_ck;
alter table public.cosmetic_iap_grants
  add constraint cosmetic_iap_grants_tombstone_ck check (
    not tombstone or (revoked_at is not null and created_inventory = false
                      and revoked_inventory = false)
  );

-- Supports the I-1 "is any OTHER purchase of this skin still unrevoked?" probe
-- on the refund path.
create index if not exists cosmetic_iap_grants_live_item_idx
  on public.cosmetic_iap_grants(user_id, item_type, item_id)
  where revoked_at is null;

comment on column public.cosmetic_iap_grants.tombstone is
  'True for a refund received before (or without) its grant. Blocks a later '
  'grant for the same transaction id so a redelivered purchase cannot undo the '
  'refund (I-2). Tombstones carry no inventory and are always revoked.';
comment on column public.cosmetic_iap_grants.revoked_inventory is
  'True when THIS clawback actually deleted the user_cosmetics row. Distinct '
  'from created_inventory, which only says this grant inserted it — post-I-1 the '
  'delete is provenance-gated, so the two can disagree. reinstate_cosmetic_iap '
  'restores ownership only for rows where this is true.';

-- ---------------------------------------------------------------------------
-- grant_cosmetic_iap: honour revoked ledger rows and tombstones (I-2).
-- ---------------------------------------------------------------------------
-- Only the idempotency branch changes: a ledger row whose revoked_at is set (a
-- real refund OR a tombstone) now blocks the grant and reports revoked=true
-- instead of already_owned=true. `already_owned` kept its old meaning — "the
-- user has this skin" — which was simply untrue for a refunded transaction.
-- Everything else (catalog verification, guard GUC, ON CONFLICT semantics,
-- unique_violation translation, the { granted, already_owned, item_id }
-- contract) is byte-for-byte the merged version.
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
    -- I-2: the transaction has been refunded (a real revoked grant, or a
    -- tombstone written by a refund that beat its grant). Do NOT re-grant — a
    -- RevenueCat redelivery of the purchase must not undo the refund. Only
    -- reinstate_cosmetic_iap (REFUND_REVERSED) can lift this.
    if v_ledger.revoked_at is not null then
      return jsonb_build_object(
        'granted', false,
        'already_owned', false,
        'revoked', true,
        'item_id', coalesce(v_ledger.item_id, p_item_id));
    end if;
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

comment on function public.grant_cosmetic_iap is
  'Grants permanent à-la-carte skin ownership to an explicit p_user_id after a '
  'receipt-verified non-consumable purchase. service_role-only (webhook path). '
  'Idempotent on transaction_id. Refuses to grant when the ledger row for that '
  'transaction is revoked or a tombstone (I-2), returning revoked=true. Records '
  'created_inventory so a refund can reason about what it created. Verifies '
  'product->item against cosmetic_catalog.iap_product_id (à-la-carte only; rejects '
  'premium-exclusive / Noor-only / unknown SKUs). Sets+resets app.cosmetics_rpc '
  'for the guard. Returns { granted, already_owned, item_id } (Lane B contract).';

-- ---------------------------------------------------------------------------
-- clawback_cosmetic_iap: provenance-gated delete (I-1) + tombstone (I-2).
-- ---------------------------------------------------------------------------
-- The signature grows three OPTIONAL identity params so a tombstone can be
-- attributed to a user/item when the webhook knows them (a CANCELLATION always
-- carries app_user_id and product_id). They are used ONLY to populate the
-- tombstone: when a real ledger row exists it is the sole source of truth for
-- who owns what, so nothing caller-supplied can widen a revocation.
--
-- Adding defaulted params would make the old 2-arg call ambiguous, so the 2-arg
-- form is dropped and recreated. Positional 2-arg callers (the existing pgTAP
-- suites) and PostgREST named-argument callers both keep working.
drop function if exists public.clawback_cosmetic_iap(text, timestamptz);

create or replace function public.clawback_cosmetic_iap(
  p_transaction_id text,
  p_event_timestamp timestamptz,
  p_user_id text default null,
  p_item_id text default null,
  p_product_id text default null
)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_ledger public.cosmetic_iap_grants%rowtype;
  v_other_unrevoked boolean;
  v_iap_provenance boolean;
  v_revoked_inventory boolean := false;
  v_tombstone_uid uuid;
begin
  if p_transaction_id is null or length(trim(p_transaction_id)) = 0 then
    raise exception 'missing transaction id';
  end if;

  -- Row-lock the ledger row so a racing redelivery serializes.
  select * into v_ledger from public.cosmetic_iap_grants
    where transaction_id = p_transaction_id
    for update;

  -- I-2: never granted here. Previously a pure no-op, which silently dropped
  -- the refund whenever it raced ahead of its grant. Leave a tombstone so the
  -- grant path (which reads this same transaction id) cannot re-grant later.
  -- ON CONFLICT DO NOTHING keeps it safe against a grant landing concurrently:
  -- if the grant won the PK, this call re-reads nothing and the next redelivery
  -- of the refund takes the ordinary revoke path.
  if not found then
    begin
      v_tombstone_uid := nullif(trim(coalesce(p_user_id, '')), '')::uuid;
    exception when invalid_text_representation then
      v_tombstone_uid := null;  -- unattributable tombstone; still blocks re-grant.
    end;

    insert into public.cosmetic_iap_grants(
      transaction_id, user_id, item_type, item_id, product_id,
      created_inventory, revoked_inventory, tombstone, revoked_at)
    values (
      p_transaction_id,
      v_tombstone_uid,
      (select item_type from public.cosmetic_catalog where item_id = p_item_id),
      nullif(trim(coalesce(p_item_id, '')), ''),
      nullif(trim(coalesce(p_product_id, '')), ''),
      false, false, true, coalesce(p_event_timestamp, now()))
    on conflict (transaction_id) do nothing;

    return jsonb_build_object('status', 'not_found',
                              'tombstoned', true,
                              'ownership_revoked', false,
                              'transaction_id', p_transaction_id);
  end if;

  -- Already revoked → idempotent (RC retries CANCELLATION on 5xx). Also the
  -- path a redelivered early refund takes once its tombstone exists.
  if v_ledger.revoked_at is not null then
    return jsonb_build_object('status', 'already_processed',
                              'ownership_revoked', false,
                              'transaction_id', p_transaction_id);
  end if;

  -- I-1: revoke ownership only when this refund leaves the user with no other
  -- claim on the skin.
  --   (i)  another IAP for the same skin is still paid for and unrevoked, or
  --   (ii) the ownership row is not iap-provenance (Noor/milestone/seasonal/
  --        premium/default) — the user earned it independently.
  -- Either way the ledger is still marked revoked below, so the refund is
  -- recorded and idempotent.
  select exists (
    select 1 from public.cosmetic_iap_grants g
     where g.user_id = v_ledger.user_id
       and g.item_type = v_ledger.item_type
       and g.item_id = v_ledger.item_id
       and g.transaction_id <> v_ledger.transaction_id
       and g.revoked_at is null
  ) into v_other_unrevoked;

  select exists (
    select 1 from public.user_cosmetics uc
     where uc.user_id = v_ledger.user_id
       and uc.item_type = v_ledger.item_type
       and uc.item_id = v_ledger.item_id
       and uc.acquired_via = 'iap'
  ) into v_iap_provenance;

  if v_iap_provenance and not v_other_unrevoked then
    delete from public.user_cosmetics
      where user_id = v_ledger.user_id
        and item_type = v_ledger.item_type
        and item_id = v_ledger.item_id;
    v_revoked_inventory := true;

    -- If the refunded skin was equipped, reset the slot to the default. Guarded
    -- write → set the RPC GUC so cosmetics_guard() permits the equipped_* update,
    -- then reset it (N1).
    if v_ledger.item_type = 'lantern_skin' then
      perform set_config('app.cosmetics_rpc', 'on', true);
      update public.user_profiles
         set equipped_lantern_skin = 'classic_gold'
       where id = v_ledger.user_id
         and equipped_lantern_skin = v_ledger.item_id;
      perform set_config('app.cosmetics_rpc', 'off', true);
    elsif v_ledger.item_type = 'backdrop' then
      perform set_config('app.cosmetics_rpc', 'on', true);
      update public.user_profiles
         set equipped_backdrop = 'default'
       where id = v_ledger.user_id
         and equipped_backdrop = v_ledger.item_id;
      perform set_config('app.cosmetics_rpc', 'off', true);
    end if;
  end if;

  -- Mark the ledger row revoked (records the refund + keeps idempotency), even
  -- when nothing was revoked. revoked_inventory records what this call actually
  -- removed so reinstate_cosmetic_iap can put back exactly that much.
  update public.cosmetic_iap_grants
     set revoked_at = coalesce(p_event_timestamp, now()),
         revoked_inventory = v_revoked_inventory
   where transaction_id = p_transaction_id;

  return jsonb_build_object(
    'status', 'revoked',
    'ownership_revoked', v_revoked_inventory,
    'transaction_id', p_transaction_id,
    'item_id', v_ledger.item_id);
end $$;

revoke all on function public.clawback_cosmetic_iap(text, timestamptz, text, text, text)
  from public, anon, authenticated;
-- Refunds are driven only by the webhook under the service role.
grant execute on function public.clawback_cosmetic_iap(text, timestamptz, text, text, text)
  to service_role;

comment on function public.clawback_cosmetic_iap is
  'Reverses an à-la-carte skin IAP grant on refund. Idempotent on transaction_id. '
  'Deletes the user_cosmetics row ONLY when no other unrevoked IAP grant covers '
  'the same (user, item) AND the ownership row is iap-provenance (I-1), so a '
  'refund can never remove a separately-earned or separately-paid-for skin; if it '
  'does delete an equipped skin the slot falls back to the default. An unmatched '
  'refund writes a TOMBSTONE ledger row (I-2) so a later grant for the same '
  'transaction cannot undo it. Called by the revenuecat-webhook edge function on '
  'a CANCELLATION for a skin SKU.';

-- ---------------------------------------------------------------------------
-- reinstate_cosmetic_iap: REFUND_REVERSED (N-1).
-- ---------------------------------------------------------------------------
-- Apple can reinstate a purchase it previously refunded. Routing that through
-- grant_cosmetic_iap does nothing — the revoked ledger row short-circuits it —
-- so reinstatement clears the revocation directly.
--
-- Deliberately does NOT restore the equipped slot: the server keeps no equip
-- history, which is the same ruling clawback_cosmetic_iap makes in the refund
-- direction. The skin returns to the wardrobe; the user re-equips it.
create or replace function public.reinstate_cosmetic_iap(
  p_transaction_id text,
  p_event_timestamp timestamptz default null
)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_ledger public.cosmetic_iap_grants%rowtype;
begin
  if p_transaction_id is null or length(trim(p_transaction_id)) = 0 then
    raise exception 'missing transaction id';
  end if;

  select * into v_ledger from public.cosmetic_iap_grants
    where transaction_id = p_transaction_id
    for update;

  -- A reversal for a transaction we never saw. Safe no-op: no tombstone is
  -- written here, because "the refund was reversed" is not evidence of a
  -- purchase — if the purchase exists, RevenueCat will deliver it and the
  -- ordinary grant path handles it.
  if not found then
    return jsonb_build_object('status', 'not_found',
                              'ownership_restored', false,
                              'transaction_id', p_transaction_id);
  end if;

  -- A tombstone means the refund beat its grant and we blocked the grant. The
  -- refund has now been reversed, so remove the block and let the redelivered
  -- purchase grant normally. There is nothing to restore — the grant never ran.
  if v_ledger.tombstone then
    delete from public.cosmetic_iap_grants where transaction_id = p_transaction_id;
    return jsonb_build_object('status', 'tombstone_cleared',
                              'ownership_restored', false,
                              'transaction_id', p_transaction_id);
  end if;

  -- Not revoked → nothing to reverse. Idempotent under RC redelivery.
  if v_ledger.revoked_at is null then
    return jsonb_build_object('status', 'not_revoked',
                              'ownership_restored', false,
                              'transaction_id', p_transaction_id);
  end if;

  -- Restore exactly what the clawback took. revoked_inventory (not
  -- created_inventory) is the right flag: post-I-1 a grant can have created the
  -- row while its refund skipped the delete, and vice versa.
  if v_ledger.revoked_inventory then
    perform set_config('app.cosmetics_rpc', 'on', true);
    insert into public.user_cosmetics(user_id, item_type, item_id, acquired_via)
      values (v_ledger.user_id, v_ledger.item_type, v_ledger.item_id, 'iap')
      on conflict (user_id, item_type, item_id) do nothing;
    perform set_config('app.cosmetics_rpc', 'off', true);
  end if;

  update public.cosmetic_iap_grants
     set revoked_at = null,
         revoked_inventory = false
   where transaction_id = p_transaction_id;

  return jsonb_build_object(
    'status', 'reinstated',
    'ownership_restored', v_ledger.revoked_inventory,
    'transaction_id', p_transaction_id,
    'item_id', v_ledger.item_id);
end $$;

revoke all on function public.reinstate_cosmetic_iap(text, timestamptz)
  from public, anon, authenticated;
-- Webhook-only, exactly like grant_cosmetic_iap / clawback_cosmetic_iap.
grant execute on function public.reinstate_cosmetic_iap(text, timestamptz) to service_role;

comment on function public.reinstate_cosmetic_iap is
  'Reverses a cosmetic IAP refund (RevenueCat REFUND_REVERSED). Clears the ledger '
  'revoked_at and re-inserts the user_cosmetics row when that clawback actually '
  'deleted one (revoked_inventory). Clearing a TOMBSTONE instead unblocks the '
  'grant path so a redelivered purchase can grant. Idempotent: an unrevoked grant '
  'returns not_revoked. Does NOT re-equip — the server keeps no equip history.';
