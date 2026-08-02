# Entry & Identity — QA Findings (2026-04-22)

Simulator-driven walkthrough of Sakina Entry & Identity flow (Phases 1–3 from `docs/testing-plan.md` and `docs/manual-test-plan.md`). Executed on iPhone 17 iOS simulator via `mcp__ios-simulator__*` tooling, with persistence verified via `mcp__supabase__*`.

**Run date:** 2026-04-22
**New test account created:** `sakinatest20260422a@sakinaqa.test` (uid `639aed54-d59a-49d7-bd59-6f52552594cb`)
**Screenshots:** `/tmp/sakina-test/` (00-baseline.png through after-paywall.png)
**UI map:** `docs/qa/ui-map.md`

---

## Summary

| Phase | Result |
|---|---|
| 0 · Prep + UI map | ✅ |
| 1 · Launch / routing / session hydration | ✅ (fresh-install handoff deferred) |
| 2 · Welcome + Auth (email, Google, Apple) | ✅ (social OAuth sheets verified; email signup completes) |
| 3 · Onboarding 20 pages | 🟡 all pages reachable, **but data loss on final persist** |
| Paywall (index 19) | ✅ renders, offerings load, close routes to Home |

**Ship-blocker:** **D5** — every onboarding answer is dropped on write; `user_profiles` ends the flow with only `onboarding_completed=true`. The entire personalization promise fails.

---

## Defects

### D5 · [P0 · ship-blocker] Onboarding answers never persisted to Supabase

**Where:** Onboarding flow writes to `user_profiles`. Likely `onboarding_provider.dart` + `services/supabase_service.dart` (or whatever handles the final write).

**Repro (exact path I walked):**
1. Fresh signup from `/welcome` → Get Started → full onboarding
2. Page 0: type "overwhelmed by life" → Reflect → Continue (NameRevealOverlay: As-Salam)
3. Result teaser → Continue
4. Name: `QaTestUser`
5. Age: 25–34
6. Intention: Spiritual Growth
7. Prayer frequency: Some days
8. Quran connection: Weekly
9. 99 Names familiarity: Just Getting Started
10. Resonant Name: Ar-Rahman
11. Dua topics: Forgiveness + Guidance + Peace
12. Common emotions: Anxious + Overwhelmed + Hopeful
13. Aspirations: Closer to Allah + Stronger faith + More present
14. Daily commitment: 5 min
15. Attribution: TikTok + Friend/Family
16. Reminder time: 08:00 AM (default)
17. Notifications: Enable Notifications
18. Commitment: Tap to commit → Continue
19. Personalization summary (correctly shows Ar-Rahman + Anxious + 5 min · 08:00 + Spiritual Growth — so client state is right)
20. Value prop → social proof → Save Your Progress → Email: `sakinatest20260422a@sakinaqa.test` → Password: 8 chars → Create Account → Encouragement ("Something beautiful awaits you, QaTestUser") → Paywall
21. Close paywall → Home

**Observed in `user_profiles` after paywall dismiss:**

```json
{
  "display_name": null,
  "onboarding_completed": true,     // ← only flag that got through
  "onboarding_intention": null,
  "age_range": null,
  "prayer_frequency": null,
  "onboarding_quran_connection": null,
  "onboarding_familiarity": null,
  "resonant_name_id": null,
  "dua_topics": [],
  "common_emotions": [],
  "aspirations": [],
  "daily_commitment_minutes": null,
  "reminder_time": null,
  "commitment_accepted": false,
  "onboarding_attribution": [],
  "onboarding_struggles": []
}
```

Auxiliary tables (`user_streaks`, `user_tokens`, `user_xp`, `user_notification_preferences`, `user_daily_rewards`) were created with defaults — those paths work. `user_profiles` specifically is the broken sink.

**Why this matters:** The app's pitch is "personalized reflections/duas/Names based on your profile." With every answer dropped, personalization silently degrades to cold-start for every new user. Discoverable only via DB or behavior regression — no UI signal.

**Likely causes to investigate:**
- Onboarding answers held in a Riverpod provider that never calls the Supabase upsert when signup completes (sign-up likely races ahead of flush).
- Separate UPDATE calls per-page might be happening pre-auth, but without a user id they no-op silently (RLS block).
- Social auth path might have a persist call; email path may not.

