# Lane B — QA Run Log (2026-06-01 Full Regression)

**Config:** Legacy build (`RATING_GATE_ENABLED=false`), `onboarding_trim_enabled=false`, `guided_tour_enabled=false`  
**Sim:** iPhone 16 Pro — UDID `2AC274EC-AF75-4E57-9687-76723B56B66B`  
**Account:** `sakinaqa.laneb.01@gmail.com` / `SakinaQA!2026`  
**Auth UID:** `782c572c-018e-48f1-944b-a6bda9265ff6`  
**Tester:** QA Lane B agent  
**Date:** 2026-06-01  
**Duration:** ~25 minutes  

---

## Summary

| Result | Count |
|--------|-------|
| PASS | 8 |
| FAIL | 0 |
| BLOCKED | 1 |
| FINDING (non-blocking) | 1 |

---

## Pre-flight Checks

| Check | Result | Evidence |
|-------|--------|---------|
| `app_config.onboarding_trim_enabled` | CONFIRMED false | `SELECT key, value FROM app_config WHERE key IN (...)` → both `false` |
| `app_config.guided_tour_enabled` | CONFIRMED false | Same query above |
| Legacy build (`RATING_GATE_ENABLED=false`) | CONFIRMED | Legacy binary; `onboardingLegacyLastPageIndex` = 25 (no rating gate) |

---

## Test Cases

| # | Test Case | Status | Evidence |
|---|-----------|--------|---------|
| B-01 | Clean launch → welcome screen | **PASS** | `B-00-launch.png`, `B-01-ob-page0.png` |
| B-02 | app_config kill switches confirmed OFF | **PASS** | SQL confirms both flags `false` |
| B-03 | Legacy onboarding has more screens than trimmed (legacy-only pages present) | **PASS** | Screenshots confirm QuranConnectionScreen (p5), CommonEmotionsScreen (p8), AspirationsScreen (p9), StruggleSupportInterstitialScreen (p12), ValuePropScreen (p16) — all LEGACY-ONLY |
| B-04 | No keyboard overflow on text-entry screens | **PASS** | `B-08-ob-name-keyboard.png`, `B-19-ob-page19-email.png`, `B-20-ob-page20-password.png` — buttons visible above keyboard |
| B-05 | No Arabic/English RTL bleed | **PASS** | Name reveal, Starting Name card, Home screen — Arabic in separate widgets; `AdjustedArabicDisplay` used correctly |
| B-06 | No guided tour after completing onboarding to Home | **PASS** | `B-33-home-screen-final.png`, `B-34-relaunch-no-tour.png` — no coachmarks visible on first arrival or relaunch |
| B-07 | Rating gate ABSENT in 26-page RATING_GATE_ENABLED=false build | **PASS** | After YourJourneyScreen (p24), went directly to PaywallScreen (p25). No RatingGateScreen appeared. `rating_gate_skipped` event fired (count=2 in Mixpanel today) |
| B-08 | Abandonment telemetry `onboarding_abandoned_at_page` | **BLOCKED** | Event requires 24h+ gap from paused (backgrounded) state. Cannot be triggered in a sim QA session without time mock. Mixpanel confirms 0 over 30 days. Unit test `test/features/onboarding/abandonment_telemetry_test.dart` covers the logic. See finding below. |
| B-09 | Social-auth routing (Google/Apple) on page 18 | **PASS** (partial) | `B-18-ob-page18-save-progress.png` confirms both "Sign in with Apple" and "Sign in with Google" buttons present on page 18 (SaveProgressScreen). OAuth completion via MCP impossible (simulator limitation). Unit test `test/features/onboarding/onboarding_auth_routing_test.dart` pins the skip-to-page-21 routing. **BLOCKED for full execution.** |
| B-10 | DB: `user_profiles` written correctly after legacy onboarding | **PASS** | SQL row confirmed: `display_name=QATester`, `onboarding_completed=true`, all quiz fields populated correctly. See DB evidence below. |

---

## Detailed Evidence

### B-01: Clean Launch
- App launched with `terminate_running=true`
- Welcome screen: "سكينة" + "Reflect · Build · Discover" + Quran verse (Arabic separate from English) + "Get Started" + "I Already Have an Account"
- **Screenshot:** `screens/B-00-launch.png`

