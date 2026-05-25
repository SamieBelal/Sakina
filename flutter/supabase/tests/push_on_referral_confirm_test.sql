-- Regression test for:
--   * 20260523010000_push_on_referral_confirm.sql
--
-- STRUCTURAL ONLY: this suite asserts the function + trigger are correctly
-- registered and locked down. Behavioral assertions (push fires once on
-- pending->confirmed, no fire on rejected->confirmed, body shape, header
-- presence) require stubbing `net.http_post` with `CREATE OR REPLACE
-- FUNCTION net.http_post(...)`, which needs CREATE privilege on the `net`
-- schema — the CI psql role lacks that, so the earlier behavioral version
-- failed with `permission denied for schema net`.
--
-- Behavioral verification lives in:
--   * docs/qa/2026-05-23-refer-unlock-device-test-plan.md (Section E)
--     — exercises the full pending->confirmed → push delivery loop on a
--     real device, including the rejected->confirmed no-fire case (E3)
--     and the secret-gate check (E4 via curl).
--   * Manual smoke via the OneSignal dashboard's Delivery tab.
--
-- The structural checks here catch the regressions that would silently
-- disable the push pipeline:
--   * trigger removed/renamed
--   * function lost SECURITY DEFINER
--   * EXECUTE re-granted to authenticated (privilege escalation)
--   * WHEN clause loosened back to IS DISTINCT FROM (resurrection-fires)

begin;

create extension if not exists pgtap;

select plan(5);

-- ---------------------------------------------------------------------------
-- Function structure
-- ---------------------------------------------------------------------------

select has_function('public', 'notify_referrer_on_confirm', array[]::text[],
  'notify_referrer_on_confirm() exists');

select ok(
  (select prosecdef from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'notify_referrer_on_confirm'),
  'notify_referrer_on_confirm is SECURITY DEFINER');

select ok(
  not has_function_privilege('authenticated',
    'public.notify_referrer_on_confirm()', 'EXECUTE'),
  'authenticated cannot EXECUTE notify_referrer_on_confirm() (privilege lockdown)');

-- ---------------------------------------------------------------------------
-- Trigger structure — use pg_get_triggerdef for reliable string assertions
-- ---------------------------------------------------------------------------

select has_trigger('public', 'referrals', 'trg_notify_referrer_on_confirm',
  'trg_notify_referrer_on_confirm exists on public.referrals');

-- The DDL string from pg_get_triggerdef contains the full CREATE TRIGGER
-- clause as Postgres normalized it. Asserting on this catches a regression
-- in ANY of: AFTER vs BEFORE, INSERT/UPDATE vs other event, FOR EACH ROW
-- vs STATEMENT, the OF status column filter, AND the WHEN clause text.
select like(
  (select pg_get_triggerdef(t.oid)
     from pg_trigger t
     join pg_class c on c.oid = t.tgrelid
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'referrals'
      and t.tgname = 'trg_notify_referrer_on_confirm'),
  '%AFTER UPDATE OF status%FOR EACH ROW%OLD.status = ''pending''%NEW.status = ''confirmed''%',
  'trigger DDL: AFTER UPDATE OF status, FOR EACH ROW, tightened pending->confirmed WHEN (S4 fix)');

select * from finish();

rollback;
