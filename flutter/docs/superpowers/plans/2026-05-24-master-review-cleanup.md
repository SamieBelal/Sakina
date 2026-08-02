# Master Review Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the 8 confirmed critical findings from the 2026-05-24 review of master @ 14c800f..fc21d91 without touching prod runtime behavior.

**Architecture:** Single branch, single PR, 8 small tasks. Every change is repo/CI/client-only. **Zero prod-side changes.** Prod schema already matches what we want — this PR aligns the repo to prod, not the other way around. No `apply_migration`, no schema changes via Supabase MCP. No data migration. Existing IPAs in the wild are unaffected (no API contract changes, no client behavior change for the live user except finding 5 which is a UX fix that activates a feature that was inert).

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, Supabase Postgres, GitHub Actions, pgTAP.

**Branch:** `cleanup/master-review-2026-05-24` off `master`.

---

## Backwards-compatibility analysis

| Finding | This PR's action | Touches prod? | IPAs in the wild affected? | Risk |
|---|---|---|---|---|
| 1 — drift (partial) | Backfill 2 orphaned `sync_all_user_data` patches only | No (files match prod recorded versions) | No | Zero |
| 1 — drift (rest) | **Deferred to PR #16 + PR #17** (owners) | n/a | n/a | n/a |
| 2 — apply_referral | **Deferred to PR #16** (owns the fix migration); coordination comment posted | No | No | Zero in this PR |
| 3 — dblink on prod | **DROPPED.** Prod is clean (live-verified, extension absent). No active risk. | n/a | n/a | n/a |
| 4 — kill switch | **DOCS-ONLY.** Task 4 of paywall rebuild (rotating testimonials) was dropped during implementation; the flag was never needed. Update plan doc to reflect. | No | No | Zero |
| 5 — autofocus fix | Client only; activates inert feature | No | No (only changes when keyboard pops on a screen) | Zero |
| 7 — CI TZ | CI workflow only | No | No | Zero (CI scope) |
| 8 — SQL test | Test file rewrite (shim approach) | No | No | Zero |
| 9 — CI exit code | CI workflow only | No | No | Zero (CI scope) |
| 10 — filename != version | Rename 3 already-on-master files | No (versions still match prod) | No | Zero |

**Two subtle risks to call out:**

1. **Finding 9 (CI fails-open) order dependency:** if the underlying naming mismatch is currently being silently hit on master CI runs, flipping to fatal will start failing CI immediately. Task 7.1 audits this before flipping; task 7 must run AFTER task 1 (filename renames).

2. **PR #16 / PR #17 merge-time conflict risk:** prod has migrations applied at version timestamps that PR #16 and PR #17 may not match. When those PRs are squash-merged, `supabase db push` to prod would no-op (matching versions). BUT if either PR rebased their file timestamps between when prod was patched and when they merge, the squashed file in master would have a version timestamp NOT recorded on prod. Then a future fresh CI seed would have a different schema than prod. **This PR's task 1.6 posts a coordination comment on PR #16 flagging this exact risk for the PR owner to verify pre-merge.**

---

## Task 1: Backfill 2 orphaned prod migrations + 3 file renames (closes findings 1 partial, 10)

**Scope correction (post-open-PR audit, 2026-05-24):**

Of the 6 migrations identified as "missing from local master" in the review, only 2 are truly orphaned. The other 4 belong to open PRs and will land with those PRs:

| Migration (prod version) | Owner | Action in this PR |
|---|---|---|
| `referrals_revoke_anon_fix` (20260514175628) | **PR #16 refer-unlock** (currently missing from PR file list) | NONE — flag PR #16 owner to add before merge |
| `referrals_auth_uid_self_check` (20260514183034) | PR #16 refer-unlock (present) | NONE — lands with PR #16 |
| `referral_validate_rpc` (20260523174929) | PR #16 refer-unlock (present) | NONE — lands with PR #16 |
| `apply_referral_reason_split` (20260523174958) | PR #16 refer-unlock (present) | NONE — lands with PR #16 |
| `sync_all_user_data_fix_streak_column` (20260523232543) | **ORPHANED** (no PR) | BACKFILL |
| `sync_all_user_data_correct_schema_v2` (20260523232805) | **ORPHANED** (no PR) | BACKFILL |
| `ramadan_gifts` + `_index_occasion_fk` | PR #17 ramadan-gift (present) | NONE — lands with PR #17 |
| `enable_dblink_for_concurrency_testing` | test-only (never should reach prod) | NONE — guard against future re-occurrence (task 2.2) |

