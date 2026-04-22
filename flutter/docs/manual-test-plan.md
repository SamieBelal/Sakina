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
2. `onboarded@test.sakina` — `profiles.onboarding_completed = true`, no check-ins, no cards, no entitlement.
3. `daily-user@test.sakina` — 7-day streak, ~500 tokens, 10 cards across tiers, 3 journal entries, 1 saved dua.
4. `premium@test.sakina` — same as #3 plus active RevenueCat entitlement.
5. `expired@test.sakina` — previously premium, entitlement lapsed.

Reset script (run before each full pass):
```sql
-- Supabase MCP: reset non-premium test users
select delete_own_account() -- call from client as each user, OR:
delete from profiles where email like '%@test.sakina';
```

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
select id, onboarding_completed, created_at from profiles where id = auth.uid();
select count(*) from checkin_history where user_id = auth.uid();
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
- Email sign-up happy path: valid email + 8+ char password + name → account created.
- Google sign-in → returns to in-flow onboarding (NOT paywall) if onboarding incomplete.
- Apple sign-in → same.

**UI checks:**
- Invalid email → inline error "Please enter a valid email".
- Password < 8 chars → inline error.
- Duplicate email → snackbar "An account with this email already exists".
- Social auth cancel → user stays on Save Progress screen, no crash.

**DB checks:**
```sql
select email, full_name, auth_provider, onboarding_completed from profiles where email = '<email>';
-- After social auth resume, onboarding_completed should still be false and user should be mid-flow.
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

## 3. Onboarding (20 pages)

**Preconditions:** fresh signup, `onboarding_completed = false`.

Walk each page 0→19. For every page:

**Per-screen checks:**
- Headline + illustration render.
- Continue disabled until valid selection (where applicable).
- Back button returns to prior page preserving prior answer.
- Progress bar segment matches page index (0–18). Paywall (19) has no progress bar.
- Kill app → relaunch resumes on same page with answers intact.

**Special per-page notes:**
- **Page 0 (First Check-in):** text field auto-focuses, emotion chips tappable, submit triggers `NameRevealOverlay`. Continue only after reveal dismissed.
- **Page 9 (Name):** entered name must appear on page 10 ("Something beautiful awaits you, <name>").
- **Page 11 (Notifications):** tapping "Allow" triggers iOS system prompt exactly once. Tapping "Not now" does NOT trigger it. Skip still advances.
- **Page 19 (Paywall):** see §4.

**DB checks after completing onboarding:**
```sql
select onboarding_completed, intention, quran_connection, familiarity,
       struggles, attribution_sources, full_name, notification_opt_in
from profiles where id = auth.uid();

select segment, count(*) from onboarding_answers where user_id = auth.uid() group by segment;
```
All survey answers must be persisted.

**Analytics:** one `onboarding_page_viewed` event per page (no duplicates on back-then-forward).

**Edge cases:**
- Force close on page 14, relaunch → same page, selections preserved.
- Back from Encouragement (page 10) → returns to Name (page 9) with name still typed.
- Social auth on page 6 → lands on page 10 (Encouragement) or wherever `_next` logic points, NOT paywall.
- Notification permission denied at OS level → app still advances, `notification_opt_in=false` persisted.

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
- After successful sandbox purchase: `list-subscriptions` shows active entitlement; `profiles.is_premium = true` (via webhook).
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
- App launch → `DailyLaunchOverlay` shows check-in CTA.
- Tap → `/muhasabah` screen.
- Answer each muhasabah question.
- Final answer → loading → AI result (Name + verse(s) + dua).
- Result saves automatically to journal.
- `NameRevealOverlay` (gacha) appears with a card.
- Continue → daily rewards claimed (tokens + XP).
- Achievement check fires if thresholds crossed.

**UI checks:**
- Streak flame shows correct count on Home before/after.
- Tokens + XP bar update visibly.
- Quest progress updates for "Daily check-in" quest.

**DB checks (Supabase MCP):**
```sql
select id, created_at, feeling_input, matched_name_id
from checkin_history where user_id = auth.uid() order by created_at desc limit 1;

