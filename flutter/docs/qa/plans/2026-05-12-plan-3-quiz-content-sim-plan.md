# iOS Simulator Test Plan — Plan 3 Discovery Quiz Expansion

**Date authored:** 2026-05-12
**Branch:** `feat/2026-05-12-plan-3-quiz-content`
**Plan:** [`2026-05-11-discovery-quiz-expansion.md`](../../superpowers/plans/2026-05-11-discovery-quiz-expansion.md)
**Authored by:** Agent (Opus 4.7). The simulator run is **deferred to the parent agent** — run this after Plan 4's agent reports back, so both 18-question expansion and any anchor backfill land together if Plan 4 also completes.

---

## What changed (under test)

- `assets/content/discovery_quiz_questions.json` grew from 6 → 18 questions.
- Every option now scores 3–6 Names with weights in `{1, 2, 3}` (was `{1, 2}` × 3 Names).
- `discoveryQuizQuestionsPublicCatalog.expectedCount` bumped 6 → 18 in `lib/services/public_catalog_contracts.dart`.
- Dart const `discoveryQuizQuestions` is now a frozen 6-question fallback (JSON wins at runtime).

## Test target

| Item | Value |
|---|---|
| Bundle ID | `com.sakina.app.sakina` |
| Simulator | iPhone 17 |
| UDID | `708E6FCA-05B0-4CEC-A372-1E9BAAA6E07E` |
| Logical viewport | 402 × 874 |
| Build command | `flutter run -d 708E6FCA-05B0-4CEC-A372-1E9BAAA6E07E --dart-define-from-file=env.json` |

No fresh install required — the quiz lives post-onboarding. Any existing signed-in account works. If the catalog is cached from a pre-Plan-3 install, force a refresh (cold-launch is enough — `bootstrapPublicCatalogs` re-validates against `expectedCount` and re-seeds from the bundled JSON on mismatch).

## Entry points to verify

1. **Home → "Discover Your Anchor Names" CTA** at approximately (201, 735) on the Home tab. Tap launches the quiz at Question 1.
2. **Settings → "Discover your anchors"** entry (per `lib/features/settings/screens/settings_screen.dart:257`).
3. **Progress → quiz entry** (per `lib/features/progress/screens/progress_screen.dart:156`).

Smoke-test entry #1 in every path below. Sanity-check entries #2 and #3 once at the end of the run (each should reach the same quiz UI).

## Coordinate map

| Element | Approx. coord |
|---|---|
| Home tab (bottom nav) | (40, 812) |
| "Discover Your Anchor Names" CTA | (201, 735) |
| Quiz progress bar | top of screen, full width, ~y=80 |
| Option 1 (first chip) | x=201, y≈300–340 |
| Option 2 | x=201, y≈380–420 |
| Option 3 | x=201, y≈460–500 |
| Option 4 (last) | x=201, y≈540–580 |
| Continue / Next button | (201, 780–820) |

Y-coords on options shift ±40 px depending on prompt line count (Plan 3 questions are slightly longer than the original 6). Use `mcp__ios-simulator__ui_describe_all` to locate elements deterministically before tapping.

## Three answer paths to test

For each path, walk the full 18 questions and capture the final result screen.

### Path A — "All option 1"

Tap the **first** option on every question (index 0). Expected: result-screen anchor list weighted toward the comfort/wisdom cluster (`as-sabur`, `at-tawwab`, `al-fattah`, `al-jamil`, `al-hadi`, `ash-shafi`).

### Path B — "All option 4" (or option 3 if a question only has 3 options)

Tap the **last** option on every question. Expected: anchor list weighted toward `al-wakil`, `ar-rabb`, `al-mujib`, `al-hadi`, `al-latif`.

### Path C — "Mixed alternating" (0, 1, 2, 3, 0, 1, 2, 3, …)

Cycle option indices `[0, 1, 2, 3]` across the 18 questions. Expected: a different primary anchor than Path A or Path B — spreads the score across more Names.

## Per-path procedure

For each path A / B / C:

```
mcp__ios-simulator__launch_app   bundleId=com.sakina.app.sakina
mcp__ios-simulator__ui_tap       x=40 y=812   # Home tab
mcp__ios-simulator__ui_tap       x=201 y=735  # "Discover Your Anchor Names"
```

Then loop 18 times:

```
mcp__ios-simulator__ui_describe_all      # confirm "Question N of 18" header
mcp__ios-simulator__screenshot           # save Q-N screenshot (path label in filename)
mcp__ios-simulator__ui_tap   <option coord for chosen index>
mcp__ios-simulator__ui_tap   <Continue / Next coord>
```

