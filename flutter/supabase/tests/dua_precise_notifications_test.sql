-- dua_precise_notifications_test.sql
--
-- pgtap coverage for the dua_precise_notifications table + its enqueue columns:
--   * base table       — 20260716120000_dua_precise_notifications.sql
--   * enqueue columns  — 20260717121000_dua_precise_notifications_enqueue_columns.sql
--
-- Asserts:
--   (c) Structure — the agreed schema columns + types exist
--       (id, user_id, window_type, fire_utc, sync_version, created_at,
--        sent_at, title, body) and the due partial index exists.
--   RLS (Risk 3, HIGH if missed):
--     (r1) a user can read ONLY their own rows,
--     (r2) a user CANNOT read another user's rows,
--     (r3) anon CANNOT read any rows,
--     (r4) a user CANNOT insert a row for another user (WITH CHECK).
--
-- Style mirrors dua_windows_test.sql (begin / plan / … / finish / rollback)
-- with the two-auth-user + request.jwt.claims pattern from the RPC tests.

begin;

select plan(21);

-- ---------------------------------------------------------------------------
-- (c) Structure — agreed schema columns + types
-- ---------------------------------------------------------------------------
select has_table('public', 'dua_precise_notifications',
  'dua_precise_notifications table exists');

select has_column('public', 'dua_precise_notifications', 'id',           'id exists');
select has_column('public', 'dua_precise_notifications', 'user_id',      'user_id exists');
select has_column('public', 'dua_precise_notifications', 'window_type',  'window_type exists');
select has_column('public', 'dua_precise_notifications', 'fire_utc',     'fire_utc exists');
select has_column('public', 'dua_precise_notifications', 'sync_version', 'sync_version exists');
select has_column('public', 'dua_precise_notifications', 'created_at',   'created_at exists');
-- Enqueue columns added by the 20260717121000 migration.
select has_column('public', 'dua_precise_notifications', 'sent_at',      'sent_at exists');
select has_column('public', 'dua_precise_notifications', 'title',        'title exists');
select has_column('public', 'dua_precise_notifications', 'body',         'body exists');

select col_is_pk('public', 'dua_precise_notifications', 'id',
  'id is the primary key');

select col_type_is('public', 'dua_precise_notifications', 'fire_utc',
  'timestamp with time zone', 'fire_utc is timestamptz');
select col_type_is('public', 'dua_precise_notifications', 'sent_at',
  'timestamp with time zone', 'sent_at is timestamptz (nullable)');

-- sent_at must be nullable — it is NULL until the cron enqueues the row.
select col_is_null('public', 'dua_precise_notifications', 'sent_at',
  'sent_at is nullable (NULL = not yet enqueued)');

-- The partial due index that backs the cron scan.
select has_index('public', 'dua_precise_notifications',
  'dua_precise_notifications_due_idx',
  'partial due index (fire_utc) WHERE sent_at IS NULL exists');

-- ---------------------------------------------------------------------------
-- RLS setup — two authenticated users.
-- ---------------------------------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
)
values
  ('00000000-0000-0000-0000-000000000000'::uuid,
   '00000000-0000-0000-0000-0000000d0a01'::uuid,
   'authenticated', 'authenticated', 'dua-a@test.sakina.local', '',
   now(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000'::uuid,
   '00000000-0000-0000-0000-0000000d0a02'::uuid,
   'authenticated', 'authenticated', 'dua-b@test.sakina.local', '',
   now(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{}'::jsonb, now(), now());

-- Seed one precise row for each user (as superuser — RLS-exempt).
insert into public.dua_precise_notifications
  (user_id, window_type, fire_utc, sync_version, title, body)
values
  ('00000000-0000-0000-0000-0000000d0a01'::uuid, 'iftar',
   now(), 1, 'A window for duʿā is open', 'Make duʿā now.'),
  ('00000000-0000-0000-0000-0000000d0a02'::uuid, 'friday_hour',
   now(), 1, 'A window for duʿā is open', 'Make duʿā now.');

-- ---------------------------------------------------------------------------
-- (r1) / (r2) — user A sees ONLY their own row.
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-0000000d0a01',
                    'role', 'authenticated')::text, true);

select is(
  (select count(*)::int from public.dua_precise_notifications),
  1,
  '(r1) user A sees exactly their own row'
);

select is(
  (select count(*)::int from public.dua_precise_notifications
     where user_id = '00000000-0000-0000-0000-0000000d0a02'::uuid),
  0,
  '(r2) user A CANNOT read user B''s rows (RLS hides them)'
);

-- (r4) user A cannot insert a row owned by user B — WITH CHECK denies it.
select throws_ok(
  $$ insert into public.dua_precise_notifications
       (user_id, window_type, fire_utc, sync_version)
     values ('00000000-0000-0000-0000-0000000d0a02'::uuid, 'iftar', now(), 1) $$,
  '42501',
  'new row violates row-level security policy for table "dua_precise_notifications"',
  '(r4) user A cannot insert a row for user B (WITH CHECK, 42501)'
);

-- user A CAN insert their own row (sanity — the policy isn't over-broad).
select lives_ok(
  $$ insert into public.dua_precise_notifications
       (user_id, window_type, fire_utc, sync_version)
     values ('00000000-0000-0000-0000-0000000d0a01'::uuid, 'last_third_of_night', now(), 2) $$,
  '(r1b) user A CAN insert their own row'
);

-- ---------------------------------------------------------------------------
-- (r3) anon sees nothing.
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '', true);
set local role anon;

select is(
  (select count(*)::int from public.dua_precise_notifications),
  0,
  '(r3) anon CANNOT read any dua_precise_notifications rows'
);

reset role;

-- Belt-and-suspenders: as superuser (RLS-exempt) both original rows still exist
-- and were untouched by the anon/other-user attempts.
select is(
  (select count(*)::int from public.dua_precise_notifications
     where sync_version = 1),
  2,
  'both seeded rows survived the cross-user + anon probes'
);

select * from finish();

rollback;