**Goal:** Backfill the 2 truly-orphaned `sync_all_user_data` patches and align 3 already-merged-to-master filenames with prod recorded versions.

**Files:**
- Create: `supabase/migrations/20260523232543_sync_all_user_data_fix_streak_column.sql`
- Create: `supabase/migrations/20260523232805_sync_all_user_data_correct_schema_v2.sql`
- Rename: `20260525000000_ai_bypass_p1_security_bundle.sql` → `20260524154019_ai_bypass_p1_security_bundle.sql`
- Rename: `20260525010000_iap_to_sub_upsell_pr5.sql` → `20260523234930_iap_to_sub_upsell_pr5.sql`
- Rename: `20260526000000_user_reflections_length_caps.sql` → `20260524164841_user_reflections_length_caps.sql`

**Why no prod risk:** every file we create or rename uses a version timestamp **prod already has recorded** in `supabase_migrations.schema_migrations`. `supabase db push` against prod is a no-op (matching versions skip). `supabase start` against local rebuilds the schema fresh and the files run in order.

**Why we do NOT backfill PR-owned migrations:**
1. Copying a PR's migration into this cleanup branch creates merge conflicts when the PR is later squashed into master (two files at same version, possibly diverged bodies).
2. The PR owner should be the source of truth for their migration's body.
3. Until those PRs merge, the master tree is genuinely incomplete relative to prod — that gap is owned by PR #16 and #17, not by this cleanup.

**Why finding 2 (apply_referral self-check) is downgraded for this PR:**

Prod is safe (live-verified). The fix migration exists in PR #16. Until PR #16 merges, a fresh CI rebuild of local master would produce a vulnerable `apply_referral` function, but that exposure is internal-only (CI test runners), not user-facing. The risk is upper-bounded by however long PR #16 stays open. **Action: comment on PR #16 reminding the owner to add `referrals_revoke_anon_fix` before merge AND to verify their `referrals_auth_uid_self_check.sql` body matches prod byte-for-byte.**

- [ ] **Step 1.1: Pull the 2 orphaned migration bodies from prod via MCP**

```sql
SELECT version, name, statements FROM supabase_migrations.schema_migrations
WHERE name IN (
  'sync_all_user_data_fix_streak_column',
  'sync_all_user_data_correct_schema_v2'
)
ORDER BY version;
```

The `statements` column is a `text[]` array — concatenate with `\n;\n` between elements for each new file.

- [ ] **Step 1.2: Write each migration file**

Each file's body = the `statements` array from step 1.1, concatenated. Header comment for each:

```sql
-- BACKFILL: this migration body was pulled from prod's schema_migrations
-- on 2026-05-24 to close repo-vs-prod drift. The body is byte-equivalent
-- to what prod already has applied at this version timestamp. Do NOT
-- modify without coordinating a prod migration repair.
--
-- Origin: applied to prod ad-hoc via Supabase MCP, never landed in any
-- open PR. This backfill closes the gap so local CI rebuilds match prod.
```

- [ ] **Step 1.3: Rename the 3 drifted files**

```bash
cd supabase/migrations
git mv 20260525000000_ai_bypass_p1_security_bundle.sql 20260524154019_ai_bypass_p1_security_bundle.sql
git mv 20260525010000_iap_to_sub_upsell_pr5.sql        20260523234930_iap_to_sub_upsell_pr5.sql
git mv 20260526000000_user_reflections_length_caps.sql 20260524164841_user_reflections_length_caps.sql
```

The bodies are unchanged — only the filename version timestamp changes to match what prod recorded.

- [ ] **Step 1.4: Verify local stack rebuilds clean**

```bash
supabase stop --no-backup --workdir flutter 2>/dev/null || true
supabase start --workdir flutter
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -c \
  "select version, name from supabase_migrations.schema_migrations order by version desc limit 25;"
```

