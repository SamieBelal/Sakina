-- F-01 v1 (SUPERSEDED by v2 — 20260601234521). This revoke-from-anon is a
-- NO-OP because EXECUTE on the function is granted to PUBLIC by default, which
-- anon/authenticated inherit; revoking from anon alone does not remove the
-- PUBLIC grant. Retained only so the repo migration history matches the applied
-- ledger. The effective fix is v2 (revoke from PUBLIC + grant service_role).
revoke execute on function public.get_eligible_notification_users(
  text, text, integer, boolean, integer, integer, boolean
) from anon, authenticated;
