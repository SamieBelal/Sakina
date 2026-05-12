# Name Anchors Backfill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Backfill `assets/content/name_anchors.json` from 32 → 99 entries so every canonical Name of Allah has the editorial one-liner (`anchor`) and supporting paragraph (`detail`) used across discovery quiz results, settings, and collection screens.

**Architecture:** Pure content fix. Each entry has shape `{ name_key, name, arabic, anchor, detail, created_at }`. Add 67 new entries matching the existing voice. Tests pin 1:1 coverage with the canonical Name list — **via a `transliteration → name_key` translation map**, because the existing 32 anchors use handcrafted shorter spellings (`al-hakim`, `al-latif`, `al-wakil`) that don't naively derive from the canonical JSON transliterations (`Al-Hakeem`, `Al-Lateef`, `Al-Wakeel`). Three existing anchors (`al-qarib`, `ar-rabb`, `al-jamil`) have NO canonical Name and are deprecated to a separate "non-canonical anchors" list.

**Tech Stack:** JSON content, `flutter_test`, iOS Simulator MCP.

**Depends on:** Plan 0 (allahNames backfill — the canonical-name source `findCanonicalName` becomes trustworthy for all 98 attribute Names).

---

## File Structure

- Modify: `assets/content/name_anchors.json` — add 67 new entries.
- Modify: `lib/services/public_catalog_contracts.dart:69` — bump `nameAnchorsPublicCatalog.expectedCount` from 32 to 99. **Without this, runtime throws `StateError('Expected 32 rows for name_anchors, got 99.')` the moment the new file lands.** Update simultaneously with the JSON.
- Create: `test/content/name_anchors_coverage_test.dart` — coverage + shape assertions, with a transliteration→slug translation map.
- Create: `docs/qa/name-anchors-editorial.md` — voice guide + per-Name draft ledger with TWO reviewer columns (Editorial + Theological), em-dash punctuation rule.

---

### Task 1: Add coverage test (RED)

**Files:**
- Create: `test/content/name_anchors_coverage_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Translation map from canonical transliteration → existing anchor slug.
/// Built empirically: existing anchors use shorter handcrafted spellings that
/// don't derive naively from `_slug(transliteration)`. Add entries when the
/// existing slug differs from `_naiveSlug(transliteration)`.
const Map<String, String> _transliterationToAnchorSlug = {
  'Al-Hakeem': 'al-hakim',
  'Al-Kareem': 'al-karim',
  'Al-Lateef': 'al-latif',
  'Al-Mujeeb': 'al-mujib',
  'Al-Wakeel': 'al-wakil',
  'Al-Mateen': 'al-matin',
  'Al-Baseer': 'al-basir',
  'Al-Khabeer': 'al-khabir',
  'Al-Qawiyy': 'al-qawi',
  'Ar-Raheem': 'ar-rahim',
  'Ash-Shaheed': 'ash-shahid',
  // Add new entries here when you discover spelling differences.
};

/// Slugs in `name_anchors.json` that have NO canonical Name in collectible_names.json.
/// Kept as "non-canonical anchors" so the test doesn't flag them as orphans,
/// but they're surfaced for migration in a future plan.
const Set<String> _nonCanonicalAnchorSlugs = {'al-qarib', 'ar-rabb', 'al-jamil'};

String _naiveSlug(String t) {
  return t.toLowerCase()
      .replaceAll(RegExp(r"['\u2018\u2019]"), '')
      .replaceAll(RegExp(r'\s+'), '-');
}

String _anchorSlug(String transliteration) {
  return _transliterationToAnchorSlug[transliteration]
      ?? _naiveSlug(transliteration);
}

void main() {
  group('name_anchors.json coverage', () {
    final anchorsRaw =
        File('assets/content/name_anchors.json').readAsStringSync();
    final namesRaw =
        File('assets/content/collectible_names.json').readAsStringSync();
    final anchors = (jsonDecode(anchorsRaw) as List).cast<Map<String, dynamic>>();
    final names = (jsonDecode(namesRaw) as List).cast<Map<String, dynamic>>();

    test('every canonical Name has an anchor (via translation map)', () {
      final anchorKeys = anchors.map((a) => a['name_key'] as String).toSet();
      final missing = <String>[];
      for (final n in names) {
        if (n['id'] == 1) continue; // skip "Allah" — proper Name, no attribute anchor
        final slug = _anchorSlug(n['transliteration'] as String);
        if (!anchorKeys.contains(slug)) {
          missing.add('${n['transliteration']} -> $slug');
        }
      }
      expect(missing, isEmpty, reason: 'Names without anchors: $missing');
    });

    test('every anchor slug either maps to a canonical Name or is in the deprecated set', () {
      final canonicalSlugs = <String>{};
      for (final n in names) {
        if (n['id'] == 1) continue;
        canonicalSlugs.add(_anchorSlug(n['transliteration'] as String));
      }
      final orphans = <String>[];
      for (final a in anchors) {
        final key = a['name_key'] as String;
        if (!canonicalSlugs.contains(key) && !_nonCanonicalAnchorSlugs.contains(key)) {
          orphans.add(key);
        }
      }
      expect(orphans, isEmpty,
          reason: 'Anchor slugs not mapped to any canonical Name (add to '
              '_transliterationToAnchorSlug or _nonCanonicalAnchorSlugs): $orphans');
    });

    test('every anchor has all required fields, non-empty', () {
      const required = ['name_key', 'name', 'arabic', 'anchor', 'detail'];
      for (final a in anchors) {
        for (final f in required) {
          expect(a[f], isA<String>(), reason: '${a['name_key']} -> $f');
          expect((a[f] as String).trim(), isNotEmpty,
              reason: '${a['name_key']} -> $f');
        }
      }
    });

    test('anchor text is <=110 characters', () {
      for (final a in anchors) {
        expect((a['anchor'] as String).length, lessThanOrEqualTo(110),
            reason: a['name_key']);
      }
    });

    test('detail text is 80–400 characters', () {
      for (final a in anchors) {
        final len = (a['detail'] as String).length;
        expect(len, inInclusiveRange(80, 400),
            reason: '${a['name_key']} -> $len');
      }
    });

    test('punctuation: em-dash (—) only, no en-dash or double-hyphen', () {
      for (final a in anchors) {
        final text = '${a['anchor']} ${a['detail']}';
        expect(text.contains('–'), isFalse,
            reason: '${a['name_key']} uses en-dash — use em-dash (—)');
        expect(text.contains(' -- '), isFalse,
            reason: '${a['name_key']} uses double-hyphen — use em-dash (—)');
      }
    });

    test('name_keys are unique', () {
      final keys = anchors.map((a) => a['name_key'] as String).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('nameAnchorsPublicCatalog.expectedCount matches reality', () {
      // Reminder: when shipping the 99 anchors, bump
      // `lib/services/public_catalog_contracts.dart:69` expectedCount: 32 → 99
      // or the catalog service throws at runtime. This test pins the file count
      // so the contracts file is updated in the same PR.
      expect(anchors.length, equals(99),
          reason: 'When this passes, also update '
              'public_catalog_contracts.dart expectedCount to match.');
    });
  });
}
```

