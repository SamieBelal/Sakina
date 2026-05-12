# Plan 0 Eng Review — Findings

## Verdict
NEEDS WORK — runner has two correctness gaps that silently corrupt the baseline; backfill script has minor gotchas that won't crash but will misnumber IDs.

## Findings (ranked)

[P0] (confidence: 9/10) Task 4 Step 2 — `RUN_LIVE_EVALS=1 flutter test test/evals/reflect_name_pick_eval.dart` does NOT pass `--dart-define-from-file=env.json`. Without it `Env.openAiApiKey` (a `String.fromEnvironment`) is empty, the guard at the top of the runner skips, and the baseline file is never written. The author will think it ran and `cp` an empty/missing `last_run.json`. **Fix:** Plan must say `RUN_LIVE_EVALS=1 flutter test --dart-define-from-file=env.json test/evals/reflect_name_pick_eval.dart`. Same correction needed wherever Plans 1/2/5 invoke the eval.

[P0] (confidence: 10/10) Runner has no demo-fallback detection. `ai_service.dart:608-642` returns `getDemoResponse()` (always `name: 'Al-Lateef'`) on missing key, network error, OpenAI 4xx/5xx, parse failure, or off-topic classification. A flaky API run returns Al-Lateef for all 25 rows. Any fixture row whose `expected_names` includes "Al-Lateef" silently passes; rows that don't fail for the *wrong reason* and the baseline is permanently poisoned. **Fix:** runner must detect demo fallback (e.g., `parsed.name == 'Al-Lateef' && parsed.reframe.startsWith("What you're feeling")`) and treat as a hard error, not a pass/fail row. Better: have `reflectWithOpenAI` surface a `wasDemoFallback` flag, or expose a non-fallback variant for testing.

[P1] (confidence: 8/10) Task 2 Step 1 — Python script emits `id: {n['id']}` straight from `collectible_names.json`. JSON id=1 is **"Allah"** (the proper Name, not one of the 99 attributes), id=2 is Ar-Rahman. The existing `allah_names.dart` is renumbered: Ar-Rahman is id=1, Ar-Raheem id=2, etc. Naive port either (a) introduces id=1 "Allah" and shifts every consumer that does `allahNames[dayOfYear % 99]` to land on "Allah" 1/99 days, or (b) creates a gap. `getTodaysName()` (line 142) is the live consumer. **Fix:** decide explicitly — either skip JSON id=1, or renumber the Dart const sequentially 1-99 and accept that "Allah" is now in the rotation. Plan currently says "preserving field order" but is silent on the id-1 question.

