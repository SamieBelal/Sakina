-- One Ship W5 / Wave D.3 — make the discover-name warmup dial actually bite
-- (docs/superpowers/plans/2026-07-31-one-ship-05-gate-and-free-tier.md §6b,
--  §4.D.3; founder decision D10② in 2026-07-23-conversion-refactor…md)
--
-- WHY THIS EXISTS. `20260731090000_warmup_discover_name_size.sql` seeds the
-- dial at 3, and `GatingService` reads it — but on its own that migration
-- achieves NOTHING, and applying it alone is worse than not applying it,
-- because an applied-but-inert dial reads as "the decision has shipped".
--
-- The chain that defeats it, verified against production 2026-07-31:
--   1. `handle_new_user` stamps `warmup_reflect_remaining` and
--      `warmup_built_dua_remaining` for a `reel_v1` signup, but never
--      `warmup_discover_name_remaining`.
--   2. That column's default is 5 — the LEGACY number, not D10②'s 3.
--   3. `sync_all_user_data` returns the column on every launch and
--      `GatingService.hydrateFromProfile` writes it straight into prefs.
--      Batch sync runs before any re-roll gate.
--   4. `GatingService._readWarmup` short-circuits the dial read entirely once
--      a local counter exists.
-- So 5 always wins, and after the `pushToServer` provenance fix (70d05cb) the
-- client does not even persist the 3 it briefly reads pre-sync. The fix has to
-- be server-side, at the one place the column is born.
--
-- WHAT CHANGES. Exactly one thing: the `reel_v1` INSERT branch of
-- `handle_new_user` now also stamps `warmup_discover_name_remaining` from
-- `app_config.warmup_discover_name_size`, coalescing to 3 so the branch is
-- correct even if the dial row is absent.
--
-- WHAT DELIBERATELY DOES NOT CHANGE.
--   * The `legacy` branch. It still stamps nothing, so legacy signups keep the
--     column default of 5 and today's effective 2/day re-roll behaviour. The
--     one-disruption rule (§V6.10) says the existing base is migrated by the
--     softener wave, announced, not silently tightened by a signup trigger.
--   * The column DEFAULT stays 5. Lowering it was the other option in §6b and
--     is the wrong one: the default is what every legacy row and every
--     `sync_all_user_data` fallback object already reads, so moving it would
--     retroactively tighten the base — the exact outcome the paragraph above
--     exists to prevent.
--   * Every existing row. No UPDATE, no backfill. `handle_new_user` fires on
--     signup only, so this governs accounts created after `new_signup_cohort`
--     flips to 'reel_v1' at T0 and nobody else. That is also why it is safe to
--     apply BEFORE T0: with the dial still 'legacy', the new branch is dead
--     code until the flip.
--
-- Re-emitted in full from `20260727100200_free_tier_cohort_weekly_pool.sql`
-- §3, which is the body currently in production (pre-flight diff 2026-07-31:
-- prod == repo). `create or replace` on a function bound to an existing
-- trigger keeps the binding, so no trigger DDL is needed.

-- Belt and braces: the dial 20260731090000 seeds. Idempotent, and harmless if
-- that migration already ran — it exists so this file cannot be applied into a
-- state where the value it reads has never been defined.
insert into public.app_config (key, value) values
  ('warmup_discover_name_size', '3')
on conflict (key) do nothing;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_cohort text;
begin
  select value #>> '{}' into v_cohort
  from public.app_config where key = 'new_signup_cohort';
  if v_cohort is null or v_cohort not in ('reel_v1', 'legacy') then
    v_cohort := 'legacy';
  end if;

  if v_cohort = 'reel_v1' then
    insert into public.user_profiles
      (id, display_name, free_tier_cohort,
       warmup_reflect_remaining, warmup_built_dua_remaining,
       warmup_discover_name_remaining)
    values
      (new.id, new.raw_user_meta_data->>'full_name', 'reel_v1',
       coalesce((select (value::text)::int from public.app_config
                 where key = 'warmup_reflect_size'), 3),
       coalesce((select (value::text)::int from public.app_config
                 where key = 'warmup_built_dua_size'), 3),
       coalesce((select (value::text)::int from public.app_config
                 where key = 'warmup_discover_name_size'), 3));
  else
    insert into public.user_profiles (id, display_name, free_tier_cohort)
    values (new.id, new.raw_user_meta_data->>'full_name', 'legacy');
  end if;

  insert into public.user_streaks (user_id) values (new.id);
  insert into public.user_xp (user_id) values (new.id);
  insert into public.user_tokens (user_id) values (new.id);
  insert into public.user_daily_rewards (user_id) values (new.id);
  insert into public.user_notification_preferences (user_id) values (new.id);
  return new;
end;
$$;

comment on function public.handle_new_user() is
  'Signup trigger. Stamps free_tier_cohort from app_config.new_signup_cohort; reel_v1 signups additionally get all three warmup counters from their app_config dials (W5 D.3 / D10②). Legacy signups take the column defaults (10/10/5) — the existing base is migrated by the softener wave, never by this trigger.';