- [ ] **Step 2: Run**

Run: `flutter test test/content/name_anchors_coverage_test.dart`
Expected: FAIL on "Names without anchors" listing 67 slugs.

- [ ] **Step 3: Commit**

```bash
git add test/content/name_anchors_coverage_test.dart
git commit -m "test(content): pin name_anchors 1:1 with canonical Names (RED)"
```

---

### Task 2: Voice guide + editorial ledger

**Files:**
- Create: `docs/qa/name-anchors-editorial.md`

- [ ] **Step 1: Write the voice guide**

```markdown
# Name Anchor Editorial Guide

Each anchor is one sentence ≤110 chars, written in the second person voice already
established by the 32 reference entries.

## Voice characteristics
- Present-tense, "He" capitalised when referring to Allah.
- Speaks TO the reader's situation, not ABOUT the Name in the abstract.
- Concrete imagery > abstract description.
- **Em-dash (—) only.** No en-dash (–), no double-hyphen (--), no triple-dot ellipses. The existing 32 entries use em-dash exclusively (33 occurrences across 32 rows).

## Reference examples (from existing anchors)
- Al-'Afuw: "His forgiveness erases — it doesn't just cover."
- Al-'Ali: "He sees your situation from above — all of it."

## Detail (80–400 chars)
A second sentence or short paragraph that gives the linguistic root, an example,
or a hadith hook. Plain prose, no Arabic transliterations beyond the Name itself.

## Two-reviewer flow (required)
Anchors make doctrinal claims wrapped in editorial voice ("His forgiveness erases").
Each row needs TWO reviewer initials:
- **ED** = Editorial reviewer — voice, tone, length, punctuation.
- **TH** = Theological reviewer — scholar sign-off that the doctrinal claim is sound.

Without TH initials, the row is ineligible to ship. The same person can fill both
roles only if they hold credentials for both — flag any single-initial rows in PR review.

## Ledger
| name_key | anchor draft | detail draft | ED | TH | Date |
|----------|--------------|--------------|----|----|----|
```

Pre-populate the ledger with one row per missing slug (67 rows).

- [ ] **Step 2: Commit**

```bash
git add docs/qa/name-anchors-editorial.md
git commit -m "docs(content): name anchor voice guide + backfill ledger"
```

---

### Task 3: Author anchors in 7 working batches, but SHIP AS ONE COMMIT

**Rollout policy (decided in eng review 2026-05-11):** the Name detail screen may render with missing fields between batches. To avoid a multi-day window of partial UI, all 67 new anchors land in a **single squashed commit** on PR open.

Author in batches for editorial review rhythm; do NOT push or commit-to-master between batches.

For each working batch (repeat 7 times locally):

