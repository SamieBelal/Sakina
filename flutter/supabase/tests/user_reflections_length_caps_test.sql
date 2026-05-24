-- supabase/tests/user_reflections_length_caps_test.sql
--
-- Pins the length + shape validation from migration
-- 20260526000000_user_reflections_length_caps.sql.
--
-- Each test attempts an INSERT and asserts whether it's REJECTED (the
-- attack-class cases) or ACCEPTED (the honest-path cases). Wrapped in a
-- single BEGIN/ROLLBACK so no live state is persisted.
--
-- Run via: psql "$DATABASE_URL" -f supabase/tests/user_reflections_length_caps_test.sql
-- Or via Supabase MCP execute_sql.

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

-- Self-seed an auth.users row so the test is independent of branch DB data.
-- The handle_new_user trigger creates user_profiles + economy rows.
do $$
declare v_uid uuid := gen_random_uuid();
begin
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'p2-5-test-' || v_uid::text || '@example.com',
          '', now(), now(), now());
  perform set_config('test.uid', v_uid::text, false);
end $$;

-- Column order: id, user_id, saved_at, user_text, name, name_arabic,
-- reframe_preview, reframe, story, dua_arabic, dua_transliteration,
-- dua_translation, dua_source, related_names, verses (15 columns).

-- TEST 1: INSERT with reframe = 5000 chars -> REJECTED (length cap on reframe)
do $$
declare v_caught boolean := false;
begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      'ok','Ar-Rahman','الرحمن','preview',
      repeat('A', 5000), 'short','','','','',
      '[]'::jsonb, '[]'::jsonb
    );
  exception when others then v_caught := true;
  end;
  perform pg_temp.expect(v_caught, 'reframe = 5000 chars is rejected');
end $$;

-- TEST 2: INSERT with story = 10000 chars -> REJECTED (length cap on story)
do $$ declare v boolean := false; begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      'ok','Ar-Rahman','الرحمن','preview',
      'short', repeat('S', 10000), '','','','',
      '[]'::jsonb, '[]'::jsonb
    );
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'story = 10000 chars is rejected');
end $$;

-- TEST 3: INSERT with verses length = 15 -> REJECTED (array cap)
do $$ declare v boolean := false; begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      'ok','Ar-Rahman','الرحمن','preview',
      'short','short','','','','',
      '[]'::jsonb,
      (select jsonb_agg(jsonb_build_object('arabic','x','translation','y','reference','r')) from generate_series(1,15))
    );
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'verses array length = 15 is rejected');
end $$;

-- TEST 4: INSERT with verses element missing translation+reference -> REJECTED (shape trigger)
do $$ declare v boolean := false; begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      'ok','Ar-Rahman','الرحمن','preview',
      'short','short','','','','',
      '[]'::jsonb,
      '[{"arabic":"x"}]'::jsonb
    );
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'verses element missing translation/reference is rejected');
end $$;

-- TEST 5: INSERT with verses element = raw string (not object) -> REJECTED
do $$ declare v boolean := false; begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      'ok','Ar-Rahman','الرحمن','preview',
      'short','short','','','','',
      '[]'::jsonb,
      '["just a string"]'::jsonb
    );
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'verses element raw string is rejected');
end $$;

-- TEST 6: INSERT with verses element arabic field = 3000 chars -> REJECTED (per-field cap)
do $$ declare v boolean := false; begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      'ok','Ar-Rahman','الرحمن','preview',
      'short','short','','','','',
      '[]'::jsonb,
      jsonb_build_array(jsonb_build_object(
        'arabic', repeat('A', 3000),
        'translation', 'y',
        'reference', 'r'))
    );
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'verses element arabic = 3000 chars is rejected');
end $$;

-- TEST 7 (HONEST PATH): 3500-char reframe + 5 well-shaped verses -> ACCEPTED
do $$ declare v boolean := false; begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      'i feel anxious','Ar-Rahman','الرحمن','preview',
      repeat('a', 3500), 'a short story','','','','',
      '[]'::jsonb,
      (select jsonb_agg(jsonb_build_object('arabic','x','translation','y','reference','Quran 2:' || g)) from generate_series(1,5) g)
    );
    v := true;
  exception when others then v := false; end;
  perform pg_temp.expect(v, 'HONEST PATH: 3500-char reframe + 5 verses accepted');
end $$;

-- TEST 8 (HONEST PATH): verses = empty array -> ACCEPTED
-- (Schema enforces NOT NULL on verses, so we use '[]'::jsonb rather than NULL.
-- This pins that the array cap + shape trigger both accept an empty array.)
do $$ declare v boolean := false; begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      'ok','Ar-Rahman','الرحمن','preview',
      'short','short','','','','',
      '[]'::jsonb,
      '[]'::jsonb
    );
    v := true;
  exception when others then v := false; end;
  perform pg_temp.expect(v, 'HONEST PATH: empty verses array accepted');
end $$;

-- TEST 9: INSERT with related_names length = 12 -> REJECTED (array cap)
do $$ declare v boolean := false; begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      'ok','Ar-Rahman','الرحمن','preview',
      'short','short','','','','',
      (select jsonb_agg(jsonb_build_object('name','n','nameArabic','ن')) from generate_series(1,12)),
      '[]'::jsonb
    );
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'related_names array length = 12 is rejected');
end $$;

-- TEST 10: INSERT with user_text = 3000 chars -> REJECTED (length cap)
do $$ declare v boolean := false; begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      repeat('u', 3000),'Ar-Rahman','الرحمن','preview',
      'short','short','','','','',
      '[]'::jsonb, '[]'::jsonb
    );
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'user_text = 3000 chars is rejected');
end $$;

-- TEST 11: INSERT with dua_arabic = 2000 chars -> REJECTED (length cap)
do $$ declare v boolean := false; begin
  begin
    insert into public.user_reflections (
      id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
      reframe, story, dua_arabic, dua_transliteration, dua_translation,
      dua_source, related_names, verses
    ) values (
      gen_random_uuid(), current_setting('test.uid')::uuid, now(),
      'ok','Ar-Rahman','الرحمن','preview',
      'short','short', repeat('د', 2000),'','','',
      '[]'::jsonb, '[]'::jsonb
    );
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'dua_arabic = 2000 chars is rejected');
end $$;

-- Final report
do $$
declare total int; passed int; failed_names text;
begin
  total  := current_setting('test.total')::int;
  passed := current_setting('test.passed')::int;
  failed_names := current_setting('test.failed_names');
  raise notice E'\n========================';
  raise notice 'user_reflections_length_caps_test: % / % passed', passed, total;
  if failed_names <> '' then
    raise exception 'FAILURES: %', failed_names;
  end if;
  if passed <> 11 then
    raise exception 'Expected 11 passes, got %', passed;
  end if;
end $$;

rollback;
