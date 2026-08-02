# Lantern Cosmetics — Plan 1 of 5: Backend Economy Foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the server-authoritative economy foundation for lantern cosmetics — inventory, catalog, Noor currency (earn-only, idempotent), atomic unlock/equip, a fixed milestone RPC, and sync — with full pgTAP coverage, before any client work.

**Architecture:** All economic state lives in Postgres and mutates ONLY through SECURITY DEFINER RPCs; guard triggers + RLS block direct client writes (same posture as the existing token/entitlement columns). Amounts are server-derived from a `reason` key against a ledger, so grants are idempotent and auditable. Cosmetics data rides the existing `sync_all_user_data()` RPC (small payload, one boot round-trip).

**Tech Stack:** Supabase Postgres, SQL migrations (`supabase/migrations/`), pgTAP (`supabase/tests/`), psql in CI.

**Source spec:** `docs/superpowers/specs/2026-07-25-lantern-cosmetics-design.md` (§4 data model, §13 correctness gaps). This plan implements spec §13 items 1, 2, 3, 8 and §4.

**Scope of THIS plan (Lane A only):** DB schema, guards/RLS, `award_noor`, `unlock_cosmetic`, `equip_cosmetic`, `claim_streak_milestone` fix, `sync_all_user_data` extension, catalog seed. **Out of scope here:** IAP grant/refund (Lane B, spec §13.4–5), premium/entitlement reconciliation (Lane B, §13.6–7), render/UI/widget (Lanes C–E).

---

## Read first (exact signatures — do NOT guess column names)

The CLAUDE.md rule "`saveOnboardingData` writes exact column names — one mismatch silently fails" applies to every RPC here. Before writing SQL, read:

- [ ] Read `supabase/migrations/20260509000000_revoke_anon_rpc_execute.sql` — the current `sync_all_user_data()` body + the return-shape it builds. Note the exact section keys and how existing sections (tokens, streak, card_collection) are assembled.
- [ ] Read `supabase/migrations/20260719000000_streaks_defense.sql:201-230` — the current `claim_streak_milestone(p_day int)` body, and the streak table/columns it reads (for the "reached" check).
- [ ] Read `supabase/migrations/20260412170000_economy_atomic_hardening_wave6.sql` — the established atomic-RPC + guard-trigger pattern to mirror (locking, error style).
- [ ] Read one pgTAP file e.g. `supabase/tests/ai_bypass_rpc_test.sql` and `supabase/checks/backend_rls_audit.sql` — the test harness style (plan(), `results_eq`, `throws_ok`, auth simulation via `set local role` / `request.jwt.claims`).

Record the real names you find (streak table, current-streak column, the auth-uid helper used, e.g. `auth.uid()`), and substitute them wherever this plan writes `<streak_table>` / `<current_streak_col>`.

## File structure

- Create: `supabase/migrations/20260726000000_cosmetics_economy.sql` — all schema + RPCs + guards + RLS for this plan (one migration; cosmetics is one cohesive unit).
- Create: `supabase/migrations/20260726000100_seed_cosmetic_catalog.sql` — catalog rows for launch skins/backdrops.
- Create: `supabase/tests/cosmetics_schema_test.sql`
- Create: `supabase/tests/cosmetics_award_noor_test.sql`
- Create: `supabase/tests/cosmetics_unlock_equip_test.sql`
- Create: `supabase/tests/cosmetics_milestone_fix_test.sql`
- Create: `supabase/tests/cosmetics_sync_test.sql`
- Modify: the `sync_all_user_data()` function (redefined inside `20260726000000_cosmetics_economy.sql` via `CREATE OR REPLACE`, preserving all existing sections + adding three).

---

## Task 1: Schema — inventory, catalog, currency columns

**Files:**
- Create: `supabase/migrations/20260726000000_cosmetics_economy.sql`
- Test: `supabase/tests/cosmetics_schema_test.sql`

- [ ] **Step 1: Write the failing pgTAP test**

