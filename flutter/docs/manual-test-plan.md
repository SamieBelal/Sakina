# Sakina Manual + MCP Test Plan

Execution-oriented plan for verifying each major flow on a real device/simulator with database and analytics assertions. Covers **major flows** and **edge cases a daily user can realistically hit**. Deep edge cases (rare races, malformed server payloads, legacy migrations) are out of scope here — see `testing-plan.md` for those.

## How to use this doc

Each section has:
- **Preconditions** — DB / account / device state to seed before starting.
- **Steps** — what to tap/type on device.
- **UI checks** — what must appear/not appear on screen.
- **DB checks** — tables/rows to verify via Supabase MCP.
- **MCP calls** — analytics/push/billing assertions via Mixpanel, OneSignal, RevenueCat MCP tools.
- **Edge cases** — realistic things a daily user trips over.

## MCP tooling reference

| Purpose | Tool |
|---|---|
| Device control & screenshots | `mcp__ios-simulator__*` (launch_app, ui_tap, ui_type, screenshot, ui_describe_all) |
| DB state | `mcp__supabase__*` (run SQL against project) |
| Analytics verification | `mcp__mixpanel__Run-Query`, `Get-Events`, `Get-User-Replays-Data` |
| Push delivery | `mcp__onesignal__send_push_notification`, `view_message_history`, `view_user` |
| Billing state | `mcp__revenuecat__get-customer`, `list-subscriptions`, `list-purchases` |

## Test accounts to create before starting

Seed these in Supabase dev project so you can jump between states without re-running onboarding:

1. `fresh@test.sakina` — no rows anywhere. Used for full new-user flow.
2. `onboarded@test.sakina` — `user_profiles.onboarding_completed = true`, no check-ins, no cards, no entitlement.
3. `daily-user@test.sakina` — 7-day streak, ~500 tokens, 10 cards across tiers, 3 journal entries, 1 saved dua.
4. `premium@test.sakina` — same as #3 plus active RevenueCat entitlement.
5. `expired@test.sakina` — previously premium, entitlement lapsed.

Reset script (run before each full pass) — note actual seed-domain examples in this run used `@sakinaqa.test` (e.g. `qa20260426@sakinaqa.test`); pick whichever pattern your seed users follow and update the LIKE filter accordingly:
```sql
-- Supabase MCP: reset non-premium test users
select delete_own_account() -- call from client as each user, OR:
delete from auth.users where email like '%@test.sakina' or email like '%@sakinaqa.test';
-- cascades to user_profiles and scoped tables via FK CASCADE
```

**Re-creating a test user via SQL (no app onboarding needed):** the QA run on 2026-04-26 used a direct insert into `auth.users` + `auth.identities` (plus a backfill of `user_profiles.display_name`, `onboarding_completed=true`, and `user_notification_preferences` with `push_enabled=true, push_enabled_last_verified_at=now()`). Pattern is documented in the run log at `docs/qa/runs/2026-04-26-settings-push.md`. Note `auth.identities.email` is a generated column — do NOT include it in the insert column list. Password must be bcrypt'd via `crypt(plaintext, gen_salt('bf'))`.

**GoTrue NULL-token pitfall (F4 from `2026-04-26-share-export-pass.md`):** direct `INSERT INTO auth.users` writes leave these token columns NULL by default. GoTrue's user-fetch path then 500s with `Scan error … converting NULL to string is unsupported` on sign-in. **Always set them to `''` (empty string), never NULL:** `confirmation_token`, `recovery_token`, `email_change_token_new`, `email_change`, `phone_change`, `phone_change_token`, `email_change_token_current`, `reauthentication_token`.

---

## 1. Launch, routing, session hydration

**Preconditions:** fresh install OR toggle between test accounts.

**Steps + checks:**
- Fresh install launches → `/welcome` (Hook screen).
- Onboarded + signed-in → `/` (Home).
- Onboarded + signed-out → `/welcome`.
- Kill app from Home, relaunch → returns to Home (not Welcome).
- Sign out from Settings → `/welcome`, scoped caches cleared.

**DB checks (Supabase MCP):**
```sql
select id, onboarding_completed, created_at from user_profiles where id = auth.uid();
select count(*) from public.user_checkin_history where user_id = auth.uid();
```