[P1] (confidence: 9/10) `_logClassifierDecision` (ai_service.dart:388) fires for every phrase in debug builds (`kDebugMode || isOffTopic`). `flutter test` runs in debug. Each eval row attempts a Supabase insert into `reflect_classifier_log`. The try/catch swallows the failure (Supabase isn't initialized in tests) but you'll get 25 `debugPrint` lines per run polluting CI output. Cosmetic, but worth a note in the plan or a `Supabase.initialize` in `setUpAll`.

[P1] (confidence: 7/10) Fixture rationale field is too thin. Example row uses `"Hidden-wisdom themes — Yusuf (AS) story families"` for a 3-name set. When a future reviewer sees the AI returned "Al-Hakeem" but the expected set was `[Al-Lateef, Al-Hakeem, Al-Khabeer]`, fine. But when the AI returns e.g. "As-Sabur", reviewer has no rubric to decide if that's also defensible. **Fix:** require rationale to include (a) the dominant emotion category and (b) why each name in the set qualifies AND a one-line "excluded because…" pattern, so out-of-set returns can be adjudicated consistently.

[P2] (confidence: 7/10) Task 4 Step 2 "establish baseline against the CURRENT (pre-Plan-1) code." Inconsistent — Plan 0 itself just grew `allahNames` from 16 → 99, which expands `buildCanonicalNamesPromptList()` (validate_names.dart:62) injected into the system prompt by `buildSystemPrompt`. Baseline is post-Plan-0, not pre-anything. That's fine as long as the plan says so. **Fix:** rename "pre-Plan-1" → "post-Plan-0, pre-prompt-changes" so future readers don't think the baseline reflects 16-name behavior.

[P2] (confidence: 9/10) Task 5 placeholder `<sakina bundle id>`. Actual bundle id is **`com.sakina.app.sakina`** (`ios/Runner.xcodeproj/project.pbxproj:514,701`). Inline it.

[P2] (confidence: 8/10) Coverage test loads `assets/content/collectible_names.json` via `File(...)` (relative). Works under `flutter test` (cwd = package root) but breaks if invoked from a worktree subdir. Existing tests in this repo use the same pattern, so non-blocking — flag only.

[P2] (confidence: 6/10) `_normalise` regex `^(al|ar|as|ash|at|az|an)` is order-sensitive — `As-` matches before `Ash-`, so `Ash-Shakur` → `hshakur` instead of `shakur`. Both sides of the lookup normalise identically so resolution works, but `findCanonicalName('Shakur')` (no prefix) → `shakur` ≠ `hshakur` → null. The AI sometimes returns bare "Shakur." Same pattern affects At-/An- vs words starting with `t`/`n`. **Fix:** out of Plan 0 scope, but worth a TODO since the eval will surface it.

## Recommended plan edits

1. Task 4 Step 2 command → `RUN_LIVE_EVALS=1 flutter test --dart-define-from-file=env.json test/evals/reflect_name_pick_eval.dart`. Propagate to Plans 1/2/5.
2. Task 4 Step 1 runner — add demo-fallback guard. Suggested:
   ```dart
   final isDemo = response.name == 'Al-Lateef' &&
                   response.reframe.contains("Al-Lateef is The Subtle One");
   if (isDemo) {
     fail('reflectWithOpenAI fell back to demo response for "$phrase" — API key missing or parse failed. Baseline aborted.');
   }
   ```
3. Task 2 Step 1 — clarify id handling: either drop `data[0]` (Allah) or accept the renumber. Add a one-line note in the Python loop: `if n['id'] == 1: continue  # skip 'Allah'` OR explicitly state Ar-Rahman becomes id=2.
4. Task 5 Step 1 — replace `<sakina bundle id>` with `com.sakina.app.sakina`.
5. Task 4 Step 2 — rename "pre-Plan-1" to "post-Plan-0, pre-Plan-1 (canonical 99 in prompt, original prompt-shape)."
6. Task 3 Step 2 — expand rationale schema: `{category, included_names: [{name, why}], excluded_pattern}`.

## Test gaps not yet in plan

- No test that `getTodaysName()` still produces sane output after backfill (the 99-entry rotation now includes "Allah" if id=1 is kept).
- No assertion that `parseReflectResponse` non-null for every eval row (i.e., the runner currently treats parse-failure-then-demo identically to a real answer).
- No "smoke" test that prevents the eval from running if `Env.openAiApiKey.isEmpty` and `RUN_LIVE_EVALS=1` — currently silently passes a no-op test. Should `fail()` instead.
- Coverage test asserts `transliteration` and `arabic` 1:1, but not `english`/`meaning`/`lesson`. A copy-paste typo in `meaning` survives.

## Failure modes

- **OpenAI 429 mid-run** → `reflectWithOpenAI` returns demo Al-Lateef → fixture rows with Al-Lateef in their set falsely pass, others fail → baseline is silently corrupted. Caught by: demo-fallback guard (fix #2).
- **CI runs `flutter test test/evals/...` without `--dart-define-from-file`** → silent skip → empty `last_run.json` → `cp` produces empty baseline → all future runs pass trivially. Caught by: fail-on-missing-key + presence-check before `cp`.
- **getTodaysName() picks "Allah" 1/99 days** → home rotation shows the generic name with surprising copy. Caught by: explicit decision in plan + a test pinning the rotation set.
- **Bare "Shakur" from AI** → `findCanonicalName` null → unknown-name fallback path engages even though Ash-Shakur exists. Caught by: a regression test in Plan 0 Task 1 covering prefix-stripped queries.
