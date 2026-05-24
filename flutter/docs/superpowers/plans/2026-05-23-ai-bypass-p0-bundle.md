# AI-Bypass P0 Hotfix Bundle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship one PR that closes the five P0 defects discovered in the post-merge review of commits 14c800f..2eeb5cb. Each defect gets a live reproduction (proving the bug exists on master), a fix, regression tests, and a re-verification (proving the fix kills the bug).

**Architecture:** Three migrations (P0-1 freemium guard extension, P0-2 idempotency schema + RPC change) plus four client edits (P0-2 client wiring, P0-3 UTC clock, P0-4 dispose cancel, P0-5 banner shown event). All fixes are additive — no behavior change for honest users; closes attack surface and fixes telemetry/state-leak defects.

**Tech Stack:** Postgres (Supabase) for migrations, Dart/Flutter (Riverpod) for client, Supabase MCP for live exploit verification, iOS Simulator MCP for end-to-end smoke. Test frameworks: project pgTAP-style helper in `supabase/tests/*.sql`, `flutter test` for Dart.

**P0s addressed (numbered to match the review report):**
- **P0-1** Freemium guards don't cover new bypass counters → user defeats daily cap via direct UPDATE.
- **P0-2** `reserve_ai_bypass` has no idempotency key → double-tap during latency double-debits 25 tokens.
- **P0-3** `daily_usage_service._today()` uses local time → client/server cap state desyncs at UTC midnight.
- **P0-4** `ReflectNotifier` (and 2 sibling notifiers) leak in-flight bypass reservations on dispose.
- **P0-5** `iap_to_sub_banner_shown` analytics event is declared and tested but never emitted → EXP-3 funnel broken.

**Out of scope** (filed as follow-ups in TODO.md, NOT in this PR):
- P1 cancel_ai_bypass cross-user vulnerability (separate hotfix migration).
- Rating-gate App Store risk (requires copy + flag changes, separate PR).
- Paywall 3s IgnorePointer (requires UX review).
- All P2 polish items.

---

## Task 0: Setup

**Files:** branch only (no worktree per user direction — work directly in the existing checkout).

- [ ] **Step 0.1: Branch off master in the existing checkout**

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
# Make sure current tree is clean (no uncommitted work) before branching.
git status --short
# Sync master, create the hotfix branch, switch to it
git fetch origin master --quiet
git checkout master
git pull --ff-only origin master
git checkout -b hotfix/ai-bypass-p0-bundle
```

- [ ] **Step 0.2: Verify clean baseline**

Run: `flutter analyze 2>&1 | tail -5 && flutter test --no-pub 2>&1 | tail -5`

Expected: No new errors. Pre-existing infos OK. Baseline test count recorded for later comparison.

- [ ] **Step 0.3: Confirm Supabase MCP is pointed at the prod project**

Use Supabase MCP `mcp__supabase__execute_sql` with:
```sql
SELECT current_database() AS db, version() AS pg_version;
```

Expected: returns the prod Sakina database (NOT a branch). All live-exploit repros run against prod; the writes are scoped to one fixed test user and wrapped in `BEGIN; ... ROLLBACK;` blocks to avoid persisting state.

---

## Task 1 — P0-1: Freemium guard extension (covers bypass counters + first_bypass_consumed + lifetime_bypasses_purchased)

**Files:**
- Create: `supabase/migrations/20260524000000_extend_freemium_guards_for_bypass_fields.sql`
- Create: `supabase/tests/freemium_guards_bypass_fields_test.sql`
- Modify (later in Task 5): no Dart changes for this P0.

### Step 1.1: Reproduce the live exploit (PROVES BUG EXISTS)

- [ ] **Step 1.1a: Run the four-attack exploit script via Supabase MCP**

Use Supabase MCP `mcp__supabase__execute_sql` with the following. Substitute a real authenticated user UUID if `6c111b1a-ac0c-44b1-8b92-efccde306f15` no longer exists (look up via `SELECT id FROM auth.users LIMIT 1`).

```sql
BEGIN;
-- Seed at the cap
INSERT INTO public.user_daily_usage (user_id, usage_date, reflect_uses, reflect_bypasses_used)
VALUES ('6c111b1a-ac0c-44b1-8b92-efccde306f15', (timezone('utc', now()))::date, 3, 2)
ON CONFLICT (user_id, usage_date) DO UPDATE SET reflect_uses=3, reflect_bypasses_used=2;
UPDATE public.user_profiles
  SET first_bypass_consumed=true, lifetime_bypasses_purchased=50
  WHERE id='6c111b1a-ac0c-44b1-8b92-efccde306f15';

-- Switch to authenticated role
SELECT set_config('request.jwt.claims',
  json_build_object('sub','6c111b1a-ac0c-44b1-8b92-efccde306f15','role','authenticated')::text, true);
SET LOCAL ROLE authenticated;

-- ATTACK A (control — existing guard should block)
SAVEPOINT a;
UPDATE public.user_daily_usage SET reflect_uses=0
  WHERE user_id='6c111b1a-ac0c-44b1-8b92-efccde306f15' AND usage_date=(timezone('utc',now()))::date;
-- Will raise; rollback to savepoint so the next attacks can run
ROLLBACK TO SAVEPOINT a;

-- ATTACK B (the bug)
UPDATE public.user_daily_usage SET reflect_bypasses_used=0
  WHERE user_id='6c111b1a-ac0c-44b1-8b92-efccde306f15' AND usage_date=(timezone('utc',now()))::date
RETURNING reflect_bypasses_used AS attack_b_after;

-- ATTACK C (the bug)
UPDATE public.user_profiles SET first_bypass_consumed=false
  WHERE id='6c111b1a-ac0c-44b1-8b92-efccde306f15'
RETURNING first_bypass_consumed AS attack_c_after;

-- ATTACK D (the bug)
UPDATE public.user_profiles SET lifetime_bypasses_purchased=0
  WHERE id='6c111b1a-ac0c-44b1-8b92-efccde306f15'