```sql
-- supabase/tests/cosmetics_schema_test.sql
begin;
select plan(12);

select has_table('public','user_cosmetics','user_cosmetics exists');
select has_table('public','cosmetic_catalog','cosmetic_catalog exists');
select has_table('public','noor_grants','noor_grants ledger exists');
select col_is_pk('public','user_cosmetics', array['user_id','item_type','item_id'],'inventory PK');
select col_is_pk('public','noor_grants', array['user_id','reason_key'],'ledger PK (idempotency)');
select has_column('public','user_profiles','noor_balance','noor_balance col');
select has_column('public','user_profiles','noor_total_earned','earned col');
select has_column('public','user_profiles','noor_total_spent','spent col');
select has_column('public','user_profiles','equipped_lantern_skin','equipped skin col');
select has_column('public','user_profiles','equipped_backdrop','equipped backdrop col');
select has_column('public','cosmetic_catalog','min_app_version','catalog min_app_version');
select has_column('public','cosmetic_catalog','iap_product_id','catalog iap product id');

select * from finish();
rollback;
```

- [ ] **Step 2: Run it, verify it fails**

Run: `psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_schema_test.sql`
Expected: FAIL — tables/columns do not exist yet.

- [ ] **Step 3: Write the schema migration**

```sql
-- supabase/migrations/20260726000000_cosmetics_economy.sql
-- Lantern cosmetics: server-authoritative economy (inventory, catalog, Noor).
-- All mutation via SECURITY DEFINER RPCs (Task 3-6); direct writes blocked (Task 2).

-- Currency + equipped-slot columns on the profile.
alter table public.user_profiles
  add column if not exists noor_balance      integer not null default 0 check (noor_balance >= 0),
  add column if not exists noor_total_earned integer not null default 0,
  add column if not exists noor_total_spent  integer not null default 0,
  add column if not exists equipped_lantern_skin text not null default 'classic_gold',
  add column if not exists equipped_backdrop     text not null default 'default';

-- The economic source of truth (visual defs live in client code, keyed by item_id).
create table if not exists public.cosmetic_catalog (
  item_type   text not null check (item_type in ('lantern_skin','backdrop')),
  item_id     text not null,
  noor_price        integer,           -- null = not Noor-purchasable
  iap_product_id    text,              -- null = not sold for money
  is_premium_exclusive boolean not null default false,
  is_seasonal          boolean not null default false,
  season_key           text,
  milestone_day        integer,        -- null = not a milestone unlock
  early_access_at      timestamptz,    -- premium early-access window start
  general_release_at   timestamptz,
  available_from       timestamptz,
  available_until      timestamptz,
  min_app_version      text not null default '0.0.0',
  grant_retention      text not null default 'permanent'
                       check (grant_retention in ('permanent','while_active')),
  sort        integer not null default 0,
  active      boolean not null default true,
  primary key (item_type, item_id)
);

-- Per-user owned cosmetics (mirrors card_collection ownership model).
create table if not exists public.user_cosmetics (
  user_id     uuid not null references auth.users(id) on delete cascade,
  item_type   text not null check (item_type in ('lantern_skin','backdrop')),
  item_id     text not null,
  acquired_via text not null check (acquired_via in
                ('default','noor','iap','milestone','seasonal','premium')),
  acquired_at timestamptz not null default now(),
  primary key (user_id, item_type, item_id)
);

-- Idempotency ledger: one row per (user, reason_key) → award_noor can never double-grant.
create table if not exists public.noor_grants (
  user_id    uuid not null references auth.users(id) on delete cascade,
  reason_key text not null,          -- e.g. 'daily:2026-07-26', 'milestone:30', 'quest:first_dua'
  amount     integer not null,
  created_at timestamptz not null default now(),
  primary key (user_id, reason_key)
);

create index if not exists idx_user_cosmetics_user on public.user_cosmetics(user_id);
```

- [ ] **Step 4: Apply + run test, verify pass**

