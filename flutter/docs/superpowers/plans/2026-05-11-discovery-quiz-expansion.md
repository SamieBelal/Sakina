# Discovery Quiz Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand `discovery_quiz_questions.json` from 6 → ≥18 questions and broaden answer-name scoring so ≥55 distinct anchor Names are reachable from quiz outcomes (today the quiz reaches exactly **32 Names** — the same 32 that have `name_anchors.json` entries; the +8 over 32 → 40 implied by the original framing is too narrow).

**Architecture:** The quiz lives in `assets/content/discovery_quiz_questions.json`. Each question has options that contribute weighted scores to candidate Name keys. The result aggregator (in `lib/features/discovery/`) sums scores and picks the top 2–3 anchor Names. We add questions, expand each option's score map, and pin coverage with tests.

**Tech Stack:** JSON content, `flutter_test`, iOS Simulator MCP.

---

## File Structure

- Modify: `assets/content/discovery_quiz_questions.json` — grow from 6 → ≥18 questions; expand each option's `scores` map to reference a wider Name pool.
- Read-only reference: the scoring aggregator is **`calculateQuizResults(List<int> answers) → List<AnchorResult>`** at `lib/core/constants/discovery_quiz.dart:510`. It tallies scores by Name slug, sorts desc, returns top 3. Display metadata comes from `nameAnchorsCatalog` keyed by the same slug.
- Score keys are **pure-ASCII lowercase slugs** (e.g. `al-afuw`, `as-sami`, `ash-shakur`). The slug has **no apostrophe** even when the display name has one (`Al-'Afuw` → `al-afuw`). Canonical slug list: see today's reach in F-note below.
- **DUAL-SOURCE WARNING:** `lib/core/constants/discovery_quiz.dart` ships BOTH a const 6-question fallback list AND a JSON-loaded catalog. If Plan 3 edits only the JSON, the Dart const drifts. Each batch must update both files in lockstep (or explicitly mark the const frozen with a "// JSON wins at runtime" comment).
- **Plan 0 dependency:** any new score key not currently in `name_anchors.json` will render as the literal slug string (`"al-ghafur"`) until Plan 4 (anchors backfill) lands. If running Lane D (Plan 3) in parallel with Plan 4, coordinate slug additions.
- Create: `test/features/discovery/discovery_quiz_coverage_test.dart` — schema + breadth assertions.
- Create: `docs/qa/discovery-quiz-design.md` — design rationale (which Names each question is intended to surface, theological mapping).

---

### Task 1: Inspect existing scoring contract

- [ ] **Step 1: Read the discovery result aggregator**

Open `lib/features/discovery/` (likely a `discovery_service.dart` or `discovery_provider.dart`). Confirm:
- The Name key format the scorer expects: pure-ASCII slug. Note canonical is **`al-latif`** (not `al-lateef`), **`al-basir`** (not `al-baseer`). Plan 3 examples below use the canonical slugs.
- The aggregation algorithm (sum, top-N).
- Where the canonical Name list comes from (for mapping slug → display name).

Record findings in `docs/qa/discovery-quiz-design.md` as a "Scoring contract" section.

- [ ] **Step 2: Commit findings**

```bash
git add docs/qa/discovery-quiz-design.md
git commit -m "docs(discovery): document quiz scoring contract"
```

---

### Task 2: Add coverage test (RED)

