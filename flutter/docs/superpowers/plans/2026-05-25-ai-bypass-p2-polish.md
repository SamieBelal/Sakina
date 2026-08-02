# AI-Bypass P2 Polish — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (or an equivalent task-by-task workflow) to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the 4 remaining P2 findings from `docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md` that survived PR #26's hotfix bundle. All four ship as **one PR off one branch from master**.

**Architecture:** Single branch (`polish/ai-bypass-p2-bundle`) off master. Four focused fixes, each with its own task block, pre-fix repro, fix, unit test, and live re-verify. One squash-merge PR at the end.

**Tech stack:** Flutter 3.41.6 / Dart 3.11.4, Supabase Postgres, RevenueCat, Mixpanel. Same patterns as the PR #26 hotfix bundle.

**Out of scope:**
- `gift_premium_until` guard. Blocked behind the separate Ramadan-gifts PR. Will be a follow-up PR after Ramadan-gifts merges to master. Not part of this plan.
- Real-dollar accounting for the banner (P2-2 fix drops the dollar figure, does not recompute it). Recomputing requires server-side aggregation across `nonSubscriptionTransactions` — separate growth-team initiative, filed as a TODO.
- Backfill of historical `user_reflections` rows that may already have absurdly-long content from the unguarded path. The new CHECK rejects future inserts only.
- Auto-retry on dismiss banner RPC failure (P2-4 fires the failure event but doesn't auto-retry — separate UX decision).

---

## What already exists

- **Live exploit reproductions** for all 4 P2s recorded in `docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md` and re-verified 2026-05-25 against current master + post-deploy prod state.
- **Test patterns:**
  - Dart widget tests with the `_TrackingSpy` analytics-mock pattern (`test/features/onboarding/rating_gate_screen_test.dart`).
  - SQL self-seeded auth.users + JWT impersonation harness (`supabase/tests/freemium_guards_bypass_fields_test.sql`).
  - In-tx live verification pattern: BEGIN; apply migration; run exploit; verify blocked; ROLLBACK (used 5 times in PR #26).
- **CI workflow** at `.github/workflows/test.yml` runs `flutter test` + `psql -f supabase/tests/*.sql` on every PR.

---

## File structure (whole PR)

| File | Action | For |
|------|--------|-----|
| `lib/services/gating_service.dart` | Modify ~lines 360-409 (reserveBypass) | P2-1 |
| `lib/widgets/iap_to_sub_upsell_banner.dart` | Modify lines 202-206 + 320-329 | P2-2 + P2-4 |
| `lib/services/analytics_events.dart` | +1 event constant | P2-4 |
| `lib/features/reflect/models/saved_reflection.dart` | Modify `toSupabaseRow` (client-side clamp) | P2-5 |
| `supabase/migrations/20260526000000_user_reflections_length_caps.sql` | NEW | P2-5 |
| `test/services/gating_service_bypass_test.dart` | Extend | P2-1 regression test |
| `test/widgets/iap_to_sub_upsell_banner_test.dart` | Extend | P2-2 + P2-4 regression tests |
| `test/features/reflect/saved_reflection_clamp_test.dart` | NEW | P2-5 client clamp tests |
| `supabase/tests/user_reflections_length_caps_test.sql` | NEW (8 assertions) | P2-5 server tests |

Total: 4 modified files + 4 new test files + 1 new migration.

---

## Task 0: Setup

- [ ] **0.1: Branch from master**

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
git fetch origin master --quiet
git checkout master
git pull --ff-only origin master
git checkout -b polish/ai-bypass-p2-bundle
```

- [ ] **0.2: Confirm baseline**

```bash
flutter test 2>&1 | tail -3   # expect "All tests passed!" with 917+
flutter analyze --no-fatal-infos 2>&1 | tail -3
```

---

## Task 1: P2-1 — Inspect `replayed:true` flag

**File:** `lib/services/gating_service.dart`

- [ ] **1.1: Pre-verify the bug exists**

```bash
grep -n "replayed" lib/services/gating_service.dart
# Expected: zero matches (proves the bug is present)
```

- [ ] **1.2: Apply fix**

In `reserveBypass()`, around the existing success branch (lines 383-409), inspect `result['replayed']` BEFORE incrementing the cache:

```dart
final reservationId = result['reservation_id'] as String?;
final balance = (result['balance'] as num?)?.toInt();
final bypassesUsed = (result['bypasses_used'] as num?)?.toInt();
final replayed = result['replayed'] == true;
if (reservationId == null || balance == null || bypassesUsed == null) {
  onAnalyticsEvent?.call('ai_bypass_rejected', {
    'feature': featureKey,
    'reason': 'malformed_response',
  });
  return null;
}

// Always hydrate the token cache — server's reported balance is the source of truth.
await tokens.hydrateTokenCache(balance: balance);

// Only increment the local bypass counter on a TRUE reservation, not a replay.
// On a replay, the original call already incremented the counter; double-incrementing
// would over-count in the local cache. Defense-in-depth against future key-reuse
// code paths (today's fresh-UUID-per-call flow doesn't trip this).
if (!replayed) {
  await _incrementBypassCache(feature);
}
```

- [ ] **1.3: Add regression test**

In `test/services/gating_service_bypass_test.dart`, add a test that mocks the RPC to return `{"ok": true, "replayed": true, "balance": 75, "bypasses_used": 1, "reservation_id": "..."}` and asserts that `_incrementBypassCache` does NOT fire (verify by inspecting cached counter via the existing token+counter cache APIs in the test). Use the existing mock pattern in that file. Name: `'reserveBypass skips bypass-cache increment when server returns replayed:true'`.

- [ ] **1.4: Run unit test**

```bash
flutter test test/services/gating_service_bypass_test.dart 2>&1 | tail -3
```

- [ ] **1.5: Live verify "server response shape matches client expectations"**

The server-side fix already shipped in PR #26. Confirm the live `reserve_ai_bypass` RPC actually returns `replayed:true` on a pending-replay path (so the client's new branch will fire). Via Supabase MCP:

```sql
-- Create test user, reserve twice with same key, confirm 2nd response has replayed:true
do $$
declare v_uid uuid := gen_random_uuid(); r1 jsonb; r2 jsonb;
begin
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'p2-1-' || v_uid::text || '@example.com', '', now(), now(), now());
  update public.user_tokens set balance=200 where user_id=v_uid;
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_uid, 'role','authenticated')::text, true);
  set local role authenticated;
  r1 := public.reserve_ai_bypass('reflect', 'p2-1-verify-key-aaaaaaaaaaaaaaaaaa');
  r2 := public.reserve_ai_bypass('reflect', 'p2-1-verify-key-aaaaaaaaaaaaaaaaaa');
  reset role;
  raise notice 'R1=% R2=%', r1, r2;