select current_streak, longest_streak, last_checkin_date from streaks where user_id = auth.uid();
select balance from tokens where user_id = auth.uid();
select current_xp, level from xp where user_id = auth.uid();
select card_id, tier, copies from user_cards where user_id = auth.uid() order by updated_at desc limit 5;
select quest_id, progress, completed_at from user_quests where user_id = auth.uid();
```

All should reflect the single check-in (no duplicates).

**Edge cases (major, realistic):**
- Double-tap final answer → only ONE check-in row created.
- Double-tap gacha Continue (known bug) → still only one reward claim. Verify `daily_rewards_claimed_at` date not double-written.
- Background app during AI loading → returns, completes or shows retry, no duplicate save.
- Complete loop at 11:58pm, open next day → new check-in allowed, streak incremented by 1 (not reset).
- Complete loop today, close, reopen same day → launch overlay does NOT re-prompt, Home shows "Come back tomorrow".
- Streak freeze auto-consumed if user missed yesterday but freezes available → streak preserved, freeze count decremented.

---

## 6. Home + Reflect (feelings → result)

**Preconditions:** onboarded user.

**Steps:**
- Home shows streak, tokens, XP, "How are you feeling?" input, featured quest.
- Type a feeling or tap emotion chip → navigate to reflect.
- Reflect: loading → result card (Name + Arabic + translit + English meaning + 1–2 verses + dua).
- Save button persists to journal. Share button opens preview.
- Follow-up question appears → answer → refined result.

**DB:**
```sql
select id, user_input, matched_name_id, verse_ids, dua_id, saved
from reflections where user_id = auth.uid() order by created_at desc limit 3;
```

**Edge cases:**
- Off-topic input ("pizza recipe") → off-topic response, does NOT decrement free usage counter. Check `daily_usage` table.
- Very long input (500+ chars) → still processes, no truncation visible.
- AI failure (toggle airplane mid-request) → error snackbar, no row created, usage not decremented.
- Free-limit hit → paywall/token gate with upgrade CTA.
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
select dua_id from favorite_duas where user_id = auth.uid();
select id, topic, generated_at from built_duas where user_id = auth.uid();
```

**Edge cases:**
- Build-a-dua with off-topic input → off-topic response, no usage decrement.
- Build-a-dua AI failure → prior state intact, no ghost row.
- Favorite a dua, sign out, sign in → still favorited.
- Token gate after free builds exhausted.

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
- Quit mid-quiz → next entry resumes at last question (or restarts cleanly — confirm intended behavior).
- Retake → overwrites prior anchors, doesn't duplicate rows.
- Anchors feed into Reflect context (verify in AI prompt via server logs if accessible).

---

## 9. Journal

**Preconditions:** `daily-user@test.sakina` with 3 reflections + 1 saved dua.

**Steps:**
- Journal tab → shows mixed list (reflections + duas) newest first.
- Tap reflection → detail page renders story, Name, verses, dua.
- Tap dua → detail page renders.
- Swipe/tap delete → confirmation → removes only that item.
- Empty state: `fresh@test.sakina` → "No reflections yet" CTA.

**DB:**
```sql
select count(*) from reflections where user_id = auth.uid() and saved = true;
select count(*) from favorite_duas where user_id = auth.uid();
```
Count matches UI list length.

**Edge cases:**
- Delete a reflection also referenced by Collection → card progress intact.
- Long user input truncates in list card but shows full on detail.
- Share from detail works (see §13).

---

## 10. Collection + Card economy

**Preconditions:** `daily-user@test.sakina` with 10 cards.

**Steps:**
- Collection tab → grid of 99 slots, obtained cards show tier visuals (bronze/silver/gold/emerald), locked ones show silhouette.
- Tap obtained card → detail page with Name, tier, copies, upgrade option.
- If enough tier-up scrolls → "Upgrade to Silver" button → consume scrolls, tier increments once.
- Tier-up preview routes (`/silver-preview` etc) render correctly.

