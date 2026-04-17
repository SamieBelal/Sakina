-- Server-authoritative premium multiplier for daily rewards (closes M8).
--
-- The prior claim_daily_reward() always credited base token/scroll amounts,
-- even for premium users. The client UI advertises a 5x premium multiplier
-- via `scaledRewardForDay(..., isPremium: true)`, which meant paying
-- subscribers saw 5x in the UI but only received 1x in their balance.
--
-- This migration moves the multiplier to the server: the RPC reads
-- has_active_premium_entitlement(auth.uid()) and scales the base reward
-- accordingly. Streak-freeze rewards are NOT multiplied (it's a single slot).
--
-- Side benefit: a tampered client cannot spoof isPremium to claim 5x —
-- the entitlement check is derived from user_subscriptions (webhook-populated).

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
    when 1 then base_token_reward := 5;
    when 2 then base_token_reward := 10;
    when 3 then base_token_reward := 15;
    when 4 then
      earned_freeze := true;
      new_freeze_owned := true;
    when 5 then base_token_reward := 20;
    when 6 then
      base_scroll_reward := 5;
      earned_scroll := true;
    when 7 then base_token_reward := 30;
    else
      raise exception 'Unsupported daily reward day %', next_day;
  end case;

  -- Server-authoritative premium multiplier. The streak-freeze slot is
  -- binary and not multiplied (premium users don't get 5 freezes, they get
  -- the same single slot).
  is_premium := public.has_active_premium_entitlement(current_user_id);
  multiplier := case when is_premium then 5 else 1 end;
  token_reward := base_token_reward * multiplier;
  scroll_reward := base_scroll_reward * multiplier;

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
    'scroll_balance', coalesce(scroll_balance, 0),
    'is_premium', is_premium,
    'multiplier', multiplier
  );
end;
$$;
