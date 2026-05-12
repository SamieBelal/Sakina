# Plan 3 (Discovery Quiz Expansion) — Eng Review Findings

Generated 2026-05-12. Plan: `docs/superpowers/plans/2026-05-11-discovery-quiz-expansion.md`.
Cross-plan findings already locked in `2026-05-11-plan-eng-review-report.md` are NOT re-surfaced here.

## Critical findings

### F1 — Resolve the `<scoring_file>` / `computeDiscoveryAnchors` placeholders now

The aggregator is **`calculateQuizResults`**, exported from `lib/core/constants/discovery_quiz.dart:510`:

```dart
List<AnchorResult> calculateQuizResults(List<int> answers)
```

- Input: list of selected option indices, one per question (0-based).
- Algorithm: tally scores by Name slug, sort desc, return top 3 as `AnchorResult`.
- Display metadata comes from `nameAnchorsCatalog` (JSON-backed `Map<String, NameAnchorInfo>`), keyed by the same slug.
- Score keys are lowercase ASCII slugs (e.g. `al-afuw`, `as-sami`, `ash-shakur`). The slug has **no apostrophe** even when the display name does (`Al-'Afuw`, `Al-'Ali`).

**Patch Plan 3 Task 5 import + call** to:

```dart
import 'package:sakina/core/constants/discovery_quiz.dart';
// ...
final result = calculateQuizResults(List.filled(qsCount, 0));
```

This also lets the test seed answers programmatically via a single int list, no fake question count argument.

### F2 — Plan's "10–15 Names reachable today" baseline is wrong; actual is 32

Computed by unioning all `scores` keys across the 6 existing questions: **32 distinct slugs** (full list pasted below). The Plan's expansion target of "≥40" is only +8 over today — much narrower than the +25-to-+30 the framing implies.

Recommendation: update Plan 3 goal copy and the design rationale doc to use the real baseline (32), and either (a) raise the target (e.g. ≥55) or (b) reframe the expansion as "broaden into the 67 Names the catalog already has metadata for but the quiz never surfaces." `name_anchors.json` ships **exactly 32 entries today** — same slugs the quiz reaches. So an honest "≥40" target *also* implies extending `name_anchors.json` (or the Plan 0 backfill) — flag this dependency.

Today's reachable slugs: `al-afuw, al-ali, al-basir, al-fattah, al-ghaffar, al-hadi, al-hakim, al-jamil, al-karim, al-khabir, al-latif, al-matin, al-mujib, al-qarib, al-qawi, al-qayyum, al-quddus, al-wadud, al-wakil, an-nur, ar-rabb, ar-rahim, ar-rahman, ar-razzaq, as-sabur, as-salam, as-samad, as-sami, ash-shafi, ash-shahid, ash-shakur, at-tawwab` (32).

### F3 — Coverage test `keyRe` does not match canonical slugs

`r'^[a-z]+(-[a-z\'\u2018\u2019]+)+$'` — but **no `name_anchors.json` slug contains an apostrophe**. `Al-'Afuw` → slug `al-afuw`; `Al-'Ali` → slug `al-ali`. Pure ASCII `[a-z-]`.

Replace with the simpler, accurate regex: `r'^[a-z]+(-[a-z]+)+$'`. Otherwise the regex is harmless but misleading (suggests apostrophes are valid). Add a stronger assertion: every key MUST exist in `nameAnchorsCatalog.keys` — this catches typos like `al-lateef` vs `al-latif` (note: plan's example design row uses `al-lateef` and `al-baseer` which are NOT canonical; canonical is `al-latif`, `al-basir`).

### F4 — Plan's example slugs in Task 3 don't match canonical

The example design row uses `al-lateef`, `al-baseer`, `al-ghafur`, `al-haleem`. Canonical (per `name_anchors.json` and `discovery_quiz.dart` const map): `al-latif`, `al-basir`. `al-ghafur` and `al-haleem` are **not in `name_anchors.json` at all** — they have no display metadata, so `AnchorResult` will fall back to `name: entry.key` (`"al-ghafur"`) as the literal display string. This is a silent rendering bug.

Recommendation: add an explicit Plan 3 sub-task that any new score key not in `name_anchors.json` must be added there too — or rely on Plan 0 backfilling `nameAnchors` to 99 Names before Plan 3 lands. Eng review report places Plan 3 in "Lane D (parallel start)" — that parallelism breaks if Plan 3 introduces slugs that depend on Plan 0's backfill.

## Minor findings

### F5 — Existing 6 questions are dense, no sparse rows
All 24 options have ≥3 score entries with weights of 1 or 2. The Plan 3 example weighting (1, 2) is consistent. No coverage hole to patch.

### F6 — Tone of existing prompts
Existing prompts: ~10-14 words, second-person, warm, situational ("When life feels heavy…", "A moment of genuine peace for you looks like:"). Plan 3's Q7 example ("When you fall short of your own expectations, what do you most need to hear?") is consistent — same length, voice, and structure. No tone fix needed.

### F7 — 18 questions UX
The quiz is **not part of onboarding** — it's reached post-onboarding from Settings (`settings_screen.dart:257`) and Progress (`progress_screen.dart:156`). The user opts in. Doubling from 6 → 18 (~3-4 min) is acceptable for an opt-in self-discovery experience but worth flagging: today's 6Q completion rate is the bar to beat. Add an analytics check (drop-off per question) to the simulator pass step.

### F8 — Simulator pre-step assumption
Plan says "delete app first to bypass onboarding skip." Since the quiz isn't gated by onboarding, **a fresh install is unnecessary** — testers can launch on any account and tap into Settings → "Discover your anchors" (or Progress). Simplify the pre-step.

### F9 — iOS bundle id
`com.sakina.app.sakina` (from `ios/Runner.xcodeproj/project.pbxproj:514`). Use this literal in Task 6 Step 1.

### F10 — JSON vs Dart const dual source
`discovery_quiz.dart` ships both a **const 6-question list** (the fallback) and a **JSON-loaded catalog**. If Plan 3 only edits the JSON, the const fallback drifts. Either (a) update both, or (b) explicitly document the const is intentionally frozen and the JSON wins at runtime. Same dual-source applies to `nameAnchors` const vs `name_anchors.json`. Add a Task 4 sub-step.

## Summary patch list

1. Replace `<scoring_file>` with `lib/core/constants/discovery_quiz.dart`, `computeDiscoveryAnchors` with `calculateQuizResults`.
2. Update baseline "10–15" → "32"; consider raising the ≥40 target.
3. Simplify regex to `^[a-z]+(-[a-z]+)+$`; add membership assertion against `nameAnchorsCatalog.keys`.
4. Fix example slugs (`al-lateef`/`al-baseer`/`al-ghafur`/`al-haleem` → canonical or add to name_anchors).
5. Add a Plan 0 dependency note if any new slug lacks anchor metadata.
6. Drop "fresh install" from simulator pre-step; bundle id = `com.sakina.app.sakina`.
7. Add a Task to keep the Dart const fallback in sync with JSON (or document it as frozen).
