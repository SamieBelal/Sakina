---
status: pending
priority: p2
issue_id: "007"
tags: [code-review, architecture, convention]
dependencies: []
---

# Decide Freezed-vs-relocate for RevealSpec (don't leave a non-Freezed class in models/)

## Problem Statement
CLAUDE.md states models use Freezed and `models/` holds "Freezed data models." `RevealSpec`/`TierPalette` are hand-written `const` classes in `lib/features/daily/models/reveal_spec.dart` with no `==`/`hashCode`/`copyWith`. Any future code comparing two specs gets identity comparison; a tuning/experiment workflow will want `copyWith`. A non-Freezed class sitting unexplained in the Freezed folder sets a precedent that erodes model uniformity.

## Findings
- `reveal_spec.dart:35` (`RevealSpec`), `:5` (`TierPalette`) — plain const classes, no value semantics.
- Defensible counter-argument: these are compile-time `const` *config*, closer to constants than data models.

## Proposed Solutions
1. **Relocate + document (recommended if kept const).** Move to `lib/features/daily/reveal/reveal_spec.dart` (aligns with #006) and add a one-line comment: "deliberately non-Freezed compile-time config." Effort: Small.
2. **Make it Freezed** to match convention (gains `==`/`copyWith`). Cons: codegen for a const config table is heavy; `Color` fields need care. Effort: Medium.

## Recommended Action
_(blank — triage)_

## Technical Details
- `lib/features/daily/models/reveal_spec.dart`. Coordinate with #006 (folder move).

## Acceptance Criteria
- [ ] Either `RevealSpec` is Freezed, or it lives outside `models/` with a documented rationale.

## Work Log
- 2026-07-23: Found via /code-review (architecture-strategist P1).
- 2026-07-23: DONE (Solution 1 — relocate + document). `git mv` reveal_spec.dart out of `models/` into `lib/features/daily/reveal/reveal_spec.dart`; added a header comment explaining the deliberate non-Freezed choice (compile-time const config, no JSON/copyWith need). All importers (overlay, reveal_card_tile, dev_tools_screen, muhasabah_screen, both tests) updated. Kept as plain const classes — not Freezed. `flutter analyze` clean.

## Resources
- CLAUDE.md "Models: Freezed".
