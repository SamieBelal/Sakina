-- Regression test for sync_all_user_data() reflections.verses field.
--
-- Pins the fix in 20260510020000_restore_reflection_verses_in_sync.sql.
-- The freemium-redesign migration (20260509120000) silently dropped
-- `'verses', r.verses` from the reflections jsonb_build_object when it
-- recreated the function. On app launch the Flutter client hydrates local
-- caches from this payload — without `verses`, saved reflections lose their
-- Quran verses. This test asserts the field is present and round-trips the
-- exact value inserted into user_reflections.
--
-- Pattern mirrors backend_rls_audit.sql: one transaction, DO block collecting
-- failures via pg_temp.expect, raise on failures, rollback. No state persists.
--
-- Run via:
--   mcp__supabase__execute_sql query=$(cat sync_all_user_data_returns_verses_test.sql)

begin;

-- expect(cond, name): records each assertion.
create or replace function pg_temp.expect(cond boolean, name text)
returns void language plpgsql as $$
begin
  perform set_config('test.total',
    (coalesce(current_setting('test.total', true)::int, 0) + 1)::text, true);
  if not cond then
    perform set_config('test.failed',
      coalesce(current_setting('test.failed', true), '') || ' | ' || name, true);
  end if;
end
$$;

-- Local helper: same shape as the one in backend_rls_audit.sql.
create or replace function pg_temp.test_insert_auth_user(
  p_id uuid,
  p_email text
) returns void
language sql
as $$
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  )
  values (
    '00000000-0000-0000-0000-000000000000'::uuid,
    p_id, 'authenticated', 'authenticated', p_email, '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', split_part(p_email, '@', 1)),
    now(), now()
  );
$$;

select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000301',
  'verses-sync@test.sakina.local'
);

-- Insert a reflection with a non-empty verses array. The verses column was
-- added in 20260415125147_add_reflection_verses.sql as `jsonb not null
-- default '[]'::jsonb`.
insert into public.user_reflections (
  user_id, user_text, name, name_arabic, verses, saved_at
) values (
  '00000000-0000-0000-0000-000000000301',
  'Need patience',
  'As-Sabur',
  'الصبور',
  '[
    {
      "arabic": "وَالْكَاظِمِينَ الْغَيْظَ وَالْعَافِينَ عَنِ النَّاسِ",
      "translation": "Those who restrain anger and pardon the people.",
      "reference": "Al-Imran 3:134"
    }
  ]'::jsonb,
  now()
);

do $body$
declare
  uid constant uuid := '00000000-0000-0000-0000-000000000301';
  expected_verses constant jsonb := '[
    {
      "arabic": "وَالْكَاظِمِينَ الْغَيْظَ وَالْعَافِينَ عَنِ النَّاسِ",
      "translation": "Those who restrain anger and pardon the people.",
      "reference": "Al-Imran 3:134"
    }
  ]'::jsonb;
  failures text;
  total int;
  payload jsonb;
  reflection jsonb;
  returned_verses jsonb;
begin
  perform set_config('test.total', '0', true);
  perform set_config('test.failed', '', true);

  -- Impersonate the test user so auth.uid() resolves inside the SECURITY
  -- DEFINER function.
  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid::text, 'role', 'authenticated')::text, true);

  payload := public.sync_all_user_data();

  perform pg_temp.expect(jsonb_typeof(payload->'reflections') = 'array',
    'reflections section is an array');

  perform pg_temp.expect(jsonb_array_length(payload->'reflections') = 1,
    'reflections array has exactly one element');

  reflection := payload->'reflections'->0;

  -- The whole point of the regression test: the verses key must exist.
  perform pg_temp.expect(reflection ? 'verses',
    'reflection includes the verses key (regression: dropped by freemium redesign)');

  returned_verses := reflection->'verses';

  perform pg_temp.expect(jsonb_typeof(returned_verses) = 'array',
    'reflection.verses is a jsonb array');

  perform pg_temp.expect(jsonb_array_length(returned_verses) > 0,
    'reflection.verses is non-empty');

  perform pg_temp.expect(returned_verses = expected_verses,
    'reflection.verses round-trips the inserted value byte-for-byte');

  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);

  failures := current_setting('test.failed', true);
  total := coalesce(current_setting('test.total', true)::int, 0);

  if failures is not null and length(failures) > 0 then
    raise exception 'FAILURES (% of % assertions): %',
      array_length(string_to_array(trim(both ' |' from failures), ' | '), 1),
      total,
      failures;
  end if;

  raise notice 'ALL PASS (% tests)', total;
end
$body$;

rollback;