**DB:**
```sql
select card_id, tier, copies from user_cards where user_id = auth.uid();
select balance from tier_up_scrolls where user_id = auth.uid();
```
After tier-up: tier + copies update, scrolls decremented by correct amount.

**Edge cases:**
- Double-tap upgrade → only ONE tier jump and ONE scroll spend.
- Upgrade with exactly the required scrolls → succeeds, balance becomes 0.
- First-time unlock from gacha shows celebration overlay. Already-owned card shows "+1 copy" only.
- Premium celebration overlay ONLY after verified premium entitlement (not just selecting a plan).

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
select balance from tokens where user_id = auth.uid();
select item_id, acquired_at from user_inventory where user_id = auth.uid();
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
select quest_id, progress, completed_at, reward_claimed_at from user_quests where user_id = auth.uid();
select current_xp, level, active_title_id, auto_title_enabled from xp where user_id = auth.uid();
select current_streak, longest_streak, freezes_available from streaks where user_id = auth.uid();
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
- Export failure (e.g., low disk space simulated) → error snackbar.

---

## 14. Settings + Notifications

**Preconditions:** signed-in user.

**Steps:**
- Settings → profile info (name, email, title, level) correct.
- Notification toggles (Daily check-in / Streak / Weekly / Re-engagement) → each toggles local + server state.
- Sign out → returns to `/welcome`, local caches cleared.
- "Reset Daily Loop" → confirmation → clears today's check-in only.
- "Clear Card Collection" → confirmation → wipes `user_cards`.
- "Delete Account" → confirmation + re-confirmation → calls `delete_own_account` RPC → returns to `/welcome`, all user rows gone.

**DB checks after notification toggle:**
```sql
select notif_daily, notif_streak, notif_weekly, notif_reengage, timezone
from notification_preferences where user_id = auth.uid();
```

**DB checks after delete account:**
```sql
select count(*) from profiles where id = '<old-uid>';  -- expect 0
select count(*) from checkin_history where user_id = '<old-uid>';  -- expect 0
select count(*) from reflections where user_id = '<old-uid>';  -- expect 0
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
- Notification arrives on device within ~10s.
- Tap → app opens to `/muhasabah` or Home with daily overlay.
- `view_message_history` shows delivered.

**Edge cases:**
- User revoked OS permission → send succeeds server-side but no delivery. `notification_opt_in` reflects revoked state on next app launch (verify via MCP `view_user`).
- User signed out → no push sent (subscription disabled).
- Scheduled daily notification does NOT fire twice in same 24h window.

---

## 16. Backend (Supabase RPCs, webhooks)

Run via Supabase MCP with service role:

**`sync_all_user_data()`:**
```sql
select * from sync_all_user_data();  -- as authenticated test user
```
Payload has all sections: profile, streaks, tokens, xp, cards, quests, journal, reflections, favorites, discovery. No nulls where not expected.

**`delete_own_account()`:** see §14.

**`grant_premium_monthly()`:**
- Call as premium user → succeeds, tokens granted.
- Call again same month → rejected / no-op.
- Call as non-premium → rejected.

**RevenueCat webhook:**
- Trigger sandbox purchase → webhook fires → `profiles.is_premium = true`, `subscriptions` row inserted.
- Trigger cancel → webhook → `is_premium` may stay true until period end (verify).
- Trigger expiration → webhook → `is_premium = false`.
- Trigger unauthorized POST to webhook URL → 401/403.

---

## 17. Public catalog & cross-user isolation

**Preconditions:** two signed-in accounts on two devices OR two simulators.

**Steps:**
- Public content (99 Names, duas, quiz questions) loads anonymously — sign out, content still browsable.
- User A creates reflection. User B on second device — query as User B:
```sql
select * from reflections where user_id = '<user-A-uid>';  -- expect 0 rows (RLS block)
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
