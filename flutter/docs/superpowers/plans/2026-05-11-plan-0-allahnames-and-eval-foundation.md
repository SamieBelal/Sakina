# Plan 0 — `allahNames` Backfill + Reflect Eval Foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unblock Plans 1–5 by (a) backfilling `lib/core/constants/allah_names.dart` from 16 → 99 entries so `findCanonicalName` resolves all canonical Names; (b) creating a shared LLM eval fixture that Plans 1, 2, 5 can run to detect Name-pick regressions when the AI prompt changes.

**Architecture:** Two independent foundations. (a) Port the 99 rows from `assets/content/collectible_names.json` into the Dart `allahNames` const list, preserving field order, so `validate_names.dart` rejects nothing real. (b) Stand up `test/evals/reflect_name_pick_eval.dart` with a ~25-row fixture (user phrase → expected Name set) and a baseline pass-rate file. Subsequent plans run the eval to confirm prompt changes don't regress quality.

**Tech Stack:** Dart constants, `flutter_test`, OpenAI key from `env.json` for live eval runs.

---

## File Structure

- Modify: `lib/core/constants/allah_names.dart` — grow `allahNames` from 16 → 99 entries via straight copy from `collectible_names.json`. Keep the `AllahName` class shape.
- Create: `test/core/constants/allah_names_coverage_test.dart` — pin 1:1 coverage with `collectible_names.json`.
- Create: `test/evals/reflect_name_pick_eval.dart` — fixture-based eval runner.
- Create: `test/evals/reflect_name_pick_fixture.json` — ~25 fixture rows: `{phrase, expected_names: [name1, name2, ...]}`.
- Create: `test/evals/reflect_name_pick_baseline.json` — pass-rate baseline + per-row pass status.
- Create: `docs/qa/reflect-eval-design.md` — fixture design rationale + how to update the baseline.

---

### Task 1: allahNames coverage test (RED)

**Files:**
- Create: `test/core/constants/allah_names_coverage_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/services/validate_names.dart';

void main() {
  group('allahNames canonical coverage', () {
    final raw = File('assets/content/collectible_names.json').readAsStringSync();
    final canonical = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    test('allahNames has 98 entries (99 canonical minus "Allah" the proper Name)', () {
      expect(allahNames.length, equals(98));
    });

    test('every collectible_names.json entry EXCEPT "Allah" is in allahNames', () {
      final present = allahNames.map((n) => n.transliteration).toSet();
      final missing = <String>[];
      for (final c in canonical) {
        if (c['id'] == 1) continue; // intentionally excluded — see Task 2
        if (!present.contains(c['transliteration'])) {
          missing.add(c['transliteration'] as String);
        }
      }
      expect(missing, isEmpty);
    });

    test('"Allah" is intentionally NOT in allahNames (proper name, not attribute)', () {
      final present = allahNames.map((n) => n.transliteration).toSet();
      expect(present.contains('Allah'), isFalse,
          reason: 'Allah is the proper Name; allahNames is the 98 attributes');
    });

    test('findCanonicalName resolves every canonical transliteration', () {
      for (final c in canonical) {
        final resolved = findCanonicalName(c['transliteration'] as String);
        expect(resolved, isNotNull,
            reason: 'findCanonicalName returned null for ${c['transliteration']}');
      }
    });

    test('arabic field matches the JSON 1:1', () {
      final byTransliteration = {
        for (final n in allahNames) n.transliteration: n.arabic,
      };
      for (final c in canonical) {
        expect(byTransliteration[c['transliteration']], equals(c['arabic']),
            reason: c['transliteration']);
      }
    });
  });
}
```

- [ ] **Step 2: Run to confirm RED**

Run: `flutter test test/core/constants/allah_names_coverage_test.dart`
Expected: FAIL — count 16/99.

- [ ] **Step 3: Commit**

```bash
git add test/core/constants/allah_names_coverage_test.dart
git commit -m "test(names): pin allahNames coverage to 99 (RED)"
```

---

### Task 2: Port the 99 entries (GREEN)

**Files:**
- Modify: `lib/core/constants/allah_names.dart`

- [ ] **Step 1: Generate the Dart entries from collectible_names.json**

Use a small one-shot script (not committed):

