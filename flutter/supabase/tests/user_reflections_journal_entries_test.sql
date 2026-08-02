-- supabase/tests/user_reflections_journal_entries_test.sql
--
-- Pins migration 20260802030000_user_reflections_journal_entries.sql:
--   * `source` defaults to 'reflect' and admits only the two known values
--   * ONE muḥāsabah row per (user_id, entry_local_day) — the idempotency
--     guarantee `completeDeeper()` writes against, and the key the Wave C time
--     machine joins on
--   * the partial index leaves 'reflect' rows alone
--   * `azm` and `thread` carry the same class of length/shape caps the sibling
--     migrations (20260524164841, 20260714000000, 20260715000000) exist to
--     enforce — unbounded user text in a jsonb array is that same hole
--   * sync_all_user_data() still carries BOTH older lineages (W1 profile keys,
--     lantern cosmetics) alongside the four new reflection keys
--
-- Same style as user_reflections_beat_data_test.sql: raise-on-failure, wrapped
-- in a single BEGIN/ROLLBACK so no live state is persisted. Inserts run as the
-- owner — this tests the CHECKs / trigger / unique index, not RLS.
--
-- Run via: psql "$DATABASE_URL" -f supabase/tests/user_reflections_journal_entries_test.sql

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

-- Self-seed two auth.users rows so the test is independent of branch data, and
-- so the "another user's same day" case has a second owner to write as.
do $$
declare v_uid uuid := gen_random_uuid();
        v_uid_b uuid := gen_random_uuid();
begin
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'journal-test-' || v_uid::text || '@example.com',
          '', now(), now(), now()),
         (v_uid_b, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'journal-test-' || v_uid_b::text || '@example.com',
          '', now(), now(), now());
  perform set_config('test.uid', v_uid::text, false);
  perform set_config('test.uid_b', v_uid_b::text, false);
end $$;

-- Helper: insert a journal row. Returns true when the write was accepted.
create or replace function pg_temp.try_insert_entry(
  p_source text,
  p_day date,
  p_thread jsonb default '[]'::jsonb,
  p_azm text default null,
  p_user uuid default null
) returns boolean language plpgsql as $$
declare v_ok boolean := true;
begin
  begin
    insert into public.user_reflections
      (id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
       reframe, story, verses, dua_arabic, dua_transliteration, dua_translation,
       dua_source, related_names, source, entry_local_day, thread, azm)
    values
      (gen_random_uuid(),
       coalesce(p_user, current_setting('test.uid')::uuid), now(),
       'the day I had', 'Al-Lateef', 'اللطيف', 'p', 'r', 's', '[]'::jsonb,
       '', '', '', '', '[]'::jsonb, p_source, p_day, p_thread, p_azm);
  exception when others then
    v_ok := false;
  end;
  return v_ok;
end $$;

-- ── source ────────────────────────────────────────────────────────────────

-- TEST 1: a legacy-shaped insert (no source column named) defaults to 'reflect'.
-- This is what makes "no backfill needed" true for every row already in prod.
do $$
declare v_id uuid := gen_random_uuid();
begin
  insert into public.user_reflections
    (id, user_id, saved_at, user_text, name, name_arabic, reframe_preview,
     reframe, story, verses, dua_arabic, dua_transliteration, dua_translation,
     dua_source, related_names)
  values
    (v_id, current_setting('test.uid')::uuid, now(),
     'u', 'Al-Lateef', 'اللطيف', 'p', 'r', 's', '[]'::jsonb,
     '', '', '', '', '[]'::jsonb);
  perform pg_temp.expect(
    (select source from public.user_reflections where id = v_id) = 'reflect',
    'legacy insert defaults to source=reflect');
  perform pg_temp.expect(
    (select thread from public.user_reflections where id = v_id) = '[]'::jsonb,
    'legacy insert defaults to an empty thread');
end $$;

