-- À-la-carte cosmetic IAP refund clawback (spec §13 item 4 — refund path).
--
-- Mirrors clawback_consumable_grant: service-role only, idempotent on the
-- transaction id. On a RevenueCat CANCELLATION for a skin SKU the webhook calls
-- this to REVOKE ownership — but ONLY the ownership this IAP grant created.
--
-- I1 (refund-safety): the clawback deletes the user_cosmetics row and resets the
-- equipped slot ONLY when the ledger row's created_inventory = true (this grant
-- inserted the ownership row). If created_inventory = false — the user already
-- owned the skin via Noor/milestone before the IAP — the clawback revokes
-- NOTHING (the user keeps the separately-earned skin) but still marks the ledger
-- revoked_at. Pinned by cosmetic_iap_clawback_test.sql (subtests 10, 11).
--
-- Design ruling: an equipped-then-refunded skin falls back to classic_gold (the
-- equipped_lantern_skin column default) — the server keeps no "previous equip"
-- history, and classic_gold is always owned, so this is the single-premium-
-- definition-safe reset. Pinned by cosmetic_iap_clawback_test.sql.
--
-- The equipped-slot write goes through the app.cosmetics_rpc guard flag, exactly
-- like equip_cosmetic, and (N1) resets it to 'off' after so the flag doesn't
-- leak to the rest of the transaction. The user_cosmetics delete is a
-- service-role SECURITY DEFINER write (RLS has no delete policy, but SECURITY
-- DEFINER owner bypasses RLS; the guard trigger is on user_profiles only, so the
-- delete needs no flag).
create or replace function public.clawback_cosmetic_iap(
  p_transaction_id text,
  p_event_timestamp timestamptz
)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_ledger public.cosmetic_iap_grants%rowtype;
begin
  if p_transaction_id is null or length(trim(p_transaction_id)) = 0 then
    raise exception 'missing transaction id';
  end if;

  -- Row-lock the ledger row so a racing redelivery serializes.
  select * into v_ledger from public.cosmetic_iap_grants
    where transaction_id = p_transaction_id
    for update;

  -- Never granted here → safe no-op (a refund for a SKU we didn't grant, or a
  -- transaction we never saw).
  if not found then
    return jsonb_build_object('status', 'not_found',
                              'transaction_id', p_transaction_id);
  end if;

  -- Already revoked → idempotent (RC retries CANCELLATION on 5xx).
  if v_ledger.revoked_at is not null then
    return jsonb_build_object('status', 'already_processed',
                              'transaction_id', p_transaction_id);
  end if;

  -- I1: only revoke ownership THIS grant created. If the user already owned the
  -- skin another way (created_inventory=false), leave their inventory + equipped
  -- slot untouched — but still mark the ledger revoked below.
  if v_ledger.created_inventory then
    -- Remove ownership.
    delete from public.user_cosmetics
      where user_id = v_ledger.user_id
        and item_type = v_ledger.item_type
        and item_id = v_ledger.item_id;

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
  -- when created_inventory=false and nothing was revoked.
  update public.cosmetic_iap_grants
     set revoked_at = coalesce(p_event_timestamp, now())
   where transaction_id = p_transaction_id;

  return jsonb_build_object(
    'status', 'revoked',
    'transaction_id', p_transaction_id,
    'item_id', v_ledger.item_id);
end $$;

revoke all on function public.clawback_cosmetic_iap(text, timestamptz) from public, anon, authenticated;
-- Refunds are driven only by the webhook under the service role.
grant execute on function public.clawback_cosmetic_iap(text, timestamptz) to service_role;

comment on function public.clawback_cosmetic_iap is
  'Reverses an à-la-carte skin IAP grant on refund. Idempotent on transaction_id. '
  'Deletes the user_cosmetics row; if the refunded skin was equipped, resets the '
  'equipped slot to the default (classic_gold / default). Marks the ledger '
  'revoked_at. Called by the revenuecat-webhook edge function on a CANCELLATION '
  'for a skin SKU.';
