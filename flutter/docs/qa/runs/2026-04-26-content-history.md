# §7–§9 Content + History QA Run — 2026-04-26

Account: `verify20260422b@sakinaqa.test` (uid `a55cc84f-c916-496f-8623-ef24cc89eca4`)
Sim: iPhone 17, UDID `E1152EC8-6A80-4966-92D9-7D7425A81CD2`
Plan: `docs/qa/plans/2026-04-26-content-history-plan.md`
Screenshots: `docs/qa/runs/2026-04-26-content-history/screenshots/`

## Pre-state baseline

| field | value |
|---|---|
| reflections | 2 |
| built_duas | 0 |
| cards | 4 |
| tokens | 1167 |
| scrolls | 15 |
| reflect_uses_today | null |
| built_dua_uses_today | null |
| anchor_names | null (no DQ row) |

## Results

| ID | Test | Status | Evidence |
|---|---|---|---|
| §7 Step 0 | Recon Duas tab | ✅ PASS | Build-a-Dua only; browse UI does NOT exist. ui-map updated. ss `02-duas-tab.png` |
| D-Build | Happy path | ✅ PASS | `user_built_duas` 0→1, `need` matches input, save fires on Ameen tap. `built_dua_uses` 0→1. ss `04..10` |
| D-E1 | Off-topic input | ⚠️  **PARTIAL FAIL** | Off-topic UI ✓ ("This place is for your heart"), no row created ✓, BUT `built_dua_uses` 1→2 — counter incremented despite off-topic. Spec says shouldn't. ss `12-de1-offtopic.png`. **Filed as finding**. |
| D-E2 | AI failure | ⚠️ PARTIAL (proxy PASS, true live still deferred) | Sim has no programmatic airplane mode; ran kill-mid-flight as substitute. DB invariants hold: no orphan `user_built_duas` row, tokens unchanged. True API-failure branch (`try/catch` at `duas_provider.dart:528`) needs a debug-fail flag or `pfctl` to exercise. Run log: `docs/qa/runs/2026-04-26-deferred-cases.md`. |
| D-E3 | Persistence | ✅ PASS | Built dua survives kill+relaunch and renders in Journal. ss `16-journal.png` |
| D-E4 | Free-limit gate | ✅ PASS | Server-seeded counter to 3, kill+relaunch hydrates, gate fires correctly: "Daily limit reached / 3 free sessions / Spend 50 tokens / Not now". Counter unchanged on blocked attempt (3). Tokens unchanged (1333). Built_count unchanged (1). ss `15-de4-gate.png` |
| D-E5 | Duplicate tap | ✅ PASS (live follow-up 2026-04-26) | Re-run after Try-Again clear bug fixed. Free path: 2 rapid taps on Build → 1 AI call, SP counter +1. Token-spend path: 2 rapid taps on "Spend 50 tokens" → 1 AI call, balance 235→185 (not 135). Run log: `docs/qa/runs/2026-04-26-build-dua-de5-live.md`. Guard at `lib/features/duas/providers/duas_provider.dart:420` and `:431`. Unit tests: `test/features/duas/submit_build_reentry_guard_test.dart` (3/3 PASS). |
| §9 J-List | List + count | ✅ PASS | "3 entries" matches DB (2 reflections + 1 built dua). Stats card: 2 Reflections / 1 Duas / 2 Names / 8 Best streak. Newest-first ordering ✓. ss `16-journal.png` |
| §9 J-Detail | Built dua detail | ✅ PASS | Title "Dua", user_text matches, all 4 sections render (Praise / Salawat / Ask / Closing). ss `17-jdetail-dua.png` |
| §9 J-Delete | Delete row | ⚠️ **PARTIAL FAIL** | Server delete works (built_count 1→0), navigation auto-pops, list refreshes, cards unchanged ✓, BUT **NO confirmation dialog** before destructive delete. Manual-test-plan §9 line 348 mandates confirmation. **Filed as bug**. |
| §9 J-E1 | Delete + back | ✅ PASS | Implicit in J-Delete — list re-rendered without ghost row. |
| §9 J-E2 | Share preview | ✅ PASS (live follow-up 2026-04-26) | Reflection detail (Al-Mujeeb) → share icon → preview opens with SAKINA branding, Arabic + English verse, citation, no RTL bleed. Tap Share → native iOS share sheet with PNG document thumbnail visible. Run log: `docs/qa/runs/2026-04-26-deferred-cases.md`. |
| §9 J-E4 | Network failure mid-delete | ⚠️ CODE AUDIT (2 findings filed) | Sim airplane mode not viable from MCP. Code review found: (1) `removeSavedBuiltDua` has NO try/catch — silent data drift on failure (`docs/qa/findings/2026-04-26-built-dua-delete-no-rollback.md`); (2) `deleteReflection` rolls back correctly but Journal does not render the error → silent reappearance UX (`docs/qa/findings/2026-04-26-journal-no-error-toast.md`). Run log: `docs/qa/runs/2026-04-26-deferred-cases.md`. |
| §8 DQ-Fresh | First-time quiz | ✅ PASS | 6 questions answered. `user_discovery_results` row inserted with 3 anchors (Al-Wadud score 3, Al-Hakim score 3, As-Sami' score 2). `completed_at` populated. `row_count = 1`. ss `19-discovery-q1`, `20-discovery-results.png` |
| §8 DQ-Retake | Retake doesn't duplicate | ✅ PASS (live follow-up 2026-04-26) | Re-run after first-time. count(*)=1 unchanged across retake; `anchor_names` fully overwritten (As-Sabur/Al-Mujib/Al-Latif → Al-Wakil/Ar-Rabb/Al-Qayyum). Confirms `saveDiscoveryQuizResults` upsert with `onConflict: 'user_id'`. Run log: `docs/qa/runs/2026-04-26-discovery-retake-quit.md`. |
| §8 DQ-Quit | Quit mid-quiz | ✅ PASS (live follow-up 2026-04-26) | Killed at Q2 → cold-launch → quiz re-opens at Q1 (clean restart, no resume). No mid-quiz SP persistence; only `_discoveryQuizResultsKey` written on completion. Closes the spec ambiguity in `manual-test-plan.md §8` ("resumes... or restarts cleanly"): app **restarts cleanly**. |
| §8 DQ-Retake-CTA | Retake CTA visibility | ⚠️ UX gap (filed) | "Take the Quiz" button is gated on `_anchorNames.isEmpty` in both `settings_screen.dart:751` and `progress_screen.dart:507`. Users with existing anchors have **no shipping retake path**. `manual-test-plan.md §8` line "Re-entering quiz → shows prior results with option to retake" is unmet. Decision needed: surface a retake button or remove the spec line. |
| §8 DQ-E1 | Quit mid-quiz | ⏭ NOT RUN | Time. |

## Post-run state (delta from baseline)

| field | before | after | delta |
|---|---|---|---|
| reflections | 2 | 2 | 0 |
| built_duas | 0 | 0 | +1 then deleted |
| cards | 4 | 4 | 0 |
| tokens | 1167 | 1333 | +166 (quest rewards) |
| scrolls | 15 | 30 | +15 (quest line complete) |
| level | Lv 4 Hopeful | Lv 6 Patient | +2 |
| built_dua_uses | null | 3 | +3 (D-Build + D-E1 off-topic + manual seed) |
| anchor_names | null | 3 anchors | new |

## Bonus observation

Building first dua triggered a **"Quest Line Complete"** screen rewarding +100 tokens + 5 scrolls — first-time-completion of "First Steps" quest line (Your First Check-In, Reflect on a Feeling, Build Your Own Dua). Token economy works as designed.

## Findings filed

- `docs/qa/findings/2026-04-26-duas-browse-aspirational.md` — manual-test-plan §7 browse flow does not exist
- `docs/qa/findings/2026-04-26-build-dua-offtopic-counter.md` — off-topic build still increments counter
- `docs/qa/findings/2026-04-26-journal-delete-no-confirm.md` — destructive delete lacks confirmation dialog
- `docs/qa/findings/2026-04-26-build-dua-tryagain-no-clear.md` — Try Again preserves stale text
- `docs/qa/findings/2026-04-26-anchor-injection-unobservable.md` — DQ-E2 was demoted to product finding pre-run
- (Pre-existing) Stale doc: manual-test-plan.md:329 references wrong table `discovery_results` (actual: `user_discovery_results`); :305 references SharedPref keys with no source

## Verdict

§7 Build-a-Dua + §8 Discovery + §9 Journal core flows work. **3 real bugs found** (off-topic counter, delete-no-confirm, try-again-no-clear) plus confirmation that manual-test-plan §7 browse flow is aspirational. No crashes, no data corruption, no RTL bleed.
