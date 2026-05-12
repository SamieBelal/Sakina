# Reflection Verse Catalog Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the approved Quran verse catalog so every one of the 99 Names of Allah has ≥2 scholar-verified verses, eliminating verseless reflect cards.

**Architecture:** `lib/features/reflect/data/reflection_verse_catalog.dart` today maps only 15 of 99 Names to a pool of 12 unique verses; the AI prompt forbids unapproved verses and the parser (`normalizeApprovedVerses`) silently drops them. Fix is data-only: source ≥2 verses per remaining 84 Names, add `const ReflectVerse` declarations, extend the `approvedReflectVersesByName` map. The AI prompt picks up new coverage automatically via `buildApprovedVersePrompt()`.

**Tech Stack:** Dart constants, `flutter_test`, iOS Simulator MCP (`mcp__ios-simulator__*`). Repo convention: user builds/installs, assistant drives UI.

**Depends on:** Plan 0 (`allahNames` backfill + reflect eval foundation) must land first. Without Plan 0, `findCanonicalName` will reject AI responses for 83 of the 99 Names, breaking the verse-lookup chain.

---

## File Structure

- Modify: `lib/services/ai_service.dart` — remove `buildApprovedVersePrompt()` injection from `buildSystemPrompt` (Task 0). The AI returns Name only; the code looks up verses deterministically via `normalizeApprovedVerses` fallback.
- Modify: `lib/features/reflect/data/reflection_verse_catalog.dart` — add 60–80 new `const ReflectVerse` entries and extend the map to cover all 99 canonical transliterations.
- Create: `test/features/reflect/reflection_verse_catalog_coverage_test.dart` — coverage assertions.
- Create: `docs/qa/reflection-verse-sources.md` — per-Name verse source ledger with two reviewer columns.

---

### Task 0.5: Rename legacy "Quran N:N" references to canonical surah names

Five existing entries in `reflection_verse_catalog.dart:47-84` use a `Quran N:N` prefix instead of the actual surah name. They render as "Quran 2:201" in the UI when they should render as "Al-Baqarah 2:201". Fix before bulk-authoring new entries.

**Renames required:**

| Constant | Current | Rename to |
|---|---|---|
| `_repentanceVerse` | Quran 7:23 | Al-A'raf 7:23 |
| `_believersMercyVerse` | Quran 59:10 | Al-Hashr 59:10 |
| `_goodWorldsVerse` | Quran 2:201 | Al-Baqarah 2:201 |
| `_acceptanceVerse` | Quran 2:127 | Al-Baqarah 2:127 |
| `_protectionVerse` | Quran 2:255 | Al-Baqarah 2:255 |

- [ ] **Step 1: Edit each `const ReflectVerse` reference field**

In `lib/features/reflect/data/reflection_verse_catalog.dart`, change the 5 entries above. The "references start with a surah name, NOT 'Quran'" test in Task 1 pins this; it fails before this task and passes after.

- [ ] **Step 2: Run the coverage test**

Run: `flutter test test/features/reflect/reflection_verse_catalog_coverage_test.dart`
Expected: the surah-not-Quran assertion now passes (other assertions still RED).

- [ ] **Step 3: Commit**

```bash
git add lib/features/reflect/data/reflection_verse_catalog.dart
git commit -m "fix(reflect): rename 5 legacy 'Quran N:N' references to canonical surah names"
```

---

### Task 0: Drop approved-verses block from AI prompt

**Files:**
- Modify: `lib/services/ai_service.dart` (`buildSystemPrompt` around line 148-156)
- Modify: `test/features/reflect/` — add a prompt-shape regression test

**Why:** After bulk-adding ~80 new verses, `buildApprovedVersePrompt()` would inflate every reflect call's input by ~10KB. The existing `normalizeApprovedVerses` fallback in `reflection_verse_catalog.dart:138-143` already pulls catalog verses when the AI returns nothing. Let the AI pick the Name; let the code pick the verses. Smaller prompts, no verse hallucination, deterministic refs.

- [ ] **Step 1: Write a failing prompt-shape test**

