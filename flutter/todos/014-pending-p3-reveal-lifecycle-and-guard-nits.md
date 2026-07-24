---
status: pending
priority: p3
issue_id: "014"
tags: [code-review, quality, cleanup]
dependencies: []
---

# Lifecycle & guard nits: dead duration reassignment, stopwatch, autoStart fence, RepaintBoundary

## Problem Statement
A cluster of small, safe hardening/cleanup items with no user-visible impact.

## Findings
- **Inert duration reassignment**: reduced-motion sets `_reveal.duration = 500ms` then `_reveal.value = 1.0` (`:136-160`) — the snap makes the 500ms dead; delete the reassignment for clarity, and add a tap-entry reduced-motion test (covered by #011).
- **`_dwell` stopwatch never stopped** (`:89,141,237`) — harmless but untidy; `.stop()` after reading in `_continue()` or in `dispose()`.
- **`autoStart` public flag** (`:47,61,102-118`) — safe today (no prod caller sets it, loop is `mounted`-guarded, no `onEvent` in preview) but comment-only fence; consider `if (widget.autoStart && kDebugMode)` belt-and-suspenders so a future caller can't ship a self-looping reveal.
- **`_ambient.repeat()` runs under reduced motion** (`:97-100`) — contradicts the a11y intent; gate with `if (!_reduceMotion)` (resolved together with #001).
- **`CompanionMedallion` not RepaintBounded during ignite** (`:433`) — wrap it in a `RepaintBoundary` (illustrated geometry is static; only the outer Transform/Opacity animate). Cheap win.
- **`TierPalette.color` duplicates `CardTier.colorValue`** (`reveal_spec.dart:18-30,70`) — hand-copied hex that must stay in sync; consider deriving `color` from `CardTier.colorValue` (keep `bright`/`glow` reveal-specific).

## Proposed Solutions
1. Apply the nits above. Each is Small and independent. Effort: Small.

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/daily/widgets/card_reveal_overlay.dart`, `lib/features/daily/models/reveal_spec.dart`.

## Acceptance Criteria
- [ ] Dead duration reassignment removed; stopwatch stopped; `autoStart` loop fenced; `_ambient` gated under reduced motion; `CompanionMedallion` RepaintBounded; palette color de-duplicated (or documented).

## Work Log
- 2026-07-23: Found via /code-review (architecture P2/P3, pattern-recognition P2-5/P3-6, simplicity P3.1, performance P2-B).
- 2026-07-23: Applied on `feat/tiered-card-reveal`:
  - Deleted the inert `_reveal.duration = 500ms` reassignment (snap to 1.0 makes it dead).
  - `_dwell.stop()` after reading elapsed in `_continue()`.
  - Fenced the autoStart loop behind `kDebugMode` (`widget.autoStart && kDebugMode`),
    imported `package:flutter/foundation.dart`.
  - `_ambient` no longer runs under reduced motion (folded into #001 rest logic — the
    ambient loop is only started in `_open()` when `!_reduceMotion`).
  - Wrapped `CompanionMedallion` in `_buildLantern` in a `RepaintBoundary`.
  - SKIPPED (intentional, per batch instructions): deriving `TierPalette.color` from
    `CardTier.colorValue` — risks touching reveal_spec.dart color values / Emerald
    parity. The hand-copied hex stays; revisit separately if desired.
- 2026-07-23: Followed up on the previously-skipped item on `feat/reveal-everywhere`:
  - `tierPalette(tier).color` now derives from `Color(tier.colorValue)` (single
    source of truth via CardTierX, already imported). `bright`/`glow` stay
    hand-specified (reveal-fx accents). `const` dropped on the four returns since
    `Color(tier.colorValue)` isn't const (inner Colors kept `const`).
  - VERIFIED the derived values equal the old hand-copied hex exactly: bronze
    0xFFCD7F32, silver 0xFFA8A9AD, gold 0xFFC8985E, emerald 0xFF50C878 — nothing
    changes visually. `reveal_spec_test.dart:28`
    (`tierColor.toARGB32() == colorValue`) still passes.

## Resources
- Several overlap with #001 (rest state) — batch where sensible.