Run: `psql "$SUPABASE_DB_URL" -f supabase/migrations/20260726000000_cosmetics_economy.sql && psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_schema_test.sql`
Expected: PASS (12/12).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260726000000_cosmetics_economy.sql supabase/tests/cosmetics_schema_test.sql
git commit -m "feat(cosmetics): economy schema — inventory, catalog, Noor ledger"
```

---

## Task 2: Guards + RLS — block direct client writes

**Files:**
- Modify: `supabase/migrations/20260726000000_cosmetics_economy.sql` (append)
- Test: `supabase/checks/backend_rls_audit.sql` conventions → add a focused test file `supabase/tests/cosmetics_guard_test.sql`

- [ ] **Step 1: Write the failing test** (an authenticated user CANNOT raise their own balance or insert inventory directly)

```sql
-- supabase/tests/cosmetics_guard_test.sql
begin;
select plan(3);
-- simulate an authenticated user (match the pattern in backend_rls_audit.sql)
set local role authenticated;
select set_config('request.jwt.claims', json_build_object('sub','00000000-0000-0000-0000-000000000001')::text, true);

select throws_ok(
  $$ update public.user_profiles set noor_balance = 999999 where id = '00000000-0000-0000-0000-000000000001' $$,
  NULL, 'direct noor_balance write is blocked');
select throws_ok(
  $$ insert into public.user_cosmetics(user_id,item_type,item_id,acquired_via)
     values ('00000000-0000-0000-0000-000000000001','lantern_skin','obsidian_gold','noor') $$,
  NULL, 'direct inventory insert is blocked');
select is_empty(
  $$ select 1 from public.noor_grants where user_id='00000000-0000-0000-0000-000000000001' $$,
  'no ledger rows creatable directly');

select * from finish();
rollback;
```

- [ ] **Step 2: Run it, verify it fails** (writes currently succeed)

Run: `psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_guard_test.sql`
Expected: FAIL — direct writes are not yet blocked.

- [ ] **Step 3: Append guard trigger + RLS to the migration**

```sql
-- (append to 20260726000000_cosmetics_economy.sql)

-- Guard: block direct client writes to the economy columns. RPCs run as
-- SECURITY DEFINER (owner), so they bypass this via a session GUC flag.
create or replace function public.cosmetics_guard() returns trigger
language plpgsql as $$
begin
  if current_setting('app.cosmetics_rpc', true) = 'on' then
    return NEW; -- called from a trusted RPC
  end if;
  if NEW.noor_balance is distinct from OLD.noor_balance
     or NEW.noor_total_earned is distinct from OLD.noor_total_earned
     or NEW.noor_total_spent  is distinct from OLD.noor_total_spent
     or NEW.equipped_lantern_skin is distinct from OLD.equipped_lantern_skin
     or NEW.equipped_backdrop     is distinct from OLD.equipped_backdrop then
    raise exception 'cosmetics columns are RPC-only';
  end if;
  return NEW;
end $$;

drop trigger if exists trg_cosmetics_guard on public.user_profiles;
create trigger trg_cosmetics_guard before update on public.user_profiles
  for each row execute function public.cosmetics_guard();

-- RLS: users may READ their own inventory; NO direct writes.
alter table public.user_cosmetics enable row level security;
alter table public.noor_grants     enable row level security;
create policy user_cosmetics_read on public.user_cosmetics
  for select using ((select auth.uid()) = user_id);
-- (no insert/update/delete policy → blocked for clients; RPCs are SECURITY DEFINER)

-- Catalog is publicly readable (anon catalog pattern, like public_catalog).
alter table public.cosmetic_catalog enable row level security;
create policy cosmetic_catalog_read on public.cosmetic_catalog
  for select using (true);
```

Note: each RPC in Tasks 3–6 must `perform set_config('app.cosmetics_rpc','on', true);` before touching guarded columns.

- [ ] **Step 4: Apply + run, verify pass**

Run: `psql "$SUPABASE_DB_URL" -f supabase/migrations/20260726000000_cosmetics_economy.sql && psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_guard_test.sql`
Expected: PASS (3/3).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260726000000_cosmetics_economy.sql supabase/tests/cosmetics_guard_test.sql
git commit -m "feat(cosmetics): guard trigger + RLS lock economy columns to RPCs"
```