end $$;
-- Cleanup
delete from public.ai_bypass_reservations where user_id in (select id from auth.users where email like 'p2-1-%@example.com');
delete from auth.users where email like 'p2-1-%@example.com';
```

Expected: `r2.replayed=true, r2.reservation_id=r1.reservation_id`. Save the output.

- [ ] **1.6: Commit**

```bash
git add lib/services/gating_service.dart test/services/gating_service_bypass_test.dart
git commit -m "fix(p2-1): inspect replayed:true in reserveBypass to skip cache increment"
```

---

## Task 2: P2-2 — Drop banner $ figure

**File:** `lib/widgets/iap_to_sub_upsell_banner.dart`

- [ ] **2.1: Pre-verify the bug exists**

```bash
sed -n '202,206p' lib/widgets/iap_to_sub_upsell_banner.dart
# Expected: shows the "illustrative" comment + dollarsSpent formula + headline string
```

- [ ] **2.2: Apply fix (drop the dollar figure, use a count)**

Replace lines 202-206:

```dart
// Headline: count-based (was previously a fabricated dollar figure
// computed as count * $0.50, removed 2026-05-25 per P2-2 finding — Apple
// 3.1.1 / FTC risk for presenting an illustrative number as user spend).
// Real per-bypass cost varies by token-pack size; computing real dollars
// requires server-side aggregation from RevenueCat nonSubscriptionTransactions,
// tracked as a separate growth-team initiative.
final count = state.lifetimeBypassesPurchased;
final headline = count == 1
    ? "You've used 1 bypass"
    : "You've used $count bypasses";
