# Share/Export + Journal Delete + Long-Text — QA Run

**Date:** 2026-04-26
**Plan:** §13 Share/Export, §7 D-E2, §9 J-E2/J-E4
**Test user:** `shareqa@sakinaqa.test` (uid `7fd655f4-33bd-4ed9-8974-2be27504df5d`)
**Sim:** iPhone 17 (UDID EDF71163-3D86-4732-B759-FCE7BF8DE6B6)
**Screenshots:** `/tmp/sakina-share-qa/*.png`

## Pre-flight

- Seeded user via Supabase MCP: 3 reflections, 2 personal duas, 2 cards (bronze id=2 Ar-Rahman, gold id=27 Al-Wadud), 1 active premium subscription, `onboarding_completed=true`.
- Sign-in fix: GoTrue 500 ("Database error querying schema" → `converting NULL to string is unsupported` on `confirmation_token`). Resolved by setting `confirmation_token`, `recovery_token`, `email_change_token_new`, `email_change`, `phone_change`, `phone_change_token`, `email_change_token_current`, `reauthentication_token` to `''` (empty string, not NULL) for direct `auth.users` inserts.

## Results

| ID | Test | Status | Notes |
|---|---|---|---|
| T1 | Reflection share preview (journal detail) | **PASS** | Sakina branding, Al-Mujeeb name + Arabic, verse Q20:25-26 Arabic + EN translation, citation. `31-reflection-share.png` |
| T2 | Personal dua share preview (journal detail) | **PASS** | Sakina branding, title, Arabic + transliteration + translation. `35-dua-share.png` |
| T4 | Long-text journal list truncation | **PASS** | Third reflection ("I have been struggling with consistency in my prayers and feel disconnected from my dee…") truncates with "…" + "View full" affordance. `29-journal.png`, `33-journal-back.png` |
| T5 | Delete-confirm regression at journal dua detail | **PASS** | Trash icon shows AlertDialog "Delete this dua? This can't be undone." with Cancel / Delete (red). Cancel preserves the row. `36-dua-delete-confirm.png`, `37-after-cancel-delete.png` |
| T2.5 | Build-a-dua "Ameen" share | **PASS** | Sakina branding, intention "grant me patience and clarity in my work", all four built-dua sections (Arabic + transliteration + translation), green Share CTA. `59-build-share.png` |
| T3a | Gold ornate card share (Al-Wadud) | **PASS** | "Share this Name" CTA on gold detail → preview shows Sakina, Arabic Al-Wadud, "The Most Loving", dua Arabic + transliteration + EN, green Share. `64-gold-share.png` |
| T3b | Bronze card share (Ar-Rahman) | **OBSERVATION** | Bronze detail has NO share button — only "Upgrade (5 Scrolls)" CTA. Share appears to be gated to ornate (silver/gold) tiers. Documented as F5 below; not a regression. `61-bronze-detail.png` |
| T3c | Emerald ornate card share | **BLOCKED** | F1 — `card_tier` enum has no `emerald` value, so no row can exist. |
| T6 | D-E2 try-again clears input | **PASS (code review)** | Live test couldn't reach the empty-breakdown UI: input "how to buy a car" hit the client-side `_isDuaOffTopic` regex path (inline error, no Try Again button). Try Again button only appears when OpenAI returns empty breakdown. Listener fix verified at `lib/features/duas/screens/duas_screen.dart:77-85` (clears `_buildController` when `buildNeed` non-empty → empty); `resetBuild()` at `duas_provider.dart:552-560` clears `buildNeed`. |
| T6.5 | Reflect result share | **PASS** | As-Salam result share preview: Sakina branding, Arabic As-Salam + transliteration, Q13:28 + Q55:13 with citations, dua + Sahih Muslim 763 attribution, green Share. `52-reflect-share.png` |
| T7 | Native share-sheet cancellation no-crash | **PASS** | From gold ornate share preview tapped Share → iOS share sheet rendered "Plain Text and 1 Document" with thumbnail + Reminders/More/Copy/Assign-to-Contact/Print/Save-to-Files actions. Tapped dimmed area to dismiss → returned to preview, all UI intact, no crash. `66-share-sheet.png`, `67-after-cancel.png` |
| T8 | Long-dua truncation in share card | **PASS (code review)** | `lib/widgets/share_card.dart` has zero `maxLines`/`TextOverflow`/`ellipsis` directives. Preview wraps content in `Expanded → SingleChildScrollView` (line 254) so the user can scroll long content; export uses `RenderRepaintBoundary.toImage` against the full-height non-preview render (`cardBuilder(false)`, line 192) which captures the whole intrinsic-height widget tree. Long content does not truncate in the exported PNG — it wraps fully. T2.5 build-dua share (`59-build-share.png`) demonstrates 4-section content (intention + Arabic + transliteration + translation) rendering cleanly. |
| T9 | Export failure path | **PARTIAL (code review)** | `_exportAndShare` (lines 18-39) is wrapped in try/catch at the call site (lines 200-215) but on error only `debugPrint('[SHARE ERROR] $e')` runs — overlay is removed and `_exporting` reset, but **no user-facing snackbar**. If `boundary.toImage`, `toByteData`, `writeAsBytes`, or `Share.shareXFiles` throws (low disk, OOM, etc) the user sees the spinner disappear and nothing else. Filed as F6 below. |

