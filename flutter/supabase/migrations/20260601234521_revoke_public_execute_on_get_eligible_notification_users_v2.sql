-- F-01 (2026-06-01): get_eligible_notification_users is a SECURITY DEFINER
-- function returning cross-user PII (user_id, display_name, timezone, streak)
-- for all push-enabled users. It had EXECUTE granted to PUBLIC (inherited by
-- anon + authenticated) with no in-body identity guard, letting any caller with
-- the public anon key enumerate the push-enabled user base via
-- POST /rest/v1/rpc/get_eligible_notification_users.
--
-- Only legitimate caller is the send-scheduled-notifications edge function,
-- which runs as service_role (bypasses these grants), so revoking is
-- behavior-neutral for real users.
--
-- NOTE: revoking from anon/authenticated alone is a no-op because EXECUTE is
-- granted to PUBLIC by default; must revoke from PUBLIC.
-- Regression test: supabase/tests/notification_eligibility_grant_test.sql
revoke execute on function public.get_eligible_notification_users(
  text, text, integer, boolean, integer, integer, boolean
) from public, anon, authenticated;

grant execute on function public.get_eligible_notification_users(
  text, text, integer, boolean, integer, integer, boolean
) to service_role;

comment on function public.get_eligible_notification_users(
  text, text, integer, boolean, integer, integer, boolean
) is 'Service-role only (send-scheduled-notifications cron). EXECUTE revoked from anon/authenticated/PUBLIC — returns cross-user PII. See docs/qa/findings/2026-06-01-notif-eligibility-anon-enumeration.md';