```

Leave the `subline` (weekly price comparison) intact — that uses live RevenueCat data, not a fabricated figure.

- [ ] **2.3: Add regression tests**

In `test/widgets/iap_to_sub_upsell_banner_test.dart`, add two tests:

- `'P2-2: banner headline shows bypass count, not dollar figure'`: pump banner with `lifetimeBypassesPurchased: 6`, assert `find.text("You've used 6 bypasses")` finds it, assert `find.textContaining("\$")` does NOT find anything in the headline subtree.
- `'P2-2: banner headline pluralization at count=1'`: pump with `lifetimeBypassesPurchased: 1`, assert `find.text("You've used 1 bypass")` finds it (singular).
- **(ENG-REVIEW added)** `'P2-2: banner does not render at count=0'`: pump with `lifetimeBypassesPurchased: 0` AND the other banner-state predicates set such that only the lifetime count is at zero. Assert the banner widget is not present (`find.byType(IapToSubUpsellBanner)` should be empty if the state provider gates on count). If the state provider DOES render at count=0, this test fails with a recommendation to either gate-on-count or accept the awkward "You've used 0 bypasses" copy.

Reuse the existing widget-pump pattern in that file.

- [ ] **2.4: Run widget tests**

```bash
flutter test test/widgets/iap_to_sub_upsell_banner_test.dart 2>&1 | tail -3
```

- [ ] **2.5: Commit**

```bash
git add lib/widgets/iap_to_sub_upsell_banner.dart test/widgets/iap_to_sub_upsell_banner_test.dart
git commit -m "fix(p2-2): drop fabricated \$X spent banner figure, use bypass count"
```

---

## Task 3: P2-4 — Reorder dismiss analytics

**Files:** `lib/widgets/iap_to_sub_upsell_banner.dart`, `lib/services/analytics_events.dart`

- [ ] **3.1: Pre-verify the bug exists**

```bash
sed -n '319,330p' lib/widgets/iap_to_sub_upsell_banner.dart
# Expected: analytics.track at line 322 BEFORE the await at line 323
```

- [ ] **3.2: Add the failed event constant**

In `lib/services/analytics_events.dart`, add alongside the other banner events:

```dart
static const String iapToSubBannerDismissFailed = 'iap_to_sub_banner_dismiss_failed';
```

- [ ] **3.3: Apply fix**

Replace `_onDismissTap()`:

```dart
Future<void> _onDismissTap() async {
  final analytics = ref.read(analyticsProvider);
  final ok = await GatingService().dismissIapToSubBanner();
  if (ok) {
    analytics.track(AnalyticsEvents.iapToSubBannerDismissed);
    if (mounted) {
      ref.invalidate(iapToSubBannerStateProvider);
    }
  } else {
    // RPC failed (network / auth / server). Fire a paired event so the
    // funnel can model retry behavior. P2-4 (2026-05-25): the previous
    // implementation fired iapToSubBannerDismissed unconditionally before
    // the await, biasing the dismiss funnel when the RPC failed.
    analytics.track(AnalyticsEvents.iapToSubBannerDismissFailed);
  }
}
```

- [ ] **3.4: Add regression tests**

In `test/widgets/iap_to_sub_upsell_banner_test.dart`, two tests:

- `'P2-4: analytics fires only after server confirms dismissal'`: mock `GatingService.dismissIapToSubBanner` (via existing provider mock) to return `true`. Tap dismiss. Assert `iapToSubBannerDismissed` was tracked exactly once.
- `'P2-4: failed-dismiss fires the paired event instead'`: mock the RPC to return `false`. Tap dismiss. Assert `iapToSubBannerDismissed` was NOT tracked. Assert `iapToSubBannerDismissFailed` WAS tracked.

The existing test file already mocks `GatingService` via the `purchaseService` provider — match that pattern.

- [ ] **3.5: Run tests**

```bash
flutter test test/widgets/iap_to_sub_upsell_banner_test.dart 2>&1 | tail -3
```

- [ ] **3.6: Commit**

```bash
git add lib/widgets/iap_to_sub_upsell_banner.dart lib/services/analytics_events.dart test/widgets/iap_to_sub_upsell_banner_test.dart
git commit -m "fix(p2-4): fire dismiss analytics after server confirms, add paired fail event"
```

---

## Task 4: P2-5 — LLM output validation

**Files:** new migration + new SQL test + client clamp + new Dart test.

### 4a: Server side

- [ ] **4a.1: Pre-verify bug exists (live)**

Run via Supabase MCP — confirm `user_reflections` STILL has no CHECKs (re-verifying post PR #26 deploy):

```sql
select conname, contype from pg_constraint where conrelid = 'public.user_reflections'::regclass;
-- Expected: only user_reflections_pkey + user_reflections_user_id_fkey
```

Then re-run the live 55KB-string + 30-fabricated-verses exploit from the findings doc to confirm prod STILL accepts it. (Identical to the run that produced the 2026-05-25 evidence.) Save the result for the audit trail.

- [ ] **4a.2: Write the migration**

File: `supabase/migrations/20260526000000_user_reflections_length_caps.sql`

```sql
-- 2026-05-26: Length + shape validation on user_reflections.
-- Closes P2-5 from docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md.
-- Live-verified exploit: 55KB reframe + 30 fabricated verses accepted by prod
-- because user_reflections had only PK + FK constraints. Defense-in-depth
-- against prompt-injection landing in user_reflections / sync_all_user_data /
-- share-card image generator with arbitrarily-large or shape-violating content.

