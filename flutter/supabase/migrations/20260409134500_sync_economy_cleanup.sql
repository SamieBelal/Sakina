alter table public.user_tokens
  alter column balance set default 100;

alter table public.user_tokens
  add column if not exists total_spent integer not null default 0;

alter table public.user_streaks
  drop column if exists streak_freeze_available;

drop function if exists public.spend_tokens(int);

create or replace function public.spend_tokens(amount int)
returns jsonb as $$
declare
  row record;
begin
  update public.user_tokens
  set
    balance = balance - amount,
    total_spent = total_spent + amount
  where user_id = (select auth.uid()) and balance >= amount
  returning balance, total_spent into row;

  if not found then
    raise exception 'Insufficient tokens';
  end if;

  return jsonb_build_object('balance', row.balance, 'total_spent', row.total_spent);
end;
$$ language plpgsql security definer;
