-- 20260715120000_dua_windows.sql
--
-- Duʿā Acceptance Times — the single seeded source of truth for DATED
-- Islamic duʿā-acceptance days (awqāt al-ijābah, the calendar layer).
--
-- Design: docs/superpowers/specs/2026-07-15-dua-acceptance-times-widget-design.md
--   §3 content model · §4 detection engine · §15 locked decisions D3/D4.
--
-- Locked decisions honored here:
--   D3 — BRAND-NEW table. islamic_occasions is NOT touched/reused: that table
--        powers the paid Sakina Gift and GiftService.currentOccasion() matches
--        ANY active row with no kind filter, so adding duʿā rows there would
--        grant free premium on ʿArafah/ʿAshura/etc. Separate table = zero gift
--        blast radius.
--   D4 — ALL dated days (incl. monthly White Days) are seeded server-side from
--        the Umm al-Qura calendar. No on-device Hijri calc; the `hijri` package
--        is dropped.
--
-- CRITICAL — all-day windows are stored as bare DATES, not fixed UTC instants.
-- Each device expands a date to its OWN local midnight→midnight. A fixed UTC
-- instant would mis-open ʿArafah by up to ~13h at the date line
-- (Honolulu UTC-10 / Auckland UTC+13). See spec §4.
--
-- Time-boxed windows (last-third-of-night, the Friday hour, iftar) are NOT
-- seeded — they are computed client-side from prayer times. This table is
-- calendar DAYS only. Friday (Jumuʿah) is a pure device-weekday check and is
-- likewise not stored here.
--
-- RLS posture mirrors the public-catalog / islamic_occasions "readable by all"
-- pattern: anon + authenticated may SELECT; no INSERT/UPDATE/DELETE policy
-- (writes stay with the service role via migrations/seed).

-- ---------------------------------------------------------------------------
-- dua_windows — dated calendar windows
-- ---------------------------------------------------------------------------
create table if not exists public.dua_windows (
  id          text primary key,
  kind        text not null,   -- 'arafah','dhul_hijjah_10','laylat_al_qadr',
                               -- 'ramadan','ashura','white_days','eid'
  tier        text not null,   -- 'hero' | 'special' | 'soft'
  title_key   text not null,   -- client copy-lookup key (no baked strings)
  start_date  date not null,   -- bare local date; device expands to local midnight
  end_date    date not null,   -- inclusive; single-day windows set = start_date
  source_ref  text,            -- hadith/source reference for the optional "why"
  constraint dua_window_range_valid check (end_date >= start_date)
);

comment on table public.dua_windows is
  'Seeded source of truth for DATED duʿā-acceptance days (Umm al-Qura). '
  'All-day windows stored as bare dates and expanded to device-local midnight. '
  'Separate from islamic_occasions by design (D3): must never grant premium.';

alter table public.dua_windows enable row level security;

-- Public read. RLS policies only filter rows AFTER the role holds the
-- table-level SELECT privilege, so the GRANT is explicit — otherwise anon
-- access depends on order-sensitive default privileges and flakes in the
-- ephemeral `supabase start` test stack (see 20260612000000_app_config_anon_table_grant).
grant select on public.dua_windows to anon, authenticated;

drop policy if exists "dua windows readable by all" on public.dua_windows;
create policy "dua windows readable by all"
  on public.dua_windows
  for select
  to anon, authenticated
  using (true);

-- Range-scan index for "which window is active on date D" lookups.
create index if not exists dua_windows_start_date_idx
  on public.dua_windows (start_date);

-- ---------------------------------------------------------------------------
-- dua_windows_meta — single-row seed-horizon sentinel
-- ---------------------------------------------------------------------------
-- The app runs a health check against last_seeded_through and warns (and we
-- log to TODO.md) well before the horizon, so the feature never silently goes
-- blank when the seed runs out (spec §4 seed-horizon safety).
create table if not exists public.dua_windows_meta (
  id                   boolean primary key default true,
  last_seeded_through  date not null,
  updated_at           timestamptz not null default now(),
  -- Enforce a single row (id can only ever be true).
  constraint dua_windows_meta_singleton check (id = true)
);

comment on table public.dua_windows_meta is
  'Single-row sentinel. last_seeded_through = last DATE the dua_windows seed '
  'covers with confidence. App health-checks this to warn before the horizon.';

alter table public.dua_windows_meta enable row level security;

grant select on public.dua_windows_meta to anon, authenticated;

drop policy if exists "dua windows meta readable by all" on public.dua_windows_meta;
create policy "dua windows meta readable by all"
  on public.dua_windows_meta
  for select
  to anon, authenticated
  using (true);

-- ---------------------------------------------------------------------------
-- Seed — Umm al-Qura dated days, ~12 months ahead (2026-07 → 2027-06).
-- Idempotent via ON CONFLICT DO NOTHING.
--
-- SOURCING NOTE (content accuracy): every date below is the Umm al-Qura
-- Gregorian equivalent, cross-checked across sources. All-day windows are
-- bare dates. Single-day windows have end_date = start_date. Dates may shift
-- ±1 day in regions following local moon sighting — the client renders these
-- as its own local day and never claims minute-precision for all-day windows.
--
-- Hijri anchors used (Umm al-Qura):
--   1 Safar 1448      = 2026-07-15   1 Rabiʿ I 1448    = 2026-08-14
--   1 Rabiʿ II 1448   = 2026-09-12   1 Jumada I 1448   = 2026-10-12
--   1 Jumada II 1448  = 2026-11-11   1 Rajab 1448      = 2026-12-10
--   1 Shaʿban 1448    = 2027-01-09   1 Ramadan 1448    = 2027-02-08 (29 days)
--   1 Shawwal 1448    = 2027-03-09   1 Dhul-Qaʿda 1448 = 2027-04-08
--   1 Dhul-Hijjah 1448= 2027-05-07   1 Muharram 1449   = 2027-06-06
-- ---------------------------------------------------------------------------
insert into public.dua_windows
  (id, kind, tier, title_key, start_date, end_date, source_ref)
