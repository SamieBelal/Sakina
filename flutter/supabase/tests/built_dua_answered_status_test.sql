-- supabase/tests/built_dua_answered_status_test.sql
--
-- Pins migration 20260803000000_built_dua_answered_status.sql:
--   * `status` defaults to 'open' and admits only the two known values
--   * `answered_at` is non-null EXACTLY when status is 'answered' — the pair is
--     one fact stated twice, and the client's upsert writes the whole row, so
--     either half moving without the other has to be refused at the boundary
--   * the supporting index for "the oldest still-open duʿā for this user"
--   * sync_all_user_data() still carries ALL THREE older lineages (W1 profile
--     keys, lantern cosmetics, the Wave B reflection keys) alongside the two
--     new built-duʿā keys
--
-- Same style as user_reflections_journal_entries_test.sql: raise-on-failure,
-- wrapped in a single BEGIN/ROLLBACK so no live state is persisted. Inserts run
-- as the owner — this tests the CHECKs and the index, not RLS.
--
-- Run via: psql "$DATABASE_URL" -f supabase/tests/built_dua_answered_status_test.sql

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

do $$
declare v_uid uuid := gen_random_uuid();
begin
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'answered-test-' || v_uid::text || '@example.com',
          '', now(), now(), now());
  perform set_config('test.uid', v_uid::text, false);
end $$;

-- Helper: insert a built duʿā. Returns true when the write was accepted.
create or replace function pg_temp.try_insert_dua(
  p_status text default 'open',
  p_answered_at timestamptz default null,
  p_saved_at timestamptz default now()
) returns boolean language plpgsql as $$
declare v_ok boolean := true;
begin
  begin
    insert into public.user_built_duas
      (id, user_id, saved_at, need, arabic, transliteration, translation,
       status, answered_at)
    values
      (gen_random_uuid(), current_setting('test.uid')::uuid, p_saved_at,
       'a job that lets me pray on time', 'اللهم', 'Allahumma', 'O Allah',
       p_status, p_answered_at);
  exception when others then
    v_ok := false;
  end;
  return v_ok;
end $$;

-- ── status ────────────────────────────────────────────────────────────────

-- TEST 1: a legacy-shaped insert (no status column named) defaults to 'open'
-- with a null answered_at. This is what makes "no backfill" true for every duʿā
-- already in prod.
do $$
declare v_id uuid := gen_random_uuid();
begin
  insert into public.user_built_duas
    (id, user_id, saved_at, need, arabic, transliteration, translation)
  values
    (v_id, current_setting('test.uid')::uuid, now(),
     'n', 'ا', 't', 'tr');
  perform pg_temp.expect(
    (select status from public.user_built_duas where id = v_id) = 'open',
    'legacy insert defaults to status=open');
  perform pg_temp.expect(
    (select answered_at from public.user_built_duas where id = v_id) is null,
    'legacy insert leaves answered_at null');
end $$;

-- TEST 2: 'answered' with a timestamp is accepted.
select pg_temp.expect(
  pg_temp.try_insert_dua('answered', now()),
  'status=answered with answered_at accepted');

-- TEST 3: anything else rejected. A third value escapes every `status =`
-- predicate the prompt selector and the journal chip rely on — and the app
-- does not adjudicate duʿā, so there is no 'partially answered'.
select pg_temp.expect(
  NOT pg_temp.try_insert_dua('pending', null),
  'unknown status rejected');

-- ── the pair moves together ───────────────────────────────────────────────

-- TEST 4: answered with NO timestamp is refused. Otherwise the journal renders
-- an "Answered" chip over nothing.
select pg_temp.expect(
  NOT pg_temp.try_insert_dua('answered', null),
  'answered without answered_at rejected');

-- TEST 5: open WITH a timestamp is refused. This is the undo path: a client
-- that flips `status` back and leaves the timestamp behind gets its whole undo
-- rolled back rather than a half-open row.
select pg_temp.expect(
  NOT pg_temp.try_insert_dua('open', now()),
  'open with a stale answered_at rejected');

