-- supabase/tests/user_reflections_beat_data_test.sql
--
-- Pins the beat_data shape validation from migration
-- 20260714000000_user_reflections_beat_data.sql:
--   - valid beat_data is accepted
--   - NULL beat_data (legacy rows) is accepted
--   - wrong field type / oversized field / >3 storyBeats are rejected
--
-- Wrapped in a single BEGIN/ROLLBACK so no live state is persisted.
-- Run via: psql "$DATABASE_URL" -f supabase/tests/user_reflections_beat_data_test.sql

begin;

create or replace function pg_temp.expect(cond boolean, name text)
returns void language plpgsql as $$
begin
  if cond then
    perform set_config('test.passed',
      (coalesce(current_setting('test.passed', true), '0')::int + 1)::text, false);
  else
    perform set_config('test.failed_names',
      coalesce(current_setting('test.failed_names', true), '') || name || ';', false);
  end if;
  perform set_config('test.total',
    (coalesce(current_setting('test.total', true), '0')::int + 1)::text, false);
end;
$$;

select set_config('test.total','0',false),
       set_config('test.passed','0',false),
       set_config('test.failed_names','',false);

-- Self-seed an auth.users row so the test is independent of branch data.
do $$
declare v_uid uuid := gen_random_uuid();
begin
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'beat-test-' || v_uid::text || '@example.com',
          '', now(), now(), now());
  perform set_config('test.uid', v_uid::text, false);
end $$;

-- Helper: insert a user_reflections row with the given beat_data (as postgres,
-- so RLS is not in the way — we're testing the CHECK/trigger, not RLS).
create or replace function pg_temp.try_insert_beat(p_beat jsonb)
returns boolean language plpgsql as $$
declare v_ok boolean := true;
begin
  begin
    insert into public.user_reflections
      (id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
       reframe, story, verses, dua_arabic, dua_transliteration, dua_translation,
       dua_source, related_names, beat_data)
    values
      (gen_random_uuid(), current_setting('test.uid')::uuid, now()::text,
       'u', 'Al-Lateef', 'اللطيف', 'p', 'r', 's', '[]'::jsonb,
       '', '', '', '', '[]'::jsonb, p_beat);
  exception when others then
    v_ok := false;
  end;
  return v_ok;
end $$;

-- TEST 1: valid beat_data accepted.
select pg_temp.expect(
  pg_temp.try_insert_beat(jsonb_build_object(
    'reframeKey', 'Allah was gentle with you',
    'reframeBody', 'Even unseen, His kindness arranged what you could not.',
    'storyTitle', 'Musa at the Sea',
    'storyBeats', jsonb_build_array('The sea stood before him.', 'He was not afraid.'),
    'storySource', 'Qur''an 26:62',
    'takeaway', 'What feels like drowning may be the sea parting.')),
  'valid beat_data accepted');

-- TEST 2: NULL beat_data (legacy row) accepted.
select pg_temp.expect(pg_temp.try_insert_beat(NULL), 'null beat_data accepted');

-- TEST 3: wrong field type (reframeKey as a number) rejected.
select pg_temp.expect(
  NOT pg_temp.try_insert_beat(jsonb_build_object('reframeKey', 42)),
  'non-string reframeKey rejected');

-- TEST 4: oversized field (reframeKey > 200 chars) rejected.
select pg_temp.expect(
  NOT pg_temp.try_insert_beat(jsonb_build_object('reframeKey', repeat('x', 201))),
  'oversized reframeKey rejected');

-- TEST 5: more than 3 storyBeats rejected.
select pg_temp.expect(
  NOT pg_temp.try_insert_beat(jsonb_build_object(
    'storyBeats', jsonb_build_array('a', 'b', 'c', 'd'))),
  'more than 3 storyBeats rejected');

-- TEST 6: non-object beat_data rejected (top-level type CHECK).
select pg_temp.expect(
  NOT pg_temp.try_insert_beat('"a string"'::jsonb),
  'non-object beat_data rejected');

-- Report.
do $$
declare v_total int := current_setting('test.total')::int;
        v_passed int := current_setting('test.passed')::int;
        v_failed text := current_setting('test.failed_names', true);
begin
  raise notice 'beat_data tests: %/% passed', v_passed, v_total;
  if v_passed <> v_total then
    raise exception 'FAILED beat_data tests: %', v_failed;
  end if;
end $$;

rollback;