-- Length caps. Numbers chosen to be MUCH larger than any legitimate AI
-- response (typical reframe: 200-800 chars; typical story: 500-1500 chars).
-- A 4KB cap leaves 5x headroom and rejects the 50KB attack class.
alter table public.user_reflections drop constraint if exists user_reflections_text_length_caps;
alter table public.user_reflections add constraint user_reflections_text_length_caps
  check (
    length(coalesce(reframe, '')) <= 4096
    and length(coalesce(story, '')) <= 4096
    and length(coalesce(reframe_preview, '')) <= 300
    and length(coalesce(name, '')) <= 200
    and length(coalesce(name_arabic, '')) <= 200
    and length(coalesce(dua_arabic, '')) <= 1024
    and length(coalesce(dua_transliteration, '')) <= 1024
    and length(coalesce(dua_translation, '')) <= 1024
    and length(coalesce(dua_source, '')) <= 200
    and length(coalesce(user_text, '')) <= 2048
  );

-- JSON array shape + size caps for verses[] and related_names[].
alter table public.user_reflections drop constraint if exists user_reflections_jsonb_array_caps;
alter table public.user_reflections add constraint user_reflections_jsonb_array_caps
  check (
    (verses is null or (jsonb_typeof(verses) = 'array' and jsonb_array_length(verses) <= 8))
    and (related_names is null or (jsonb_typeof(related_names) = 'array' and jsonb_array_length(related_names) <= 8))
  );

-- Per-verse shape validator. Each verses[] element MUST be an object with
-- string fields {arabic, translation, reference}. Other element shapes
-- (raw strings, arrays, missing required keys) get rejected here.
create or replace function public._validate_user_reflections_verses_shape()
returns trigger language plpgsql security invoker set search_path = public, pg_temp as $$
declare v_verse jsonb;
begin
  if new.verses is not null then
    for v_verse in select jsonb_array_elements(new.verses) loop
      if jsonb_typeof(v_verse) <> 'object'
         or v_verse->>'arabic' is null
         or v_verse->>'translation' is null
         or v_verse->>'reference' is null
         or length(v_verse->>'arabic') > 2048
         or length(v_verse->>'translation') > 2048
         or length(v_verse->>'reference') > 200 then
        raise exception 'user_reflections.verses[] element fails shape validation: %', v_verse
          using errcode = 'check_violation';
      end if;
    end loop;
  end if;
  return new;