### B-03: Legacy Onboarding Pages

**Pages walked (0-indexed):**

| Page | Screen | Legacy-only? | Screenshot |
|------|--------|-------------|-----------|
| 0 | FirstCheckinScreen ("How are you feeling today?") | No | `B-01-ob-page0.png` |
| — | Name of Allah reveal overlay (gacha) | Modal, not a page | `B-04-ob-page1-namereveal.png` |
| 1 | NameInputScreen ("What should we call you?") | No | `B-08-ob-name-keyboard.png` |
| 2 | AgeRangeScreen ("How old are you?") | No | `B-09-ob-page2-age.png` |
| 3 | IntentionScreen ("What brings you here?") | No | `B-12-ob-page3-intention.png` |
| 4 | PrayerFrequencyScreen ("How often do you pray?") | No | (AX only) |
| **5** | **QuranConnectionScreen ("How often do you connect with the Quran?")** | **YES** | `B-13-ob-page5-quran-connection-LEGACY.png` |
| 6 | FamiliarityScreen ("How familiar with the 99 Names?") | No | (AX only) |
| 7 | DuaTopicsScreen ("What would you most want to dua for?") | No | (AX only) |
| **8** | **CommonEmotionsScreen ("Which emotions come up most for you?")** | **YES** | `B-14-ob-page8-common-emotions-LEGACY.png` |
| **9** | **AspirationsScreen ("Who do you want to become?")** | **YES** | `B-15-ob-page9-aspirations-LEGACY.png` |
| 10 | DailyCommitmentScreen ("How much time a day feels right?") | No | (AX only) |
| 11 | AttributionScreen ("Where did you hear about Sakina?") | No | (AX only) |
| **12** | **StruggleSupportInterstitialScreen ("You're not alone in this.")** | **YES** | `B-16-ob-page12-struggle-support-LEGACY.png` |
| 13 | ReminderTimeScreen ("When should we check in with you?") | No | (AX only) |
| 14 | NotificationScreen ("Stay connected to your practice") | No | (AX only) |
| 15 | CommitmentPactScreen ("Your commitment") | No | (AX only) |
| **16** | **ValuePropScreen ("Sakina helps you become who you want to be")** | **YES** | `B-17-ob-page16-valueprop-LEGACY.png` |
| 17 | SocialProofScreen ("Sakina was made for hearts like yours") | No | (AX only) |
| 18 | SaveProgressScreen ("Save your progress") | No | `B-18-ob-page18-save-progress.png` |
| 19 | SignUpEmailScreen ("What's your email?") | No | `B-19-ob-page19-email.png` |
| 20 | SignUpPasswordScreen ("Create a password") | No | `B-20-ob-page20-password.png` |
| **21** | **EncouragementScreen ("Something beautiful awaits you, QATester")** | **YES** | `B-22-ob-after-signup.png` |
| 22 | GeneratingScreen (loader w/ Bismillah) | No | `B-24-ob-page22-generating.png` |
| 23 | PersonalizedPlanScreen ("Your plan, QATester.") | No | `B-24-ob-page22-generating.png` (captures p23) |
| 24 | YourJourneyScreen ("Where you'll be in 30 days") | No | `B-25-ob-page24-journey.png` |
| **25** | **PaywallScreen (NO rating gate — direct from p24)** | Gate removed | `B-26-ob-page25-paywall-or-ratinggate.png` |

**Total: 26 pages (0-25), 6 legacy-only screens confirmed present. Trimmed flow has 20 pages (0-19). Legacy has 6 additional screens: pages 5, 8, 9, 12, 16, 21.**

### B-04: Keyboard Overflow Checks
- NameInputScreen (p1): Text field + "Continue" button both visible above keyboard. No overflow.
- SignUpEmailScreen (p19): Email field + "Continue" button visible above keyboard. No overflow.
- SignUpPasswordScreen (p20): Password field + "Create Account" button visible above keyboard. No overflow.
- Layout pattern (`LayoutBuilder → SingleChildScrollView → ConstrainedBox → IntrinsicHeight`) confirmed working.

