# Finding: Duas tab browse/category UI does NOT exist (manual-test-plan §7 is aspirational)

**Severity:** Documentation drift (misleading test plan)
**Discovered:** 2026-04-26 during §7 Step 0 recon

## What

`docs/manual-test-plan.md` §7 (lines 290-315) describes a Duas tab with:
- Category filter row
- List of public duas
- Tap dua → detail page (Arabic, transliteration, translation)
- Heart/favorite toggle persisted in SharedPrefs (`saved_browse_dua_ids`, `saved_built_duas`, `saved_related_duas`)
- "Build a Dua" CTA as a secondary feature

**None of this exists in the shipped build (commit 1443ba5, 2026-04-26).**

The Duas tab is exclusively the Build-a-Dua flow:

- Title: "Build a Dua"
- Subtitle: "Describe your specific need and we'll construct a personal dua following authentic prophetic etiquette."
- 4-step indicator: Praise → Salawat → Ask → Close
- Text field: "What do you need a dua for..."
- "Build My Dua" button (disabled until input)

## Verification

```bash
$ ls flutter/lib/features/duas/screens/
duas_screen.dart    # only file — pure Build-a-Dua
```

```bash
$ rg -n "favorite_duas|saved_browse_dua_ids|saved_built_duas|saved_related_duas" flutter/lib/ --type dart
# (zero matches — these SharedPref keys exist nowhere in the codebase)
```

## Impact

- Manual-test-plan §7 D-Browse, favorite-toggle, persistence-of-favorite, related-duas tests are all unrunnable.
- Future QA passes will waste time looking for UI that doesn't exist.
- Hard-coded SharedPref key references in the doc point to features that were never shipped.

## Recommendation

1. **Update `docs/manual-test-plan.md` §7** to reflect that Duas tab = Build-a-Dua only. Remove the browse/favorites scenarios. Or:
2. **Build the missing browse UI** if it's still on the product roadmap. If not, kill the doc references.

Both of these are product/PM decisions, not engineering. Surfacing for triage.

## Evidence

- Run log: `docs/qa/runs/2026-04-26-content-history.md`
- Screenshot: `02-duas-tab.png`
- Code: `flutter/lib/features/duas/screens/duas_screen.dart`