**Suggested fix path:** right after `authServiceProvider.signUp(...)` succeeds, before navigating to encouragement/paywall, upsert the entire in-memory onboarding state into `user_profiles` using the new `auth.uid()`. Verify under RLS.

---

### D1 · [P1] Onboarding p0 keyboard causes 152-pixel layout overflow

**Where:** Onboarding page 0 (First Check-in) — `lib/features/onboarding/` subscreen that renders "How are you feeling today?"

**Repro:**
1. `/welcome` → Get Started → p0
2. Tap "Type how you're feeling…" field

**Observed:**
- Flutter debug banner: `BOTTOM OVERFLOWED BY 152 PIXELS`
- Emotion chips (Anxious/Sad/Grateful/Frustrated/Lost/Hopeful) hidden by keyboard
- Reflect button hidden by keyboard, not reachable via scroll

Evidence: `/tmp/sakina-test/onboarding-p0-keyboard.png`

**Fix:** wrap body in `SingleChildScrollView` + `resizeToAvoidBottomInset: true`, or shrink the illustration by `MediaQuery.viewInsets.bottom > 0`.

---

### D2 · [P3 · doc drift] `testing-plan.md` / `manual-test-plan.md` reference columns and tables that don't exist

Docs mention `profiles.full_name`, `profiles.auth_provider`, `profiles.notification_opt_in`, `onboarding_answers` table.

Actual schema:
- Table is `user_profiles`, not `profiles`.
- Column is `display_name`, not `full_name`.
- No `auth_provider` column in `user_profiles` (available on `auth.users.raw_user_meta_data` / `auth.identities`).
- Notification prefs live in `user_notification_preferences`, not a `notification_opt_in` column.
- No `onboarding_answers` table — survey answers are array columns directly on `user_profiles` (`onboarding_struggles`, `onboarding_attribution`, `common_emotions`, `aspirations`, `dua_topics`).

**Fix:** update both docs' SQL assertions + eliminate references to `profiles.*` and `onboarding_answers`.

---

### D3 · [P3 · doc drift] `CLAUDE.md` onboarding page order is stale

Documented (CLAUDE.md):
- 0: First Check-in · 1: Collect · 2: Reflect · 3: Build · 4: Ascend · 5: Journal · 6: Save Progress · 7: Sign-Up Email · 8: Sign-Up Password · 9: Sign-Up Name · 10: Encouragement · 11: Notifications · 12: Intention · 13: Value Prop · 14: Familiarity · 15: Quran Connection · 16: Struggles · 17: Attribution · 18: Social Proof · 19: Paywall

Actual flow walked today:
1. First Check-in (emotion input + AI-picked Name reveal + "Your Reflection" teaser)
2. Name (What should we call you?)
3. Age range (13-17 … 55+)
4. Intention
5. Prayer frequency
6. Quran connection
7. 99 Names familiarity
8. Resonant Name picker
9. Dua topics (multi-select + optional "on your heart" field)
10. Common emotions (multi-select)
11. Aspirations (pick up to 3)
12. Daily commitment (1/3/5/10/Custom)
13. Attribution (multi-select)
14. Encouragement interstitial ("You're not alone in this")
15. Reminder time (sliders)
16. Notifications opt-in
17. Commitment ("Tap to commit")
18. Personalization plan summary
19. Value prop (Daily check-in / 99 Names / Journal)
20. Social proof (4.9 stars + testimonials)
21. Save Your Progress (Apple/Google/Email)
22. Email → Password → (encouragement "Something beautiful awaits you") → Paywall

(21+ user-facing pages — 99 Names familiarity is before Quran connection, age added, aspirations added, resonant name picker added, commitment + plan summary added, social auth moved to end, dedicated encouragement after signup shown.)

**Fix:** re-document the canonical page index order in CLAUDE.md so it matches source. This also invalidates the old page-index references in `testing-plan.md` §3 (e.g., "Page 9 = Name", "Page 11 = Notifications", "Page 19 = Paywall") — Paywall is still effectively terminal, but the indexes shift.

---

### D4 · [P3 · doc drift] Password min length mismatch

