-- equip_cosmetic: widen the ownership gate to the two classes of item that are
-- legitimately equippable but are NEVER rows in user_cosmetics.
--
-- The 20260726000000 gate was `exists(user_cosmetics row)` only. That rejected:
--
--   1. The always-owned catalog DEFAULTS. 'lantern_skin'/'classic_gold' and
--      'backdrop'/'default' are owned by convention, not by inventory row — the
--      client models them that way (CosmeticsState.owns in
--      lib/services/cosmetics_service.dart) and the user_profiles.equipped_*
--      columns default to exactly these values. With the old gate there was NO
--      path back to the default lantern once a user equipped anything else.
--
--   2. PREMIUM-EXCLUSIVE items (e.g. 'ramadan_royal') while premium is active.
--      Per the locked ruling these are equippable-while-active and must NEVER
--      be converted to permanent ownership, so they are deliberately absent
--      from user_cosmetics. The old gate made the marquee premium perk
--      entirely non-functional: the wardrobe offered Equip and the server threw.
--
-- Everything else is unchanged: SECURITY DEFINER, pinned search_path, the
-- auth.uid() null check, the guard GUC around the user_profiles write, the
-- error message, the return shape, and the grants.
create or replace function public.equip_cosmetic(p_item_type text, p_item_id text)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  -- The always-owned default for each slot. These literals MIRROR the
  -- user_profiles.equipped_lantern_skin / equipped_backdrop column defaults
  -- (20260726000000) and the client's always-owned convention. If either
  -- column default ever changes, change these with it.
  c_default_lantern_skin constant text := 'classic_gold';
  c_default_backdrop     constant text := 'default';
  v_allowed boolean := false;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;

  if exists (select 1 from public.user_cosmetics
             where user_id=v_uid and item_type=p_item_type and item_id=p_item_id) then
    -- (a) Owned outright — unchanged behavior.
    v_allowed := true;
  elsif (p_item_type = 'lantern_skin' and p_item_id = c_default_lantern_skin)
     or (p_item_type = 'backdrop'     and p_item_id = c_default_backdrop) then
    -- (b) The slot's catalog default: always equippable, no inventory row.
    v_allowed := true;
  elsif exists (select 1 from public.cosmetic_catalog
                where item_type=p_item_type and item_id=p_item_id
                  and is_premium_exclusive and active) then
    -- (c) Premium-exclusive while premium is ACTIVE. This branch deliberately
    -- does NOT insert into user_cosmetics — equipping a perk must never mint
    -- permanent ownership.
    --
    -- The premium test is the UNION of PurchaseService.isPremium()'s FOUR
    -- sources: RevenueCat subscription entitlement, gift, referral, and
    -- reverse-trial. has_active_premium_entitlement() alone counts
    -- SUBSCRIPTIONS ONLY, so using it by itself would silently reject
    -- gift / referral / trial premium users and reproduce, for that cohort,
    -- the exact bug this migration fixes. Any divergence between this
    -- expression and the client's isPremium() breaks equip for whichever
    -- cohort falls through the gap — keep the two in sync.
    select public.has_active_premium_entitlement(v_uid)
        or coalesce(p.gift_premium_until,     '-infinity'::timestamptz) > now()
        or coalesce(p.referral_premium_until, '-infinity'::timestamptz) > now()
        or coalesce(p.trial_premium_until,    '-infinity'::timestamptz) > now()
      into v_allowed
      from public.user_profiles p
     where p.id = v_uid;
    -- No profile row (or a null from the OR chain) is NOT premium.
    v_allowed := coalesce(v_allowed, false);
  end if;

  if not v_allowed then raise exception 'cannot equip unowned item'; end if;

  perform set_config('app.cosmetics_rpc','on', true);
  if p_item_type = 'lantern_skin' then
    update public.user_profiles set equipped_lantern_skin=p_item_id where id=v_uid;
  elsif p_item_type = 'backdrop' then
    update public.user_profiles set equipped_backdrop=p_item_id where id=v_uid;
  else raise exception 'unknown item_type %', p_item_type; end if;
  return true;
end $$;

revoke execute on function public.equip_cosmetic(text,text) from public, anon;
grant  execute on function public.equip_cosmetic(text,text) to authenticated;
