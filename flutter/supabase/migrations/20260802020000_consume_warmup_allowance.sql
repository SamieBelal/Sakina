-- An ATOMIC server-side warmup decrement, replacing a client-computed absolute.
--
-- THE BUG. `GatingService._decrementWarmup` read the LOCAL cached counter,
-- computed `next = current - 1` on the device, and pushed that literal absolute
-- via a raw upsert. The guard trigger on these columns
-- (20260510200915_lock_freemium_gating_fields.sql) only blocks an INCREASE, so
-- the write sails through — a decrement is exactly what it is designed to
-- permit.
--
-- Two devices each holding a stale `3` therefore both compute `3 - 1 = 2` and
-- both push `2`. Two real AI calls are consumed and one is recorded.
--
-- AND IT DOES NOT SELF-HEAL. `hydrateFromProfile` overwrites the local counter
-- with the server value unconditionally, so both devices then adopt the
-- server's `2`. The lost use is permanent: one leaked use per race, not a
-- transient blip. Under `reel_v1`'s 3-use lifetime warmup that is a third of
-- the budget, where against legacy's 10 it was a rounding error — which is why
-- this stopped being tolerable at exactly this release.
--
-- The shape here is deliberately identical to `consume_weekly_allowance`
-- (20260727100200): SELECT … FOR UPDATE, no write on the rejected path, a
-- jsonb `{allowed, remaining}` result. The two allowances sitting side by side
-- with different concurrency stories was itself part of how this survived
-- review for so long.
--
-- ─────────────────────────────────────────────────────────────────────────
-- BACKWARDS COMPATIBILITY — this migration is PURELY ADDITIVE.
--
--   * No schema change. The three `warmup_*_remaining` columns already exist
--     and keep their current values; nothing is backfilled or rewritten.
--   * No trigger change. The decrement-only guard is untouched and still
--     applies to every other writer.
--   * No behaviour change for anyone. Nothing calls this function until a
--     client is shipped that does, so every currently-installed build keeps
--     working exactly as it does today.
--
-- It is therefore safe to apply BEFORE the 1.3.0 release, and doing so is
-- preferred: it decouples the server change from the release, and the client
-- ships with the correct path already live.
--
-- KNOWN LIMIT, stated rather than implied: the old absolute-push path lives in
-- every already-shipped binary forever. This closes the race
-- new-client-to-new-client only. An old device racing a new one still loses a
-- decrement until that user updates. Strictly better, never worse — but not a
-- retirement of the bug on the day it lands.
-- ─────────────────────────────────────────────────────────────────────────

create or replace function public.consume_warmup_allowance(p_feature text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid       uuid := auth.uid();
  v_remaining int;
begin
  if v_uid is null then
    raise exception 'consume_warmup_allowance: not authenticated'
      using errcode = 'insufficient_privilege';
  end if;

  -- All three gated features carry a warmup, unlike the weekly pool which
  -- excludes discover_name. Validated rather than defaulted so a typo fails
  -- loudly instead of silently decrementing the wrong budget.
  if p_feature not in ('reflect', 'built_dua', 'discover_name') then
    raise exception 'consume_warmup_allowance: invalid feature %', p_feature
      using errcode = 'check_violation';
  end if;

  -- FOR UPDATE is the entire point: it serialises two devices arriving at the
  -- same instant, which the client-side read-compute-push could not.
  select case p_feature
           when 'reflect'       then warmup_reflect_remaining
           when 'built_dua'     then warmup_built_dua_remaining
           when 'discover_name' then warmup_discover_name_remaining
         end
  into v_remaining
  from public.user_profiles
  where id = v_uid
  for update;

  if not found then
    raise exception 'consume_warmup_allowance: no profile row'
      using errcode = 'no_data_found';
  end if;

  -- Already spent. NO WRITE on the rejected path — same posture as the weekly
  -- pool, so a refused call cannot stamp anything or move a counter.
  if coalesce(v_remaining, 0) <= 0 then
    return jsonb_build_object('allowed', false, 'remaining', 0);
  end if;

  v_remaining := v_remaining - 1;

  update public.user_profiles
  set warmup_reflect_remaining =
        case when p_feature = 'reflect'
             then v_remaining else warmup_reflect_remaining end,
      warmup_built_dua_remaining =
        case when p_feature = 'built_dua'
             then v_remaining else warmup_built_dua_remaining end,
      warmup_discover_name_remaining =
        case when p_feature = 'discover_name'
             then v_remaining else warmup_discover_name_remaining end
  where id = v_uid;

  return jsonb_build_object('allowed', true, 'remaining', v_remaining);
end
$$;

comment on function public.consume_warmup_allowance(text) is
  'Atomically spends one warmup use for the calling user. Returns '
  '{allowed, remaining}. Replaces a client-computed absolute that two devices '
  'could each push identically, leaking one real AI use per race. Additive: '
  'no schema or trigger change, and no currently-shipped client calls it.';

revoke all on function public.consume_warmup_allowance(text) from public;
grant execute on function public.consume_warmup_allowance(text) to authenticated;
