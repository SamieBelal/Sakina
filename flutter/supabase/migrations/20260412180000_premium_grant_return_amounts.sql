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
      'tokens_granted', 0,
      'scrolls_granted', 0,
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
    'tokens_granted', grant_tokens,
    'scrolls_granted', grant_scrolls,
    'new_token_balance', coalesce(new_token_balance, 0),
    'new_scroll_balance', coalesce(new_scroll_balance, 0)
  );
end;
$$;
