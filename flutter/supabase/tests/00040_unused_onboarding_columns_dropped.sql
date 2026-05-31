begin;
select plan(3);

select hasnt_column('public', 'user_profiles', 'onboarding_quran_connection',
  '2026-05-25 migration drops onboarding_quran_connection');
select hasnt_column('public', 'user_profiles', 'common_emotions',
  '2026-05-25 migration drops common_emotions');
select hasnt_column('public', 'user_profiles', 'aspirations',
  '2026-05-25 migration drops aspirations');

select * from finish();
rollback;