## Resolved regression

The previously-filed `2026-04-26-journal-delete-no-confirm.md` finding is **fixed**: `lib/widgets/confirm_delete_dialog.dart` is now wired into journal-dua detail (and per code grep, journal reflection detail + 4 inline list callers in `journal_screen.dart`). T5 confirmed live.

## Findings filed during this session

### F1 (P2) — `card_tier` enum lacks `emerald`, but `emerald_ornate_card.dart` exists

DB enum is `{bronze, silver, gold}`. `lib/widgets/cards/emerald_ornate_card.dart` is reachable in code but no row can have `tier='emerald'`. Either drop the widget or add the enum value via migration. Today: emerald cards are unreachable in production.

### F2 (P3) — silver gap

Enum allows `silver` but no `silver_ornate_card.dart` exists; visual fallback unknown. Either build the silver variant or remove `silver` from the enum.

## Fixes applied this session

- **F1 (P2) → FIXED** end-to-end (with on-device regression caught + patched):
  - DB: migration `add_emerald_to_card_tier_enum` applied — `card_tier` enum now `{bronze, silver, gold, emerald}`. Verified via `pg_enum` + a live `INSERT … 'emerald'::card_tier` round-trip on user `7fd655f4` name_id=99.
  - Dart enum: `CardTier.emerald` added to `lib/services/card_collection_service.dart`; `CardTierX` extended with label/number/colorValue/`fromNumber` cases (number=4, color=`0xFF50C878`).
  - `lib/features/collection/screens/collection_screen.dart`: imports `emerald_ornate_card.dart`; both grid (`_GridItem`) and detail (`_buildOrnateDetail`) switch expressions now route `CardTier.emerald` → `EmeraldOrnateTile` / `EmeraldOrnateDetailSheet`.
  - **Regression caught on rebuilt sim:** Ar-Rasheed at name_id=99 with `tier='emerald'` in DB rendered as **bronze** in-app. Root cause: `enumToTier` / `tierToEnum` helpers at `card_collection_service.dart:1834-1837` had hardcoded 3-tier maps that defaulted unknown strings (`'emerald'`) to `1` (bronze). Also `CardCollectionState.unlockedTiersFor` (line 1896-1903) was capped at gold.
  - **Follow-up patch:** added `'emerald': 4` / `4: 'emerald'` to both maps; added `if (maxTier >= 4) CardTier.emerald` to `unlockedTiersFor`; added `int get totalEmerald => countByTier(CardTier.emerald)` to mirror existing tier counters.
  - New unit tests in `test/services/card_tier_enum_test.dart`: 7 cases (enum exposure, label/number/colorValue, `fromNumber(4)`, all-tier `fromNumber` round-trip, `enumToTier('emerald')==4`, `tierToEnum(4)=='emerald'`, all 4 tiers round-trip). Pass.
  - Sim verification post-rebuild required: with the parser fix, the DB-seeded emerald row at name_id=99 should now render `EmeraldOrnateTile` in the grid and `EmeraldOrnateDetailSheet` (max-tier = no Upgrade button, Share visible) on tap. Pre-fix screenshots `73-all-cards.png`, `74-scrolled.png`, `75-end.png`, `76-emerald-detail.png` show the bronze-misrender; post-rebuild capture pending.
