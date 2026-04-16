create table if not exists public.user_notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  push_enabled boolean not null default true,
  notify_daily boolean not null default true,
  notify_streak boolean not null default true,
  notify_reengagement boolean not null default true,
  notify_weekly boolean not null default true,
  notify_updates boolean not null default true,
  timezone text not null default 'UTC',
  last_daily_sent_at timestamptz,
  last_streak_sent_at timestamptz,
  last_reengagement_sent_at timestamptz,
  last_weekly_sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_notification_preferences
  add column if not exists push_enabled boolean not null default true,
  add column if not exists notify_daily boolean not null default true,
  add column if not exists notify_streak boolean not null default true,
  add column if not exists notify_reengagement boolean not null default true,
  add column if not exists notify_weekly boolean not null default true,
  add column if not exists notify_updates boolean not null default true,
  add column if not exists timezone text not null default 'UTC',
  add column if not exists last_daily_sent_at timestamptz,
  add column if not exists last_streak_sent_at timestamptz,
  add column if not exists last_reengagement_sent_at timestamptz,
  add column if not exists last_weekly_sent_at timestamptz,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.user_notification_preferences
set timezone = 'UTC'
where timezone is null or btrim(timezone) = '';

drop trigger if exists user_notification_preferences_updated_at
  on public.user_notification_preferences;

create trigger user_notification_preferences_updated_at
before update on public.user_notification_preferences
for each row execute function public.handle_updated_at();

alter table public.user_notification_preferences enable row level security;

drop policy if exists "Users can view own notification preferences"
  on public.user_notification_preferences;
create policy "Users can view own notification preferences"
  on public.user_notification_preferences
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert own notification preferences"
  on public.user_notification_preferences;
create policy "Users can insert own notification preferences"
  on public.user_notification_preferences
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own notification preferences"
  on public.user_notification_preferences;
create policy "Users can update own notification preferences"
  on public.user_notification_preferences
  for update to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can delete own notification preferences"
  on public.user_notification_preferences;
create policy "Users can delete own notification preferences"
  on public.user_notification_preferences
  for delete to authenticated
  using ((select auth.uid()) = user_id);

insert into public.user_notification_preferences (user_id)
select id
from auth.users
on conflict (user_id) do nothing;

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'full_name');
  insert into public.user_streaks (user_id) values (new.id);
  insert into public.user_xp (user_id) values (new.id);
  insert into public.user_tokens (user_id) values (new.id);
  insert into public.user_daily_rewards (user_id) values (new.id);
  insert into public.user_notification_preferences (user_id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create or replace function public.get_eligible_notification_users(
  p_pref_column text,
  p_sent_column text,
  p_target_hour integer,
  p_requires_streak boolean default false,
  p_inactive_days integer default 0,
  p_day_of_week integer default null
)
returns table (
  user_id uuid,
  timezone text,
  display_name text,
  current_streak integer,
  last_active date
)
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  allowed_pref_columns constant text[] := array[
    'notify_daily',
    'notify_streak',
    'notify_reengagement',
    'notify_weekly',
    'notify_updates'
  ];
  allowed_sent_columns constant text[] := array[
    'last_daily_sent_at',
    'last_streak_sent_at',
    'last_reengagement_sent_at',
    'last_weekly_sent_at'
  ];
  dedup_days integer := case
    when p_sent_column = 'last_reengagement_sent_at' then 7
    else 0
  end;
  sql_query text;
begin
  if not (p_pref_column = any(allowed_pref_columns)) then
    raise exception 'Unsupported preference column: %', p_pref_column;
  end if;

  if not (p_sent_column = any(allowed_sent_columns)) then
    raise exception 'Unsupported sent column: %', p_sent_column;
  end if;

  sql_query := format(
    $sql$
      select
        n.user_id,
        coalesce(nullif(n.timezone, ''), 'UTC') as timezone,
        p.display_name,
        coalesce(s.current_streak, 0)::integer as current_streak,
        s.last_active
      from public.user_notification_preferences n
      left join public.user_profiles p
        on p.id = n.user_id
      left join public.user_streaks s
        on s.user_id = n.user_id
      left join auth.users u
        on u.id = n.user_id
      where n.push_enabled = true
        and n.%1$I = true
        and extract(
          hour from (current_timestamp at time zone coalesce(nullif(n.timezone, ''), 'UTC'))
        )::integer = $1
        and ($2 = false or coalesce(s.current_streak, 0) > 0)
        and (
          n.%2$I is null
          or (
            n.%2$I at time zone coalesce(nullif(n.timezone, ''), 'UTC')
          )::date < (
            current_timestamp at time zone coalesce(nullif(n.timezone, ''), 'UTC')
          )::date - $3
        )
        and (
          $4 < 0
          or coalesce(
            s.last_active,
            timezone('utc', u.created_at)::date
          ) < (
            current_timestamp at time zone coalesce(nullif(n.timezone, ''), 'UTC')
          )::date - $4
        )
        and (
          $5 is null
          or extract(
            dow from (current_timestamp at time zone coalesce(nullif(n.timezone, ''), 'UTC'))
          )::integer = $5
        )
    $sql$,
    p_pref_column,
    p_sent_column
  );

  return query execute sql_query
    using p_target_hour, p_requires_streak, dedup_days, p_inactive_days, p_day_of_week;
end;
$$;

grant execute on function public.get_eligible_notification_users(
  text,
  text,
  integer,
  boolean,
  integer,
  integer
) to authenticated, service_role;

-- Hourly cron invokes the edge function. The edge function does its own auth check;
-- pg_cron only needs to hit the URL. No Bearer token required (verify_jwt: false on
-- the function + null Authorization is treated as authorized by the function itself).
create extension if not exists pg_net with schema extensions;

do $$
begin
  if exists (select 1 from cron.job where jobname = 'send-scheduled-notifications') then
    perform cron.unschedule('send-scheduled-notifications');
  end if;
end$$;

select cron.schedule(
  'send-scheduled-notifications',
  '0 * * * *',
  $cron$
    select net.http_post(
      url := 'https://smhvsqrxqoehqncphjrq.supabase.co/functions/v1/send-scheduled-notifications',
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body := '{}'::jsonb
    );
  $cron$
);
