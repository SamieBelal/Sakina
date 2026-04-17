# Onboarding Refactor — Input-Driven Flow

**Date:** 2026-04-16
**Status:** Design approved, pending implementation plan
**Owner:** Ibrahim

## 1. Problem

Today's onboarding has 20 screens, but only 6 take user input (first check-in + 5 late-stage survey questions). The remaining 14 are passive — 5 of them are consecutive feature-showcase screens (steps 1–5) the user taps through without contributing anything. Sign-up happens at step 6, *before* any personalization quiz, so the user is asked to commit an account before the app has learned anything about them.

This diverges from how the best-converting onboarding flows work — Cal AI, Duolingo, Noom, and Fastic all front-load input-dense quizzes, defer sign-up until after a "generated plan" moment, and use the user's own answers to drive the paywall and home experience. Cal AI's onboarding is 25+ screens, but it feels short because nearly every screen asks a question.

## 2. Goal

Refactor onboarding into an input-driven flow (~29 screens, ~15 input screens) modeled on Cal AI and Duolingo. Every screen either:

1. **Takes input** from the user (preferred), or
2. **Is an earned passive** — a reward, reveal, commitment moment, social-proof interstitial, or system prompt that follows directly from a prior input.

No more passive feature-tour screens that exist only because the user hasn't reached the app yet.

## 3. Non-goals

