-- Regression test for:
--   * 20260523010000_push_on_referral_confirm.sql
--
-- Verifies:
--   * notify_referrer_on_confirm() exists with SECURITY DEFINER.
--   * trg_notify_referrer_on_confirm trigger exists on public.referrals.
--   * Trigger is REVOKEd from authenticated.
--   * INSERT with status='pending' does NOT fire (only UPDATE OF status).
--   * INSERT with status='confirmed' does NOT fire (S7 coverage gap).
--   * UPDATE pending -> confirmed fires exactly one http_post.
--   * The http_post URL targets the value of `app.notify_referral_url`
--     (env-bound — S3 fix).
--   * The http_post body contains referrer_id + referee_id populated.
--   * The http_post headers include X-Notify-Secret matching
--     `app.notify_referral_secret` (S1 fix).
--   * A no-op UPDATE confirmed -> confirmed does NOT re-fire.
--   * UPDATE rejected -> confirmed does NOT fire (S4 fix).
--   * UPDATE of a non-status column on a pending row does NOT fire.
--   * If `app.notify_referral_url` or `app.notify_referral_secret` is
--     unset, the trigger no-ops gracefully (no http_post enqueued).

begin;

create extension if not exists pgtap;

-- ---------------------------------------------------------------------------
-- Stubbing net.http_post for the test transaction.
--
-- CREATE OR REPLACE FUNCTION inside a transaction is rolled back along with
-- the transaction itself, so the production net.http_post is restored when
-- the test ROLLBACKs at the end. Run via `psql -1` (single transaction) for
-- the safest restore semantics.
-- ---------------------------------------------------------------------------
create table public._test_push_calls (
  id        bigserial primary key,
  called_at timestamptz not null default now(),
  url       text not null,
  body      jsonb not null,
  headers   jsonb not null
);

create or replace function net.http_post(
  url text,
  body jsonb default '{}'::jsonb,
  params jsonb default '{}'::jsonb,
  headers jsonb default '{}'::jsonb,
  timeout_milliseconds integer default 5000
) returns bigint
language plpgsql as $$
begin
  insert into public._test_push_calls(url, body, headers)
    values (url, body, headers);
  return 0::bigint;
end
$$;

-- Configure the env-bound GUCs the trigger reads (S1 + S3 fixes).
-- `set local` scopes them to this transaction so they don't leak.
set local app.notify_referral_url = 'https://test.supabase.co/functions/v1/notify-referral-confirmed';
set local app.notify_referral_secret = 'test-secret-32-chars-of-randomness';

select plan(15);

-- ---------------------------------------------------------------------------
-- Structural assertions
-- ---------------------------------------------------------------------------

select has_function('public', 'notify_referrer_on_confirm', array[]::text[],
  'notify_referrer_on_confirm() exists');

select ok(
  (select prosecdef from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'notify_referrer_on_confirm'),
  'notify_referrer_on_confirm is SECURITY DEFINER');

select has_trigger('public', 'referrals', 'trg_notify_referrer_on_confirm',
  'trg_notify_referrer_on_confirm exists on public.referrals');

select ok(
  not has_function_privilege('authenticated',
    'public.notify_referrer_on_confirm()', 'EXECUTE'),
  'authenticated cannot EXECUTE notify_referrer_on_confirm()');

