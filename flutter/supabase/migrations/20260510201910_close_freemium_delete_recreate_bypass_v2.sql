-- Follow-up: drop the renamed "Own data delete" policy on user_daily_usage.
-- The 20260510172511_drop_redundant_policies_and_indexes migration consolidated
-- per-table delete policy names into "Own data delete", so the previous DROP
-- targeting "Users can delete own daily usage" was a no-op. The BEFORE DELETE
-- trigger added in 20260510030000_close_freemium_delete_recreate_bypass.sql
-- already blocks the bypass — this is policy-level cleanup so the table is
-- doubly hardened (no policy AND a trigger).

drop policy if exists "Own data delete" on public.user_daily_usage;