-- TEST 2: 'muhasabah' accepted.
select pg_temp.expect(
  pg_temp.try_insert_entry('muhasabah', date '2026-08-01'),
  'source=muhasabah accepted');

-- TEST 3: anything else rejected — a third value would escape every
-- `source =` predicate the journal and the unique index rely on.
select pg_temp.expect(
  NOT pg_temp.try_insert_entry('journal', date '2026-08-05'),
  'unknown source rejected');

-- ── one muḥāsabah per local day ───────────────────────────────────────────

-- TEST 4: the SAME user, the SAME local day, twice -> the second is refused.
-- Not a duplicate and not an overwrite: `completeDeeper()` is best-effort and
-- may replay, and this index is what makes the replay a no-op.
select pg_temp.expect(
  NOT pg_temp.try_insert_entry('muhasabah', date '2026-08-01'),
  'a second muhasabah row for the same local day is rejected');

-- TEST 5: a different local day is a different night.
select pg_temp.expect(
  pg_temp.try_insert_entry('muhasabah', date '2026-08-02'),
  'a muhasabah row for another local day is accepted');

-- TEST 6: another user's 2026-08-01 is untouched by the first user's row.
select pg_temp.expect(
  pg_temp.try_insert_entry('muhasabah', date '2026-08-01', '[]'::jsonb, null,
                           current_setting('test.uid_b')::uuid),
  'another user may have their own row for the same local day');

-- TEST 7: the index is PARTIAL — Reflect entries are unlimited per day and
-- must never be caught by it, even carrying the same entry_local_day.
select pg_temp.expect(
  pg_temp.try_insert_entry('reflect', date '2026-08-01'),
  'a reflect row on that day is accepted');
select pg_temp.expect(
  pg_temp.try_insert_entry('reflect', date '2026-08-01'),
  'a SECOND reflect row on that day is still accepted');

-- TEST 8: the guarantee's honest edge — NULL entry_local_day rows do NOT
-- collide (Postgres treats NULLs as distinct in a unique index). Recorded here
-- so no caller mistakes "one per day" for "one per user with no day".
select pg_temp.expect(
  pg_temp.try_insert_entry('muhasabah', null)
  AND pg_temp.try_insert_entry('muhasabah', null),
  'null entry_local_day rows do not collide (NULLs are distinct)');

-- TEST 9: the index exists with the expected predicate and columns.
select pg_temp.expect(
  (select count(*) from pg_indexes
    where schemaname = 'public' and tablename = 'user_reflections'
      and indexname = 'uniq_muhasabah_per_local_day'
      and indexdef like '%UNIQUE%'
      and indexdef like '%(user_id, entry_local_day)%'
      and indexdef like '%muhasabah%') = 1,
  'uniq_muhasabah_per_local_day exists as a unique partial index');

-- TEST 10: the supporting index for the journal feed / time-machine lookup.
select pg_temp.expect(
  (select count(*) from pg_indexes
    where schemaname = 'public' and tablename = 'user_reflections'
      and indexname = 'idx_reflections_user_source_day') = 1,
  'idx_reflections_user_source_day exists');

-- ── azm ───────────────────────────────────────────────────────────────────

-- TEST 11: an honest one-line ʿazm is accepted.
select pg_temp.expect(
  pg_temp.try_insert_entry('reflect', null, '[]'::jsonb,
    'Tomorrow I will call my mother before Maghrib.'),
  'a short azm is accepted');

-- TEST 12: exactly at the cap is accepted (the boundary, not just past it).
select pg_temp.expect(
  pg_temp.try_insert_entry('reflect', null, '[]'::jsonb, repeat('x', 500)),
  'azm at exactly 500 chars accepted');

-- TEST 13: over the cap is rejected.
select pg_temp.expect(
  NOT pg_temp.try_insert_entry('reflect', null, '[]'::jsonb, repeat('x', 501)),
  'oversized azm rejected');

