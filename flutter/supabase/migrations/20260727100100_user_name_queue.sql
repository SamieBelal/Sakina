-- One Ship W1 / Migration B — user_name_queue + seed/unseal RPCs
-- (docs/superpowers/plans/2026-07-26-one-ship-01-data-layer.md §Migration B)
--
-- The 7-Name acquisition-promise queue: the onboarding pair at positions 1-2,
-- aspiration-derived Names at 3-7. One unseal per user-local day, server-
-- gated. SELECT via RLS; ALL writes via the two RPCs below (no write
-- policies on purpose). Anon-session support cut per plan-of-record §V6.8.E.
--
-- Security posture (review record F3/F4):
--  * unseal timing = server authority; a 20-hour wall-clock floor makes the
--    cadence immune to timezone manipulation (the local-day check is UX only).
--  * the client chooses WHICH Names (accepted residual risk — matches the
--    shipped discoverName posture; Name choice carries no tier/economy value).
--    BINDING for W2/W3: unseal must never directly grant tokens/XP/tier.

create table if not exists public.user_name_queue (
  user_id     uuid not null references auth.users(id) on delete cascade,
  position    int  not null check (position between 1 and 7),
  name_id     int  not null references public.collectible_names(id),
  unsealed_at timestamptz,
  created_at  timestamptz not null default now(),
  primary key (user_id, position),
  unique (user_id, name_id)
);

alter table public.user_name_queue enable row level security;

drop policy if exists "Users can view own name queue" on public.user_name_queue;
create policy "Users can view own name queue" on public.user_name_queue
  for select to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- seed_name_queue: one-shot idempotency by refusal — the queue IS the
-- promise; it is set exactly once at onboarding. Concurrent double-seed is
-- additionally PK-protected: the second transaction aborts on
-- (user_id, position). Do NOT soften with ON CONFLICT DO NOTHING — that
-- would silently allow a partial reseed.
-- ---------------------------------------------------------------------------

create or replace function public.seed_name_queue(p_name_ids int[])
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid      uuid := auth.uid();
  v_n        int  := coalesce(cardinality(p_name_ids), 0);
  v_distinct int;
begin
  if v_uid is null then
    raise exception 'seed_name_queue: not authenticated'
      using errcode = 'insufficient_privilege';
  end if;

  -- coalesce matters: array_length('{}') is NULL and `null between` never fires
  if v_n < 2 or v_n > 7 then
    raise exception 'seed_name_queue: expected 2-7 name ids, got %', v_n
      using errcode = 'check_violation';
  end if;

  select count(distinct id) into v_distinct from unnest(p_name_ids) as t(id);
  if v_distinct <> v_n then
    raise exception 'seed_name_queue: duplicate name ids'
      using errcode = 'check_violation';
  end if;

  if exists (select 1 from public.user_name_queue q where q.user_id = v_uid) then
    raise exception 'seed_name_queue: queue already seeded'
      using errcode = 'check_violation';
  end if;

  -- position 1 = the Name met at the onboarding reveal itself → born unsealed;
  -- junk/unknown ids abort on the collectible_names FK.
  insert into public.user_name_queue (user_id, position, name_id, unsealed_at)
  select v_uid, t.ord, t.id, case when t.ord = 1 then now() else null end
  from unnest(p_name_ids) with ordinality as t(id, ord);
end
$$;

-- ---------------------------------------------------------------------------
-- unseal_next_name: returns the row unsealed "today" (idempotent per user-
-- local day), unsealing the lowest sealed position when eligible. Empty
-- result = queue exhausted.
-- ---------------------------------------------------------------------------

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
  select max(q.unsealed_at) into v_max_unsealed
  from public.user_name_queue q where q.user_id = v_uid;

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

-- Grants: functions default-grant EXECUTE to PUBLIC — revoke wide, grant narrow
-- (repo convention; see 20260616204630 §grants and the two anon-revoke
-- cleanup migrations).
revoke execute on function public.seed_name_queue(int[]) from public, anon;
revoke execute on function public.unseal_next_name() from public, anon;
grant execute on function public.seed_name_queue(int[]) to authenticated;
grant execute on function public.unseal_next_name() to authenticated;
