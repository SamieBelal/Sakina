-- Fix handle_new_user trigger to populate display_name from user metadata
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  insert into public.user_streaks (user_id) values (new.id);
  insert into public.user_xp (user_id) values (new.id);
  insert into public.user_tokens (user_id) values (new.id);
  insert into public.user_daily_rewards (user_id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;
