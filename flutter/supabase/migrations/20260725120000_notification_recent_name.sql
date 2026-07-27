-- 2026-07-25: Notification Phase A (conversion-refactor plan §0.3) — give the
-- push cron each user's MOST-RECENT checked-in Name so server templates can
-- speak in "reel voice" with yesterday's-Name framing.
--
-- DESIGN: COMPANION FUNCTION, NOT an extension of get_eligible_notification_users.
--
-- Two reasons:
--
--   1. The live prod body of get_eligible_notification_users is NOT the one in
--      this repo. Migration `add_push_enabled_last_verified_at_with_cron_filter`
--      (applied 2026-04-26 via MCP, documented in
--      docs/qa/findings/2026-04-26-push-cron-defense-in-depth-followup.md but
--      with NO local .sql file) added the Option B defense-in-depth filter
--      (`push_enabled_last_verified_at > now() - interval '7 days'`). Any
--      CREATE OR REPLACE built from the stale local copy would silently DROP
--      that filter and re-open ghost-dispatching. A previous notification-cron
--      change already caused a ~1hr outage — we do not touch that function,
--      its signature, its cron wiring, or its auth at all.
--
--   2. The unified streak family reads a DIFFERENT RPC
--      (get_streak_notification_decisions) and needs the same Name lookup.
--      One companion function serves every notification kind as step two of a
--      two-step query (edge fn fetches eligible users first, then passes the
--      user-id array here — no PostgREST FK embed anywhere; there is no FK
--      between these tables and auth.users-keyed tables cannot be embedded,
--      per the dua due-query gotcha).
--
-- Data path: user_checkin_history (name_returned = transliteration the user
-- actually saw, e.g. 'Ar-Raheem') → name_anchors (anchor one-liner). The
-- transliteration→name_key mapping mirrors the client's canonical
-- widgetNameKeyFor() in lib/core/constants/allah_names.dart: naive
-- lowercase-kebab slug plus the 11 long-vowel overrides (also pinned by
-- lib/core/constants/transliteration_slug_map.dart and
-- test/content/name_anchors_coverage_test.dart).
--
-- NULL behavior (binding): a user with no check-in rows still gets a result
-- row with NULL checked_in_at / name_transliteration / name_anchor, so the
-- edge function can fall back to generic copy without ever interpolating null.
-- 'Allah' (proper Name, no anchors row) and any unmapped/legacy spelling yield
-- a NULL anchor the same way.

-- ── 1. Pure slug helper (mirrors widgetNameKeyFor in allah_names.dart) ────────
create or replace function public.notification_name_anchor_slug(
  p_transliteration text
)
returns text
language sql
immutable
strict
set search_path = ''
as $$
  select case slug
    -- The 11 long-vowel overrides where the naive slug does not equal the
    -- name_anchors.name_key spelling. Keep in lockstep with
    -- widgetNameKeyOverrides (lib/core/constants/allah_names.dart).
    when 'ar-raheem'   then 'ar-rahim'
    when 'al-hakeem'   then 'al-hakim'
    when 'al-kareem'   then 'al-karim'
    when 'al-wakeel'   then 'al-wakil'
    when 'al-lateef'   then 'al-latif'
    when 'al-mujeeb'   then 'al-mujib'
    when 'al-baseer'   then 'al-basir'
    when 'al-khabeer'  then 'al-khabir'
    when 'ash-shaheed' then 'ash-shahid'
    when 'al-qawiyy'   then 'al-qawi'
    when 'al-mateen'   then 'al-matin'
    else slug
  end
  from (
    select trim(
      both '-' from regexp_replace(lower(p_transliteration), '[^a-z0-9]+', '-', 'g')
    ) as slug
  ) s
$$;

comment on function public.notification_name_anchor_slug(text) is
  'Maps a user_checkin_history.name_returned transliteration (e.g. ''Ar-Raheem'') '
  'to the name_anchors.name_key slug (e.g. ''ar-rahim''). Mirrors the client''s '
  'widgetNameKeyFor(); pure/IMMUTABLE, no table access.';

-- ── 2. Companion RPC: most-recent checked-in Name per user ───────────────────
create or replace function public.get_recent_checkin_names(
  p_user_ids uuid[]
)
returns table (
  user_id uuid,
  checked_in_at timestamptz,
  name_transliteration text,
  name_anchor text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    ids.user_id,
    h.checked_in_at,
    nullif(trim(h.name_returned), '') as name_transliteration,
    a.anchor as name_anchor
  from unnest(p_user_ids) as ids(user_id)
  left join lateral (
    -- idx_checkin_user_date (user_id, checked_in_at desc) makes this a
    -- single index probe per user.
    select c.checked_in_at, c.name_returned
    from public.user_checkin_history c
    where c.user_id = ids.user_id
    order by c.checked_in_at desc
    limit 1
  ) h on true
  left join public.name_anchors a
    on a.name_key = public.notification_name_anchor_slug(h.name_returned)
$$;

comment on function public.get_recent_checkin_names(uuid[]) is
  'Notification Phase A (plan 2026-07-23 §0.3): step two of the cron''s '
  'two-step query. Returns each requested user''s most-recent checked-in Name '
  '(transliteration exactly as the user saw it + the one-line anchor). Users '
  'with no check-ins get a row of NULLs — callers must fall back to generic '
  'copy and NEVER interpolate null. service_role only: SECURITY DEFINER over '
  'per-user check-in history.';

-- ── 3. Grants: service_role ONLY (matches get_eligible_notification_users /
--      get_streak_notification_decisions). This reads arbitrary users'
--      check-in history, so it must not be callable by end-users or anon.
revoke execute on function public.get_recent_checkin_names(uuid[])
  from public, anon, authenticated;
grant execute on function public.get_recent_checkin_names(uuid[])
  to service_role;

-- The slug helper is pure (no table access) but there is no reason to expose
-- it either.
revoke execute on function public.notification_name_anchor_slug(text)
  from public, anon, authenticated;
grant execute on function public.notification_name_anchor_slug(text)
  to service_role;
