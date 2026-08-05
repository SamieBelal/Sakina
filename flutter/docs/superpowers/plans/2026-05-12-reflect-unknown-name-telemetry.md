# Reflect Unknown-Name Telemetry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface production telemetry whenever the reflect feature falls back to the two "always-safe" verses because the AI returned a Name not in the approved catalog, so we can detect spelling drift and aliasing opportunities.

**Architecture:** Add a new user-scoped Supabase table `reflect_unknown_name_log` mirroring `reflect_classifier_log` (the proven pattern at `ai_service.dart:388`). Schema is minimal — `user_id` + `ai_returned_name` + `created_at`, no user excerpt (the AI's returned Name is the primary signal, and the user's raw text is not in scope at the logging call site anyway). Keep the pure catalog function pure by injecting an optional `onFallback` callback parameter into `normalizeApprovedVerses`. Wire that callback in `ai_service.dart` to a fire-and-forget logger that mirrors `_logClassifierDecision` exactly. Leaves the catalog free of service dependencies and keeps tests trivially passable with `null` callbacks.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, Supabase Postgres + RLS, existing `supabaseSyncService.insertRow()` helper.

**Trigger context (from `TODO.md` §4):** Plan 1 (verse catalog expansion) has shipped, so residual fallback firings are now meaningful signal rather than noise from a known-incomplete catalog.

**Out of scope (deliberately not in this plan):**
- A weekly aggregation query — that's an ops task to run in the Supabase SQL editor, not code. A canned query is included in the migration comment for the operator.
- An edge function or service-role variant — user-scoped RLS matches the existing `reflect_classifier_log` pattern and is enough. The original TODO sketch had service-role insert, but the canonical pattern in this codebase is user-scoped.
- Auto-alerting / dashboards — first, see what the data looks like.

---

## File Structure

**Create:**
- `supabase/migrations/20260512000000_create_reflect_unknown_name_log.sql` — table + RLS policies, mirrors `reflect_classifier_log` shape
- `test/features/reflect/reflection_verse_catalog_unknown_name_callback_test.dart` — pins callback firing behavior

**Modify:**
- `lib/features/reflect/data/reflection_verse_catalog.dart` — add optional `onFallback` callback parameter to `normalizeApprovedVerses`; preserve existing `kDebugMode` warning
- `lib/services/ai_service.dart` — add `_logUnknownNameFallback` helper (mirrors `_logClassifierDecision`); wire the callback at the existing `normalizeApprovedVerses` call site (currently `line 282`)
- `TODO.md` — mark §4 as DONE with the deployed migration name + commit SHA after merge

---

## Task 1: Migration — create `reflect_unknown_name_log` table

**Files:**
- Create: `supabase/migrations/20260512000000_create_reflect_unknown_name_log.sql`