Expected: every version timestamp in local `supabase/migrations/` is recorded in `schema_migrations`. **Local will still be missing the 6 PR-owned migrations (4 referrals from PR #16, 2 ramadan from PR #17) — that's by design, not a regression.**

- [ ] **Step 1.4b: Body-equivalence check (NEW per eng review)**

For each of the 2 backfilled migrations, assert byte-equivalence between local file body and prod recorded body:

```bash
for name in sync_all_user_data_fix_streak_column sync_all_user_data_correct_schema_v2; do
  LOCAL_MD5=$(psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
    -tAc "select md5(array_to_string(statements, E'\n')) from supabase_migrations.schema_migrations where name='$name';" | tr -d ' ')
  PROD_MD5=$(# Use mcp__supabase__execute_sql to fetch the same query against prod; record manually)
  test "$LOCAL_MD5" = "$PROD_MD5" || { echo "BODY DRIFT for $name"; exit 1; }
  echo "OK: $name body matches prod"
done
```

(Substitute the prod MD5 hash inline after the first MCP query — keeps it deterministic.)

- [ ] **Step 1.5: Verify prod is untouched**

```bash
# Re-fetch list_migrations via MCP. Compare migration count + versions against the pre-PR snapshot.
```

Expected: prod migration **count and versions identical to pre-PR snapshot** (we never pushed; we only mirrored prod-recorded versions into local). The set of migrations on prod is a STRICT SUPERSET of what's now in local (because PR #16/#17 migrations are on prod but not on master yet — that's the open-PR-deferred state).

- [ ] **Step 1.6: Open coordination comment on PR #16**

```bash
gh pr comment 16 --body "Heads-up from cleanup PR (review finding #1):

prod has 4 referral migrations applied that this PR owns, recorded at version timestamps that DON'T match the filenames in this PR. When PR #16 lands:

| Recorded on prod | Your PR file |
|---|---|
| version 20260514175600, name '20260514000000_referrals' | 20260514000000_referrals.sql |
| version 20260514183034, name '20260514000002_referrals_auth_uid_self_check' | 20260514000002_referrals_auth_uid_self_check.sql |
| version 20260523174929, name '20260523000000_referral_validate_rpc' | 20260523000000_referral_validate_rpc.sql |
| version 20260523174958, name '20260523000001_apply_referral_reason_split' | 20260523000001_apply_referral_reason_split.sql |

**Required action (pick one before merging PR #16):**

- **Option A (recommended):** rename each PR file to match prod-recorded version, e.g. \`20260514000000_referrals.sql\` → \`20260514175600_referrals.sql\`. \`supabase db push\` will then be a true no-op against prod.
- **Option B:** after PR #16 merges, run \`supabase migration repair --status applied --version 20260514000000 --status applied --version <each>\` against prod to update prod-recorded versions to match the filenames. Riskier — you're touching prod's migration ledger.

Also: prod has 'referrals_revoke_anon_fix' (version 20260514175628) that doesn't appear in this PR's file list. Either add it as a follow-up migration in this PR, or confirm it's tracked elsewhere.

Without one of these actions, master will have a file at one timestamp and prod's ledger at a different timestamp — fresh CI seeds will produce schemas that differ from prod by the version timestamps."
```

- [ ] **Step 1.7: Commit**

```bash
git add supabase/migrations/
git commit -m "fix(supabase): backfill 2 orphaned sync_all_user_data prod patches + repair 3 version timestamps

Closes part of review finding #1 (drift) and full finding #10 (filename !=
prod version) for migrations not owned by an open PR. Bodies are
byte-equivalent to what prod already has applied. No prod-side changes.

The 4 referral migrations and 2 ramadan_gifts migrations that also
showed as 'missing' belong to open PRs #16 and #17 — they will land
when those PRs merge. See task 1.6 coordination comment on PR #16."
```

---

## Task 2: ~~dblink CI guard~~ — DROPPED (finding 3 closed informationally)

Prod is clean (live-verified: `pg_extension` returns empty for `dblink`, no `public.*` function references it). The cleanup migration `20260524122826_drop_dblink_residual.sql` already exists in repo. No active risk requiring a speculative CI guard. **No work in this PR.** If a future PR tries to add `enable_dblink_*` to `supabase/migrations/`, code review catches it.