- [ ] **Step 1: Pick 10 missing slugs from the ledger**

- [ ] **Step 2: Draft anchor + detail for each**

Write directly in `docs/qa/name-anchors-editorial.md` against the ledger row. Pass through reviewer (initials in Reviewer cell). Keep ≤110 chars for the anchor; 80–400 chars for the detail. Match the second-person voice from the reference examples.

- [ ] **Step 3: Add JSON entries**

In `assets/content/name_anchors.json`, append entries matching the existing shape:

```json
{
  "name_key": "al-aleem",
  "name": "Al-'Aleem",
  "arabic": "الْعَلِيمُ",
  "anchor": "He knows what you can't put into words.",
  "detail": "Al-'Aleem is the All-Knowing — His knowledge precedes your awareness of your own state. When you can't name what's wrong, He already does, and He is gentle with what He finds.",
  "created_at": "2026-05-11T00:00:00.000000+00:00"
}
```

`arabic` and `name` come from `collectible_names.json`. `created_at` = today's date.

- [ ] **Step 4: Run test (must still be RED until all 7 batches done)**

Run: `flutter test test/content/name_anchors_coverage_test.dart`
Expected: still RED but with 10 fewer missing. After 7 batches → GREEN.

- [ ] **Step 5: Stage but DO NOT commit between batches**

```bash
git add assets/content/name_anchors.json docs/qa/name-anchors-editorial.md
# (no commit yet — staging carries forward across batches)
```

Repeat Step 1–5 seven times.

- [ ] **Step 6: Bump `expectedCount` in public_catalog_contracts.dart**

```dart
// lib/services/public_catalog_contracts.dart line 69-ish
const nameAnchorsPublicCatalog = PublicCatalog(
  // ...
  expectedCount: 99,  // was 32
);
```

If you skip this, `validatePublicCatalogRows` throws `StateError('Expected 32 rows for name_anchors, got 99.')` at runtime — both for the bundled asset and for Supabase fetches. The Task 1 coverage test "nameAnchorsPublicCatalog.expectedCount matches reality" will surface this.

```bash
git add lib/services/public_catalog_contracts.dart
```

- [ ] **Step 7: Single squashed commit after batch 7 is GREEN**

```bash
git commit -m "feat(content): backfill all 99 name anchors (67 new entries) + bump expectedCount"
```

This is the only commit Plan 4 produces. No intermediate broken UI states reach master.

**If you accidentally commit mid-batch:** `git reset --soft HEAD~N` to undo the last N commits while keeping changes staged, then continue authoring.

---

### Task 4: Full suite green

- [ ] **Step 1: Full test run**

Run: `flutter test`
Expected: PASS.

Run: `flutter analyze`
Expected: clean.

---

### Task 5: iOS Simulator MCP — anchors render in Name detail / Journey UI

**Pre-step (user):** `flutter run -d <ios-simulator> --dart-define-from-file=env.json`.

For 6 newly-backfilled Names (cover both Names with anchors that existed before and 4 freshly backfilled):

- [ ] **Step 1: Boot + launch**

```
mcp__ios-simulator__get_booted_sim_id
mcp__ios-simulator__launch_app   bundleId=com.sakina.app.sakina
```

- [ ] **Step 2: Navigate to the Names collection**

```
mcp__ios-simulator__ui_describe_all   # locate Names tab
mcp__ios-simulator__ui_tap
```

- [ ] **Step 3: Open each target Name detail**

```
mcp__ios-simulator__ui_describe_all
mcp__ios-simulator__ui_tap            # tap the Name tile
mcp__ios-simulator__screenshot
```

- [ ] **Step 4: Verify anchor + detail are visible**

Inspect screenshot for:
- The anchor sentence rendered (typically near the Arabic calligraphy).
- The detail paragraph rendered below.

If the Name detail screen does not surface anchor/detail fields, file a follow-up bug (not in scope for this plan) and skip that Name from the verification log.

- [ ] **Step 5: Log to QA**

Append `## Simulator verification 2026-05-XX` table to `docs/qa/name-anchors-editorial.md`.

- [ ] **Step 6: Commit**

```bash
git add docs/qa/name-anchors-editorial.md
git commit -m "docs(qa): record name anchors simulator pass 2026-05-XX"
```

---

### Task 6: PR

```bash
git push origin <branch>
gh pr create --title "Backfill name anchors for all 99 Names" --body "$(cat <<'EOF'
## Summary
- Backfills `assets/content/name_anchors.json` from 32 → 99 entries.
- Editorial voice guide + reviewer ledger in `docs/qa/name-anchors-editorial.md`.
- Coverage tests pin 1:1 with canonical Names; anchor length and shape constraints enforced.

## Test plan
- [x] `flutter test test/content/name_anchors_coverage_test.dart` PASS
- [x] `flutter test` PASS
- [x] iOS simulator MCP: 6 Name detail screens render anchor + detail correctly.
EOF
)"
```
