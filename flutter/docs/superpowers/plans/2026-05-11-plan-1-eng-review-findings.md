# Plan 1 (Reflection Verse Catalog Expansion) — Eng Review Findings

Plan-specific issues missed by the cross-plan batched review. Cross-plan items
(prompt size, allahNames gap, eval foundation, unknown-name safety) are
already covered in `2026-05-11-plan-eng-review-report.md` — not re-litigated here.

## Verdict

**CONDITIONALLY CLEARED.** Six plan-specific edits below are required before
implementation. None are architectural blockers; all are correctness / consistency
fixes that prevent silent failures after Task 0 lands.

## Findings

### F1 — Five existing entries use "Quran N:N" prefix; the new regex passes them, but they violate the stated "Surah N:N" intent

`reflection_verse_catalog.dart:47-84` declares five constants whose `reference`
field starts with `Quran` rather than a surah name:
- `_repentanceVerse` → `Quran 7:23` (Al-A'raf)
- `_believersMercyVerse` → `Quran 59:10` (Al-Hashr)
- `_goodWorldsVerse` → `Quran 2:201` (Al-Baqarah)
- `_acceptanceVerse` → `Quran 2:127` (Al-Baqarah)
- `_protectionVerse` → `Quran 2:255` (Al-Baqarah, Ayat al-Kursi)

The new regex `^[A-Za-z'\-]+(\s[A-Za-z'\-]+)*\s\d+:\d+(-\d+)?$` accepts these
syntactically (because "Quran" is `[A-Za-z]+`), so the coverage test passes
**but the data is wrong** — these will render as "Quran 2:201" in the UI when
they should be "Al-Baqarah 2:201". The test as written cannot catch this.

**Edit:** add Task 0.5 to rename these five references to canonical surah
names AND tighten the regex to require a known surah name (or at least
forbid the literal `Quran` prefix). A simple guard:
```dart
expect(v.reference.startsWith('Quran '), isFalse,
    reason: '${entry.key} -> "${v.reference}" — use surah name, not "Quran"');
```

### F2 — `_normalizeVerseKey` is fine for AI hallucinations, but cross-format mismatch is silent after Task 0

`_normalizeVerseKey` strips non-alphanumeric and lowercases. "Al-Baqarah 2:286"
→ `albaqarah2286`; "Quran 2:286" → `quran2286`. They do **not** collide — good.
But the AI's old reference-lookup path is now dead code after Task 0 (no
`##VERSE_*##` markers). `normalizeApprovedVerses` is still called with `[]`,
which short-circuits to `approvedVersesForName(name)`. The reference-key map
(`_approvedReflectVersesByReference`) becomes vestigial — referenced only if
some future caller passes in AI-supplied verses again.

**Edit:** add a comment at `reflection_verse_catalog.dart:104` noting the
reference-key map is now a defensive fallback for future re-introduction of
AI verse parsing, not a hot path. Also consider deleting `_parseReflectVerses`
+ `parseReflectResponse`'s `parsedVerses` line after Task 0 since they only
ever produce `[]` (the AI no longer emits the markers).

### F3 — Coverage test reads JSON only; doesn't cross-check `allahNames` (Plan 0's fix)

`_canonicalTransliterations()` reads `collectible_names.json` directly. After
Plan 0 lands, `allahNames` should mirror this list, but the test doesn't pin
that invariant. If the two drift (someone edits one without the other),
`findCanonicalName` returns the AI's raw name → the catalog map lookup misses
on spelling → Task 3.5's "always-safe" fallback kicks in **silently**, and
every user gets the same two demo verses for the affected Name.

**Edit:** add an assertion in the coverage test:
```dart
test('allahNames mirrors collectible_names.json transliterations', () {
  final fromJson = _canonicalTransliterations().toSet();
  final fromDart = allahNames.map((n) => n.transliteration).toSet();
  expect(fromDart, equals(fromJson),
      reason: 'allahNames and collectible_names.json must agree');
});
```

### F4 — Task 3.5 returns the same two verses for every unknown Name; OK as safety net, weak as UX

Returning `[_heartsRestVerse, _noBurdenVerse]` is correct as a never-blank
guarantee. But if the AI consistently returns a non-canonical spelling (e.g.
"Al-Latif" vs "Al-Lateef"), every reflect card for that user funnels into
the same generic pair — invisibly degrading the personalised experience.

**Edit:** add a debug-only assertion (or non-fatal analytics event) when the
final fallback fires, so we can detect persistent canonical-name mismatches
in production rather than silently shipping demo verses.

### F5 — Batch math wording is sloppy but arithmetically correct

Plan says "Repeat Task 3 nine times (84 names ÷ 10 ≈ 9 batches; final batch is
4 names)." 9 iterations of 10 would be 90; the intent is **8 batches of 10 +
1 final batch of 4 = 84 names across 9 iterations**. Internally consistent
but ambiguous.

**Edit:** rewrite line 292 as "Repeat Task 3: 8 batches of 10 Names + 1 final
batch of 4 Names (9 iterations total, 84 Names)."

### F6 — Simulator MCP bundle id placeholder

Plan says `bundleId=com.sakina.app (confirm from ios/Runner.xcodeproj if unsure)`.
Real value from `ios/Runner.xcodeproj/project.pbxproj:514` is
**`com.sakina.app.sakina`**. Replace placeholder.

### F7 — Ledger reviewer cells are unverifiable at code-review time

The ledger requires TR + TH initials per row but the test only checks coverage,
not reviewer column completeness. Nothing stops a contributor from leaving
`—` in TR/TH and shipping.

**Edit:** add a CI test that parses `docs/qa/reflection-verse-sources.md` and
fails if any in-scope row (one of the 99 names) has empty/dash TR or TH cells.
Cheap and pins the scholarly-review gate.

## Recommended plan edits (summary)

1. Add **Task 0.5**: rename the five `Quran N:N` references to canonical
   surah names and tighten the regex (F1).
2. Add comment + delete dead parsing code post-Task 0 (F2).
3. Add `allahNames ↔ JSON` cross-check test (F3).
4. Add analytics/debug signal when Task 3.5 fallback fires (F4).
5. Rewrite the batch arithmetic line (F5).
6. Replace bundle id placeholder with `com.sakina.app.sakina` (F6).
7. Add ledger-completeness CI test (F7).

## Test gaps

- No test pins that `allahNames` and `collectible_names.json` agree (F3).
- No test pins that reviewer initials are filled in ledger (F7).
- No test catches "Quran N:N" prefix in references (F1).
- No test detects when Task 3.5 fallback is invoked at runtime (F4).

## Failure modes

| # | Mode | Likelihood | Mitigation |
|---|---|---|---|
| 1 | Five "Quran N:N" refs render in UI as-is | High (data already wrong) | Task 0.5 rename |
| 2 | `allahNames` ↔ JSON spelling drift → silent generic fallback | Medium | F3 test |
| 3 | Ledger reviewer cells left blank, scholarly review skipped | Medium | F7 test |
| 4 | Persistent canonical-name mismatch ships same two verses to many users | Low (depends on AI behavior) | F4 telemetry |
| 5 | Dead `_parseReflectVerses` code rots over time | Low | F2 cleanup |
