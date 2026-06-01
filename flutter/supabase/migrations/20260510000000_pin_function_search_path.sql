-- 2026-05-10: Pin search_path on SECURITY DEFINER functions flagged by
-- Supabase advisor (lint 0011 / function_search_path_mutable).
--
-- A mutable search_path on a SECURITY DEFINER function lets a caller
-- prepend a schema they own (e.g. via `set search_path = attacker_schema, public`
-- in their session) and hijack unqualified name resolution at the
-- function owner's privilege level. The classic exploit is shadowing a
-- built-in like `pg_catalog.lower` or a referenced table with a
-- malicious same-named object, which then runs as the definer.
--
-- Pin to `public, pg_temp` so:
--   * unqualified references inside the function body resolve to public
--     (where our app schema lives), and
--   * pg_temp stays available so PL/pgSQL can still create temp tables
--     when needed.
--
-- `alter function ... set search_path = ...` is naturally idempotent —
-- re-running this migration just rewrites the same proconfig entry.
--
-- Verified via pg_proc on 2026-05-10:
--   public.handle_new_user()                  proconfig = null
--   public.cleanup_orphaned_users()           proconfig = null
--   public.earn_scrolls(amount integer)       proconfig = null
-- Only one `earn_scrolls` overload exists, so no ambiguity.

alter function public.handle_new_user()         set search_path = public, pg_temp;
-- cleanup_orphaned_users is an out-of-band prod function with no creating
-- migration; guard so a fresh db reset / CI (where it doesn't exist) skips it.
do $$
begin
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'cleanup_orphaned_users'
  ) then
    alter function public.cleanup_orphaned_users() set search_path = public, pg_temp;
  end if;
end $$;
alter function public.earn_scrolls(integer)     set search_path = public, pg_temp;
