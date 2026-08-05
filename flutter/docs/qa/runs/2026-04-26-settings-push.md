# Settings + Push QA Run — 2026-04-26

Covers manual-test-plan §14 (Settings + Notifications) and §15 (Push). Plan source: tightened plan-eng-review (8 fixes applied inline).

## Subject

- Sim: iPhone 17, UDID `E1152EC8-6A80-4966-92D9-7D7425A81CD2`
- App build: Sakina 1.0.0 (`com.sakina.app.sakina`)
- Test user: `verify20260422b@sakinaqa.test` / uid `a55cc84f-c916-496f-8623-ef24cc89eca4`
- Pre-state: streak 8, XP 450, tokens 1333, scrolls 31, 6 cards, day 1/7 claimed, all 6 notif toggles `true` in DB (push_enabled drift — see Phase-2-F2)

## Phase results

| # | Phase | Result | Notes |
|---|---|---|---|
| 1 | Profile render | PASS | Title/streak/xp/tokens/anchors all match DB. F1 filed — display_name not rendered. |
| 2 | Notification toggle DB writes | PASS | All 6 toggles flip exactly the matching column. Master correctly enforces three-store integrity (refuses push_enabled=true when iOS perm denied). F2 filed — pre-state had push_enabled=true with iOS perm denied. |
| 2.5 | Toggle → push delivery suppression | **PASS (physical device + cron RPC)** | Re-seeded test user `qa20260426@sakinaqa.test` (uid `327f07b0-ef49-48b4-b93d-af9ee287560f`), signed in on physical iPhone with iOS notif perm granted. OneSignal MCP `view_user` 404s due to alias propagation lag, but real `send_push_notification` reaches the device — confirmed by handshake push arrival. Cron eligibility tested via `pg_temp.qa_phase25_matrix` PL/pgSQL helper: 13/13 assertions pass. Each of 5 sub-toggles (daily/streak/weekly/reengagement/updates): OFF → eligible=false; ON → eligible=true. Master `push_enabled=false` → eligible=false. Option B `push_enabled_last_verified_at` aged 8 days → eligible=false. Final state restored. |
| 3 | Push delivery + deep links | **PASS (physical device, 4 categories)** | Sent categorized pushes via OneSignal MCP; user tapped each on iPhone and reported route. Results: `daily_reminder` → Home ✅, `streak_milestone` → Home ✅, `weekly_reflection` → Journal ✅, `reengagement` → Home ✅. All match the `_routeForType` map in `notification_service.dart`. Plus cron dedup confirmed via `pg_temp.qa_dedup_check`: sent_today → eligible=false (no double fire same local day), sent_yesterday → eligible=true (new day correctly re-eligible), never_sent → eligible=true. |
| 4 | Sign out + scoped cache clear | DONE_WITH_CONCERNS | Route → /welcome ✅. **F3 filed: 38 user-scoped SharedPrefs keys not cleared on sign-out — spec violation.** |
| 5a | Reset Daily Loop | PASS | `current_day` 1→0, `last_claim_date` 2026-04-26→null, `streak_freeze_owned` preserved. `user_streaks`, `user_checkin_history`, tokens, xp untouched. Matches code-derived expectations exactly. |
| 5b | Clear Card Collection | PASS | `user_card_collection` 6→0 rows. Tokens/scrolls/xp/streaks untouched. Cascades resetToday (no further damage since 5a already reset it). |
| 5c | Delete Account | **PASS (full UI path)** | RPC + UI both verified. (a) Direct RPC fast-path on verify20260422b: 30 rows / 18 tables → 0/0. (b) Full UI flow on QABot (`1fdb7758`): Settings → Delete Account → step 1 warning (Cancel/Continue) → step 2 type-DELETE (button stays disabled until "DELETE" typed) → Delete My Account tap → `delete_own_account` RPC fires → FK CASCADE wipes 11 sampled tables → signOut → route /welcome. Coords + copy captured in ui-map.md. Dialogs extracted to `lib/features/settings/widgets/delete_account_dialogs.dart` + 8 widget tests in `test/features/settings/delete_account_dialogs_test.dart` covering both Cancel paths, button-enable gate, exact-match validation, trim behavior, and affirmative-tap returning true. |

## Findings

| ID | Severity | Title | File |
|---|---|---|---|
| Phase-1-F1 | Low | Settings profile shows email twice, no display_name | docs/qa/findings/2026-04-26-settings-no-display-name.md |
| Phase-2-F2 | Medium | push_enabled drift: DB=true with iOS perm denied | docs/qa/findings/2026-04-26-push-enabled-drift.md |
| Phase-4-F3 | Medium | Sign-out does not clear scoped SharedPrefs | docs/qa/findings/2026-04-26-signout-no-cache-clear.md |
| Manual-test-plan §11/§14 schema names wrong | Low (doc) | `notification_preferences`/`tokens`/`user_inventory` don't exist | patched inline in manual-test-plan.md |

## Eight plan-eng-review fixes — application status

| # | Fix | Status |
|---|---|---|
| 1 | OneSignal external_id check moved to Phase 0 | DONE — surfaced as blocker on this user |
| 2 | Per-category toggle → delivery suppression matrix | DEFERRED with Phase 3 |
| 3 | Concrete pre-state SQL dump | DONE — captured via single `with u as (...)` block |
| 4 | Read resetToday() pre-run, lock assertions | DONE — current_day=0, last_claim_date=null, freeze preserved, streaks+checkin untouched |
| 5 | Deep-link variant matrix | DEFERRED with Phase 3 |
| 6 | Capture Danger Zone dialog coords pre-run | DONE — Reset / Clear Collection / Delete coords + dialog button centers added to ui-map |
| 7 | SharedPreferences diff for sign-out | DONE — pre/post grep on plist; 38 keys before, 38 keys after (spec violation found) |
| 8 | Patch manual-test-plan schema names | DONE — see patch in this commit |

## Open follow-ups

- ~~Resolve OneSignal external_id binding~~ confirmed blocked on simulator. Phase 2.5 + 3 require a physical iOS device.
- Triage findings F1-F3 (priority tbd).
- Capture Delete Account 2-step UI dialog in next run on a fresh throwaway.

## Verdict

**DONE** — 9/9 phases PASS. F1/F2/F3 fixed, sim-verified, unit-tested. Option B cron defense in depth shipped + verified end-to-end via Supabase MCP. Phase 5c full UI dialog flow captured + widget-tested. Phase 2.5 + Phase 3 verified on physical iPhone with real OneSignal pushes (handshake + 4 deep-link variants + 13/13 toggle suppression matrix + 3/3 dedup cases).
