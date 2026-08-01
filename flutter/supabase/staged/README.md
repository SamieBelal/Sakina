# supabase/staged/ — reviewed-but-NOT-applied scripts

Scripts in this directory are **deliberately outside `supabase/migrations/`**
so that neither `supabase db push` nor CI (`supabase start` applies only
`migrations/`; `run_sql_tests.sh` globs only `tests/`) ever runs them.
They are written and reviewed now so the post-keep work is a copy, not a
design session.

## T0 — `t0_flip_all_to_reel_v1.sql` (D12, run FIRST)

**Trigger condition:** release day, once the T0 build is live.

D12 (founder, 2026-08-01) moved the free-tier tightening off the softener wave
entirely: every account becomes `reel_v1` at T0, with no 30-day notice. This
script is the whole operation — cohort backfill, warmup clamp on **all three**
counters, weekly-pool reset, then `new_signup_cohort`.

**It replaces the softener wave's role in the free-tier migration.** Do not run
`softener_1_notice.sql` / `softener_2_flip.sql` for that purpose; see the note
under them below. Pinned by `test/ops/t0_cohort_flip_script_test.dart`.

**Rollback is partial.** Setting `free_tier_cohort` back to `'legacy'` restores
the legacy economy but NOT the clamped counters — `least()` discards the
surplus. The script snapshots the three columns into
`warmup_pre_t0_snapshot` first; that table is the only way back.

## Reverse-trial close-out — `reverse_trial_close.sql` (W5 Wave A)

**Two steps, run days apart. Step 1 is urgent; step 2 is gated.**

**Step 1 — flip `reverse_trial_experiment_enabled` to false. Trigger: now.**
The live App Store build still reads this key at onboarding-complete and calls
`activate_trial(3)` for the treatment half of every new signup, so each signup
pushes the close-out date out another 72h — the "last in-flight trial" already
slid from 2026-08-03 20:45 to 22:55 UTC for exactly this reason. Step 1 freezes
that horizon at (flip + 3 days + ≤6h of config-cache staleness). Nothing else
does; deleting the client code does not, because the minting code is in the
shipped binary.

It touches no user state. In-flight trials are honored to natural expiry —
`trial_premium_until` is a server column OR'd into `PurchaseService.isPremium()`,
and that read never consults this flag. There is no clawback in this close-out.

**Step 2 — verification gate, then delete the key. Trigger: after the last
expiry, and after the build that stopped reading it is rolled out.** Step 2a is
the `count(*) where trial_premium_until > now()` gate that the W5 plan blocks
Wave A on; it must return 0 before any build carrying the client-side deletion
ships. Re-query it rather than trusting a recorded timestamp. Step 2b (the
`DELETE`) is commented out and is hygiene only — `getBool` falls back to false,
so a missing key and an explicit false behave identically to every build.

The client half of Wave A is already committed (the three source files, the
orphaned tour bucketing, and the frozen `paywall_exp_arm`); this script is only
the `app_config` key.

## Softener wave (§V6.10 — no grandfathering)

> **⚠️ SUPERSEDED for the free-tier migration (D12, 2026-08-01).** Both scripts
> below were written for the plan where existing users migrated after a 30-day
> notice. `softener_2_flip.sql` is gated on `softener_notice_ends_at <= now()`,
> and under D12 nothing stamps that column — so it now matches **zero rows**.
> It also clamps only `warmup_reflect_remaining` and
> `warmup_built_dua_remaining`, leaving `warmup_discover_name_remaining` at the
> legacy default of 5. Use `t0_flip_all_to_reel_v1.sql` instead.
>
> They are kept, not deleted, because the softener wave still exists for the
> **tokens→Noor currency merge** (`docs/superpowers/plans/2026-07-31-one-currency-noor-merge.md`).
> If a notice-based migration is ever revived, fix the missing third column
> before trusting the flip.

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