---

## Task 3: `award_noor` — server-derived amount, idempotent (spec §13.1)

**Files:**
- Modify: `supabase/migrations/20260726000000_cosmetics_economy.sql` (append)
- Test: `supabase/tests/cosmetics_award_noor_test.sql`

- [ ] **Step 1: Write the failing test**

```sql
-- supabase/tests/cosmetics_award_noor_test.sql
begin;
select plan(4);
-- seed a user row in user_profiles for id ...0001 (match existing test fixtures)
-- ... (insert fixture as backend_rls_audit.sql does) ...

-- happy: a recognized reason grants the SERVER amount (not a client amount)
select is(
  (select public.award_noor('daily', 'daily:2026-07-26')),
  10, 'daily grants server-side 10');
select is(
  (select noor_balance from public.user_profiles where id='00000000-0000-0000-0000-000000000001'),
  10, 'balance credited');

-- idempotent: same reason_key twice → no double credit
select is(
  (select public.award_noor('daily', 'daily:2026-07-26')),
  0, 'duplicate reason_key grants 0');
select is(
  (select noor_balance from public.user_profiles where id='00000000-0000-0000-0000-000000000001'),
  10, 'balance unchanged on replay');

select * from finish();
rollback;
```

- [ ] **Step 2: Run it, verify it fails**

Run: `psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_award_noor_test.sql`
Expected: FAIL — `award_noor` undefined.

- [ ] **Step 3: Append the RPC**

```sql
-- (append) award_noor: amount is SERVER-DERIVED from p_reason (never client-supplied),
-- idempotent per (user, reason_key) via the ledger. Returns the amount actually granted.
create or replace function public.award_noor(p_reason text, p_reason_key text)
returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_amount integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;

  -- Server-owned reason → amount table. Add rows here, never trust the client.
  v_amount := case
    when p_reason = 'daily'          then 10
    when p_reason = 'milestone:7'    then 40
    when p_reason = 'milestone:14'   then 75
    when p_reason = 'milestone:30'   then 150
    when p_reason = 'milestone:60'   then 250
    when p_reason = 'milestone:90'   then 400  -- was 'milestone:100' as planned;
                                               -- corrected by 20260726000800 to
                                               -- match streakMilestones (90).
    when p_reason = 'quest'          then 15
    else null end;
  if v_amount is null then raise exception 'unknown noor reason: %', p_reason; end if;

  -- Idempotency: insert ledger row; if it already exists, grant nothing.
  insert into public.noor_grants(user_id, reason_key, amount)
    values (v_uid, p_reason_key, v_amount)
    on conflict (user_id, reason_key) do nothing;
  if not found then return 0; end if;

  perform set_config('app.cosmetics_rpc','on', true);
  update public.user_profiles
     set noor_balance = noor_balance + v_amount,
         noor_total_earned = noor_total_earned + v_amount
   where id = v_uid;
  return v_amount;
end $$;

revoke execute on function public.award_noor(text,text) from public, anon;
grant  execute on function public.award_noor(text,text) to authenticated;
```

- [ ] **Step 4: Apply + run, verify pass**

Run: `psql "$SUPABASE_DB_URL" -f supabase/migrations/20260726000000_cosmetics_economy.sql && psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_award_noor_test.sql`
Expected: PASS (4/4).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260726000000_cosmetics_economy.sql supabase/tests/cosmetics_award_noor_test.sql
git commit -m "feat(cosmetics): award_noor — server-derived amount, idempotent ledger"
```

---

## Task 4: `unlock_cosmetic` — atomic deduct+insert (spec §13.2)

**Files:**
- Modify: `supabase/migrations/20260726000000_cosmetics_economy.sql` (append)
- Test: `supabase/tests/cosmetics_unlock_equip_test.sql`

- [ ] **Step 1: Write the failing test** (happy unlock; insufficient funds rejected; double-unlock charges once)

```sql
-- supabase/tests/cosmetics_unlock_equip_test.sql (unlock portion)
begin;
select plan(5);
-- seed user with noor_balance = 220 and a catalog row obsidian_gold @ 200 (active)
insert into public.cosmetic_catalog(item_type,item_id,noor_price,active)
  values ('lantern_skin','obsidian_gold',200,true) on conflict do nothing;