end $$;

drop trigger if exists user_reflections_verses_shape on public.user_reflections;
create trigger user_reflections_verses_shape
  before insert or update on public.user_reflections
  for each row execute function public._validate_user_reflections_verses_shape();
```

- [ ] **4a.3: Write the SQL test file**

File: `supabase/tests/user_reflections_length_caps_test.sql`. Mirror the structure of `freemium_guards_bypass_fields_test.sql`: BEGIN/ROLLBACK, `pg_temp.expect()`, self-seed an auth.users via the existing trigger chain. **11 assertions** (ENG-REVIEW added the last 3 for coverage gaps):

1. INSERT with `reframe` = 5000 chars → REJECTED (length cap)
2. INSERT with `story` = 10000 chars → REJECTED
3. INSERT with `verses` length = 15 → REJECTED (array cap)
4. INSERT with `verses` = `[{ "arabic": "x" }]` (missing translation+reference) → REJECTED (shape trigger)
5. INSERT with `verses` = `["just a string"]` (raw string not object) → REJECTED
6. INSERT with `verses` element `arabic` field = 3000 chars → REJECTED (per-field cap)
7. INSERT with `reframe` = 3500 chars (just under cap), 5 well-shaped verses → ACCEPTED (honest path)
8. INSERT with `verses = NULL` → ACCEPTED (nullable, original schema allows it)
9. **(new)** INSERT with `related_names` length = 12 → REJECTED (array cap)
10. **(new)** INSERT with `user_text` = 3000 chars → REJECTED (length cap)
11. **(new)** INSERT with `dua_arabic` = 2000 chars → REJECTED (length cap)

Final do-block raises if `passed <> 11`.

- [ ] **4a.4: Verify the migration locally via Supabase MCP**

Apply the migration body inline in a BEGIN/ROLLBACK transaction via `execute_sql`, then run the test SQL body, confirm 8/8 pass, ROLLBACK. **Do NOT use `apply_migration` here — that would commit to prod before the PR ships.**

### 4b: Client side (includes ENG-REVIEW Finding 2 fix — reorder local state)

**ENG-REVIEW DECISION (Finding 2):** the existing `_saveReflection` (`lib/features/reflect/providers/reflect_provider.dart` lines 700-711) updates the local state via `state.copyWith(savedReflections: updated)` + `_persistReflections(updated)` BEFORE awaiting the server `insertRow`. With the new CHECKs, a rejected write would leave the UI showing a "saved" reflection that doesn't exist server-side. **Reorder: server write first, then local state.** The clamp itself runs synchronously up-front so the local state and the server write see identical clamped values.

Pseudo-diff for the reordering inside `_saveReflection`:

```dart
// Build clamped row first (single source of truth for both writes).
final reflection = SavedReflection( /* fields, clamped via _clampText */ );

// Write to Supabase FIRST. If the new CHECK rejects, this throws and we
// never touch local state — preserves UI consistency.
final userId = supabaseSyncService.currentUserId;
if (userId != null) {
  await supabaseSyncService.insertRow(
    'user_reflections',
    reflection.toSupabaseRow(userId),
  );
}