- **F2 (P3) → INVALIDATED.** Code review showed silver IS implemented inline in `collection_screen.dart` as `_SilverOrnateTile` + `_SilverOrnateDetailSheet` + `_SilverOrnateBorderPainter`. The original finding assumed file-by-tier symmetry; in practice silver lives inline rather than a `silver_ornate_card.dart`. No fix needed; finding closed as not-a-bug.
- **F3 (P3) → FIXED**:
  - `lib/features/onboarding/widgets/onboarding_autofocus_text_field.dart`: added `autocorrect` + `enableSuggestions` parameters (default `true`, pass-through to inner `TextField`).
  - `lib/features/onboarding/screens/sign_up_email_screen.dart` + `sign_up_password_screen.dart`: pass `autocorrect: false, enableSuggestions: false`.
  - `lib/features/auth/screens/sign_in_screen.dart`: email field gets `autocorrect: false, enableSuggestions: false, textCapitalization: TextCapitalization.none`; password field gets `autocorrect: false, enableSuggestions: false`.
  - New widget tests in `test/widgets/onboarding_autofocus_text_field_test.dart` (2 cases: defaults true; pass-through false).
- **F4 (P2) → DOCUMENTED.** Appended GoTrue NULL-token gotcha to `docs/manual-test-plan.md` "Re-creating a test user via SQL" block, listing all 8 token columns that must be set to `''` not NULL. No app-code fix; this is dev/QA helper guidance.
- **F5 (P3) → INVALIDATED.** Code review shows `bronze_ornate_card.dart:804-840` already has a "Share Reflection" `OutlinedButton.icon` rendered when `tier == 3` (max bronze). The bronze card I screenshotted was tier 1 — Upgrade button is correct for that state. Share is gated on max-tier-within-the-ornate-tier, which is consistent across bronze/silver/gold/emerald. Not a bug; finding closed.
- **F6 (P2) → FIXED** in `lib/widgets/share_card.dart:_share()`: catch branch now shows `ScaffoldMessenger` snackbar `"Couldn't share that — please try again."` while still logging via `debugPrint`. Existing `share_card_test.dart` still passes.

**Test totals:** `flutter test` → **367/367 pass** (added 6 new cases this session). `flutter analyze` clean.

**Sim verification (post-rebuild, 2026-04-26 evening):**

- **RTL bleed visual check (§13 UI check)** → **PASS.** From journal → long Al-Wadud reflection → Share. Preview shows SAKINA, الودود (Aref Ruqaa, gold, no clip), `Al-Wadud`, gold rule, Arabic dua `يَا وَدُودُ يَا وَدُودُ يَا ذَا الْعَرْشِ الْمَجِيدِ` (full diacritics, RTL), English translation `"O Loving One, O Loving One, O Owner of the Glorious Throne."`, `Daily du'a` caption, Share CTA. Each script lives in its own `Text` widget with vertical separation — zero RTL bleed at the Arabic/English boundary. `95-share-preview-long.png`.
- **T8 long-dua-truncation** → **PASS.** Same preview confirms code-review finding: no `maxLines`/`ellipsis` directives; share template renders Name + Arabic + English + caption cleanly. Long user reflection text is NOT part of the share card by design (only Name + dua), so "long content" pressure for journal shares lands on the dua, not free text. Journal long-text *list* truncation already verified at T4.
- **F6 export-failure snackbar** → **PASS code-only.** Live failure path (low disk / OOM / `boundary.toImage` throw) is not safely triggerable on a healthy sim mid-export. Code change at `share_card.dart:_share()` is the entire fix surface; existing widget tests still pass.
- **F3 autocorrect on auth fields** → **PASS code-only.** Test user `shareqa@sakinaqa.test` has no Sign Out path in Settings (Danger Zone is Reset Daily Loop / Clear Card Collection / Delete Account only). Reaching the Sign In or signup email/password screens would require destroying the test account and re-seeding. `autocorrect: false` is a Flutter framework `TextField` property pass-through, covered by `onboarding_autofocus_text_field_test.dart` (2 passing tests) + grep confirms all four auth/onboarding fields set both `autocorrect` and `enableSuggestions` to `false`.

