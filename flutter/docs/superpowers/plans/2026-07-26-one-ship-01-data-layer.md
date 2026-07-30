# One Ship 01 — W1 Data Layer

**Status: APPROVED (founder, 2026-07-26 — all three open items decided; build in progress)**
**Date:** 2026-07-26
**Branch/worktree:** `feat/reel-first-one-ship` at `/Users/appleuser/CS Work/Repos/sakina-reel-first` (based on master `25277ce`)
**Parents:** `2026-07-23-conversion-refactor-changes-and-implementation.md` (Phase 1 → W1) · plan of record `2026-07-03-reel-first-conversion-refactor.md` (§V6.8, §V6.9, §V6.10)

W1 is the migrations-first workstream of the One Ship. Everything here is **additive and invisible to shipped clients** — safe to apply to prod before the app release (exempt from one-change-at-a-time), with ONE deliberate exception called out in "Cohort activation" below.

**Scope:** `user_name_queue` + RPCs · `user_profiles` new columns + weekly-pool server authority · timezone-input hardening · `sync_all_user_data` extension · app_config dials · staged (NOT applied) softener-wave scripts · the quest local-vs-UTC client fix (decision 0.1.4).
**Non-goals:** onboarding UI (W2), daily-loop seam (W3), gating/paywall wiring (W5), analytics events (W6).

---

## Design principle (from review): no economy math on client-asserted inputs

Both review blockers reduced to one flaw in the draft: limit/pacing math derived from client-writable values (`timezone`, a client-written cohort) with equality/optional-write semantics. The corrected design:

1. **Cohort is server-assigned** (in `handle_new_user`), never client-written.
2. **All resets/gates are monotonic and wall-clock-anchored** — a timezone change can shift *rendering*, never manufacture a reset or an extra unseal.
3. **Timezone is validated at write** and defensively coalesced at read.

---

## Verified baseline (2026-07-26)

- Latest `sync_all_user_data` in repo = `20260722000000_streak_freeze_premium_tier.sql:364` (NOT the 20260616 copy). **Prod verified matching** via marker probe (`streak_freeze_count` ✓, `tour_step_index` ✓, no `noor_*` keys).
- Latest freemium-guard body = `20260616204630_reverse_trial_backend.sql:92+`; trigger is plain `BEFORE UPDATE ... FOR EACH ROW` with no column list → CREATE OR REPLACE preserves the binding and NEW-mutation is legal (review-verified).
- Cosmetics economy (`20260726000000_cosmetics_economy.sql`) already in master → new files timestamp `202607271xxxxx+`; re-check `list_migrations` + `ls supabase/migrations | tail` immediately before finalizing names (lantern session is active on the same DB).
- `user_card_collection.discovered_at` already rides sync → **`met_at` = derive, no new column.**
- Name ids: queue references **`collectible_names(id)`** (int pk, drives cards/decks; `names_of_allah` is the other int-pk catalog — not this one). Add a real FK.
- RLS convention: `to authenticated` + initplan `(select auth.uid())`. **Grants convention (review F/eng-4): functions default-grant EXECUTE to PUBLIC — every new RPC gets `revoke ... from public, anon; grant ... to authenticated;`** (two past migrations exist solely to clean up this mistake).
- SQL test convention: `pg_temp.expect` + `pg_temp.set_auth` harness (`ai_bypass_rpc_test.sql:58-100`), rolled back.
- CI safety of `supabase/staged/`: verified — CI applies only `supabase/migrations/` and `run_sql_tests.sh` globs `supabase/tests` at maxdepth 1; nothing picks up `staged/`.

---

## Migration A — timezone hardening (prerequisite for everything below)

`user_notification_preferences.timezone` is client-writable free text with no validation; the notification scheduler and (now) economy RPCs read it (review F5: garbage tz makes `at time zone tz` raise → self-DoS; hostile tz feeds F1/F3).

1. **Validate on write:** BEFORE INSERT/UPDATE trigger on `user_notification_preferences`: if `new.timezone` is non-empty and not in `pg_timezone_names`, raise (loud failure surfaces client bugs; `FlutterTimezone` emits IANA names, so honest clients never hit it).
2. **Coalesce on read:** shared helper `public.safe_user_tz(p_user uuid) returns text` — returns the stored tz if valid, else `'UTC'` (defends rows written before the trigger). All RPCs below use it.

---

## Migration B — `user_name_queue`