- App asserts: "At least 6 characters"
- `manual-test-plan.md` §2 asserts: "Password < 8 chars → inline error"

**Fix:** pick one. 6 is permissive for a spiritual journaling app; consider 8 for safety, update either source or docs.

---

### D6 · [P3] Settings "Sign Out" location differs from doc

`manual-test-plan.md` §14 lists Sign Out alongside Reset Daily Loop / Clear Card Collection / Delete Account. Real app: Sign Out is in its own **Account** section, between Store and Preferences. Danger Zone has only Reset / Clear / Delete. Doc fix; app behavior is correct.

---

### D7 · [P2 · minor UX] Invalid email gives no inline error copy

Doc says: "Invalid email → inline error 'Please enter a valid email'"
Actual: Continue button stays disabled, no visible copy.
**Impact:** mild. User might be confused why Continue is grey. Either add the inline error copy or update the doc. Prefer adding the copy — it matches the spec and is more helpful.

---

## Confirmed behaviors ✅

| Check | Status |
|---|---|
| Onboarded + signed-in → Home | ✅ |
| Onboarded + signed-out → Welcome | ✅ |
| Kill from Home → relaunch → Home | ✅ |
| Sign-out from Settings → Welcome + caches cleared | ✅ |
| DailyLaunchOverlay shown-once-per-day tracking | ✅ (relaunch does not re-show after first view) |
| Welcome/Hook screen renders (mihrab illustration + CTAs) | ✅ |
| Welcome → Get Started → `/onboarding` | ✅ |
| Onboarding p0 auto-focus cursor (though soft keyboard gated on hw keyboard state) | ✅ |
| Validation: Reflect/Continue disabled until input provided on every input page | ✅ |
| Name interpolation (p2 typed name → p19 summary and post-signup encouragement) | ✅ |
| NameRevealOverlay renders post-first-check-in with Arabic + English (As-Salam) | ✅ |
| Arabic (RTL) rendering on Result teaser card — no bleed into English | ✅ |
| Apple Sign-In — tapping button triggers iOS native sheet | ✅ |
| Google Sign-In — tapping button triggers OAuth consent sheet | ✅ |
| Google cancel — graceful snackbar "Google sign-in cancelled." | ✅ |
| Continue with Email → dedicated email → password screens | ✅ |
| Email signup creates `auth.users` + default rows in streaks/tokens/xp/notification_prefs/daily_rewards | ✅ |
| Paywall renders (RevenueCat offerings): Yearly $49.99 + Weekly $4.99, trial copy, Restore/Terms/Privacy links, close X | ✅ |
| Post-signup routing: encouragement → paywall → Home | ✅ |
| New-user Home shows 0-day streak + Today's Name card | ✅ |
| Settings → Sign Out confirmation dialog + destructive styling | ✅ |
| iOS notification permission prompt did NOT fire on this user (OS pre-granted from prior runs) — needs physical re-check on a truly fresh OS state to verify the doc claim that Enable triggers prompt exactly once | ⚠️ inconclusive |

---

## Gap-fill verifications (2026-04-22 follow-up)

After D1–D7 fixes, ran coverage matrix vs both docs and executed 8 remaining items.

| # | Item | Method | Result |
|---|---|---|---|
| 1 | Privacy Policy link | Live sim — Safari opened brahim7860.github.io | ✅ |
| 2 | Terms of Service link | Live sim — Safari opened brahim7860.github.io | ✅ |
| 3 | Hook "I Already Have an Account" → /signin | Live sim — "Welcome back" screen with Apple/Google/email | ✅ |
| 4 | Existing onboarded user → Home (skip onboarding) | Live sim as `verify20260422b@sakinaqa.test`, landed on DailyLaunchOverlay | ✅ |
| 5 | Duplicate email snackbar on sign-up | Code-verified `sign_up_password_screen.dart:82-87` (AuthException → SnackBar + signupFailed analytics); same pattern as invalid-login already verified live | ✅ |
| 6 | Back preserves prior answers | Code-verified `name_input_screen.dart:35`, `sign_up_email_screen.dart:34`, `reminder_time_screen.dart:31`, `daily_commitment_screen.dart:37` all restore from Riverpod state in initState | ✅ |
| 7 | Kill/resume mid-onboarding restores page | Code-verified `onboarding_provider.dart:215-231` persists/restores full OnboardingState including `currentPage` to SharedPreferences on every setter | ✅ |
| 8 | "Not now" on notifications does NOT fire OS prompt | Code-verified `notification_screen.dart:150-158` — skip button only fires analytics + onNext(); no `requestPermission()` call | ✅ |

