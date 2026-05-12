# Discovery Quiz — Design & Scoring Contract

> **Status:** Living doc. Created as part of Plan 3 (Discovery Quiz Expansion).
> **Source file:** `flutter/docs/superpowers/plans/2026-05-11-discovery-quiz-expansion.md`

This document captures the scoring contract that the discovery quiz aggregator
honors so authors of new questions and tests can rely on a stable shape.

---

## Aggregator

- **Function:** `calculateQuizResults(List<int> answers) -> List<AnchorResult>`
- **Location:** `lib/core/constants/discovery_quiz.dart:510`
- **Signature:**
  ```dart
  List<AnchorResult> calculateQuizResults(List<int> answers);
  ```
- **Algorithm:**
  1. Load the quiz catalog via `discoveryQuizQuestionsCatalog` (JSON-first, Dart
     const fallback) and the display catalog via `nameAnchorsCatalog`.
  2. Walk `answers` index-by-index. Each entry is the selected option index for
     the question at that position. Out-of-range indices are skipped silently.
  3. For each selected option, fold its `scores` map (slug -> int) into a
     running `tally: Map<String, int>`, summing weights per slug.
  4. Sort `tally.entries` by value descending and take the top 3.
  5. For each top entry, look up the display info from `nameAnchorsCatalog`;
     if the slug is missing, the `AnchorResult` falls back to the literal slug
     for `name` and empty strings for `arabic` / `anchor` / `detail`. (i.e., a
     slug never present in the anchor catalog will surface as the raw string,
     not crash.)

## Score key format

- **Pure-ASCII lowercase slugs.** Apostrophes in the display name are dropped.
- Required shape: `^[a-z]+(-[a-z]+)+$` — at least one dash, only lowercase
  ASCII letters between dashes. No digits, no unicode, no underscores.
- Canonical examples (live in JSON today): `al-latif`, `as-sami`, `ash-shakur`,
  `al-afuw`, `at-tawwab`, `ar-rahman`.
- Non-canonical examples to avoid: `al-lateef`, `al-baseer`, `Al-'Afuw`,
  `al_ghafur`.

## Today's reach (computed from JSON, 6 questions, 4 options each)

Unioning every key across every option's `scores` map yields exactly **32
distinct slugs** (also coincidentally the size of `name_anchors.json`):

```
al-afuw, al-ali, al-basir, al-fattah, al-ghaffar, al-hadi, al-hakim, al-jamil,
al-karim, al-khabir, al-latif, al-matin, al-mujib, al-qarib, al-qawi,
al-qayyum, al-quddus, al-wadud, al-wakil, an-nur, ar-rabb, ar-rahim,
ar-rahman, ar-razzaq, as-sabur, as-salam, as-samad, as-sami, ash-shafi,
ash-shahid, ash-shakur, at-tawwab
```

Plan 3's GREEN target is `>= 40` distinct slugs (the previously-discussed "+8"
expansion). The stretch goal is 55+ once Plan 4 (anchor backfill) lands more
display rows.

## Dual-source note

`lib/core/constants/discovery_quiz.dart` ships TWO sources of truth:

1. **Dart const fallback** — `const List<QuizQuestion> discoveryQuizQuestions`
   starting around line 63. Hard-coded 6 questions used when the JSON catalog
   is unavailable (e.g. cold start before the public catalog has loaded).
2. **JSON catalog** — `assets/content/discovery_quiz_questions.json`, loaded
   by `discoveryQuizQuestionsCatalog` via `getParsedCatalog<>` /
   `_parseQuizQuestions`. **JSON wins at runtime** whenever it parses to a
   non-empty list; otherwise the Dart const is returned.

The same dual-source pattern exists for `nameAnchorsCatalog` (rendered display
info) vs the `const Map<String, NameAnchorInfo> nameAnchors` fallback.

**Implication:** authors adding questions to JSON should keep the Dart const
in lockstep, or explicitly mark the const frozen with a comment so reviewers
know JSON is the live source.

## Scoring contract

The test layer (and any future authoring tooling) can rely on the following
invariants of the **JSON catalog** at `assets/content/discovery_quiz_questions.json`:

1. The root is a JSON array of question objects.
2. Each question object has:
   - `id` — non-empty string (e.g. `q1`),
   - `prompt` — non-empty string,
   - `options` — array of at least 3 option objects.
3. Each option object has:
   - `text` — non-empty string,
   - `scores` — non-empty `Map<String, num>` where every key matches the
     slug regex `^[a-z]+(-[a-z]+)+$` and every value is a positive integer
     weight (today's weights are 1 or 2).
4. The aggregator is **purely additive** over the selected options' `scores`
   maps; no slug is special-cased, no negative weights are used, no
   normalization is applied. A slug that appears in only one option will
   surface as a top anchor whenever that option is selected and no other slug
   beats it.
5. Out-of-range answer indices are tolerated (skipped). Answer lists shorter
   than the question count are tolerated (remaining questions skipped).
   Answer lists longer than the question count are tolerated (trailing
   entries skipped).
6. The top-3 cut is final; ties are broken by the underlying `Map.entries`
   iteration order (insertion order in Dart), which is deterministic per run
   but not specified across runs.
7. A slug not present in `nameAnchorsCatalog` will render with `name == slug`
   and empty display strings. It will NOT cause a crash, but will look ugly in
   the UI until Plan 4's anchor backfill lands.

These invariants are pinned by
`test/features/discovery/discovery_quiz_coverage_test.dart`.
