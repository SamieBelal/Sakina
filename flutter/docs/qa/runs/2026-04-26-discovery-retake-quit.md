# §8 Discovery Quiz — Retake + Quit-Mid (live sim)

**Run date:** 2026-04-26
**Sim:** iPhone 17 (UDID `E1152EC8-6A80-4966-92D9-7D7425A81CD2`)
**Account:** `shareqa@sakinaqa.test` (uid `7fd655f4-33bd-4ed9-8974-2be27504df5d`)
**Tools:** `mcp__ios-simulator__*`, `mcp__supabase__execute_sql`, plistlib

## Why this run

Closes the two outstanding §8 cases from `docs/qa/runs/2026-04-26-content-history.md:39` (`DQ-Retake ⏭ NOT RUN`) and the unconfirmed quit-mid-quiz spec branch in `manual-test-plan.md §8` ("resumes at last question (or restarts cleanly — confirm intended behavior)").

## Setup

Pre-snapshot of original anchors (preserved for restore):
```
As-Sabur (5) / Al-Mujib (3) / Al-Latif (2)
```

To expose the "Take the Quiz" CTA on this user (it's gated on `_anchorNames.isEmpty` at `lib/features/settings/screens/settings_screen.dart:751` and `lib/features/progress/screens/progress_screen.dart:507`), the run cleared both server and local discovery state:
```sql
delete from public.user_discovery_results where user_id='7fd655f4-...';
```
```python
# plistlib: removed flutter.sakina_discovery_quiz_results_v1:<uid>
```
After the run the originals were restored via `update ... anchor_names = <jsonb>`.

## DQ-Quit — quit mid-quiz then re-enter

| Step | Observed |
|---|---|
| Settings → Take the Quiz | Quiz opens at "Question 1 of 6" |
| Tap an answer on Q1 | Auto-advance to "Question 2 of 6" |
| `xcrun simctl terminate ... com.sakina.app.sakina` | App killed mid-quiz |
| Cold-launch, dismiss notif dialog, Settings → Take the Quiz | Quiz opens at **"Question 1 of 6"** (not Q2) |

**Verdict: PASS.** Behavior matches the "restarts cleanly" branch. No mid-quiz SP persistence — only `_discoveryQuizResultsKey` is written, and only on `completeQuiz()` (`lib/features/discovery/providers/discovery_quiz_provider.dart:120-132`). `currentQuestion` and `selectedAnswers` live in StateNotifier memory only, so a kill wipes them; on re-entry `_loadSavedResults` finds no completed results → `ensureQuizReady` calls `startQuiz()` which resets to Q0. Screenshot: `/tmp/sakina-qa/dq/04-quit-restart-q1.png`.

## DQ-Retake — completing again overwrites, doesn't append

| Step | Observed |
|---|---|
| Pre: `select count(*) from user_discovery_results where user_id='<uid>'` | 0 (cleared in setup) |
| Walked through all 6 questions, choosing answers different from the original profile | OK |
| Results page rendered | "Your Anchor Names" with #1 Al-Wakil / #2 Ar-Rabb / #3 Al-Qayyum (different from original As-Sabur / Al-Mujib / Al-Latif) |
| Post: `select count(*) from user_discovery_results where user_id='<uid>'` | **1** (no duplicate row) |
| Post: `anchor_names` JSON | Al-Wakil (3) / Ar-Rabb (2) / Al-Qayyum (2) — full overwrite |

**Verdict: PASS.** `saveDiscoveryQuizResults` upserts with `onConflict: 'user_id'` (`discovery_quiz_provider.dart:152-157`). Single-row contract holds across retake. Screenshot: `/tmp/sakina-qa/dq/05-results.png`.

## Open finding (UX gap)

The retake CTA is **only visible when the user has zero anchors**. Both surface the button under `if (_anchorNames.isEmpty)`:
- `lib/features/settings/screens/settings_screen.dart:751` (`_buildAnchorNamesSection`)
- `lib/features/progress/screens/progress_screen.dart:507` (`_showDiscoveryQuiz`)

Once a user completes the quiz once, there is **no shipping path to retake it.** The quiz screen route `/discovery-quiz` exists (`lib/core/router.dart:86`) but no UI exposes it for an already-anchored user. `manual-test-plan.md §8` says "Re-entering quiz → shows prior results with option to retake" — that retake CTA does not exist in the running app. The QA shim for this run was: clear server row + local SP cache to make `_anchorNames` empty so the existing-empty-state CTA surfaces.

Action item (not in scope of this run): decide if a "Retake quiz" affordance belongs on Settings (under Anchor Names pills) or on Progress. If yes, file a tiny issue and wire `_openDiscoveryQuiz` to a button there. If no, remove the line from `manual-test-plan.md §8` so the spec stops promising a CTA that doesn't ship.

## Status

§8 — closed for this pass:
- DQ-First-time: PASS (prior run, `2026-04-26-content-history.md:38`).
- DQ-Quit: PASS (restarts cleanly, no resume).
- DQ-Retake: PASS (single row, full overwrite, no duplication).
- Open: retake CTA hidden once anchors exist — UX gap, not a regression.