Side effect: reset `verify20260422b@sakinaqa.test` password to `Sakina2026!` via `auth.users.encrypted_password = crypt(...)` to enable #4.

## Follow-up run (2026-04-22 #2): fresh-install + Mixpanel

### Fresh-install routing ✅
Uninstalled via `xcrun simctl uninstall`, reinstalled from `build/ios/iphonesimulator/Runner.app`, launched. App lands directly on **Welcome** screen (Phase 1 state 1/5). No leaked routes, no crash.

### Mixpanel per-user audit ⚠️ (4 new defects)
Filtered analytics can't be run by Supabase user id because **`$user_id` is never populated**. Instead broke down by `$device_id = 59E3E084-7107-4972-A65D-3B5406471BC6` (2 onboarding runs today).

Counts per event, broken down by `step_index`:

| Event | Expected (2 runs) | Actual | Delta |
|---|---|---|---|
| `onboarding_step_viewed` | 52 (26 pages × 2) | 56 | +4 |
| `onboarding_step_completed` | 50 (25 completes × 2) | 52 | +2 |
| `onboarding_answer_captured` | - | 28 (step_index missing) | - |
| `onboarding_completed` | 2 | 2 | ✅ |
| `signup_completed` | 2 | 2 | ✅ |

#### D8 · [P2] Duplicate `onboarding_step_viewed` on pages 21 & 22
Every page fires 2× (two runs) except `step_index=21` (email) and `step_index=22` (password), which fire 4× each. Likely a widget rebuild or keyboard-dismiss re-fires the view event. Trace `_emitStepViewed` (or equivalent) in email/password screen init/didChangeDependencies.

#### D9 · [P2] Duplicate `onboarding_step_completed` on page 21
Page 21 (email screen) emits `step_completed` 4× across 2 runs. Possibly firing on `_submit()` and again on the next screen's onShown. Dedupe with a `_hasEmittedCompleted` flag.

#### D10 · [P3] `onboarding_answer_captured` missing `step_index`
All 28 events have `step_index = undefined`. Funnel-by-page analysis is broken. Add `'step_index': state.currentPage` to the properties map wherever the event is emitted.

#### D11 · [P2] `$user_id` never attached to Mixpanel events
`sign_up_password_screen.dart:77` calls `ref.read(analyticsProvider).identify(userId)` after Supabase signup, but no event ever carries `$user_id`. All events today show `$user_id = undefined` in breakdowns. Likely cause: `Mixpanel.identify()` from `mixpanel_flutter` alone does not attach `$user_id` as a super property — you must also call `_mixpanel.getPeople().set("\$user_id", userId)` or `setSuperProperties({'user_id': userId})`. Fix in `analytics_service.dart` `identify()` by also setting user properties or super properties. Until fixed, you cannot filter/breakdown by actual user in Mixpanel.

Artifacts: report URLs preserved in queries `d7e484bf` (device breakdown), `c67285f2` (step_index breakdown).

### D8–D11 verification (2026-04-22 run #3)

Post-fix fresh-install + full onboarding as `verifyfix20260422@sakinaqa.test` (uid `60eddf83-4e50-4097-b580-b9d54ed6f7a9`, device `E344450A-3746-4B91-AFF6-89C94DE09E8E`). Mixpanel queries `0bc36748` (user_id filter), `164c21ca` (step_index breakdown).

| Defect | Expected | Actual | Status |
|---|---|---|---|
| D8 `step_viewed` | 26 unique, 1× each | 26 unique, 1× each | ✅ |
| D9 `step_completed` | 25 unique, 1× each | 25 unique, 1× each | ✅ |
| D10 `answer_captured` carries step_index | step_index set on all events | 14 events, 13 pages, step_index populated | ✅ |
| D11 `user_id` filter works | events filterable | 2 events filterable by user_id=60eddf83… | ✅ |