**Why this shape:** Mirrors `reflect_classifier_log` exactly. User-scoped INSERT/SELECT RLS (users can write their own rows and read them back). No user-text column — `rawUserText` is not in scope at the call site (`parseReflectResponse(String text)` receives the AI response, not the user's input), and a free-text excerpt would carry PII anyway. `ai_returned_name` is what the AI actually said before we tried to match it to canonical, and that alone is the primary aliasing signal.

- [ ] **Step 1: Write the migration SQL**

```sql
-- 20260512000000_create_reflect_unknown_name_log.sql
--
-- Captures every firing of the "unknown-name" safety-net fallback in
-- `normalizeApprovedVerses` (lib/features/reflect/data/reflection_verse_catalog.dart).
-- When the AI returns a Name not in approvedReflectVersesByName, we serve the
-- two always-safe verses (_heartsRestVerse + _noBurdenVerse). This table lets
-- us measure how often that happens and which non-canonical spellings the AI
-- keeps returning, so we can either alias them or expand the catalog.
--
-- Mirrors the shape and RLS pattern of `reflect_classifier_log`.
--
-- Operator query for weekly review:
--
--   select ai_returned_name, count(*) as hits, max(created_at) as last_seen
--   from public.reflect_unknown_name_log
--   where created_at > now() - interval '7 days'
--   group by 1
--   order by hits desc
--   limit 25;

create table public.reflect_unknown_name_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ai_returned_name text not null,
  created_at timestamptz not null default now()
);

create index reflect_unknown_name_log_created_at_idx
  on public.reflect_unknown_name_log (created_at desc);

create index reflect_unknown_name_log_user_id_idx
  on public.reflect_unknown_name_log (user_id);

alter table public.reflect_unknown_name_log enable row level security;

-- Users may insert rows attributed to themselves.
create policy "users insert own unknown-name rows"
  on public.reflect_unknown_name_log
  for insert
  with check ((select auth.uid()) = user_id);

-- Users may read their own rows. Project owner reads aggregate via Studio /
-- service role; this policy is for app-side debug surfaces if we ever build one.
create policy "users read own unknown-name rows"
  on public.reflect_unknown_name_log
  for select
  using ((select auth.uid()) = user_id);
```

- [ ] **Step 2: Verify the migration applies cleanly to a Supabase branch (or local stack)**

Run (against a non-prod branch or local Supabase):
```bash
supabase db push
```
Or via the Supabase MCP `apply_migration` tool against a development branch.

Expected: migration applies without error. Then verify shape:
```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema='public' and table_name='reflect_unknown_name_log'
order by ordinal_position;
```
Expected columns in order: `id` (uuid, NO), `user_id` (uuid, NO), `ai_returned_name` (text, NO), `created_at` (timestamptz, NO).

Verify RLS:
```sql
select policyname, cmd from pg_policies
where schemaname='public' and tablename='reflect_unknown_name_log';
```
Expected: two rows — `users insert own unknown-name rows` (INSERT), `users read own unknown-name rows` (SELECT).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260512000000_create_reflect_unknown_name_log.sql
git commit -m "feat(supabase): add reflect_unknown_name_log table for fallback telemetry"
```

---

## Task 2: Add `onFallback` callback to `normalizeApprovedVerses`

**Files:**
- Modify: `lib/features/reflect/data/reflection_verse_catalog.dart:123-158`
- Test: `test/features/reflect/reflection_verse_catalog_unknown_name_callback_test.dart`

**Why a callback (not async, not refactored return type):** The catalog must stay pure and free of `supabase_sync_service` imports — it's used in the coverage tests that run synchronously and have zero network. A nullable callback parameter is the lowest-blast-radius change.

**Current signature for context (do not change return type):**
```dart
List<ReflectVerse> normalizeApprovedVerses(
  String name,
  List<ReflectVerse> verses,
) { ... }
```

- [ ] **Step 1: Write the failing test**

Create `test/features/reflect/reflection_verse_catalog_unknown_name_callback_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/reflect/data/reflection_verse_catalog.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';

void main() {
  group('normalizeApprovedVerses onFallback callback', () {
    test('fires once when Name is not in approved catalog', () {
      var firedCount = 0;
      String? firedWithName;

      final result = normalizeApprovedVerses(
        'Al-FabricatedName',
        const <ReflectVerse>[],
        onFallback: (name) {
          firedCount++;
          firedWithName = name;
        },
      );

      expect(result.length, 2, reason: 'fallback still returns 2 safe verses');
      expect(firedCount, 1);
      expect(firedWithName, 'Al-FabricatedName');
    });

    test('does NOT fire when Name has approved verses in catalog', () {
      var fired = false;

      // 'Ar-Rahman' is in approvedReflectVersesByName (see catalog file).
      // Pass empty AI verses so the function still has to do the by-name lookup.
      normalizeApprovedVerses(
        'Ar-Rahman',
        const <ReflectVerse>[],
        onFallback: (_) => fired = true,
      );

      expect(fired, isFalse);
    });

    test('does NOT fire when AI verses themselves match approved references', () {
      var fired = false;
      // Ash-Sharh 94:5-6 is in the catalog (hardshipEaseVerse). Even with a
      // fabricated Name, an approved verse reference avoids the fallback path.
      const approvedRef = ReflectVerse(
        arabic: 'placeholder',
        translation: 'placeholder',
        reference: 'Ash-Sharh 94:5-6',
      );

      normalizeApprovedVerses(
        'Al-FabricatedName',
        const <ReflectVerse>[approvedRef],
        onFallback: (_) => fired = true,
      );

      expect(fired, isFalse);
    });

    test('omitted callback parameter is safe (no crash)', () {
      // Existing callers (coverage tests, possible future call sites) should
      // not need to pass the callback. This guards against accidentally making
      // it required.
      final result = normalizeApprovedVerses(
        'Al-FabricatedName',
        const <ReflectVerse>[],
      );
      expect(result.length, 2);
    });

    test('callback that throws is swallowed — reflect flow never breaks', () {
      // Defensive contract: telemetry must NEVER take down a user's reflect.
      // If a future logger throws (sync), normalizeApprovedVerses must still
      // return the safety-net pair without propagating.
      final result = normalizeApprovedVerses(
        'Al-FabricatedName',
        const <ReflectVerse>[],
        onFallback: (_) => throw StateError('boom'),
      );
      expect(result.length, 2, reason: 'fallback verses still returned');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reflect/reflection_verse_catalog_unknown_name_callback_test.dart`

Expected: FAIL — compilation error "The named parameter 'onFallback' isn't defined" on test cases that pass `onFallback:`.

- [ ] **Step 3: Add the callback parameter to `normalizeApprovedVerses`**

Edit `lib/features/reflect/data/reflection_verse_catalog.dart`. Replace the existing `normalizeApprovedVerses` function (currently lines 123-158) with:

```dart
List<ReflectVerse> normalizeApprovedVerses(
  String name,
  List<ReflectVerse> verses, {
  void Function(String aiReturnedName)? onFallback,
}) {
  final approvedByReference = _approvedReflectVersesByReference;
  final normalized = <ReflectVerse>[];
  final seen = <String>{};

  for (final verse in verses) {
    final approved = approvedByReference[_normalizeVerseKey(verse.reference)];
    if (approved == null) continue;
    if (seen.add(approved.reference)) {
      normalized.add(approved);
    }
  }

  if (normalized.isNotEmpty) {
    return normalized.take(2).toList();
  }

  final byName = approvedVersesForName(name);
  if (byName.isNotEmpty) {
    return byName.take(2).toList();
  }

  // Final safety net: any Name not in the catalog still gets two "always-safe"
  // verses. Prevents verseless cards if the AI returns a non-canonical Name.
  // Debug-only warning (debugPrint is a no-op in release). When investigating a
  // suspected canonical-name mismatch, run the app in debug mode and watch the
  // console for "unknown-name fallback fired" lines.
  if (kDebugMode) {
    debugPrint('[reflect_verse] WARN: unknown-name fallback fired for "$name". '
        'Check AI prompt + canonical-names list for spelling mismatch.');
  }
  // Fire-and-forget telemetry hook. Caller (ai_service.dart) wires a Supabase
  // insert into reflect_unknown_name_log. Optional so the catalog stays
  // dependency-free for unit tests. Wrapped in try/catch because reflect
  // must NEVER break because of telemetry — pinned by
  // reflection_verse_catalog_unknown_name_callback_test.dart "callback that
  // throws" test.
  try {
    onFallback?.call(name);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[reflect_verse] onFallback threw: $e — swallowed.');
    }
  }
  return const [_heartsRestVerse, _noBurdenVerse];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reflect/reflection_verse_catalog_unknown_name_callback_test.dart`

Expected: PASS — all 5 cases.

- [ ] **Step 5: Run the existing reflect coverage test to confirm no regression**

Run: `flutter test test/features/reflect/reflection_verse_catalog_coverage_test.dart`

Expected: PASS — existing tests pass because the new parameter is optional and existing call sites omit it.

- [ ] **Step 6: Commit**

```bash
git add lib/features/reflect/data/reflection_verse_catalog.dart \
        test/features/reflect/reflection_verse_catalog_unknown_name_callback_test.dart
git commit -m "feat(reflect): add onFallback hook to normalizeApprovedVerses"
```

---

## Task 3: Wire the callback to a Supabase logger in `ai_service.dart`

**Files:**
- Modify: `lib/services/ai_service.dart` (add `_logUnknownNameFallback` helper near `_logClassifierDecision` at line 388; update the `normalizeApprovedVerses(...)` call at line 282)

**Why mirror `_logClassifierDecision`:** Same shape (fire-and-forget, swallows errors, debugPrint on failure for local dev). Same `insertRow` helper. Same try/catch envelope. Reviewers should grep the two functions to confirm they look like siblings.

- [ ] **Step 1: Read the existing `_logClassifierDecision` helper for reference**

Run: `flutter pub get` (sanity check imports resolve).

Look at `lib/services/ai_service.dart:388-404`. The new helper will mirror it.

- [ ] **Step 2: Add the `_logUnknownNameFallback` helper**

In `lib/services/ai_service.dart`, immediately after the closing brace of `_logClassifierDecision` (currently end of line 404), insert:

```dart
/// Fire-and-forget log when the reflect verse catalog falls back to the two
/// "always-safe" verses because the AI returned a Name we couldn't match to
/// our canonical list. Mirrors `_logClassifierDecision` — never blocks the
/// reflect flow, swallows errors, surfaces them in debug.
///
/// Surfaces what to fix: either alias the AI's spelling, or expand the catalog.
Future<void> _logUnknownNameFallback(String aiReturnedName) async {
  try {
    await supabaseSyncService.insertRow('reflect_unknown_name_log', {
      'user_id': supabaseSyncService.currentUserId,
      'ai_returned_name': aiReturnedName,
    });
  } catch (e) {
    // Swallow — logging must never block reflect. Visible in debug builds so
    // a misconfigured table / RLS rule is caught locally before shipping.
    debugPrint('reflect_unknown_name_log insert failed: $e');
  }
}
```

- [ ] **Step 3: Wire the callback at the existing call site**

In `lib/services/ai_service.dart`, find the existing line:
```dart
verses: normalizeApprovedVerses(canonicalName, parsedVerses),
```
(currently line 282). Replace it with:

```dart
verses: normalizeApprovedVerses(
  canonicalName,
  parsedVerses,
  onFallback: (aiReturnedName) {
    unawaited(_logUnknownNameFallback(aiReturnedName));
  },
),
```

Note: `rawUserText` is NOT in scope here — `parseReflectResponse(String text)` receives the AI response, not the user input. The Name alone is the primary signal for aliasing.

`unawaited` is already available via the existing `import 'dart:async';` at the top of the file (line 7). No new import needed.

- [ ] **Step 4: Run the full ai_service test suite**

Run: `flutter test test/services/`

Expected: PASS — no behavior change to the happy path; the callback only fires on the unknown-name branch.

- [ ] **Step 5: Run `flutter analyze` to catch unused imports / typos**

Run: `flutter analyze lib/services/ai_service.dart lib/features/reflect/`

Expected: No new errors. Existing infos/warnings unchanged.

- [ ] **Step 6: Commit**

```bash
git add lib/services/ai_service.dart
git commit -m "feat(reflect): log unknown-name fallback to reflect_unknown_name_log"
```

---

## Task 4: Manual smoke test against staging Supabase + close the TODO

**Files:**
- Modify: `TODO.md` (mark §4 as DONE)
- Modify: `CLAUDE.md` (no entry needed — this isn't a bug fix, but mention the new table in the Known telemetry section if one exists; otherwise skip)

**Why a manual smoke:** This path only fires when the AI returns a non-canonical Name, which is rare and timing-dependent. Cheapest validation is to force a fallback with a fabricated Name in a debug run and watch the table.

- [ ] **Step 1: Force a fallback in a local debug run**

Two options — pick one:

**Option A (recommended, no code change):** In `lib/services/ai_service.dart`, temporarily hardcode `canonicalName = 'Al-FabricatedName'` right above the `normalizeApprovedVerses` call (currently line 282). Run the app, complete a reflect flow, then revert.

**Option B:** Use the Supabase SQL editor to manually insert a row as a signed-in user:
```sql
insert into public.reflect_unknown_name_log (user_id, ai_returned_name)
values (auth.uid(), 'Al-FabricatedName');
```

- [ ] **Step 2: Verify the row landed via Supabase MCP or Studio**

Run via Supabase MCP `execute_sql`:
```sql
select id, user_id, ai_returned_name, created_at
from public.reflect_unknown_name_log
order by created_at desc
limit 5;
```

Expected: 1+ row with `ai_returned_name = 'Al-FabricatedName'` and a `created_at` within the last minute.

- [ ] **Step 3: Verify RLS isolation**

In the Supabase SQL editor, switch to a different test user and run the same select. Expected: zero rows (you only see your own).

- [ ] **Step 4: Revert any temporary debug changes**

If you used Option A, revert the hardcoded `canonicalName` line back to its original value. Run:
```bash
git diff lib/services/ai_service.dart
```
Expected: only the additions from Tasks 2 and 3 remain (the helper + the wired-up callback). No fabricated-name line.

- [ ] **Step 5: Mark the TODO as done**

Open `TODO.md` and replace the entire `## Production telemetry for unknown-name fallback` section (currently around lines 66-104) with:

```markdown
## ~~Production telemetry for unknown-name fallback~~ ✅ DONE 2026-05-12

Shipped in PR #<num> via migration `20260512000000_create_reflect_unknown_name_log.sql`.
`normalizeApprovedVerses` now fires an optional `onFallback` callback that
`ai_service.dart` wires to a fire-and-forget `_logUnknownNameFallback` insert
into `reflect_unknown_name_log`. RLS mirrors `reflect_classifier_log`
(user-scoped INSERT-own + SELECT-own).

**Weekly review query** (run in Supabase SQL editor):

```sql
select ai_returned_name, count(*) as hits, max(created_at) as last_seen
from public.reflect_unknown_name_log
where created_at > now() - interval '7 days'
group by 1
order by hits desc
limit 25;
```
```

Replace `<num>` with the actual PR number once opened.

- [ ] **Step 6: Commit**

```bash
git add TODO.md
git commit -m "docs(todo): mark unknown-name fallback telemetry as shipped"
```

---

## Self-review notes (filled in by author)

**Spec coverage:**
- ✅ Migration to create `reflect_unknown_name_log` table (Task 1)
- ✅ Fire-and-forget logger mirroring `_logClassifierDecision` (Task 3)
- ✅ Preserve `kDebugMode` warning for local development (kept verbatim in Task 2)
- ✅ Weekly Supabase query for top-N unknown names (included as a comment in the migration + in the TODO done-entry; not code)
- ✅ Defensive: callback try/catch + regression test pinning "callback that throws never breaks reflect" (Task 2)

**Placeholder scan:** No "TBD", "fill in details", "appropriate error handling", or "similar to Task N" found.

**Type consistency:** `onFallback` is `void Function(String aiReturnedName)?` in every reference. Logger signature is `_logUnknownNameFallback(String aiReturnedName)`. Both consistent across tasks 2 and 3.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR (PLAN) | 2 issues, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **UNRESOLVED:** 0
- **VERDICT:** ENG CLEARED — ready to implement. Two architecture/quality issues surfaced and resolved inline: dropped `phrase_excerpt` (PII + scope not available at call site), and added defensive try/catch around `onFallback?.call(name)` so a misbehaving telemetry callback can never take down a user's reflect.
