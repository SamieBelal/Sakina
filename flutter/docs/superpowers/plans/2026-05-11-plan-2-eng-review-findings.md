# Plan 2 (Browse Duas Expansion) — Eng Review Findings

Reviewer: focused eng pass, 2026-05-12. Scope: `docs/superpowers/plans/2026-05-11-browse-duas-expansion.md`. Cross-plan decisions (Plan 0 foundation, Plan 1 prompt/unknown-name fix, Plan 4 squash) are already locked; not re-litigated.

## Critical

### C1. No regression test on the existing 15 categories
Plan 2 adds searchability tests only for the 12 new categories (Task 4). The existing 76 duas span `anxiety`, `forgiveness`, `grief`, `protection`, `guidance`, `wealth`, `family`, `morning`, `evening`, `sleep`, `travel`, `food`, `gratitude`, `hope`, `general`. None of these get a pin. Adding `'fighting': ['marriage_conflict']`, `'failing': ['parenting','shame']`, `'tired': ['burnout']` etc. can plausibly shift the score ordering on existing queries (e.g. "I'm so tired and worried" used to bias toward anxiety; now competes with burnout).

Fix: extend the Task 4 keyword map with one canonical phrase per *existing* category (e.g. `'anxiety': 'I keep feeling anxious'`, `'forgiveness': 'I want Allah to forgive me'`, `'protection': 'protect me from evil'`, `'grief': 'I lost someone'`, ...) and assert at least one returned dua has that category. This is a 12-line addition that prevents silent ranking regressions on the 76 we already shipped.

## High

### H1. `'sick' → ['illness','protection']` collides with the existing `protection` category
The existing `_semanticMap` doesn't have `'sick'`, but the new mapping co-tags it with `protection`, and `inferredTags.contains(dua.category)` awards +6 for both `illness` and `protection`. There are 5 `protection` duas already. Several will outrank the brand-new `illness` duas on a query like "I'm sick" until the catalog has enough `illness` entries with strong emotion-tag overlap. Suggest dropping `protection` from `sick` (keep it on `cancer`/`disease` only) or boosting the `illness` category by adding `emotion_tags: ['illness']` redundantly so the tag-match path also scores +4.

Same shape applies to `'temptation' → ['lust','forgiveness']` and `'shame' → ['shame','forgiveness']` — they will likely route to the existing 8 forgiveness duas before the new lust/shame duas reach critical mass.

### H2. Task 9 ("run reflect eval as regression guard") tests the wrong thing
Plan 2's surface area is `_semanticMap` + `_searchLocalDuas`, called only by `findDuas`. `reflectWithOpenAI` (the Name-pick path) is independent — it doesn't consult `_semanticMap`. The Plan 0 reflect eval will pass even if every new keyword routes wrong. Either drop Task 9 (it is theatre), or add a dedicated `findDuas` smoke eval with ~10 natural-language → expected-category rows. Task 4's per-keyword assertions already partially cover this; a small eval fixture would close it.

## Medium

### M1. Schema/example mismatch — fine for JSON, but BrowseDua model is bypassed
Verified: `assets/content/browse_duas.json` does use `when_to_recite` and `emotion_tags` (snake_case) on all 76 entries. `lib/core/constants/duas.dart:1180 _parseBrowseDuas` reads `map['emotion_tags']` and `map['when_to_recite']` — matches. The example in Plan 2 is correct. But note: `lib/core/constants/duas.dart` has a separate `const browseDuas` Dart-literal fallback list (76 entries) that mirrors the JSON. Plan 2 only edits the JSON. The fallback list will silently drift — acceptable since `browseDuasCatalog` prefers parsed JSON, but worth flagging in the plan ("fallback list deliberately left stale, JSON is source of truth").

### M2. `'tired' → ['burnout']` is too sticky
"I'm tired" is one of the most common natural-language inputs and currently maps to `anxiety` indirectly (via `'overwhelmed'`/`'stress'` in compound queries). Hard-mapping `'tired'` solely to burnout will steal hits from the existing anxiety dua corpus. Either co-tag (`'tired': ['burnout','anxiety']`) or downgrade to `'exhausted'` only.

## Low

### L1. `'failing': ['parenting','shame']` over-broad
`failing` is a generic English word ("failing a class", "failing at work") that will spuriously hit parenting/shame duas. Recommend `'failing as a parent'` is matched via the substring fallback in `_searchLocalDuas` (it splits on whitespace and `key.contains(word)` already catches "parent"). Drop `'failing'` from the map.

### L2. `@visibleForTesting` on top-level function — verified valid
Pattern is already used at `lib/services/public_catalog_service.dart:162`. Plan 2's syntax compiles. No action.

### L3. `File('assets/content/browse_duas.json')` in tests — verified valid
`test/widgets/app_shell_level_up_overlay_test.dart:128` and four other tests use the same `File(...).readAsStringSync()` pattern from project root. Convention confirmed. No action.

### L4. Simulator step references "Find a dua for…" entry
Actual UI hint is `'What do you need a dua for...'` (`lib/features/duas/screens/duas_screen.dart:248`). Update Task 8 Step 4 wording so the agent finds the right field.

### L5. Bundle id
Real iOS bundle id is `com.sakina.app.sakina` (`ios/Runner.xcodeproj/project.pbxproj:514`). Fill into Task 8 Step 1.

### L6. Hadith reference (Sahih al-Bukhari 3282) for the anger example
The reference is plausible — Bukhari does carry the narration about the Prophet ﷺ instructing an angry man to say A'udhu billahi mina-sh-shaytani-r-rajim — but verification is a content-author duty. The Task 6 ledger column (`Grade` + `Reviewer`) already enforces this; just call it out explicitly in plan prose so the author doesn't treat the example as pre-verified.

### L7. `emotion_tags` coverage already 100% on existing 76 entries
All 76 entries have `emotion_tags` and `when_to_recite` populated. No backfill needed; concern raised in scope brief is N/A.

## Verdict
CLEARED with C1 + H1 + H2 addressed before Task 7. Other items are inline tweaks.
