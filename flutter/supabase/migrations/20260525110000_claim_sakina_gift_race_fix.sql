-- ---------------------------------------------------------------------------
-- claim_sakina_gift race fix.
--
-- The original RPC in 20260514100000_ramadan_gifts.sql did a non-atomic
-- SELECT-then-INSERT to enforce idempotency. Two concurrent calls (double-tap
-- on the Accept button, two devices, retried network call) could both observe
-- "not found" and both attempt INSERT. The (user_id, occasion_id) primary key
-- protects correctness — the second INSERT raises unique_violation — but the
-- RPC then propagates the exception instead of returning the idempotent
-- `reused=true` payload, and the user sees the snackbar "couldn't accept the
-- gift just now" on a race that should have been silent.
--
-- Fix: INSERT ... ON CONFLICT DO NOTHING RETURNING. If the insert wins, we
-- get the new row's timestamps back and update user_profiles.gift_premium_until.
-- If the insert loses (conflict), we re-SELECT the existing row and return
-- reused=true. No exception path on race; no double-insert.
-- ---------------------------------------------------------------------------

create or replace function public.claim_sakina_gift(p_user uuid, p_occasion text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_occ        public.islamic_occasions%rowtype;
  v_granted_at timestamptz;
  v_expires_at timestamptz;
begin
  if auth.uid() is null or auth.uid() <> p_user then
    return jsonb_build_object('granted', false, 'reason', 'unauthorized');
  end if;

  select * into v_occ from public.islamic_occasions where id = p_occasion;
  if not found then
    return jsonb_build_object('granted', false, 'reason', 'unknown_occasion');
  end if;

  if now() < v_occ.starts_at or now() > v_occ.ends_at then
    return jsonb_build_object('granted', false, 'reason', 'outside_window');
  end if;

  -- Atomic insert-or-skip. ON CONFLICT keeps the older row's timestamps
  -- intact (no double 7-day extension on re-claim).
  insert into public.sakina_gifts(user_id, occasion_id, granted_at, expires_at)
  values (p_user, p_occasion, now(), now() + interval '7 days')
  on conflict (user_id, occasion_id) do nothing
  returning granted_at, expires_at into v_granted_at, v_expires_at;

  if v_granted_at is not null then
    -- Fresh claim: mirror to user_profiles for cheap premium gate. GREATEST
    -- coalesce so a previously-granted longer window doesn't regress.
    update public.user_profiles
       set gift_premium_until = greatest(coalesce(gift_premium_until, now()), v_expires_at)
     where id = p_user;

    return jsonb_build_object(
      'granted', true,
      'granted_at', v_granted_at,
      'expires_at', v_expires_at,
      'reused', false
    );
  end if;

  -- Conflict: an existing row blocked the insert. Read it back.
  select granted_at, expires_at into v_granted_at, v_expires_at
    from public.sakina_gifts
   where user_id = p_user and occasion_id = p_occasion;

  return jsonb_build_object(
    'granted', true,
    'granted_at', v_granted_at,
    'expires_at', v_expires_at,
    'reused', true
  );
end
$$;

revoke execute on function public.claim_sakina_gift(uuid, text) from anon;
