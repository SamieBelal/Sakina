-- Promotes every Gold card the calling user owns to Emerald, in one atomic
-- statement. Premium is judged SERVER-SIDE (never trusts a client boolean),
-- reusing the same predicate as repair_streak_paid: RC entitlement via webhook
-- (has_active_premium_entitlement) OR any active *_premium_until grant.
-- Idempotent: once no Gold rows remain it returns an empty set. Returns the
-- name_ids that were promoted so the client can mark those tiles "unseen".
create or replace function public.backfill_emerald_cards()
returns setof int
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    return;
  end if;

  if not (
    public.has_active_premium_entitlement(uid)
    or exists (
      select 1 from public.user_profiles p
      where p.id = uid
        and (p.referral_premium_until > now()
          or p.gift_premium_until   > now()
          or p.trial_premium_until  > now())
    )
  ) then
    return; -- not premium: no-op
  end if;

  return query
    update public.user_card_collection
       set tier = 'emerald'
     where user_id = uid
       and tier = 'gold'
    returning name_id;
end;
$$;

revoke execute on function public.backfill_emerald_cards() from public, anon;
grant  execute on function public.backfill_emerald_cards() to authenticated;