// THEN update local state + persist.
final updated = [reflection, ...state.savedReflections];
state = state.copyWith(savedReflections: updated);
await _persistReflections(updated);
```

Add a unit test for this ordering in `test/features/reflect/reflect_provider_save_test.dart` (extend existing file if present, create new otherwise):
- `'_saveReflection does NOT update local state when server insert throws'`: mock `supabaseSyncService.insertRow` to throw a `check_violation` error; call `_saveReflection`; assert `state.savedReflections` is unchanged.



- [ ] **4b.1: Audit `saved_reflection.dart`**

```bash
grep -n "toSupabaseRow\|reframe\|story\|verses" lib/features/reflect/models/saved_reflection.dart | head -20
```

Identify the `toSupabaseRow()` method.

- [ ] **4b.2: Apply client-side clamp**

In `toSupabaseRow()`, clamp every field that crosses the boundary to match the server CHECKs. Add a `// P2-5:` comment block citing the findings doc.

**ENG-REVIEW DECISION (Finding 1):** clamp by **codepoints** to match the server's `length()` CHECK (which counts codepoints, not bytes). Earlier draft used `maxBytes ~/ 2` runes — that over-truncates honest Arabic content. Both sides now use the same units.

Helper to add at file top:

```dart
/// Clamp a string to at most [maxChars] codepoints (Dart `String.length`).
/// Matches the server's Postgres `length()` CHECK which also counts codepoints.
/// Returns '' for null so the row always has explicit values.
String _clampText(String? value, int maxChars) {
  if (value == null) return '';
  if (value.length <= maxChars) return value;
  return value.substring(0, maxChars);
}
```

Apply caps (mirroring the server `length()` CHECKs exactly):
- `reframe`, `story` → 4096 chars
- `reframe_preview` → 300 chars
- `name`, `name_arabic`, `dua_source` → 200 chars
- `dua_arabic`, `dua_transliteration`, `dua_translation` → 1024 chars
- `user_text` → 2048 chars
- `verses[]` → first 8 elements only (`.take(8).toList()`); within each, clamp `arabic` and `translation` to 2048 chars, `reference` to 200 chars
- `related_names[]` → first 8 elements only

- [ ] **4b.3: Add Dart unit tests**

`test/features/reflect/saved_reflection_clamp_test.dart` — 7 tests (ENG-REVIEW added the last 3 for coverage gaps):
- `'P2-5: toSupabaseRow clamps reframe to 4096 chars'`: pass a 5000-char reframe, assert output's `reframe` length is exactly 4096.
- `'P2-5: toSupabaseRow clamps story to 4096 chars'`
- `'P2-5: toSupabaseRow truncates verses[] to 8 elements'`: pass 15 verses, assert output has 8.
- `'P2-5: toSupabaseRow preserves honest payloads unchanged'`: pass a typical 500-char reframe + 4 verses, assert output is identical to input.
- **(new)** `'P2-5: toSupabaseRow truncates related_names[] to 8 elements'`: pass 20 related_names, assert output has 8.
- **(new)** `'P2-5: toSupabaseRow clamps per-verse field lengths'`: pass 1 verse with `arabic` = 3000 chars, assert output's `verses[0].arabic` is 2048; same for `translation` (cap 2048) and `reference` (cap 200).
- **(new)** `'P2-5: toSupabaseRow handles null inputs without crashing'`: pass `reframe: null`, assert output `reframe == ''`. Repeat for other nullable text fields.

- [ ] **4b.4: Run tests**

```bash
flutter test test/features/reflect/saved_reflection_clamp_test.dart 2>&1 | tail -3
```

### 4c: Live re-verify exploit blocked

- [ ] **4c.1: Independent live verification**

Run via Supabase MCP in a single `execute_sql` query:

```
BEGIN;
-- Apply the migration body inline
-- Create test user
-- Attempt the SAME 55KB-string + 30-fabricated-verses INSERT from the bug repro
-- Expected: check_violation exception raised
-- Verify zero rows landed
ROLLBACK;
```

Save the verification output (showing constraint name in the error, e.g., `user_reflections_text_length_caps` for the length attack and `user_reflections_jsonb_array_caps` for the 30-verses attack).

- [ ] **4c.2: Honest-path live verification**

Same shape but with a typical-size payload (500-char reframe, 4 well-shaped verses). Expected: INSERT succeeds. Confirms we didn't over-restrict.

