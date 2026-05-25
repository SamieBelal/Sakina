begin;
select plan(2);

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

select * from finish();
rollback;