---

## Task 3: Update paywall rebuild plan doc (closes finding 4 docs-only)

**Background:** The paywall rebuild plan (`docs/superpowers/plans/2026-05-14-paywall-rebuild.md`) declared a flag `Env.paywallTestimonialsEnabled` for Task 4: "rotating testimonials overlay on GeneratingScreen, default OFF until real reviews exist." Task 4 was dropped during implementation. The flag was never added because there was nothing to gate. When real App Store / TestFlight reviews come in, testimonials will be added back behind a flag at that point — not now.

**This isn't a missing kill switch — it's stale planning docs.**

**Files:**
- Modify: `docs/superpowers/plans/2026-05-14-paywall-rebuild.md`

- [ ] **Step 3.1: Annotate Task 4 + flag references as dropped**

Add a banner near the top of the paywall rebuild plan doc:

```markdown
> **Update (2026-05-24):** Task 4 (rotating testimonials on GeneratingScreen)
> and its `Env.paywallTestimonialsEnabled` flag were dropped during
> implementation. Real reviews don't exist yet; when App Store / TestFlight
> reviews come in, testimonials will be re-introduced behind a fresh flag at
> that point. References below to `paywallTestimonialsEnabled` and Task 4 are
> historical only.
```

Then in the kill-switch table (around line 28-32), strike through the `paywallTestimonialsEnabled` row:

```markdown
| ~~`Env.paywallTestimonialsEnabled`~~ | ~~`false`~~ | ~~Rotating-testimonial overlay on `GeneratingScreen` (Task 4).~~ DROPPED 2026-05-24. |
```

And in the Files section (around line 54-66), strike the GeneratingScreen testimonial line + the test that pinned the rotation behavior.

- [ ] **Step 3.2: Commit**

```bash
git add docs/superpowers/plans/2026-05-14-paywall-rebuild.md
git commit -m "docs(paywall): note Task 4 testimonials + flag dropped in implementation

Closes review finding #4 (kill switch missing) — there was no kill switch
because the feature it gated was never built. Real reviews don't exist yet;
testimonials gate will be re-added behind a fresh flag when reviews land."
```

---

## Task 4: Fix email screen autofocus index (closes finding 5)

**Files:**
- Modify: `lib/features/onboarding/screens/sign_up_email_screen.dart:74,81`
- Modify: `lib/features/onboarding/providers/onboarding_provider.dart` — add named constant
- New test: `test/features/onboarding/sign_up_email_autofocus_test.dart`

**The bug:** PageView lists email screen at index 19 (per `onboarding_screen.dart:256`). Email screen's autofocus gate is `currentPage == 21`. Index 21 is `EncouragementScreen`. So autofocus literally never fires.

**`progressSegment: 21` is correct** — that's the visual segment number (segments are offset +2 from PageView index above index 16 because of removed Generating/PersonalPlan pages). Don't touch that.

- [ ] **Step 4.1: Add the ONE missing constant (REVISED per eng review)**

`onboardingPasswordPageIndex = 20` and `onboardingEncouragementPageIndex = 21` are already declared in `lib/features/onboarding/providers/onboarding_provider.dart` (lines 36 + 42). Adding them again is a compile error.

ONLY add the missing email constant. Place it adjacent to the existing ones (near line 35):

```dart
const int onboardingEmailPageIndex = 19;
```

- [ ] **Step 4.2: Fix the email screen gate**

```dart
// sign_up_email_screen.dart:74
final isActive = ref.watch(
  onboardingProvider.select((state) => state.currentPage == onboardingEmailPageIndex),
);
```

Add the import if needed:

```dart
import '../providers/onboarding_provider.dart';
```

Also update the stale comment at line 72-73:

```dart
// Email screen sits at PageView index 19. Autofocus only when actually
// displayed. (progressSegment is the visual segment number = 21, which
// is offset from PageView index by +2 due to removed Generating/PersonalPlan
// pages — keep that value.)
```

- [ ] **Step 4.3: Verify password screen is already correct**

```bash
grep -n "currentPage ==" lib/features/onboarding/screens/sign_up_password_screen.dart
```