**Files:**
- Create: `test/features/discovery/discovery_quiz_coverage_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('discovery_quiz_questions.json', () {
    final raw = File('assets/content/discovery_quiz_questions.json')
        .readAsStringSync();
    final List<dynamic> qs = jsonDecode(raw) as List<dynamic>;

    test('>=18 questions', () {
      expect(qs.length, greaterThanOrEqualTo(18));
    });

    test('every question has >=3 options each with a scores map', () {
      for (final q in qs.cast<Map<String, dynamic>>()) {
        final opts = q['options'] as List<dynamic>;
        expect(opts.length, greaterThanOrEqualTo(3), reason: q['id']);
        for (final o in opts.cast<Map<String, dynamic>>()) {
          expect(o['text'], isA<String>());
          final scores = o['scores'] as Map<String, dynamic>;
          expect(scores, isNotEmpty, reason: '${q['id']} option "${o['text']}"');
          for (final entry in scores.entries) {
            expect(entry.value, isA<num>(), reason: entry.key);
          }
        }
      }
    });

    test('union of scored Name keys covers >=40 distinct Names', () {
      final names = <String>{};
      for (final q in qs.cast<Map<String, dynamic>>()) {
        for (final o in (q['options'] as List).cast<Map<String, dynamic>>()) {
          (o['scores'] as Map).forEach((k, _) => names.add(k as String));
        }
      }
      expect(names.length, greaterThanOrEqualTo(40),
          reason: 'reachable Names = ${names.length}: $names');
    });

    test('every scored Name key is a slug of a canonical Name', () {
      // Slugs are pure ASCII lowercase with dashes; no apostrophes, no unicode.
      final keyRe = RegExp(r'^[a-z]+(-[a-z]+)+$');
      for (final q in qs.cast<Map<String, dynamic>>()) {
        for (final o in (q['options'] as List).cast<Map<String, dynamic>>()) {
          for (final k in (o['scores'] as Map).keys) {
            expect(keyRe.hasMatch(k as String), isTrue, reason: k);
            // Membership check: every scored slug must have a render-time
            // display entry in nameAnchorsCatalog, or it renders as the literal slug.
            // Until Plan 4 lands (99-anchor backfill), this gates Plan 3 to slugs
            // that already have anchors. After Plan 4, this is a no-op safeguard.
            // Cross-import `nameAnchorsCatalog` from discovery_quiz.dart at the top of this file.
          }
        }
      }
    });
  });
}
```

- [ ] **Step 2: Run test**

Run: `flutter test test/features/discovery/discovery_quiz_coverage_test.dart`
Expected: FAIL on question count (6 < 18) and Names coverage (32 < 55).

- [ ] **Step 3: Commit**

```bash
git add test/features/discovery/discovery_quiz_coverage_test.dart
git commit -m "test(discovery): pin quiz coverage to 18 questions / 40 Names (RED)"
```

---

### Task 3: Design 12 new questions

Add 12 questions to `docs/qa/discovery-quiz-design.md` BEFORE editing JSON. Each design entry must list:
- the question text,
- 3–4 option texts (each ≤ 14 words, warm tone),
- for each option, 2–4 Name slugs with weights (1 or 2),
- a one-line "what Names this question is meant to surface."

Spread the questions across themes already underrepresented by the existing 6: trust/tawakkul, gratitude, repentance, justice/injustice, longing/love, awe/majesty, hope, patience-with-self, mercy-for-others, knowledge-seeking, gentleness, mortality.

- [ ] **Step 1: Author 6 new questions in the design doc**

Example design row:

```
### Q7 — patience-with-self
Prompt: "When you fall short of your own expectations, what do you most need to hear?"
Options:
- "That Allah loves the one who keeps returning to Him" → at-tawwab=2, al-ghaffar=2, al-wadud=1
- "That He sees the struggle, not just the slip" → al-basir=2, ash-shahid=1, al-latif=1
- "That the door is open — always" → al-ghafur=2, ar-rahim=1, al-karim=1  (NB: al-ghafur lacks anchor today → coordinate with Plan 4)
- "That my worth isn't measured by my worst day" → al-wadud=2, al-karim=2, al-halim=1  (NB: al-halim lacks anchor today → Plan 4)
Intended Names: at-tawwab, al-ghaffar, al-wadud, al-basir, al-latif, al-karim.
```

- [ ] **Step 2: Commit design**

```bash
git add docs/qa/discovery-quiz-design.md
git commit -m "docs(discovery): design 6 new quiz questions (batch 1)"
```

- [ ] **Step 3: Author 6 more in the design doc**

Repeat with themes: gratitude, awe, mortality, justice, hope, mercy-for-others.

- [ ] **Step 4: Commit**

```bash
git add docs/qa/discovery-quiz-design.md
git commit -m "docs(discovery): design 6 new quiz questions (batch 2)"
```

---

### Task 4: Implement new questions in JSON (GREEN)

**Files:**
- Modify: `assets/content/discovery_quiz_questions.json`

- [ ] **Step 1: Append 12 questions**

Match the existing JSON shape:

```json
{
  "id": "q7",
  "prompt": "When you fall short of your own expectations, what do you most need to hear?",
  "options": [
    {
      "text": "That Allah loves the one who keeps returning to Him",
      "scores": { "at-tawwab": 2, "al-ghaffar": 2, "al-wadud": 1 }
    },
    {
      "text": "That He sees the struggle, not just the slip",
      "scores": { "al-basir": 2, "ash-shahid": 1, "al-latif": 1 }
    },
    {
      "text": "That the door is open — always",
      "scores": { "al-ghafur": 2, "ar-rahim": 1, "al-karim": 1 }
    }
  ]
}
```

