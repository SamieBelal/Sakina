-- unseal_next_name: scope the 20-hour wall-clock floor to position > 1.
-- (fixes "D1 is unreachable" — the W3 defect; supersedes the floor query in
--  20260727100100_user_name_queue.sql, which stays applied as-is)
--
-- ── THE DEFECT ─────────────────────────────────────────────────────────────
-- `seed_name_queue` marks position 1 unsealed AT ONBOARDING TIME (it is the
-- Name met at the onboarding reveal itself, so it is born unsealed). The floor
-- then measured `max(unsealed_at)` across ALL positions — including that one —
-- so the clock on the user's FIRST real unseal started at onboarding
-- completion rather than at their local midnight.
--
-- Onboard 21:00 Monday → position 2 could not unseal until 17:00 Tuesday.
-- Anyone who onboarded after roughly midday and came back the next morning got
-- an ordinary gacha pull instead of the Name they were promised — while the
-- copy shipped for that seal says "Sealed until tomorrow" and "You will meet
-- this Name tomorrow, when it can be its own morning."
--
-- ── WHY `position > 1` IS THE CORRECT SCOPE ────────────────────────────────
-- Position 1 is the only row born unsealed, and it was GRANTED by the seed
-- rather than EARNED by an unseal. An anti-abuse floor exists to rate-limit
-- what the RPC hands out; a row the RPC never handed out should not start its
-- clock.
--
-- "Tomorrow" is still enforced — by the per-user-local-day idempotency branch
-- above the floor, which already returns position 1 to a user who tries again
-- the same local evening. No same-day advance is possible, with or without the
-- floor. And D2 onward stays floored exactly as today, because position 2+
-- unseals do count toward `v_max_unsealed`.
--
-- The residual is one early hop on the day a user changes timezone (a local-day
-- flip forward can clear the idempotency branch before 20h have passed, once,
-- while no position > 1 is yet unsealed). That is the same bounded risk W1
-- already accepted for the weekly pool's once-ever init hop, and it self-closes
-- the moment position 2 is unsealed.
--
-- Everything else is preserved byte-for-byte: the auth check, the
-- lock-BEFORE-idempotency-read ordering (load-bearing — two concurrent calls
-- must serialize on the same rows), the safe_user_tz local-day branch, the
-- exhausted branch, the return shape, and the search_path pin.

create or replace function public.unseal_next_name()
returns table ("position" int, name_id int, unsealed_at timestamptz)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid          uuid := auth.uid();
  v_tz           text;
  v_today        date;
  v_max_unsealed timestamptz;
  v_pos          int;
begin
  if v_uid is null then
    raise exception 'unseal_next_name: not authenticated'
      using errcode = 'insufficient_privilege';
  end if;

  -- Lock BEFORE the idempotency read (review: lock-first ordering is load-
  -- bearing — two concurrent calls must serialize on the same rows).
  perform 1 from public.user_name_queue q where q.user_id = v_uid for update;

  v_tz    := public.safe_user_tz(v_uid);
  v_today := (now() at time zone v_tz)::date;

  -- Idempotent per local day: an unseal already happened "today" → return it.
  -- This is what enforces "tomorrow"; the floor below is only anti-abuse.
  return query
    select q.position, q.name_id, q.unsealed_at
    from public.user_name_queue q
    where q.user_id = v_uid
      and q.unsealed_at is not null
      and (q.unsealed_at at time zone v_tz)::date = v_today
    order by q.unsealed_at desc
    limit 1;
  if found then
    return;
  end if;

  -- 20h wall-clock floor (review F3): no timezone choice can manufacture an
  -- extra unseal — local midnights are >=20h apart for any fixed honest zone,
  -- while a tz-walk cannot beat the monotonic server clock.
  --
  -- Scoped to position > 1: position 1's timestamp is the SEED's now(), not an
  -- unseal, and counting it made the first real unseal wait 20h from
  -- onboarding instead of from local midnight (see header).
  select max(q.unsealed_at) into v_max_unsealed
  from public.user_name_queue q
  where q.user_id = v_uid and q.position > 1;

  if v_max_unsealed is not null and v_max_unsealed > now() - interval '20 hours' then
    return query
      select q.position, q.name_id, q.unsealed_at
      from public.user_name_queue q
      where q.user_id = v_uid and q.unsealed_at = v_max_unsealed
      limit 1;
    return;
  end if;

  select min(q.position) into v_pos
  from public.user_name_queue q
  where q.user_id = v_uid and q.unsealed_at is null;

  if v_pos is null then
    return; -- exhausted
  end if;

  return query
    update public.user_name_queue q
    set unsealed_at = now()
    where q.user_id = v_uid and q.position = v_pos
    returning q.position, q.name_id, q.unsealed_at;
end
$$;

-- Grants: `create or replace` retains the existing ACL, but restate it — the
-- repo convention is revoke wide, grant narrow, stated explicitly at every
-- definition site (see 20260727100100 §grants).
revoke execute on function public.unseal_next_name() from public, anon;
grant execute on function public.unseal_next_name() to authenticated;