values
  -- ===== Monthly White Days (Ayyām al-Bīḍ), 13–15 of each Hijri month) =====
  -- Ramadan's own White Days are intentionally omitted: 13–15 Ramadan fall
  -- inside the all-Ramadan window below, so a separate row would double-cover.
  ('white_days_safar_1448',     'white_days', 'soft', 'dua_window.white_days', '2026-07-27', '2026-07-29', 'Tirmidhi 761'),
  ('white_days_rabi1_1448',     'white_days', 'soft', 'dua_window.white_days', '2026-08-26', '2026-08-28', 'Tirmidhi 761'),
  ('white_days_rabi2_1448',     'white_days', 'soft', 'dua_window.white_days', '2026-09-24', '2026-09-26', 'Tirmidhi 761'),
  ('white_days_jumada1_1448',   'white_days', 'soft', 'dua_window.white_days', '2026-10-24', '2026-10-26', 'Tirmidhi 761'),
  ('white_days_jumada2_1448',   'white_days', 'soft', 'dua_window.white_days', '2026-11-23', '2026-11-25', 'Tirmidhi 761'),
  ('white_days_rajab_1448',     'white_days', 'soft', 'dua_window.white_days', '2026-12-22', '2026-12-24', 'Tirmidhi 761'),
  ('white_days_shaban_1448',    'white_days', 'soft', 'dua_window.white_days', '2027-01-21', '2027-01-23', 'Tirmidhi 761'),
  ('white_days_shawwal_1448',   'white_days', 'soft', 'dua_window.white_days', '2027-03-21', '2027-03-23', 'Tirmidhi 761'),
  ('white_days_dhulqada_1448',  'white_days', 'soft', 'dua_window.white_days', '2027-04-20', '2027-04-22', 'Tirmidhi 761'),
  ('white_days_dhulhijja_1448', 'white_days', 'soft', 'dua_window.white_days', '2027-05-19', '2027-05-21', 'Tirmidhi 761'),
  ('white_days_muharram_1449',  'white_days', 'soft', 'dua_window.white_days', '2027-06-18', '2027-06-20', 'Tirmidhi 761'),

  -- ===== ʿAshura (9–10 Muharram) — next occurrence is Muharram 1449 =====
  -- (Muharram 1448 / Jun 2026 already passed relative to the 2026-07-15 seed.)
  ('ashura_1449',               'ashura', 'special', 'dua_window.ashura', '2027-06-14', '2027-06-15', 'Muslim 1162'),

  -- ===== Ramadan 1448 (full month) + last ten nights =====
  ('ramadan_1448',              'ramadan', 'special', 'dua_window.ramadan', '2027-02-08', '2027-03-08', NULL),
  -- Last ten nights = 21–29 Ramadan 1448 (Laylat al-Qadr emphasis, odd nights).
  ('laylat_al_qadr_1448',       'laylat_al_qadr', 'hero', 'dua_window.laylat_al_qadr', '2027-02-28', '2027-03-08', 'al-Bukhari 2020'),

  -- ===== Eid al-Fitr (1 Shawwal 1448) =====
  ('eid_fitr_1448',             'eid', 'special', 'dua_window.eid_fitr', '2027-03-09', '2027-03-09', NULL),

  -- ===== Dhul-Hijjah 1448: first ten days + ʿArafah + Eid al-Adha =====
  ('dhul_hijjah_10_1448',       'dhul_hijjah_10', 'special', 'dua_window.dhul_hijjah_10', '2027-05-07', '2027-05-16', 'al-Bukhari 969'),
  -- ʿArafah (9 Dhul-Hijjah) — the hero: best duʿā of the year.
  ('arafah_1448',               'arafah', 'hero', 'dua_window.arafah', '2027-05-15', '2027-05-15', 'Tirmidhi 3585'),
  -- Eid al-Adha (10 Dhul-Hijjah).
  ('eid_adha_1448',             'eid', 'special', 'dua_window.eid_adha', '2027-05-16', '2027-05-16', NULL)
on conflict (id) do nothing;

-- TODO(verify): 15 Shaʿbān 1448 (Shab-e-Barāʾah, ~2027-01-23) intentionally
-- NOT seeded — scholarly-contested, consistent with the prior Mawlid removal
-- (spec §3). Its date coincides with the Shaʿban White Days row above but is a
-- distinct claim we deliberately do not make.
--
-- TODO(verify): Dhul-Hijjah 1449 / Ramadan 1449 and beyond are past the
-- confident horizon of this seed and are NOT included. Extend the seed (and
-- bump last_seeded_through) once the Umm al-Qura tables are re-verified.

-- ---------------------------------------------------------------------------
-- Seed horizon sentinel.
-- last_seeded_through = the last DATE covered above with confidence:
-- 2027-06-20 (White Days of Muharram 1449). Idempotent upsert.
-- ---------------------------------------------------------------------------
insert into public.dua_windows_meta (id, last_seeded_through, updated_at)
values (true, '2027-06-20', now())
on conflict (id) do update
  set last_seeded_through = excluded.last_seeded_through,
      updated_at          = now();