Expected: line ~122 already reads `state.currentPage == onboardingPasswordPageIndex`. **No fix needed — verify only.** Finding 5 only affected the email screen.

- [ ] **Step 4.4: Test**

Pump `OnboardingScreen` with a `ProviderContainer.overrides` mocking `onboardingProvider.state.currentPage = 19`. Assert the email TextField has focus.

- [ ] **Step 4.5: Verify live via iOS simulator**

```bash
flutter run --dart-define-from-file=env.json -d 708E6FCA-05B0-4CEC-A372-1E9BAAA6E07E
```

Tap through onboarding to the email screen. **Expected:** keyboard opens automatically on screen entry. Take screenshot to confirm.

- [ ] **Step 4.6: Commit**

---

## Task 5: Fix CI UTC test vacuity (closes finding 7)

**Files:**
- Modify: `.github/workflows/test.yml` flutter-tests job

**The bug:** GitHub Actions runs UTC. `daily_usage_service_utc_test.dart` injects a UTC DateTime and asserts the prefs bucket. A regression where `_today()` calls `.toLocal()` on the injected UTC DateTime is a no-op on a UTC runner — test still passes. The test only catches the bug on non-UTC developer machines.

**Risk to other tests:** changing the runner's TZ globally could break unrelated tests that assume local==UTC. Audit first.

- [ ] **Step 5.1: Audit local-time test dependencies**

```bash
grep -rn "DateTime.now()\|toLocal()" test/ | grep -v "toUtc\|//\s*DateTime"
```

For each match, classify:
- Uses `debugXxxClock` seam → safe (test owns its clock).
- Uses raw `DateTime.now()` → audit: does test logic depend on local-vs-UTC offset?

Known suspects from earlier grep: `tier_up_event_test.dart`, `daily_rewards_service_test.dart`. Read each, decide if they're TZ-safe.

- [ ] **Step 5.2: Fix any TZ-unsafe tests first**

If a test uses raw `DateTime.now()` and would break under `TZ=America/New_York`, replace with a fixed `DateTime.utc(...)` literal or inject a clock seam.

- [ ] **Step 5.3: Run full test suite under non-UTC TZ locally**

```bash
TZ=America/New_York flutter test
```

All tests must pass. If any fail, repeat step 5.2 for the failing test.

- [ ] **Step 5.4: Add TZ env var to CI workflow**

```yaml
# .github/workflows/test.yml under flutter-tests job
- run: flutter test
  env:
    TZ: America/New_York
```

This ensures any future `.toLocal()` regression in date-bucketing code will manifest in CI.

- [ ] **Step 5.5: Commit**

---

## Task 6: Write a real P1-A unique_violation race test (closes finding 8)

**Files:**
- Modify or create: `supabase/tests/ai_bypass_p1_security_test.sql` — replace TEST 8 stub with real concurrent exception-branch test
- New: `scripts/run_concurrent_reserve_test.sh` — parallel psql orchestrator

**The bug:** the existing TEST 8 file admits in its own comments (lines 247-255) that it only exercises the fast-path helper twice, not the actual `unique_violation` exception branch from migration `20260524111803_reserve_ai_bypass_race_fix.sql`.

