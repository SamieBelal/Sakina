-- Cosmetics hardening (forward-only, code-review follow-ups):
--   1. unlock_cosmetic must refuse premium-exclusive items and out-of-window
--      seasonal items — a premium/seasonal item can never be Noor-purchased even
--      if it gets a price. Only the catalog SELECT's WHERE clause changes; every
--      other line (SECURITY DEFINER, search_path, FOR UPDATE, guard GUC, grants)
--      is identical to the shipped body.
--   2. Defensive CHECK constraints: noor_grants.amount must be positive, and
--      cosmetic_catalog.noor_price (when set) must be non-negative.

create or replace function public.unlock_cosmetic(p_item_type text, p_item_id text)
 returns boolean
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  v_uid uuid := auth.uid();
  v_price integer;
  v_balance integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from public.user_cosmetics
             where user_id=v_uid and item_type=p_item_type and item_id=p_item_id) then
    return true;
  end if;
  select noor_price into v_price from public.cosmetic_catalog
   where item_type=p_item_type and item_id=p_item_id and active
     and not is_premium_exclusive
     and (available_from is null or now() >= available_from)
     and (available_until is null or now() < available_until);
  if v_price is null then raise exception 'item not Noor-purchasable or inactive'; end if;
  select noor_balance into v_balance from public.user_profiles where id=v_uid for update;
  if v_balance < v_price then raise exception 'insufficient noor'; end if;
  perform set_config('app.cosmetics_rpc','on', true);
  update public.user_profiles
     set noor_balance = noor_balance - v_price,
         noor_total_spent = noor_total_spent + v_price
   where id=v_uid;
  insert into public.user_cosmetics(user_id,item_type,item_id,acquired_via)
     values (v_uid,p_item_type,p_item_id,'noor')
     on conflict (user_id,item_type,item_id) do nothing;
  return true;
end $function$;

-- Defensive CHECK constraints. Guarded so the migration is idempotent.
do $$ begin
  alter table public.noor_grants
    add constraint noor_grants_amount_pos check (amount > 0);
exception when duplicate_object then null;
end $$;

do $$ begin
  alter table public.cosmetic_catalog
    add constraint cosmetic_catalog_price_nonneg check (noor_price is null or noor_price >= 0);
exception when duplicate_object then null;
end $$;