-- TEST 6: the same constraint holds on UPDATE, not just INSERT — the client
-- marks by upserting the whole row, which is an UPDATE on collision.
do $$
declare v_id uuid := gen_random_uuid();
        v_ok boolean := true;
begin
  insert into public.user_built_duas
    (id, user_id, saved_at, need, arabic, transliteration, translation)
  values (v_id, current_setting('test.uid')::uuid, now(), 'n', 'ا', 't', 'tr');
  begin
    update public.user_built_duas set status = 'answered' where id = v_id;
  exception when others then
    v_ok := false;
  end;
  perform pg_temp.expect(NOT v_ok,
    'UPDATE to answered without a timestamp is rejected too');

  perform pg_temp.expect(
    (select status from public.user_built_duas where id = v_id) = 'open',
    'the refused update left the row open');
end $$;

-- TEST 7: the full, correct transition is accepted on UPDATE.
do $$
declare v_id uuid := gen_random_uuid();
begin
  insert into public.user_built_duas
    (id, user_id, saved_at, need, arabic, transliteration, translation)
  values (v_id, current_setting('test.uid')::uuid, now(), 'n', 'ا', 't', 'tr');
  update public.user_built_duas
     set status = 'answered', answered_at = now()
   where id = v_id;
  perform pg_temp.expect(
    (select status = 'answered' and answered_at is not null
       from public.user_built_duas where id = v_id),
    'marking answered moves both columns');

  -- And the undo, in full.
  update public.user_built_duas
     set status = 'open', answered_at = null
   where id = v_id;
  perform pg_temp.expect(
    (select status = 'open' and answered_at is null
       from public.user_built_duas where id = v_id),
    'the undo clears both columns');
end $$;

-- ── indexes ───────────────────────────────────────────────────────────────

-- TEST 8: the index behind "the oldest still-open duʿā for this user".
select pg_temp.expect(
  (select count(*) from pg_indexes
    where schemaname = 'public' and tablename = 'user_built_duas'
      and indexname = 'idx_built_duas_user_status_saved') = 1,
  'idx_built_duas_user_status_saved exists');

-- ── sync_all_user_data() superset ─────────────────────────────────────────

-- TEST 9: the re-emitted function carries the two new keys AND all three older
-- lineages. This is the collision tripwire (20260726000300 vs 20260727100300):
-- re-emitting from a stale base silently deletes sections, and by Wave E there
-- are three separate sets of keys a stale base could drop.
do $$
declare v_def text := pg_get_functiondef('public.sync_all_user_data()'::regprocedure);
begin
  perform pg_temp.expect(
    v_def like '%''status'', d.status%'
    and v_def like '%''answered_at'', d.answered_at%',
    'sync union carries the two new built-dua keys');
  perform pg_temp.expect(
    v_def like '%''source'', r.source%'
    and v_def like '%''entry_local_day'', r.entry_local_day%'
    and v_def like '%''thread'', r.thread%'
    and v_def like '%''azm'', r.azm%',
    'sync union still carries the Wave B reflection keys');
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

-- TEST 10: no notification template, no scheduled send, nothing that could
-- become a push. COPY_VERSION is frozen at 'reel_v1' until the keep read, and
-- the answered-duʿā mechanic is exactly the kind of thing that would tempt one.
select pg_temp.expect(
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname like '%answered%dua%') = 0,
  'no answered-dua RPC was added (in-app only, no push)');

-- Report.
do $$
declare v_total int := current_setting('test.total')::int;
        v_passed int := current_setting('test.passed')::int;
        v_failed text := current_setting('test.failed_names', true);
begin
  raise notice 'answered-dua tests: %/% passed', v_passed, v_total;
  if v_passed <> v_total then
    raise exception 'FAILED answered-dua tests: %', v_failed;
  end if;
end $$;

rollback;
