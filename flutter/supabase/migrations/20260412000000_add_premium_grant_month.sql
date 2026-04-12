alter table public.user_daily_rewards
  add column if not exists last_premium_grant_month text;

drop function if exists public.grant_premium_monthly(int, int);
drop function if exists public.grant_premium_monthly();

-- Grant amounts are hardcoded server-side so a malicious client cannot pass
-- arbitrary values.  Once RevenueCat webhooks populate a user_subscriptions
-- table, add an entitlement check here:
--   IF NOT EXISTS (SELECT 1 FROM user_subscriptions WHERE user_id = current_user_id AND active) THEN
--     RAISE EXCEPTION 'Not a premium subscriber';
--   END IF;
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
  last_grant_month text;
  new_token_balance int;
  new_scroll_balance int;
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
  set last_premium_grant_month = current_month
  where user_id = current_user_id;

  return jsonb_build_object(
    'granted', true,
    'grant_month', current_month,
    'new_token_balance', coalesce(new_token_balance, 0),
    'new_scroll_balance', coalesce(new_scroll_balance, 0)
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
          'balance', 100,
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
            'is_auto_title', p.is_auto_title
          )
          from public.user_profiles p
          where p.id = current_user_id
        ),
        jsonb_build_object(
          'selected_title', null,
          'is_auto_title', true
        )
      )
  );
end;
$$;
