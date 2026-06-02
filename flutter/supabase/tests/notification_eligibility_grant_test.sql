-- Regression guard for F-01 (2026-06-01): get_eligible_notification_users is a
-- SECURITY DEFINER function returning cross-user PII. It must be callable ONLY by
-- service_role (the send-scheduled-notifications cron) — never anon/authenticated,
-- which would let any client enumerate push-enabled users.
-- The existing pgtap suite tested eligibility BEHAVIOR but not EXECUTE grants, so
-- this drift class was uncovered. See docs/qa/findings/2026-06-01-notif-eligibility-anon-enumeration.md
begin;

select plan(3);

select ok(
  not has_function_privilege(
    'anon',
    'public.get_eligible_notification_users(text,text,integer,boolean,integer,integer,boolean)',
    'EXECUTE'),
  'anon cannot EXECUTE get_eligible_notification_users (no PII enumeration)');

select ok(
  not has_function_privilege(
    'authenticated',
    'public.get_eligible_notification_users(text,text,integer,boolean,integer,integer,boolean)',
    'EXECUTE'),
  'authenticated cannot EXECUTE get_eligible_notification_users');

select ok(
  has_function_privilege(
    'service_role',
    'public.get_eligible_notification_users(text,text,integer,boolean,integer,integer,boolean)',
    'EXECUTE'),
  'service_role CAN EXECUTE get_eligible_notification_users (cron path intact)');

select * from finish();
rollback;