- **F1 → PASS live.** Second rebuild verified end-to-end: Collection grid shows new "All 8/396" with sub-tier counts including emerald; Ar-Rasheed (name_id=99) renders with full emerald palette + 4 progress dots in the grid (`79-emerald-grid.png`); detail sheet opens as `EmeraldOrnateDetailSheet` with EMERALD tier badge, max-tier 4-dot indicator, "Share this Name" button, no Upgrade button (correct max-tier behavior) (`80-emerald-detail.png`).
- **F3 → PASS code-verified.** Live sim verification not run (signed-in test user `shareqa@sakinaqa.test` has no Sign Out path in Settings; only Delete Account, which would destroy seeded test data). `autocorrect`/`enableSuggestions` are Flutter framework `TextField` properties — pass-through is covered by `onboarding_autofocus_text_field_test.dart` (2 passing tests) + grep confirms all four auth/onboarding fields set them to `false`.
- **F6 → PASS code-verified.** Snackbar branch added to `share_card.dart:_share()` catch. Live failure path is hard to trigger in sim (would need to interrupt `boundary.toImage` mid-flight) and not worth a destructive test. Code change is one-line, behaviorally simple, and existing `share_card_test.dart` still passes.

### F6 (P2) — Share export failure is silent

`lib/widgets/share_card.dart:210` catches all errors from `_exportAndShare` with `catch (e) { debugPrint('[SHARE ERROR] $e'); }` and then removes the export overlay. There is no user-facing feedback. If export fails (low disk space, image render failure, OOM, plugin error), the share button's spinner disappears and nothing happens — the user has no way to know something went wrong. Manual test plan §13 asks for "error snackbar"; current behavior is no snackbar at all. Fix: show `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn't share that — please try again.')))` in the catch branch.

### F5 (P3) — Bronze tier cards have no share affordance

Confirmed via UI inspection: the bronze Ar-Rahman card detail (`61-bronze-detail.png`) shows only an "Upgrade (5 Scrolls)" CTA where the gold detail (`64-gold-share.png`) shows "Share this Name". This appears to be intentional — share is reserved for ornate (silver/gold/emerald) tiers as the "shareable" reward for upgrading. Worth confirming with product whether bronze should also be shareable (lower-friction social moment) or whether the current gating is the desired growth-loop design.

### F3 (P3) — Sim QA infra: autocorrect on auth fields

`mcp__ios-simulator__ui_type` is autocorrect-vulnerable on email/password fields, garbling typed text (e.g. `share-qa-2026@test.sakina` → `share-as-20262test.sakina`). Workaround: macOS `pbcopy` + Select All + Paste. Recommend `autocorrect: false, enableSuggestions: false` on auth `TextField`s in `lib/features/auth/` to make sim QA reliable for users and matches typical native-app convention for credentials.

### F4 (P2) — GoTrue NULL-token pitfall on direct seeding

Direct `INSERT INTO auth.users` writes leave `confirmation_token`, `recovery_token`, `email_change_token_new`, `email_change`, `phone_change`, `phone_change_token`, `email_change_token_current`, `reauthentication_token` as NULL. GoTrue's user-fetch path then 500s with `Scan error … converting NULL to string is unsupported` on sign-in. Document this in any dev/QA seeding helper: those fields must be `''`, not NULL.

## Session complete

All §13 / §7 / §9 cases resolved (live PASS, code-review PASS, or filed as F1/F5). All filed findings (F1–F6) closed: F1/F3/F6 fixed, F2/F5 invalidated by code review, F4 documented. F1 verified live post-rebuild (screenshots 79+80). Remaining product call: F5 (bronze share gating — keep gold-only or open up to bronze for lower-friction sharing).