Create `test/features/reflect/system_prompt_shape_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/ai_service.dart';

void main() {
  test('system prompt does not contain approved-verse enumeration', () {
    final prompt = buildSystemPrompt();
    expect(prompt.contains('## Approved Quran Verses'), isFalse,
        reason: 'verse list belongs in code, not prompt');
    expect(prompt.contains('VERSE_1_AR'), isFalse,
        reason: 'AI no longer returns verses');
  });

  test('parser response shape no longer requires verse fields', () {
    // Confirms that parseReflectResponse populates verses purely from catalog fallback.
    final response = parseReflectResponse(
      '##NAME## Al-Lateef\n'
      '##NAME_AR## اللطيف\n'
      '##REFRAME## Reframe text\n'
      '##STORY## Story text\n'
      '##DUA_AR## Dua\n'
      '##DUA_TR## Dua\n'
      '##DUA_EN## Dua\n'
      '##DUA_SOURCE## Source\n'
      '##RELATED## Al-Hakeem (الحكيم)',
    );
    expect(response, isNotNull);
    expect(response!.verses, isNotEmpty,
        reason: 'verses must come from catalog fallback');
  });
}
```

Run: `flutter test test/features/reflect/system_prompt_shape_test.dart`
Expected: FAIL (prompt still contains the verse block).

- [ ] **Step 2: Strip the verse block from the prompt**

In `lib/services/ai_service.dart` `buildSystemPrompt`:

- Delete the `final approvedVerseClause = buildApprovedVersePrompt();` line.
- Remove `$approvedVerseClause` from the returned string.
- Remove the `##VERSE_*` markers from the Response Format section.
- Remove the rule line about verses coming from the approved list.
- Keep `_parseReflectVerses` and `normalizeApprovedVerses` calls in `parseReflectResponse` — they still work because `normalizeApprovedVerses` falls back to the catalog when AI returns no verses.

- [ ] **Step 3: Run prompt-shape test**

Run: `flutter test test/features/reflect/system_prompt_shape_test.dart`
Expected: PASS.

- [ ] **Step 4: Run full reflect suite**

Run: `flutter test test/features/reflect/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/ai_service.dart test/features/reflect/system_prompt_shape_test.dart
git commit -m "refactor(reflect): drop verse list from AI prompt; catalog is source of truth"
```

---

### Task 1: Add coverage test (RED)

**Files:**
- Create: `test/features/reflect/reflection_verse_catalog_coverage_test.dart`

- [ ] **Step 1: Write the failing test**

Plan 0 backfills `allahNames` from `collectible_names.json` (98 attribute entries, excluding "Allah"). This test cross-checks both sources AND verifies verse coverage 1:1 with the attribute list.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/features/reflect/data/reflection_verse_catalog.dart';

