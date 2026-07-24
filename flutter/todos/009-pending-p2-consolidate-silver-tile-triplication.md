---
status: pending
priority: p2
issue_id: "009"
tags: [code-review, quality, dry, drift-risk]
dependencies: []
---

# Consolidate the three copies of the Silver ornate tile

## Problem Statement
There are now THREE independent copies of the same silver tile visual, and this branch added the third link. The reveal's silver card and the collection grid's silver card are maintained separately and will drift — a palette/border tweak in one won't reach the other, and QA won't catch it (different screens). Bronze/Gold/Emerald already expose public `*OrnateTile` widgets; Silver is the odd one out.

## Findings
- `collection_screen.dart:771-988` — `_SilverOrnateTile`, the live grid tile (used at `:607`), with its own painters (`:994-1148`).
- `silver_card_preview.dart:96-294` — `_OrnateTile` (design-preview), now load-bearing.
- `silver_card_preview.dart:855-868` — NEW public `SilverOrnateTile` wrapper added by this branch; `reveal_card_tile.dart:22` wires the reveal to it.
- Palette constants re-declared in ≥3 places (`silver_card_preview.dart:104-110, :303-309`, `collection_screen.dart:777-783`).

## Proposed Solutions
1. **Promote one canonical `SilverOrnateTile`** (natural home: `silver_card_preview.dart` public class, or a new `silver_ornate_tile.dart`) with its two painters; have `collection_screen.dart:607` consume it and delete `_SilverOrnateTile` + its private painters. Removes the Bronze/Gold/Emerald-vs-Silver inconsistency too. Effort: Medium.
2. **Minimum: cross-link TODOs** on both classes documenting the drift risk if full de-dup is deferred. Effort: Small.

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/collection/widgets/silver_card_preview.dart`, `lib/features/collection/screens/collection_screen.dart`, `lib/features/daily/widgets/reveal_card_tile.dart`.

## Acceptance Criteria
- [ ] One canonical Silver tile; collection grid + reveal both consume it.
- [ ] No duplicated silver palette/painter definitions remain (or a documented deferral).

## Work Log
- 2026-07-23: Found via /code-review (pattern-recognition P1-1; architecture P3).
- 2026-07-23: Took the FULL consolidation path (Solution 1). Verified the two grid-tile impls are visually identical before merging: `_SilverOrnateTile` (collection_screen) and `_OrnateTile` (silver_card_preview, wrapped by public `SilverOrnateTile`) share byte-identical palettes (7 constants), an identical Islamic-pattern painter, and an identical ornate-border painter (same insets/corner ornaments/mid-edge diamonds/medallion/dots/transliteration). The ONLY structural difference: `_OrnateTile` wraps its body in `AspectRatio(0.72)`, whereas `_SilverOrnateTile` had none. The collection grid delegate is already `childAspectRatio: 0.72` and the reveal slot is `cardW/0.72`, so the inner AspectRatio renders the same size in both contexts → no grid appearance change. Changes: collection_screen `:607` now uses `SilverOrnateTile(card:, unseen:)`; added the `silver_card_preview.dart` import; deleted `_SilverOrnateTile` + `_SilverOrnateBorderPainter`. KEPT `_SilverIslamicPatternPainter` (still used by the detail sheet `_SilverOrnateDetailSheet`). Detail-sheet palette constants left in place (separate class, out of scope for the tile de-dup). `flutter analyze` clean (0 errors; only pre-existing infos); `flutter test test/features/daily/ test/features/collection/` = 59 pass. NOTE: match verified by source comparison, not device QA — a device glance at the collection Silver tile is still advisable but low-risk given the identical painters/palette.

## Resources
- Related: #002 (Silver "signature gesture").