**ID handling decision:** `collectible_names.json` row id=1 is **"Allah"** (the proper Name), id=2 is Ar-Rahman. The existing `allah_names.dart` numbers Ar-Rahman as id=1. `getTodaysName()` (`allah_names.dart:142`) uses `allahNames[dayOfYear % allahNames.length]` — so if we keep id=1=Allah in the rotation, 1/99 days the home screen shows the generic proper Name rather than a daily attribute. **Decision: skip JSON id=1 ("Allah") and renumber sequentially 1-98 to preserve attribute-only rotation.** If you want Allah included, change the script and add a regression test pinning the rotation set.

```bash
python3 <<'EOF'
import json
data = json.load(open('assets/content/collectible_names.json'))
seq = 0
for n in data:
    if n['id'] == 1:  # skip "Allah" — proper name, not an attribute
        continue
    seq += 1
    arabic = n['arabic']
    transliteration = n['transliteration']
    english = n['english']
    meaning = n['meaning'].replace("'", "\\'")
    lesson = n['lesson'].replace("'", "\\'")
    print(f'''  AllahName(
    id: {seq},
    arabic: '{arabic}',
    transliteration: '{transliteration}',
    english: '{english}',
    meaning: '{meaning}',
    lesson: '{lesson}',
  ),''')
EOF
```

Paste the output into `allahNames` in `lib/core/constants/allah_names.dart`, replacing the existing 16-entry literal. Result: 98 attribute entries, sequential id 1-98. Update the coverage test in Task 1 to expect 98, not 99 — and to verify the canonical JSON file has 99 rows but "Allah" (id=1) is intentionally excluded.

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/core/constants/allah_names.dart`
Expected: clean. If string-escape errors appear (apostrophes in `meaning`/`lesson`), patch them by escaping `'` → `\'`.

- [ ] **Step 3: Run the coverage test**

Run: `flutter test test/core/constants/allah_names_coverage_test.dart`
Expected: PASS.

- [ ] **Step 4: Run full suite**

Run: `flutter test`
Expected: PASS. No regression elsewhere — `findCanonicalName` now resolves more inputs, which is strictly better.

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/allah_names.dart
git commit -m "feat(names): backfill allahNames to 99 entries from collectible_names.json"
```

---

### Task 3: Reflect eval fixture (~25 rows)

**Files:**
- Create: `test/evals/reflect_name_pick_fixture.json`
- Create: `docs/qa/reflect-eval-design.md`

- [ ] **Step 1: Author the fixture**

Each row: a natural user phrase + the set of Names that would be an acceptable response (usually 1–3 Names — a phrase often maps to a small thematic cluster, not exactly one Name). Rationale field is structured so future reviewers can adjudicate out-of-set returns consistently:

```json
[
  {
    "phrase": "I feel like nothing in my life makes sense right now",
    "expected_names": ["Al-Lateef", "Al-Hakeem", "Al-Khabeer"],
    "rationale": {
      "category": "hidden-wisdom / disorientation",
      "included_names": [
        {"name": "Al-Lateef", "why": "the gentle one whose plan unfolds invisibly"},
        {"name": "Al-Hakeem", "why": "the wise — every event has a reason"},
        {"name": "Al-Khabeer", "why": "the aware — sees what we can't"}
      ],
      "excluded_pattern": "Names of power/strength (Al-Qawi, Al-Aziz) — phrase is about confusion, not weakness"
    }
  },
  {
    "phrase": "I'm scared no one understands what I'm going through",
    "expected_names": ["Al-Aleem", "Al-Khabeer", "As-Sami", "Al-Baseer"],
    "rationale": {
      "category": "feeling-unseen / loneliness in pain",
      "included_names": [
        {"name": "Al-Aleem", "why": "the all-knowing — knows interior states"},
        {"name": "Al-Khabeer", "why": "the aware — knows the hidden"},
        {"name": "As-Sami", "why": "the all-hearing — hears unspoken cries"},
        {"name": "Al-Baseer", "why": "the all-seeing — witnesses every tear"}
      ],
      "excluded_pattern": "Forgiveness Names (Al-Ghaffar, At-Tawwab) — phrase is about being seen, not about sin"
    }
  }
]
```

Author 25 rows covering: anxiety, grief, gratitude, anger, loneliness, shame, hope, awe, repentance, longing, illness, parenting, work, relationship, doubt, fear, joy, exhaustion, jealousy, faith-struggle, family-conflict, financial-stress, decision-paralysis, mortality, peace.

- [ ] **Step 2: Document design in `docs/qa/reflect-eval-design.md`**

```markdown
# Reflect Name-Pick Eval