List<Map<String, dynamic>> _canonicalRows() {
  final raw = File('assets/content/collectible_names.json').readAsStringSync();
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

void main() {
  group('reflection verse catalog coverage', () {
    final canonical = _canonicalRows()
        .where((r) => r['id'] != 1) // skip "Allah" — proper Name, not attribute
        .map((r) => r['transliteration'] as String)
        .toList();

    test('allahNames mirrors collectible_names.json transliterations (excluding Allah)', () {
      final fromJson = canonical.toSet();
      final fromDart = allahNames.map((n) => n.transliteration).toSet();
      expect(fromDart, equals(fromJson),
          reason: 'allahNames and collectible_names.json must agree '
              '(excluding the proper Name "Allah"). Run Plan 0 first.');
    });

    test('every canonical attribute Name has >=2 approved verses', () {
      final missing = <String>[];
      for (final t in canonical) {
        final verses = approvedReflectVersesByName[t] ?? const [];
        if (verses.length < 2) missing.add(t);
      }
      expect(missing, isEmpty,
          reason: 'Names lacking >=2 verses: $missing');
    });

    test('every verse has non-empty arabic, translation, reference', () {
      for (final entry in approvedReflectVersesByName.entries) {
        for (final v in entry.value) {
          expect(v.arabic.trim(), isNotEmpty, reason: entry.key);
          expect(v.translation.trim(), isNotEmpty, reason: entry.key);
          expect(v.reference.trim(), isNotEmpty, reason: entry.key);
        }
      }
    });

    test('references start with a surah name, NOT "Quran"', () {
      // Five legacy entries (_repentanceVerse 7:23, _believersMercyVerse 59:10,
      // _goodWorldsVerse 2:201, _acceptanceVerse 2:127, _protectionVerse 2:255)
      // use "Quran N:N" prefix. They render as "Quran 2:201" in the UI when
      // they should render as "Al-Baqarah 2:201". Task 0.5 renames them.
      for (final entry in approvedReflectVersesByName.entries) {
        for (final v in entry.value) {
          expect(v.reference.startsWith('Quran '), isFalse,
              reason: '${entry.key} -> "${v.reference}" — use surah name, not the literal "Quran"');
        }
      }
    });

    test('references match "Surah N:N" format', () {
      final ref = RegExp(r"^[A-Za-z'\-]+(\s[A-Za-z'\-]+)*\s\d+:\d+(-\d+)?$");
      for (final entry in approvedReflectVersesByName.entries) {
        for (final v in entry.value) {
          expect(ref.hasMatch(v.reference), isTrue,
              reason: '${entry.key} -> "${v.reference}"');
        }
      }
    });

    test('normalizeApprovedVerses fallback returns >=2 for every Name', () {
      for (final t in canonical) {
        final out = normalizeApprovedVerses(t, const []);
        expect(out.length, greaterThanOrEqualTo(2),
            reason: 'fallback for $t');
      }
    });

    test('normalizeApprovedVerses with an unknown Name returns demo verses, not empty', () {
      // If the AI ever returns a hallucinated Name that survives canonical resolution,
      // the reflect card should still show at least 2 verses — never blank.
      final out = normalizeApprovedVerses('Al-FabricatedName', const []);
      expect(out.length, greaterThanOrEqualTo(2),
          reason: 'unknown-name fallback must produce verses; today returns []. '
              'Patch normalizeApprovedVerses to default to a small "always-safe" '
              'verse pair (e.g. _heartsRestVerse + _noBurdenVerse) when the name '
              'key is not in approvedReflectVersesByName.');
    });
  });
}
```

The map key is the transliteration **exactly as written in `collectible_names.json`** —
mismatched spellings (e.g. `Al-Lateef` vs `Al-Latif`) will count as missing. When adding
new entries in Task 3, copy the transliteration verbatim from the JSON.

- [ ] **Step 2: Run test to confirm RED**

Run: `flutter test test/features/reflect/reflection_verse_catalog_coverage_test.dart`
Expected: FAIL on "Names lacking >=2 verses" listing the missing 84.

- [ ] **Step 3: Commit the failing test**

```bash
git add test/features/reflect/reflection_verse_catalog_coverage_test.dart
git commit -m "test(reflect): pin verse coverage to >=2 per Name (RED)"
```

---

### Task 2: Scaffold the source ledger

**Files:**
- Create: `docs/qa/reflection-verse-sources.md`

- [ ] **Step 1: Create the ledger**

```markdown
# Reflection Verse Source Ledger

Every verse mapped in `lib/features/reflect/data/reflection_verse_catalog.dart`
must have a row here. Arabic copied from a primary mushaf source.
English translation must match Sahih International unless noted.

Two reviewer initials required per row:
- TR = translation reviewer (verifies Arabic + English fidelity)
- TH = theme reviewer (verifies the verse fits the Name)

| Name | Verse Ref | Arabic Source | Translation Source | Theme | TR | TH | Date |
|------|-----------|---------------|--------------------|-------|----|----|------|
| Allah | Al-Fatiha 1:1 | quran.com | Sahih International | The unique Name | — | — | — |
| Ar-Rahman | Ar-Rahman 55:13 | quran.com | Sahih International | Universal favors | — | — | — |

(One row per canonical attribute Name from `assets/content/collectible_names.json` — 98 total, excluding id=1 "Allah" which is the proper Name not an attribute.)
```

Fill in all 98 attribute Name rows with empty reviewer cells; rows will get reviewer initials in Task 3.

**Ledger completeness test (add to `test/features/reflect/reflection_verse_catalog_coverage_test.dart`):**

```dart
test('every canonical attribute Name has filled TR and TH initials in ledger', () {
  final ledger = File('docs/qa/reflection-verse-sources.md').readAsStringSync();
  final lines = ledger.split('\n');
  final missing = <String>[];
  for (final t in canonical) {
    // Find the row for this Name. Match by name followed by pipe.
    final row = lines.firstWhere(
      (l) => l.startsWith('| $t '),
      orElse: () => '',
    );
    if (row.isEmpty) {
      missing.add('$t (no row)');
      continue;
    }
    final cells = row.split('|').map((c) => c.trim()).toList();
    // Format: | Name | Verse Ref | Arabic Source | Translation Source | Theme | TR | TH | Date |
    final tr = cells.length > 6 ? cells[6] : '';
    final th = cells.length > 7 ? cells[7] : '';
    if (tr.isEmpty || tr == '—' || th.isEmpty || th == '—') {
      missing.add('$t (TR="$tr", TH="$th")');
    }
  }
  expect(missing, isEmpty,
      reason: 'Ledger rows missing reviewer initials: $missing');
});
```

This gates merge on the scholarly-review step actually happening.

- [ ] **Step 2: Commit the ledger scaffold**

```bash
git add docs/qa/reflection-verse-sources.md
git commit -m "docs(qa): scaffold reflection verse source ledger"
```

---

### Task 3: Author verses, batch of 10 (GREEN, repeat 9 times)

For each iteration, work on 10 Names that don't yet appear in `approvedReflectVersesByName`. Do NOT skip the review step.

- [ ] **Step 1: Pick 10 uncovered Names**

Open `lib/features/reflect/data/reflection_verse_catalog.dart`. Identify 10 Names from `assets/content/collectible_names.json` whose transliteration is not a key in the map.

- [ ] **Step 2: Source ≥2 verses per Name**

For each Name, find verses that either explicitly mention the Name (preferred) or thematically express its meaning. Use quran.com or tanzil.net to cross-check Surah/ayah numbers and copy Arabic with full diacritics. Use Sahih International English unless the row notes otherwise.

- [ ] **Step 3: Add `const ReflectVerse` declarations**

Example pattern at the top of `reflection_verse_catalog.dart`:

```dart
const ReflectVerse _allKnowingVerse = ReflectVerse(
  arabic: 'وَهُوَ الْعَلِيمُ الْحَكِيمُ',
  translation: 'And He is the Knowing, the Wise.',
  reference: 'At-Tahrim 66:2',
);
```

If a verse already exists in the file under a different `_xxxVerse` name, reuse it rather than duplicate.

- [ ] **Step 4: Extend the map for those 10 Names**

```dart
const Map<String, List<ReflectVerse>> approvedReflectVersesByName = {
  // existing entries unchanged...
  'Al-Aleem': [_allKnowingVerse, _heartsRestVerse],
  // 9 more rows...
};
```

- [ ] **Step 5: Fill ledger rows**

In `docs/qa/reflection-verse-sources.md`, fill in TR + TH initials and the date for those 10 rows. The two reviewers must be different people; if you're solo-driving, mark TR/TH with the scholar's initials whose source you cross-referenced.

- [ ] **Step 6: Run analyzer + coverage test**

Run: `flutter analyze lib/features/reflect/data/reflection_verse_catalog.dart`
Expected: no warnings.

Run: `flutter test test/features/reflect/reflection_verse_catalog_coverage_test.dart`
Expected: same test still RED but with 10 fewer missing names. After 9 batches, GREEN.

- [ ] **Step 7: Commit the batch**

```bash
git add lib/features/reflect/data/reflection_verse_catalog.dart docs/qa/reflection-verse-sources.md
git commit -m "feat(reflect): add approved verses for batch N/9 ([Name1, Name2, ...])"
```

Repeat Task 3: **8 batches of 10 Names + 1 final batch of 4 Names = 9 iterations covering 84 Names** (98 attribute Names minus the 14 already mapped pre-Task-3). Verify by running the coverage test after each batch.

---

### Task 3.5: Add the unknown-name safety net in `normalizeApprovedVerses`

The new test "unknown Name returns demo verses, not empty" will fail until the function has a final fallback. Plan 1 should ensure no Name ever produces a verseless card.

**Files:**
- Modify: `lib/features/reflect/data/reflection_verse_catalog.dart` (around line 138)

- [ ] **Step 1: Add the final fallback**

```dart
List<ReflectVerse> normalizeApprovedVerses(
  String name,
  List<ReflectVerse> verses,
) {
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
  // Fires a debugPrint so production monitoring can surface persistent mismatches —
  // a steady stream of these means the AI is returning a non-canonical spelling.
  assert(() {
    // ignore: avoid_print
    print('[reflect_verse] WARN: unknown-name fallback fired for "$name". '
        'Check AI prompt + canonical-names list for spelling mismatch.');
    return true;
  }());
  return const [_heartsRestVerse, _noBurdenVerse];
}
```

- [ ] **Step 2: Run the unknown-name test**

Run: `flutter test test/features/reflect/reflection_verse_catalog_coverage_test.dart`
Expected: PASS, including the "unknown Name returns demo verses" assertion.

- [ ] **Step 3: Commit**

```bash
git add lib/features/reflect/data/reflection_verse_catalog.dart
git commit -m "fix(reflect): unknown-name fallback in normalizeApprovedVerses prevents verseless cards"
```

---

### Task 4: Full test suite green

- [ ] **Step 1: Run all reflect tests**

Run: `flutter test test/features/reflect/`
Expected: PASS, all 4 coverage assertions green.

- [ ] **Step 2: Run the full project test suite**

Run: `flutter test`
Expected: PASS. No regression (verse catalog is read only by AI service prompt-building).

---

### Task 5: iOS Simulator MCP — verses render across coverage

**Pre-step (user):** user runs `flutter run -d <ios-simulator> --dart-define-from-file=env.json` to install dev build. Per repo convention, user builds/installs; assistant drives UI via MCP.

For each of 6 spread-out Names (Al-Lateef, Al-Aleem, As-Sami, Al-Wadud, Al-Hafeez, Al-Wakeel):

- [ ] **Step 1: Locate sim + launch app**

```
mcp__ios-simulator__get_booted_sim_id
mcp__ios-simulator__launch_app   bundleId=com.sakina.app.sakina
```

- [ ] **Step 2: Navigate to reflect screen**

```
mcp__ios-simulator__ui_describe_all          # locate "Reflect" / home check-in entry
mcp__ios-simulator__ui_tap                   # tap that element
```

- [ ] **Step 3: Enter target phrase**

| Name | Phrase to type |
|---|---|
| Al-Lateef | "I feel like nothing in my life makes sense right now." |
| Al-Aleem | "I'm scared no one understands what I'm going through." |
| As-Sami | "I keep crying alone and feel unheard." |
| Al-Wadud | "I feel unloved and disposable." |
| Al-Hafeez | "I'm terrified something will happen to my family." |
| Al-Wakeel | "I can't carry work, kids, and money all at once." |

```
mcp__ios-simulator__ui_type   text="<phrase>"
mcp__ios-simulator__ui_tap    # submit button
mcp__ios-simulator__ui_view   # wait ~6s for response
```

- [ ] **Step 4: Assert verse rendered**

```
mcp__ios-simulator__screenshot
mcp__ios-simulator__ui_describe_all
```

Inspect snapshot:
- Result card shows a Name (Arabic + transliteration).
- ≥1 verse block contains Arabic + English + a "Surah N:N" reference.

If a card returns without a verse, the underlying Name needs verses added (back to Task 3).

- [ ] **Step 5: Log result**

Append to `docs/qa/reflection-verse-sources.md`:

```markdown
## Simulator verification 2026-05-XX

| Name | Got Name? | Got Arabic? | Got Translation? | Got Reference? | Pass |
|------|-----------|-------------|------------------|----------------|------|
| Al-Lateef | y | y | y | y | ✅ |
... 5 more rows ...
```

- [ ] **Step 6: Commit log**

```bash
git add docs/qa/reflection-verse-sources.md
git commit -m "docs(qa): record reflect verse simulator pass 2026-05-XX"
```

---

### Task 6: Reflect eval — no regression

Plan 0 created `test/evals/reflect_name_pick_eval.dart` + a baseline. Plan 1 changes the AI prompt substantively (Task 0 drop, plus the catalog now drives verses), so re-run the eval.

- [ ] **Step 1: Run eval against new code**

Run: `RUN_LIVE_EVALS=1 flutter test test/evals/reflect_name_pick_eval.dart`
Expected: pass rate ≥ Plan 0 baseline.

- [ ] **Step 2: If pass rate dropped, inspect**

Open `test/evals/reflect_name_pick_last_run.json`. For each newly-failing row, decide:
- The new Name is a theologically valid alternative → update baseline.
- The new Name is a regression → fix the prompt OR add explicit handling for that phrase.

- [ ] **Step 3: Update baseline (only if improvements, not regressions)**

```bash
cp test/evals/reflect_name_pick_last_run.json test/evals/reflect_name_pick_baseline.json
git add test/evals/reflect_name_pick_baseline.json
git commit -m "test(evals): update reflect baseline post-Plan-1"
```

---

### Task 7: PR

- [ ] **Step 1: Push and open PR**

```bash
git push origin <branch>
gh pr create --title "Expand reflection verse catalog to all 99 Names" --body "$(cat <<'EOF'
## Summary
- Adds >=2 scholar-verified Quran verses per canonical Name in `reflection_verse_catalog.dart`.
- Coverage 99/99 (was 15/99); reflect cards no longer render verseless.
- Drops the approved-verses enumeration from the AI prompt (Task 0); catalog is the deterministic source of truth — ~10KB lighter prompt per call.
- Reflect eval pass rate held against Plan 0 baseline.
- Source ledger with reviewer initials in `docs/qa/reflection-verse-sources.md`.

## Depends on
- Plan 0 (allahNames backfill + reflect eval foundation) must merge first.

## Test plan
- [x] `flutter test test/features/reflect/` PASS
- [x] `flutter test` PASS
- [x] `RUN_LIVE_EVALS=1 flutter test test/evals/reflect_name_pick_eval.dart` PASS
- [x] iOS simulator MCP run: 6 Names rendered with verses; log in QA doc.
EOF
)"
```