**Edge cases:**
- Airplane mode on launch → loader shows, then graceful offline state (no crash).
- Relaunch mid-onboarding at page index N → resumes on same page.
- Switching accounts without reinstall → no data bleed (tokens, cards, journal all reset to new user's values).

---

## 2. Welcome + Auth

**Preconditions:** signed out.

**Steps:**
- Hook screen: "Get Started" → `/onboarding`, "Sign In" → `/signin`.
- Email sign-up happy path: valid email + 6+ char password + name → account created.
- Google sign-in → returns to in-flow onboarding (NOT paywall) if onboarding incomplete.
- Apple sign-in → same.

**UI checks:**
- Invalid email → inline error "Please enter a valid email".
- Password < 6 chars → Create Account button disabled.
- Duplicate email → snackbar "An account with this email already exists".
- Social auth cancel → user stays on Save Progress screen, no crash.

**DB checks:**
```sql
select u.email, p.display_name, p.onboarding_completed
from auth.users u left join public.user_profiles p on p.id = u.id
where u.email = '<email>';
-- After social auth resume, onboarding_completed should still be false and user should be mid-flow.
-- auth provider: inspect auth.identities.provider for the user, not user_profiles.
```

**Analytics (Mixpanel MCP):**
```
Get-Events filter: distinct_id = <user-id>, events: ['sign_up_started', 'sign_up_succeeded', 'social_auth_completed']
```
Each should fire exactly once.

**Edge cases:**
- User backgrounds during Apple sign-in modal, returns → no stuck spinner.
- Sign in as existing onboarded user → lands directly on Home, skips onboarding.

---

## 3. Onboarding (20+ pages)

**Preconditions:** fresh signup, `onboarding_completed = false`.

Canonical page order (confirmed 2026-04-22 via sim walkthrough):

0. First Check-in (emotion input + NameRevealOverlay + Result teaser)
1. Name (display name)
2. Age range
3. Intention
4. Prayer frequency
5. Quran connection
6. 99 Names familiarity
7. Resonant Name picker (becomes first card)
8. Dua topics (multi + "on your heart" text)
9. Common emotions (multi)
10. Aspirations (pick up to 3)
11. Daily commitment minutes
12. Attribution (multi)
13. Encouragement interstitial ("You're not alone…")
14. Reminder time
15. Notifications opt-in
16. Commitment pact ("Tap to commit")
17. Personalization plan summary ("Your plan, <name>")
18. Value prop (Daily check-in / 99 Names / Journal)
19. Social proof (4.9 stars + testimonials)
20. Save Your Progress (Apple / Google / Email)
21. Email input
22. Password input
23. Encouragement ("Something beautiful awaits you, <name>")
24. Paywall

Walk each page in order. For every page:

**Per-screen checks:**
- Headline + illustration render.
- Continue disabled until valid selection (where applicable).
- Back button returns to prior page preserving prior answer.
- Progress bar segment matches page index (0–18). Paywall (19) has no progress bar.
- Kill app → relaunch resumes on same page with answers intact.

**Special per-page notes:**
- **Page 0 (First Check-in):** text field auto-focuses, emotion chips tappable, submit triggers `NameRevealOverlay`. Continue only after reveal dismissed.
- **Page 1 (Name):** entered display name must appear on page 17 ("Your plan, <name>") and page 23 ("Something beautiful awaits you, <name>").
- **Page 15 (Notifications):** tapping "Enable Notifications" triggers iOS system prompt exactly once (only if OS permission not already granted). Tapping "Not now" does NOT trigger it. Skip still advances.
- **Page 24 (Paywall):** see §4.

**DB checks after completing onboarding:**
```sql
select onboarding_completed, display_name, onboarding_intention,
       onboarding_quran_connection, onboarding_familiarity,
       onboarding_struggles, onboarding_attribution,
       age_range, prayer_frequency, resonant_name_id,
       dua_topics, common_emotions, aspirations,
       daily_commitment_minutes, reminder_time, commitment_accepted
from public.user_profiles where id = auth.uid();

select notif_daily_checkin, notif_streak, notif_weekly, notif_reengage, timezone
from public.user_notification_preferences where user_id = auth.uid();
```
All survey answers must be persisted.

**Analytics:** one `onboarding_page_viewed` event per page (no duplicates on back-then-forward).

**Edge cases:**
- Force close mid-flow, relaunch → same page, selections preserved (via SharedPreferences).
- Back from Encouragement (page 23) → returns to Password (page 22).
- Social auth on Save Progress (page 20) → completes signup + lands in-flow (encouragement/paywall), NOT direct to home unless already onboarded.
- Notification permission denied at OS level → app still advances, `user_notification_preferences` reflects the state.

---

## 4. Paywall (RevenueCat)

**Preconditions:** at onboarding page 19 OR via Settings → Upgrade.

**Steps + UI checks:**
- Offerings load: annual + weekly plan pills visible with correct prices from RevenueCat dashboard.
- Selecting plan updates highlighted state + analytics.
- "Restore" button visible.
- Legal links open Privacy + Terms in external browser.

**DB + MCP checks:**
- RevenueCat MCP: `get-customer <supabase-user-id>` → `original_app_user_id` matches Supabase id.
- After successful sandbox purchase: `list-subscriptions` shows active entitlement; `select public.has_active_premium_entitlement('<uid>');` returns `true` (via webhook-populated `public.user_subscriptions` row).
- Analytics: `paywall_viewed`, `paywall_plan_selected`, `paywall_purchase_succeeded` / `paywall_purchase_cancelled` fire.

**Edge cases:**
- Offerings empty (simulate by archiving offerings in RC dashboard) → error UI, NOT blank screen, Continue-as-free path reachable.
- Purchase cancelled → stays on paywall, no entitlement granted.
- Restore with no prior purchase → "No purchases to restore" snackbar.
- Restore with prior purchase on fresh install → entitlement restored, routed to Home.
- Background during purchase, resume → UI recovers (no frozen spinner).

---

## 5. Daily core loop

**Preconditions:** `daily-user@test.sakina`, no check-in today.

**Steps:**

The shipping muhasabah path is **discover-only**. The multi-question check-in
that previously lived inside the launch overlay was removed 2026-04-26 (see
`docs/qa/findings/2026-04-26-launch-overlay-dead-checkinstep.md`).

**Live flow:**
1. App launch on a fresh day → `DailyLaunchOverlay` step 0 (streak greeting). Tap Begin.
2. Step 1 (reward claim). Tap Claim Reward → claim animates inline. Tap Continue → overlay dismisses to Home.
3. Home → tap "Begin Muḥāsabah" → routes to `/muhasabah`.
4. `MuhasabahScreen.initState` calls `discoverName()` (`daily_loop_provider.dart:402`) which picks an undiscovered/lowest-tier card and jumps straight to gacha.
5. `user_checkin_history` row written with `q1='discover'` sentinel and q2/q3/q4 empty — **intentional**, not a bug.
6. Gacha Continue → reflection → story → dua → Ameen → completion.
7. `_markStreakAndHandleMilestones` runs (logs `user_activity_log`, calls `markActiveToday`, fires milestone overlay if at threshold). `claimDailyReward` runs idempotently.

**`answerCheckin` is preserved in the provider but has no live UI surface.** The function holds a known re-entry race that is fixed defensively with `if (state.checkinLoading) return;` (2026-04-26) but is currently unreachable. See finding F1 in the 2026-04-26 run log.

**UI checks:**
- Streak flame shows correct count on Home before/after.
- Tokens + XP bar update visibly.
- Quest progress updates for "Daily check-in" quest.

**DB checks (Supabase MCP):**
```sql
select id, checked_in_at, q1, q2, q3, q4, name_returned, name_arabic
from public.user_checkin_history where user_id = auth.uid() order by checked_in_at desc limit 1;

select current_streak, longest_streak, last_active from public.user_streaks where user_id = auth.uid();
select balance, total_spent, tier_up_scrolls from public.user_tokens where user_id = auth.uid();
select total_xp from public.user_xp where user_id = auth.uid();
select id, name_id, tier, discovered_at, last_engaged_at from public.user_card_collection where user_id = auth.uid() order by last_engaged_at desc limit 5;
select quest_id, cadence, progress, completed, period_start from public.user_quest_progress where user_id = auth.uid();
select count(*) from public.user_activity_log where user_id = auth.uid() and active_date = current_date;
```

All should reflect the single check-in (no duplicates).

**Edge cases (major, realistic):**
- ~~Double-tap final answer~~ — **OBSOLETE** (multi-question UI removed). Latent race in `answerCheckin` is guarded by an early-return on `checkinLoading`. Reintroduce as a regression case if a multi-question UI returns.
- Double-tap gacha Continue (known bug) → still only one reward claim. Verify `daily_rewards_claimed_at` date not double-written.
- ~~Background app during AI loading~~ — **OBSOLETE** (no AI call in `discoverName`). Re-instate against the muhasabah card-pick path only if a meaningful loading window is reintroduced.
- Complete loop at 11:58pm, open next day → new check-in allowed, streak incremented by 1 (not reset). Verified 2026-04-26 via DB-driven date-rewind. **Schema note**: `user_daily_rewards.last_claim_date` is `date`, not text — write `current_date - 1`, not `(current_date - 1)::text`.
- Complete loop today, close, reopen same day → launch overlay does NOT re-prompt, Home shows "Come back tomorrow".
- Streak freeze auto-consumed if user missed yesterday but freezes available → streak preserved, freeze decremented. Verified 2026-04-26 (B6): seed `streak_freeze_owned=true`, `last_claim_date=current_date-2`, `last_active=current_date-2` → after muhasabah, `current_streak=pre+1`, `streak_freeze_owned=false`. Note: the consume happens in `streak_service.dart markActiveToday`, NOT in the daily reward claim.

---

## 6. Home + Reflect (feelings → result)

**Preconditions:** onboarded user.

**Steps:**
- Home shows streak, tokens, XP, level/title pill (top card on Home/Progress route), and "Begin Muḥāsabah" CTA. Free-text reflect input lives on the **Reflect tab** (bottom nav, slot 3), not on Home.
- Reflect tab → enter feeling text or tap emotion chip → tap Reflect button.
- Two AI-generated follow-up prompts appear (one slider, one multi-choice) before the final reflect call. Continue to advance.
- Final loading → result card (Name + Arabic + transliteration + English meaning + 2 related Names + reflection paragraph).
- **Reflection auto-saves the moment AI completes** — there is no Save button in the live reflect flow. Saved entries appear in **Journal tab** (bottom nav slot 5).
- Share happens from Journal detail screen header (top-right share icon), not on the live reflect.

**DB:**
```sql
-- Schema: id, user_id, user_text, name, name_arabic, reframe / reframe_preview / story,
-- verses (jsonb), dua_arabic / dua_transliteration / dua_translation / dua_source, related_names (jsonb).
select id, saved_at, user_text, name, name_arabic
from public.user_reflections where user_id = auth.uid() order by saved_at desc limit 3;

-- Free-reflect counter (resets midnight). dailyFreeReflects=3.
select reflect_uses from public.user_daily_usage
where user_id = auth.uid() and usage_date = current_date;
```

**Edge cases:**
- Off-topic input ("pizza recipe") → off-topic response ("This space is for your heart…"), does NOT decrement free usage counter. Check `public.user_daily_usage` (composite key `user_id, usage_date`, columns `reflect_uses`, `built_dua_uses`).
- Very long input (500+ chars) → still processes, no truncation visible.
- AI failure (toggle airplane mid-request) → error snackbar, no row created, usage not decremented.
- Free-limit hit (`reflect_uses >= 3` for today) → "Daily limit reached / You've used your 3 free Reflect sessions today. Spend 50 tokens to continue." overlay with "Spend 50 tokens to continue" + "Not now". Counter does NOT increment on a blocked attempt.
- Duplicate tap while loading → only one request.
- Arabic text never bleeds into English (known gotcha from CLAUDE.md).

---

## 7. Duas (browse + builder)

**Preconditions:** onboarded user, some public duas seeded in `duas` table.

**Steps:**
- Duas tab → list loads, categories filter works.
- Tap dua → detail page with Arabic, transliteration, translation.
- Favorite a dua → heart fills. Un-favorite → empties.
- "Build a Dua" → input topic → AI-generated dua, shows source Name + verses referenced.
- Save → appears in Journal under Duas.

**DB:**
```sql
-- Built (AI-generated) duas land here:
select id, saved_at, need, arabic, transliteration, translation from public.user_built_duas where user_id = auth.uid();
-- "Favorite" / saved browse + related duas are SharedPreferences-only on device
-- (keys: saved_built_duas, saved_related_duas, saved_browse_dua_ids — scoped per user).
-- No server-side favorite_duas table exists today.
```

**Edge cases:**
- Build-a-dua with off-topic input → off-topic response, no usage decrement. Verify `select built_dua_uses from public.user_daily_usage where user_id=auth.uid() and usage_date=current_date;` is unchanged.
- **Off-topic + Try Again → input field is cleared** (regression for `2026-04-26-build-dua-tryagain-no-clear`). Same applies to "Build Another Dua" on the result screen.
- Build-a-dua AI failure → prior state intact, no ghost row.
- Favorite a dua, sign out, sign in → still favorited.
- Token gate after free builds exhausted.
- **Duplicate tap on Build (D-E5)** — re-entry guard at `duas_provider.dart:425` (free path) and `:441` (token-spend path) using a synchronous instance flag `_submitInFlight` (set BEFORE any `await`, cleared in `finally`). The earlier `state.buildLoading` guard alone was insufficient: `buildLoading` is only set inside `_doBuild` AFTER the async `canBuildDuaFree()` check, so two taps fired in the same microtask both passed it and both incremented the counter (sim-caught 2026-04-26 with `built_dua_uses=2`). The synchronous flag closes that race. Two rapid taps must produce exactly **one** AI call, **one** counter increment (free) or **one** 50-token spend (paid). Live PASS 2026-04-26: free-path counter +1 only on rebuilt app (post `_submitInFlight` upgrade), token-spend balance 235→185 in earlier run. Unit tests in `test/features/duas/submit_build_reentry_guard_test.dart` (3/3, including the synchronous-microtask pre-loading race that the original guard missed). Run logs: `docs/qa/runs/2026-04-26-build-dua-de5-live.md` (initial), follow-up sim verification of the upgraded fix in this session.
- **AI failure mid-build (D-E2)** — server delete or `_dependencies.buildDua` throws → `_doBuild` catch arm clears `buildLoading`, `buildResult`, `buildProgress`; sets error to `'Something went wrong. Please try again.'`. **No** `incrementBuiltDuaUsage()` call (consume only fires on `result.breakdown.isNotEmpty` after success). Covered by unit test in `test/features/duas/duas_provider_test.dart:203-220`. Live sim verification not run this session — `xcrun simctl` has no reliable airplane-mode toggle (status_bar spoof only) and the unit test is deterministic against this exact path.

---

## 8. Discovery quiz

**Preconditions:** user with no anchors set (`discovery_results` empty).

**Steps:**
- Launch overlay or Settings CTA → `/discovery-quiz`.
- Answer each question → final results show 3 anchor Names.
- Settings now shows "Your Anchors: Al-Rahman, Al-Wadud, Al-Hafeez".
- Re-entering quiz → shows prior results with option to retake.

**DB:**
```sql
select anchor_names, completed_at from discovery_results where user_id = auth.uid();
```

**Edge cases:**
- **Quit mid-quiz (DQ-E1)** → restarts cleanly. `selectedAnswers` lives in `DiscoveryQuizNotifier` memory only (StateNotifier), not persisted to SharedPreferences. Cold-launch reads `loadSavedDiscoveryQuizResults` from server; if no row exists, the quiz is in `initialized: true, completed: false, quizStarted: false` and `ensureQuizReady()` calls `startQuiz()` which resets to question 0. Live PASS 2026-04-26: answered Q1+Q2 → `xcrun simctl terminate booted com.sakina.app.sakina` → relaunch → Home (no resume), `select count(*) from public.user_discovery_results where user_id=auth.uid()` returns 0.
- **Retake (DQ-Retake)** → overwrites prior anchors, doesn't duplicate rows. `completeQuiz()` (`discovery_quiz_provider.dart:120-132`) calls `saveDiscoveryQuizResults(results)` → `supabaseSyncService.upsertRow('user_discovery_results', userId, {'anchor_names': encodedResults}, onConflict: 'user_id')`. The unique constraint on `user_id` + `onConflict: 'user_id'` guarantees count cannot exceed 1 by DB invariant. **Live overwrite PASS 2026-04-26** (`docs/qa/runs/2026-04-26-discovery-retake-quit.md`): pre-clear → completed full quiz with new answers → `count(*)=1` unchanged, `anchor_names` fully overwritten (As-Sabur/Al-Mujib/Al-Latif → Al-Wakil/Ar-Rabb/Al-Qayyum). **UX gap (not a code regression)**: there is no user-visible Retake CTA after completion. Home `Discover Your Anchor Names` row disappears once anchors exist; Settings shows static anchor chips with no retake action. To retake today, a user has to clear the row server-side (this run did so to surface the existing-empty-state CTA). File a product question: should retake live in Settings as a "Retake quiz" button under Your Anchor Names?
- Anchors feed into Reflect context (verify in AI prompt via server logs if accessible).

---

## 9. Journal

**Preconditions:** `daily-user@test.sakina` with 3 reflections + 1 saved dua.

**Steps:**
- Journal tab → shows mixed list (reflections + duas) newest first.
- Tap reflection → detail page renders story, Name, verses, dua.
- Tap dua → detail page renders.
- **Delete confirmation flow** (regression for `2026-04-26-journal-delete-no-confirm`). Test all 3 delete sites:
  1. Reflection detail page → header trash icon
  2. Dua detail page → header trash icon
  3. Inline "Remove" pill on Journal list cards (covers reflection + built-dua + saved-related-dua variants)
  For each: tap delete → "Delete this {reflection|dua|entry}?" dialog appears with **Cancel + Delete** buttons.
  - Tap **Cancel** → dialog closes, row preserved (verify count unchanged in `user_reflections` / `user_built_duas`).
  - Tap delete again → tap **Delete** → row removed, only that item gone (verify by id).
- Empty state: `fresh@test.sakina` → "No reflections yet" CTA.

**DB:**
```sql
-- All rows in user_reflections are saved (auto-save on AI complete; no `saved` flag column).
select count(*) from public.user_reflections where user_id = auth.uid();
-- Built duas (from "Build a Dua" flow) live separately:
select count(*) from public.user_built_duas where user_id = auth.uid();
```
Count matches UI list length.

**Edge cases:**
- Delete a reflection also referenced by Collection → card progress intact.
- Long user input truncates in list card but shows full on detail.
- **Share from detail (J-E2)** works — see §13. Last live PASS in `docs/qa/findings/2026-04-26-share-export-pass.md` (T1 reflection share preview, T2 personal dua share, T6.5 reflect result share, T7 native share-sheet cancel-no-crash). The share/export code path (`lib/widgets/share_card.dart`, `lib/features/journal/screens/reflection_detail_page.dart`) was not touched by D-E5/J-E4 fixes; re-verification on each subsequent commit only required if `share_card.dart` or detail page changes.
- **Network failure mid-delete (J-E4)** — `ReflectNotifier.deleteReflection` (`reflect_provider.dart:411-431`) snapshots `previous = state.savedReflections` synchronously, optimistically mutates local + persists, then awaits `supabaseSyncService.deleteRow('user_reflections', 'id', id)` inside a `try/catch`. On exception (airplane / RLS reject / 5xx), restores `state.savedReflections = previous`, re-persists, and sets `state.error = "Couldn't delete the reflection. Please try again."` for the UI snackbar. **Reliable sim-level toggle of mid-request airplane mode is not available** (`xcrun simctl status_bar` only spoofs the icon; Network Link Conditioner is manual-only). Verified by 2 unit tests in `test/features/reflect/delete_reflection_network_failure_test.dart` (throwing fake → revert + error; happy path → row removed, no error). `@visibleForTesting void debugSeedReflections(...)` added to skip the load path. **Known limitation:** the catch arm uses `catch (_)` and does not log the underlying error type; future debuggability could be improved with a `debugPrint` of `e`.

---

## 10. Collection + Card economy

**Preconditions:** `daily-user@test.sakina` with 10 cards. Last sim verification: `docs/qa/runs/2026-04-26-collection-§10.md` against `shareqa@sakinaqa.test`.

**Schema reality (verified 2026-04-26):**
- `user_card_collection` columns: `id, user_id, name_id, tier, discovered_at, last_engaged_at`. There is **no `copies` column** — tier upgrades replace the row's `tier` value via `upsertRow` keyed on `(user_id, name_id)`. The same row's tier moves bronze → silver → gold; emerald is gacha-only.
- `tier_up_scrolls` is an integer column on `public.user_tokens` (not its own table).
- Costs: `scrollCostBronzeToSilver = 5`, `scrollCostSilverToGold = 10` (`lib/services/tier_up_scroll_service.dart:10-11`).

**Steps:**
- Collection tab → grid of 99 slots, obtained cards show tier visuals (bronze/silver/gold/emerald), locked ones show silhouette.
- Tap obtained card → `_CardDetailSheet` shows tier badge, description, lesson, and (when applicable) `Upgrade (N Scrolls)` CTA.
- Upgrade gate: `showUpgrade = isMaxTier && tier.number < 3` (`collection_screen.dart:986`) — CTA only appears on bronze (1) and silver (2). Gold (3) and emerald (4) intentionally have no upgrade button.
- Tap Upgrade → confirm sheet → `spendTierUpScrolls(cost)` → on success `engageById(card.id)` → `NameRevealOverlay` plays.
- Tier-up preview routes (`/silver-preview` etc, registered in `lib/core/router.dart:101-120`) render correctly. Marked DEBUG/temporary in router.

**DB:**
```sql
select id, name_id, tier::text as tier, discovered_at, last_engaged_at
from public.user_card_collection where user_id = auth.uid();
-- scrolls live on user_tokens (not a separate table):
select balance, tier_up_scrolls from public.user_tokens where user_id = auth.uid();
```
After tier-up: the row's `tier` advances by exactly one step, `tier_up_scrolls` decrements by `scrollCost`, no new rows inserted.

**Edge cases:**
- **C1 tier-up scroll spend (live PASS 2026-04-26)** — bronze → silver flow on `shareqa@sakinaqa.test`: pre `tier=bronze, tier_up_scrolls=21`; tap Upgrade (5 Scrolls) → confirm → post `tier=silver, tier_up_scrolls=16` (delta=5, exact). Single row mutated in place. Run log: `docs/qa/runs/2026-04-26-collection-§10.md`.
- **C2 double-tap idempotency** — `spendTierUpScrolls` (`tier_up_scroll_service.dart:148`) holds a module-level `Completer<void>?` lock (`_spendTierUpScrollsLock` at `:13`). Second tap waits on first's Completer (line 149-151), reads post-first balance, and returns `insufficientBalance` once the cache is depleted. Verified by 5 unit tests in `test/services/tier_up_scroll_service_test.dart` §10 group: exact-balance success, spend(0) no-op, two-call serialize, three-call exactly-two-succeed, and lock-cleanup-on-early-return. Sim-level double-tap is not run (timing too flaky to be authoritative; the lock is a synchronous in-process guard, not a UI-debounce concern).
- **C3 exact-balance edge** — spend balance==cost → `success=true, newBalance=0`. Spend(0) on balance=0 → success no-op (caller must guard 0-cost upgrades). Covered by §10 unit tests.
- **C4 lock cleanup on insufficient early-return** — `try/finally` at `tier_up_scroll_service.dart:156-192` releases the lock even when the early-return at :159 fires. Without this, a single failed spend would deadlock all future spends in-process. Pinned by `'C4 insufficient-balance early-return clears the lock'` test.
- **C5 DB-seeded emerald renders (live PASS 2026-04-26)** — emerald `Ar-Rasheed` (name_id=99) already seeded in user's collection → Collection grid → scroll to bottom → `EmeraldOrnateTile` (`emerald_ornate_card.dart:266`) renders with green radial gradient + Islamic interlace pattern at low opacity. Tap → `EmeraldOrnateDetailSheet` (`:516`) renders Arabic calligraphy, EMERALD badge, transliteration, meaning, description, lesson, prophetic teaching, and Share CTA. No RTL bleed, no overflow, no upgrade button (gate correctly hides for tier.number=4). Widget-level smoke also covered by `EmeraldOrnateTile` and `EmeraldOrnateDetailSheet` pump tests in `test/features/collection/collection_screen_test.dart` §10 C5b group.
- **Preview-route registration** — Bronze/Silver/Gold/EmeraldCardPreviewScreen are const-constructible and registered (`router.dart:101-120`). Visual fidelity is sim-only because previews use `flutter_animate` `.repeat()` continuous loops that `pumpAndSettle` cannot drain. Const-constructibility pinned in §10 C4 group.
- First-time unlock from gacha shows celebration overlay. Already-owned card shows "+1 copy" only.
- Premium celebration overlay ONLY after verified premium entitlement (not just selecting a plan).
- **Observation (UX gap, not regression):** the filter-chip rail does not include an `Emerald` chip even when the user owns an emerald card. Filed for product review.

---

## 11. Store

**Preconditions:** any onboarded user.

**Steps:**
- Store tab → Free + Premium sub-tabs.
- Free tab: items purchasable with tokens. Purchase disabled if balance < price.
- Premium tab: items require entitlement OR tokens (confirm per-item gating).
- Purchase → tokens deducted, inventory updated, success toast.

**DB:**
```sql
-- Actual table is public.user_tokens (not tokens). No public.user_inventory table exists today.
select balance, tier_up_scrolls from public.user_tokens where user_id = auth.uid();
-- Card-equivalent inventory lives in public.user_card_collection. If a true Store inventory ships,
-- update this section with the real table name.
```

**Edge cases:**
- Insufficient tokens → button disabled with "Not enough tokens" hint.
- Double-tap purchase → only ONE deduction.
- Offerings unavailable → buttons fail safely, no crash.

---

## 12. Quests, XP, Titles, Streaks

**Preconditions:** `onboarded@test.sakina` (fresh, no quests completed).

**Steps:**
- Quests tab → First Steps section shows beginner quests.
- Complete qualifying action (e.g., first check-in, first reflection, first dua save) → quest progress increments, reward claimable.
- Claim → tokens/XP granted, quest marked complete.
- XP crossing level threshold → level-up celebration + title auto-updates (if auto mode).
- Settings → Title picker → manual override persists.

**DB:**
```sql
select quest_id, cadence, progress, completed, period_start from public.user_quest_progress where user_id = auth.uid();
select total_xp from public.user_xp where user_id = auth.uid();
-- Title selection lives on user_profiles:
select selected_title, is_auto_title from public.user_profiles where id = auth.uid();
select current_streak, longest_streak, last_active from public.user_streaks where user_id = auth.uid();
-- Streak freeze is a BOOLEAN flag on user_daily_rewards (not an integer count):
select current_day, last_claim_date, streak_freeze_owned from public.user_daily_rewards where user_id = auth.uid();
```

**Edge cases:**
- Multiple quests complete from same action (e.g., first check-in completes streak quest + daily quest) → both grant once.
- Sign out + back in → quest progress + claimed state preserved.
- Broken streak → `current_streak` resets to 1 on next check-in, `longest_streak` preserved.
- Manual title, then achievement unlocks new auto title → manual selection stays active.

---

## 13. Share + Export

**Preconditions:** any saved reflection, built dua, or card.

**Steps:**
- From reflection detail → Share → preview opens → Export → native share sheet with PNG.
- From built dua → Share → preview + export.
- From card detail (ornate view) → Share → export.

**UI checks:**
- Shared card shows Name, verse(s), dua, Sakina branding — rendered via widget-to-image (not screenshot).
- No clipping of Arabic text.
- Arabic + English render with correct direction (no RTL bleed).

**Edge cases:**
- Very long dua → card still fits key content (may truncate secondary text gracefully).
- Native share cancelled → no crash, returns to preview.
- Export failure → user-facing snackbar "Couldn't share that — please try again." (F6 fix landed 2026-04-26 in `lib/widgets/share_card.dart:210-218`; the catch block now calls `ScaffoldMessenger.of(context).showSnackBar(...)` in addition to `debugPrint`, and the `finally` block always cleans up the overlay + `_exporting` state).

---

## 14. Settings + Notifications

**Preconditions:** signed-in user.

**Steps:**
- Settings → profile info (display_name, email, title, level) correct.
- **Account section** → Sign Out (confirm dialog) → returns to `/welcome`, **scoped SharedPrefs keys cleared** (F3 fix landed 2026-04-26 — `AuthService.signOut` now calls `clearScopedPreferencesForUser(prefs, uid)` which strips every key with the `:<uid>` suffix; unit-tested in `test/services/auth_service_signout_clear_prefs_test.dart`, sim-verified 17→0 keys on QABot). Verify: dump `Library/Preferences/com.sakina.app.sakina.plist` post-signout and grep for the uid suffix → 0 results.
- **Preferences** toggles (Push Notifications / Daily Reminder / Streak Reminders / Weekly Reflection / Come Back Nudge / New Content & Updates) → each toggles local + server state.
- **Danger Zone** → "Reset Daily Loop" → confirmation → resets `user_daily_rewards.current_day=0, last_claim_date=null` (preserves `streak_freeze_owned`), clears SharedPrefs `_todayKey` and scoped launch_gate. **Does NOT delete today's `user_checkin_history` row, does NOT touch `user_streaks`** (verified 2026-04-26).
- **Danger Zone** → "Clear Card Collection" → confirmation → deletes all `public.user_card_collection` rows (server-side `deleteRow`) + writes empty collection JSON to scoped SharedPrefs + cascades resetToday/resetLaunchGate. Tokens and tier_up_scrolls preserved (verified 2026-04-26).
- **Danger Zone** → "Delete Account" — 2-step UI captured 2026-04-26 in `docs/qa/ui-map.md` and `lib/features/settings/widgets/delete_account_dialogs.dart`:
  - **Step 1 (warning)**: AlertDialog "Delete Account" with body listing what's destroyed; Cancel (212, 527) / Continue (296, 527, red).
  - **Step 2 (type-confirm)**: AlertDialog "Are you sure?" with text field "Type DELETE to confirm account deletion." The "Delete My Account" button stays disabled (`enabled=false` in AX tree) until the trimmed input equals exactly `DELETE`. Cancel (145, 531) / Delete My Account (261, 531).
  - On confirm: `AuthService.deleteAccount()` calls `delete_own_account` RPC → FK CASCADE wipes 18 user-owned tables → app calls `signOut()` → routes to `/welcome`. End-to-end verified on QABot 2026-04-26: 30 rows / 18 tables → 0 rows. Widget tests in `test/features/settings/delete_account_dialogs_test.dart` cover both Cancel paths, the disabled-button gate, exact-match validation, and trim behavior.
  - **Footgun**: the Delete My Account button center (261, 531) sits very close to the underlying Reset Daily Loop row at (201, 550) when scrolled to Danger Zone. If the dialog dismisses pre-tap or the button is still disabled, a tap there can fall through to Reset Daily Loop. Verify the button is enabled before tapping.

**DB checks after notification toggle:**
```sql
-- Actual table is public.user_notification_preferences (not notification_preferences).
-- Column names use notify_* prefix (not notif_*) and include push_enabled master + notify_updates.
select push_enabled, notify_daily, notify_streak, notify_weekly,
       notify_reengagement, notify_updates, timezone, updated_at
from public.user_notification_preferences where user_id = auth.uid();
```

UI ↔ column mapping (verified 2026-04-26):
- Push Notifications (master) → `push_enabled`. App refuses to set `true` when iOS perm is denied (three-store gate). Sub-toggles visually grey out when master is off but their stored value is preserved.
- Daily Reminder → `notify_daily`
- Streak Reminders → `notify_streak`
- Weekly Reflection → `notify_weekly`
- Come Back Nudge → `notify_reengagement`
- New Content & Updates → `notify_updates`

**F2 push_enabled reconcile (added 2026-04-26)**: when `getNotificationPreferences` runs and the server has `push_enabled=true` AND `OneSignal.Notifications.permission` is currently `false`, the client writes `push_enabled=false` back to Supabase. Backend cron then stops dispatching ghost pushes for revoked-perm users.

**Manual repro:** with iOS notif perm granted on device, sign in → DB shows `push_enabled=true`. Sim Settings → Sakina → Notifications → toggle Allow OFF → cold-launch app → open in-app Settings (triggers `getNotificationPreferences`) → verify `select push_enabled from public.user_notification_preferences where user_id=auth.uid();` flips to `false`. Unit tests in `test/services/notification_service_test.dart` cover both branches.

**Option B push_enabled_last_verified_at (added 2026-04-26)**: new column on `public.user_notification_preferences`. The client stamps it `now()` on `optIn()` success and on `getNotificationPreferences` when server says enabled AND iOS perm is granted. The cron RPC `get_eligible_notification_users` requires `push_enabled_last_verified_at IS NOT NULL AND > now() - interval '7 days'`. A user who hasn't foregrounded the app with perm granted in 7 days stops receiving pushes even if `push_enabled=true` lies. Migration `add_push_enabled_last_verified_at_with_cron_filter` applied + backfilled 29 rows.

**Manual repro:** as authenticated user, `update public.user_notification_preferences set push_enabled_last_verified_at = now() - interval '8 days' where user_id = auth.uid();` → run cron RPC for that target_hour → user is excluded. Restore by foregrounding the app with iOS perm granted (auto-restamps).

**DB checks after delete account:**
```sql
select count(*) from user_profiles where id = '<old-uid>';  -- expect 0
select count(*) from public.user_checkin_history where user_id = '<old-uid>';  -- expect 0
select count(*) from public.user_reflections where user_id = '<old-uid>';  -- expect 0
```

**OneSignal MCP:**
- `view_user <onesignal-external-id>` before delete → exists.
- After delete → user removed OR subscription disabled.

**Edge cases:**
- Toggle notification while offline → UI updates optimistically, retries on reconnect.
- Tap notification from lock screen → app opens to correct deep link (daily check-in, streak, etc.).
- Foreground notification → banner, no crash on current screen.
- Timezone changes (e.g., travel) → next sync updates `timezone` column; scheduled notifications use new TZ.

---

## 15. Push notifications (OneSignal)

**Preconditions:** user opted in, OneSignal external id = Supabase user id.

**MCP test sends:**
```
mcp__onesignal__send_push_notification
  target: external_user_id = <user-id>
  title: "Time for your daily check-in"
  deep_link: sakina://daily
```

**Checks:**
- Notification arrives on device within ~10s. Confirm by user tapping it; the app routes per the type→route map in `notification_service.dart` (verified end-to-end 2026-04-26 on QABot for `daily_reminder`, `streak_milestone`, `weekly_reflection`, `reengagement`).
- `view_message_history` is **paid-tier only** ("Your account must be a paid account and have the audience events feature available and enabled"). Don't rely on it on the free tier — confirm delivery via the device tester instead.
- `view_user` has alias-propagation lag and may 404 for ~30–60s after sign-in even when the subscription is registered and pushes deliver. If `send_push_notification` succeeds and the device receives the banner, registration is fine regardless of `view_user` returning 404. Verified live 2026-04-26.

**Edge cases:**
- User revoked OS permission → send succeeds server-side but no delivery. The next time `getNotificationPreferences` runs (e.g. opening Settings), the F2 reconcile flips `public.user_notification_preferences.push_enabled` to `false`, which then makes the cron's `get_eligible_notification_users` RPC skip this user (the cron filters on `push_enabled = true`, not on per-category columns alone).
- User signed out → no push sent (subscription disabled). `OneSignal.logout()` runs from `app_session.dart`.
- Scheduled daily notification does NOT fire twice in same 24h window. The cron RPC dedup clause uses `(last_daily_sent_at AT TIME ZONE tz)::date < (now() AT TIME ZONE tz)::date - 0` — i.e. previous send must be on an earlier local-tz date. Verified 2026-04-26 via `pg_temp.qa_dedup_check`: sent_today=ineligible, sent_yesterday=eligible, never_sent=eligible.
- **Option B 7-day freshness**: `push_enabled_last_verified_at` older than 7 days makes the cron RPC skip the user even if every other gate is satisfied. Catches drift where `push_enabled=true` but the device hasn't reverified in a week.

---

## 16. Backend (Supabase RPCs, webhooks)

Automated regression: `flutter/supabase/tests/backend_rls_test.sql` (47 assertions, runnable via `mcp__supabase__execute_sql`) and the Deno suite in `flutter/supabase/functions/revenuecat-webhook/index.test.ts` (14 tests, run with `deno test --no-check`). The on-device runbook below is the manual confirmation pass; expect both to pass before exercising it.

Run via Supabase MCP with service role; impersonate users via `set local role authenticated; set_config('request.jwt.claims', '{"sub":"<uid>","role":"authenticated"}', true);` inside a transaction (verified pattern).

**`sync_all_user_data()`** (auth-gated; raises `Not authenticated` otherwise):
```sql
select sync_all_user_data();
```
Payload has **exactly 11 keys**: `xp`, `tokens`, `streak`, `daily_rewards`, `profile`, `built_duas`, `reflections`, `achievements`, `card_collection`, `checkin_history`, `discovery_results`. (No `quests`, no `journal`, no `favorites`. `profile` exposes only `selected_title`, `is_auto_title`, `created_at` — no `id`, no `onboarding_completed`.) `discovery_results` may be `null` for users without quiz history; all others are non-null.

**`delete_own_account()`:** see §14. Implementation is one-line `DELETE FROM auth.users WHERE id = auth.uid()`; cleanup is FK CASCADE-only — every scoped table with a `user_id` FK to `auth.users` must drop the row, otherwise it's a P0 schema bug.

**`grant_premium_monthly()`:**
- Call as premium user → `granted=true`, `tokens_granted=50`, `scrolls_granted=15`, `user_daily_rewards.last_premium_grant_month` set to current `YYYY-MM`.
- Call again same month → `granted=false`, `tokens_granted=0`, balance unchanged (idempotency keyed on `last_premium_grant_month`).
- Call as non-premium → `granted=false`, `reason='not_premium'`.
- Unauthenticated → raises `Not authenticated`.

**RevenueCat webhook (`revenuecat-webhook` edge function):**
- Auth header is `Authorization: Bearer $REVENUECAT_WEBHOOK_SECRET`. Persistence target is `public.user_subscriptions` (not `subscriptions`). Persistence goes through `upsert_user_subscription_if_newer`, which **rejects events with `event_timestamp_ms` ≤ stored `last_event_at`** — sequence forged events with strictly increasing timestamps.
- The function silently returns 200 `{status:"skipped"}` when: event `type` not in {INITIAL_PURCHASE, RENEWAL, PRODUCT_CHANGE, UNCANCELLATION, CANCELLATION, BILLING_ISSUE, EXPIRATION}; `entitlement_ids` doesn't include `premium`; `app_user_id` (or `original_app_user_id` / first non-anonymous alias) isn't a UUID.
- Trigger via real sandbox purchase (physical device only) **or** forged `curl` against the function URL (MCP-friendly).
  - INITIAL_PURCHASE → 200 `{status:"ok"}`, `user_subscriptions` row inserted, `has_active_premium_entitlement('<uid>')` → `true`.
  - CANCELLATION (with future `expiration_at_ms`) → 200, `canceled_at` set, `expires_at` unchanged, entitlement still active until period end.
  - EXPIRATION (with past `expiration_at_ms`) → 200, `has_active_premium_entitlement` → `false`. After CANCELLATION → EXPIRATION the `canceled_at` timestamp is **preserved** (per migration `20260426000000_preserve_canceled_at_on_absent_key.sql` — the upsert is key-presence-aware: absent JSON keys preserve stored values, explicit nulls still clear). Regression test in `supabase/tests/backend_rls_test.sql`.
- Unauthorized POST → 401. GET → 405.

---

## 17. Public catalog & cross-user isolation

Automated regression: same `flutter/supabase/tests/backend_rls_test.sql` covers anon catalog read (5 catalog tables) and cross-user RLS for 18 scoped tables, plus the RLS-on + has-policy audit. Run via `mcp__supabase__execute_sql`.

**Preconditions:** two signed-in accounts on two devices OR two simulators (or two impersonated UIDs via SQL).

**Steps:**
- Public content (99 Names, duas, quiz questions) loads anonymously — sign out, content still browsable. Public catalog tables: `daily_questions`, `browse_duas`, `discovery_quiz_questions`, `name_anchors`, `collectible_names` (per `lib/services/public_catalog_contracts.dart`).
- User A creates reflection. User B on second device — query as User B (or impersonate via `set local role authenticated; set_config('request.jwt.claims', ...)`):
```sql
select * from public.user_reflections where user_id = '<user-A-uid>';  -- expect 0 rows (RLS block)
```

**Edge cases:**
- Catalog refresh mid-session → existing screens don't crash, new data appears on next navigation.
- Airplane mode → bundled snapshot catalog used as fallback (names/duas still browsable).

---

## 18. App lifecycle + offline

- Background app mid-flow on every major screen → resume → UI state preserved, no duplicate network calls.
- Airplane mode on Home → streak/tokens read from cache, attempted actions show "No connection" snackbar.
- Toggle airplane mode off during a failed reflect → retry succeeds.
- Low memory termination while in onboarding → relaunch resumes at correct page.

---

## Release-gate manual pass (30 min)

Before every TestFlight/App Store push, run this condensed flow on **one physical iOS device + one Android** (once available):

1. Fresh install → full onboarding → paywall restore → Home.
2. Daily loop: muhasabah → AI → gacha → rewards.
3. Reflect from Home → save → open in Journal.
4. Build a dua → save → open in Journal.
5. Open Collection → upgrade one card.
6. Settings → toggle one notification → sign out → sign back in → toggle still set.
7. Receive a scheduled push (or send via OneSignal MCP) → tap → correct deep link.
8. Settings → delete account → confirm DB rows gone via Supabase MCP.

If all eight pass with no visual or DB anomalies, ship.

## 18. Fresh-checkout build

Regression guard for the `.env`-as-gitignored-but-required-asset bug.

1. `git clone` the repo into a temp directory (e.g. `/tmp/sakina-fresh-$(date +%Y%m%d-%H%M%S)`).
2. `cd flutter && flutter pub get`
3. `flutter build web --debug` must succeed — no "No file or variants
   found for asset: .env" error. (`.env` is no longer a pubspec asset;
   `.env.example` is bundled as the always-loaded fallback.)
4. `flutter build ios --debug --no-codesign` — same expectation.
5. Launching the app should not crash during `dotenv.load`; the app
   boots on placeholder values from `.env.example`. To run against real
   Supabase/RevenueCat, add `- .env` back to `pubspec.yaml` locally and
   provide the secrets in `.env`.

**Last verified 2026-04-26 (web):** clone of HEAD `3fc53d0` → `flutter pub get` → `flutter build web --debug` → `✓ Built build/web` in ~43s. Clone contained `.env.example` only, no `.env`. Pubspec asset list correctly excludes `.env`. The `mixpanel_flutter` wasm-dry-run lint about `invalid_runtime_check_with_js_interop_types` surfaces but does NOT fail the build — it is unrelated upstream noise. Disable with `--no-wasm-dry-run` if it muddies CI signal.

**What can break this regression:** anyone re-adding `- .env` to the asset list under `flutter:` in `pubspec.yaml` and committing it. Local devs SHOULD add it back for real Supabase/RevenueCat values, but must NOT commit the change. The local-only line in HEAD's pubspec is intentionally absent.