## Purpose
Detect AI Name-pick quality regressions when the system prompt changes
(Plans 1, 2, 5 in the 2026-05-11 content batch all change prompt content).

## Fixture shape
- 25 phrases spanning the emotional spectrum.
- Each phrase has an `expected_names` set (1-3 Names).
- A response PASSES the row if the returned Name is in the expected set.

## Baseline
`test/evals/reflect_name_pick_baseline.json` stores:
- `pass_rate`: float (e.g. 0.84 = 21 of 25 pass)
- `per_row_status`: array of {phrase, last_returned_name, pass}

## Update protocol
When a plan intentionally improves Name routing, run the eval, inspect failures,
update the baseline only if the failures are theologically defensible improvements.
Never update the baseline to mask a regression.
```

- [ ] **Step 3: Commit fixture + design**

```bash
git add test/evals/reflect_name_pick_fixture.json docs/qa/reflect-eval-design.md
git commit -m "feat(evals): reflect Name-pick fixture (25 rows) + design doc"
```

---

### Task 4: Eval runner

**Files:**
- Create: `test/evals/reflect_name_pick_eval.dart`

- [ ] **Step 1: Write the runner**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/core/env.dart';

/// Detect when reflectWithOpenAI fell back to the hardcoded demo response.
/// The demo is always Al-Lateef with a fixed reframe; if the API errors mid-run,
/// every row returns demo Al-Lateef, silently passing rows whose expected_names
/// include Al-Lateef and failing others. Treating demo as data poisons the baseline.
bool _isDemoFallback(ReflectResponse r) =>
    r.name == 'Al-Lateef' &&
    r.reframe.contains('Al-Lateef is The Subtle One');

void main() {
  // Hard-fail if eval is requested but the API key is missing — silent skips
  // led to empty baselines in past runs.
  if (Platform.environment['RUN_LIVE_EVALS'] == '1' && Env.openAiApiKey.isEmpty) {
    test('eval requested but OPENAI_API_KEY missing', () {
      fail('RUN_LIVE_EVALS=1 set but Env.openAiApiKey is empty. '
          'Run with: RUN_LIVE_EVALS=1 flutter test --dart-define-from-file=env.json test/evals/reflect_name_pick_eval.dart');
    });
    return;
  }

  // Default: skip cleanly when no live-eval flag set.
  if (Env.openAiApiKey.isEmpty ||
      Platform.environment['RUN_LIVE_EVALS'] != '1') {
    test('reflect eval (skipped, set RUN_LIVE_EVALS=1 + env.json)', () {});
    return;
  }

  group('reflect Name-pick eval', () {
    final fixture =
        jsonDecode(File('test/evals/reflect_name_pick_fixture.json').readAsStringSync())
            as List;
    final baselineFile = File('test/evals/reflect_name_pick_baseline.json');
    final baseline = baselineFile.existsSync()
        ? jsonDecode(baselineFile.readAsStringSync()) as Map<String, dynamic>
        : {'pass_rate': 0.0, 'per_row_status': []};

    test('pass rate >= baseline', () async {
      var passes = 0;
      final perRow = <Map<String, dynamic>>[];
      final demoRows = <String>[];
      for (final row in fixture.cast<Map<String, dynamic>>()) {
        final phrase = row['phrase'] as String;
        final expected = (row['expected_names'] as List).cast<String>().toSet();
        final response = await reflectWithOpenAI(phrase);

        // Hard fail if the live API fell back to demo — protects baseline integrity.
        if (_isDemoFallback(response)) {
          demoRows.add(phrase);
          continue;
        }

        final pass = expected.contains(response.name);
        if (pass) passes++;
        perRow.add({
          'phrase': phrase,
          'last_returned_name': response.name,
          'pass': pass,
        });
      }

      if (demoRows.isNotEmpty) {
        fail('reflectWithOpenAI fell back to demo response for ${demoRows.length} '
            'rows (e.g. "${demoRows.first}"). API likely errored mid-run. '
            'Baseline aborted to prevent corruption.');
      }

      final rate = passes / fixture.length;
      final baselineRate = (baseline['pass_rate'] as num).toDouble();

      // Write the updated row status for diffing — never auto-overwrite pass_rate.
      File('test/evals/reflect_name_pick_last_run.json').writeAsStringSync(
          jsonEncode({'pass_rate': rate, 'per_row_status': perRow}));

      expect(rate, greaterThanOrEqualTo(baselineRate),
          reason:
              'pass rate $rate < baseline $baselineRate. Inspect test/evals/reflect_name_pick_last_run.json.');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
```

