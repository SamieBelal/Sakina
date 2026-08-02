# §7–§9 Content + History QA Plan — `verify20260422b@sakinaqa.test`

Sim-only pass. Builds on accumulated state. UDID `E1152EC8-6A80-4966-92D9-7D7425A81CD2`.

ui-map covers Home, Reflect, Journal detail, Share preview. Duas tab, Build-a-Dua,
Discovery quiz, Journal list filters are **unmapped**. Extend `ui-map.md` as we go.

Evidence convention: screenshots → `docs/qa/runs/2026-04-26-content-history/screenshots/<test-id>-<step>.png`.
Run log → `docs/qa/runs/2026-04-26-content-history.md` (one line per test ID, PASS/FAIL + DB snippet or screenshot path).

## Pre-state snapshot (run before anything)

```sql
select id from auth.users where email='verify20260422b@sakinaqa.test'; -- capture <uid>
select onboarding_completed from public.user_profiles where id=<uid>;
select count(*) as reflections from public.user_reflections where user_id=<uid>;
select count(*) as built_duas from public.user_built_duas where user_id=<uid>;
select balance, tier_up_scrolls from public.user_tokens where user_id=<uid>;
select reflect_uses, built_dua_uses from public.user_daily_usage
  where user_id=<uid> and usage_date=current_date;
select anchor_names, completed_at from public.user_discovery_results where user_id=<uid>;
select count(*) as cards from public.user_card_collection where user_id=<uid>;
```

Save these numbers. Every assertion below is delta-based against this baseline.

## §7 Duas

### Step 0 — Recon (do this BEFORE writing assertions)

The current `lib/features/duas/screens/duas_screen.dart` appears to be Build-a-Dua only;
`manual-test-plan.md` §7's "browse list + categories + favorite" UI may not exist in the
shipped build. Confirm before scripting D-Browse.

1. Tap Duas tab `(280, 812)`.
2. `screenshot` + `ui_describe_all`. Record into `ui-map.md`.
3. Branch:
   - **If browse list exists:** grep source for the actual favorite-storage key/column,
     write D-Browse assertions against that. Update plan inline.
   - **If only Build-a-Dua exists:** mark D-Browse N/A. File finding
     `docs/qa/findings/2026-04-26-duas-browse-aspirational.md` with code pointer.

### D-Build (happy path + economy)

Pre-state for this section:
```sql
select count(*) as built_before from public.user_built_duas where user_id=<uid>;
select built_dua_uses as uses_before from public.user_daily_usage
  where user_id=<uid> and usage_date=current_date;
select balance as tokens_before from public.user_tokens where user_id=<uid>;
```

1. Map Build-a-Dua input field, Build button, loading state, result card, Save button.
2. Submit on-topic need ("guidance for a hard decision").
3. Result renders: Arabic + transliteration + translation + source Name + verses.
4. Save. Assertions:
   - `select count(*) from public.user_built_duas where user_id=<uid>` = `built_before + 1`.
   - New row's `need`, `arabic`, `transliteration`, `translation` populated.
   - `built_dua_uses` = `uses_before + 1` (if user was within free quota).
   - If quota exhausted, `tokens` balance decremented by per-build cost (read code at
     execution time — `daily_usage_service.dart` + `duas_provider.dart:417,501`).

### D-Edge

| ID | Case | Steps | Assertion |
|---|---|---|---|
| D-E1 | Off-topic | Submit "pizza recipe" | Off-topic UI; **no** new `user_built_duas` row; `built_dua_uses` unchanged |
| D-E2 | AI failure | Submit → toggle airplane mid-flight | Error snackbar; no row; counter unchanged |
| D-E3 | Persistence | Build+save → kill app → relaunch → Journal tab | Built dua present in Journal |
| D-E4 | Free-limit gate | Seed `update public.user_daily_usage set built_dua_uses=<limit> where user_id=<uid> and usage_date=current_date;` then attempt build | Token gate / upgrade overlay; **counter unchanged** after blocked attempt (re-query and assert no increment); no new `user_built_duas` row |
| D-E5 | Duplicate tap | 2 rapid taps on Build | Only one `user_built_duas` row; `built_dua_uses` +1 only |

Restore after §7:
```sql
-- if D-E4 polluted the counter, reset to pre-state value
update public.user_daily_usage set built_dua_uses=<uses_before>
  where user_id=<uid> and usage_date=current_date;
```

## §8 Discovery quiz

Pre-state:
```sql
select anchor_names, completed_at from public.user_discovery_results where user_id=<uid>;
-- capture original_anchors for restore
```

### DQ-Fresh (only if no anchors)

If `user_discovery_results` is empty, skip to DQ-Retake. If populated, capture and
optionally wipe-and-rerun.

1. Settings → "Take the Quiz" CTA OR launch overlay.
2. Map quiz screens: question card, answer chips, progress indicator, results screen.
3. Answer each question → results show 3 Names.
4. Assertion:
   ```sql
   select anchor_names, completed_at from public.user_discovery_results where user_id=<uid>;
   ```
   `anchor_names` length = 3, `completed_at` ≈ now.
5. Settings → "Your Anchor Names" displays the 3 names.

### DQ-Retake

1. After capturing original_anchors, wipe:
   ```sql
   delete from public.user_discovery_results where user_id=<uid>;
   ```
2. Re-enter quiz from Settings → fresh path → new anchors written.
3. Assertion: exactly ONE row in `user_discovery_results` for this user (overwrite,
   not append):
   ```sql
   select count(*) from public.user_discovery_results where user_id=<uid>; -- expect 1
   ```