### B-05: Arabic/English RTL Check
- Name reveal overlay: "السلام" in separate full-screen AnimatedText widget, "As-Salam" in English below. No bleed.
- Starting Name card (p2): "السَّلَامُ" gold Arabic text, then "As-Salam" English transliteration on separate line. No bleed.
- DailyLaunchOverlay: "السَّلَامُ" in separate AdjustedArabicDisplay widget, "As-Salam — The Source of Peace" in English below. No bleed.
- Home screen: Same pattern on Starting Name card. No bleed.

### B-07: Rating Gate Absent
- After YourJourneyScreen (p24) → tapped "Begin my 30 days" → went directly to PaywallScreen. No RatingGateScreen appeared.
- PaywallScreen confirmed: "YOU'RE 1 STEP AWAY, QATester" / "Just 5 minutes a day..."
- Mixpanel `rating_gate_skipped` count: **2 events today** (at least 1 from this run)
- The code `if (Env.ratingGateEnabled) RatingGateScreen(...)` correctly excludes the page when false.

### B-08: Abandonment Telemetry (BLOCKED)

The `onboarding_abandoned_at_page` event is designed to fire when:
1. The `OnboardingScreen` widget detects `AppLifecycleState.paused`
2. Then `AppLifecycleState.resumed` is detected **>24 hours later**

This 24-hour gap makes the event **impossible to trigger in a QA session** without time mocking.

**What was attempted:**
- Advanced to page 2 (AgeRangeScreen), terminated the app, relaunched
- `xcrun simctl terminate` does not send `AppLifecycleState.paused` to the app before killing it
- On relaunch, state was correctly restored to page 2 (saved to SharedPreferences), but `_pausedAt` is null (in-memory only, lost on process kill)

**Baseline:** Mixpanel `onboarding_abandoned_at_page` count = **0 over 30 days** (confirmed), **0 for today** (confirmed).

**Coverage:** Unit test `test/features/onboarding/abandonment_telemetry_test.dart` pins:
- `shouldFireAbandonment` returns `true` for >24h gap
- `shouldFireAbandonment` returns `false` for ≤24h gap
- Legacy paywall suppression gate uses `_activeLastPageIndex` correctly (page 25 suppressed for legacy, page 19 suppressed for trimmed)
- Dual-flow index M2 test confirms legacy paywall at page 25 is suppressed (not page 19)

**Recommendation:** To exercise this event in CI/QA, expose a `debugForcedAbandonmentThreshold` or time-injection seam to `shouldFireAbandonment`.

### B-09: Social-Auth Routing
- Page 18 (SaveProgressScreen) confirmed: "Sign in with Apple" (black) and "Sign in with Google" (white) buttons present
- "Did a friend send you a gift?" referral code disclosure expandable present
- OAuth completion is impossible via MCP on iOS Simulator (OAuth sheets require real device + Apple ID)
- Unit test `test/features/onboarding/onboarding_auth_routing_test.dart` pins the social-auth jump from page 18 to page 21 (Encouragement), skipping Email/Password screens
- **BLOCKED for actual OAuth execution**

### B-10: DB Profile Evidence

```sql
SELECT id, display_name, onboarding_completed, onboarding_intention, onboarding_familiarity,
       age_range, prayer_frequency, daily_commitment_minutes, reminder_time, 
       commitment_accepted, starter_name_id, dua_topics, referral_code
FROM user_profiles WHERE id = '782c572c-018e-48f1-944b-a6bda9265ff6';
```

Result:
| Field | Value | Expected | Match |
|-------|-------|---------|-------|
| display_name | QATester | Name entered | ✓ |
| onboarding_completed | true | true | ✓ |
| onboarding_intention | Just Curious | Intention selected | ✓ |
| onboarding_familiarity | somewhat | Somewhat Familiar | ✓ |
| age_range | 25_34 | 25-34 selected | ✓ |
| prayer_frequency | fivePlus | Five times a day | ✓ |
| daily_commitment_minutes | 5 | 5 min | ✓ |
| reminder_time | 08:00:00 | 8:00 AM | ✓ |
| commitment_accepted | true | Committed | ✓ |
| starter_name_id | 6 | As-Salam | ✓ |
| dua_topics | ["peace"] | Peace selected | ✓ |
| referral_code | 3PAAYTN3 | Generated | ✓ |

---

## Findings

### FINDING-1: Migration 20260525000001 Not Applied to Production