```sql
create table public.user_name_queue (
  user_id     uuid not null references auth.users(id) on delete cascade,
  position    int  not null check (position between 1 and 7),
  name_id     int  not null references public.collectible_names(id),
  unsealed_at timestamptz,
  created_at  timestamptz not null default now(),
  primary key (user_id, position),   -- also serves the unseal query's user_id prefix
  unique (user_id, name_id)
);
alter table public.user_name_queue enable row level security;
create policy "Users can view own name queue" on public.user_name_queue
  for select to authenticated using ((select auth.uid()) = user_id);
-- deliberately NO insert/update/delete policies: writes are RPC-only.
```

Anon-session support cut per §V6.8.E.

### RPC `seed_name_queue(p_name_ids int[])` — SECURITY DEFINER

- Caller = `auth.uid()` (no `p_user_id` — not cross-user callable).
- Validation: `coalesce(cardinality(p_name_ids), 0) between 2 and 7` (eng-6: bare `array_length` is NULL on `{}` and `NULL between ...` never fires); `count(distinct unnest) = cardinality` (dup check); FK catches junk ids.
- **Refuse re-seed:** `if exists (select 1 from user_name_queue where user_id = v_uid) then raise`. Concurrent double-seed is PK-protected (second txn aborts on `(user_id, position)`) — do NOT soften with `on conflict do nothing` (would silently half-reseed; review-verified safe as a hard abort).
- Inserts positions `1..N`; position 1 `unsealed_at = now()` (Name #1 met at the onboarding reveal); ≥2 sealed.
- **Accepted residual risk (review F4, founder-visible):** the client chooses WHICH Names and their order. This matches the status quo (`discoverName` already client-writes `user_card_collection`), and Name choice carries no tier value — tier comes from the gacha roll, never the queue. Binding constraint on W2/W3: **unseal must never directly grant tokens/XP/tier** (card award goes through the existing gacha/economy path); the W3 review re-checks this.
- `set search_path = public, pg_temp`; grants per convention.

### RPC `unseal_next_name()` — SECURITY DEFINER

Server is the unseal-timing authority; timezone affects rendering, not eligibility:

1. `select ... for update` on the caller's queue rows **first** (lock before the idempotency read — explicit, per review).
2. `tz := safe_user_tz(v_uid)`; `today_local := (now() at time zone tz)::date`.
3. If a row has `(unsealed_at at time zone tz)::date = today_local` → return it (idempotent per local day; D1's first call unseals position 2 because position 1 was stamped on signup day).
4. **Wall-clock floor (review F3 — kills the tz-walk drain):** if `max(unsealed_at) > now() - interval '20 hours'` → return the newest unsealed row, unseal nothing. No timezone choice can beat a 20h monotonic server-clock gap; honest users are unaffected (local midnights are ≥20h apart except DST edges, which the local-day check absorbs).
5. Else unseal `min(position) where unsealed_at is null`, return it (empty = exhausted; client handles).

W3 note: the stated-feeling override never mutates the queue; per-local-day idempotency + the 20h floor make late-day calls safe.

---

## Migration C — `user_profiles` columns, cohort assignment, guard, pool RPC, dials

### New columns

```sql
alter table public.user_profiles
  add column if not exists acquisition_promise     jsonb
    check (acquisition_promise is null or acquisition_promise ? 'contract'),
  add column if not exists first_problem_text      text,
  add column if not exists onboarding_flow         text check (onboarding_flow in ('reel_v1','legacy')),
  add column if not exists free_tier_cohort        text check (free_tier_cohort in ('reel_v1','legacy')),
  add column if not exists weekly_pool_used        int  not null default 0 check (weekly_pool_used >= 0),
  add column if not exists weekly_pool_week_start  date,
  add column if not exists weekly_pool_reset_at    timestamptz,
  add column if not exists softener_notice_ends_at timestamptz;
```

- `acquisition_promise` — `{reel_id?, hook_type, contract, problem_category?}` (§V6.8). Client-written during onboarding.
- `first_problem_text` — free text, same write path; same privacy posture as `user_reflections.user_text`.
- `onboarding_flow` — which experience the user went through (analytics + tour suppression key). Client-written; low-stakes if tampered (you get the legacy tour, congratulations).
- `free_tier_cohort` — which LIMITS apply. **Server-assigned only (review F2 blocker — see below); all client writes blocked.** NULL = account predates cohort activation = legacy limits, legitimately (with server assignment, NULL can no longer mean "tampered client omitted it").
- `weekly_pool_*` — server mirror of the 3-combined weekly pool (Reflect + Build-a-Dua), RPC-only.
- `softener_notice_ends_at` — stamped only by the staged wave.

### Cohort assignment — server-derived (fixes review F2)

Extend `handle_new_user` (CREATE OR REPLACE — **pre-flight prod diff of THIS function too**): read `app_config.new_signup_cohort` (seeded `'legacy'` now); stamp `free_tier_cohort` with it and, when it resolves `'reel_v1'`, set `warmup_reflect_remaining = 3, warmup_built_dua_remaining = 3` at insert (unconditional, not contingent on any client write — replaces the draft's fragile NULL→'reel_v1' clamp).

**Cohort activation (runbook, T0 release day):** flip `new_signup_cohort` → `'reel_v1'`. This is why it's a separate key from the kill switch seed: stamping reel_v1 warmups (3 vs 10) on signups **before** T0 would silently change live old-app users — a one-change-at-a-time violation the draft missed. If the kill switch is ever flipped post-T0, flip `new_signup_cohort` back to `'legacy'` in the same action (paired runbook item).

### Guard-trigger extension

CREATE OR REPLACE `guard_user_profiles_freemium_fields()` from the **latest** body (`20260616204630:92`, pre-flight prod diff first):

- `free_tier_cohort`, `weekly_pool_used`, `weekly_pool_week_start`, `weekly_pool_reset_at`, `softener_notice_ends_at`: ANY non-exempt-role change raises.
- `acquisition_promise`, `onboarding_flow`: **freeze-after-completion** (review eng-2 — the draft's naive write-once would have silently bricked the *second* onboarding persist, since `persistOnboardingToSupabase` runs 2-4× per signup and errors are swallowed at `onboarding_provider.dart:464`): raise only when `old.onboarding_completed = true AND new.x is distinct from old.x`. Re-sends of identical values and back-nav edits during onboarding pass; post-onboarding rewrites raise. Binding W2 note: include these keys in the final persist.

### RPC `consume_weekly_allowance(p_feature text)` — SECURITY DEFINER

- `p_feature in ('reflect','built_dua')` else raise (`discover_name` is never pooled — 1/day forever).
- Row-lock the profile row; `tz := safe_user_tz(...)`; `week_start_local := date_trunc('week', (now() at time zone tz))::date` (ISO Monday — verified).
- **Reset condition (review F1 blocker — kills the tz ping-pong):** reset (`used := 0`, stamp `week_start`, `weekly_pool_reset_at := now()`) only when BOTH:
  - `weekly_pool_week_start is null OR week_start_local > weekly_pool_week_start` (monotonic — hopping "back" across the dateline can never be `>`), AND
  - `weekly_pool_reset_at is null OR now() - weekly_pool_reset_at >= interval '6 days'` (wall-clock anchor — at most one reset per real ~week regardless of any tz choreography).
  Honest cost: an eastward traveler's reset can lag by up to a day; acceptable.
- `pool_size := coalesce((select (value::text)::int from app_config where key = 'weekly_pool_size'), 3)` (eng-8: `(value::text)::int` is the repo's pinned cast form — keep consistent).
- `used >= pool_size` → `{allowed:false, remaining:0, week_start}`; else increment, return `{allowed:true, remaining, week_start}`.
- No refund path in v1 (consumed-on-error is eaten, matching warmup posture).

### app_config seeds

```sql
insert into public.app_config (key, value) values
  ('weekly_pool_size', '3'),
  ('warmup_reflect_size', '3'),
  ('warmup_built_dua_size', '3'),
  ('new_signup_cohort', '"legacy"'),
  ('reel_first_onboarding_enabled', 'true')
on conflict (key) do nothing;
```

`reel_first_onboarding_enabled` is THE kill switch (§V6.9) — client-readable is fine (boolean flag, nothing sensitive); server paths never trust a client-asserted read of it (the pool RPC and `handle_new_user` re-read config server-side).

---

## Migration D — `sync_all_user_data` extension

CREATE OR REPLACE from the `20260722000000:364` body. Add to the `profile` section AND its no-profile-row fallback object (review F7 nit): `acquisition_promise, first_problem_text, onboarding_flow, free_tier_cohort, weekly_pool_used, weekly_pool_week_start` (`first_problem_text` added per eng-9 — W3's AI context needs it cross-device). Shipped clients ignore unknown keys (parser verified) — backward-compatible.

**Mandatory pre-flight (standing rule):** `select pg_get_functiondef('public.sync_all_user_data'::regproc)` on prod, diff against repo, immediately before applying. Same for `guard_user_profiles_freemium_fields` and `handle_new_user`. If prod drifted (lantern session), base on PROD and reconcile the repo with a catch-up migration. Never CREATE OR REPLACE from a stale copy.

---

## Staged (NOT applied): softener wave — `supabase/staged/`

Outside `migrations/` (CI-verified safe). Moves into migrations/ only after the T0+6wk keep decision (§V6.10; complete before Ramadan).

1. `softener_1_notice.sql` — users with `free_tier_cohort is distinct from 'reel_v1'`: `softener_notice_ends_at = now() + interval '30 days'`. (Premium users stamped too — harmless.)
2. `softener_2_flip.sql` — ≥30d later, where notice ended: `free_tier_cohort = 'reel_v1'`, clamp `warmup_*_remaining` to `least(current, 3)`, zero pool columns. Bypass-subsystem deletion is a separate post-wave PR.

Both scripts **assert the running role at the top** (`current_user in ('postgres','service_role','supabase_admin')` else raise — review F8: the guard would half-block them under any other role; fail loudly, not partially). README records trigger condition, Ramadan deadline, and that notice push/UI is Phase 3.

---

## Client fix — quest local-vs-UTC bug (decision 0.1.4)

`quests_provider.dart`: rotation is local-time, persistence is UTC → west-of-UTC users' quest IDs don't match their `period_start` rows near midnight.

**Fix: unify EVERYTHING on `debugQuestBoundariesClock()` (UTC).** Review eng-1 found the draft's three label builders were not enough — the rotation *seeds* are also local, and a labels-only fix ships a new variant of the same bug (pool index flips mid-UTC-day → 6 daily completions/day). Full call-site list:

- `_todayLabel` :526, `_weekLabel` :531, `_monthLabel` :537 (labels)
- `_dayOfYear` :542, `_isoWeekNumber` :547, inline `DateTime.now().month` :723-727 (pool-selection seeds)

Why UTC, not per-user local: the 0.1.4 audit pinned muhasabah/rewards/usage as uniformly UTC; local-tz quests would re-key every user's active quests and need tz plumbed into quest IDs. UTC unification is small and zero-migration. Side effect verified beneficial: `_recordCollectionVisitDay` (:1288) compares `_todayLabel` dates against UTC `_weekStart` (:1306) — currently mismatched, fixed by this change. One-time re-key blip for west-of-UTC users on update day — same class the bug causes daily; note in PR.

Regression tests: fixed clock at `2026-07-25T03:00Z` (11pm ET July 24) → label date == `_periodStartFor(daily)` date AND selected pool index stable across the local-midnight window; weekly across Sunday/Monday; monthly across the 1st.

---

## Tests

**SQL — `supabase/tests/user_name_queue_test.sql` + extend the freemium test** (expect/set_auth harness, rolled back):
1. RLS: user A cannot select B's queue; anon cannot select; direct INSERT/UPDATE/DELETE as authenticated fails.
2. RPC grants: EXECUTE denied to anon (matches the revoke-from-public,anon convention).
3. `seed_name_queue`: happy path (pos 1 unsealed, rest sealed); empty array raises; dups raise; junk id raises (FK); re-seed raises.
4. `unseal_next_name`: same-local-day idempotent; next local day unseals next; **20h floor: tz flip to UTC+14 immediately after an unseal returns the same row, no new unseal**; exhausted returns empty.
5. Weekly pool: 3 then `allowed:false`; Monday-local rollover resets; **tz ping-pong across the dateline does NOT reset (monotonic + 6d anchor)**; `discover_name` arg raises.
6. Guard: client UPDATE of any RPC-only column raises; `free_tier_cohort` client write raises even from NULL; `acquisition_promise` re-send of same value passes, change during onboarding passes, change after `onboarding_completed=true` raises.
7. `handle_new_user` + `new_signup_cohort='reel_v1'`: new row gets cohort + warmups 3/3; with `'legacy'`: cohort legacy, warmups 10/10.
8. Timezone trigger: invalid tz string raises; `safe_user_tz` falls back to UTC for a pre-trigger junk row.
9. app_config seeds present.

**Dart:** quest label/period/pool-index alignment tests (above). Full `flutter test` + `flutter analyze` (known flaky baseline: `purchase_service_premium_started`, `find_duas` eval).

---

## Order of work & review gates

1. Migration A (tz hardening) → tests.
2. Migration B (queue + RPCs) → tests → agent review.
3. Migration C (columns/cohort/guard/pool/dials) → tests → adversarial "can I self-grant?" pass (must re-attack F1/F2/F3 fixes specifically).
4. Migration D (sync) → prod pre-flight diffs.
5. Staged softener scripts + README (review-only artifact).
6. Quest fix + Dart tests.
7. Apply A→D to prod **via migration files** (`db push` or MCP `apply_migration` with identical file content — never MCP-only SQL with no repo file), then `get_advisors` pass.
8. PR into master.

**Coordination hazard:** lantern-cosmetics session shares the prod DB and may redefine shared functions. Before EVERY apply: `list_migrations` + drift probes on `sync_all_user_data`, `guard_user_profiles_freemium_fields`, `handle_new_user`.

## Review record — round 2, post-build Opus /review (2026-07-26)

Full-branch review (SQL + quests + tests + drift), all findings fixed same day:
**P1-a** `sync_all_user_data` collision with lantern's unmerged `20260726000300`
(whichever CREATE OR REPLACE runs last clobbers the other's keys; CI vs prod
order differs) → migrations renumbered `20260727*` (always last in version
order) + Migration D now carries the **union body** (W1 keys + lantern's
noor/equipped/cosmetics sections verbatim) + sync-payload tripwire tests
(34/35). ⚠️ OPEN COORDINATION ITEM: when lantern PR #61 merges, its
`20260726000300` must be dropped or re-emitted as the same union, or applying
it to prod after W1 strips the W1 keys there. **P1-b** weekly quest *seed*
rolled every Tuesday (old ceil formula) while label/period rolled Monday →
`_isoWeekNumber` now derives from `_weekStart()`; Monday-roll test added.
**P2** tz trigger now validates only actual timezone changes (poisoned legacy
row can't brick the cron batch); INSERT-path guard trigger for server-owned
profile columns; `onboarding_completed` one-way latch (freeze was bypassable
via un-complete); UTC `Z`-parse for collection-visit + discovery date strings
(east-of-UTC undercount) + UTC writer in card_collection_service; stale-pool
`_reloadIfStale()` in `_tryComplete`/`_updateProgress` (UTC midnight lands in
US peak hours); `period_start` fallback UTC-ified; vacuous clock test replaced
with literal pins; deterministic 20h-floor test (computed near-midnight zone);
`safe_user_tz` invalid-stored-value test; sync-payload key tests. **P3**
rejected pool path no longer writes; accepted-bounds comment (~+14% worst-case
weekly allowance, once-ever init hop); `create table if not exists`/policy
hygiene; UTC Z-suffixed event logs; monthly-seed seam+test; anon
select/execute tests; NULL-element seed test; cohort NULL→value pin.
Post-fix: 52 SQL assertions + full suite pass, 1810 Flutter tests pass,
analyze clean. (Observed pre-existing, not W1: `push_on_referral_confirm_test`
pgtap `not ok 5` on local dev DB — pgtap failures don't fail CI's runner.)

## Review record — round 1, plan-level (2026-07-26)

Two adversarial passes (eng-correctness + security). Blockers folded in: **F1** weekly-pool tz ping-pong → monotonic `>` reset + 6-day wall-clock anchor; **F2** client-asserted cohort → server-assigned in `handle_new_user` via `new_signup_cohort` config, all client writes blocked, warmups set at insert. Majors: **F3** unseal tz-walk → 20h floor; **F4** client-chosen deck → FK + accepted-residual-risk note + binding no-economy-on-unseal rule for W2/W3; **F5** tz as unauthenticated input → Migration A; **eng-1** quest fix widened to the pool-selection seeds; **eng-2** write-once → freeze-after-completion; **eng-4** grants convention. Minors: eng-6 cardinality, eng-7 FK target `collectible_names`, eng-8 cast form, eng-9 `first_problem_text` in sync, F7 fallback keys, F8 staged-script role assert. Verified-clean claims retained in "Verified baseline."

## Founder decisions (2026-07-26)

1. **Queue length: 7** (pair + 5 aspiration rows). A longer arc later = one-line check-constraint migration.
2. **Weekly pool: no refunds** — consumed-on-error is eaten, matching warmup posture.
3. **PR strategy: merge W1 alone when green**; W2 becomes its own PR on top of master.