- [ ] **4c.3: Commit**

```bash
git add supabase/migrations/20260526000000_user_reflections_length_caps.sql \
        supabase/tests/user_reflections_length_caps_test.sql \
        lib/features/reflect/models/saved_reflection.dart \
        test/features/reflect/saved_reflection_clamp_test.dart
git commit -m "fix(p2-5): length caps + verses shape validation on user_reflections"
```

---

## Task 5: PR + verify + deploy

- [ ] **5.1: Full Dart test suite**

```bash
flutter test 2>&1 | tail -3
# Expected: All tests passed. Count up by ~7 new tests vs baseline (917).
```

- [ ] **5.2: Analyze**

```bash
flutter analyze --no-fatal-infos 2>&1 | tail -3
# Expected: no new errors introduced
```

- [ ] **5.3: Push branch + open PR**

```bash
git push -u origin polish/ai-bypass-p2-bundle
gh pr create --base master --title "polish(ai-bypass): P2 bundle (P2-1 + P2-2 + P2-4 + P2-5)" --body "$(cat <<'EOF'
Closes the 4 remaining P2 findings from
docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md. All four shipped
together in one branch / one squash-merge PR.

P2-1 (client): gating_service inspects result['replayed'] and skips
_incrementBypassCache on replays. Defense-in-depth against future
key-reuse code paths (today's fresh-UUID flow doesn't trigger this).

P2-2 (client): banner headline switched from fabricated "\$X spent"
(computed as count * \$0.50, flagged as Apple 3.1.1 / FTC risk) to
count-based "You've used X bypasses". Real-dollar accounting from
RevenueCat is out of scope.

P2-4 (client): dismiss analytics now fires AFTER the server confirms,
with paired iap_to_sub_banner_dismiss_failed event for failed-dismiss
funnel modeling.

P2-5 (server + client): length CHECKs + verses[] shape trigger on
user_reflections. Closes a live-verified exploit where prod accepted
55KB strings + 30 fabricated verses + arbitrary "Made-Up Surah" refs.
Client-side belt-and-braces clamp in SavedReflection.toSupabaseRow.

Tests:
* 917+ flutter tests pass (5 new client tests across P2-1/2/4 + 4 new
  for P2-5 client clamp).
* New supabase/tests/user_reflections_length_caps_test.sql: 8 assertions
  covering length cap, array cap, per-verse shape, honest path.
* Independent live re-verify via Supabase MCP: all 4 exploits blocked
  post-fix; honest payloads still accepted.
EOF
)"
```

- [ ] **5.4: Wait for CI green** (`gh pr checks <PR_NUM>`)

- [ ] **5.5: Squash-merge + delete branch**

```bash
gh pr merge <PR_NUM> --squash --delete-branch
```

- [ ] **5.6: Apply migration to prod via Supabase MCP**

