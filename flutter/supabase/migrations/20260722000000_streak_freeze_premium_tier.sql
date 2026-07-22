-- Streak-freeze becomes a genuine premium differentiator (backs paywall
-- benefit5: "Streak protection so you never lose progress").
--
-- BEFORE: `user_daily_rewards.streak_freeze_owned` is a single boolean — a user
-- holds at most one freeze, and premium is byte-for-byte identical to free
-- (the daily-reward 5× multiplier explicitly skips the freeze slot). The paywall
-- claim was therefore unbacked (docs TODO: "Back the paywall's premium-benefit
-- claims"; app_strings.dart SHIPPED-AHEAD-OF-MECHANIC note).
--
-- AFTER: the freeze becomes a COUNT with a per-tier cap enforced SERVER-SIDE
-- (via has_active_premium_entitlement — a tampered client cannot grant itself
-- extra freezes):
--   * free cap    = 1   (unchanged behaviour: hold at most one)
--   * premium cap = 3   (accumulate a buffer so a rough week never breaks the
--                        streak), plus grant_premium_monthly tops premium up to
--                        the cap each calendar month so the buffer is immediately
--                        useful rather than only building over ~3 weekly cycles.
--
-- The legacy boolean column is KEPT and written in lockstep (owned = count > 0)
-- so an older client still in the wild reads a correct value and a rollback is
-- safe. New app code reads streak_freeze_count.
--
-- The repair ladder in streak_service.dart is unchanged: consume_streak_freeze
-- still returns "was a freeze available?" — only the storage underneath moves
-- from set-false to decrement.

-- ---------------------------------------------------------------------------
-- 1. streak_freeze_count column + backfill
-- ---------------------------------------------------------------------------
alter table public.user_daily_rewards
  add column if not exists streak_freeze_count int not null default 0;

alter table public.user_daily_rewards
  drop constraint if exists user_daily_rewards_streak_freeze_count_nonneg;
alter table public.user_daily_rewards
  add constraint user_daily_rewards_streak_freeze_count_nonneg
  check (streak_freeze_count >= 0);

-- Seed the count from the current boolean source of truth. Runs once; existing
-- holders of a freeze become count = 1, everyone else 0.
update public.user_daily_rewards
set streak_freeze_count = case when streak_freeze_owned then 1 else 0 end
where streak_freeze_count = 0 and streak_freeze_owned = true;

-- ---------------------------------------------------------------------------
-- 2. Per-tier caps (single source of truth for the SQL layer; mirrored in
--    lib/services/daily_rewards_service.dart)
-- ---------------------------------------------------------------------------
create or replace function public.streak_freeze_cap(p_is_premium boolean)
returns int
language sql
immutable
set search_path = public
as $$
  select case when p_is_premium then 3 else 1 end;
$$;

-- ---------------------------------------------------------------------------
-- 3. claim_daily_reward — day-4 grant now respects the per-tier cap
-- ---------------------------------------------------------------------------
-- Re-emitted from 20260417000000_daily_reward_premium_multiplier.sql with the
-- freeze slot changed from a binary set-true to a capped increment. A grant only
-- happens when the current count is below the tier cap, so a downgraded premium
-- user holding extras is never reduced. Both count and the legacy boolean are
-- written in lockstep.
create or replace function public.claim_daily_reward()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  today_utc date := timezone('utc', now())::date;
  yesterday_utc date := (timezone('utc', now())::date - 1);
  stored_day int := 0;
  next_day int;
  stored_last_claim date;
  stored_count int := 0;
  new_count int := 0;
  freeze_cap int := 1;
  base_token_reward int := 0;
  base_scroll_reward int := 0;
  multiplier int := 1;
  token_reward int := 0;
  scroll_reward int := 0;
  earned_freeze boolean := false;
  earned_scroll boolean := false;
  token_balance int := 0;
  scroll_balance int := 0;
  is_premium boolean := false;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.user_daily_rewards (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  insert into public.user_tokens (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  select
    r.current_day,
    r.last_claim_date,
    r.streak_freeze_count
  into
    stored_day,
    stored_last_claim,
    stored_count
  from public.user_daily_rewards r
  where r.user_id = current_user_id
  for update;

  is_premium := public.has_active_premium_entitlement(current_user_id);
  freeze_cap := public.streak_freeze_cap(is_premium);

  if stored_last_claim = today_utc then
    select t.balance, t.tier_up_scrolls
    into token_balance, scroll_balance
    from public.user_tokens t
    where t.user_id = current_user_id;

    return jsonb_build_object(
      'day', stored_day,
      'tokens_awarded', 0,
      'scrolls_awarded', 0,
      'earned_streak_freeze', false,
      'earned_tier_up_scroll', false,
      'already_claimed', true,
      'current_day', stored_day,
      'last_claim_date', stored_last_claim,
      'streak_freeze_count', stored_count,
      'streak_freeze_owned', stored_count > 0,
      'token_balance', coalesce(token_balance, 0),
      'scroll_balance', coalesce(scroll_balance, 0)
    );
  end if;

  if stored_last_claim is not null
      and stored_last_claim <> today_utc
      and stored_last_claim <> yesterday_utc then
    stored_day := 0;
  end if;

  next_day := case when stored_day >= 7 then 1 else stored_day + 1 end;
  new_count := stored_count;

  case next_day
    when 1 then base_token_reward := 5;
    when 2 then base_token_reward := 10;
    when 3 then base_token_reward := 15;
    when 4 then
      -- Capped increment: only earn a freeze when below the tier cap. Never
      -- reduces an existing (possibly post-downgrade) surplus.
      if stored_count < freeze_cap then
        new_count := stored_count + 1;
        earned_freeze := true;
      end if;
    when 5 then base_token_reward := 20;
    when 6 then
      base_scroll_reward := 5;
      earned_scroll := true;
    when 7 then base_token_reward := 30;
    else
      raise exception 'Unsupported daily reward day %', next_day;
  end case;

  -- Server-authoritative premium multiplier for tokens/scrolls. The freeze slot
  -- is differentiated by the CAP above, not by this multiplier.
  multiplier := case when is_premium then 5 else 1 end;
  token_reward := base_token_reward * multiplier;
  scroll_reward := base_scroll_reward * multiplier;

  update public.user_daily_rewards
  set
    current_day = next_day,
    last_claim_date = today_utc,
    streak_freeze_count = new_count,
    streak_freeze_owned = new_count > 0
  where user_id = current_user_id;

  update public.user_tokens
  set
    balance = balance + token_reward,
    tier_up_scrolls = tier_up_scrolls + scroll_reward
  where user_id = current_user_id
  returning balance, tier_up_scrolls
  into token_balance, scroll_balance;

  return jsonb_build_object(
    'day', next_day,
    'tokens_awarded', token_reward,
    'scrolls_awarded', scroll_reward,
    'earned_streak_freeze', earned_freeze,
    'earned_tier_up_scroll', earned_scroll,
    'already_claimed', false,
    'current_day', next_day,
    'last_claim_date', today_utc,
    'streak_freeze_count', new_count,
    'streak_freeze_owned', new_count > 0,
    'token_balance', coalesce(token_balance, 0),
    'scroll_balance', coalesce(scroll_balance, 0),
    'is_premium', is_premium,
    'multiplier', multiplier
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. consume_streak_freeze — decrement instead of set-false
-- ---------------------------------------------------------------------------
-- Re-emitted from 20260720000000_freeze_burn_marker.sql. The `> 0` guard keeps
-- it idempotent under concurrency (a racing second call matches 0 rows and
-- returns false). Boolean kept in lockstep for older clients.
create or replace function public.consume_streak_freeze()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  consumed boolean := false;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.user_daily_rewards (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  update public.user_daily_rewards
  set streak_freeze_count = streak_freeze_count - 1,
      streak_freeze_owned = (streak_freeze_count - 1) > 0,
      last_freeze_burn_at = now(),
      freeze_burn_acked = false
  where user_id = current_user_id
    and streak_freeze_count > 0
  returning true into consumed;

  return coalesce(consumed, false);
end;
$$;

-- ---------------------------------------------------------------------------
-- 5. grant_premium_monthly — also top the freeze buffer up to the premium cap
-- ---------------------------------------------------------------------------
-- Re-emitted from 20260413000000_create_user_subscriptions_and_guard.sql with a
-- freeze top-up (GREATEST → never reduces an existing surplus) added to the
-- grant path, and streak_freeze_count surfaced on every return object so the
-- client cache stays in sync. Not-premium and already-granted paths read the
-- current count back without mutating it.
create or replace function public.grant_premium_monthly()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  current_month text := to_char(date_trunc('month', timezone('utc', now())), 'YYYY-MM');
  grant_tokens constant int := 50;
  grant_scrolls constant int := 15;
  premium_cap int := public.streak_freeze_cap(true);
  last_grant_month text;
  new_token_balance int;
  new_scroll_balance int;
  new_freeze_count int := 0;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if not public.has_active_premium_entitlement(current_user_id) then
    return jsonb_build_object(
      'granted', false,
      'reason', 'not_premium',
      'grant_month', current_month,
      'tokens_granted', 0,
      'scrolls_granted', 0,
      'streak_freeze_count', coalesce(
        (select streak_freeze_count from public.user_daily_rewards where user_id = current_user_id), 0
      ),
      'new_token_balance', coalesce(
        (select balance from public.user_tokens where user_id = current_user_id), 0
      ),
      'new_scroll_balance', coalesce(
        (select tier_up_scrolls from public.user_tokens where user_id = current_user_id), 0
      )
    );
  end if;

  insert into public.user_daily_rewards (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  insert into public.user_tokens (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  select r.last_premium_grant_month
  into last_grant_month
  from public.user_daily_rewards r
  where r.user_id = current_user_id
  for update;

  if last_grant_month = current_month then
    select t.balance, t.tier_up_scrolls
    into new_token_balance, new_scroll_balance
    from public.user_tokens t
    where t.user_id = current_user_id;

    return jsonb_build_object(
      'granted', false,
      'grant_month', current_month,
      'tokens_granted', 0,
      'scrolls_granted', 0,
      'streak_freeze_count', coalesce(
        (select streak_freeze_count from public.user_daily_rewards where user_id = current_user_id), 0
      ),
      'new_token_balance', coalesce(new_token_balance, 0),
      'new_scroll_balance', coalesce(new_scroll_balance, 0)
    );
  end if;

  update public.user_tokens
  set
    balance = balance + grant_tokens,
    tier_up_scrolls = tier_up_scrolls + grant_scrolls
  where user_id = current_user_id
  returning balance, tier_up_scrolls
  into new_token_balance, new_scroll_balance;

  update public.user_daily_rewards
  set last_premium_grant_month = current_month,
      streak_freeze_count = greatest(streak_freeze_count, premium_cap),
      streak_freeze_owned = greatest(streak_freeze_count, premium_cap) > 0
  where user_id = current_user_id
  returning streak_freeze_count into new_freeze_count;

  return jsonb_build_object(
    'granted', true,
    'grant_month', current_month,
    'tokens_granted', grant_tokens,
    'scrolls_granted', grant_scrolls,
    'streak_freeze_count', coalesce(new_freeze_count, premium_cap),
    'new_token_balance', coalesce(new_token_balance, 0),
    'new_scroll_balance', coalesce(new_scroll_balance, 0)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. sync_all_user_data — surface streak_freeze_count for cache hydration
-- ---------------------------------------------------------------------------
-- Re-emitted verbatim from 20260616204630_reverse_trial_backend.sql with
-- streak_freeze_count added to BOTH the populated and fallback daily_rewards
-- objects. Pure read aggregator — no user_profiles UPDATE, so the freemium guard
-- is untouched.
create or replace function public.sync_all_user_data()
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to 'public'
as $function$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  return jsonb_build_object(
    'xp',
      coalesce(
        (select jsonb_build_object('total_xp', x.total_xp)
         from public.user_xp x where x.user_id = current_user_id),
        jsonb_build_object('total_xp', 0)
      ),
    'tokens',
      coalesce(
        (select jsonb_build_object('balance', t.balance, 'total_spent', t.total_spent, 'tier_up_scrolls', t.tier_up_scrolls)
         from public.user_tokens t where t.user_id = current_user_id),
        jsonb_build_object('balance', 100, 'total_spent', 0, 'tier_up_scrolls', 0)
      ),
    'streak',
      coalesce(
        (select jsonb_build_object('current_streak', s.current_streak, 'longest_streak', s.longest_streak, 'last_active', s.last_active)
         from public.user_streaks s where s.user_id = current_user_id),
        jsonb_build_object('current_streak', 0, 'longest_streak', 0, 'last_active', null)
      ),
    'daily_rewards',
      coalesce(
        (select jsonb_build_object('current_day', r.current_day, 'last_claim_date', r.last_claim_date,
            'streak_freeze_owned', r.streak_freeze_owned, 'streak_freeze_count', r.streak_freeze_count,
            'last_premium_grant_month', r.last_premium_grant_month)
         from public.user_daily_rewards r where r.user_id = current_user_id),
        jsonb_build_object('current_day', 0, 'last_claim_date', null, 'streak_freeze_owned', false,
            'streak_freeze_count', 0, 'last_premium_grant_month', null)
      ),
    'checkin_history',
      coalesce(
        (select jsonb_agg(
          jsonb_build_object('checked_in_at', c.checked_in_at, 'q1', c.q1, 'q2', c.q2, 'q3', c.q3, 'q4', c.q4,
            'name_returned', c.name_returned, 'name_arabic', c.name_arabic)
          order by c.checked_in_at desc)
         from public.user_checkin_history c where c.user_id = current_user_id),
        '[]'::jsonb
      ),
    'reflections',
      coalesce(
        (select jsonb_agg(
          jsonb_build_object('id', r.id, 'saved_at', r.saved_at, 'user_text', r.user_text,
            'name', r.name, 'name_arabic', r.name_arabic, 'reframe_preview', r.reframe_preview,
            'reframe', r.reframe, 'story', r.story, 'verses', r.verses,
            'dua_arabic', r.dua_arabic, 'dua_transliteration', r.dua_transliteration,
            'dua_translation', r.dua_translation, 'dua_source', r.dua_source, 'related_names', r.related_names)
          order by r.saved_at desc)
         from public.user_reflections r where r.user_id = current_user_id),
        '[]'::jsonb
      ),
    'built_duas',
      coalesce(
        (select jsonb_agg(
          jsonb_build_object('id', d.id, 'saved_at', d.saved_at, 'need', d.need,
            'arabic', d.arabic, 'transliteration', d.transliteration, 'translation', d.translation)
          order by d.saved_at desc)
         from public.user_built_duas d where d.user_id = current_user_id),
        '[]'::jsonb
      ),
    'card_collection',
      coalesce(
        (select jsonb_agg(jsonb_build_object('name_id', cc.name_id, 'tier', cc.tier, 'discovered_at', cc.discovered_at,
            'last_engaged_at', cc.last_engaged_at) order by cc.discovered_at asc)
         from public.user_card_collection cc where cc.user_id = current_user_id),
        '[]'::jsonb
      ),
    'profile',
      coalesce(
        (select jsonb_build_object(
            'selected_title', p.selected_title,
            'is_auto_title', p.is_auto_title,
            'created_at', p.created_at,
            'warmup_reflect_remaining', p.warmup_reflect_remaining,
            'warmup_built_dua_remaining', p.warmup_built_dua_remaining,
            'warmup_discover_name_remaining', p.warmup_discover_name_remaining,
            'had_trial', p.had_trial,
            'trial_premium_until', p.trial_premium_until,
            'first_bypass_consumed', p.first_bypass_consumed,
            'display_name', p.display_name,
            'lifetime_bypasses_purchased', p.lifetime_bypasses_purchased,
            'iap_upsell_banner_dismissed_at', p.iap_upsell_banner_dismissed_at,
            'onboarding_paywall_cleared', p.onboarding_paywall_cleared,
            'tour_step_index', p.tour_step_index)
         from public.user_profiles p where p.id = current_user_id),
        jsonb_build_object(
          'selected_title', null,
          'is_auto_title', true,
          'created_at', null,
          'warmup_reflect_remaining', 10,
          'warmup_built_dua_remaining', 10,
          'warmup_discover_name_remaining', 5,
          'had_trial', false,
          'trial_premium_until', null,
          'first_bypass_consumed', false,
          'display_name', 'Friend',
          'lifetime_bypasses_purchased', 0,
          'iap_upsell_banner_dismissed_at', null,
          'onboarding_paywall_cleared', null,
          'tour_step_index', null)
      ),
    'achievements',
      coalesce(
        (select jsonb_agg(jsonb_build_object('achievement_id', a.achievement_id, 'unlocked_at', a.unlocked_at) order by a.unlocked_at desc)
         from public.user_achievements a where a.user_id = current_user_id),
        '[]'::jsonb
      ),
    'discovery_results',
      (select jsonb_build_object('anchor_names', d.anchor_names)
       from public.user_discovery_results d where d.user_id = current_user_id),
    'daily_usage',
      coalesce(
        (select jsonb_agg(jsonb_build_object('usage_date', u.usage_date, 'reflect_uses', u.reflect_uses,
            'built_dua_uses', u.built_dua_uses, 'discover_name_uses', u.discover_name_uses,
            'reflect_bypasses_used', u.reflect_bypasses_used, 'built_dua_bypasses_used', u.built_dua_bypasses_used,
            'discover_name_bypasses_used', u.discover_name_bypasses_used) order by u.usage_date desc)
         from public.user_daily_usage u where u.user_id = current_user_id
           and u.usage_date between timezone('utc', now())::date - 1 and timezone('utc', now())::date + 1),
        '[]'::jsonb
      ),
    'daily_answers',
      coalesce(
        (select jsonb_agg(jsonb_build_object('answered_at', da.answered_at, 'question_id', da.question_id,
            'selected_option', da.selected_option, 'name_returned', da.name_returned, 'name_arabic', da.name_arabic,
            'teaching', da.teaching, 'dua_arabic', da.dua_arabic, 'dua_transliteration', da.dua_transliteration,
            'dua_translation', da.dua_translation) order by da.answered_at desc)
         from public.user_daily_answers da where da.user_id = current_user_id
           and da.answered_at::date between timezone('utc', now())::date - 1 and timezone('utc', now())::date),
        '[]'::jsonb
      ),
    'quest_progress',
      coalesce(
        (select jsonb_agg(jsonb_build_object('quest_id', q.quest_id, 'cadence', q.cadence, 'progress', q.progress,
            'completed', q.completed, 'period_start', q.period_start, 'updated_at', q.updated_at) order by q.updated_at desc)
         from public.user_quest_progress q where q.user_id = current_user_id),
        '[]'::jsonb
      )
  );
end;
$function$;

-- ---------------------------------------------------------------------------
-- 7. Freemium guard: clamp direct client writes of streak_freeze_count
-- ---------------------------------------------------------------------------
-- The RLS "update own daily rewards" policy (20260407000000_initial_schema.sql)
-- has no WITH CHECK, so without this an authenticated user could
--   PATCH /user_daily_rewards?user_id=eq.<self> {"streak_freeze_count": 9999}
-- and self-grant the premium freeze benefit for free — making the server-side
-- cap in claim_daily_reward / grant_premium_monthly merely advisory. This BEFORE
-- UPDATE guard makes the RPCs the only path that can RAISE the count above the
-- caller's tier cap. Mirrors the guard_user_*_freemium_fields pattern
-- (security invoker + role-based bypass) already used for user_profiles /
-- user_daily_usage.
--
-- security invoker is REQUIRED: it lets `current_user` distinguish a direct
-- client UPDATE (→ 'authenticated', enforced) from a SECURITY DEFINER RPC's
-- UPDATE (→ table owner 'postgres', bypassed). A definer guard would always see
-- the owner and never enforce.
create or replace function public.guard_user_daily_rewards_freeze()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  cap int;
begin
  -- claim_daily_reward / consume_streak_freeze / grant_premium_monthly are
  -- SECURITY DEFINER and run as the table owner — let their honest writes pass.
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  -- Only constrain INCREASES. Decreases (a local mirror lowering after a
  -- consume) and no-op updates always pass, so a downgraded premium holder's
  -- surplus is never forcibly reduced by the guard.
  if new.streak_freeze_count > old.streak_freeze_count then
    cap := public.streak_freeze_cap(
      public.has_active_premium_entitlement(auth.uid()));
    if new.streak_freeze_count > cap then
      raise exception
        'cannot raise streak_freeze_count above tier cap (% > %); must go through claim_daily_reward / grant_premium_monthly',
        new.streak_freeze_count, cap
        using errcode = 'check_violation';
    end if;
  end if;

  -- Keep the legacy boolean in lockstep for older clients.
  new.streak_freeze_owned := new.streak_freeze_count > 0;
  return new;
end
$$;

drop trigger if exists guard_user_daily_rewards_freeze
  on public.user_daily_rewards;
create trigger guard_user_daily_rewards_freeze
  before update on public.user_daily_rewards
  for each row execute function public.guard_user_daily_rewards_freeze();

-- ---------------------------------------------------------------------------
-- 8. Execute grants (mirror the posture of the functions being replaced)
-- ---------------------------------------------------------------------------
-- streak_freeze_cap stays executable by authenticated: the security-invoker
-- guard above calls it as the authenticated client. It leaks nothing (a pure
-- `case` returning 1 or 3).
revoke execute on function public.streak_freeze_cap(boolean) from public, anon;
grant  execute on function public.streak_freeze_cap(boolean) to authenticated;
grant  execute on function public.claim_daily_reward() to authenticated;
grant  execute on function public.consume_streak_freeze() to authenticated;
grant  execute on function public.grant_premium_monthly() to authenticated;
grant  execute on function public.sync_all_user_data() to authenticated;
