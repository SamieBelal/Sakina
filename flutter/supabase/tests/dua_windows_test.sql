-- dua_windows_test.sql
--
-- pgtap coverage for the dua_windows calendar table (migration
-- 20260715120000_dua_windows.sql). Asserts:
--   (a) anon can SELECT from dua_windows (public-catalog posture)
--   (b) anon CANNOT INSERT / UPDATE / DELETE (no write policy)
--   (c) the table exists with the expected columns + types
--   plus: the seed-horizon sentinel exists and the seed is non-empty and
--   passes its own range check.
--
-- Style mirrors ramadan_gifts_test.sql: begin / plan / … / finish / rollback.

begin;

select plan(27);

-- ---------------------------------------------------------------------------
-- (c) Structure — table + columns + types
-- ---------------------------------------------------------------------------
select has_table('public', 'dua_windows', 'dua_windows table exists');

select has_column('public', 'dua_windows', 'id',         'dua_windows.id exists');
select has_column('public', 'dua_windows', 'kind',       'dua_windows.kind exists');
select has_column('public', 'dua_windows', 'tier',       'dua_windows.tier exists');
select has_column('public', 'dua_windows', 'title_key',  'dua_windows.title_key exists');
select has_column('public', 'dua_windows', 'start_date', 'dua_windows.start_date exists');
select has_column('public', 'dua_windows', 'end_date',   'dua_windows.end_date exists');
select has_column('public', 'dua_windows', 'source_ref', 'dua_windows.source_ref exists');

select col_is_pk('public', 'dua_windows', 'id', 'dua_windows.id is the primary key');

-- All-day windows MUST be bare dates (spec §4: expanded to device-local
-- midnight; a timestamptz here would re-introduce the date-line bug).
select col_type_is('public', 'dua_windows', 'start_date', 'date',
  'start_date is a bare date (not timestamptz)');
select col_type_is('public', 'dua_windows', 'end_date', 'date',
  'end_date is a bare date (not timestamptz)');

select col_not_null('public', 'dua_windows', 'kind',       'kind is NOT NULL');
select col_not_null('public', 'dua_windows', 'tier',       'tier is NOT NULL');
select col_not_null('public', 'dua_windows', 'start_date', 'start_date is NOT NULL');
select col_not_null('public', 'dua_windows', 'end_date',   'end_date is NOT NULL');

-- Sentinel table for the seed horizon.
select has_table('public', 'dua_windows_meta', 'dua_windows_meta sentinel table exists');
select has_column('public', 'dua_windows_meta', 'last_seeded_through',
  'dua_windows_meta.last_seeded_through exists');

-- ---------------------------------------------------------------------------
-- Seed sanity (runs as the migration/superuser role, pre-anon)
-- ---------------------------------------------------------------------------
select ok(
  (select count(*) from public.dua_windows) > 0,
  'dua_windows is seeded (non-empty)'
);

select ok(
  not exists (select 1 from public.dua_windows where end_date < start_date),
  'every seeded window has end_date >= start_date'
);

-- The dua_window_range_valid CHECK must reject an inverted range (end_date <
-- start_date). Attempt an insert with start > end and assert the check
-- constraint fires (SQLSTATE 23514). Runs as superuser so RLS can't mask it.
select throws_ok(
  $$ insert into public.dua_windows
       (id, kind, tier, title_key, start_date, end_date)
     values ('inverted_range', 'arafah', 'hero', 'x', '2027-01-02', '2027-01-01') $$,
  '23514',
  null,
  'dua_window_range_valid CHECK rejects an inverted date range (23514)'
);

select ok(
  (select last_seeded_through from public.dua_windows_meta) is not null,
  'last_seeded_through sentinel is populated'
);

-- ---------------------------------------------------------------------------
-- (a) anon can SELECT
-- ---------------------------------------------------------------------------
set local role anon;

select ok(
  (select count(*) from public.dua_windows) > 0,
  '(a) anon can SELECT dua_windows and sees seeded rows'
);

select ok(
  (select count(*) from public.dua_windows_meta) = 1,
  '(a) anon can SELECT the dua_windows_meta sentinel'
);

-- ---------------------------------------------------------------------------
-- (b) anon CANNOT INSERT / UPDATE / DELETE
--
-- With RLS enabled and NO write policy:
--   * INSERT raises a policy violation (SQLSTATE 42501) — the new row has no
--     WITH CHECK policy that permits it.
--   * UPDATE / DELETE do NOT raise; RLS instead makes every row INVISIBLE to
--     the anon role, so the statement matches zero rows and is a silent no-op.
-- We assert the security property directly for each: INSERT throws, and
-- UPDATE/DELETE affect zero rows AND leave the seeded row untouched.
-- ---------------------------------------------------------------------------
select throws_ok(
  $$ insert into public.dua_windows
       (id, kind, tier, title_key, start_date, end_date)
     values ('anon_hack', 'arafah', 'hero', 'x', '2027-05-15', '2027-05-15') $$,
  '42501',
  'new row violates row-level security policy for table "dua_windows"',
  '(b) anon INSERT into dua_windows is denied (42501)'
);

-- UPDATE: RLS hides all rows from anon → zero rows changed, seed unmodified.
with upd as (
  update public.dua_windows set tier = 'hacked' where id = 'arafah_1448'
  returning 1
)
select is(
  (select count(*)::int from upd),
  0,
  '(b) anon UPDATE of dua_windows changes zero rows (RLS hides all rows)'
);

-- DELETE: same — zero rows visible to anon, so nothing is deleted.
with del as (
  delete from public.dua_windows where id = 'arafah_1448' returning 1
)
select is(
  (select count(*)::int from del),
  0,
  '(b) anon DELETE from dua_windows removes zero rows (RLS hides all rows)'
);

reset role;

-- Belt-and-suspenders: as superuser (RLS-exempt), confirm the seeded row the
-- anon UPDATE/DELETE targeted still exists and was never mutated.
select ok(
  exists (select 1 from public.dua_windows
           where id = 'arafah_1448' and tier = 'hero'),
  '(b) seeded arafah_1448 row survived the anon write attempts intact'
);

select * from finish();

rollback;