Use `mcp__supabase__apply_migration` with name `user_reflections_length_caps` and the migration body. (Same deploy pattern as the PR #26 hotfix bundle.)

- [ ] **5.7: Post-deploy live re-verify**

Re-run the 55KB-string + 30-fabricated-verses exploit against prod with the migration now applied. Expected: `check_violation` raised. Save the post-deploy evidence.

- [ ] **5.8: Update findings doc**

Mark P2-1, P2-2, P2-4, P2-5 as RESOLVED with links to the merged PR commit. Leave the residual P1 (`gift_premium_until`) entry in place — that one's deferred behind Ramadan-gifts.

---

## Verification ladder (applies to every task above)

Each fix follows this pattern:

1. **Pre-fix repro** — run the exploit live OR grep the code, confirm the bug fires AS EXPECTED. Save evidence.
2. **Apply the fix** — code change + tests.
3. **Unit test pass** — relevant `flutter test` or SQL test file.
4. **Independent live verify** — run the SAME exploit again with the fix in place. Confirm it's now blocked. Save evidence.
5. **CI green** — both `flutter-tests` + `sql-tests` jobs.
6. **(For server changes) post-deploy verify** — after merge + `apply_migration` to prod, re-run the live exploit one more time against prod. Confirm blocked.
7. **Cleanup** — delete any test users / rows.

Identical to the ladder PR #25 and PR #26 used.

---

## Failure modes per fix (and what catches them)

| Fix | Realistic failure | Test? | Error path? | User-visible? |
|-----|-------------------|-------|-------------|---------------|
| P2-1 client replay-skip | Future code reuses idempotency key → double-increments cache | Yes (new mocked-replay test) | n/a (defensive) | Local cache shows wrong count until next server sync |
| P2-2 count headline | RevenueCat returns stale lifetime count | n/a — display only | n/a | User sees a count off by one for a few seconds; self-corrects |
| P2-4 dismiss order | RPC retries succeed but analytics already fired the success event | Yes (mocked failure test) | Paired failure event fires | Funnel sees mixed signals — better than silent skew |
| P2-5 length cap | Honest LLM response exceeds 4KB (rare but possible for long reframes) | Yes (honest-path test at 3.5KB) | Save flow surfaces exception, reflection isn't saved locally either | User sees an error toast; can retry or shorten input |

**No critical gaps** — every failure has a test, an error path, and a user-visible surface.

---

## Out of scope (filed explicitly)

- **`gift_premium_until` guard.** Blocked behind the Ramadan-gifts PR merging to master. Will be a separate small follow-up PR after that lands. NOT in this plan.
- **Real-dollar accounting for the IAP→sub banner** via RevenueCat aggregation. Separate growth-team initiative.
- **Backfill audit** of historical `user_reflections` rows with absurdly-long content from the pre-CHECK era. Separate cleanup task.
- **Auto-retry** on `dismiss_iap_upsell_banner` RPC failure. Building automatic retry is a separate UX decision; this PR fires a failure analytics event so we can see how often it matters first.
- **`_saveReflection` graceful degradation** when the new CHECKs reject. Current behavior: exception → reflection not saved locally either. Acceptable for safety. Could file as a follow-up if user-impact metric shows real rejects.

---

## Completion summary template

When this PR ships, the findings doc gets these updates:

- P2-1: marked closed, link to the merged PR commit.
- P2-2: marked closed, link to merged PR. Filed real-dollar-accounting as a TODO.
- P2-4: marked closed, link to merged PR.
- P2-5: marked closed, link to merged PR.
- `gift_premium_until` residual P1: status unchanged (still deferred behind Ramadan-gifts PR).

Final state of the 2026-05-24 review: 4 of 5 findings resolved; 1 deferred (P1, scope-blocked).

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 2 issues found + applied, 5 test gaps backfilled, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**ENG-REVIEW DECISIONS (2026-05-25):**
- **Finding 1 (Architecture, P2):** client clamp now uses **codepoints** to match the server `length()` CHECK. Earlier draft used `bytes/2 runes` which over-truncated honest Arabic content. Plan updated in Task 4b.2.
- **Finding 2 (Code Quality, P2):** `_saveReflection` reordered so the server `insertRow` runs BEFORE the local state update. If the new CHECK rejects the write, local UI never shows a phantom saved reflection. Plan updated in a new ENG-REVIEW subsection under Task 4b.

**TEST GAPS BACKFILLED INTO THE PLAN:**
- Banner count=0 widget test (Task 2.3 amended).
- Client clamp tests for per-verse field clamps, `related_names[]` truncation, null inputs (Task 4b.3 expanded from 4 → 7 tests).
- SQL tests for `related_names` array cap, `user_text` length, `dua_arabic` length (Task 4a.3 expanded from 8 → 11 assertions).
- New `_saveReflection`-server-reject Dart test (added under Task 4b).

**UNRESOLVED:** 0

**VERDICT:** ENG CLEARED — plan is ready to execute. No outside voice run (scope small + recently P0/P1-reviewed in this session). No CEO review needed (no product/scope decisions). No design review needed (no UI surface changes beyond one headline string).