-- ... seed profile balance 220 via a direct owner update in the test setup ...

select is((select public.unlock_cosmetic('lantern_skin','obsidian_gold')), true, 'unlock succeeds');
select is((select noor_balance from public.user_profiles where id='00000000-0000-0000-0000-000000000001'),
          20, 'balance deducted once');
select isnt_empty($$ select 1 from public.user_cosmetics
   where user_id='00000000-0000-0000-0000-000000000001' and item_id='obsidian_gold' $$, 'inventory row created');
-- double unlock: already owned → no second charge
select is((select public.unlock_cosmetic('lantern_skin','obsidian_gold')), true, 'idempotent re-unlock ok');
select is((select noor_balance from public.user_profiles where id='00000000-0000-0000-0000-000000000001'),
          20, 'no second charge');
select * from finish();
rollback;
```

- [ ] **Step 2: Run it, verify it fails**

Run: `psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_unlock_equip_test.sql`
Expected: FAIL — `unlock_cosmetic` undefined.

- [ ] **Step 3: Append the RPC** (row-lock the profile; conditional deduct; already-owned short-circuit)

```sql
-- (append) unlock_cosmetic: atomic. Locks the profile row, verifies price from the
-- catalog (never the client), deducts and inserts inventory in one transaction.
create or replace function public.unlock_cosmetic(p_item_type text, p_item_id text)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_price integer;
  v_balance integer;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;

  -- Already owned → success, no charge (idempotent).
  if exists (select 1 from public.user_cosmetics
             where user_id=v_uid and item_type=p_item_type and item_id=p_item_id) then
    return true;
  end if;

  select noor_price into v_price from public.cosmetic_catalog
   where item_type=p_item_type and item_id=p_item_id and active;
  if v_price is null then raise exception 'item not Noor-purchasable or inactive'; end if;

  -- Lock the profile row so concurrent unlocks serialize.
  select noor_balance into v_balance from public.user_profiles where id=v_uid for update;
  if v_balance < v_price then raise exception 'insufficient noor'; end if;

  perform set_config('app.cosmetics_rpc','on', true);
  update public.user_profiles
     set noor_balance = noor_balance - v_price,
         noor_total_spent = noor_total_spent + v_price
   where id=v_uid;
  insert into public.user_cosmetics(user_id,item_type,item_id,acquired_via)
     values (v_uid,p_item_type,p_item_id,'noor')
     on conflict (user_id,item_type,item_id) do nothing;
  return true;
end $$;

revoke execute on function public.unlock_cosmetic(text,text) from public, anon;
grant  execute on function public.unlock_cosmetic(text,text) to authenticated;
```

- [ ] **Step 4: Apply + run, verify pass**

Run: same apply+test command as Task 3 against `cosmetics_unlock_equip_test.sql`.
Expected: PASS (5/5).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260726000000_cosmetics_economy.sql supabase/tests/cosmetics_unlock_equip_test.sql
git commit -m "feat(cosmetics): unlock_cosmetic — atomic row-locked deduct + insert"
```

---

## Task 5: `equip_cosmetic` — ownership-checked slot set

**Files:**
- Modify: `supabase/migrations/20260726000000_cosmetics_economy.sql` (append)
- Test: append to `supabase/tests/cosmetics_unlock_equip_test.sql`

- [ ] **Step 1: Add failing test cases** (equip owned item ok; equipping a not-owned item throws)