Implementation:
- `onboarding_screen.dart` — added `Set<int> _viewedEmitted` / `_completedEmitted` with `_emitStepViewedOnce` / `_emitStepCompletedOnce` helpers.
- `analytics_events.dart` — new `trackOnboardingAnswerWithRef(ref, key, value)` reads `onboardingProvider.currentPage` and attaches `step_index` + `step_name`.
- `analytics_service.dart` — `identify(userId)` now additionally `registerSuperProperties({'user_id': userId})` and `getPeople().set(r'$user_id', userId)`.
- 13 callers updated to `trackOnboardingAnswerWithRef`.

## Deferred items — follow-up run (2026-04-22)

### #3 Account-switching data bleed — ✅ PASS

Two accounts with distinct DB state:
- User B `verifyfix20260422@sakinaqa.test` (uid `60eddf83-4e50-4097-b580-b9d54ed6f7a9`) — signed in first.
- User A `verify20260422b@sakinaqa.test` (uid `a55cc84f-c916-496f-8623-ef24cc89eca4`) — signed in second.

Flow: Settings → Sign Out (with confirmation dialog) → Welcome → "I Already Have an Account" → email + password → Sign In.

| Signal | User B | User A | Result |
|---|---|---|---|
| Settings email | `verifyfix20260422@sakinaqa.test` | `verify20260422b@sakinaqa.test` | ✅ scoped |
| Day Streak | 0 | 0 (fresh, not inherited) | ✅ |
| Total XP | 0 | 0 (fresh, not inherited) | ✅ |
| Daily reward day | D1 available | D1 available (separate user claim row) | ✅ |

Sign-out path in `settings_screen.dart:878-883` calls `onboardingProvider.reset()`, `appSessionProvider.clearSession()`, `_invalidateAllUserProviders(ref)`, then `authService.signOut()` — local Riverpod state is invalidated before new sign-in. No bleed observed. (The shared "Today's Name = Al-Azeez" is date-deterministic global content, not per-user.)

### #5 Deep link / push routing — ⚠️ Partial (no deep-link surface)

**Deep links — not implemented.**
- `ios/Runner/Info.plist` registers only `com.googleusercontent.apps.*` (Google OAuth callback). No custom app URL scheme.
- No `app_links` / `uni_links` / `FlutterDeepLinkingEnabled` — no Universal Links either.
- `xcrun simctl openurl sakina://journal` → `LSApplicationWorkspaceErrorDomain` error 115 (no handler).
- `xcrun simctl openurl https://sakina.app/journal` → opened in Safari (no AASA file intercepts it).

**Push routing — code exists, simulator can't end-to-end verify.**
- `notification_service.dart:394-405` — `routeForNotificationType()` maps `weekly_reflection → /journal`, default → `/`; wired via `OneSignal.Notifications.addClickListener`.
- `xcrun simctl push com.sakina.app.sakina payload.apns` delivered successfully (with `custom.a.type = daily_reminder`), but OneSignal SDK requires a real APNs device token to fire its click listener — physical device needed to validate routing on tap.

### #2 Fresh OS notification prompt — Not run

Requires uninstall + reinstall + fresh walk through onboarding to p15. Deferred — follow-up when time allows.

### #4 Airplane mode launch — Not run

Genuinely blocking the sim's network without breaking the MCP session is infeasible from this environment: toggling Mac Wi-Fi kills the Claude tooling channel; `/etc/hosts` and `pfctl` need sudo. Deferred — run manually via macOS Control Center → Wi-Fi off while sim is booted, then launch app, expect graceful offline state (no crash, no blank home).

## Deferred (out of scope for today)

- **Paywall purchase path.** Sim can't complete StoreKit — physical-device job.
- **#2 fresh OS notification prompt** — needs clean reinstall cycle.
- **#4 airplane mode launch** — needs Mac-level network toggle, manual.

---

## Artifacts

- `docs/qa/ui-map.md` — persistent coord reference (iPhone 17, logical points) for fast re-runs.
- `/tmp/sakina-test/*.png` — 30+ screenshots of every page, including keyboard-up state for p0.
- Test account: `sakinatest20260422a@sakinaqa.test` (uid `639aed54-d59a-49d7-bd59-6f52552594cb`) — leave or purge with `delete_own_account()` as desired.