- [ ] **Step 2: Establish baseline (post-Plan-0, pre-Plan-1 — canonical 99 in prompt, original prompt shape)**

The baseline captures behavior AFTER `allahNames` was backfilled (so the canonical-names list in the AI prompt is the full 98 attributes) but BEFORE Plans 1/2/5 change other prompt content. **Must pass env.json or the runner silently skips:**

Run: `RUN_LIVE_EVALS=1 flutter test --dart-define-from-file=env.json test/evals/reflect_name_pick_eval.dart`

Expected: runs 25 phrases, writes `test/evals/reflect_name_pick_last_run.json`. Verify the file exists and has all 25 rows before copying:

```bash
test -s test/evals/reflect_name_pick_last_run.json || { echo "ERROR: last_run.json empty/missing"; exit 1; }
jq '.per_row_status | length' test/evals/reflect_name_pick_last_run.json   # must print 25
cp test/evals/reflect_name_pick_last_run.json test/evals/reflect_name_pick_baseline.json
```

If the runner hard-failed on demo-fallback rows, the API is misbehaving — fix that before pinning a baseline. Don't paper over a flaky run.

- [ ] **Step 3: Commit eval runner + baseline**

```bash
git add test/evals/reflect_name_pick_eval.dart test/evals/reflect_name_pick_baseline.json
git commit -m "feat(evals): reflect Name-pick eval runner + initial baseline"
```

---

### Task 5: iOS Simulator MCP — sanity check that backfill doesn't regress reflect

**Pre-step (user):** `flutter run -d <ios-simulator> --dart-define-from-file=env.json`.

- [ ] **Step 1: Boot + launch, navigate to reflect**

```
mcp__ios-simulator__get_booted_sim_id
mcp__ios-simulator__launch_app   bundleId=com.sakina.app.sakina
mcp__ios-simulator__ui_describe_all
mcp__ios-simulator__ui_tap        # reflect entry
```

- [ ] **Step 2: Type a phrase whose answer USED to land outside the 16 (e.g. should hit Al-Aleem or Al-Wakeel)**

```
mcp__ios-simulator__ui_type   text="I feel completely overwhelmed by everything on my plate"
mcp__ios-simulator__ui_tap    # submit
mcp__ios-simulator__ui_view
mcp__ios-simulator__screenshot
```

- [ ] **Step 3: Confirm result card shows a canonical Name with no rendering glitches**

Before Plan 0: AI might return "Al-Wakeel" → `findCanonicalName('Al-Wakeel')` returns null (16-list doesn't include it) → raw string passes through → display works but downstream catalog lookups silently miss.

After Plan 0: same phrase → Al-Wakeel resolved → consistent transliteration → catalog lookups succeed.

- [ ] **Step 4: Commit any QA notes**

Append a "## Simulator verification 2026-05-XX" section to `docs/qa/reflect-eval-design.md`.

```bash
git add docs/qa/reflect-eval-design.md
git commit -m "docs(qa): record Plan 0 simulator verification"
```

---

### Task 6: PR

```bash
git push origin <branch>
gh pr create --title "Plan 0: backfill allahNames + reflect eval foundation" --body "$(cat <<'EOF'
## Summary
- `allahNames` Dart const goes from 16 → 99 entries, matching `collectible_names.json` 1:1. Fixes silent rejection of 83 canonical Names by `findCanonicalName`.
- Adds reflect Name-pick eval: 25-row fixture, eval runner (gated on `RUN_LIVE_EVALS=1`), initial baseline. Plans 1, 2, 5 will run this to detect prompt-change regressions.

## Test plan
- [x] `flutter test test/core/constants/allah_names_coverage_test.dart` PASS
- [x] `flutter test` PASS
- [x] `RUN_LIVE_EVALS=1 flutter test test/evals/reflect_name_pick_eval.dart` PASS — baseline pinned
- [x] iOS simulator MCP: reflect on previously-rejected Name routes correctly post-backfill
EOF
)"
```