After the 18th tap, capture the result screen:

```
mcp__ios-simulator__screenshot           # final result
mcp__ios-simulator__ui_describe_all      # read anchor Names + body copy
```

## Required verifications

### Per-question (must hold on **every** question, every path)

- [ ] Progress indicator reads `Question N of 18` (or visual equivalent — `N/18`), **never** `N of 6`. This pins the JSON-loaded catalog.
- [ ] Prompt and 3–4 option chips render without truncation or RTL bleed.
- [ ] Tapping an option visibly selects it before Continue is enabled (matches existing UX).
- [ ] Continue/Next button advances to the next question and progress bar fills proportionally.

### On the final result screen (all paths)

- [ ] **2–3 anchor cards are shown** (top-3 from the aggregator).
- [ ] Each card renders the **anchor sentence** from `name_anchors.json` — e.g. for `al-latif`: `He works in the details you cannot see.` — **not** a raw slug like `al-latif`.
- [ ] Each card renders the **detail paragraph** (longer copy beneath the anchor).
- [ ] Each card shows the Arabic calligraphy hero (Aref Ruqaa) without overflow into the header.
- [ ] No card displays a slug-looking string (lowercase, dashes) as its title — that would indicate a Name escaped the anchor catalog.

### Cross-path verification (compare A vs B vs C)

- [ ] At least **2 distinct primary anchors** appear across the 3 paths (the property test pins this; the simulator confirms it end-to-end).
- [ ] The 3 paths feel meaningfully different — not just reordered versions of the same anchor list.

### Regression checks (back-compat with pre-Plan-3 behavior)

- [ ] **Original 6-answer paths still work.** Replay Path A but stop after question 6 (kill the app or back-navigate). The aggregator should still return non-empty results when fewer than 18 answers are provided (`calculateQuizResults` defends against this with `i < answers.length && i < questions.length`).
- [ ] Quiz still launches cleanly from **Home CTA**, **Settings entry**, and **Progress entry**.
- [ ] A user who already saved anchors from the 6-question version sees their saved anchors hydrate (covered by `discovery_quiz_test.dart` — sim sanity-check only).
- [ ] No console errors logged in the simulator output during the quiz flow (especially `[PublicCatalogService] discovery_quiz_questions validation failed`). If you see that error, the cached bundle is stale — kill the app, delete the app data, relaunch.

## Failure-mode checklist (what to flag back)

If any of the following surface during the run, capture a screenshot and flag in the report:

- Slug rendering (e.g. `al-fattah` displayed as title instead of "Al-Fattah" with anchor sentence) → indicates an un-anchored Name leaked through (should be impossible per the coverage + property tests, but verify in the wild).
- Progress bar showing `of 6` → JSON didn't load; the frozen const fallback is being used. Check device logs for catalog-validation errors.
- Empty result screen → aggregator returned `[]`. Should not happen with 18 valid answers.
- Crash on the result screen → likely a missing anchor key. Capture stack trace from console.
- Visual regressions (text overflow, RTL bleed, Aref Ruqaa header bleed) → screenshot and reference `AdjustedArabicDisplay` notes in `CLAUDE.md`.

## Test plan execution log (filled by runner)

```markdown
### Run: 2026-05-XX

| Path | Q-count seen | Primary anchor | Anchor 2 | Anchor 3 | Slug leaks? | Notes |
|------|--------------|----------------|----------|----------|-------------|-------|
| A (all-0)   |  |  |  |  |  |  |
| B (all-last)|  |  |  |  |  |  |
| C (mixed)   |  |  |  |  |  |  |

Distinct primary anchors across 3 paths: __ / 3
Regression checks: __ / 4 passed
Visual issues: ___
```

## Out of scope for this run

- Verifying anchor copy for the 67 Names not yet in `name_anchors.json` — that's Plan 4. The quiz will never surface those Names today (the coverage test and the slug-membership guard pin this).
- Testing what happens if Supabase ships a *partial* refresh — covered by `public_catalog_service_test.dart` unit tests.
- Performance/load time of the quiz — not a Plan 3 deliverable.

---

**Caveat to flag in the PR description:** Coverage stays at the **32-Name ceiling** until Plan 4's anchor backfill lands. The Plan 3 coverage test currently asserts `>=32`; once Plan 4 ships, lift to `>=55` per the discovery-quiz-expansion plan and rebroaden the JSON scoring maps to reach the additional anchors.