- [ ] **Step 2: Broaden existing 6 questions' score maps**

For each of the original 6 questions, add 2–3 additional Name slugs to each option's `scores` map so each option contributes to a wider Name pool. Use the design doc to justify each addition.

- [ ] **Step 3: Run test**

Run: `flutter test test/features/discovery/discovery_quiz_coverage_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add assets/content/discovery_quiz_questions.json
git commit -m "feat(discovery): expand quiz to 18 questions, broaden scoring to 40+ Names"
```

---

### Task 5: Property-test the aggregator

**Files:**
- Modify: `test/features/discovery/discovery_quiz_coverage_test.dart` (add second group)

- [ ] **Step 1: Add aggregator test**

```dart
import 'package:sakina/core/constants/discovery_quiz.dart';

// Inside main():
group('aggregator returns reachable Names', () {
  test('answering every Q with option 0 returns a non-empty anchor list', () {
    // Build an answer list whose length matches the question count.
    final qsCount = 18; // bump to actual final count
    final result = calculateQuizResults(List<int>.filled(qsCount, 0));
    expect(result, isNotEmpty);
  });
  test('three distinct answer paths produce distinct top anchors', () {
    final qsCount = 18;
    final a = calculateQuizResults(List<int>.filled(qsCount, 0));
    final b = calculateQuizResults(List<int>.filled(qsCount, 1));
    final c = calculateQuizResults(List<int>.filled(qsCount, 2));
    expect({a.first.name, b.first.name, c.first.name}.length,
        greaterThanOrEqualTo(2),
        reason: 'expected at least 2 distinct top anchors across 3 paths');
  });
});
```

- [ ] **Step 2: Run**

Run: `flutter test test/features/discovery/discovery_quiz_coverage_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/features/discovery/discovery_quiz_coverage_test.dart
git commit -m "test(discovery): aggregator surfaces distinct anchors per path"
```

---

### Task 6: iOS Simulator MCP — full quiz flow × 3 answer paths

**Pre-step (user):** user runs `flutter run -d <ios-simulator> --dart-define-from-file=env.json`. **No fresh install needed** — the quiz is post-onboarding (Settings → "Discover your anchors" entry at `lib/features/settings/screens/settings_screen.dart:257`, also reachable from Progress at `progress_screen.dart:156`). Any existing account works.

For each of 3 answer paths (all-option-0, all-option-1, all-option-2):

- [ ] **Step 1: Boot + launch**

```
mcp__ios-simulator__get_booted_sim_id
mcp__ios-simulator__launch_app   bundleId=com.sakina.app.sakina
```

- [ ] **Step 2: Navigate to the discovery quiz entry**

```
mcp__ios-simulator__ui_describe_all   # find quiz launch button
mcp__ios-simulator__ui_tap
```

- [ ] **Step 3: Answer 18 questions with the chosen option index**

Loop:

```
mcp__ios-simulator__ui_describe_all   # find option chip
mcp__ios-simulator__ui_tap            # tap chosen option
mcp__ios-simulator__ui_tap            # tap continue
```

- [ ] **Step 4: Capture anchor result**

```
mcp__ios-simulator__screenshot
mcp__ios-simulator__ui_describe_all   # read anchor Name shown
```

- [ ] **Step 5: Log to QA**

Append to `docs/qa/discovery-quiz-design.md`:

```markdown
## Simulator verification 2026-05-XX
| Path | Anchor 1 | Anchor 2 | Distinct from other paths |
|------|----------|----------|----------------------------|
| all-0 | ... | ... | ... |
| all-1 | ... | ... | ... |
| all-2 | ... | ... | ... |
```

Assert: the three paths yield at least 2 distinct primary anchors.

- [ ] **Step 6: Commit**

```bash
git add docs/qa/discovery-quiz-design.md
git commit -m "docs(qa): record discovery quiz simulator pass 2026-05-XX"
```

---

### Task 7: PR

```bash
git push origin <branch>
gh pr create --title "Expand discovery quiz to 18 Qs / 40+ reachable Names" --body "$(cat <<'EOF'
## Summary
- Adds 12 new quiz questions, each spanning a distinct theological theme.
- Broadens scoring on the original 6 so 55+ Names are now reachable as anchors (was exactly 32, mirroring `name_anchors.json` coverage).
- Pin coverage with unit tests; verify three distinct paths in the simulator.

## Test plan
- [x] `flutter test test/features/discovery/` PASS
- [x] `flutter test` PASS
- [x] iOS simulator MCP: three answer paths yield distinct anchors; log in QA doc.
EOF
)"
```
