begin;
select plan(4);

select results_eq(
  $$ select value::text from public.app_config where key = 'onboarding_trim_enabled' $$,
  $$ values ('true'::text) $$,
  'onboarding_trim_enabled row exists with value true'
);
select results_eq(
  $$ select value::text from public.app_config where key = 'guided_tour_enabled' $$,
  $$ values ('true'::text) $$,
  'guided_tour_enabled row exists with value true'
);

-- C3 regression: the anon role must be able to read the kill-switch flags.
-- They are consumed pre-auth (onboarding before sign-up + cold-launch
-- primeCache), so an authenticated-only RLS policy silently zeroes them out
-- and the kill switch can never turn the trim/tour OFF on a fresh install.
set local role anon;
select isnt_empty(
  $$ select 1 from public.app_config where key = 'onboarding_trim_enabled' $$,
  'anon can read onboarding_trim_enabled'
);
select isnt_empty(
  $$ select 1 from public.app_config where key = 'guided_tour_enabled' $$,
  'anon can read guided_tour_enabled'
);
reset role;

select * from finish();
rollback;