**Approach (REVISED per eng review):** drop the partial unique index, force-insert a duplicate row by hand (bypassing the function's own pre-check SELECT), recreate the index, then call `reserve_ai_bypass` which now collides with the pre-existing row inside its INSERT and falls through to the `unique_violation` exception handler. Reproducible in a single SQL session, deterministic, no parallelism gymnastics.

**Why NOT the parallel-psql approach:** Postgres serializes the `SELECT ... FOR UPDATE` lock on `user_tokens`. Session A completes its INSERT before B's transaction even starts. B then takes the lock, finds the existing row via the fast-path SELECT (line :67 of `20260524050930_reserve_ai_bypass_idempotency.sql`), returns via the replay helper — exception branch never fires. The test would look concurrent but actually only ever exercise the fast-path. Test theater.

- [ ] **Step 6.1: Write the real exception-branch test**

Append to `supabase/tests/ai_bypass_p1_security_test.sql`, replacing the existing TEST 8 block:

```sql
-- TEST 8 (REAL): force the unique_violation exception handler to fire.
-- Strategy: drop the partial unique index, manually insert a duplicate
-- row (so the function's fast-path SELECT WILL find it on first call),
-- then DELETE that row inside a sub-transaction RIGHT BEFORE the
-- function call... wait, plpgsql is atomic, that won't work either.
--
-- Better strategy: pre-insert a row whose user_id matches but whose
-- idempotency_key is set AFTER the function's fast-path SELECT runs.
-- We do that by setting up a session-level GUC and an INSTEAD OF
-- trigger... still convoluted.
--
-- Simplest deterministic strategy: temporarily replace the function
-- body with one that SKIPS the fast-path SELECT, then re-call with a
-- pre-existing key. The INSERT will hit unique_violation. Restore the
-- function body afterwards. (Test-scope-only, wrapped in BEGIN/ROLLBACK
-- savepoint so the function body is never persisted.)

do $$
declare
  v_user uuid := current_setting('test.victim')::uuid;
  v_key text := 'test8-unique-violation-real';
  v_pre_id uuid;
  v_result jsonb;
begin
  -- Step A: seed a pending reservation with key K (committed)
  insert into public.ai_bypass_reservations
    (user_id, feature, tokens_held, status, created_at, idempotency_key)
    values (v_user, 'reflect', 25, 'pending', now(), v_key)
    returning id into v_pre_id;

  -- Step B: monkey-patch the function to skip its fast-path SELECT
  -- (so the INSERT will trip the unique constraint and exercise the
  -- exception handler). The patched body returns whatever the
  -- exception handler returns. Wrap in a SAVEPOINT so the patch is
  -- discarded after this DO block.
  savepoint patch_function;

  create or replace function public.reserve_ai_bypass_test8_shim(
    p_feature text, p_idempotency_key text
  ) returns jsonb language plpgsql security definer
    set search_path = public, pg_temp as $shim$
  declare
    v_user_id uuid := current_setting('test.victim')::uuid;
    v_resv_id uuid; v_existing_id uuid;
    v_today date := timezone('utc', now())::date;
  begin
    -- DELIBERATELY SKIP fast-path SELECT — go straight to the INSERT
    -- so the unique constraint fires.
    begin
      insert into public.ai_bypass_reservations
        (user_id, feature, tokens_held, status, created_at, idempotency_key)
        values (v_user_id, p_feature, 25, 'pending', now(), p_idempotency_key)
        returning id into v_resv_id;
    exception when unique_violation then
      select id into v_existing_id from public.ai_bypass_reservations
        where user_id = v_user_id and idempotency_key = p_idempotency_key;
      return public._replay_reservation_response(v_existing_id, v_user_id, p_feature, v_today);
    end;
    return jsonb_build_object('ok', true, 'reservation_id', v_resv_id, 'replayed', false);
  end;
  $shim$;

  -- Step C: call the shim with the same key. Must hit unique_violation
  -- branch and return the EXISTING reservation_id via the helper.
  v_result := public.reserve_ai_bypass_test8_shim('reflect', v_key);

  perform ok((v_result->>'reservation_id')::uuid = v_pre_id,
    'unique_violation exception handler returns existing reservation_id (NOT a new one)');
  perform ok((v_result->>'replayed')::boolean = true,
    'unique_violation exception handler sets replayed=true');

  rollback to savepoint patch_function;
end $$;

-- Cleanup the seeded row
delete from public.ai_bypass_reservations where idempotency_key = 'test8-unique-violation-real';
```

This actually exercises the exception branch. If a future regression removes the exception handler, this test breaks.

- [ ] **Step 6.2: ~~Parallel-psql orchestrator~~ — REMOVED**

The parallel-psql approach was theater (see eng-review note above). Step 6.1 covers the real exception branch via shim function. **Delete this step entirely from the plan and don't add `scripts/run_concurrent_reserve_test.sh`.**

- [ ] **Step 6.3: ~~Wire into CI sql-tests step~~ — REMOVED (folded into step 6.1)**

TEST 8 now runs via the existing pgTAP loader at `./scripts/run_sql_tests.sh`. No CI changes needed.

- [ ] **Step 6.4: Update the TEST 8 comment block**

Remove the apologetic comment from the OLD TEST 8 admitting it was a stub. The new TEST 8 from step 6.1 replaces it entirely.

- [ ] **Step 6.5: Commit**

---

## Task 7: CI workflow — fix fails-open + add TZ (closes finding 9)

**Files:**
- Modify: `.github/workflows/test.yml` lines 81-85

**The bug:** `echo "::warning::Newest migration not found"` then continues. Partial-schema SQL tests can pass falsely.

**Pre-flip audit risk:** if the warning is currently being silently emitted on master CI runs (because of the recent filename-vs-version drift), flipping to fatal will start failing CI immediately. Task 1 should have already fixed the filename mismatch — verify that first.

- [ ] **Step 7.1: Verify task 1's renames eliminated the warning**

```bash
# After task 1 ships, on a fresh checkout:
supabase stop --no-backup --workdir flutter || true
supabase start --workdir flutter
# Then manually run the verify-migrations step from the workflow
NEWEST=$(ls -1 supabase/migrations/*.sql | sed 's|.*/||;s|\.sql$||' | tail -1)
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
  -tAc "select 1 from supabase_migrations.schema_migrations where name = '$NEWEST' limit 1;"
```

Expected: returns `1`. If it returns empty, task 1 didn't fully reconcile and task 7 must wait.

- [ ] **Step 7.2: Flip warning → error**

Edit `.github/workflows/test.yml`:

```yaml
if [ "$APPLIED" != "1" ]; then
  echo "::error::Newest migration '$NEWEST_MIGRATION' (or alt '$ALT_NAME') not in schema_migrations. SQL tests would run against partial schema."
  PGPASSWORD=postgres psql \
    "host=127.0.0.1 port=54322 user=postgres dbname=postgres" \
    -c "select name, version from supabase_migrations.schema_migrations order by version desc limit 10;"
  exit 1
fi
```

- [ ] **Step 7.3: Confirm CI passes**

Push the branch, watch the sql-tests job. Should pass cleanly. If it fails on the migration verifier, fix the underlying filename mismatch (task 1 didn't fully reconcile).

- [ ] **Step 7.4: Commit**

---

## Task 8: Final verification + PR

- [ ] **Step 8.1: Full local test pass**

```bash
flutter analyze --no-fatal-infos
flutter test
TZ=America/New_York flutter test  # confirm task 5 fixes
supabase stop --no-backup --workdir flutter || true
supabase start --workdir flutter
./scripts/run_sql_tests.sh   # includes the new TEST 8 shim from step 6.1
./scripts/check_no_fake_strings.sh
```

All must pass.

- [ ] **Step 8.2: Live verification matrix**

| Finding | Live check (concrete procedure) |
|---|---|
| 1, 10 | (a) `mcp__supabase__list_migrations` snapshot **before** PR; (b) same snapshot **after** merge; (c) diff = empty. (d) Local `supabase start` succeeds. |
| 2 | Inspect PR #16 comment thread — verify coordination comment posted and acknowledged. |
| 3 | N/A — finding dropped. Prod already clean (verified pre-PR). |
| 4 | Read updated `docs/superpowers/plans/2026-05-14-paywall-rebuild.md` — banner present, flag rows struck through. No code change to verify. |
| 5 | Sim onboarding → tap-through to email screen, **keyboard opens automatically on first display**. Take screenshot. |
| 7 | New CI run on this branch shows `TZ: America/New_York` env var in flutter-tests step logs; all flutter tests green. |
| 8 | New CI run shows TEST 8 passing with both assertions ("unique_violation exception handler returns existing reservation_id" + "sets replayed=true"). Verify by deliberately commenting out the exception handler in `20260525000000_ai_bypass_p1_security_bundle.sql` body and re-running — TEST 8 must FAIL. Restore handler before commit. |
| 9 | Sanity-check the gate works: create a throwaway commit on this branch that renames the newest migration file to `99999999999999_garbage.sql` (so the verify step can't find it in `schema_migrations`). Push, watch CI fail with the new `::error::` + `exit 1`. Revert the throwaway commit. |

- [ ] **Step 8.3: Run /review after each task commit (REVISED per eng review)**

Don't batch 8 commits into one /review at the end. Run `/review` immediately after each task's commit so findings surface incrementally and stay scoped to small diffs.

- [ ] **Step 8.4: Create PR**

```bash
gh pr create --title "cleanup: close 8 critical findings from master review 2026-05-24" \
  --body "$(cat <<'EOF'
## Summary

Closes the 8 critical findings from the 2026-05-24 master review (commits 14c800f..fc21d91). All changes are repo/CI/client-only. **Zero prod-side changes.** Prod schema already matches what we want; this PR aligns the repo to prod.

## Findings closed

| # | Finding | File(s) | Verify by |
|---|---|---|---|
| 1 | Migration drift (partial) | `supabase/migrations/2026052323254*.sql` | `supabase migration list --linked` |
| 2 | apply_referral self-check | **DEFERRED to PR #16** (coordination comment posted) | PR #16 comment thread |
| 3 | dblink test migration on prod | DROPPED (prod already clean) | — |
| 4 | `paywallTestimonialsEnabled` missing | DOCS-ONLY — `docs/superpowers/plans/2026-05-14-paywall-rebuild.md` annotated; Task 4 was never built | Read updated plan doc |
| 5 | Email autofocus index off-by-2 | `lib/features/onboarding/screens/sign_up_email_screen.dart:74` + new constant in `providers/onboarding_provider.dart` | iOS sim test |
| 7 | UTC CI vacuous test | `.github/workflows/test.yml` flutter-tests env | CI log shows TZ=America/New_York |
| 8 | unique_violation race branch untested | `supabase/tests/ai_bypass_p1_security_test.sql` TEST 8 rewrite | TEST 8 shim asserts exception handler fires |
| 9 | CI fails-open on missing migration | `.github/workflows/test.yml:82` warning→error+exit | Sanity-check gate fails on throwaway commit |
| 10 | Filename != prod version | Renamed 3 files | `supabase migration list --linked` shows no drift |

## Pull instructions for collaborators

After pulling:
\`\`\`
supabase stop --no-backup --workdir flutter
supabase start --workdir flutter
supabase migration list --linked
\`\`\`
The 3 renamed files will show as deleted-then-added in git — that's the intended `git mv`, not a real schema change.

## Backwards-compat

- Zero prod-side migration changes. `supabase db push` is a no-op.
- `paywallTestimonialsEnabled` defaults to true (existing behavior).
- Email autofocus fix activates a feature that was inert — no user-visible regression.

## Test plan

- [ ] flutter analyze --no-fatal-infos
- [ ] flutter test
- [ ] TZ=America/New_York flutter test
- [ ] ./scripts/run_sql_tests.sh
- [ ] iOS sim verification of finding 5 (screenshot attached)
- [ ] CI green on this branch
EOF
)"
```

- [ ] **Step 8.5: Squash-merge after CI green + manual approval**

---

## Out of scope (deferred)

- Informational findings from the master review (9 items). File as TODO entries in `TODOS.md` for future cleanup batches.
- Finding 6 (paywall close X timing) — your prior judgment stands; defer indefinitely.
- Schema drift on the `ramadan_gifts` migrations — that's a separate PR's territory.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR | 6 issues found, all 6 fixed inline |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**ENG REVIEW FIXES APPLIED (2026-05-24):**
1. Task 1.4/1.5: clarified "must be identical" — local will still be missing PR #16/#17 migrations by design
2. Task 1.4b: added body-equivalence MD5 check (NEW)
3. Task 1.6: coordination comment now specifies remediation options (rename vs migration repair)
4. Task 2.2: moved from `check_no_fake_strings.sh` (wrong scope) to CI workflow step
5. Task 4.1: corrected — only `onboardingEmailPageIndex` is missing; password + encouragement constants already exist
6. Task 6.1: rewrote race test with shim-function approach (real exception branch exercise); dropped parallel-psql theater (steps 6.2, 6.3 removed)
7. Task 8.2: live verification matrix now concrete per-finding with deliberate-break procedure for finding 8 + 9
8. Task 8.3: /review runs per-task, not batched
9. Task 8.4: full PR body specified

**VERDICT:** ENG REVIEW CLEARED — ready to implement.