```sql
-- append two cases (bump plan() count accordingly):
select is((select public.equip_cosmetic('lantern_skin','obsidian_gold')), true, 'equip owned ok');
select is((select equipped_lantern_skin from public.user_profiles where id='00000000-0000-0000-0000-000000000001'),
          'obsidian_gold', 'equipped slot updated');
select throws_ok($$ select public.equip_cosmetic('lantern_skin','crystal_star') $$,
          NULL, 'equipping a not-owned skin throws');
```

- [ ] **Step 2: Run, verify fail**

Run: `psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_unlock_equip_test.sql`
Expected: FAIL — `equip_cosmetic` undefined.

- [ ] **Step 3: Append the RPC**

```sql
-- (append) equip_cosmetic: verify ownership, set the equipped slot for that type.
create or replace function public.equip_cosmetic(p_item_type text, p_item_id text)
returns boolean
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if not exists (select 1 from public.user_cosmetics
                 where user_id=v_uid and item_type=p_item_type and item_id=p_item_id) then
    raise exception 'cannot equip unowned item';
  end if;
  perform set_config('app.cosmetics_rpc','on', true);
  if p_item_type = 'lantern_skin' then
    update public.user_profiles set equipped_lantern_skin=p_item_id where id=v_uid;
  elsif p_item_type = 'backdrop' then
    update public.user_profiles set equipped_backdrop=p_item_id where id=v_uid;
  else raise exception 'unknown item_type %', p_item_type; end if;
  return true;
end $$;

revoke execute on function public.equip_cosmetic(text,text) from public, anon;
grant  execute on function public.equip_cosmetic(text,text) to authenticated;
```

- [ ] **Step 4: Run, verify pass** — Expected: all cases PASS.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260726000000_cosmetics_economy.sql supabase/tests/cosmetics_unlock_equip_test.sql
git commit -m "feat(cosmetics): equip_cosmetic — ownership-checked slot"
```

---

## Task 6: Fix `claim_streak_milestone` — verify recognized AND reached (spec §13.3)

**Files:**
- Create: `supabase/migrations/20260726000200_fix_claim_streak_milestone.sql`
- Test: `supabase/tests/cosmetics_milestone_fix_test.sql`

- [ ] **Step 1: Write the failing test** (arbitrary/unreached day is rejected)

```sql
-- supabase/tests/cosmetics_milestone_fix_test.sql
begin;
select plan(3);
-- seed a user whose current streak is 7 (use the real <streak_table>/<current_streak_col>)
select lives_ok($$ select public.claim_streak_milestone(7) $$, 'reached recognized day ok');
select throws_ok($$ select public.claim_streak_milestone(999) $$, NULL, 'unrecognized day rejected');
select throws_ok($$ select public.claim_streak_milestone(30) $$, NULL, 'unreached day rejected');
select * from finish();
rollback;
```

- [ ] **Step 2: Run, verify fail** (current RPC accepts any day)

Run: `psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_milestone_fix_test.sql`
Expected: FAIL — day 999 and unreached 30 currently succeed.

- [ ] **Step 3: Redefine the RPC with both checks** (preserve its existing grant logic — copy from the read of `20260719000000_streaks_defense.sql:201`, add the two guards)

```sql
-- supabase/migrations/20260726000200_fix_claim_streak_milestone.sql
create or replace function public.claim_streak_milestone(p_day int)
returns <existing_return_type>  -- match the original
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_streak int;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  -- Guard 1: recognized milestone day only.
  -- NOTE: as planned this read 100; the shipped guard uses 90 to match
  -- streakMilestones (migration 20260726000800_align_milestone_day_90.sql).
  if p_day not in (7,14,30,60,90,180,365) then
    raise exception 'unrecognized milestone day %', p_day;
  end if;
  -- Guard 2: user must have actually reached it.
  select <current_streak_col> into v_streak from public.<streak_table> where user_id=v_uid;
  if coalesce(v_streak,0) < p_day then
    raise exception 'milestone % not reached (streak=%)', p_day, coalesce(v_streak,0);
  end if;
  -- ... original grant/claim body here (idempotent claim), unchanged ...