RETURNING lifetime_bypasses_purchased AS attack_d_after;
ROLLBACK;
```

Expected: ATTACK A errors with `cannot reset/refill freemium gating field: reflect_uses (3 -> 0)`. Attacks B, C, D each succeed and return `0` / `false`. This proves the three new fields are unguarded.

- [ ] **Step 1.1b: Record the proof**

Append the actual returned rows to a scratch file:

```bash
cat > /tmp/p0-1-repro-before.txt <<'EOF'
P0-1 LIVE EXPLOIT — BEFORE FIX (date: $(date -u +%FT%TZ))
attack_a: BLOCKED (existing guard works)
attack_b: SUCCEEDED — reflect_bypasses_used set to 0
attack_c: SUCCEEDED — first_bypass_consumed flipped true→false
attack_d: SUCCEEDED — lifetime_bypasses_purchased reset to 0
EOF
cat /tmp/p0-1-repro-before.txt
```

### Step 1.2: Write the failing pgTAP-style test

- [ ] **Step 1.2: Write the SQL test that pins the new guards**

Create `supabase/tests/freemium_guards_bypass_fields_test.sql`:

```sql
-- supabase/tests/freemium_guards_bypass_fields_test.sql
--
-- Pins the freemium-guard extension from migration
-- 20260524000000_extend_freemium_guards_for_bypass_fields.sql.
--
-- Each test impersonates an authenticated session for a fixed UUID and
-- asserts that the protected UPDATE is rejected. Wrapped in a single
-- BEGIN/ROLLBACK so no live state is persisted.
--
-- Run via: psql "$DATABASE_URL" -f supabase/tests/freemium_guards_bypass_fields_test.sql
-- Or in CI: any script that runs supabase/tests/*.sql.

begin;

-- Re-use the helper convention from ai_bypass_rpc_test.sql
create or replace function pg_temp.expect(cond boolean, name text)
returns void language plpgsql as $$
begin
  if cond then
    raise notice '  ok % %', name, '';
    perform set_config('test.passed', (coalesce(current_setting('test.passed', true), '0')::int + 1)::text, false);
  else
    raise notice '  not ok % %', name, '';
    perform set_config('test.failed_names',
      coalesce(current_setting('test.failed_names', true), '') || name || ';', false);
  end if;
  perform set_config('test.total', (coalesce(current_setting('test.total', true), '0')::int + 1)::text, false);
end;
$$;

select set_config('test.total','0',false),
       set_config('test.passed','0',false),
       set_config('test.failed_names','',false);

-- Pick a known user. If none exists in dev, create a synthetic one for the test.
do $$
declare v_uid uuid;
begin
  select id into v_uid from auth.users order by created_at limit 1;
  if v_uid is null then
    raise exception 'No auth.users to test against — seed at least one user first';
  end if;
  perform set_config('test.uid', v_uid::text, false);
end $$;

-- Seed today's row at the cap as postgres (bypasses guards)
insert into public.user_daily_usage (user_id, usage_date, reflect_uses, reflect_bypasses_used)
values (current_setting('test.uid')::uuid, (timezone('utc',now()))::date, 3, 2)
on conflict (user_id, usage_date) do update
set reflect_uses=3, reflect_bypasses_used=2;

update public.user_profiles
set first_bypass_consumed=true, lifetime_bypasses_purchased=50
where id=current_setting('test.uid')::uuid;

-- Impersonate authenticated
perform set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
set local role authenticated;

-- TEST 1: reset reflect_bypasses_used → should now be blocked
do $$
declare v_caught boolean := false;
begin
  begin
    update public.user_daily_usage set reflect_bypasses_used=0
      where user_id=current_setting('test.uid')::uuid
        and usage_date=(timezone('utc',now()))::date;
  exception when others then v_caught := true;
  end;
  perform pg_temp.expect(v_caught, 'reset reflect_bypasses_used is blocked');
end $$;

-- TEST 2: reset built_dua_bypasses_used
do $$ declare v boolean := false; begin
  begin
    update public.user_daily_usage set built_dua_bypasses_used=0
      where user_id=current_setting('test.uid')::uuid
        and usage_date=(timezone('utc',now()))::date;
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'reset built_dua_bypasses_used is blocked');
end $$;

-- TEST 3: reset discover_name_bypasses_used
do $$ declare v boolean := false; begin
  begin
    update public.user_daily_usage set discover_name_bypasses_used=0
      where user_id=current_setting('test.uid')::uuid
        and usage_date=(timezone('utc',now()))::date;
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'reset discover_name_bypasses_used is blocked');
end $$;

-- TEST 4: flip first_bypass_consumed true → false
do $$ declare v boolean := false; begin
  begin
    update public.user_profiles set first_bypass_consumed=false
      where id=current_setting('test.uid')::uuid;
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'flip first_bypass_consumed true→false is blocked');
end $$;

-- TEST 5: decrement lifetime_bypasses_purchased
do $$ declare v boolean := false; begin
  begin
    update public.user_profiles set lifetime_bypasses_purchased=0
      where id=current_setting('test.uid')::uuid;
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'decrement lifetime_bypasses_purchased is blocked');
end $$;

-- TEST 6: monotonic increment still allowed (honest happy path)
do $$ declare v boolean := false; begin
  begin
    update public.user_daily_usage set reflect_bypasses_used=2
      where user_id=current_setting('test.uid')::uuid
        and usage_date=(timezone('utc',now()))::date;
    v := true; -- this should succeed
  exception when others then v := false; end;
  perform pg_temp.expect(v, 'incrementing reflect_bypasses_used still works');
end $$;

-- TEST 7: incrementing lifetime is still allowed
do $$ declare v boolean := false; begin
  begin
    update public.user_profiles set lifetime_bypasses_purchased=51
      where id=current_setting('test.uid')::uuid;
    v := true;
  exception when others then v := false; end;
  perform pg_temp.expect(v, 'incrementing lifetime_bypasses_purchased still works');
end $$;

-- TEST 8 (HONEST PATH): cancel_ai_bypass MUST still be able to decrement
-- reflect_bypasses_used. The function is SECURITY DEFINER owned by `postgres`
-- (verified live via pg_proc.proowner). Inside the function body
-- current_user = postgres, which is in the bypass list of the guard, so
-- the decrement passes. This test pins that assumption — if the function
-- were ever recreated under a non-postgres owner, this test fails and the
-- refund path silently breaks.
reset role;
do $$
declare v_resv_id uuid; v_before int; v_after int; r jsonb;
begin
  update public.user_daily_usage set reflect_bypasses_used=1
    where user_id=current_setting('test.uid')::uuid
      and usage_date=(timezone('utc',now()))::date;
  insert into public.ai_bypass_reservations (user_id, feature, status, tokens_held)
    values (current_setting('test.uid')::uuid, 'reflect', 'pending', 25)
    returning id into v_resv_id;
  select reflect_bypasses_used into v_before from public.user_daily_usage
    where user_id=current_setting('test.uid')::uuid
      and usage_date=(timezone('utc',now()))::date;

  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.cancel_ai_bypass(v_resv_id);
  reset role;

  select reflect_bypasses_used into v_after from public.user_daily_usage
    where user_id=current_setting('test.uid')::uuid
      and usage_date=(timezone('utc',now()))::date;
  perform pg_temp.expect(v_after = v_before - 1,
    'HONEST PATH: cancel_ai_bypass decrements bypass counter through guard');
end $$;

reset role;

-- Final report
do $$
declare total int; passed int; failed_names text;
begin
  total  := current_setting('test.total')::int;
  passed := current_setting('test.passed')::int;
  failed_names := current_setting('test.failed_names');
  raise notice E'\n========================';
  raise notice 'freemium_guards_bypass_fields_test: % / % passed', passed, total;
  if failed_names <> '' then
    raise exception 'FAILURES: %', failed_names;
  end if;
end $$;

rollback;
```

- [ ] **Step 1.3: Run the test, expect it to FAIL**

Use Supabase MCP `mcp__supabase__execute_sql` with the full file contents above. Expected: tests 1–5 FAIL (guards don't exist yet), tests 6–7 PASS. The DO block at the end will `raise exception 'FAILURES: reset reflect_bypasses_used is blocked;...'`.

This proves the test exercises the right behavior.

### Step 1.4: Write the migration (the fix)

- [ ] **Step 1.4: Create the migration**

Create `supabase/migrations/20260524000000_extend_freemium_guards_for_bypass_fields.sql`:

```sql
-- 2026-05-24: Extend freemium guards to cover AI-bypass counters.
--
-- Background:
--   PR #20–#24 (the 2026-05-23 ai-bypass-token-spend feature) added 3 new
--   columns to user_daily_usage and 2 new columns to user_profiles that all
--   participate in freemium gating:
--
--     user_daily_usage
--       reflect_bypasses_used         monotonic non-decreasing (cap = 2/day)
--       built_dua_bypasses_used       monotonic non-decreasing
--       discover_name_bypasses_used   monotonic non-decreasing
--
--     user_profiles
--       first_bypass_consumed         one-way latch (false→true only)
--       lifetime_bypasses_purchased   monotonic non-decreasing
--
--   The existing freemium guards in
--   20260510010000_lock_freemium_gating_fields.sql were not extended in PR
--   #20, leaving these 5 columns updatable by any authenticated user against
--   their own row (RLS allows self-row UPDATE).
--
-- Threat model (verified live on prod 2026-05-24):
--   * Reset reflect_bypasses_used / built_dua_bypasses_used /
--     discover_name_bypasses_used → defeat the 2-bypass-per-day cap, become
--     unlimited per day given enough tokens (purchasable IAP)
--   * Flip first_bypass_consumed true→false → re-claim the Day-1 freebie
--     every 24h forever
--   * Decrement lifetime_bypasses_purchased → never trigger the IAP→sub
--     upsell banner (EXP-3), and hide spend from product analytics
--
-- Fix:
--   Extend both BEFORE UPDATE trigger functions to enforce the same
--   monotonicity rules. Service-role bypass preserved verbatim from the
--   original migration. Honest increment paths (commit_ai_bypass,
--   claim_first_bypass) all run under service_role or use NEW = OLD writes,
--   so this change is fully backward-compatible.

create or replace function public.guard_user_daily_usage_freemium_fields()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  -- Existing rules (verbatim from 20260510010000)
  if new.reflect_uses < old.reflect_uses then
    raise exception
      'cannot reset/refill freemium gating field: reflect_uses (% -> %)',
      old.reflect_uses, new.reflect_uses
      using errcode = 'check_violation';
  end if;

  if new.built_dua_uses < old.built_dua_uses then
    raise exception
      'cannot reset/refill freemium gating field: built_dua_uses (% -> %)',
      old.built_dua_uses, new.built_dua_uses
      using errcode = 'check_violation';
  end if;

  if new.discover_name_uses < old.discover_name_uses then
    raise exception
      'cannot reset/refill freemium gating field: discover_name_uses (% -> %)',
      old.discover_name_uses, new.discover_name_uses
      using errcode = 'check_violation';
  end if;

  -- New rules (this migration)
  if new.reflect_bypasses_used < old.reflect_bypasses_used then
    raise exception
      'cannot reset/refill freemium gating field: reflect_bypasses_used (% -> %)',
      old.reflect_bypasses_used, new.reflect_bypasses_used
      using errcode = 'check_violation';
  end if;

  if new.built_dua_bypasses_used < old.built_dua_bypasses_used then
    raise exception
      'cannot reset/refill freemium gating field: built_dua_bypasses_used (% -> %)',
      old.built_dua_bypasses_used, new.built_dua_bypasses_used
      using errcode = 'check_violation';
  end if;

  if new.discover_name_bypasses_used < old.discover_name_bypasses_used then
    raise exception
      'cannot reset/refill freemium gating field: discover_name_bypasses_used (% -> %)',
      old.discover_name_bypasses_used, new.discover_name_bypasses_used
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;

create or replace function public.guard_user_profiles_freemium_fields()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  -- Existing rules (verbatim from 20260510010000)
  if new.warmup_reflect_remaining > old.warmup_reflect_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_reflect_remaining (% -> %)',
      old.warmup_reflect_remaining, new.warmup_reflect_remaining using errcode = 'check_violation';
  end if;
  if new.warmup_built_dua_remaining > old.warmup_built_dua_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_built_dua_remaining (% -> %)',
      old.warmup_built_dua_remaining, new.warmup_built_dua_remaining using errcode = 'check_violation';
  end if;
  if new.warmup_discover_name_remaining > old.warmup_discover_name_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_discover_name_remaining (% -> %)',
      old.warmup_discover_name_remaining, new.warmup_discover_name_remaining using errcode = 'check_violation';
  end if;
  if old.had_trial = true and new.had_trial = false then
    raise exception 'cannot reset/refill freemium gating field: had_trial (true -> false is forbidden)'
      using errcode = 'check_violation';
  end if;
  if old.referral_code is not null and new.referral_code is distinct from old.referral_code then
    raise exception 'cannot modify referral_code after initial assignment (% -> %)',
      old.referral_code, new.referral_code using errcode = 'check_violation';
  end if;
  if new.referral_premium_until is distinct from old.referral_premium_until then
    raise exception 'cannot modify referral_premium_until directly; must go through SECURITY DEFINER RPC'
      using errcode = 'check_violation';
  end if;

  -- New rules (this migration)
  if old.first_bypass_consumed = true and new.first_bypass_consumed = false then
    raise exception
      'cannot reset/refill freemium gating field: first_bypass_consumed (true -> false is forbidden)'
      using errcode = 'check_violation';
  end if;

  if new.lifetime_bypasses_purchased < old.lifetime_bypasses_purchased then
    raise exception
      'cannot reset/refill freemium gating field: lifetime_bypasses_purchased (% -> %)',
      old.lifetime_bypasses_purchased, new.lifetime_bypasses_purchased
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;

-- Triggers themselves are unchanged (re-use existing names + bindings).
-- The CREATE OR REPLACE FUNCTION above swaps out the body atomically.
```

### Step 1.5: Apply the migration via Supabase MCP, re-run tests

- [ ] **Step 1.5a: Apply the migration**

Use Supabase MCP `mcp__supabase__apply_migration` with name `extend_freemium_guards_for_bypass_fields` and the SQL body above.

Expected: returns success.

- [ ] **Step 1.5b: Re-run the test suite**

Same as Step 1.3 — submit the test file contents via `mcp__supabase__execute_sql`.

Expected: all 7 tests PASS. The final NOTICE reads `freemium_guards_bypass_fields_test: 7 / 7 passed` and no exception raised.

### Step 1.6: Re-run the original exploit to prove fix is live

- [ ] **Step 1.6: Re-run Step 1.1a verbatim**

Expected: ATTACKS A, B, C, D all raise `cannot reset/refill freemium gating field: ...`. Save proof:

```bash
cat > /tmp/p0-1-repro-after.txt <<'EOF'
P0-1 LIVE EXPLOIT — AFTER FIX
attack_a: BLOCKED (existing guard, regression-pinned)
attack_b: BLOCKED — reflect_bypasses_used guard fires
attack_c: BLOCKED — first_bypass_consumed guard fires
attack_d: BLOCKED — lifetime_bypasses_purchased guard fires
EOF
```

### Step 1.7: Commit

- [ ] **Step 1.7: Commit P0-1**

```bash
git add supabase/migrations/20260524000000_extend_freemium_guards_for_bypass_fields.sql \
        supabase/tests/freemium_guards_bypass_fields_test.sql
git commit -m "fix(security): extend freemium guards to cover bypass counters (P0-1)

The AI-bypass feature (PRs #20-24) added 3 columns to user_daily_usage
and 2 to user_profiles that all participate in gating, but the
freemium-guard triggers from 20260510010000 were not extended.

Verified live: any authenticated user could reset reflect_bypasses_used
to 0 between attempts (defeating the 2/day cap), flip
first_bypass_consumed true->false (replay the Day-1 freebie), and zero
lifetime_bypasses_purchased (hide spend from EXP-3 trigger).

Honest paths run through SECURITY DEFINER RPCs as service_role, which
bypasses the guard. No behavior change for legitimate users.

Pinned by supabase/tests/freemium_guards_bypass_fields_test.sql (7
assertions covering each new field + happy-path increments)."
```

---

## Task 2 — P0-2: Add idempotency to `reserve_ai_bypass`

**Files:**
- Create: `supabase/migrations/20260524010000_reserve_ai_bypass_idempotency.sql`
- Create: `supabase/tests/reserve_ai_bypass_idempotency_test.sql`
- Modify: `lib/services/gating_service.dart` (around lines 356–406 — pass key)
- Modify: `test/services/gating_service_bypass_test.dart` (assert key is sent)

### Step 2.1: Reproduce double-debit live

- [ ] **Step 2.1: Run the double-call exploit via Supabase MCP**

```sql
BEGIN;
-- Seed user with enough tokens and clean state for today
UPDATE public.user_tokens SET balance=200 WHERE user_id='6c111b1a-ac0c-44b1-8b92-efccde306f15';
DELETE FROM public.user_daily_usage
  WHERE user_id='6c111b1a-ac0c-44b1-8b92-efccde306f15'
    AND usage_date=(timezone('utc',now()))::date;
DELETE FROM public.ai_bypass_reservations
  WHERE user_id='6c111b1a-ac0c-44b1-8b92-efccde306f15' AND status='pending';

-- Impersonate authenticated
SELECT set_config('request.jwt.claims',
  json_build_object('sub','6c111b1a-ac0c-44b1-8b92-efccde306f15','role','authenticated')::text, true);
SET LOCAL ROLE authenticated;

-- Two back-to-back calls — simulates user double-tapping the bypass CTA
SELECT public.reserve_ai_bypass('reflect') AS call_1;
SELECT public.reserve_ai_bypass('reflect') AS call_2;

-- Inspect: how many tokens were debited? How many reservations created?
RESET ROLE;
SELECT balance FROM public.user_tokens WHERE user_id='6c111b1a-ac0c-44b1-8b92-efccde306f15';
SELECT count(*) AS reservations FROM public.ai_bypass_reservations
  WHERE user_id='6c111b1a-ac0c-44b1-8b92-efccde306f15' AND status='pending';
ROLLBACK;
```

Expected (proves bug): balance = 200 - 50 = **150** (two debits), reservations = **2**. A single user action should have created 1 reservation and debited 25.

### Step 2.2: Write the failing SQL test

- [ ] **Step 2.2: Create `supabase/tests/reserve_ai_bypass_idempotency_test.sql`**

```sql
-- Pins idempotency behavior of reserve_ai_bypass: two calls with the same
-- idempotency_key MUST return the same reservation_id and debit tokens
-- only once.
begin;

create or replace function pg_temp.expect(cond boolean, name text)
returns void language plpgsql as $$
begin
  if cond then perform set_config('test.passed', (coalesce(current_setting('test.passed', true), '0')::int + 1)::text, false);
  else perform set_config('test.failed_names',
       coalesce(current_setting('test.failed_names', true), '') || name || ';', false);
  end if;
  perform set_config('test.total', (coalesce(current_setting('test.total', true), '0')::int + 1)::text, false);
end $$;

select set_config('test.total','0',false),
       set_config('test.passed','0',false),
       set_config('test.failed_names','',false);

do $$
declare v_uid uuid;
begin
  select id into v_uid from auth.users order by created_at limit 1;
  perform set_config('test.uid', v_uid::text, false);
end $$;

-- Seed clean state
update public.user_tokens set balance=200 where user_id=current_setting('test.uid')::uuid;
delete from public.user_daily_usage where user_id=current_setting('test.uid')::uuid and usage_date=(timezone('utc',now()))::date;
delete from public.ai_bypass_reservations where user_id=current_setting('test.uid')::uuid and status='pending';

perform set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
set local role authenticated;

-- TEST 1: two calls with same key return same reservation_id
do $$
declare r1 jsonb; r2 jsonb;
begin
  r1 := public.reserve_ai_bypass('reflect', 'idem-key-1');
  r2 := public.reserve_ai_bypass('reflect', 'idem-key-1');
  perform pg_temp.expect(
    (r1->>'reservation_id') = (r2->>'reservation_id'),
    'same key returns same reservation_id');
end $$;

-- TEST 2: only ONE row was created, tokens debited ONCE
do $$
declare v_count int; v_balance int;
begin
  reset role;
  select count(*) into v_count from public.ai_bypass_reservations
    where user_id=current_setting('test.uid')::uuid and status='pending';
  select balance into v_balance from public.user_tokens where user_id=current_setting('test.uid')::uuid;
  perform pg_temp.expect(v_count = 1, 'exactly one reservation persisted');
  perform pg_temp.expect(v_balance = 175, 'tokens debited exactly once (200-25=175)');
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
  set local role authenticated;
end $$;

-- TEST 3: a different key creates a SECOND reservation (within cap)
do $$
declare r3 jsonb;
begin
  r3 := public.reserve_ai_bypass('reflect', 'idem-key-2');
  perform pg_temp.expect(r3->>'ok' = 'true', 'different key creates new reservation');
  perform pg_temp.expect((r3->>'bypasses_used')::int = 2, 'second key brings bypasses_used to 2');
end $$;

-- TEST 4: third reservation rejected by cap (cap=2)
do $$
declare r4 jsonb;
begin
  r4 := public.reserve_ai_bypass('reflect', 'idem-key-3');
  perform pg_temp.expect(r4->>'ok' = 'false', 'third call rejected by cap');
  perform pg_temp.expect(r4->>'reason' = 'bypass_cap', 'correct rejection reason');
end $$;

-- TEST 5: re-calling with key-1 still returns reservation 1 even after cap
do $$
declare r5 jsonb; v_first uuid;
begin
  select id into v_first from public.ai_bypass_reservations
    where user_id=current_setting('test.uid')::uuid order by created_at asc limit 1;
  r5 := public.reserve_ai_bypass('reflect', 'idem-key-1');
  perform pg_temp.expect((r5->>'reservation_id')::uuid = v_first,
    'idempotent replay survives cap');
end $$;

-- TEST 6 (REGRESSION / BACKWARDS-COMPAT): the 1-arg shim must still work
-- for pre-PR-26 mobile clients in the wild. They lose idempotency but the
-- RPC keeps responding so the bypass UX doesn't appear broken on deploy.
reset role;
delete from public.user_daily_usage where user_id=current_setting('test.uid')::uuid
  and usage_date=(timezone('utc',now()))::date;
delete from public.ai_bypass_reservations where user_id=current_setting('test.uid')::uuid;
update public.user_tokens set balance=200 where user_id=current_setting('test.uid')::uuid;

do $$ declare r jsonb; begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.reserve_ai_bypass('reflect');  -- 1-arg legacy signature
  perform pg_temp.expect(r->>'ok' = 'true',
    'BACKWARDS-COMPAT: 1-arg reserve_ai_bypass shim still works');
  perform pg_temp.expect((r->>'reservation_id') is not null,
    'shim returns a reservation_id');
end $$;

reset role;

do $$
declare total int; passed int; failed_names text;
begin
  total := current_setting('test.total')::int;
  passed := current_setting('test.passed')::int;
  failed_names := current_setting('test.failed_names');
  raise notice 'reserve_ai_bypass_idempotency_test: % / % passed', passed, total;
  if failed_names <> '' then raise exception 'FAILURES: %', failed_names; end if;
end $$;

rollback;
```

- [ ] **Step 2.3: Run the test, expect FAIL**

Submit via `mcp__supabase__execute_sql`. Expected: fails immediately at `r1 := public.reserve_ai_bypass('reflect', 'idem-key-1')` with `function public.reserve_ai_bypass(text, text) does not exist`.

This proves the test requires the new 2-arg signature.

### Step 2.4: Write the migration (add column + unique index + new function)

- [ ] **Step 2.4: Create `supabase/migrations/20260524010000_reserve_ai_bypass_idempotency.sql`**

```sql
-- 2026-05-24: Add idempotency-key support to reserve_ai_bypass.
--
-- Background:
--   Plan doc 2026-05-23-ai-bypass-token-spend.md claims "idempotency keys
--   honored" but the table has no key column and the function has no key
--   parameter. Double-tap of the bypass CTA during network latency calls
--   reserve_ai_bypass twice, creating two pending reservations and debiting
--   50 tokens for what should be one user action (verified live 2026-05-24).
--
-- Fix:
--   1. Add ai_bypass_reservations.idempotency_key (nullable for historical
--      rows; will be NOT NULL on new rows enforced by the function).
--   2. Partial unique index on (user_id, idempotency_key) where
--      idempotency_key is not null. Partial so we don't break existing
--      pre-migration NULLs.
--   3. New 2-arg reserve_ai_bypass(text, text) that:
--        - looks up (current_user_id, p_idempotency_key) and returns the
--          existing reservation_id if found (regardless of status)
--        - otherwise behaves identically to the original
--      Drop the 1-arg version (no other callers; client will be updated in
--      the same PR).

alter table public.ai_bypass_reservations
  add column if not exists idempotency_key text;

-- Partial unique to allow legacy NULLs but enforce uniqueness on new rows
create unique index if not exists ai_bypass_reservations_user_idem_uniq
  on public.ai_bypass_reservations (user_id, idempotency_key)
  where idempotency_key is not null;

-- Backwards-compat: keep the 1-arg signature as a shim for pre-PR-26
-- mobile clients in the wild (no force-upgrade in app). Old clients lose
-- idempotency (each call generates a fresh server-side key, so a
-- double-tap still double-debits for them) but the RPC keeps responding,
-- so the bypass flow doesn't appear broken after deploy. New clients
-- (PR-26+) call the 2-arg version with a real UUID and get protection.
-- The 1-arg shim can be dropped in a future release after enough time
-- has passed for the old IPAs to drain (track via Mixpanel app version
-- segments).
create or replace function public.reserve_ai_bypass(p_feature text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  return public.reserve_ai_bypass(p_feature, 'legacy-' || gen_random_uuid()::text);
end;
$$;
revoke all on function public.reserve_ai_bypass(text) from public, anon;
grant execute on function public.reserve_ai_bypass(text) to authenticated, service_role;

create or replace function public.reserve_ai_bypass(
  p_feature text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_user_id uuid := auth.uid();
  v_cost int; v_cap int; v_balance int; v_bypasses_used int;
  v_reservation_id uuid;
  v_existing_id uuid;
  v_today date := timezone('utc', now())::date;
begin
  if current_user_id is null then raise exception 'Not authenticated'; end if;
  if p_idempotency_key is null or length(p_idempotency_key) < 8 then
    return jsonb_build_object('ok',false,'reason','missing_idempotency_key');
  end if;
  if p_feature not in ('reflect','built_dua','discover_name') then
    return jsonb_build_object('ok',false,'reason','invalid_feature');
  end if;

  -- Idempotency replay: if this user already submitted a row with this key,
  -- return the existing reservation_id. No tokens debited, no counter
  -- incremented. Status doesn't matter — if cancelled, the client is
  -- replaying a stale tap and gets the (now non-pending) id back.
  select id into v_existing_id
    from public.ai_bypass_reservations
    where user_id = current_user_id
      and idempotency_key = p_idempotency_key;
  if v_existing_id is not null then
    select balance into v_balance from public.user_tokens
      where user_id = current_user_id;
    return jsonb_build_object(
      'ok', true,
      'reservation_id', v_existing_id,
      'balance', coalesce(v_balance, 0),
      'bypasses_used', null,
      'replayed', true
    );
  end if;

  -- Otherwise, identical to prior behavior
  select (value::text)::int into v_cost from public.app_config where key='bypass_token_cost';
  v_cost := coalesce(v_cost, 25);
  select (value::text)::int into v_cap from public.app_config where key='max_bypasses_per_day';
  v_cap := coalesce(v_cap, 2);

  insert into public.user_tokens (user_id) values (current_user_id) on conflict (user_id) do nothing;
  insert into public.user_daily_usage (user_id, usage_date) values (current_user_id, v_today)
    on conflict (user_id, usage_date) do nothing;

  select balance into v_balance from public.user_tokens
    where user_id = current_user_id for update;
  if v_balance < v_cost then
    return jsonb_build_object('ok',false,'reason','no_tokens','balance',v_balance);
  end if;

  case p_feature
    when 'reflect' then
      select reflect_bypasses_used into v_bypasses_used from public.user_daily_usage
        where user_id=current_user_id and usage_date=v_today for update;
    when 'built_dua' then
      select built_dua_bypasses_used into v_bypasses_used from public.user_daily_usage
        where user_id=current_user_id and usage_date=v_today for update;
    when 'discover_name' then
      select discover_name_bypasses_used into v_bypasses_used from public.user_daily_usage
        where user_id=current_user_id and usage_date=v_today for update;
  end case;
  if v_bypasses_used >= v_cap then
    return jsonb_build_object('ok',false,'reason','bypass_cap','bypasses_used',v_bypasses_used);
  end if;

  update public.user_tokens set balance=balance-v_cost, total_spent=total_spent+v_cost
    where user_id=current_user_id returning balance into v_balance;

  case p_feature
    when 'reflect' then
      update public.user_daily_usage set reflect_bypasses_used=reflect_bypasses_used+1
        where user_id=current_user_id and usage_date=v_today
        returning reflect_bypasses_used into v_bypasses_used;
    when 'built_dua' then
      update public.user_daily_usage set built_dua_bypasses_used=built_dua_bypasses_used+1
        where user_id=current_user_id and usage_date=v_today
        returning built_dua_bypasses_used into v_bypasses_used;
    when 'discover_name' then
      update public.user_daily_usage set discover_name_bypasses_used=discover_name_bypasses_used+1
        where user_id=current_user_id and usage_date=v_today
        returning discover_name_bypasses_used into v_bypasses_used;
  end case;

  insert into public.ai_bypass_reservations
    (user_id, feature, tokens_held, status, created_at, idempotency_key)
    values (current_user_id, p_feature, v_cost, 'pending', now(), p_idempotency_key)
    returning id into v_reservation_id;

  return jsonb_build_object('ok',true,'reservation_id',v_reservation_id,
    'balance',v_balance,'bypasses_used',v_bypasses_used,'replayed',false);
end;
$$;

revoke all on function public.reserve_ai_bypass(text, text) from public, anon;
grant execute on function public.reserve_ai_bypass(text, text) to authenticated, service_role;
```

### Step 2.5: Apply migration, re-run SQL test

- [ ] **Step 2.5a:** Use `mcp__supabase__apply_migration` with name `reserve_ai_bypass_idempotency` and the body above.

- [ ] **Step 2.5b:** Re-run the SQL test from Step 2.2 via `mcp__supabase__execute_sql`.

Expected: `reserve_ai_bypass_idempotency_test: 7 / 7 passed`.

### Step 2.6: Update client to send idempotency key

- [ ] **Step 2.6a: Modify `lib/services/gating_service.dart`**

Find `Future<BypassReservation?> reserveBypass(GatedFeature feature) async {` (around line 356). Change the signature and body:

```dart
// Add to imports at top of file if not present
import 'package:uuid/uuid.dart';

// Then replace the entire reserveBypass body
Future<BypassReservation?> reserveBypass(GatedFeature feature) async {
  if (await PurchaseService().isPremium()) return null;

  final featureKey = _bypassFeatureKey(feature);
  final idempotencyKey = const Uuid().v4();
  final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
    'reserve_ai_bypass',
    {'p_feature': featureKey, 'p_idempotency_key': idempotencyKey},
  );
  // ...rest of body unchanged...
}
```

If `uuid` is not already in pubspec.yaml, add it:

```yaml
dependencies:
  uuid: ^4.5.1
```

Run: `flutter pub get`

- [ ] **Step 2.6b: Modify analytics_events test or add `idempotency_key` property pin**

No analytics change required — the key is not sent to Mixpanel (it's transport-only).

### Step 2.7: Update Dart test to assert key is sent

- [ ] **Step 2.7: Edit `test/services/gating_service_bypass_test.dart`**

Find any test that captures the args to `rpcHandlers['reserve_ai_bypass']`. Add an assertion:

```dart
test('reserveBypass sends an idempotency_key (uuid v4)', () async {
  Map<String, dynamic>? capturedArgs;
  fakeSync.rpcHandlers['reserve_ai_bypass'] = (args) {
    capturedArgs = args;
    return {
      'ok': true, 'reservation_id': 'r-1', 'balance': 75, 'bypasses_used': 1,
    };
  };
  await GatingService().reserveBypass(GatedFeature.reflect);
  expect(capturedArgs, isNotNull);
  expect(capturedArgs!['p_feature'], 'reflect');
  expect(capturedArgs!['p_idempotency_key'], isA<String>());
  // UUID v4 is 36 chars with hyphens at positions 8, 13, 18, 23
  expect((capturedArgs!['p_idempotency_key'] as String).length, 36);
});

test('two reserveBypass calls send DIFFERENT idempotency keys', () async {
  final keys = <String>[];
  fakeSync.rpcHandlers['reserve_ai_bypass'] = (args) {
    keys.add(args['p_idempotency_key'] as String);
    return {'ok': true, 'reservation_id': 'r-${keys.length}', 'balance': 75, 'bypasses_used': keys.length};
  };
  await GatingService().reserveBypass(GatedFeature.reflect);
  await GatingService().reserveBypass(GatedFeature.reflect);
  expect(keys.length, 2);
  expect(keys[0], isNot(equals(keys[1])));
});
```

- [ ] **Step 2.8: Run Dart tests**

Run: `flutter test test/services/gating_service_bypass_test.dart --no-pub`

Expected: all tests pass, including the two new ones.

### Step 2.9: Re-run live exploit, prove fixed

- [ ] **Step 2.9: Re-run Step 2.1 verbatim**

Expected: both calls now fail with `function public.reserve_ai_bypass(text) does not exist` (since we dropped the 1-arg version). To exercise the new path, repro with the 2-arg version and same key:

```sql
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"...","role":"authenticated"}', true);
SELECT public.reserve_ai_bypass('reflect', 'test-key-aaa') AS call_1;
SELECT public.reserve_ai_bypass('reflect', 'test-key-aaa') AS call_2;
RESET ROLE;
SELECT balance FROM public.user_tokens WHERE user_id='...';
SELECT count(*) FROM public.ai_bypass_reservations WHERE user_id='...' AND status='pending';
ROLLBACK;
```

Expected: both calls return same `reservation_id`, second includes `"replayed":true`, balance debited once, exactly 1 reservation row.

### Step 2.10: Commit

```bash
git add supabase/migrations/20260524010000_reserve_ai_bypass_idempotency.sql \
        supabase/tests/reserve_ai_bypass_idempotency_test.sql \
        lib/services/gating_service.dart \
        test/services/gating_service_bypass_test.dart \
        pubspec.yaml pubspec.lock
git commit -m "fix(payments): add idempotency to reserve_ai_bypass (P0-2)

Plan doc claimed 'idempotency keys honored' but neither the table nor
the function had a key. Double-tap during network latency triggered two
reservations and debited 50 tokens for one user action (verified live).

Migration adds ai_bypass_reservations.idempotency_key + partial unique
index + 2-arg reserve_ai_bypass that replays the prior reservation when
the (user_id, key) tuple repeats. Client generates a UUID v4 per
reserve call via package:uuid."
```

---

## Task 3 — P0-3: `_today()` to UTC with debug clock seam

**Files:**
- Modify: `lib/services/daily_usage_service.dart:31-46` (the `_today()` family of helpers)
- Modify: `test/services/daily_usage_service_test.dart` (or create if missing)

### Step 3.1: Reproduce the bug with a failing test

- [ ] **Step 3.1: Create `test/services/daily_usage_service_utc_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/daily_usage_service.dart' as dus;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    dus.debugDailyUsageClock = null;
  });

  test('REGRESSION: keys use UTC date, not local-time date (PR #8-style)', () async {
    // Pin clock to 23:30 EDT on 2026-06-15 = 03:30 UTC on 2026-06-16.
    // Locally still "yesterday", in UTC it's "today".
    dus.debugDailyUsageClock = () =>
        DateTime.utc(2026, 6, 16, 3, 30); // already UTC

    await dus.incrementReflectUsage();
    final today = await dus.getReflectUsageToday();
    expect(today, 1, reason: 'should write to UTC date bucket');

    // If a sibling caller reads the local-time key, they would see 0
    // because local-time "yesterday" key doesn't have the increment.
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys().toList();
    expect(
      allKeys.any((k) => k.contains('2026-06-16')),
      isTrue,
      reason: 'must include the UTC date in the prefs key',
    );
    expect(
      allKeys.any((k) => k.contains('2026-06-15')),
      isFalse,
      reason: 'must NOT include the local-time date in the prefs key',
    );
  });
}
```

- [ ] **Step 3.2: Run, expect FAIL**

Run: `flutter test test/services/daily_usage_service_utc_test.dart --no-pub`

Expected: fails because `debugDailyUsageClock` doesn't exist yet and `_today()` uses local time.

### Step 3.3: Apply the fix

- [ ] **Step 3.3: Edit `lib/services/daily_usage_service.dart` lines 27–46**

Replace:

```dart
const int dailyFreeReflects = 1;
const int dailyFreeBuiltDuas = 1;
const int dailyFreeDiscoverNames = 1;

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _todayKey(String feature) {
  return supabaseSyncService.scopedKey(
    'daily_usage_${feature}_${_today()}',
  );
}

String _bypassTodayKey(String feature) {
  return supabaseSyncService.scopedKey(
    'daily_bypass_${feature}_${_today()}',
  );
}
```

With:

```dart
const int dailyFreeReflects = 1;
const int dailyFreeBuiltDuas = 1;
const int dailyFreeDiscoverNames = 1;

/// Debug seam mirroring `debugRewardsClock` and `debugLaunchGateClock` so
/// tests can pin a known UTC instant. Always returns UTC.
///
/// Production callers should leave this null. The default reads
/// `DateTime.now().toUtc()` to match the server (Supabase stores
/// user_daily_usage.usage_date in UTC, set via `timezone('utc', now())`).
///
/// Previously this used `DateTime.now()` (local), which caused the
/// client cap state to disagree with the server near local-but-not-UTC
/// midnight (e.g. 11pm EDT). Same regression class as the
/// daily-launch overlay UTC fix in PR #8 — see CLAUDE.md Known Bugs.
@visibleForTesting
DateTime Function()? debugDailyUsageClock;

DateTime _nowUtc() =>
    (debugDailyUsageClock ?? () => DateTime.now().toUtc())();

String _today() {
  final now = _nowUtc();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _todayKey(String feature) {
  return supabaseSyncService.scopedKey(
    'daily_usage_${feature}_${_today()}',
  );
}

String _bypassTodayKey(String feature) {
  return supabaseSyncService.scopedKey(
    'daily_bypass_${feature}_${_today()}',
  );
}
```

Add at top of file (after existing imports):

```dart
import 'package:flutter/foundation.dart' show visibleForTesting;
```

- [ ] **Step 3.4: Re-run the test, expect PASS**

Run: `flutter test test/services/daily_usage_service_utc_test.dart --no-pub`

Expected: passes.

- [ ] **Step 3.5: Run the whole gating + daily test sweep to catch any callers that relied on local time**

Run:
```bash
flutter test test/services/ test/features/daily/ test/features/reflect/ test/features/paywall/ --no-pub
```

Expected: all pass. If anything breaks because a sibling test seeded prefs at a local-time key, update that test to seed at the UTC key.

### Step 3.6: Commit

```bash
git add lib/services/daily_usage_service.dart test/services/daily_usage_service_utc_test.dart
git commit -m "fix(daily): use UTC for daily_usage prefs keys (P0-3)

Mirror PR #8's launch-gate fix. The server stores usage_date as UTC; the
client was keying SharedPreferences by local date. Near local-but-not-UTC
midnight (e.g. 11pm EDT = 3am UTC next day) the client saw
bypassesUsedToday=0 while the server said 2, surfacing a 'Use 25
tokens' CTA the server then rejected.

Added @visibleForTesting debugDailyUsageClock seam matching the
debugRewardsClock pattern. Tests now pin UTC behavior at the EDT
midnight boundary.

Backwards-compat note (one-time grace period): existing SharedPreferences
keys were written under local-date. After this commit deploys, the new
code reads UTC-date keys and finds zero for any user in a non-UTC
timezone on upgrade day. They get bonus free uses for that one day.
Acceptable trade-off vs writing a SharedPreferences migration script for
a one-day cosmetic regression. Documented in CLAUDE.md Known Bugs in
Task 7.1."
```

---

## Task 4 — P0-4: Dispose cancels in-flight bypass reservations

**Files:**
- Modify: `lib/features/reflect/providers/reflect_provider.dart` (add dispose override)
- Modify: `lib/features/daily/providers/daily_loop_provider.dart` (same)
- Modify: `lib/features/duas/providers/duas_provider.dart` (same)
- Modify or create: `test/features/reflect/reflect_dispose_cancel_test.dart`

### Step 4.1: Write the failing dispose test

- [ ] **Step 4.1: Add new test file `test/features/reflect/reflect_dispose_cancel_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/gating_service.dart';
// Test helpers — copy the FakeSupabaseSyncService / FakePurchaseService
// pattern from reflect_bypass_flow_test.dart.

void main() {
  // (Setup omitted for brevity — copy the exact fixtures used in
  // reflect_bypass_flow_test.dart so the test wires correctly into
  // ProviderContainer + ReflectNotifier + GatingService.)

  test('REGRESSION: dispose mid-AI-call cancels the active bypass reservation', () async {
    final cancelledIds = <String>[];
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) =>
      {'ok': true, 'reservation_id': 'r-abc', 'balance': 75, 'bypasses_used': 1};
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (args) {
      cancelledIds.add(args['p_reservation_id'] as String);
      return {'ok': true, 'refunded_tokens': 25, 'balance': 100};
    };

    // Stub the AI call to hang forever (simulates user backgrounding the app)
    final container = ProviderContainer(overrides: [
      // ...override aiService.reflect to return a never-completing Future
    ]);
    final notifier = container.read(reflectProvider.notifier);

    // Fire the bypass-funded submit, do NOT await
    final pending = notifier.submitWithBypass('I feel anxious');

    // Yield once so reserveBypass completes and _activeBypassReservationId is set
    await Future<void>.delayed(Duration.zero);

    // Now dispose the container (simulates the user popping the screen)
    container.dispose();

    // Yield to let dispose() fire-and-forget cancel
    await Future<void>.delayed(Duration.zero);

    expect(cancelledIds, ['r-abc'],
      reason: 'dispose() must cancel the in-flight reservation');
  });
}
```

- [ ] **Step 4.2: Run, expect FAIL**

Run: `flutter test test/features/reflect/reflect_dispose_cancel_test.dart --no-pub`

Expected: fails — no cancel RPC was fired because ReflectNotifier has no dispose override that cancels.

### Step 4.3: Apply the fix to ReflectNotifier

- [ ] **Step 4.3a: Edit `lib/features/reflect/providers/reflect_provider.dart`**

Find the class declaration `class ReflectNotifier extends StateNotifier<ReflectState>`. Locate `_activeBypassReservationId` (declared around line 325). Add a dispose override:

```dart
@override
void dispose() {
  // P0-4: cancel any in-flight bypass reservation so the user's tokens
  // are refunded immediately instead of waiting up to 15 min for the
  // server-side orphan cron. Fire-and-forget — we're tearing down,
  // failures here are unrecoverable anyway.
  //
  // Safety: dispose can run during app shutdown when the Supabase
  // client is mid-teardown. Wrap in try/catch and use .ignore() so a
  // sync throw or rejected future doesn't escape into Flutter's
  // unhandled-error logger. Orphan cron rescues at 15 min worst case.
  final id = _activeBypassReservationId;
  _activeBypassReservationId = null;
  if (id != null) {
    try {
      GatingService().cancelBypass(id, GatedFeature.reflect).ignore();
    } catch (_) {
      // Tearing down; orphan cron will refund.
    }
  }
  super.dispose();
}
```

Place this just before the existing `reset()` method (which has similar shape but doesn't fire on dispose).

- [ ] **Step 4.3b: Re-run the dispose test, expect PASS**

Run: `flutter test test/features/reflect/reflect_dispose_cancel_test.dart --no-pub`

Expected: passes.

### Step 4.4: Apply the same fix to daily_loop_provider and duas_provider

- [ ] **Step 4.4a: Mirror the dispose override in `lib/features/daily/providers/daily_loop_provider.dart`**

Find where `_activeBypassReservationId` is declared in that file and add the same `@override void dispose()` block from Step 4.3a verbatim, but with `GatedFeature.discoverName` instead of `GatedFeature.reflect`:

```dart
@override
void dispose() {
  final id = _activeBypassReservationId;
  _activeBypassReservationId = null;
  if (id != null) {
    try {
      GatingService().cancelBypass(id, GatedFeature.discoverName).ignore();
    } catch (_) {
      // Tearing down; orphan cron will refund.
    }
  }
  super.dispose();
}
```

- [ ] **Step 4.4b: Mirror in `lib/features/duas/providers/duas_provider.dart`**

Same shape as 4.4a, but feature is `GatedFeature.builtDua`:

```dart
@override
void dispose() {
  final id = _activeBypassReservationId;
  _activeBypassReservationId = null;
  if (id != null) {
    try {
      GatingService().cancelBypass(id, GatedFeature.builtDua).ignore();
    } catch (_) {
      // Tearing down; orphan cron will refund.
    }
  }
  super.dispose();
}
```

- [ ] **Step 4.4c: Add equivalent regression tests for both sibling providers**

Create:
- `test/features/daily/discover_name_dispose_cancel_test.dart`
- `test/features/duas/build_dua_dispose_cancel_test.dart`

Each test follows the same shape as Step 4.1. Run both and expect PASS.

### Step 4.5: Run the full bypass-flow suite

- [ ] **Step 4.5: Verify no flow regression**

Run: `flutter test test/features/reflect/ test/features/daily/ test/features/duas/ test/features/paywall/ test/services/gating_service_bypass_test.dart --no-pub`

Expected: all pass, including the existing reflect_bypass_flow_test.dart (commit/cancel happy paths must still work).

### Step 4.6: Commit

```bash
git add lib/features/reflect/providers/reflect_provider.dart \
        lib/features/daily/providers/daily_loop_provider.dart \
        lib/features/duas/providers/duas_provider.dart \
        test/features/reflect/reflect_dispose_cancel_test.dart \
        test/features/daily/discover_name_dispose_cancel_test.dart \
        test/features/duas/build_dua_dispose_cancel_test.dart
git commit -m "fix(bypass): cancel in-flight reservations on notifier dispose (P0-4)

When a user backgrounds the app or pops the route mid-AI-call, the
ReflectNotifier (and 2 sibling notifiers) tore down without cancelling
the active bypass reservation. The reservation sat pending until the
15-minute orphan cron rescued it, blocking the user from re-entering
the bypass path with locked tokens.

All three notifiers now override dispose() to fire-and-forget
cancelBypass with the active reservation id. Regression-pinned per
feature."
```

---

## Task 5 — P0-5: Emit `iap_to_sub_banner_shown` event

**Files:**
- Modify: `lib/widgets/iap_to_sub_upsell_banner.dart` (around lines 173–200)
- Modify: `test/widgets/iap_to_sub_upsell_banner_test.dart`

### Step 5.1: Write the failing test

- [ ] **Step 5.1: Add tests to `test/widgets/iap_to_sub_upsell_banner_test.dart`**

The file already has a `SpyAnalytics` test double and uses the Riverpod override pattern (see existing tests around line 84 that do `analyticsProvider.overrideWithValue(spy)`). Reuse that pattern — do NOT introduce a new static-capture API.

```dart
// Add these two tests inside the main() body, alongside the existing
// banner tests. Re-use the existing _pumpBanner helper / SpyAnalytics
// double already in the file. If SpyAnalytics doesn't expose a
// "calls" list yet, add one that records (event, properties) tuples.

testWidgets('REGRESSION: iap_to_sub_banner_shown fires once when banner becomes visible', (tester) async {
  final spy = SpyAnalytics();
  await _pumpBanner(
    tester,
    analytics: spy,
    state: IapToSubBannerState.visible(
      lifetimeBypassesPurchased: 8,
      weeklyPriceString: r'$4.99',
    ),
    currentPath: '/home',
  );
  await tester.pump(); // run the post-frame callback that emits

  final shownCalls = spy.calls
      .where((c) => c.event == AnalyticsEvents.iapToSubBannerShown)
      .toList();
  expect(shownCalls.length, 1,
      reason: 'should fire exactly once on first visible render');
  expect(shownCalls.single.properties?['lifetime_bypasses_purchased'], 8,
      reason: 'event includes the lifetime count for funnel segmentation');

  // Subsequent rebuilds with same visible state must NOT re-fire
  await tester.pump();
  await tester.pump();
  expect(
    spy.calls.where((c) => c.event == AnalyticsEvents.iapToSubBannerShown).length,
    1,
    reason: 'sticky guard prevents re-fire on rebuild',
  );
});

testWidgets('REGRESSION: iap_to_sub_banner_shown does NOT fire when banner is hidden', (tester) async {
  final spy = SpyAnalytics();
  await _pumpBanner(
    tester,
    analytics: spy,
    state: IapToSubBannerState.hidden,
    currentPath: '/home',
  );
  await tester.pump();
  expect(
    spy.calls.any((c) => c.event == AnalyticsEvents.iapToSubBannerShown),
    isFalse,
  );
});

// Additionally: a structural test that catches the next time someone
// declares an analytics event by name but forgets to wire a producer.
test('iapToSubBannerShown has at least one producer in lib/', () async {
  final dir = Directory('lib/');
  final hits = <String>[];
  await for (final f in dir.list(recursive: true)) {
    if (f is File && f.path.endsWith('.dart')) {
      final content = await f.readAsString();
      if (content.contains('AnalyticsEvents.iapToSubBannerShown')) {
        hits.add(f.path);
      }
    }
  }
  expect(hits, isNotEmpty,
      reason: 'event must have a producer (P0-5 regression pin)');
});
```

If `SpyAnalytics` in the existing test file doesn't already expose a `calls` list of `(event, properties)`, extend it minimally:

```dart
class _SpyAnalyticsCall {
  _SpyAnalyticsCall(this.event, this.properties);
  final String event;
  final Map<String, dynamic>? properties;
}

class SpyAnalytics extends AnalyticsService {
  final List<_SpyAnalyticsCall> calls = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    calls.add(_SpyAnalyticsCall(event, properties));
  }
}
```

- [ ] **Step 5.2: Run, expect FAIL**

Run: `flutter test test/widgets/iap_to_sub_upsell_banner_test.dart --no-pub`

Expected: the first test fails — zero `iap_to_sub_banner_shown` events fired.

### Step 5.3: Apply the fix

- [ ] **Step 5.3: Edit `lib/widgets/iap_to_sub_upsell_banner.dart`**

Find the `_IapToSubUpsellBannerState` class. Add a sticky flag and emit in `build()`:

```dart
// Add to state class (near _currentPath declaration)
bool _shownEventFired = false;
```

Then in `build()`, after the `if (!state.visible) return const SizedBox.shrink();` line (around line 182), and BEFORE the existing computation of `dollarsSpent`, add:

```dart
// P0-5: fire shown event once per visible mount. Sticky boolean so
// rebuilds (route changes, theme changes, parent invalidations) don't
// re-emit. The fire is post-frame because emitting analytics during
// build is a layout-pass violation.
//
// IMPORTANT: use the Riverpod analyticsProvider pattern that the rest
// of this file already uses (lines 287-289, 303-304). AnalyticsService
// is NOT a static class — the static call style would not compile.
if (!_shownEventFired) {
  _shownEventFired = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return; // widget may have disposed between build and post-frame
    ref.read(analyticsProvider).track(
      AnalyticsEvents.iapToSubBannerShown,
      properties: {
        'lifetime_bypasses_purchased': state.lifetimeBypassesPurchased,
      },
    );
  });
}
```

- [ ] **Step 5.4: Re-run the test, expect PASS**

Run: `flutter test test/widgets/iap_to_sub_upsell_banner_test.dart --no-pub`

Expected: both new tests pass + all existing banner tests still pass.

### Step 5.5: Commit

```bash
git add lib/widgets/iap_to_sub_upsell_banner.dart test/widgets/iap_to_sub_upsell_banner_test.dart
git commit -m "fix(analytics): emit iap_to_sub_banner_shown when banner renders (P0-5)

The event was declared in analytics_events.dart and pinned by name in
analytics_events_test.dart but had zero call sites. The EXP-3 funnel
(shown → tapped → dismissed) had no denominator, making the readout
unmeasurable.

Banner now fires once per visible mount via a sticky boolean, using a
post-frame callback to avoid the in-build emit footgun."
```

---

## Task 6 — End-to-end verification (simulator + advisors + full test suite)

**Files:** none modified, this task only runs verifications.

### Step 6.1: Run full Dart test suite

- [ ] **Step 6.1:** Run `flutter test --no-pub`

Expected: all tests pass. Baseline count (from Step 0.2) plus the new tests added in this PR (~15 new tests).

### Step 6.2: Run full SQL test suite via Supabase MCP

- [ ] **Step 6.2:** Submit each of the following file contents via `mcp__supabase__execute_sql`:

```
supabase/tests/freemium_guards_bypass_fields_test.sql       (NEW - 7 tests)
supabase/tests/reserve_ai_bypass_idempotency_test.sql       (NEW - 7 tests)
supabase/tests/ai_bypass_rpc_test.sql                       (existing - must still pass)
supabase/tests/dismiss_iap_upsell_banner_test.sql           (existing)
supabase/tests/freemium_gating_lockdown_test.sql            (existing)
supabase/tests/sync_all_user_data_returns_verses_test.sql   (existing)
supabase/tests/backend_rls_test.sql                         (existing)
```

Expected: every file ends with `X / X passed` and no exceptions raised.

### Step 6.3: Run Supabase advisors

- [ ] **Step 6.3:** Use `mcp__supabase__get_advisors` with `type: "security"` and again with `type: "performance"`.

Expected: no NEW warnings introduced. Pre-existing `cancel_ai_bypass`, `reserve_ai_bypass`, etc. advisors are unchanged (those are by-design for authenticated callers). Leaked-password protection (a pre-existing P2) stays open — out of scope for this PR.

### Step 6.4: iOS Simulator smoke — build, install, walk through the bypass flow

- [ ] **Step 6.4a: Build the app**

```bash
flutter build ios --simulator --dart-define-from-file=env.json
```

Expected: builds successfully.

- [ ] **Step 6.4b: Install on the booted simulator**

Use `mcp__ios-simulator__get_booted_sim_id` then `mcp__ios-simulator__install_app` with path `build/ios/iphonesimulator/Runner.app`.

- [ ] **Step 6.4c: Launch and verify cold-launch home renders**

Use `mcp__ios-simulator__launch_app` with `bundle_id: com.sakina.app` (or whatever the actual bundle id is — check `ios/Runner.xcodeproj/project.pbxproj`).

Use `mcp__ios-simulator__screenshot` to capture. Save to `/tmp/p0-smoke-home.png`. Inspect with `Read` — verify the home screen renders (no crash from the gating_service uuid import or daily_usage UTC change).

- [ ] **Step 6.4d: Walk the bypass flow**

1. Tap **Reflect** in bottom nav (use `mcp__ios-simulator__ui_describe_all` to find coords).
2. Type something into the reflect input (`mcp__ios-simulator__ui_type`).
3. Tap submit. Repeat until daily cap hit.
4. When the DailyCapSheet appears, screenshot it. Verify the bypass CTA is present.
5. Tap the bypass CTA. Screenshot the result. Verify the reflection rendered and tokens decremented (visible in the header chip).

Expected: no crash. Bypass succeeds. Tokens debited by 25.

- [ ] **Step 6.4e: Test double-tap idempotency live**

Hit the bypass CTA twice in rapid succession (use two `mcp__ios-simulator__ui_tap` calls with no delay).

Check via `mcp__supabase__execute_sql`:
```sql
SELECT count(*), sum(tokens_held) FROM public.ai_bypass_reservations
WHERE user_id='<test-uid>'
  AND created_at > now() - interval '1 minute'
  AND status='pending';
```

Expected: count = 1 (not 2), sum = 25 (not 50). The two taps resolved to the same idempotent reservation.

- [ ] **Step 6.4f: Verify the IAP→sub upsell banner emits the shown event**

(Only feasible if a test user with `lifetime_bypasses_purchased >= 6` and `created_at > 7 days ago` and no recent dismissal exists. Otherwise note this step as covered by widget test from Task 5.)

If feasible: sign in as such a user, observe the banner appear at top of home, then check the Mixpanel event log via `mcp__mixpanel__Get-Events` filtered to `iap_to_sub_banner_shown` in the last 5 minutes.

Expected: at least one event recorded for the simulator user.

### Step 6.5: `flutter analyze` clean

- [ ] **Step 6.5:** Run `flutter analyze` and verify no new errors/warnings (pre-existing infos OK).

---

## Task 7 — Documentation + PR

**Files:**
- Modify: `flutter/CLAUDE.md` (Known Bugs section)
- Modify: `docs/superpowers/plans/2026-05-23-ai-bypass-token-spend.md` (status header)

### Step 7.1: Update CLAUDE.md Known Bugs

- [ ] **Step 7.1:** Edit `flutter/CLAUDE.md` "Known Bugs" section. Add six entries using the project's `~~bug name~~ (FIXED date — explanation. Regression-pinned by test.)` format:

1. **P0-1** Freemium guards missing for bypass counters. Regression-pinned by `supabase/tests/freemium_guards_bypass_fields_test.sql`.
2. **P0-2** `reserve_ai_bypass` had no idempotency key. Regression-pinned by `supabase/tests/reserve_ai_bypass_idempotency_test.sql`. **Backwards-compat shim:** the 1-arg signature remains as a wrapper that generates a server-side key — pre-PR-26 clients keep working but lose double-tap protection (same as their pre-PR state).
3. **P0-3** `daily_usage_service._today()` used local time. Regression-pinned by `test/services/daily_usage_service_utc_test.dart`. **One-time grace period on deploy:** users in non-UTC timezones may see one bonus free use on upgrade day because the new code reads a different prefs key than the local-time one previously written. Self-corrects after first usage on the new code.
4. **P0-4** `ReflectNotifier` (and 2 sibling notifiers) leaked in-flight bypass reservations on dispose. Regression-pinned by `test/features/reflect/reflect_dispose_cancel_test.dart` (+ 2 siblings).
5. **P0-5** `iap_to_sub_banner_shown` declared but never emitted. Regression-pinned by `test/widgets/iap_to_sub_upsell_banner_test.dart` + a structural "has-producer" test.
6. **Bonus add:** add a section under "Gotchas" titled "AI-bypass feature" that summarizes the reserve/commit/cancel flow + the new idempotency-key contract (clients MUST pass a UUID v4 per user action; replay of same key returns same reservation).

### Step 7.2: Mark the AI-bypass plan as Shipped

- [ ] **Step 7.2:** Edit `docs/superpowers/plans/2026-05-23-ai-bypass-token-spend.md`. Change the Status header from `Status: Plan — pending user approval` to `Status: Shipped — PRs 1-5 landed 2026-05-22..23, P0 hotfix bundle landed 2026-05-24 (PR #25)`. Tick all 11 acceptance checkboxes per actual code state.

### Step 7.3: Push branch and open PR (against master)

- [ ] **Step 7.3a:** Push the branch:

```bash
git push -u origin hotfix/ai-bypass-p0-bundle
```

- [ ] **Step 7.3b:** Open the PR against master:

```bash
gh pr create --base master --title "Hotfix bundle: 5 P0s from AI-bypass post-merge review" --body "$(cat <<'EOF'
## Summary
Bundles five P0 fixes discovered in the post-merge review of commits 14c800f..2eeb5cb (PRs #20-24, the AI-bypass feature). Each fix has a live reproduction documented in the plan + a regression test.

- **P0-1** Extend freemium guards to cover bypass counters + first_bypass_consumed + lifetime_bypasses_purchased. Without this, any authenticated user could reset their daily cap, replay the Day-1 freebie forever, and hide spend from the EXP-3 upsell trigger. **Verified live: 3-of-3 exploit attempts succeeded against master, all blocked after this PR.**
- **P0-2** Add idempotency_key support to reserve_ai_bypass. Plan doc claimed it but neither the table nor the function had one — double-tap during latency double-debited 25 tokens. **Backwards-compat:** kept the 1-arg signature as a shim that auto-generates a server-side key, so pre-PR-26 IPAs in the wild keep working (they retain the pre-PR double-debit bug but the feature responds normally instead of erroring).
- **P0-3** daily_usage_service._today() switched to UTC. Mirrors PR #8's launch-gate fix; client cap state was desyncing from server at local midnight. **One-time grace period on deploy:** users in non-UTC timezones may see one bonus free use on the day they upgrade — documented in CLAUDE.md.
- **P0-4** ReflectNotifier + 2 siblings now cancel in-flight bypass reservations on dispose. Was leaking 25 tokens for up to 15 min until the orphan cron rescued. Wrapped in try/catch + .ignore() so app shutdown doesn't surface unhandled errors.
- **P0-5** IapToSubUpsellBanner now emits iap_to_sub_banner_shown via Riverpod analyticsProvider + post-frame callback (with mounted guard). Was declared, tested by name, but zero call sites — broke the EXP-3 funnel denominator.

## Migrations
1. 20260524000000_extend_freemium_guards_for_bypass_fields.sql
2. 20260524010000_reserve_ai_bypass_idempotency.sql  (keeps 1-arg shim for backwards-compat)

## Test plan
- [x] supabase/tests/freemium_guards_bypass_fields_test.sql (8 assertions including SECURITY DEFINER honest-path pin)
- [x] supabase/tests/reserve_ai_bypass_idempotency_test.sql (6 assertions including 1-arg shim regression)
- [x] All pre-existing SQL test files still pass
- [x] flutter test (~17 new Dart tests across daily_usage, reflect/daily/duas dispose, banner emit + structural producer pin, gating idempotency)
- [x] flutter analyze clean
- [x] iOS Simulator smoke: bypass flow + double-tap idempotency + banner shown event
- [x] Re-ran each live exploit, all blocked post-fix
- [x] Supabase advisors: no new warnings introduced

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 7.4: Commit + push docs

```bash
git add flutter/CLAUDE.md docs/superpowers/plans/2026-05-23-ai-bypass-token-spend.md
git commit -m "docs: record P0 hotfix bundle in CLAUDE.md + mark bypass plan shipped"
git push
```

### Step 7.5: File the CI follow-up TODO

- [ ] **Step 7.5:** Append to repo-root `TODOS.md`:

```markdown
## P1: Wire CI for flutter test + SQL test suites

**What:** Add `.github/workflows/test.yml` that runs `flutter test` and a script
to execute every `supabase/tests/*.sql` file against a branch DB on every PR.

**Why:** The 2,500+ lines of new Dart tests and ~1,400 lines of SQL pgTAP-style
tests added across the AI-bypass feature (PRs #20-24) and the P0 hotfix bundle
(PR #26) are aspirational-only — they have no CI hook. The repo has zero
`.github/workflows/`. Any regression in those areas ships silently until
someone runs the tests locally.

**Pros:** the existing test investment becomes load-bearing; PRs get a green
check before merge; SQL guard regressions get caught at PR time rather than in
production.

**Cons:** Supabase branch DB cost (small); CI run time (flutter test ~3 min on
hosted runners); requires `flutter` setup action + a psql client + a way to
seed at least one auth user for the SQL tests that need a UUID.

**Context:** PR #26 doc — `docs/superpowers/plans/2026-05-23-ai-bypass-p0-bundle.md`.
The eng-review surfaced this as a P2 distribution gap; deferred from the P0
bundle to keep scope tight.

**Depends on / blocked by:** none.
```

Commit:

```bash
git add TODOS.md
git commit -m "docs: file P1 TODO for CI wiring (deferred from PR #26)"
git push
```

---

## Self-Review Checklist (run before declaring plan done)

- [ ] Each P0 has 3 phases: live repro → fix → re-verify. ✓
- [ ] Each fix has a TDD-shaped task: failing test → fix → passing test. ✓
- [ ] No placeholder language ("add appropriate handling", "TODO"). ✓
- [ ] Every step contains either the actual code, the exact command, or the exact MCP tool call needed. ✓
- [ ] Types and names match across tasks: `idempotency_key` (column), `p_idempotency_key` (arg), `Uuid().v4()` (client), `debugDailyUsageClock` (seam). ✓
- [ ] Migration filenames sorted lexicographically AFTER 2026-05-23 PRs ✓
- [ ] No `--no-verify` or hook skipping in any commit. ✓
- [ ] Cleanup steps in repros wrapped in `BEGIN/ROLLBACK` so prod state is preserved. ✓
- [ ] Each commit has a single clear scope, suitable for individual revert if needed. ✓

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 7 issues found, all addressed in revision below |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | n/a | server + analytics only |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | n/a | not a dev-facing change |

**VERDICT:** ENG CLEARED — ready to implement.

### Eng-review revision log (2026-05-23)

Issues found by `/plan-eng-review` and folded into the plan above:

1. **Backwards-compat (CRITICAL):** original plan dropped 1-arg `reserve_ai_bypass`. Old IPAs in the wild would have started returning `function does not exist`. **Fix applied:** Task 2.4 now keeps a 1-arg shim that auto-generates a server-side key. Old clients keep working, lose only double-tap protection (which they already lacked). Regression-pinned by Task 2.2 Test 6.
2. **Won't-compile bug:** Task 5.3 used `AnalyticsService.track(...)` (static). **Fix applied:** rewritten to use `ref.read(analyticsProvider).track(event, properties: {...})` matching the existing call sites at lines 287-289, 303-304 of the banner file.
3. **Won't-compile test bug:** Task 5.1 used `AnalyticsService.testCapture` (doesn't exist). **Fix applied:** rewritten to use the existing `SpyAnalytics` + `analyticsProvider.overrideWithValue(...)` Riverpod pattern (matches existing tests in same file at line 84). Added a structural producer-pin test as a bonus.
4. **Shutdown safety:** Task 4 dispose overrides could escape unhandled errors. **Fix applied:** wrapped each in `try { GatingService().cancelBypass(id, feature).ignore(); } catch (_) {}` for all 3 notifiers.
5. **Frame safety:** Task 5 post-frame callback could fire on a torn-down widget. **Fix applied:** added `if (!mounted) return;` guard inside the callback.
6. **Honest-path regression pin:** Task 1.2 didn't verify that `cancel_ai_bypass` can still decrement the now-guarded `reflect_bypasses_used`. **Fix applied:** added Test 8 (verified live: function owner is `postgres` which is in the guard bypass list, so the SECURITY DEFINER path works through the guard).
7. **CI gap:** no `.github/workflows/` exists; all the new tests are aspirational. **Fix applied:** Task 7.5 files a P1 TODO for CI wiring rather than expanding this PR's scope.

Also: **Task 0 switched from worktree to a direct branch off master** per user direction.