4. If schema appends (count > 1), file finding.

Restore after §8:
```sql
-- restore original anchors if test pollution matters for downstream sessions
delete from public.user_discovery_results where user_id=<uid>;
insert into public.user_discovery_results (user_id, anchor_names, completed_at)
  values (<uid>, <original_anchors>, <original_completed_at>);
```

### DQ-Edge

| ID | Case | Assertion |
|---|---|---|
| DQ-E1 | Quit mid-quiz, re-enter | Either resumes at last question OR cleanly restarts. File finding either way (intent unclear). |

**Removed: DQ-E2 (anchors feed Reflect).** Demoted to product finding —
`docs/qa/findings/2026-04-26-anchor-injection-unobservable.md`. Verifying anchor
injection into the AI prompt requires server-side log access we don't have today.
Not testable from the client.

## §9 Journal

Pre-state:
```sql
select count(*) as reflections_before from public.user_reflections where user_id=<uid>;
select count(*) as built_before from public.user_built_duas where user_id=<uid>;
select count(*) as cards_before from public.user_card_collection where user_id=<uid>;
```

### J-List

1. Journal tab `(360, 812)`. Map filters/tabs, list ordering, empty state copy.
2. UI list count == `reflections_before + built_before` (post-§7 D-Build, +1 from that test).
3. Newest-first: top card's `saved_at` matches `max(saved_at)` from union of both tables.

### J-Detail

1. Tap top reflection → detail. Verify body matches DB row: `user_text`, `name`,
   `name_arabic`, `story`, `verses`, `dua` sections.
2. Back → tap a built dua → detail renders Arabic + translation + source.
3. Long `user_text` → truncates in list, full in detail.

### J-Delete

1. From detail header trash icon `(322, 94)` → confirm dialog → delete.
2. Assertions:
   - `select id from public.user_reflections where id=<id>;` returns 0 rows.
   - List count = previous − 1.
   - **Cross-feature:** `select count(*) from public.user_card_collection where user_id=<uid>;`
     unchanged (`= cards_before`).

### J-Edge

| ID | Case | Steps | Assertion |
|---|---|---|---|
| J-E1 | Delete then immediate back | Delete → back to list | List re-renders without deleted item; no ghost row |
| J-E2 | Share preview opens | Tap share `(370, 94)` → Cancel | Preview opens; cancel closes without crash. **Do NOT trigger native share.** |
| J-E3 | Empty state | SKIPPED — wrong account | File follow-up plan against `fresh@test.sakina` |
| J-E4 | Delete during network failure | Tap delete → confirm → toggle airplane mid-flight | Either row stays + clear error UI, OR row removed both client + server. **Critical:** verify next relaunch matches what user saw — no ghost row reappearing. Re-toggle airplane off, re-query DB. |

Restore after §9:
```sql
-- if J-Delete or J-E4 removed a row needed for downstream sessions, note the deleted
-- id; do not auto-restore (user_reflections has many rows and the test is destructive
-- by design). The deletion is part of the accumulated state for the next pass.
```

## Execution order

1. Pre-state SQL snapshot.
2. §7 Step 0 recon — branch plan based on findings.
3. §7 D-Build → D-E1 → D-E2 → D-E3 → D-E4 → D-E5. Restore counter.
4. §9 J-List + J-Detail (uses §7 built dua as fresh content).
5. §9 J-Delete + J-E1 + J-E2 + J-E4 (J-E4 last because it's the most disruptive).
6. §8 DQ — capture original anchors, run retake, restore.

## ui-map.md additions (deliverable)

- **Duas tab** — keyboard-down + keyboard-up input states, Build button, loading,
  result card, Save button. Plus browse list IF it exists (per Step 0 recon).
- **Discovery quiz** — question card, answer chips, progress indicator, results
  screen with 3 anchor cards.
- **Journal list** — filter tabs (if any), list card frame, share/delete header
  icons (already partly mapped).
- **Token gate (Build-a-Dua)** — distinct from Reflect's token gate; capture if
  different.

## NOT in scope (explicit)

- Cross-user RLS isolation for §7 duas (manual L315) → defer to §17 sweep.
- Empty Journal state → needs `fresh@test.sakina`, separate plan.
- Native iOS share sheet end-to-end (J-E2 stops at preview).
- Server-side anchor injection into Reflect AI prompt (was DQ-E2).
- Build-a-dua audio (not in current build).
- Token cost numerics — verify against code at exec time, don't hard-code in plan.
- Manual-test-plan §7 browse flow — pending Step 0 recon.

## Findings to file (regardless of PASS/FAIL)

- Missing analytics for: dua build/save/share, journal open/delete/share, discovery
  start/answer/complete. Same gap class as core loop. Cite
  `lib/services/analytics_events.dart`.
- `manual-test-plan.md:329` references wrong table `discovery_results` — actual is
  `user_discovery_results`.
- `manual-test-plan.md:305` references SharedPref keys
  (`saved_browse_dua_ids`, `saved_built_duas`, `saved_related_duas`) that don't exist
  in `lib/`. Either stale doc or unimplemented feature.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR | 3 decisions resolved (A1/B1/C1), 4 direct-fixes applied, 1 critical gap closed (J-E4) |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**UNRESOLVED:** 0

**VERDICT:** ENG CLEARED — ready to execute. CEO/Design reviews not applicable
(QA test plan, not product/UI change).
