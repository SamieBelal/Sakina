-- Softener wave step 1 — stamp the 30-day notice window (§V6.10)
-- STAGED: do not apply before the T0+6wk KEEP decision. See README.md.

do $$
begin
  if current_user not in ('postgres', 'service_role', 'supabase_admin') then
    raise exception 'softener_1_notice must run as an exempt role (got %); the freemium guard would half-block it', current_user;
  end if;
end $$;

-- Premium users get stamped too — harmless: free-tier limits never touch
-- them, and RC entitlement is not reliably queryable in Postgres.
update public.user_profiles
set softener_notice_ends_at = now() + interval '30 days'
where free_tier_cohort is distinct from 'reel_v1'
  and softener_notice_ends_at is null;   -- idempotent re-run safety
