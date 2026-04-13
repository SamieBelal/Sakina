update public.user_tokens
set
  balance = greatest(balance, 0),
  tier_up_scrolls = greatest(tier_up_scrolls, 0)
where balance < 0 or tier_up_scrolls < 0;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'token_balance_non_negative'
      and conrelid = 'public.user_tokens'::regclass
  ) then
    alter table public.user_tokens
      add constraint token_balance_non_negative
      check (balance >= 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'tier_up_scrolls_non_negative'
      and conrelid = 'public.user_tokens'::regclass
  ) then
    alter table public.user_tokens
      add constraint tier_up_scrolls_non_negative
      check (tier_up_scrolls >= 0);
  end if;
end $$;

create or replace function public.earn_tokens(amount int)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_balance int;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if amount <= 0 then
    raise exception 'Token amount must be positive';
  end if;

  insert into public.user_tokens (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  update public.user_tokens
  set balance = balance + amount
  where user_id = current_user_id
  returning balance into new_balance;

  if not found then
    raise exception 'Token row missing for user %', current_user_id;
  end if;

  return new_balance;
end;
$$;

create or replace function public.spend_tokens(amount int)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  row record;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if amount <= 0 then
    raise exception 'Token amount must be positive';
  end if;

  insert into public.user_tokens (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  update public.user_tokens
  set
    balance = balance - amount,
    total_spent = total_spent + amount
  where user_id = current_user_id and balance >= amount
  returning balance, total_spent into row;

  if not found then
    raise exception 'Insufficient tokens';
  end if;

  return jsonb_build_object(
    'balance', row.balance,
    'total_spent', row.total_spent
  );
end;
$$;

create or replace function public.earn_scrolls(amount int)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_balance int;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if amount <= 0 then
    raise exception 'Scroll amount must be positive';
  end if;

  insert into public.user_tokens (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  update public.user_tokens
  set tier_up_scrolls = tier_up_scrolls + amount
  where user_id = current_user_id
  returning tier_up_scrolls into new_balance;

  if not found then
    raise exception 'Token row missing for user %', current_user_id;
  end if;

  return new_balance;
end;
$$;

create or replace function public.spend_scrolls(amount int)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_balance int;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if amount <= 0 then
    raise exception 'Scroll amount must be positive';
  end if;

  insert into public.user_tokens (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  update public.user_tokens
  set tier_up_scrolls = tier_up_scrolls - amount
  where user_id = current_user_id and tier_up_scrolls >= amount
  returning tier_up_scrolls into new_balance;

  if not found then
    raise exception 'Insufficient tier up scrolls';
  end if;

  return new_balance;
end;
$$;

drop function if exists public.award_xp(int);

create or replace function public.award_xp(amount int)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  old_total int := 0;
  new_total int;
  old_level int := 1;
  new_level int := 1;
  reward_tokens int := 0;
  reward_scrolls int := 0;
  token_balance int := 0;
  scroll_balance int := 0;
  idx int;
  level_thresholds int[] := array[
    0, 75, 175, 275, 375,
    445, 545, 665, 815, 995,
    1195, 1445, 1745, 2095, 2495,
    2945, 3495, 4145, 4895, 5745,
    6695, 7795, 9095, 10595, 12195
  ];
  level_token_rewards int[] := array[
    5, 5, 5, 5, 5,
    6, 6, 7, 7, 8,
    8, 9, 9, 10, 10,
    11, 11, 12, 12, 13,
    13, 14, 14, 15, 15
  ];
  level_scroll_rewards int[] := array[
    0, 0, 0, 0, 2,
    0, 0, 0, 0, 5,
    0, 0, 0, 0, 3,
    0, 0, 0, 0, 7,
    0, 0, 0, 0, 10
  ];
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if amount <= 0 then
    raise exception 'XP amount must be positive';
  end if;

  insert into public.user_xp (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  insert into public.user_tokens (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  select x.total_xp
  into old_total
  from public.user_xp x
  where x.user_id = current_user_id
  for update;

  old_total := coalesce(old_total, 0);
  new_total := old_total + amount;

  for idx in 1..coalesce(array_length(level_thresholds, 1), 0) loop
    if old_total >= level_thresholds[idx] then
      old_level := idx;
    else
      exit;
    end if;
  end loop;

  new_level := old_level;
  if old_level < coalesce(array_length(level_thresholds, 1), 0) then
    for idx in old_level + 1..array_length(level_thresholds, 1) loop
      exit when new_total < level_thresholds[idx];
      new_level := idx;
      reward_tokens := reward_tokens + level_token_rewards[idx];
      reward_scrolls := reward_scrolls + level_scroll_rewards[idx];
    end loop;
  end if;

  update public.user_xp
  set total_xp = new_total
  where user_id = current_user_id;

  update public.user_tokens
  set
    balance = balance + reward_tokens,
    tier_up_scrolls = tier_up_scrolls + reward_scrolls
  where user_id = current_user_id
  returning balance, tier_up_scrolls
  into token_balance, scroll_balance;

  return jsonb_build_object(
    'total_xp', new_total,
    'old_level', old_level,
    'new_level', new_level,
    'reward_tokens', reward_tokens,
    'reward_scrolls', reward_scrolls,
    'token_balance', token_balance,
    'scroll_balance', scroll_balance
  );
end;
$$;

drop function if exists public.consume_streak_freeze();

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
  set streak_freeze_owned = false
  where user_id = current_user_id
    and streak_freeze_owned = true
  returning true into consumed;

  return coalesce(consumed, false);
end;
$$;

drop function if exists public.claim_daily_reward();
drop function if exists public.claim_daily_reward(boolean);

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
  stored_freeze boolean := false;
  new_freeze_owned boolean := false;
  token_reward int := 0;
  scroll_reward int := 0;
  earned_freeze boolean := false;
  earned_scroll boolean := false;
  token_balance int := 0;
  scroll_balance int := 0;
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
    r.streak_freeze_owned
  into
    stored_day,
    stored_last_claim,
    stored_freeze
  from public.user_daily_rewards r
  where r.user_id = current_user_id
  for update;

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
      'streak_freeze_owned', stored_freeze,
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
  new_freeze_owned := stored_freeze;

  case next_day
    when 1 then token_reward := 5;
    when 2 then token_reward := 10;
    when 3 then token_reward := 15;
    when 4 then
      earned_freeze := true;
      new_freeze_owned := true;
    when 5 then token_reward := 20;
    when 6 then
      scroll_reward := 5;
      earned_scroll := true;
    when 7 then token_reward := 30;
    else
      raise exception 'Unsupported daily reward day %', next_day;
  end case;

  update public.user_daily_rewards
  set
    current_day = next_day,
    last_claim_date = today_utc,
    streak_freeze_owned = new_freeze_owned
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
    'streak_freeze_owned', new_freeze_owned,
    'token_balance', coalesce(token_balance, 0),
    'scroll_balance', coalesce(scroll_balance, 0)
  );
end;
$$;

create or replace function public.sync_all_user_data()
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  return jsonb_build_object(
    'xp',
      coalesce(
        (
          select jsonb_build_object(
            'total_xp', x.total_xp
          )
          from public.user_xp x
          where x.user_id = current_user_id
        ),
        jsonb_build_object('total_xp', 0)
      ),
    'tokens',
      coalesce(
        (
          select jsonb_build_object(
            'balance', t.balance,
            'total_spent', t.total_spent,
            'tier_up_scrolls', t.tier_up_scrolls
          )
          from public.user_tokens t
          where t.user_id = current_user_id
        ),
        jsonb_build_object(
          'balance', 50,
          'total_spent', 0,
          'tier_up_scrolls', 0
        )
      ),
    'streak',
      coalesce(
        (
          select jsonb_build_object(
            'current_streak', s.current_streak,
            'longest_streak', s.longest_streak,
            'last_active', s.last_active
          )
          from public.user_streaks s
          where s.user_id = current_user_id
        ),
        jsonb_build_object(
          'current_streak', 0,
          'longest_streak', 0,
          'last_active', null
        )
      ),
    'daily_rewards',
      coalesce(
        (
          select jsonb_build_object(
            'current_day', r.current_day,
            'last_claim_date', r.last_claim_date,
            'streak_freeze_owned', r.streak_freeze_owned,
            'last_premium_grant_month', r.last_premium_grant_month
          )
          from public.user_daily_rewards r
          where r.user_id = current_user_id
        ),
        jsonb_build_object(
          'current_day', 0,
          'last_claim_date', null,
          'streak_freeze_owned', false,
          'last_premium_grant_month', null
        )
      ),
    'checkin_history',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'checked_in_at', c.checked_in_at,
              'q1', c.q1,
              'q2', c.q2,
              'q3', c.q3,
              'q4', c.q4,
              'name_returned', c.name_returned,
              'name_arabic', c.name_arabic
            )
            order by c.checked_in_at desc
          )
          from public.user_checkin_history c
          where c.user_id = current_user_id
        ),
        '[]'::jsonb
      ),
    'reflections',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'id', r.id,
              'saved_at', r.saved_at,
              'user_text', r.user_text,
              'name', r.name,
              'name_arabic', r.name_arabic,
              'reframe_preview', r.reframe_preview,
              'reframe', r.reframe,
              'story', r.story,
              'dua_arabic', r.dua_arabic,
              'dua_transliteration', r.dua_transliteration,
              'dua_translation', r.dua_translation,
              'dua_source', r.dua_source,
              'related_names', r.related_names
            )
            order by r.saved_at desc
          )
          from public.user_reflections r
          where r.user_id = current_user_id
        ),
        '[]'::jsonb
      ),
    'built_duas',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'id', d.id,
              'saved_at', d.saved_at,
              'need', d.need,
              'arabic', d.arabic,
              'transliteration', d.transliteration,
              'translation', d.translation
            )
            order by d.saved_at desc
          )
          from public.user_built_duas d
          where d.user_id = current_user_id
        ),
        '[]'::jsonb
      ),
    'card_collection',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'name_id', cc.name_id,
              'tier', cc.tier,
              'discovered_at', cc.discovered_at,
              'last_engaged_at', cc.last_engaged_at
            )
            order by cc.discovered_at asc
          )
          from public.user_card_collection cc
          where cc.user_id = current_user_id
        ),
        '[]'::jsonb
      ),
    'profile',
      coalesce(
        (
          select jsonb_build_object(
            'selected_title', p.selected_title,
            'is_auto_title', p.is_auto_title,
            'created_at', p.created_at
          )
          from public.user_profiles p
          where p.id = current_user_id
        ),
        jsonb_build_object(
          'selected_title', null,
          'is_auto_title', true,
          'created_at', null
        )
      ),
    'achievements',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'achievement_id', a.achievement_id,
              'unlocked_at', a.unlocked_at
            )
            order by a.unlocked_at desc
          )
          from public.user_achievements a
          where a.user_id = current_user_id
        ),
        '[]'::jsonb
      ),
    'discovery_results',
      (
        select jsonb_build_object(
          'anchor_names', d.anchor_names
        )
        from public.user_discovery_results d
        where d.user_id = current_user_id
      )
  );
end;
$$;