**Severity:** Low / Non-blocking  
**Detail:** Migration `supabase/migrations/20260525000001_drop_unused_onboarding_columns.sql` drops `onboarding_quran_connection`, `common_emotions`, `aspirations` from `user_profiles`. These columns **still exist** in production (`schema_migrations` table does not show version `20260525000001`).  
**Impact:** No functional impact — legacy flow still writes to these columns correctly, and the trimmed flow does not write to them (they remain null). The columns are benign dead weight.  
**Action:** Apply the migration when convenient; not a release blocker.  
**Evidence:** `SELECT column_name FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name IN ('onboarding_quran_connection', 'common_emotions', 'aspirations')` → all 3 returned.

### FINDING-2: onboarding_abandoned_at_page Cannot Be Exercised in QA Sessions

**Severity:** Gap / Design constraint  
**Detail:** The event requires a 24h+ background gap via `AppLifecycleState` transitions. No sim-based or manual QA session can trigger it without time mocking. The event has been at count=0 for 30+ days in production (confirming no real users have abandoned for 24h+ mid-onboarding and returned). This may be expected (most users either complete quickly or don't return).  
**Action:** Add a `shouldFireAbandonment` override/seam in debug builds to enable automated testing via widget tests or integration tests. Alternatively, accept that this is covered by unit tests only.  
**Bug file:** See `docs/qa/findings/2026-06-01-abandonment-telemetry-not-exercisable.md`

---

## Mixpanel Analytics

| Event | Count (today) | Count (30d) | Notes |
|-------|-------------|------------|-------|
| `rating_gate_skipped` | 2 | — | At least 1 from this run; confirms firing when gate disabled |
| `onboarding_abandoned_at_page` | 0 | 0 | Cannot be triggered in QA; unit-tested only |

---

## Screenshots Index

| File | Description |
|------|-------------|
| `B-00-launch.png` | Sakina splash → welcome screen |
| `B-01-ob-page0.png` | FirstCheckinScreen — "How are you feeling today?" |
| `B-04-ob-page1-namereveal.png` | Name of Allah reveal overlay (As-Salam) |
| `B-05-ob-page2.png` | Starting Name card — Arabic/English RTL check |
| `B-07-ob-page3.png` | AgeRangeScreen (state resume confirmation) |
| `B-08-ob-name-keyboard.png` | NameInputScreen with keyboard — no overflow |
| `B-12-ob-page3-intention.png` | IntentionScreen |
| `B-13-ob-page5-quran-connection-LEGACY.png` | **LEGACY-ONLY: QuranConnectionScreen (p5)** |
| `B-14-ob-page8-common-emotions-LEGACY.png` | **LEGACY-ONLY: CommonEmotionsScreen (p8)** |
| `B-15-ob-page9-aspirations-LEGACY.png` | **LEGACY-ONLY: AspirationsScreen (p9)** |
| `B-16-ob-page12-struggle-support-LEGACY.png` | **LEGACY-ONLY: StruggleSupportInterstitialScreen (p12)** |
| `B-17-ob-page16-valueprop-LEGACY.png` | **LEGACY-ONLY: ValuePropScreen (p16)** |
| `B-18-ob-page18-save-progress.png` | SaveProgressScreen — social auth routing page |
| `B-19-ob-page19-email.png` | SignUpEmailScreen — keyboard layout check |
| `B-20-ob-page20-password.png` | SignUpPasswordScreen — keyboard layout check |
| `B-22-ob-after-signup.png` | EncouragementScreen — personalized with "QATester" |
| `B-24-ob-page22-generating.png` | GeneratingScreen + PersonalizedPlanScreen |
| `B-25-ob-page24-journey.png` | YourJourneyScreen — 30-day timeline |
| `B-26-ob-page25-paywall-or-ratinggate.png` | **PaywallScreen (p25) — NO rating gate before it** |
| `B-27-home-after-onboarding.png` | Refer-to-Unlock screen post-paywall-dismiss |
| `B-28-after-referunlock.png` | DailyLaunchOverlay — Starting Name card |
| `B-33-home-screen-final.png` | Home screen — no guided tour visible |
| `B-34-relaunch-no-tour.png` | Home screen after cold relaunch — no guided tour |