end $$;
revoke execute on function public.claim_streak_milestone(int) from public, anon;
grant  execute on function public.claim_streak_milestone(int) to authenticated;
```

- [ ] **Step 4: Run, verify pass** — Expected: 3/3 PASS.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260726000200_fix_claim_streak_milestone.sql supabase/tests/cosmetics_milestone_fix_test.sql
git commit -m "fix(streaks): claim_streak_milestone verifies day is recognized AND reached"
```

---

## Task 7: Extend `sync_all_user_data()` — noor / cosmetics / equipped sections

**Files:**
- Modify: the `sync_all_user_data()` body (redefine via `CREATE OR REPLACE` inside a new migration `20260726000300_sync_cosmetics_sections.sql`, preserving ALL existing sections).
- Test: `supabase/tests/cosmetics_sync_test.sql`

- [ ] **Step 1: Write the failing test** (the sync payload includes the three new keys)

```sql
-- supabase/tests/cosmetics_sync_test.sql
begin;
select plan(3);
-- seed: user with noor_balance 10, one owned skin, equipped_lantern_skin='obsidian_gold'
select is( (public.sync_all_user_data() -> 'noor' ->> 'balance')::int, 10, 'sync returns noor.balance');
select is( (public.sync_all_user_data() -> 'equipped' ->> 'lantern_skin'), 'obsidian_gold', 'sync returns equipped skin');
select is( jsonb_array_length(public.sync_all_user_data() -> 'cosmetics'), 1, 'sync returns owned cosmetics list');
select * from finish();
rollback;
```

- [ ] **Step 2: Run, verify fail** (keys absent)

Run: `psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_sync_test.sql`
Expected: FAIL — `noor`/`equipped`/`cosmetics` keys missing.

- [ ] **Step 3: Redefine `sync_all_user_data()` preserving existing sections + adding three**

Copy the entire existing function body (from the Read step), and before the final return, add the three sections to the assembled JSON object. Do NOT drop or rename any existing key.

```sql
-- supabase/migrations/20260726000300_sync_cosmetics_sections.sql
create or replace function public.sync_all_user_data(/* existing args */)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_result jsonb;  -- built exactly as today
begin
  -- ... ALL existing section-building code, verbatim ...

  v_result := v_result
    || jsonb_build_object('noor', (
         select jsonb_build_object(
           'balance', noor_balance,
           'total_earned', noor_total_earned,
           'total_spent', noor_total_spent)
         from public.user_profiles where id=v_uid))
    || jsonb_build_object('equipped', (
         select jsonb_build_object(
           'lantern_skin', equipped_lantern_skin,
           'backdrop', equipped_backdrop)
         from public.user_profiles where id=v_uid))
    || jsonb_build_object('cosmetics', coalesce((
         select jsonb_agg(jsonb_build_object(
           'item_type', item_type, 'item_id', item_id, 'acquired_via', acquired_via))
         from public.user_cosmetics where user_id=v_uid), '[]'::jsonb));

  return v_result;
end $$;
```

- [ ] **Step 4: Run, verify pass** — Expected: 3/3 PASS. Also re-run the existing sync test suite to prove no existing section regressed:

