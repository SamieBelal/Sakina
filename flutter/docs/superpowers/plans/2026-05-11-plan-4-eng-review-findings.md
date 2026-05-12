# Plan 4 Eng Review Findings — Name Anchors Backfill

Plan: `docs/superpowers/plans/2026-05-11-name-anchors-backfill.md`
Reviewer: eng-review (focused) — 2026-05-12
Scope: issues NOT already covered by cross-plan report `2026-05-11-plan-eng-review-report.md`.

---

## Critical (blocks plan as written)

### 1. Slug strategy is wrong — canonical transliterations use different spelling than existing `name_key`s
Plan 4's coverage test slugs `collectible_names.json[].transliteration` and checks membership in the anchor set. But the existing 32 `name_key`s are NOT derived from the canonical transliterations — they're handcrafted shorter spellings. Empirically (computed by mapping all 99 transliterations through `_slug`):

- Existing anchor `al-hakim` ≠ canonical `Al-Hakeem` → slug `al-hakeem`
- `al-karim` ≠ `Al-Kareem` → `al-kareem`
- `al-latif` ≠ `Al-Lateef` → `al-lateef`
- `al-mujib` ≠ `Al-Mujeeb` → `al-mujeeb`
- `al-wakil` ≠ `Al-Wakeel` → `al-wakeel`
- `al-matin` ≠ `Al-Mateen` → `al-mateen`
- `al-basir` ≠ `Al-Baseer` → `al-baseer`
- `al-khabir` ≠ `Al-Khabeer` → `al-khabeer`
- `al-qawi` ≠ `Al-Qawiyy` → `al-qawiyy`
- `al-jamil` ≠ `Al-Jami` → `al-jami` (and `Al-Jamil` not in canonical list at all)
- `al-qarib` not in canonical list at all
- `ar-rabb` not in canonical list at all
- `ar-rahim` ≠ `Ar-Raheem` → `ar-raheem`
- `ash-shahid` ≠ `Ash-Shaheed` → `ash-shaheed`

The Plan 4 test reports **81 missing slugs, not 67**. Worse, 14 of the existing 32 anchors become orphans (their `name_key` doesn't match ANY canonical slug). Two anchors (`al-qarib`, `ar-rabb`, `al-jamil`) have no canonical Name at all and will be flagged as junk by Plan 0's `requiresCanonicalPrimaryKeys` work.

**Resolution required (pick one):**
- (a) Normalize: rename existing `name_key`s to match canonical slugs (`al-hakim` → `al-hakeem`, etc.), and drop/migrate the 3 anchors with no canonical Name. This is a coordinated rename across `discovery_quiz.dart` constants (lines 200–435), the persisted user payload in `_legacyAnchorNamesKey` shared prefs, and Supabase `name_anchors` table.
- (b) Build a `transliteration → name_key` translation map in the test and keep both forms (more pragmatic for Plan 4 in isolation; but punts the canonical-key debt to a later plan).

This MUST be decided before Task 1 lands. It's the single biggest gap.

### 2. `nameAnchorsPublicCatalog.expectedCount` is pinned at 32
`lib/services/public_catalog_contracts.dart:69` says `expectedCount: 32`. After Plan 4 lands 99 rows, `validatePublicCatalogRows` will throw `StateError('Expected 32 rows for name_anchors, got 99.')` at runtime — both for the bundled asset and for Supabase fetches. Plan 4 must bump this to `99` (or whatever the final count is). Not mentioned anywhere in the plan; add to Task 3.

---

## Medium

### 3. `_slug` does not strip ASCII apostrophe
Plan 4's regex is `r"['\u2018\u2019]"`. The first character class entry IS a straight ASCII `'` inside a Dart raw string, so this DOES strip ASCII apostrophes correctly. **No bug here** — false alarm worth pinning with a test case (`_slug("Al-'Afuw") == "al-afuw"`).

The existing JSON does NOT use curly quotes; it uses straight `'` only (verified: 6 entries with `'`, 0 with U+2018/U+2019). The `\u2018\u2019` clauses are dead but harmless.

### 4. Existing 32 entries already pass length constraints
Anchors all ≤110 chars; details all in 80–400. Plan 4's test will not fire on existing data. (Spot-checked all 32.)

### 5. Single-commit policy has no enforcement
Task 3 Step 5 says "Stage but DO NOT commit between batches." A guardrail is trivial: add a `tool/check-anchor-coverage.sh` precommit hook OR put a comment at the top of `name_anchors.json` (`// last-edited intentionally as one commit — see plan-4`). The plan author is also the only enforcer; consider adding "if you accidentally commit mid-batch, do `git reset --soft HEAD~N` to undo and continue" as inline guidance.

### 6. Single-reviewer ledger vs verse plan's two-reviewer
Plan 1's verse ledger requires TR (textual review) + TH (theological). Plan 4 requires one reviewer. Anchors are editorial INTERPRETATION of theological content — "Al-Afuw erases" makes a doctrinal claim. Recommend two-reviewer flow: Editorial (voice/tone/length) + Theological (scholar OK on the claim). Without this, the plan is one Twitter-thread reviewer initial away from shipping a doctrinally wonky sentence.

---

## Low

### 7. `created_at` format is irrelevant
`_parseNameAnchors` in `discovery_quiz.dart:487` doesn't read `created_at`. ISO microsecond vs millisecond format doesn't matter for runtime. The field is purely metadata. Keep the existing microsecond format for consistency.

### 8. Display fallback is already safe
Name detail screen (`lib/features/names/screens/names_screen.dart`) is a stub — no anchor rendering yet. Anchor display only happens in discovery quiz results (`discovery_quiz_screen.dart:342, 349`) and settings (`settings_screen.dart:870, 877`), and both go through `info?.anchor ?? ''` / `info?.detail ?? ''` fallbacks at `discovery_quiz.dart:539-540`. Even a Name with no anchor entry renders an empty string — not a crash. The single-commit policy is belt-and-braces; the suspenders already exist.

### 9. Punctuation consistency
Existing 32 entries use em-dash (—) exclusively (33 occurrences); zero en-dashes; zero ASCII hyphens-as-punctuation. Voice guide should explicitly say "em-dash (—), not en-dash (–) or double-hyphen (--)." Plan 4's example uses em-dash, so the implementer is likely fine, but make it a rule.

### 10. iOS bundle id
`com.sakina.app.sakina` (from `ios/Runner.xcodeproj/project.pbxproj:514`). Use this in Task 5 Step 1.

---

## Summary

Two blockers (#1 slug mismatch, #2 `expectedCount`), four medium gaps, four low notes. Plan 4 cannot start Task 1 until #1 is decided — the test as written would report 81 missing names, half the existing 32 anchors would be orphaned, and three would be flagged as junk by Plan 0.