- Reducing the number of screens (the user explicitly wants Cal AI density, not brevity).
- Redesigning the post-onboarding home experience.
- Changing the paywall product/pricing — only its personalization layer.
- Internationalization (strings will stay English in this refactor; i18n extraction is in scope only where it's free).
- Changing auth providers (Apple / Google / Email stay).
- RevenueCat/Superwall integration changes.

## 4. New flow (29 screens)

### Phase 1 — Hook (2 screens)

| # | Screen | Type | Input schema |
|---|---|---|---|
| 1 | First Check-in | **input** | `demoFeelingInput: String` (free text, emotion chips fallback) |
| 2 | Name reveal / gacha | earned passive | — (reward for #1, existing `NameRevealOverlay`) |

### Phase 2 — Personalization quiz (12 screens, pre-auth)

| # | Screen | Type | Input schema |
|---|---|---|---|
| 3 | Your first name | **input** | `signUpName: String` (moved up from step 9) |
| 4 | Age range | **input** (new) | `ageRange: enum { 13_17, 18_24, 25_34, 35_44, 45_54, 55plus }` — app is 13+ per Apple minimum; no under-13 option |
| 5 | Intention | **input** | `intention: enum { spiritualGrowth, difficultTime, justCurious, dailyHabit }` (keep) |
| 6 | Prayer frequency | **input** (new) | `prayerFrequency: enum { fivePlus, someDaily, fridaysOnly, rarely, learning }` — non-judgmental labels |
| 7 | Quran connection | **input** | `quranConnection: enum` (keep) |
| 8 | Familiarity with 99 Names | **input** | `familiarity: enum` (keep) |
| 9 | Most meaningful Name | **input** (new — replaces Feature: Collect) | `resonantName: String` (id of one Name from a curated carousel of ~6) |
| 10 | What you'd dua for | **input** (new — replaces Feature: Build) | `duaTopics: Set<enum> { health, family, forgiveness, guidance, peace, success, provision, other }` + optional `duaTopicsOther: String` |
| 11 | Struggles | **input** | `struggles: Set<String>` (keep) |
| 12 | Emotions that come up often | **input** (new — replaces Feature: Reflect) | `commonEmotions: Set<String>` (multi-select chips OR free text) |
| 13 | Who you want to become | **input** (new) | `aspirations: Set<enum> { morePatient, moreGrateful, closerToAllah, morePresent, strongerFaith, moreConsistent }` |
| 14 | Daily commitment | **input** (new — replaces Feature: Quests) | `dailyCommitmentMinutes: enum { 1, 3, 5, 10 }` |

### Phase 3 — Social proof + attribution (3 screens)

| # | Screen | Type | Input schema |
|---|---|---|---|
| 15 | Social-proof interstitial | earned passive | — (copy templated against `struggles` and `intention`) |
| 16 | Attribution | **input** | `attribution: Set<String>` (keep) |
| 17 | "You're not alone" interstitial | earned passive | — (copy references a specific selected struggle) |

### Phase 4 — Commit & generate (5 screens)

| # | Screen | Type | Input schema |
|---|---|---|---|
| 18 | Reminder time picker | **input** (new) | `reminderTime: TimeOfDay` |
| 19 | Notification permission | system passive | — (iOS/Android prompt) |
| 20 | Commitment pact | **micro-input** (new) | `commitmentAccepted: bool` (tap to sign). Copy is conditional on #19 outcome: if notifications granted → "I commit to {dailyCommitmentMinutes} minutes a day, with a gentle reminder at {reminderTime}"; if denied → drop the reminder clause ("I commit to {dailyCommitmentMinutes} minutes a day") |
| 21 | Generating your plan | earned passive | — (existing `runGeneratingTheater`, 3s) |
| 22 | Your personalized plan | earned passive | — (the reveal — shows `intention`, `resonantName` or fallback `Ar-Rahman` if user didn't pick, top struggle or a generic "your path" label if none, `reminderTime` as a plan card) |

### Phase 5 — Auth & paywall (6 screens)

| # | Screen | Type | Input schema |
|---|---|---|---|
| 23 | Value prop tied to answers | earned passive | — (dynamic copy referencing quiz answers) |
| 24 | Social proof / reviews | earned passive | — (keep) |
| 25 | Save-progress choice | auth | Apple / Google / Email |
| 26 | Sign-up email | auth | `signUpEmail: String` |
| 27 | Sign-up password | auth | password |
| 28 | Encouragement | earned passive | — ("Ahlan, {signUpName}") |
| 29 | Paywall | paywall | (personalized framing referencing `struggles`, `aspirations`, `dailyCommitmentMinutes`) |

> Note: numbering above is 1-indexed for readability; `PageView` is 0-indexed. The final `onboardingLastPageIndex` will be **28** (paywall at `PageView` index 28, quiz spans 0–27).

### Screens deleted
- `feature_names_screen.dart` (replaced by screen #9)
- `feature_reflect_screen.dart` (replaced by screen #12)
- `feature_dua_screen.dart` (replaced by screen #10)
- `feature_quests_screen.dart` (replaced by screen #14)
- `feature_journal_screen.dart` (deleted outright; Journal is shown on the personalized-plan reveal instead)
- `value_prop_screen.dart` (replaced by screen #23 with dynamic copy)

## 5. State model changes

`OnboardingState` (in `onboarding_provider.dart`) gains the following fields. All are nullable / empty-default for safe resume:

```dart
final String? ageRange;
final String? prayerFrequency;
final String? resonantNameId;            // FK into Names of Allah table
final Set<String> duaTopics;
final String? duaTopicsOther;
final Set<String> commonEmotions;
final Set<String> aspirations;
final int? dailyCommitmentMinutes;       // 1 | 3 | 5 | 10
final String? reminderTime;              // "HH:mm" 24h
final bool commitmentAccepted;
```

`toJson` / `fromJson` bump to `version: 3`. **Sakina has no production users at the time of this refactor**, so no v2→v3 state-migration logic is required beyond defaulting new fields to null / empty on deserialize. `loadFromPrefs` may safely discard any pre-existing `v < 3` blob and start the user at page 0. v1 / legacy `currentPage` offset handling may be removed alongside this bump.

**Free-text input sanitization:** all free-text fields (`demoFeelingInput`, `duaTopicsOther`, `commonEmotions` when in free-text mode, `signUpName`) are capped at **280 characters** client-side, trimmed, and the existing CLAUDE.md RTL-bleed rule (`TextDirection.rtl` on Arabic-only sub-widgets) applies to any downstream rendering.

`onboardingLastPageIndex` is updated from `19` to `28` (0-indexed — 29 screens total).

Each field gets a corresponding `setX` / `toggleX` notifier method, mirroring existing patterns (`setIntention`, `toggleStruggle`, etc.).

## 6. Persistence

### Local
SharedPreferences persistence already exists and survives resume mid-quiz. New fields ride along via the same `toJson`/`fromJson` path.

**Zero server-side writes until sign-up (#25).** Quiz answers live only in `SharedPreferences` until the user authenticates. This is intentional (no PII written pre-consent). Consequence: if a user uninstalls between #3 and #25, their answers are lost — acceptable. Any downstream analytics or services that historically enriched events from `user_profiles` must tolerate the quiz fields being absent pre-auth.

### Supabase
`AuthService.saveOnboardingData` (called from `persistOnboardingToSupabase`) is extended to accept and write the new columns on `user_profiles`:

- `age_range text`
- `prayer_frequency text`
- `resonant_name_id uuid references names_of_allah(id)`
- `dua_topics text[]`
- `dua_topics_other text`
- `common_emotions text[]`
- `aspirations text[]`
- `daily_commitment_minutes int`
- `reminder_time time`

One new migration adds these columns with sensible defaults and RLS consistent with existing `user_profiles` policies.

## 7. Downstream personalization hooks

The new inputs are not just captured — they drive:

1. **Personalized plan reveal (#22)** — reads `intention`, `resonantNameId`, first `struggles` element, `reminderTime`, `dailyCommitmentMinutes` to render the plan card.
2. **Value prop (#23)** — conditional copy blocks keyed on top `aspiration` and top `struggle`.
3. **Paywall (#29)** — framing copy ("You told us you want to become **more patient**. Sakina helps in {dailyCommitmentMinutes} minutes a day.") keyed on `aspirations` + `dailyCommitmentMinutes`.
4. **Scheduled notifications** — `reminderTime` seeds the existing notification-scheduling service's default daily reminder. Because notification permission (#19) is now requested *before* sign-up (#25), the OneSignal subscriber is initially anonymous. On successful auth at #25, the existing `AuthService` sign-up path must call OneSignal's external-user-id identify to bind the anon subscriber to the new user id; this binding already exists for the current flow and is preserved — it simply runs in a different position in the sequence.
5. **Home screen first-load** — `resonantNameId` is pre-loaded as the user's "starred" Name of Allah (existing favorites model).

These hooks are **thin**: each downstream consumer reads from `user_profiles` (Supabase) or `OnboardingState` directly. No new service layer.

## 8. Analytics

Every new input screen emits:
- `step_viewed` on entry (existing)
- `step_completed` on advance (existing)
- `onboarding_answer_captured` with `{ key, value }` on answer (**new**)

`setUserProperties` on `completeOnboarding` is extended to push the new fields to Mixpanel as user properties, so cohorting by `aspirations`, `dailyCommitmentMinutes`, etc. works out of the box.

**Post-launch observability requirement:** build a **per-screen drop-off funnel dashboard** in Mixpanel keyed on `step_viewed` / `step_completed`. This is the primary instrument for judging whether the refactor moved the needle; without it, the refactor is un-measurable. Dashboard must render: per-step viewed count, per-step completed count, per-step conversion %, and end-to-end paywall-reached rate.

## 9. Copy & UX constraints

- **Warm, non-judgmental tone** throughout — especially for prayer frequency (never "you're doing badly").
- **"Because you said X"** pattern on interstitials (#15, #17, #22, #23) — always cite a prior answer to make the personalization feel real.
- **Progress bar** updates to reflect 28 total segments. Paywall (#29) still hides the bar.
- **Back button** allowed on every quiz screen until #25 (save-progress). Once authed, back is disabled to avoid auth state drift.
- Arabic calligraphy on screen #9 (Name selection) uses `AdjustedArabicDisplay` per CLAUDE.md.
- **No skip on quiz questions.** Continue is disabled until the user selects / types an answer on every input screen (Cal AI / Duolingo pattern). The only exceptions are the free-text-with-optional-other fields (`duaTopicsOther`, `commonEmotions` free-text variant) which are genuinely optional extensions to a required multi-select. This eliminates null-branch proliferation across every downstream personalization consumer.

## 9a. Shared input-screen scaffold (`OnboardingQuestionScaffold`)

To keep the 8 new input screens DRY, a single reusable widget is introduced:

```dart
class OnboardingQuestionScaffold extends StatelessWidget {
  final String headline;          // required
  final String? subtitle;          // optional caption below headline
  final Widget body;              // the input (chips, cards, text field, time wheel)
  final VoidCallback onContinue;
  final bool continueEnabled;     // false until answer selected (see §9 "no skip" rule)
  final VoidCallback onBack;
}
```

All new input screens (#3, #4, #6, #9, #10, #12, #13, #14, #18, #20) compose through this scaffold. Existing input screens (`IntentionScreen`, `FamiliarityScreen`, `QuranConnectionScreen`, `StrugglesScreen`, `AttributionScreen`) are migrated to it in the same refactor so all quiz screens share one layout contract. Estimated reduction: ~400 lines of duplicated scaffolding across the 13 quiz screens.

## 10. Migration plan (order of work for the implementation plan)

1. Extend `OnboardingState` + notifier methods + v3 JSON migration + tests.
2. Add Supabase migration for new `user_profiles` columns.
3. Extend `AuthService.saveOnboardingData`.
4. Build the 8 new input screens (one per feature: age range, prayer frequency, resonant Name, dua topics, common emotions, aspirations, daily commitment, reminder time, commitment pact).
5. Rebuild the "Your personalized plan" screen (#22).
6. Rewrite `value_prop_screen.dart` as dynamic-copy screen #23.
7. Rewrite `social_proof_screen.dart` + add second interstitial (#17).
8. Reorder `onboarding_screen.dart` PageView to the new sequence; update `onboardingLastPageIndex` to 28.
9. Delete the 5 old feature screens.
10. Extend analytics hooks.
11. Update paywall copy renderer to consume new fields.
12. Update widget tests; add tests for:
    - each new input screen (pick → Continue becomes enabled → tapping advances);
    - the resume-mid-quiz flow;
    - an integration test asserting every quiz field round-trips through `completeOnboarding` → `user_profiles`;
    - conditional commitment-pact copy (notifications granted vs denied paths);
    - fallback Ar-Rahman rendering on screen #22 when `resonantNameId` is null;
    - a regression test for OneSignal external-user-id binding on sign-up (#25) — the binding must still fire correctly now that notification permission is requested at #19 pre-auth.

## 11. Open questions

None blocking implementation. Copy polish and the exact Name carousel content (which 6 Names appear in screen #9) will be decided in the implementation plan.

## 12. Rollout posture

Single-cutover deploy — **no feature flag, no kill switch.** Rollback if production conversion tanks requires a revert + App Store re-submission (24–48h worst case). This posture is acceptable because Sakina has no production users at the time of this refactor; the funnel-loss-per-hour cost of a bad launch is effectively zero. Post-launch this posture should be reconsidered for subsequent onboarding iterations.

Supabase migration is additive / nullable / zero-downtime.

## 13. Pre-ship gate: privacy policy

Before App Store submission of the build containing this refactor, the privacy policy **must** be updated to disclose the following additional Mixpanel user properties and Supabase `user_profiles` columns, all of which are religious-behavior, health-adjacent, or demographic signals:

- `aspirations`
- `prayer_frequency`
- `age_range`
- `common_emotions`
- `dua_topics` (and `dua_topics_other`)
- `resonant_name_id`
- `daily_commitment_minutes`
- `reminder_time`

This extends the existing pre-launch privacy-policy item in `TODOS.md`. This spec does not ship until the policy is updated.

## 14. Out of scope / explicitly deferred

- Dynamic branching based on prior answers (e.g., showing different follow-ups for `prayerFrequency = rarely` vs `fivePlus`). Revisit after v1 ships.
- A/B testing harness on quiz copy.
- Voice input / audio onboarding.
- Localizing the new strings beyond English.