-- ── thread ────────────────────────────────────────────────────────────────

-- TEST 14: a well-formed thread is accepted.
select pg_temp.expect(
  pg_temp.try_insert_entry('reflect', null, jsonb_build_array(
    jsonb_build_object('at', '2026-08-02T21:14:00.000Z', 'text', 'one more thing'),
    jsonb_build_object('at', '2026-08-02T22:02:00.000Z', 'text', 'and this'))),
  'a well-formed thread is accepted');

-- TEST 15: `at` is optional.
select pg_temp.expect(
  pg_temp.try_insert_entry('reflect', null,
    jsonb_build_array(jsonb_build_object('text', 'no timestamp'))),
  'thread element without at is accepted');

-- TEST 16: more than 20 appends rejected (element-count cap).
select pg_temp.expect(
  NOT pg_temp.try_insert_entry('reflect', null, (
    select jsonb_agg(jsonb_build_object('text', 'x')) from generate_series(1, 21))),
  'more than 20 thread elements rejected');

-- TEST 17: an oversized append rejected — the whole point of the trigger.
select pg_temp.expect(
  NOT pg_temp.try_insert_entry('reflect', null,
    jsonb_build_array(jsonb_build_object('text', repeat('x', 2049)))),
  'oversized thread element text rejected');

-- TEST 18: a non-object element rejected.
select pg_temp.expect(
  NOT pg_temp.try_insert_entry('reflect', null, jsonb_build_array('a string')),
  'non-object thread element rejected');

-- TEST 19: a non-string text rejected.
select pg_temp.expect(
  NOT pg_temp.try_insert_entry('reflect', null,
    jsonb_build_array(jsonb_build_object('text', 42))),
  'non-string thread text rejected');

-- TEST 20: an unknown key rejected — without the whitelist a client can park
-- an arbitrarily large blob under a key nothing reads (20260715000000).
select pg_temp.expect(
  NOT pg_temp.try_insert_entry('reflect', null,
    jsonb_build_array(jsonb_build_object('text', 'ok', 'evil', repeat('x', 100)))),
  'unknown thread key rejected');

-- TEST 21: a non-array thread rejected (top-level type CHECK).
select pg_temp.expect(
  NOT pg_temp.try_insert_entry('reflect', null, '{"text":"x"}'::jsonb),
  'non-array thread rejected');

-- ── sync_all_user_data() superset ─────────────────────────────────────────

-- TEST 22: the re-emitted function still carries BOTH older lineages plus the
-- four new keys. This is the collision tripwire (20260726000300 vs
-- 20260727100300): re-emitting from a stale base silently deletes sections.
do $$
declare v_def text := pg_get_functiondef('public.sync_all_user_data()'::regprocedure);
begin
  perform pg_temp.expect(
    v_def like '%''source'', r.source%'
    and v_def like '%''entry_local_day'', r.entry_local_day%'
    and v_def like '%''thread'', r.thread%'
    and v_def like '%''azm'', r.azm%',
    'sync union carries the four new reflection keys');
  perform pg_temp.expect(
    v_def like '%weekly_pool_week_start%'
    and v_def like '%free_tier_cohort%'
    and v_def like '%acquisition_promise%',
    'sync union still carries the One Ship W1 profile keys');
  perform pg_temp.expect(
    v_def like '%noor_balance%'
    and v_def like '%equipped_lantern_skin%'
    and v_def like '%user_cosmetics%',
    'sync union still carries the lantern cosmetics sections');
end $$;

-- Report.
do $$
declare v_total int := current_setting('test.total')::int;
        v_passed int := current_setting('test.passed')::int;
        v_failed text := current_setting('test.failed_names', true);
begin
  raise notice 'journal-entry tests: %/% passed', v_passed, v_total;
  if v_passed <> v_total then
    raise exception 'FAILED journal-entry tests: %', v_failed;
  end if;
end $$;

rollback;
