# NameTeaching Corpus Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Grow `lib/core/constants/knowledge_base.dart` from ~48 entries / 38 keys → full 99 canonical Name coverage, so every canonical Name has emotional context tags, a prophetic story, and a dua available to the AI reflection prompt. Especially the lesser-known Names (Al-Muqtadir, Al-Jami', Al-Mani', Adh-Dharr, etc.) that are currently invisible to `getRelevantTeachings()`.

**Pre-work (blocks Task 1 RED→GREEN):**
1. **Lowercase 47 existing `emotionalContext` strings** (or relax the assertion). Today entries like `"feeling unworthy of Allah's love"` (capital A in Allah) and `"sacrificing prayers or Islam for career"` (capital I) violate the lowercase rule. Decision: lowercase them all (matcher already lowercases userText before matching — `"allah"` vs `"Allah"` doesn't affect matching). Do this in Task 1 Step 0 before the RED test runs.
2. **Compound-key transliterations don't match canonical.** Today's teaching keys like `Al-Basir`, `Al-Karim`, `Al-Latif` won't match canonical JSON entries `Al-Baseer`, `Al-Kareem`, `Al-Lateef`. Plan must normalize both sides through `findCanonicalName()` (Plan 0 makes this trustworthy).

**Architecture:** `knowledge_base.dart` exposes a list of `NameTeaching` objects keyed by Name (sometimes compound, e.g. "Ar-Rahman" or "Al-Wahid / Al-Ahad"). `getRelevantTeachings(userText)` matches a teaching when any string in `emotionalContext` appears in `userText.toLowerCase()`. The AI service builds a "Teaching Reference" block in the system prompt from those matches (`ai_service.dart:489-500`). Adding teachings broadens which Names the AI can surface for a given user feeling. Fix is data-only — no schema change.

**Tech Stack:** Dart constants, `flutter_test`, iOS Simulator MCP.

---

## File Structure

- Modify: `lib/core/constants/knowledge_base.dart` — (a) lowercase 47 existing `emotionalContext` strings; (b) rewrite compound-key transliterations to canonical spellings OR rely on `findCanonicalName` normalization (see Task 1); (c) add ~50 new `NameTeaching` entries covering Names not yet present.
- Create: `test/core/constants/knowledge_base_coverage_test.dart` — coverage + shape assertions, normalized through `findCanonicalName`.
- Create: `docs/qa/name-teaching-sources.md` — per-teaching source ledger with `Story Type` (Quran/Hadith) + `Grade` (N/A for Quran, sahih/hasan for hadith) + reviewer initials.

**Depends on:** Plan 0 (allahNames backfill — makes `findCanonicalName` trustworthy across all 98 attribute Names).

---

### Task 1: Add coverage test (RED)

**Files:**
- Create: `test/core/constants/knowledge_base_coverage_test.dart`

- [ ] **Step 0: Lowercase existing `emotionalContext` strings (pre-work)**

Before the RED coverage test can fail for the RIGHT reason (missing Names) instead of the wrong reason (existing capital letters), lowercase all `emotionalContext` strings in `knowledge_base.dart`. The matcher already does `userText.toLowerCase().contains(ctx)` so this is a no-op for behavior but unblocks the test.

Run a one-shot sed/dart script across the file, focused on the `emotionalContext: [...]` arrays. Then commit as a separate "chore" commit before Step 1:

```bash
git commit -m "chore(knowledge): lowercase emotionalContext strings (no-op for matcher, pins test invariant)"
```

- [ ] **Step 1: Write the failing test**

`nameTeachings` is **already exported** as `const List<NameTeaching> nameTeachings` at `knowledge_base.dart:81`. No re-export work needed.

The coverage test normalizes BOTH sides through `findCanonicalName` so spelling drift (`Al-Basir` vs `Al-Baseer`) doesn't masquerade as missing coverage.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/knowledge_base.dart';
import 'package:sakina/services/validate_names.dart';

/// Canonical names that have no `NameTeaching` AND legitimately don't need one
/// (e.g. "Allah" the proper Name vs. the 98 attributes). Empty for now; add as needed.
const Set<String> _intentionallyUncovered = {'Allah'};

List<String> _canonicalTransliterations() {
  final raw = File('assets/content/collectible_names.json').readAsStringSync();
  return (jsonDecode(raw) as List)
      .cast<Map<String, dynamic>>()
      .map((n) => n['transliteration'] as String)
      .toList();
}

String? _canonicalize(String s) {
  final hit = findCanonicalName(s);
  return hit?.name;
}

void main() {
  group('knowledge_base NameTeaching coverage', () {
    final teachings = nameTeachings;
    final canonical = _canonicalTransliterations();

    test('every canonical Name (except intentionally uncovered) appears in some teaching key, normalized', () {
      // A teaching key may be a single Name ("Al-Lateef") or a compound
      // ("Al-Wahid / Al-Ahad" or "Al-Dhahir & Al-Batin"). Split on both separators.
      final keyedCanonical = <String>{};
      final unresolvedKeys = <String>[];
      for (final t in teachings) {
        for (final part in t.name.split(RegExp(r'\s*[/&]\s*'))) {
          final p = part.trim();
          final c = _canonicalize(p);
          if (c != null) {
            keyedCanonical.add(c);
          } else {
            unresolvedKeys.add(p);
          }
        }
      }

      // Surface any teaching key parts that don't resolve to a canonical Name —
      // either they're misspelled or they're non-99 honorifics (Ar-Rabb, Al-Qarib).
      // We don't fail on these; we report them so they can be migrated.
      if (unresolvedKeys.isNotEmpty) {
        // ignore: avoid_print
        print('NOTE: ${unresolvedKeys.length} teaching key parts do not resolve to '
            'a canonical Name: $unresolvedKeys. Consider migrating or removing.');
      }

      final missing = <String>[];
      for (final t in canonical) {
        if (_intentionallyUncovered.contains(t)) continue;
        if (!keyedCanonical.contains(t)) missing.add(t);
      }
      expect(missing, isEmpty,
          reason: 'Canonical Names without a NameTeaching: $missing');
    });

    test('each teaching has emotionalContext >=3', () {
      for (final t in teachings) {
        expect(t.emotionalContext.length, greaterThanOrEqualTo(3),
            reason: t.name);
      }
    });

    test('each teaching has non-empty arabic, coreTeaching, propheticStory, dua', () {
      for (final t in teachings) {
        expect(t.arabic.trim(), isNotEmpty, reason: t.name);
        expect(t.coreTeaching.trim(), isNotEmpty, reason: t.name);
        expect(t.propheticStory.trim(), isNotEmpty, reason: t.name);
        expect(t.dua.arabic.trim(), isNotEmpty, reason: t.name);
        expect(t.dua.transliteration.trim(), isNotEmpty, reason: t.name);
        expect(t.dua.translation.trim(), isNotEmpty, reason: t.name);
        expect(t.dua.source.trim(), isNotEmpty, reason: t.name);
      }
    });

    test('every emotionalContext entry is lowercase (matcher uses .toLowerCase())', () {
      // Run Step 0 first — this fails today against 47 existing strings until they're lowercased.
      for (final t in teachings) {
        for (final e in t.emotionalContext) {
          expect(e, equals(e.toLowerCase()), reason: '${t.name} -> $e');
        }
      }
    });
  });
}
```

- [ ] **Step 2: Run**

Run: `flutter test test/core/constants/knowledge_base_coverage_test.dart`
Expected: FAIL on Names without a teaching, ~50 missing.

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/knowledge_base.dart test/core/constants/knowledge_base_coverage_test.dart
git commit -m "test(knowledge): pin NameTeaching coverage to all 99 (RED)"
```

---

### Task 2: Source ledger

**Files:**
- Create: `docs/qa/name-teaching-sources.md`

- [ ] **Step 1: Scaffold ledger**

```markdown
# NameTeaching Source Ledger

Each teaching in `lib/core/constants/knowledge_base.dart` requires a row here.
Prophetic stories must come from Quran or sahih/hasan hadith — never fabricated.

`Story Type` is Quran or Hadith.
`Grade` only applies to hadith (sahih/hasan); for Quran rows write `N/A (Quran sura:ayah)`.

| Name | Story Type | Story Source | Grade | Dua Source | Dua Grade | Reviewer | Date |
|------|------------|--------------|-------|------------|-----------|----------|------|
```

Pre-populate one row per missing Name (~50 rows).

- [ ] **Step 2: Commit**

```bash
git add docs/qa/name-teaching-sources.md
git commit -m "docs(qa): scaffold NameTeaching source ledger"
```

---

### Task 3: Author teachings, batch of 10 (GREEN, repeat 5 times)

For each batch:

- [ ] **Step 1: Pick 10 uncovered Names**

Cross-reference `allahNames` from `lib/core/constants/allah_names.dart` against existing `nameTeachings`. Pick 10 not yet covered.

- [ ] **Step 2: For each, source content**

Required content per Name:
- `arabic` — copy from canonical list.
- `emotionalContext` — ≥3 lowercase short phrases users might type, e.g. `['feeling unseen', 'invisible', 'no one notices']`.
- `coreTeaching` — 2–4 sentences on what the Name means and when to invoke it.
- `propheticStory` — 3–6 sentences referencing a real Quranic narrative or sahih hadith. Cite the surah/ayah or collection in the story text.
- `dua` — `DuaContent(arabic, transliteration, translation, source)` from a sahih/hasan source.

- [ ] **Step 3: Add `NameTeaching` entries**

Match the existing pattern in `knowledge_base.dart`. The dua type is `NameTeachingDua` (not `DuaContent`) with **named** constructor args:

```dart
const NameTeaching(
  name: 'Al-Muqtadir',
  arabic: 'الْمُقْتَدِرُ',
  emotionalContext: [
    'feeling powerless',
    'nothing i do matters',
    'overwhelmed by circumstances',
  ],
  coreTeaching:
      'Al-Muqtadir is The All-Powerful, the One whose decree nothing escapes. '
      'When the world feels arbitrary and you small inside it, His power is '
      'precise — your situation is not random, even when it is hard.',
  propheticStory:
      'When Pharaoh chased Musa (AS) to the sea, the people cried out, "We are '
      'overtaken!" Musa said: "Never! My Lord is with me; He will guide me." '
      'Then Allah commanded the sea to split (Quran 26:61-63). Al-Muqtadir bent '
      'the laws of the world for a man who chose to trust Him.',
  dua: NameTeachingDua(
    arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    transliteration: 'Hasbuna-llahu wa ni\'ma al-wakeel',
    translation: 'Allah is sufficient for us, and He is the best disposer of affairs.',
    source: 'Quran 3:173',
  ),
),
```

- [ ] **Step 4: Fill ledger**

10 rows in `docs/qa/name-teaching-sources.md` with story grade + dua grade + reviewer initials.

- [ ] **Step 5: Run analyzer + tests**

Run: `flutter analyze lib/core/constants/knowledge_base.dart`
Expected: clean.

Run: `flutter test test/core/constants/knowledge_base_coverage_test.dart`
Expected: still RED but 10 fewer missing. After 5 batches → GREEN.

- [ ] **Step 6: Commit**

```bash
git add lib/core/constants/knowledge_base.dart docs/qa/name-teaching-sources.md
git commit -m "feat(knowledge): add NameTeaching for batch N/5"
```

Repeat five times (50 ÷ 10 = 5 batches).

---

### Task 4: Behavior test — getRelevantTeachings surfaces new Names

**Files:**
- Modify: `test/core/constants/knowledge_base_coverage_test.dart` (add group)

- [ ] **Step 1: Add the test**

```dart
import 'package:sakina/core/constants/knowledge_base.dart' show getRelevantTeachings;

// inside main():
group('getRelevantTeachings surfaces formerly-uncovered Names', () {
  const probes = {
    'feeling powerless': 'Al-Muqtadir',
    'i feel scattered and pulled in every direction': 'Al-Jami',
    'i feel cut off from everyone': 'Al-Mani',
    // add more probes as new teachings land
  };
  probes.forEach((phrase, expectedName) {
    // Tightened: expected Name must be the TOP-1 returned teaching, not just
    // anywhere in the top-N list. Catches over-broad emotionalContext entries
    // that route a phrase to a different Name with similar tags.
    test('"$phrase" surfaces $expectedName as top-1', () {
      final teachings = getRelevantTeachings(phrase);
      expect(teachings, isNotEmpty,
          reason: 'phrase "$phrase" returned no teachings at all');
      expect(teachings.first.name.contains(expectedName), isTrue,
          reason: 'phrase "$phrase" top-1 was ${teachings.first.name}, expected $expectedName');
    });
  });
});
```

- [ ] **Step 2: Run**

Run: `flutter test test/core/constants/knowledge_base_coverage_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/core/constants/knowledge_base_coverage_test.dart
git commit -m "test(knowledge): getRelevantTeachings surfaces new Names"
```

---

### Task 5: Full suite green + AI prompt sanity-check

- [ ] **Step 1: Full test run**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 2: Manual prompt inspection**

Add a temporary debug test (don't commit) that builds the system prompt via `buildSystemPrompt(teachingContext: _buildTeachingContext('feeling powerless'))` and prints it. Confirm the new teaching shows up in the "Teaching Reference" block of the prompt.

```dart
// Run once locally, then delete:
test('debug prompt', () {
  final ctx = /* call private _buildTeachingContext via small @visibleForTesting wrapper */;
  print(ctx);
});
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`
Expected: clean. No unused imports.

---

### Task 6: iOS Simulator MCP — reflect surfaces previously-uncovered Names

**Pre-step (user):** `flutter run -d <ios-simulator> --dart-define-from-file=env.json`.

Pick 6 Names that were previously NOT in the teaching corpus (use the ledger to verify). For each:

- [ ] **Step 1: Boot + launch**

```
mcp__ios-simulator__get_booted_sim_id
mcp__ios-simulator__launch_app   bundleId=com.sakina.app.sakina
```

- [ ] **Step 2: Navigate to reflect entry**

```
mcp__ios-simulator__ui_describe_all
mcp__ios-simulator__ui_tap
```

- [ ] **Step 3: Type a phrase aligned to a probed emotional context**

Use phrases drawn from the new teaching's `emotionalContext` array. Examples:

| Target Name | Phrase |
|---|---|
| Al-Muqtadir | "I feel powerless — nothing I do changes anything" |
| Al-Jami | "I feel scattered, pulled in every direction" |
| Al-Mani | "I keep getting blocked from every path I try" |
| Adh-Dharr | "I'm afraid of what's happening to me" |
| An-Nafi | "I need something good to come out of this" |
| Al-Wahhab | "I have nothing to offer anyone right now" |

```
mcp__ios-simulator__ui_type   text="<phrase>"
mcp__ios-simulator__ui_tap    # submit
mcp__ios-simulator__ui_view
mcp__ios-simulator__screenshot
```

- [ ] **Step 4: Assert returned Name matches target**

Inspect screenshot or `ui_describe_all` output for the Arabic + transliteration of the result. If the AI returned a different Name, that is acceptable provided the returned Name is also one of the newly-added teachings AND a thematic fit. The bar: at least 4 of 6 probes return a Name that was previously uncovered.

- [ ] **Step 5: Log to QA**

Append `## Simulator verification 2026-05-XX` table to `docs/qa/name-teaching-sources.md`.

- [ ] **Step 6: Commit**

```bash
git add docs/qa/name-teaching-sources.md
git commit -m "docs(qa): record NameTeaching simulator pass 2026-05-XX"
```

---

### Task 7: Reflect eval — verify new teachings improve, not regress

Plan 5 expands `getRelevantTeachings` coverage, which directly changes the "Teaching Reference" block in the system prompt for any matching phrase. Run the Plan 0 eval to detect regressions.

- [ ] **Step 1: Run eval**

Run: `RUN_LIVE_EVALS=1 flutter test test/evals/reflect_name_pick_eval.dart`
Expected: pass rate ≥ Plan 0 baseline.

- [ ] **Step 2: For fixture rows that now route to a NEW Name, decide**

Each newly-failing row needs a call:
- Old Name was acceptable, new Name is also acceptable → expand `expected_names` in the fixture (commit the change).
- New Name is a theologically better match → update baseline.
- New Name is a regression → patch the relevant teaching's `emotionalContext` to reduce false-positive matching.

- [ ] **Step 3: Update fixture/baseline if needed**

```bash
git add test/evals/reflect_name_pick_fixture.json test/evals/reflect_name_pick_baseline.json
git commit -m "test(evals): expand fixture / update baseline post-Plan-5"
```

---

### Task 8: PR

```bash
git push origin <branch>
gh pr create --title "Expand NameTeaching corpus to all 99 Names" --body "$(cat <<'EOF'
## Summary
- Grows `knowledge_base.dart` from 49 → 99 `NameTeaching` entries.
- Lesser-known Names (Al-Muqtadir, Al-Jami, Al-Mani, Adh-Dharr, An-Nafi, Al-Wahhab) now reachable via `getRelevantTeachings`.
- Reflect eval pass rate held against Plan 0 baseline.
- Source ledger in `docs/qa/name-teaching-sources.md` with story + dua grades + reviewer initials.

## Depends on
- Plan 0 (allahNames backfill + reflect eval foundation) must merge first.

## Test plan
- [x] `flutter test test/core/constants/knowledge_base_coverage_test.dart` PASS
- [x] `flutter test` PASS
- [x] `RUN_LIVE_EVALS=1 flutter test test/evals/reflect_name_pick_eval.dart` PASS
- [x] iOS simulator MCP: 4+ of 6 probes return previously-uncovered Names.
EOF
)"
```
