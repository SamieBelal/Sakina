alter table public.user_tokens
  alter column balance set default 100;

alter table public.user_tokens
  add column if not exists total_spent integer not null default 0;

alter table public.user_streaks
  drop column if exists streak_freeze_available;

create or replace function public.spend_tokens(amount int)
returns int as $$
declare
  new_balance int;
begin
  update public.user_tokens
  set
    balance = balance - amount,
    total_spent = total_spent + amount
  where user_id = (select auth.uid()) and balance >= amount
  returning balance into new_balance;

  if not found then
    raise exception 'Insufficient tokens';
  end if;

  return new_balance;
end;
$$ language plpgsql security definer;
