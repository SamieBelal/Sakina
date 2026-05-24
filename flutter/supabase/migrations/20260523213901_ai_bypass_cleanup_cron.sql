-- 2026-05-23: AI bypass cleanup cron — orphan rescue.
--
-- Plan: docs/superpowers/plans/2026-05-23-ai-bypass-token-spend.md
--
-- The reserve-then-commit flow has three terminal states for a reservation:
--   * committed  — AI call succeeded, commit_ai_bypass fired.
--   * cancelled  — AI call failed (or user upgraded mid-flow), cancel_ai_bypass fired.
--   * pending    — app was killed mid-flow, neither commit nor cancel fired.
--
-- The third case is an orphan: the user's tokens stay debited, the bypass
-- counter stays incremented, but the reservation will never be finalized
-- by the client. This cron rescues orphans by canceling reservations older
-- than 15 minutes (a normal AI call takes 5-15 seconds — 15 min is generous).
--
-- Frequency: every 5 minutes. Pairs naturally with the 15-min staleness
-- window: a freshly orphaned reservation is rescued within 5-20 minutes.
--
-- Idempotency: cancel_ai_bypass is itself idempotent (returns ok=false on
-- non-pending reservations), so a cron tick that races a late client
-- commit/cancel cannot double-refund.

-- Ensure pg_cron is available (pg_net was already enabled by an earlier
-- migration; the cron extension itself is enabled by default on Supabase
-- but we declare the dependency for clarity).
do $$
begin
  if not exists (select 1 from pg_extension where extname = 'pg_cron') then
    raise notice 'pg_cron extension not installed — skipping ai_bypass_cleanup schedule';
  end if;
end$$;

-- Unschedule any prior version so this migration is re-runnable.
do $$
begin
  if exists (select 1 from cron.job where jobname = 'ai_bypass_cleanup') then
    perform cron.unschedule('ai_bypass_cleanup');
  end if;
end$$;

select cron.schedule(
  'ai_bypass_cleanup',
  '*/5 * * * *',
  $cron$
    select public.cancel_ai_bypass(id)
    from public.ai_bypass_reservations
    where status = 'pending'
      and created_at < now() - interval '15 minutes';
  $cron$
);