Run: `psql "$SUPABASE_DB_URL" -f supabase/checks/backend_rls_audit.sql` (and any existing sync test) — Expected: still PASS.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260726000300_sync_cosmetics_sections.sql supabase/tests/cosmetics_sync_test.sql
git commit -m "feat(cosmetics): sync_all_user_data returns noor/cosmetics/equipped"
```

---

## Task 8: Seed the launch catalog

**Files:**
- Create: `supabase/migrations/20260726000100_seed_cosmetic_catalog.sql`

- [ ] **Step 1: Write the seed** (item_ids MUST match the client `LanternSkin.id` / `Backdrop.id` values in `lib/features/streaks/models/lantern_skin.dart` + `backdrop.dart`)

```sql
-- supabase/migrations/20260726000100_seed_cosmetic_catalog.sql
insert into public.cosmetic_catalog(item_type,item_id,noor_price,milestone_day,is_premium_exclusive,is_seasonal,season_key,iap_product_id,sort) values
  ('lantern_skin','classic_gold',    0,    null, false, false, null, null, 0),   -- default, auto-owned
  ('lantern_skin','moonlit_silver',  120,  null, false, false, null, null, 1),
  ('lantern_skin','emerald_jade',    120,  7,    false, false, null, null, 2),   -- also a 7d milestone unlock
  ('lantern_skin','rose_quartz',     120,  null, false, false, null, null, 3),
  ('lantern_skin','obsidian_gold',   200,  30,   false, false, null, 'sakina.skin.obsidian', 4),
  ('lantern_skin','masjid_brass',    300,  null, false, false, null, 'sakina.skin.masjid', 5),
  ('lantern_skin','crystal_star',    300,  null, false, false, null, 'sakina.skin.crystal', 6),
  ('lantern_skin','ramadan_royal',   null, null, true,  true,  'ramadan', null, 7), -- premium/seasonal
  ('backdrop','default',             0,    null, false, false, null, null, 0),
  ('backdrop','laylat_night',        150,  14,   false, false, null, null, 1),
  ('backdrop','emerald_sanctuary',   150,  null, false, false, null, null, 2)
on conflict (item_type,item_id) do nothing;
```

- [ ] **Step 2: Apply, verify rows**

Run: `psql "$SUPABASE_DB_URL" -f supabase/migrations/20260726000100_seed_cosmetic_catalog.sql && psql "$SUPABASE_DB_URL" -c "select count(*) from public.cosmetic_catalog;"`
Expected: 11 rows.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260726000100_seed_cosmetic_catalog.sql
git commit -m "feat(cosmetics): seed launch catalog (8 skins, 2 backdrops + default)"
```

---

## Self-review (done)

- **Spec coverage:** §4 data model → Tasks 1,8. §13.1 award_noor idempotency → Task 3. §13.2 unlock atomicity → Task 4. §13.3 milestone fix → Task 6. §13.8 catalog fields + RLS → Tasks 1,2,8. Sync extension (§4) → Task 7. Equip → Task 5.
- **Not in this plan (own plans, spec §15):** IAP grant/refund + premium/entitlement reconciliation (Lane B, §13.4–7), render + arched-window + backdrop perf (Lane C, §13.10–12, T13), Companion/wardrobe/share/naming UI (Lane D, §12), widget payload (Lane E, §13.9).
- **Type consistency:** `item_type ∈ {lantern_skin,backdrop}`, `acquired_via` enum, and catalog `item_id`s match the client model ids (`classic_gold`, `obsidian_gold`, `laylat_night`, …) — Task 8 ids must equal `LanternSkin.id`/`Backdrop.id`. The `app.cosmetics_rpc` GUC flag is set in every RPC that writes guarded columns (Tasks 3,4,5,7-not-needed-read-only).
- **Placeholders:** the only intentional `<...>` are the three real names the engineer must substitute after the Read step (`<streak_table>`, `<current_streak_col>`, `<existing_return_type>`) — flagged explicitly, not TODOs.

## Follow-on plans (write when their lane starts)

- **Plan 2 — Lane B (client services):** premium-definition unification, non-consumable IAP grant + RevenueCat refund/restore reconciliation, Noor/cosmetics service layer, sync hydration in `user_data_batch_sync_service.dart`, entitlement-period grant reconciliation. Depends on this plan's RPC contracts.
- **Plan 3 — Lane C (render):** productionize skin/backdrop painters, arch-top the glass window (remove the additive-cap seam), backdrop `RepaintBoundary` + low-end perf test, fix `Backdrop.none`, golden set.
- **Plan 4 — Lane D (UI):** Companion screen, wardrobe (browse/preview/equip/unlock/buy), share hook, name-your-lantern. Depends on B + C.
- **Plan 5 — Lane E (widget):** skin field in the App-Group payload, Swift lookup by equipped skin, frame generator loop at 360px, refresh-on-equip. Depends on C (PNGs) + B (equip field).
