# supabase/staged/ — reviewed-but-NOT-applied scripts

Scripts in this directory are **deliberately outside `supabase/migrations/`**
so that neither `supabase db push` nor CI (`supabase start` applies only
`migrations/`; `run_sql_tests.sh` globs only `tests/`) ever runs them.
They are written and reviewed now so the post-keep work is a copy, not a
design session.

## Softener wave (§V6.10 — no grandfathering)

**Trigger condition:** the T0+6wk KEEP decision on the One Ship
(2026-07-23 plan, Phase 2 step 4). Do NOT run on a kill/rollback outcome.
**Deadline:** the full wave (notice + flip) must complete before Ramadan prep.

Execution order:

1. `softener_1_notice.sql` — stamps `softener_notice_ends_at = now() + 30 days`
   on every non-reel_v1 user. The 30-day notice push/UI that references this
   timestamp is Phase 3 client/content work, NOT part of this script.
2. **Wait ≥30 days.**
3. `softener_2_flip.sql` — flips expired-notice users to the `reel_v1` cohort,
   clamps warmups to the pinned 3/3, zeroes the weekly pool columns.
4. Bypass-subsystem deletion is a **separate post-wave PR** (see the flag &
   dead-code hygiene ledger in the 2026-07-23 plan) — not a staged script.

Both scripts assert they run as an exempt role (`postgres` / `service_role` /
`supabase_admin`): the freemium guard blocks these columns for everyone else,
and a half-applied wave under a restricted role would be worse than a loud
failure. To execute: move the script content into a normal timestamped
migration file and apply via the standard flow (never MCP-only SQL without a
repo file).
