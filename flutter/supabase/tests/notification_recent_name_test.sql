-- pgtap: notification_recent_name migration (Phase A)
-- Pins the slug helper's overrides against drift (they mirror the client's
-- widgetNameKeyOverrides — a third hand-maintained copy; drift fails safe to
-- generic copy but silently kills personalization) and the RPC's shape/grants.
begin;
select plan(12);

-- Helper exists and is service-callable logic (pure mapping checks)
select is(public.notification_name_anchor_slug('As-Salam'), 'as-salam', 'naive kebab');
select is(public.notification_name_anchor_slug('Dhul-Jalali wal-Ikram'), 'dhul-jalali-wal-ikram', 'space → dash');
select is(public.notification_name_anchor_slug('Malik-ul-Mulk'), 'malik-ul-mulk', 'multi-dash preserved');
-- Long-vowel overrides (sample of the 11 pinned overrides — must match
-- lib/core/constants/allah_names.dart widgetNameKeyOverrides)
select is(public.notification_name_anchor_slug('Ar-Raheem'), 'ar-rahim', 'override: Ar-Raheem → ar-rahim');
select is(public.notification_name_anchor_slug('Al-Wakeel'), 'al-wakil', 'override: Al-Wakeel → al-wakil');
select is(public.notification_name_anchor_slug(null), null, 'null-safe (STRICT)');

-- Every override target actually exists in name_anchors (drift tripwire):
select is(
  (select count(*)::int from name_anchors where name_key in
    (public.notification_name_anchor_slug('Ar-Raheem'),
     public.notification_name_anchor_slug('Al-Wakeel'),
     public.notification_name_anchor_slug('As-Salam'))),
  3, 'override/naive targets resolve to real anchor rows');

-- RPC exists with the two-step-friendly signature
select has_function('public', 'get_recent_checkin_names', array['uuid[]'], 'companion RPC exists');

-- Grants: service_role only (mirrors get_streak_notification_decisions)
select function_privs_are('public', 'get_recent_checkin_names', array['uuid[]'], 'service_role', array['EXECUTE'], 'service_role can execute');
select function_privs_are('public', 'get_recent_checkin_names', array['uuid[]'], 'anon', array[]::text[], 'anon cannot execute');
select function_privs_are('public', 'get_recent_checkin_names', array['uuid[]'], 'authenticated', array[]::text[], 'authenticated cannot execute');

-- No-checkin user still yields exactly one NULL row (unnest LEFT JOIN contract)
select is(
  (select count(*)::int from public.get_recent_checkin_names(array['00000000-0000-0000-0000-000000000000']::uuid[])),
  1, 'unknown user returns one NULL row, not zero rows');

select * from finish();
rollback;