-- ---------------------------------------------------------------------------
-- Behavioral assertions — INSERT does not fire (trigger is on UPDATE)
-- ---------------------------------------------------------------------------

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000'::uuid,
   '00000000-0000-0000-0000-000000007201'::uuid,
   'authenticated', 'authenticated', 'r-push@test.sakina.local', '',
   now(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000'::uuid,
   '00000000-0000-0000-0000-000000007202'::uuid,
   'authenticated', 'authenticated', 'a-push@test.sakina.local', '',
   now(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{}'::jsonb, now(), now()),
  ('00000000-0000-0000-0000-000000000000'::uuid,
   '00000000-0000-0000-0000-000000007203'::uuid,
   'authenticated', 'authenticated', 'rej-push@test.sakina.local', '',
   now(), '{"provider":"email","providers":["email"]}'::jsonb,
   '{}'::jsonb, now(), now());

insert into public.referrals(referrer_id, referee_id, status)
  values ('00000000-0000-0000-0000-000000007201'::uuid,
          '00000000-0000-0000-0000-000000007202'::uuid, 'pending');

select is((select count(*)::int from public._test_push_calls), 0,
  'INSERT pending does not fire the trigger');

-- S7 coverage: INSERT with status='confirmed' directly also does not fire
-- (trigger is `after update of status`, no INSERT branch). Pin this so a
-- future contributor adding an INSERT trigger doesn't accidentally double-
-- send pushes.
insert into public.referrals(referrer_id, referee_id, status)
  values ('00000000-0000-0000-0000-000000007201'::uuid,
          '00000000-0000-0000-0000-000000007203'::uuid, 'confirmed');

select is((select count(*)::int from public._test_push_calls), 0,
  'INSERT directly with status=confirmed does not fire the trigger');

-- ---------------------------------------------------------------------------
-- Happy path: pending -> confirmed fires once with correct payload + headers
-- ---------------------------------------------------------------------------

update public.referrals
   set status = 'confirmed', confirmed_at = now()
 where referee_id = '00000000-0000-0000-0000-000000007202'::uuid;

select is((select count(*)::int from public._test_push_calls), 1,
  'UPDATE pending -> confirmed fires exactly one http_post');

select is(
  (select url from public._test_push_calls order by id desc limit 1),
  'https://test.supabase.co/functions/v1/notify-referral-confirmed',
  'http_post URL is read from app.notify_referral_url (S3 fix)');

select is(
  (select body->>'referrer_id' from public._test_push_calls order by id desc limit 1),
  '00000000-0000-0000-0000-000000007201',
  'http_post body.referrer_id is the referrer uuid');

select is(
  (select body->>'referee_id' from public._test_push_calls order by id desc limit 1),
  '00000000-0000-0000-0000-000000007202',
  'http_post body.referee_id is the referee uuid');

select is(
  (select headers->>'X-Notify-Secret' from public._test_push_calls order by id desc limit 1),
  'test-secret-32-chars-of-randomness',
  'http_post headers carry X-Notify-Secret from app.notify_referral_secret (S1 fix)');

-- ---------------------------------------------------------------------------
-- WHEN-clause filters: no double-fires, no resurrection fires, no unrelated
-- column fires
-- ---------------------------------------------------------------------------

update public.referrals set status = 'confirmed'
 where referee_id = '00000000-0000-0000-0000-000000007202'::uuid;

select is((select count(*)::int from public._test_push_calls), 1,
  'UPDATE confirmed -> confirmed (no real flip) does not re-fire');

-- S4 fix: rejected -> confirmed must NOT fire. Set the row to 'rejected'
-- first via service-role bypass (the apply_referral RPC doesn't produce
-- this transition naturally, but support could in theory).
-- Use the third user/referee to keep the first happy-path row clean.
insert into public.referrals(referrer_id, referee_id, status)
  values ('00000000-0000-0000-0000-000000007201'::uuid,
          '00000000-0000-0000-0000-000000007203'::uuid, 'rejected')
  on conflict (referee_id) do update set status = 'rejected';

-- Clear the pre-fire call count so the next assertion is unambiguous.
truncate public._test_push_calls;

update public.referrals
   set status = 'confirmed'
 where referee_id = '00000000-0000-0000-0000-000000007203'::uuid;

select is((select count(*)::int from public._test_push_calls), 0,
  'UPDATE rejected -> confirmed does NOT fire (S4 — tightened WHEN clause)');

-- S7 coverage: UPDATE of a non-status column on a pending row should NOT
-- fire (the trigger is `after update of status`). Re-seed a pending row
-- with a known fixed UUID so we can target it in subsequent updates.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000'::uuid,
  '00000000-0000-0000-0000-000000007204'::uuid,
  'authenticated', 'authenticated', 'colcheck@test.sakina.local', '',
  now(), '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb, now(), now());

insert into public.referrals(referrer_id, referee_id, status)
  values ('00000000-0000-0000-0000-000000007201'::uuid,
          '00000000-0000-0000-0000-000000007204'::uuid, 'pending');

truncate public._test_push_calls;

update public.referrals
   set confirmed_at = now()
 where referee_id = '00000000-0000-0000-0000-000000007204'::uuid;

select is((select count(*)::int from public._test_push_calls), 0,
  'UPDATE of non-status column does NOT fire (UPDATE OF status only)');

-- ---------------------------------------------------------------------------
-- Fail-soft: unset GUCs should not fire an unauthenticated push
-- ---------------------------------------------------------------------------

-- Wipe the GUC for the next assertion.
reset app.notify_referral_secret;
truncate public._test_push_calls;

-- The pending row from the previous block (referee 7204) is still pending
-- (we only updated confirmed_at). Flip its status now while the secret is
-- unset — the trigger should no-op.
update public.referrals
   set status = 'confirmed'
 where referee_id = '00000000-0000-0000-0000-000000007204'::uuid;

select is((select count(*)::int from public._test_push_calls), 0,
  'Trigger no-ops when app.notify_referral_secret is unset (fail-soft)');

-- Restore the GUC for any subsequent assertion.
set local app.notify_referral_secret = 'test-secret-32-chars-of-randomness';

-- ---------------------------------------------------------------------------
-- Final structural pin: the X-Notify-Secret header key spelling.
-- A typo here would silently disable auth (header missing → edge function
-- 401s but trigger swallows). This is the canary.
-- ---------------------------------------------------------------------------

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000'::uuid,
  '00000000-0000-0000-0000-000000007205'::uuid,
  'authenticated', 'authenticated', 'canary@test.sakina.local', '',
  now(), '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb, now(), now());

insert into public.referrals(referrer_id, referee_id, status)
  values ('00000000-0000-0000-0000-000000007201'::uuid,
          '00000000-0000-0000-0000-000000007205'::uuid, 'pending');

truncate public._test_push_calls;

update public.referrals
   set status = 'confirmed'
 where referee_id = '00000000-0000-0000-0000-000000007205'::uuid;

select ok(
  (select headers ? 'X-Notify-Secret' from public._test_push_calls order by id desc limit 1),
  'http_post headers map contains the X-Notify-Secret key (exact spelling)');

select * from finish();

rollback;
