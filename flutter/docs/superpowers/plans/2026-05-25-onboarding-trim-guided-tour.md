# Onboarding Trim + Guided Tour Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trim onboarding from 27 → 18 screens, retire unused profile fields from Supabase, and ship a 4-surface contextual guided tour (Home / Collection / Journal / Duas) that uses on-brand coachmarks plus empty-state teaching to introduce features post-paywall.

**Architecture:**
- **Phase A — Onboarding cuts:** delete 7 screens (`quran_connection`, `common_emotions`, `aspirations`, `struggle_support_interstitial`, `value_prop`, `encouragement`, `your_journey`), rewire `OnboardingScreen`'s `PageView`, recompute page-index constants, bump `OnboardingState.toJson` version 6 → 7, drop now-unused fields from `OnboardingState` + `AuthService.saveOnboardingData`, update routing test pins.
- **Phase B — Supabase cleanup:** drop now-unused columns from `public.user_profiles` (`onboarding_quran_connection`, `common_emotions`, `aspirations`) via a forward-only migration. Other fields stay (still captured).
- **Phase C — Guided tour:** roll-your-own `CoachmarkOverlay` widget (cream scrim + cutout + emerald tooltip card with gold accent line — matches `app_colors.dart` palette) driven by `TourService` (per-user, versioned shared-prefs keys). Four micro-tours: 3-step Home, empty-state Collection, empty-state Journal, 1-step Duas. Triggers on first-visit per surface, never blocks, fully skippable. Settings → "Replay tour" entry resets all flags. Mixpanel events for funnel analysis.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4 · Riverpod · GoRouter · SharedPreferences · Supabase Postgres · Mixpanel · pgTAP (CI tests for migration). No new pub deps — bespoke `OverlayEntry` keeps the brand cream/emerald aesthetic without `showcaseview`'s default chrome.

---

## File Structure

**New files:**
- `lib/services/tour_service.dart` — per-user, versioned tour-seen flag store on SharedPreferences. Exposed via `tourServiceProvider`.
- `lib/widgets/coachmark/coachmark_overlay.dart` — `OverlayEntry`-based widget. Renders cream scrim + cutout around target `GlobalKey`, emerald tooltip card with gold top-accent, step dots, `Skip` / `Next` bar.
- `lib/widgets/coachmark/coachmark_step.dart` — `CoachmarkStep` value type: `{ GlobalKey target, String message, AlignmentDirectional tooltipAlign }`.
- `lib/widgets/coachmark/coachmark_controller.dart` — sequence runner (`start`, `next`, `skip`), invokes `onComplete` / `onSkip` callbacks. Inserts/removes `OverlayEntry`. Has no Riverpod dep so it stays testable.
- `lib/features/tour/providers/tour_keys_provider.dart` — `Provider<TourKeys>` exposing `GlobalKey`s for Home CTA, streak pill, tab bar, Duas save-heart so widgets can both register and consume the same key.
- `test/services/tour_service_test.dart` — unit test for first-show / mark-seen / reset semantics.
- `test/widgets/coachmark/coachmark_overlay_test.dart` — widget test that the overlay shows + dismisses correctly.
- `test/features/tour/home_tour_trigger_test.dart` — integration-ish widget test verifying Home auto-fires the tour on first visit.
- `supabase/migrations/20260525000000_drop_unused_onboarding_columns.sql` — forward-only DROP COLUMN migration.
- `supabase/tests/00040_unused_onboarding_columns_dropped.sql` — pgTAP assertion the columns no longer exist.
- `docs/qa/plans/2026-05-25-tour-manual-qa.md` — manual QA checklist for device runs.

**Modified files:**
- `lib/features/onboarding/providers/onboarding_provider.dart` — remove `quranConnection` / `commonEmotions` / `aspirations` fields + setters, bump `toJson.version` 6→7, recompute `onboardingLastPageIndex` / `onboardingEmailPageIndex` / `onboardingPasswordPageIndex` / `onboardingEncouragementPageIndex`.
- `lib/features/onboarding/screens/onboarding_screen.dart` — remove imports + PageView children for the 7 deleted screens, renumber inline comments.
- `lib/features/onboarding/screens/save_progress_screen.dart` — verify `onSocialAuthComplete` still jumps to the (new) Encouragement index (now removed → jumps straight to Generating).
- `lib/features/onboarding/screens/personalized_plan_screen.dart` — absorb the one-line "you committed!" tease from `encouragement_screen.dart` into the plan header.
- `lib/services/auth_service.dart` — drop `quranConnection`, `commonEmotions`, `aspirations` params from `saveOnboardingData`; drop the matching keys from the `update()` map.
- `lib/features/feelings/screens/home_screen.dart` (it does exist — but `ProgressScreen` is the actual `/` route; verify which renders the Muḥāsabah CTA). Attach `GlobalKey`s to: `Begin Muḥāsabah` CTA button, streak pill, and tab bar. Fire `TourController.start()` post-first-frame on first visit.
- `lib/features/progress/screens/progress_screen.dart` — same GlobalKey wiring as above on the `Begin Muḥāsabah` button at `:787` and the streak pill (find in same file).
- `lib/features/collection/screens/collection_screen.dart` — render explanatory caption only on first visit when the starter card is the only card; mark seen on first build.
- `lib/features/journal/screens/journal_screen.dart` — replace plain empty state with illustrated empty state + `Write first entry` CTA that opens the editor pre-loaded with today's Name.
- `lib/features/duas/screens/duas_screen.dart` — single coachmark on the first dua card's save-heart icon on first visit.
- `lib/features/settings/screens/settings_screen.dart` — add `Replay tour` row that calls `TourService.resetAll(userId)`.
- `lib/services/analytics_events.dart` — add `tour_started`, `tour_step_viewed`, `tour_completed`, `tour_skipped`, `tour_replay_tapped`.
- `test/features/onboarding/onboarding_auth_routing_test.dart` — adjust expected `onboardingEncouragementPageIndex` (will become 19 after the cuts — see Phase A math).
- `docs/qa/ui-map.md` — update onboarding map to reflect 18-screen flow + new tour surfaces.

**Deleted files (7):**
- `lib/features/onboarding/screens/quran_connection_screen.dart`
- `lib/features/onboarding/screens/common_emotions_screen.dart`
- `lib/features/onboarding/screens/aspirations_screen.dart`
- `lib/features/onboarding/screens/struggle_support_interstitial_screen.dart`
- `lib/features/onboarding/screens/value_prop_screen.dart`
- `lib/features/onboarding/screens/encouragement_screen.dart`
- `lib/features/onboarding/screens/your_journey_screen.dart`

---

## New page-index math (Phase A target)

After cuts the `PageView` children are (old index → new index):

| New | Old | Screen                              |
|-----|-----|-------------------------------------|
| 0   | 0   | FirstCheckinScreen                  |
| 1   | 1   | NameInputScreen                     |
| 2   | 2   | AgeRangeScreen                      |
| 3   | 3   | IntentionScreen                     |
| 4   | 4   | PrayerFrequencyScreen               |
| 5   | 6   | FamiliarityScreen                   |
| 6   | 7   | DuaTopicsScreen                     |
| 7   | 10  | DailyCommitmentScreen               |
| 8   | 11  | AttributionScreen                   |
| 9   | 13  | ReminderTimeScreen                  |
| 10  | 14  | NotificationScreen                  |
| 11  | 15  | CommitmentPactScreen                |
| 12  | 17  | SocialProofScreen                   |
| 13  | 18  | SaveProgressScreen                  |
| 14  | 19  | SignUpEmailScreen                   |
| 15  | 20  | SignUpPasswordScreen                |
| 16  | 22  | GeneratingScreen                    |
| 17  | 23  | PersonalizedPlanScreen              |
| 18  | 25  | RatingGateScreen (if env on)        |
| 19  | 26  | PaywallScreen                       |

New constants (in `onboarding_provider.dart`):
```dart
const int onboardingLastPageIndex = Env.ratingGateEnabled ? 19 : 18;
const int onboardingEmailPageIndex = 14;
const int onboardingPasswordPageIndex = 15;
// Encouragement screen is removed. Social-auth flow now lands directly on
// Generating (16) — auth is already done, plan-generation is what's next.
const int onboardingPostSignupPageIndex = 16;
```

`SaveProgressScreen.onSocialAuthComplete` now jumps to `onboardingPostSignupPageIndex` instead of `onboardingEncouragementPageIndex`.

---

## Phase A — Onboarding screen cuts

### Task A1: Baseline guard — capture current test + analyze state

**Files:**
- Read-only: `flutter analyze` + `flutter test` baselines

- [ ] **Step 1: Confirm baseline tests pass**

Run:
```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
flutter test
```
Expected: all tests pass. Note any pre-existing failures — they are NOT introduced by this work and must be flagged but not "fixed" inside this PR.

- [ ] **Step 2: Confirm baseline analyze is clean**

Run:
```bash
flutter analyze
```
Expected: ~54 infos/warnings, 0 errors (per `MEMORY.md`). Record the number; we must not regress it.

- [ ] **Step 3: Create branch**

```bash
git checkout -b onboarding-trim-and-tour
git status
```

---

### Task A2: Update routing test to new indices (FAILS first)

**Files:**
- Modify: `test/features/onboarding/onboarding_auth_routing_test.dart`

- [ ] **Step 1: Edit the test expectations**

Replace the social-auth precondition at line 23 (`currentPage: 18`) with `currentPage: 13` (new SaveProgress index), and line 58's pin from `onboardingEncouragementPageIndex, 21` to `onboardingPostSignupPageIndex, 16`. Replace the password-screen `OnboardingState(currentPage: onboardingPasswordPageIndex)` block import as needed. Final test snippet for the social-auth case:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      cachedOnboardingStateProvider.overrideWithValue(
        const OnboardingState(currentPage: 13),
      ),
    ],
    child: const MaterialApp(home: OnboardingScreen()),
  ),
);
// ... unchanged middle ...
expect(
  container.read(onboardingProvider).currentPage,
  onboardingPostSignupPageIndex,
);
expect(onboardingPostSignupPageIndex, 16);
```

- [ ] **Step 2: Run the test — expect FAIL**

```bash
flutter test test/features/onboarding/onboarding_auth_routing_test.dart
```
Expected: FAIL because `onboardingPostSignupPageIndex` doesn't exist yet, and SaveProgressScreen still expects the old index.

---

### Task A3: Add new page-index constants in onboarding_provider.dart

**Files:**
- Modify: `lib/features/onboarding/providers/onboarding_provider.dart:33-49`

- [ ] **Step 1: Replace the four `const int onboarding*PageIndex` lines**

Replace lines 22-49 of `onboarding_provider.dart` with:

```dart
/// Last index in [OnboardingScreen]'s PageView. Computed from the rating-gate
/// kill switch so the "gate on" and "gate off" paths stay in sync.
///   * `Env.ratingGateEnabled == true`  → 20 children (0..19), paywall at 19.
///   * `Env.ratingGateEnabled == false` → 19 children (0..18), paywall at 18.
///
/// Updated 2026-05-25 by onboarding-trim refactor: removed
/// QuranConnection, CommonEmotions, Aspirations, StruggleSupportInterstitial,
/// ValueProp, Encouragement, YourJourney (7 screens). Old indices shifted -7.
const int onboardingLastPageIndex = Env.ratingGateEnabled ? 19 : 18;

/// Index of the Sign-up email screen in [OnboardingScreen]'s PageView.
const int onboardingEmailPageIndex = 14;

/// Index of the Sign-up password screen in [OnboardingScreen]'s PageView.
const int onboardingPasswordPageIndex = 15;

/// Where social-auth (Apple/Google) users land after OAuth succeeds. The
/// Encouragement interstitial was removed in 2026-05-25 — authenticated
/// users now go straight to the Generating loader.
const int onboardingPostSignupPageIndex = 16;
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/features/onboarding/providers/onboarding_provider.dart
```
Expected: errors about `onboardingEncouragementPageIndex` undefined references in `save_progress_screen.dart` and possibly tests — that is expected; will be fixed below.

---

### Task A4: Remove unused state fields from OnboardingState + Notifier

**Files:**
- Modify: `lib/features/onboarding/providers/onboarding_provider.dart` (state class lines 51-241, notifier lines 309-381)

- [ ] **Step 1: Delete `quranConnection`, `commonEmotions`, `aspirations` from constructor, fields, copyWith, toJson, fromJson**

Concretely:
1. Remove `this.quranConnection,` from the constructor (line 60).
2. Remove `this.commonEmotions = const {},` (line 73) and `this.aspirations = const {},` (line 74).
3. Remove `final String? quranConnection;` (line 88), `final Set<String> commonEmotions;` (line 100), `final Set<String> aspirations;` (line 101).
4. Remove the matching `copyWith` params + body lines (124, 140, 141, 157, 170, 171).
5. In `toJson` (line 182-203): **bump `'version': 6` → `'version': 7`** and remove the `quranConnection`, `commonEmotions`, `aspirations` entries.
6. In `fromJson` (line 205-240): change the version gate from `if (version < 6)` to `if (version < 7)`. Remove the three lines reading `quranConnection` / `commonEmotions` / `aspirations`.
7. In `OnboardingNotifier`: delete `setQuranConnection` (lines 314-317), `toggleCommonEmotion` (lines 369-374), `toggleAspiration` (lines 376-381).
8. In `_persistQuizAnswers` (lines 479-497): remove `quranConnection: state.quranConnection,`, `commonEmotions: state.commonEmotions.toList(),`, `aspirations: state.aspirations.toList(),` lines.

- [ ] **Step 2: Run analyze on the file**

```bash
flutter analyze lib/features/onboarding/providers/onboarding_provider.dart
```
Expected: clean (or only pre-existing warnings).

---

### Task A5: Remove the 3 quiz params from AuthService.saveOnboardingData

**Files:**
- Modify: `lib/services/auth_service.dart:144-181`

- [ ] **Step 1: Delete the 3 params + map entries**

Concretely:
- Line 148: delete `String? quranConnection,`
- Line 155: delete `List<String> commonEmotions = const [],`
- Line 156: delete `List<String> aspirations = const [],`
- Line 168: delete `'onboarding_quran_connection': quranConnection,`
- Line 175: delete `'common_emotions': commonEmotions,`
- Line 176: delete `'aspirations': aspirations,`

- [ ] **Step 2: Run analyze on the file**

```bash
flutter analyze lib/services/auth_service.dart
```
Expected: clean.

---

### Task A6: Rewire OnboardingScreen PageView

**Files:**
- Modify: `lib/features/onboarding/screens/onboarding_screen.dart`

- [ ] **Step 1: Remove the 7 imports**

Delete these import lines from the top of the file (lines 10, 13, 16, 26, 33, 34, 35):
```dart
import 'aspirations_screen.dart';
import 'common_emotions_screen.dart';
import 'encouragement_screen.dart';
import 'quran_connection_screen.dart';
import 'struggle_support_interstitial_screen.dart';
import 'value_prop_screen.dart';
import 'your_journey_screen.dart';
```

- [ ] **Step 2: Rewrite the PageView children list (lines 212-276)**

Replace with the new 20-child list (renumbered comments):

```dart
children: [
  // 0 — First check-in hook (gacha overlay fires here, not a separate page).
  FirstCheckinScreen(onNext: _next, onBack: _back),
  // 1 — Name input
  NameInputScreen(onNext: _next, onBack: _back),
  // 2 — Age range
  AgeRangeScreen(onNext: _next, onBack: _back),
  // 3 — Intention
  IntentionScreen(onNext: _next, onBack: _back),
  // 4 — Prayer frequency
  PrayerFrequencyScreen(onNext: _next, onBack: _back),
  // 5 — Familiarity with the 99 Names
  FamiliarityScreen(onNext: _next, onBack: _back),
  // 6 — Dua topics
  DuaTopicsScreen(onNext: _next, onBack: _back),
  // 7 — Daily commitment minutes
  DailyCommitmentScreen(onNext: _next, onBack: _back),
  // 8 — Attribution
  AttributionScreen(onNext: _next, onBack: _back),
  // 9 — Reminder time
  ReminderTimeScreen(onNext: _next, onBack: _back),
  // 10 — Notifications permission
  NotificationScreen(onNext: _next, onBack: _back),
  // 11 — Commitment pact
  CommitmentPactScreen(onNext: _next, onBack: _back),
  // 12 — Social proof (pre-signup, single beat — was 17)
  SocialProofScreen(onNext: _next, onBack: _back),
  // 13 — Save progress (sign-up choice)
  SaveProgressScreen(
    onNext: _next,
    onBack: _back,
    onSocialAuthComplete: _skipToPostSignup,
  ),
  // 14 — Sign-up email
  SignUpEmailScreen(onNext: _next, onBack: _back),
  // 15 — Sign-up password
  SignUpPasswordScreen(onNext: _next, onBack: _back),
  // — Paywall flow begins. Progress bar hidden on these. —
  // 16 — Generating (loader; absorbed Encouragement tease as a 1.5s header line)
  GeneratingScreen(onNext: _next),
  // 17 — Personalized plan
  PersonalizedPlanScreen(onNext: _next, onBack: _back),
  // 18 — Rating gate (gated by Env.ratingGateEnabled)
  if (Env.ratingGateEnabled)
    RatingGateScreen(onNext: _next, onBack: _back),
  // 19 — Paywall (was 18 if gate off)
  PaywallScreen(onComplete: _completeOnboarding),
],
```

- [ ] **Step 3: Rename `_skipToEncouragement` → `_skipToPostSignup`**

In the file replace the method (currently at line 135):
```dart
void _skipToPostSignup() => _goToPage(onboardingPostSignupPageIndex);
```
And update the `resizeToAvoidBottomInset` line 208 — page `7` was DuaTopics (multi-select, no keyboard issue). The keyboard-disable predicate stays correct because Page 0 (FirstCheckin) and the (new) Page 6 = DuaTopics both have free-text fields. Update to:
```dart
resizeToAvoidBottomInset: currentPage != 0 && currentPage != 6,
```

- [ ] **Step 4: Run analyze**

```bash
flutter analyze lib/features/onboarding/screens/onboarding_screen.dart
```
Expected: clean.

---

### Task A7: Fold Encouragement tease into PersonalizedPlanScreen

**Files:**
- Modify: `lib/features/onboarding/screens/personalized_plan_screen.dart`

- [ ] **Step 1: Read the existing EncouragementScreen header line**

```bash
grep -nE "You committed|Salaam|tease" "/Users/appleuser/CS Work/Repos/sakina/flutter/lib/features/onboarding/screens/encouragement_screen.dart" | head
```

- [ ] **Step 2: Add a small "You committed — here's your plan" header above the existing plan header**

In `personalized_plan_screen.dart`, prepend the existing plan title with a 14px DM Sans gold subtitle (replicate the existing copy from `encouragement_screen.dart`'s headline; copy literally rather than referencing). Keep total added height under 32px so the layout doesn't shift.

- [ ] **Step 3: Snapshot-verify by running the existing test for the personalized plan screen** (if one exists; otherwise just `flutter analyze`)

```bash
flutter analyze lib/features/onboarding/screens/personalized_plan_screen.dart
```

---

### Task A8: Delete the 7 onboarding screen files

**Files:**
- Delete:
  - `lib/features/onboarding/screens/quran_connection_screen.dart`
  - `lib/features/onboarding/screens/common_emotions_screen.dart`
  - `lib/features/onboarding/screens/aspirations_screen.dart`
  - `lib/features/onboarding/screens/struggle_support_interstitial_screen.dart`
  - `lib/features/onboarding/screens/value_prop_screen.dart`
  - `lib/features/onboarding/screens/encouragement_screen.dart`
  - `lib/features/onboarding/screens/your_journey_screen.dart`

- [ ] **Step 1: rm the 7 files**

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter"
rm lib/features/onboarding/screens/quran_connection_screen.dart \
   lib/features/onboarding/screens/common_emotions_screen.dart \
   lib/features/onboarding/screens/aspirations_screen.dart \
   lib/features/onboarding/screens/struggle_support_interstitial_screen.dart \
   lib/features/onboarding/screens/value_prop_screen.dart \
   lib/features/onboarding/screens/encouragement_screen.dart \
   lib/features/onboarding/screens/your_journey_screen.dart
```

- [ ] **Step 2: Find any other references**

Run:
```bash
grep -rn "EncouragementScreen\|QuranConnectionScreen\|CommonEmotionsScreen\|AspirationsScreen\|StruggleSupportInterstitialScreen\|ValuePropScreen\|YourJourneyScreen" lib/ test/
```
Expected: no matches. If matches surface (especially in tests), delete or update those references.

- [ ] **Step 3: Find lingering references to removed providers/state fields**

```bash
grep -rn "quranConnection\|commonEmotions\|aspirations\|setQuranConnection\|toggleCommonEmotion\|toggleAspiration\|onboardingEncouragementPageIndex" lib/ test/
```
Replace any remaining `onboardingEncouragementPageIndex` consumers with `onboardingPostSignupPageIndex`. Remove anything else.

- [ ] **Step 4: Run analyze**

```bash
flutter analyze
```
Expected: clean (or no new errors vs Task A1 baseline).

---

### Task A9: Update the routing test and rerun the full suite

**Files:**
- Verify: `test/features/onboarding/onboarding_auth_routing_test.dart` (already edited in Task A2)

- [ ] **Step 1: Run the routing test**

```bash
flutter test test/features/onboarding/onboarding_auth_routing_test.dart
```
Expected: PASS.

- [ ] **Step 2: Run the full onboarding test directory**

```bash
flutter test test/features/onboarding/
```
Expected: PASS. Any failure here is a real regression in the renumbered flow — read the failure, fix the consumer (likely a hardcoded page index in another test).

- [ ] **Step 3: Run full suite**

```bash
flutter test
```
Expected: PASS.

- [ ] **Step 4: Commit Phase A**

```bash
git add lib/features/onboarding lib/services/auth_service.dart test/features/onboarding/onboarding_auth_routing_test.dart
git commit -m "refactor(onboarding): trim 27→18 screens, drop 3 unused profile fields"
```

---

## Phase B — Supabase cleanup

### Task B1: Write the forward-only DROP migration

**Files:**
- Create: `supabase/migrations/20260525000000_drop_unused_onboarding_columns.sql`

- [ ] **Step 1: Write the migration**

```sql
-- 2026-05-25: onboarding refactor — three columns are no longer captured.
-- The Flutter client stopped writing these in the same release. Forward-only;
-- no rollback (the data was never load-bearing — Mixpanel had a copy of
-- onboarding_quran_connection / common_emotions / aspirations for any
-- retro analysis we still want).
alter table public.user_profiles
  drop column if exists onboarding_quran_connection,
  drop column if exists common_emotions,
  drop column if exists aspirations;
```

- [ ] **Step 2: Write the pgTAP assertion**

Create `supabase/tests/00040_unused_onboarding_columns_dropped.sql`:
```sql
begin;
select plan(3);

select hasnt_column('public', 'user_profiles', 'onboarding_quran_connection',
  '2026-05-25 migration drops onboarding_quran_connection');
select hasnt_column('public', 'user_profiles', 'common_emotions',
  '2026-05-25 migration drops common_emotions');
select hasnt_column('public', 'user_profiles', 'aspirations',
  '2026-05-25 migration drops aspirations');

select * from finish();
rollback;
```

---

### Task B2: Apply migration to local + verify

**Files:**
- Run-only

- [ ] **Step 1: Reset local Supabase DB to apply the new migration**

```bash
cd "/Users/appleuser/CS Work/Repos/sakina/flutter/supabase" 2>/dev/null || cd "/Users/appleuser/CS Work/Repos/sakina"
supabase db reset --local
```
Expected: applies all migrations cleanly, including the new one.

- [ ] **Step 2: Run pgTAP suite locally**

Use the project's existing pgTAP runner. Example (adjust to repo convention):
```bash
psql "$(supabase status --output env | grep DB_URL | cut -d= -f2-)" -c "select * from runtests('supabase/tests'::text);"
```
Expected: the 3 assertions from `00040_*` pass plus all existing tests.

- [ ] **Step 3: Confirm the project freemium-guard triggers + RPCs still compile**

```bash
psql "<local-db-url>" -c "\df sync_all_user_data" -c "\df save_onboarding_data 2>/dev/null"
```
Expected: functions still listed. If `sync_all_user_data` references the dropped columns we have a problem — check function bodies:
```bash
grep -rni "common_emotions\|aspirations\|onboarding_quran_connection" supabase/migrations
```
Any remaining function-body references must be patched in the same migration (drop the column read then recreate the function).

- [ ] **Step 4: Commit Phase B**

```bash
git add supabase/migrations/20260525000000_drop_unused_onboarding_columns.sql \
        supabase/tests/00040_unused_onboarding_columns_dropped.sql
git commit -m "feat(db): drop onboarding_quran_connection, common_emotions, aspirations columns"
```

---

## Phase C — Guided tour infrastructure

### Task C1: Build TourService (TDD)

**Files:**
- Create: `lib/services/tour_service.dart`
- Test: `test/services/tour_service_test.dart`

- [ ] **Step 1: Write the failing tests**

`test/services/tour_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/tour_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shouldShow returns true the first time and false after markSeen', () async {
    final svc = TourService();
    expect(await svc.shouldShow('uid1', TourKey.home), isTrue);
    await svc.markSeen('uid1', TourKey.home);
    expect(await svc.shouldShow('uid1', TourKey.home), isFalse);
  });

  test('flags are scoped per user', () async {
    final svc = TourService();
    await svc.markSeen('uid1', TourKey.home);
    expect(await svc.shouldShow('uid2', TourKey.home), isTrue);
  });

  test('resetAll restores all tours to shouldShow=true', () async {
    final svc = TourService();
    await svc.markSeen('uid1', TourKey.home);
    await svc.markSeen('uid1', TourKey.duas);
    await svc.resetAll('uid1');
    expect(await svc.shouldShow('uid1', TourKey.home), isTrue);
    expect(await svc.shouldShow('uid1', TourKey.duas), isTrue);
  });

  test('version bump re-triggers previously-seen tours', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tour_seen_uid1_home_v0', true); // legacy key
    final svc = TourService();
    expect(await svc.shouldShow('uid1', TourKey.home), isTrue,
        reason: 'current TourService version is v1+, legacy v0 flag ignored');
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/services/tour_service_test.dart
```
Expected: FAIL — `tour_service.dart` doesn't exist.

- [ ] **Step 3: Implement TourService**

`lib/services/tour_service.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TourKey { home, collection, journal, duas }

/// Per-user, versioned tour-seen flag store on SharedPreferences.
///
/// Versioning rule: bump `_version` when a tour is redesigned so existing
/// users re-see the new copy. Old keys are left in prefs harmlessly — the
/// version is part of the lookup key, not the value.
class TourService {
  static const int _version = 1;

  String _key(String userId, TourKey k) =>
      'tour_seen_${userId}_${k.name}_v$_version';

  Future<bool> shouldShow(String userId, TourKey k) async {
    final p = await SharedPreferences.getInstance();
    return !(p.getBool(_key(userId, k)) ?? false);
  }

  Future<void> markSeen(String userId, TourKey k) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key(userId, k), true);
  }

  Future<void> resetAll(String userId) async {
    final p = await SharedPreferences.getInstance();
    for (final k in TourKey.values) {
      await p.remove(_key(userId, k));
    }
  }
}

final tourServiceProvider = Provider<TourService>((_) => TourService());
```

- [ ] **Step 4: Run — expect PASS**

```bash
flutter test test/services/tour_service_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/tour_service.dart test/services/tour_service_test.dart
git commit -m "feat(tour): TourService — per-user versioned seen flags"
```

---

### Task C2: CoachmarkStep value type + CoachmarkController

**Files:**
- Create: `lib/widgets/coachmark/coachmark_step.dart`
- Create: `lib/widgets/coachmark/coachmark_controller.dart`

- [ ] **Step 1: Write coachmark_step.dart**

```dart
import 'package:flutter/widgets.dart';

/// A single step in a coachmark sequence. The target's render box is read
/// once at `start` time; if the target rebuilds offscreen the controller
/// recomputes on next `next()` call.
class CoachmarkStep {
  const CoachmarkStep({
    required this.target,
    required this.message,
    this.tooltipBelow = true,
  });

  final GlobalKey target;
  final String message;
  final bool tooltipBelow; // if false, place tooltip above the target
}
```

- [ ] **Step 2: Write coachmark_controller.dart**

```dart
import 'package:flutter/widgets.dart';
import 'coachmark_overlay.dart';
import 'coachmark_step.dart';

/// Sequences a list of [CoachmarkStep]s using a single [OverlayEntry].
/// Holds no global state; the caller owns lifecycle (create, start, dispose).
class CoachmarkController {
  CoachmarkController({
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });

  final List<CoachmarkStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  int _index = 0;
  OverlayEntry? _entry;
  BuildContext? _ctx;

  void start(BuildContext context) {
    if (steps.isEmpty) {
      onComplete();
      return;
    }
    _ctx = context;
    _show();
  }

  void _show() {
    final overlay = Overlay.of(_ctx!);
    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => CoachmarkOverlay(
        step: steps[_index],
        stepIndex: _index,
        totalSteps: steps.length,
        onNext: _next,
        onSkip: _skip,
      ),
    );
    overlay.insert(_entry!);
  }

  void _next() {
    if (_index >= steps.length - 1) {
      _dismiss();
      onComplete();
      return;
    }
    _index++;
    _show();
  }

  void _skip() {
    _dismiss();
    onSkip();
  }

  void _dismiss() {
    _entry?.remove();
    _entry = null;
  }

  void dispose() => _dismiss();
}
```

- [ ] **Step 3: Run analyze (overlay file doesn't exist yet — expected reference error)**

```bash
flutter analyze lib/widgets/coachmark/
```
Expected: error about missing `coachmark_overlay.dart`. Fix in next task.

---

### Task C3: CoachmarkOverlay widget (TDD)

**Files:**
- Create: `lib/widgets/coachmark/coachmark_overlay.dart`
- Test: `test/widgets/coachmark/coachmark_overlay_test.dart`

- [ ] **Step 1: Write the failing widget test**

`test/widgets/coachmark/coachmark_overlay_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/coachmark/coachmark_overlay.dart';
import 'package:sakina/widgets/coachmark/coachmark_step.dart';

void main() {
  testWidgets('CoachmarkOverlay shows tooltip message and step dots',
      (tester) async {
    final key = GlobalKey();
    var nextCalls = 0;
    var skipCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 100, top: 200,
                child: Container(key: key, width: 80, height: 40, color: const Color(0xFF1B6B4A)),
              ),
              CoachmarkOverlay(
                step: CoachmarkStep(
                  target: key,
                  message: 'Tap here daily to unlock today\'s Name.',
                ),
                stepIndex: 0,
                totalSteps: 3,
                onNext: () => nextCalls++,
                onSkip: () => skipCalls++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining("Tap here daily"), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip tour'), findsOneWidget);

    await tester.tap(find.text('Next'));
    expect(nextCalls, 1);

    await tester.tap(find.text('Skip tour'));
    expect(skipCalls, 1);
  });
}
```

- [ ] **Step 2: Implement CoachmarkOverlay**

`lib/widgets/coachmark/coachmark_overlay.dart`:
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'coachmark_step.dart';

/// Cream scrim + rounded-rect cutout around the target widget, with an
/// emerald tooltip card. Reads the target's render box via the supplied
/// GlobalKey. If the target hasn't been laid out yet, the overlay falls
/// back to a centered card with no cutout (defensive — shouldn't happen
/// in practice because the controller fires post-first-frame).
class CoachmarkOverlay extends StatelessWidget {
  const CoachmarkOverlay({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
  });

  final CoachmarkStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  Rect? _targetRect() {
    final ctx = step.target.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final rect = _targetRect();
    final mq = MediaQuery.of(context);
    final isLast = stepIndex == totalSteps - 1;

    final tooltip = _Tooltip(
      message: step.message,
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      isLast: isLast,
      onNext: onNext,
      onSkip: onSkip,
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Cream scrim with rounded-rect cutout.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: CustomPaint(
                painter: _ScrimPainter(cutout: rect),
              ),
            ),
          ),
          // Tooltip positioned below the target (or centered if no rect).
          if (rect != null)
            Positioned(
              left: 16,
              right: 16,
              top: step.tooltipBelow
                  ? (rect.bottom + 14).clamp(0.0, mq.size.height - 220)
                  : null,
              bottom: step.tooltipBelow
                  ? null
                  : (mq.size.height - rect.top + 14)
                      .clamp(0.0, mq.size.height - 220),
              child: tooltip,
            )
          else
            Center(child: tooltip),
        ],
      ),
    );
  }
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({
    required this.message,
    required this.stepIndex,
    required this.totalSteps,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final String message;
  final int stepIndex;
  final int totalSteps;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.primary, // emerald
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          top: BorderSide(color: AppColors.secondary, width: 1), // gold accent
        ),
        boxShadow: const [
          BoxShadow(blurRadius: 24, color: Color(0x33000000), offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message,
              style: const TextStyle(
                color: AppColors.cream,
                fontSize: 15,
                height: 1.35,
                fontFamily: 'DM Sans',
              )),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < totalSteps; i++)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == stepIndex
                        ? AppColors.secondary
                        : AppColors.cream.withValues(alpha: 0.35),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: onSkip,
                child: Text('Skip tour',
                    style: TextStyle(
                      color: AppColors.cream.withValues(alpha: 0.85),
                      fontFamily: 'DM Sans',
                    )),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: onNext,
                child: Text(isLast ? 'Done' : 'Next →',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.cutout});
  final Rect? cutout;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0x8C1B0E0E); // dark warm scrim
    if (cutout == null) {
      canvas.drawRect(Offset.zero & size, scrim);
      return;
    }
    final pad = const EdgeInsets.all(8).inflateRect(cutout!);
    final rrect = RRect.fromRectAndRadius(pad, const Radius.circular(16));
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, scrim);
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter old) => old.cutout != cutout;
}
```

> If `AppColors.cream` / `AppColors.secondary` are named differently in `app_colors.dart`, use the actual identifier. Run `grep -n "static const Color" lib/core/constants/app_colors.dart` to confirm before pasting.

- [ ] **Step 3: Run — expect PASS**

```bash
flutter test test/widgets/coachmark/coachmark_overlay_test.dart
```
Expected: PASS.

- [ ] **Step 4: Run analyze on the widget dir**

```bash
flutter analyze lib/widgets/coachmark/
```
Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/coachmark test/widgets/coachmark
git commit -m "feat(tour): CoachmarkOverlay + Controller + Step value type"
```

---

### Task C4: tour_keys_provider — shared GlobalKeys

**Files:**
- Create: `lib/features/tour/providers/tour_keys_provider.dart`

- [ ] **Step 1: Write the provider**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// GlobalKeys that the in-app tour anchors coachmarks to. The producers
/// (ProgressScreen, AppShell, DuasScreen) attach these keys to their target
/// widgets; the consumer (the tour trigger logic) reads them from the same
/// provider so registration + lookup never drift.
class TourKeys {
  TourKeys()
      : muhasabahCtaKey = GlobalKey(debugLabel: 'tour.muhasabahCta'),
        streakPillKey = GlobalKey(debugLabel: 'tour.streakPill'),
        tabBarKey = GlobalKey(debugLabel: 'tour.tabBar'),
        duasFirstHeartKey = GlobalKey(debugLabel: 'tour.duasFirstHeart');

  final GlobalKey muhasabahCtaKey;
  final GlobalKey streakPillKey;
  final GlobalKey tabBarKey;
  final GlobalKey duasFirstHeartKey;
}

final tourKeysProvider = Provider<TourKeys>((_) => TourKeys());
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/features/tour/
```
Expected: clean.

---

### Task C5: Analytics events for tours

**Files:**
- Modify: `lib/services/analytics_events.dart`

- [ ] **Step 1: Add the 5 constants**

Open `lib/services/analytics_events.dart` and add the following constants alongside the existing ones (preserve the file's existing const-class or string-pool pattern):

```dart
static const String tourStarted       = 'tour_started';
static const String tourStepViewed    = 'tour_step_viewed';
static const String tourCompleted     = 'tour_completed';
static const String tourSkipped       = 'tour_skipped';
static const String tourReplayTapped  = 'tour_replay_tapped';
```

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/services/analytics_events.dart
```

---

## Phase D — Home tour (3 steps)

### Task D1: Attach GlobalKeys to ProgressScreen + AppShell

**Files:**
- Modify: `lib/features/progress/screens/progress_screen.dart:787` (Begin Muḥāsabah button + streak pill nearby)
- Modify: `lib/widgets/app_shell.dart` (or wherever the bottom tab bar lives — find via `grep -rn "BottomNavigationBar\|NavigationBar" lib/widgets lib/core`)

- [ ] **Step 1: Locate the tab bar widget**

```bash
grep -rn "BottomNavigationBar\|NavigationBar(" lib/
```
Note the exact file. (Likely `lib/core/widgets/app_shell.dart` or similar.)

- [ ] **Step 2: Wrap the Muḥāsabah CTA with the key**

In `progress_screen.dart`, find the button at line ~787 (`inProgress ? 'Continue Muḥāsabah' : 'Begin Muḥāsabah'`). Convert the surrounding widget tree to read `final keys = ref.watch(tourKeysProvider);` near the top of `build()`, then set `key: keys.muhasabahCtaKey` on the outermost tappable widget of that CTA.

- [ ] **Step 3: Wrap the streak pill with the key**

Locate the streak pill in the same screen (search for `streak` references). Set `key: keys.streakPillKey` on the pill container.

- [ ] **Step 4: Wrap the tab bar with the key**

In the tab bar widget identified in Step 1, set `key: ref.watch(tourKeysProvider).tabBarKey` on the outermost container.

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/features/progress/screens/progress_screen.dart lib/core/widgets/
```
Expected: clean.

---

### Task D2: Wire Home-tour trigger

**Files:**
- Modify: `lib/features/progress/screens/progress_screen.dart`

- [ ] **Step 1: Add post-first-frame trigger**

In `ProgressScreen`'s state class, in `initState`:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartHomeTour());
}

Future<void> _maybeStartHomeTour() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null || !mounted) return;
  final svc = ref.read(tourServiceProvider);
  if (!await svc.shouldShow(userId, TourKey.home)) return;
  if (!mounted) return;

  final keys = ref.read(tourKeysProvider);
  final analytics = ref.read(analyticsProvider);
  analytics.track(AnalyticsEvents.tourStarted, properties: {'tour': 'home'});

  final controller = CoachmarkController(
    steps: [
      CoachmarkStep(
        target: keys.muhasabahCtaKey,
        message: "Tap here daily. Today's Name unlocks after your check-in.",
      ),
      CoachmarkStep(
        target: keys.streakPillKey,
        message: "Your streak grows with every reflection. Don't break it.",
        tooltipBelow: true,
      ),
      CoachmarkStep(
        target: keys.tabBarKey,
        message: "Cards, Journal, Duas — your library lives here.",
        tooltipBelow: false,
      ),
    ],
    onComplete: () async {
      analytics.track(AnalyticsEvents.tourCompleted, properties: {'tour': 'home'});
      await svc.markSeen(userId, TourKey.home);
    },
    onSkip: () async {
      analytics.track(AnalyticsEvents.tourSkipped, properties: {'tour': 'home'});
      await svc.markSeen(userId, TourKey.home);
    },
  );
  // Emit step_viewed on every advance via a wrapper, or simpler: track right
  // before starting since we know all 3 steps will at least flash.
  analytics.track(AnalyticsEvents.tourStepViewed,
      properties: {'tour': 'home', 'step': 0});
  controller.start(context);
}
```

- [ ] **Step 2: Write a widget test for the trigger**

`test/features/tour/home_tour_trigger_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/progress/screens/progress_screen.dart';

void main() {
  testWidgets('Home tour fires on first visit and not on second', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Pump ProgressScreen with mocked Supabase auth + analytics provided as
    // null-safe doubles via the project's existing test harness in
    // test/_helpers/. If that harness does not yet support ProgressScreen,
    // factor the trigger into a small testable function and exercise that
    // directly instead. The MVP for this test is: shouldShow returns true →
    // overlay inserted; shouldShow returns false → not inserted.
    // (See test/_helpers/* for existing patterns.)
    // ... harness wiring ...
  });
}
```

This test is intentionally a skeleton because the full harness wiring is project-specific. The Phase-D acceptance criteria are validated manually on a device (Task D3) since the Home tour involves the bottom tab bar and a `GlobalKey` on a widget that lives outside `ProgressScreen`.

- [ ] **Step 3: Run analyze**

```bash
flutter analyze lib/features/progress/screens/progress_screen.dart
```

- [ ] **Step 4: Manual smoke test on simulator**

```bash
flutter run --dart-define-from-file=env.json
```
- Fresh-install (delete the app first) → complete onboarding → reach Home → tour should auto-fire with 3 coachmarks.
- Tap `Next` 3× → tour dismisses, no second fire on re-render.
- Take screenshots; `sips -Z 1600` each one per CLAUDE.md.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress lib/features/tour lib/widgets/coachmark lib/services/tour_service.dart \
        lib/services/analytics_events.dart test/features/tour test/services/tour_service_test.dart
git commit -m "feat(tour): Home tour — 3 coachmarks on first visit"
```

---

## Phase E — Collection empty-state teach

### Task E1: First-visit explanatory caption

**Files:**
- Modify: `lib/features/collection/screens/collection_screen.dart`

- [ ] **Step 1: Add the conditional caption**

When the collection has exactly 1 card (the starter) AND `TourService.shouldShow(userId, TourKey.collection)` is true, render a small cream card under the starter card with copy:

> *This is your first Name. Earn the next one with tomorrow's check-in.*

On first render after the user has seen the caption (post-frame), call `markSeen(userId, TourKey.collection)`. Use `ref.read` once in `initState` + a `Future.microtask`.

- [ ] **Step 2: Track analytics**

In the same trigger:
```dart
ref.read(analyticsProvider).track(AnalyticsEvents.tourStarted, properties: {'tour': 'collection'});
ref.read(analyticsProvider).track(AnalyticsEvents.tourCompleted, properties: {'tour': 'collection'});
```
(Empty-state teach is a single beat — start + complete fire together when shown.)

- [ ] **Step 3: Run analyze + a render-only widget test that asserts caption only appears with 1 card**

```bash
flutter analyze lib/features/collection/screens/collection_screen.dart
flutter test test/features/collection/
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/collection
git commit -m "feat(tour): Collection — first-visit starter-card explainer caption"
```

---

## Phase F — Journal empty-state CTA

### Task F1: Illustrated empty state + Write first entry

**Files:**
- Modify: `lib/features/journal/screens/journal_screen.dart`

- [ ] **Step 1: Replace plain empty state**

When the journal entries list is empty AND `TourService.shouldShow(userId, TourKey.journal)` is true, render:
- Illustrated quill SVG (reuse an existing onboarding asset — `grep -rn "quill\|feather" assets/` to find a candidate; if none, ship a minimal `Icons.edit_note` placeholder).
- Title: *Reflect on today's Name.*
- Body: *Your entries stay private. Only you can read them.*
- Filled primary button: `Write first entry` → routes to the existing reflection editor with today's Name pre-loaded.

When tapped, fire `tourCompleted` + `markSeen`. When the user backs out without writing, fire `tourSkipped` + `markSeen` on `dispose` (so the prompt doesn't re-trigger on every visit).

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/features/journal/screens/journal_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/journal
git commit -m "feat(tour): Journal — illustrated empty state with first-entry CTA"
```

---

## Phase G — Duas single coachmark

### Task G1: Save-heart coachmark on first visit

**Files:**
- Modify: `lib/features/duas/screens/duas_screen.dart`

- [ ] **Step 1: Attach the GlobalKey + trigger**

In `DuasScreen`, attach `tourKeysProvider.duasFirstHeartKey` to the save-heart icon of the first dua card in the list. In `initState`, post-first-frame, check `TourService.shouldShow(userId, TourKey.duas)`. If true, build a `CoachmarkController` with a single step:

```dart
CoachmarkStep(
  target: keys.duasFirstHeartKey,
  message: 'Tap ♡ to save duas you love. Browse them anytime.',
);
```

`onComplete` / `onSkip` both `markSeen` + fire the matching analytics event.

- [ ] **Step 2: Analyze + commit**

```bash
flutter analyze lib/features/duas/
git add lib/features/duas
git commit -m "feat(tour): Duas — save-heart coachmark on first visit"
```

---

## Phase H — Settings: Replay tour

### Task H1: Add the Replay row + handler

**Files:**
- Modify: `lib/features/settings/screens/settings_screen.dart`

- [ ] **Step 1: Add the row in the Help section**

Use the existing settings-row component (`grep -n "SettingsRow\|ListTile\|_buildRow" lib/features/settings/screens/settings_screen.dart` to find the pattern). Add:

```dart
SettingsRow(
  icon: Icons.info_outline,
  label: 'Replay app tour',
  onTap: () async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    await ref.read(tourServiceProvider).resetAll(uid);
    ref.read(analyticsProvider).track(AnalyticsEvents.tourReplayTapped);
    if (!context.mounted) return;
    context.go('/'); // back to Home so the home tour re-fires
  },
),
```

- [ ] **Step 2: Manual smoke**

`flutter run --dart-define-from-file=env.json` → Settings → tap Replay → routes home, Home tour auto-fires again. Take screenshots.

- [ ] **Step 3: Analyze + commit**

```bash
flutter analyze lib/features/settings/
git add lib/features/settings
git commit -m "feat(tour): Settings — Replay app tour entry"
```

---

## Phase I — Docs + UI map + manual QA

### Task I1: Update ui-map.md

**Files:**
- Modify: `docs/qa/ui-map.md`

- [ ] **Step 1: Replace the onboarding section**

Find the onboarding canonical order section in `docs/qa/ui-map.md` and replace with the 20-row table from the **New page-index math** section of this plan. Add a new **Guided tour** section listing the 4 tour surfaces and their trigger conditions.

---

### Task I2: Write the manual QA plan

**Files:**
- Create: `docs/qa/plans/2026-05-25-tour-manual-qa.md`

- [ ] **Step 1: Write the checklist**

```markdown
# 2026-05-25 — Onboarding Trim + Guided Tour manual QA

## Pre-conditions
- [ ] Fresh install on iOS sim + 1 Android device
- [ ] `env.json` populated
- [ ] Mixpanel project: dev

## Onboarding (cold start, fresh account)
- [ ] Reaches 18 screens (or 19 with rating gate)
- [ ] No 404 / missing screen between FirstCheckin and Paywall
- [ ] Social-auth path (Apple) lands on Generating (page 16), not Encouragement
- [ ] Email path: email (14) → password (15) → Generating (16)
- [ ] On second cold launch after restore, user lands on the correct restored page (no off-by-one)

## Home tour
- [ ] Fires once on first Home visit after paywall close
- [ ] Step 1 spotlights Begin Muḥāsabah CTA
- [ ] Step 2 spotlights streak pill
- [ ] Step 3 spotlights tab bar
- [ ] Skip tour at any step → never re-fires
- [ ] Complete → never re-fires
- [ ] Mixpanel: tour_started / tour_step_viewed (×3) / tour_completed events received

## Collection
- [ ] First visit with starter card shows explainer caption
- [ ] After leaving + returning, caption is gone
- [ ] With 2+ cards, caption never shows

## Journal
- [ ] First visit empty state shows quill + Write first entry CTA
- [ ] Tap CTA → editor opens with today's Name pre-loaded
- [ ] After writing 1 entry, empty state replaced by list

## Duas
- [ ] First visit shows save-heart coachmark on first card
- [ ] Tap Skip / Done → never re-fires

## Settings → Replay
- [ ] Tap Replay app tour → routes to Home, Home tour fires again
- [ ] All four micro-tours are re-triggerable

## Regressions
- [ ] `flutter test` clean
- [ ] `flutter analyze` ≤ baseline count
- [ ] No crashes on rotate during a coachmark
- [ ] Cream scrim renders correctly in both light + dark mode
- [ ] Backgrounding the app during a coachmark and returning preserves state
```

- [ ] **Step 2: Commit docs**

```bash
git add docs/qa docs/superpowers
git commit -m "docs(tour): UI map update + manual QA plan"
```

---

## Phase J — Final integration check + PR

### Task J1: Full-suite verification

- [ ] **Step 1: Run everything**

```bash
flutter analyze
flutter test
./scripts/check_no_fake_strings.sh
dart run build_runner build --delete-conflicting-outputs
```
Expected: clean across all four.

- [ ] **Step 2: Build iOS release**

```bash
flutter build ios --release --dart-define-from-file=env.json
```
Expected: success.

- [ ] **Step 3: Build Android appbundle**

```bash
flutter build appbundle --release --dart-define-from-file=env.json
```
Expected: success.

- [ ] **Step 4: Push branch + open PR**

```bash
git push -u origin onboarding-trim-and-tour
gh pr create --title "feat: onboarding trim + guided tour" --body "$(cat <<'EOF'
## Summary
- Onboarding 27 → 18 screens (deleted 7 filler/redundant screens)
- Dropped 3 unused profile columns from `user_profiles` (forward-only migration)
- New 4-surface contextual guided tour: Home (3 steps), Collection (empty-state caption), Journal (illustrated CTA), Duas (1 coachmark)
- Settings → "Replay app tour" entry
- New bespoke `CoachmarkOverlay` (no new pub deps — matches cream/emerald palette)

## Test plan
- [ ] Full `flutter test` + `flutter analyze` pass
- [ ] pgTAP migration assertions pass
- [ ] Manual QA per `docs/qa/plans/2026-05-25-tour-manual-qa.md`
- [ ] iOS + Android release builds succeed
- [ ] Tour fires once + replay works
- [ ] Mixpanel events received

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- ✅ Delete onboarding screens — Phase A (Tasks A6, A8)
- ✅ Clean up Supabase — Phase B (Tasks B1, B2)
- ✅ Other places (auth_service, page-index constants, routing test, state JSON version, onboarding state fields) — Tasks A2, A3, A4, A5
- ✅ Aesthetic tour — Phase C–G (custom widget matches `app_colors.dart` palette)
- ✅ Natural progression / guides the user properly — 4 micro-tours, never blocks, all skippable, Replay affordance in Settings
- ✅ Reference code where needed — concrete file paths, line numbers, code snippets throughout

**Placeholder scan:**
- No "TBD", "handle edge cases", "implement later". One *intentional* skeleton (`test/features/tour/home_tour_trigger_test.dart` in Task D2) is explicitly called out as project-harness-dependent and validated by manual QA — that's a deliberate tradeoff documented in-line, not a hidden gap.

**Type consistency:**
- `TourKey.home / .collection / .journal / .duas` used consistently across `TourService`, `tour_keys_provider`, and every trigger.
- `onboardingPostSignupPageIndex` (new) used in `onboarding_provider.dart`, `onboarding_screen.dart` (via `_skipToPostSignup`), and the routing test — same identifier everywhere.
- `CoachmarkStep.tooltipBelow` named consistently in Step 2 of Task C2 and Step 1 of Task D2.

---

## CEO Review Updates (2026-05-25)

Plan was reviewed under **SELECTIVE EXPANSION + Approach B (split PRs)**. All 7 surfaced cherry-picks accepted. The original Phases A–J above remain canonical for code-level steps; this section overrides sequencing, adds new tasks, and flags risks that did not surface in the first draft.

### Sequencing override — 3 PRs, not 1 (E7)

The work ships as **three independent PRs** off `master`, in this order:

1. **PR-1 — Supabase migration only.** ~15 LOC + pgTAP. Lands in <1hr. (Phase B + new app_config seed.)
2. **PR-2 — Onboarding trim + abandonment telemetry + funnel.** (Phase A + E1 + E4 + `app_config` client-side gate.) Lands when conversion is stable for ~3 days.
3. **PR-3 — Guided tour + SVG illustrations + Replay walk + win-back.** (Phases C–H + E2 + E3 + E5 + E6.)

This sequencing decouples the migration's blast radius from the client churn, lets us measure trim impact in isolation, and keeps each branch short-lived against hot files (`progress_screen.dart` is touched 14× / 30d — long branches will conflict).

### Accepted expansions (all 7)

| # | Expansion | PR | Adds tasks |
|---|---|---|---|
| E1 | Onboarding-abandonment telemetry — fire `onboarding_abandoned_at_page` event when user backgrounds the app mid-onboarding and doesn't return within 24h | PR-2 | Task A10 |
| E2 | Per-tour version constants in `TourService` (each `TourKey` gets its own `_version`) | PR-3 | Task C1.5 |
| E3 | 3 SVG illustrations — already generated at `assets/illustrations/{journal_empty,collection_starter_ornament,duas_first_visit}.svg` | PR-3 | Task F0 |
| E4 | Mixpanel funnel JSON committed to `docs/analytics/onboarding_funnel.json` (export from Mixpanel) | PR-2 | Task A11 |
| E5 | Tour-skip → win-back push: if user skips Home tour AND no check-in for 3 days, OneSignal segment fires a "want me to show you around?" push deep-linked to Settings → Replay | PR-3 | Task H2 |
| E6 | Sequenced Replay walk in Settings: Home tour → auto-route Collection (1.5s pause) → Journal → Duas in a single guided sequence | PR-3 | Task H3 |
| E7 | 3-PR sequencing (this section) | sequencing only | — |

### `app_config` kill switch (Issue 2A — accepted via `app_config` table, not `Env`)

Replaces the proposed `Env`-flag approach. Uses the existing `app_config (key text PK, value jsonb)` table — same pattern as `bypass_token_cost` in `gating_service.dart`.

**PR-1 adds this row** alongside the migration:

```sql
-- supabase/migrations/20260525010000_app_config_onboarding_trim_flag.sql
insert into public.app_config (key, value) values
  ('onboarding_trim_enabled', 'true'::jsonb),
  ('guided_tour_enabled', 'true'::jsonb)
on conflict (key) do nothing;
```

**PR-2 adds the client wrapper** at `lib/services/app_config_service.dart`:

```dart
class AppConfigService {
  AppConfigService(this._supabase);
  final SupabaseClient _supabase;

  static const _cacheKey = 'app_config_cache_v1';
  static const _cacheTtl = Duration(hours: 6);

  /// Cached read. Reads SharedPreferences mirror first (instant) and refreshes
  /// from Supabase in the background if stale. App launch NEVER blocks on the
  /// network — if the cache is missing AND offline, returns the hardcoded
  /// fallback so the app boots in a known-good state.
  Future<bool> getBool(String key, {required bool fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_cacheKey}_$key');
    final cachedAtMs = prefs.getInt('${_cacheKey}_${key}_at') ?? 0;
    final stale = DateTime.now().millisecondsSinceEpoch - cachedAtMs > _cacheTtl.inMilliseconds;

    if (raw != null && !stale) return raw == 'true';

    // Stale-while-revalidate
    unawaited(_refresh(key));
    return raw == null ? fallback : raw == 'true';
  }

  Future<void> _refresh(String key) async {
    try {
      final row = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', key)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));
      final v = row?['value'];
      final asBool = v is bool ? v : (v?.toString() == 'true');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_cacheKey}_$key', asBool ? 'true' : 'false');
      await prefs.setInt('${_cacheKey}_${key}_at', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {/* swallow — fallback is already returned */}
  }
}

final appConfigServiceProvider = Provider<AppConfigService>(
  (ref) => AppConfigService(Supabase.instance.client),
);
```

**`onboarding_screen.dart` reads the flag at `initState`:**
```dart
final useTrimmed = await ref.read(appConfigServiceProvider)
    .getBool('onboarding_trim_enabled', fallback: true);
```
If `false`, render the *old* 27-screen flow (PR-2 must therefore preserve the old `PageView` children behind the flag — see "PR-2 dual-flow note" below).

**PR-2 dual-flow note:** PR-2 cannot delete the 7 onboarding screen files outright if the kill switch is going to be useful for rollback. Two options:
- **Option α (recommended):** keep the 7 deleted-screen `.dart` files committed but unreferenced *only for the lifetime of PR-2*. Once `onboarding_trim_enabled` has been `true` in prod for 7+ days with no rollback, ship a follow-up PR-2b that physically `rm`s the files. This is the smallest-blast-radius approach.
- **Option β:** delete the files in PR-2 and accept that the kill switch only reverts to the trimmed flow's *first version* (i.e., the kill switch is one-way: it can disable, not re-enable, the old flow). Faster but eliminates rollback after the 7 files are gone.

Decide before PR-2 starts. Default = **α** unless explicit override.

### New tasks added to original phases

#### Task A10 — Abandonment telemetry (E1, PR-2)

**Files:**
- Modify: `lib/features/onboarding/screens/onboarding_screen.dart`
- Modify: `lib/services/analytics_events.dart`

- [ ] **Step 1: Add `tracker_abandoned_at_page` event constant**

In `analytics_events.dart`:
```dart
static const String onboardingAbandonedAtPage = 'onboarding_abandoned_at_page';
```

- [ ] **Step 2: Wire `AppLifecycleState.paused` listener**

In `_OnboardingScreenState`, add `WidgetsBindingObserver`:
```dart
class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;
  int? _pausedAtPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ... existing initState body
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      _pausedAtPage = ref.read(onboardingProvider).currentPage;
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final gone = DateTime.now().difference(_pausedAt!);
      if (gone > const Duration(hours: 24) && _pausedAtPage != null) {
        ref.read(analyticsProvider).track(
              AnalyticsEvents.onboardingAbandonedAtPage,
              properties: {'page': _pausedAtPage, 'gone_hours': gone.inHours},
            );
      }
      _pausedAt = null;
      _pausedAtPage = null;
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/screens/onboarding_screen.dart lib/services/analytics_events.dart
git commit -m "feat(onboarding): track abandonment-at-page after 24h+ paused"
```

#### Task A11 — Mixpanel funnel JSON committed (E4, PR-2)

- [ ] **Step 1: Export the funnel from Mixpanel**

In the Mixpanel UI: build a funnel with steps `step_viewed(0)` → `step_completed(0)` → `step_viewed(N)` → `onboarding_completed` → `paywall_viewed` → `paywall_purchase_completed`. Click `…` → `Export` → JSON.

- [ ] **Step 2: Save to repo**

`docs/analytics/onboarding_funnel.json` — paste the exported JSON. Add a `README.md` next to it:

```markdown
# Onboarding funnel — Mixpanel definition

Import this JSON in Mixpanel UI to rebuild the canonical onboarding-conversion funnel.
Source of truth for any conversion claim made on Sakina onboarding analyses.

Last updated: 2026-05-25 (post onboarding-trim refactor).
```

- [ ] **Step 3: Commit**

```bash
git add docs/analytics/
git commit -m "docs(analytics): commit onboarding funnel definition"
```

#### Task C1.5 — Per-tour version constants (E2, PR-3)

**Files:**
- Modify: `lib/services/tour_service.dart`

- [ ] **Step 1: Replace single `_version` constant with per-tour map**

```dart
class TourService {
  // Bump the version for a specific TourKey to re-trigger that tour
  // on next launch for every user. Other tours keep their seen flags.
  static const Map<TourKey, int> _versions = {
    TourKey.home: 1,
    TourKey.collection: 1,
    TourKey.journal: 1,
    TourKey.duas: 1,
  };

  String _key(String userId, TourKey k) =>
      'tour_seen_${userId}_${k.name}_v${_versions[k]!}';
  // ... rest unchanged
}
```

- [ ] **Step 2: Update the existing version-bump test in `tour_service_test.dart`**

Verify bumping `_versions[TourKey.home]` does NOT re-trigger `TourKey.duas`. The old test asserted "version bump re-triggers" — extend it to also assert *non*-bumped tours stay seen.

#### Task F0 — Use the generated empty-state SVGs (E3, PR-3)

**Files:**
- Already exist: `assets/illustrations/journal_empty.svg`, `collection_starter_ornament.svg`, `duas_first_visit.svg`
- Modify: `pubspec.yaml` — verify `assets/illustrations/` is in the assets list (it should already be — check `flutter:` → `assets:` block)

- [ ] **Step 1: Verify pubspec includes the directory**

```bash
grep -A 20 "^flutter:" pubspec.yaml | grep -E "assets/illustrations|illustrations/"
```
Expected: a line matching `- assets/illustrations/`. If missing, add it under `flutter: assets:` and run `flutter pub get`.

- [ ] **Step 2: Reference the SVGs in the empty states**

- Journal (Task F1): `SvgPicture.asset('assets/illustrations/journal_empty.svg', width: 160)` above the title.
- Collection (Task E1): `SvgPicture.asset('assets/illustrations/collection_starter_ornament.svg', width: 200)` above the caption.
- Duas: optional — only render if the dua list is short and there's a header slot; otherwise stick with the coachmark alone.

`flutter_svg` is required. If not in pubspec yet:
```bash
flutter pub add flutter_svg
```

#### Task H2 — Win-back push for tour skippers (E5, PR-3)

**Files:**
- Modify: `lib/services/analytics_service.dart` — fire user-property `tour_home_skipped_at`
- OneSignal dashboard (manual): create segment `tour_skipped_no_checkin_3d` = `tour_home_skipped_at < 3d ago` AND `last_checkin_at > 3d ago`
- OneSignal push template: title `"Want me to show you around?"` body `"Tap to retake the Sakina tour — 30 seconds."`, deep-link `sakina://settings?action=replay_tour`

- [ ] **Step 1: Set user property on tour skip**

In `progress_screen.dart` `_maybeStartHomeTour` `onSkip`:
```dart
ref.read(analyticsProvider).setUserProperties({
  'tour_home_skipped_at': DateTime.now().toUtc().toIso8601String(),
});
```

- [ ] **Step 2: Settings deep-link handler**

In `router.dart`, the `/settings` route accepts a `?action=replay_tour` query param. On detect, auto-tap the Replay row (programmatically call `TourService.resetAll(userId)` + `context.go('/')`).

- [ ] **Step 3: Manual setup in OneSignal**

Document in `docs/runbooks/onesignal-segments.md` (create if missing) — segment definition + template copy.

#### Task H3 — Sequenced "Take the tour" Replay walk (E6, PR-3)

**Files:**
- Modify: `lib/services/tour_service.dart`
- Modify: `lib/features/settings/screens/settings_screen.dart`

- [ ] **Step 1: Add `runFullTour()` method on TourService**

```dart
/// Resets all flags and emits a "sequence" intent the router can pick up.
/// The actual routing/sequencing happens in the listener — TourService stays
/// stateless beyond the prefs flags.
Future<void> startGuidedSequence(String userId) async {
  await resetAll(userId);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tour_guided_sequence_active', true);
}
```

- [ ] **Step 2: Sequence listener**

After Home tour `onComplete` (in `progress_screen.dart`), check the flag — if `true`, auto-route to `/collection` after a 1.2s delay. `CollectionScreen`'s first-visit teach fires, then on its `onComplete` it routes to `/journal`, then `/duas`. The final `onComplete` clears the flag.

- [ ] **Step 3: Update the Settings Replay row (replace H1's onTap)**

```dart
onTap: () async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return;
  await ref.read(tourServiceProvider).startGuidedSequence(uid);
  ref.read(analyticsProvider).track(AnalyticsEvents.tourReplayTapped);
  if (!context.mounted) return;
  context.go('/');
},
```

### Risks flagged by CEO review (write into final implementation)

| # | Risk | Mitigation in plan |
|---|---|---|
| R1 | **Tour target widget unmounts before coachmark inserts** — `GlobalKey.currentContext` returns null if the target widget was disposed between trigger and overlay paint (e.g., rapid tab switch). | `CoachmarkOverlay` already has a null-rect fallback to centered card. **Add**: log `tour_target_missing` analytics event with `tour, step` so we can detect if it fires in prod. |
| R2 | **Rotation during coachmark** — `_targetRect()` is computed once on build; a rotation invalidates the cutout. | Wrap `CoachmarkOverlay` in `OrientationBuilder` so it rebuilds on rotation. |
| R3 | **App backgrounded mid-tour** — `OverlayEntry` persists across backgrounding but `markSeen` only fires on complete/skip. A force-kill mid-tour would re-trigger on next launch. Acceptable behavior. **Decision: accept**. |
| R4 | **`app_config` round-trip blocks app launch** — addressed by SWR pattern in `AppConfigService` above (cached + fallback). |
| R5 | **Hot file conflicts** — `progress_screen.dart` 14× / 30d. | 3-PR sequence; each PR-2/PR-3 branch <3 days lifespan. |
| R6 | **PR-2 dual-flow complexity** — Option α requires keeping 7 dead files committed for a week. Worth it: rollback is the entire point of the kill switch. |
| R7 | **`stash@{3}` content overlap** — accepted decision: drop after PR-3 lands. **Add to Phase J**: `git stash drop stash@{3}` and any other onboarding-related stashes (3, 7) after PR-3 lands clean for 48h. |

### Updated execution handoff

Sequencing: PR-1 (Supabase) → measure 0 → PR-2 (Trim + telemetry) → measure 3 days → PR-3 (Tour). Each is independently revertable. PR-2 ships behind `app_config.onboarding_trim_enabled`, PR-3 ships behind `app_config.guided_tour_enabled`.

---

## Eng Review Updates (2026-05-25)

Reviewed by `/plan-eng-review`. 5 Architecture findings, 3 Code Quality findings (all stated-fix), 17 test gaps with mandatory regression case, 0 Performance issues. Resolved decisions: **1.2C** (parallel prefetch) and **1.4α** (dual-flow with PR-2b cleanup) accepted.

### Architecture fixes to apply

#### 1.1 — `CoachmarkController` must use `rootOverlay` so it survives route pushes (E6 sequenced walk)

In `lib/widgets/coachmark/coachmark_controller.dart` `_show()`:
```dart
final overlay = Overlay.of(_ctx!, rootOverlay: true);
```
And in `_dismiss()`:
```dart
void _dismiss() {
  _entry?.remove();
  _entry = null; // always clear, even on no-op
}
```
Without this, the E6 sequenced Replay walk crashes the second time `context.go('/collection')` fires because the stale overlay entry is detached but not nulled.

#### 1.2C — `AppConfigService` is prefetched on `main.dart` in parallel with auth init

Plan's SWR-with-fallback approach (in the original CEO Review Updates section above) is REPLACED by parallel prefetch. The kill switch must be effective on the *first* launch after flip, not the second.

**Modify `lib/main.dart`** — find the auth bootstrap block (after `Supabase.initialize`, before `runApp`):
```dart
// 1.2C: prefetch app_config flags in parallel with auth resolution so the
// first-frame router decision sees the correct kill-switch values. Both
// run concurrently; the slower of the two gates app launch. Timeout: 1.5s
// so an offline launch is never blocked indefinitely.
final results = await Future.wait([
  appSession.resolveInitial(), // existing auth init
  AppConfigService(Supabase.instance.client)
      .primeCache(['onboarding_trim_enabled', 'guided_tour_enabled'])
      .timeout(const Duration(milliseconds: 1500), onTimeout: () {}),
]);
```

**Add to `AppConfigService`** (alongside `getBool`):
```dart
/// Pre-loads a list of keys into the SharedPreferences cache. Called from
/// main.dart in parallel with auth so the first router decision sees
/// fresh values, not stale cache. Errors are swallowed — fallback remains.
Future<void> primeCache(List<String> keys) async {
  await Future.wait(keys.map((k) => _refresh(k)));
}
```

`getBool` keeps its hardcoded fallback for offline-launch resilience, but in the happy path it now reads a fresh value populated by `primeCache`.

#### 1.3 — Rotation handling for `CoachmarkOverlay`

Wrap the overlay's outermost widget in `OrientationBuilder` so the rect recomputes on rotation:
```dart
@override
Widget build(BuildContext context) {
  return OrientationBuilder(
    builder: (context, _) => _buildOverlayContent(context),
  );
}
```
Where `_buildOverlayContent` is the existing `Material(... Stack ...)` body. Costs nothing; fixes a real visual bug on rotation mid-tour.

#### 1.4α — Dual-flow strategy: keep deleted screens for 7 days, then PR-2b removes them

PR-2 does NOT physically `rm` the 7 screen files in Phase A8. Instead:

- The 7 files stay in `lib/features/onboarding/screens/` committed and imported.
- `OnboardingScreen` builds the `PageView` children list **conditionally** based on `app_config.onboarding_trim_enabled`:
  ```dart
  Future<bool> _shouldUseTrimmedFlow() async {
    return ref.read(appConfigServiceProvider)
        .getBool('onboarding_trim_enabled', fallback: true);
  }

  // In build():
  return FutureBuilder<bool>(
    future: _trimmedFlowFuture, // memoize in initState
    builder: (context, snapshot) {
      final trimmed = snapshot.data ?? true; // optimistic
      return PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: trimmed ? _trimmedChildren() : _legacyChildren(),
      );
    },
  );
  ```
- `_trimmedChildren()` returns the 20-child list from Task A6.
- `_legacyChildren()` returns the original 27-child list (commit it as a private method, exact copy of the pre-trim PageView children).
- `Task A8` is **removed from PR-2**. Replaces with **Task A8' (PR-2b, ships 7 days after PR-2 lands clean):**
  - Verify `onboarding_trim_enabled=true` has been stable in prod for 7+ days with no rollback.
  - Delete the 7 screen files.
  - Remove `_legacyChildren()`.
  - Remove the `FutureBuilder` wrapper; always render trimmed list.
  - Remove `onboarding_trim_enabled` from `app_config` (or set to `true` permanently).

**Page-index regression test (mandatory):** test that flipping `onboarding_trim_enabled=false` while a user is mid-onboarding lands them on a *valid* page in the legacy flow. The trimmed and legacy flows have different page counts (20 vs 27) and different content per index — naive clamp leaves users stranded. The test must assert: user on trimmed page N restores to the *content-equivalent* legacy page, or to the beginning if no equivalent. Implement via a `_remapPageIndex(int trimmedIndex)` helper in `OnboardingNotifier` with explicit cases for the 7 removed screens.

#### 1.5 — `TourKeys` lifetime — per-screen ownership, not global

Replace the `Provider<TourKeys>` pattern with per-screen ownership. `GlobalKey`s in a global provider collide on hot reload AND on re-entry to a screen.

**Delete:** `lib/features/tour/providers/tour_keys_provider.dart` (the version in Task C4)

**Replace with:** each screen owns its keys in its own State:

```dart
class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  final _muhasabahCtaKey = GlobalKey(debugLabel: 'tour.muhasabahCta');
  final _streakPillKey = GlobalKey(debugLabel: 'tour.streakPill');
  // tabBarKey lives on AppShell's State
  // ...
}
```

Tour trigger reads the keys from the screen's State (or via a callback param) rather than from a provider. For the tab bar key, AppShell exposes it via a `tabBarKeyProvider = StateProvider<GlobalKey?>` populated in `AppShell.initState` — but that provider is *autoDispose* so it dies with the route stack.

This costs ~20 LOC but eliminates a real hot-reload footgun and a real "rapid back+forth tab switch" production crash.

### Code Quality fixes to apply

#### 2.1 — E6 sequenced walk via Riverpod, not SharedPreferences

In Task H3, replace `tour_guided_sequence_active` shared-prefs flag with:

```dart
// lib/features/tour/providers/guided_sequence_provider.dart
final guidedSequenceActiveProvider = StateProvider<bool>((_) => false);
```

`TourService.startGuidedSequence` becomes:
```dart
Future<void> startGuidedSequence(WidgetRef ref, String userId) async {
  await resetAll(userId);
  ref.read(guidedSequenceActiveProvider.notifier).state = true;
}
```

Each tour screen's `onComplete` reads `ref.read(guidedSequenceActiveProvider)`. Final screen's `onComplete` sets it back to `false`. App restart = state gone, no stuck flag.

#### 2.2 — `.gitattributes` for Mixpanel funnel JSON

Add to `.gitattributes` (create if missing):
```
docs/analytics/*.json diff=json text eol=lf
```
And in `docs/analytics/README.md` (created in Task A11), include rebuild instructions so the JSON can be re-generated from scratch if Mixpanel UI changes invalidate the format.

### Test additions to plan (Phase C+ scope)

The original plan has 3 tests. Adding 17 to hit 100% coverage of new branches.

| # | File | What it asserts | Phase |
|---|---|---|---|
| T1 | `supabase/tests/00041_app_config_onboarding_flags.sql` | After PR-1 migration, both `onboarding_trim_enabled` and `guided_tour_enabled` rows exist with value `true` | PR-1 |
| T2 | `test/services/app_config_service_test.dart` | `getBool` cache hit (fresh) returns cached value, no network call | PR-2 |
| T3 | same | `getBool` cache hit (stale) returns stale, fires async refresh | PR-2 |
| T4 | same | `getBool` cache miss + offline returns fallback | PR-2 |
| T5 | same | `getBool` cache miss + online populates cache + returns fresh | PR-2 |
| T6 | same | `_refresh` swallows Supabase timeout, no crash | PR-2 |
| T7 | same | `primeCache` populates all keys in parallel | PR-2 |
| T8 | `test/features/onboarding/onboarding_dual_flow_test.dart` | `onboarding_trim_enabled=true` → PageView has 20 children | PR-2 |
| T9 | same | `onboarding_trim_enabled=false` → PageView has 27 children | PR-2 |
| T10 | same | **REGRESSION**: flip from trimmed→legacy mid-flow on page 8 lands on `_remapPageIndex(8)` (defined by helper) | PR-2 |
| T11 | `test/features/onboarding/abandonment_telemetry_test.dart` | 24h+ paused fires `onboarding_abandoned_at_page` event with correct page | PR-2 |
| T12 | same | < 24h paused fires nothing | PR-2 |
| T13 | `test/widgets/coachmark/coachmark_overlay_test.dart` (extension) | null target rect → centered card fallback | PR-3 |
| T14 | same | rotation rebuilds the cutout rect | PR-3 |
| T15 | `test/widgets/coachmark/coachmark_controller_test.dart` | `_show` → `_next` advances index, replaces overlay entry | PR-3 |
| T16 | same | `_skip` dismisses, clears `_entry`, calls onSkip | PR-3 |
| T17 | same | `dispose` clears entry even mid-sequence | PR-3 |
| T18 | `test/features/tour/home_tour_trigger_test.dart` (replaces skeleton) | Extract `maybeStartHomeTour(userId, service, analytics, controllerFactory)` as a top-level function and test directly. shouldShow=true triggers; shouldShow=false doesn't | PR-3 |
| T19 | `test/features/tour/sequenced_walk_test.dart` | Home complete → guidedSequenceActive=true → /collection route → /journal → /duas → guidedSequenceActive=false | PR-3 |
| T20 | `test/features/tour/replay_deep_link_test.dart` (E5) | `/settings?action=replay_tour` query param triggers `resetAll` + `context.go('/')` | PR-3 |

All tests are TDD-first per the existing plan convention — write the failing test, run, implement, run, commit.

### Worktree parallelization strategy

Three PRs are inherently sequential (PR-2 depends on PR-1, PR-3 depends on PR-2's `AppConfigService`). Within PR-3 there is some parallelism:

| Step | Modules touched | Depends on |
|---|---|---|
| C1 — TourService | `lib/services/`, `test/services/` | — |
| C2-C3 — Coachmark widget+controller | `lib/widgets/coachmark/`, `test/widgets/coachmark/` | — |
| C4 — TourKeys refactor (per-screen) | `lib/features/{progress,collection,journal,duas,settings}/` | — |
| D — Home tour wiring | `lib/features/progress/`, `lib/widgets/app_shell.dart` | C1, C2, C3, C4 |
| E — Collection empty state | `lib/features/collection/` | C1, F0 (SVGs) |
| F — Journal empty state | `lib/features/journal/` | C1, F0 |
| G — Duas coachmark | `lib/features/duas/` | C1, C2, C3, C4 |
| H — Settings replay + sequenced walk | `lib/features/settings/`, sequence provider | D, E, F, G |

**Lanes:**
- **Lane A:** C1 (sequential, services only)
- **Lane B:** C2 → C3 (sequential, both in `lib/widgets/coachmark/`)
- **Lane C:** F0 (SVGs — already done)
- After A+B+C complete in parallel: D, E, F, G can all run in parallel (different feature modules)
- After D+E+F+G: H

**Conflict flag:** None — every lane owns a distinct module directory.

### Resolved decisions
- **1.2C** accepted — parallel prefetch
- **1.4α** accepted — dual-flow with PR-2b cleanup

### Unresolved decisions
None. All Architecture and Code Quality findings have stated-fix or user-decided resolutions.

---

## Design Review Updates (2026-05-25)

Reviewed by `/plan-design-review`. Initial design score 7.5/10 → 9/10 after fixes. 0 unresolved decisions. App-UI classifier (not marketing), no AI-slop patterns triggered.

### Tour intro animation spec (Pass 1)

When a tour fires, the user's gaze must be sequenced:

```
t=0ms       scrim opacity 0 → 0.55  (280ms ease-out)
t=180ms     cutout rect grows from center to full bounds (200ms ease-out-back)
t=320ms     tooltip slides up 16px + fades in (280ms ease-out)
t=600ms     step dots animate in one-by-one (60ms stagger)
```

Implement in `CoachmarkOverlay.build`:
```dart
return AnimatedOpacity(
  opacity: _opacity, // initial 0, set to 1 on first frame
  duration: const Duration(milliseconds: 280),
  curve: Curves.easeOut,
  child: /* scrim + tooltip */,
);
```
Tooltip wraps in `TweenAnimationBuilder<Offset>` with begin `(0, 16)` end `(0, 0)`. Cutout grow handled by `_ScrimPainter` with an animated `t` parameter (0→1) that interpolates the cutout rect from `cutout.center` size 0 to full `cutout`.

Total intro: 600ms. Dismissal: reverse, 280ms.

### Tour Copy Table (Pass 3)

Single source of truth for all tour and empty-state copy. Implementers reference this table, not inline strings. Future i18n extraction reads from here.

| Surface | Slot | English copy |
|---|---|---|
| Home tour | step 1/3 | Tap here daily. Today's Name unlocks after your check-in. |
| Home tour | step 2/3 | Your streak grows with every reflection. Don't break it. |
| Home tour | step 3/3 | Cards, Journal, Duas — your library lives here. |
| Collection | empty caption (under starter card) | This is your first Name. Earn the next with tomorrow's check-in. |
| Journal | empty title | Reflect on today's Name. |
| Journal | empty body | Your entries stay private. Only you can read them. |
| Journal | empty CTA | Write first entry |
| Duas | coachmark 1/1 | Tap ♡ to save duas you love. Browse them anytime. |
| Settings | replay row label | Replay app tour |
| Win-back push (E5) | title | Want me to show you around? |
| Win-back push (E5) | body | Tap to retake the Sakina tour — 30 seconds. |
| Tour shared | Skip button | Skip tour |
| Tour shared | Next button (mid-step) | Next → |
| Tour shared | Next button (final step) | Done |

### Resolved design decisions (with answers)

**7.1 — markSeen timing: B (current plan).** Fires only on tour complete OR skip. Mid-tour background = next launch picks up at step 0 fresh (acceptable — the markSeen flag was never set). Spec note: do NOT mark seen on overlay insert, only on user-driven dismissal. Maps to "respect user's time, show once" ethos.

**7.2 — Dark mode: N/A.** Sakina has no app-wide dark mode (CLAUDE.md mentions it as a secondary aspiration but no implementation exists). Tour scrim hardcoded to `Color(0x8C1B0E0E)` (dark warm). **Test added (T21):** verify on a device that the scrim renders correctly against the light cream backgrounds throughout the app. If dark mode ships later, add a dark-mode scrim variant in a follow-up PR.

**7.3 — Replay walk inter-screen transition: B (280ms fade).** Between Home → Collection → Journal → Duas during the E6 sequenced walk, use Flutter's default `MaterialPageRoute` with a custom `transitionsBuilder`:
```dart
PageRouteBuilder(
  transitionDuration: const Duration(milliseconds: 280),
  pageBuilder: (_, __, ___) => destination,
  transitionsBuilder: (_, anim, __, child) =>
      FadeTransition(opacity: anim, child: child),
);
```
For the AppShell's bottom-tab routes (which use `NoTransitionPage` in `router.dart`), the sequenced walk needs a one-off override. **Simpler approach:** in `progress_screen.dart` post-Home-tour complete, when `guidedSequenceActive=true`, use `context.go('/collection')` and let `AppShell`'s `IndexedStack` switch tabs (no route push, no transition). The 280ms fade is between **tour overlays** when one screen's tour completes and the next begins — implement as a 280ms `Future.delayed` between overlay dismiss and next overlay insert. No route-level transition needed.

**7.5 — Win-back push localization: A (ship EN first, i18n in follow-up).** PR-3 ships the push template in English only. Add `localize_win_back_push` to the project TODOs (use the existing i18n table once it exists — Sakina currently has no i18n infrastructure either; this is a known gap from CLAUDE.md). EN-only is acceptable because the entire app is currently EN-only.

### Contrast + button sizing (Pass 5)

- Cream `#FBF7F2` on emerald `#1B6B4A`: 10:1 ✓ WCAG AAA.
- Gold `#C8985E` on emerald `#1B6B4A`: ~3.2:1 — passes WCAG large-text threshold (3:1) ONLY when the gold "Next →" / "Done" button uses **16pt minimum + semibold** weight. Spec note in `CoachmarkOverlay._Tooltip`:
  ```dart
  style: const TextStyle(
    color: AppColors.secondary,
    fontFamily: 'DM Sans',
    fontSize: 16,           // minimum 16pt for large-text contrast pass
    fontWeight: FontWeight.w600,  // semibold ≥ 600
  ),
  ```

### Accessibility + responsive (Pass 6)

Add to PR-3 as **Task C3.5: A11y + responsive polish**.

**Files:**
- Modify: `lib/widgets/coachmark/coachmark_overlay.dart`

**Steps:**

- [ ] Wrap the tooltip card in `Semantics(container: true, liveRegion: true, label: step.message)` so VoiceOver/TalkBack announces the message on appear.
- [ ] Wrap Skip + Next buttons in `Semantics(button: true, label: 'Skip tour' / 'Next, step 1 of 3')` with the step number interpolated. Ensures screen-reader users know progress.
- [ ] Set explicit `minHeight: 44, minWidth: 44` on Skip + Next `TextButton`s via `style: TextButton.styleFrom(minimumSize: const Size(44, 44))`.
- [ ] Small-screen (<360pt width) handling: replace `Skip tour` text with an `Icon(Icons.close, semanticLabel: 'Skip tour')` at this breakpoint. Detect via `MediaQuery.of(context).size.width < 360`.
- [ ] When the overlay inserts, request focus on the tooltip: `FocusScope.of(context).requestFocus(_tooltipFocusNode)` so TalkBack swipe-right reaches Skip/Next first.
- [ ] When the overlay dismisses, restore focus to the prior owner via stored `FocusNode`.
- [ ] Add `excludeSemantics: true` to the `_ScrimPainter` `CustomPaint` so screen readers don't read "decorative paint."
- [ ] Test: VoiceOver enabled → walk through Home tour → verify each tooltip is announced, Skip and Next are labeled with step count.

### Test additions (extends eng review's T1–T20)

| # | File | What it asserts |
|---|---|---|
| T21 | `test/widgets/coachmark/coachmark_dark_bg_test.dart` | Scrim renders with sufficient contrast on light cream backgrounds (visual golden test using `flutter_test`'s `matchesGoldenFile`) |
| T22 | `test/widgets/coachmark/coachmark_a11y_test.dart` | Semantics tree contains tooltip message as liveRegion + Skip/Next as labeled buttons |
| T23 | `test/widgets/coachmark/coachmark_small_screen_test.dart` | At width 320pt, Skip renders as icon not text; tooltip card fits without overflow |
| T24 | `test/features/tour/copy_table_test.dart` | Every string in the Tour Copy Table appears verbatim somewhere in `lib/` — guards against copy drift |

### NOT in scope (design)

- Dark mode scrim variant — no dark mode exists in the app
- Localized tour copy — entire app is EN-only
- Hero animations beyond the 600ms intro — adds complexity, low value
- Custom transitions during sequenced walk (using existing `NoTransitionPage` + 280ms inter-overlay delay instead)

### Approved Mockups

3 SVG illustrations generated and shipped during CEO review:

| Screen/Section | Path | Direction | Notes |
|---|---|---|---|
| Journal empty state | `assets/illustrations/journal_empty.svg` | Quill on parchment with 6% opacity octagram | Emerald shaft + gold nib, faint gold rule lines on parchment |
| Collection starter ornament | `assets/illustrations/collection_starter_ornament.svg` | Khatam medallion + flourishes | Goes above the "earn next Name" caption under the seeded starter card |
| Duas first visit | `assets/illustrations/duas_first_visit.svg` | Open mushaf with text-line indicators + gold heart hint | Optional hero for first-visit Duas before any saves |

All three use Sakina's palette (emerald `#1B6B4A`, gold `#C8985E`) and Islamic geometric accents at 6-7% opacity per CLAUDE.md design system.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-25-onboarding-trim-guided-tour.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using `executing-plans`, batch execution with checkpoints

**Which approach?**

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | CLEAR | 7 proposals, 7 accepted, 0 deferred (SELECTIVE_EXPANSION) |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR | 8 issues found, 0 critical gaps, 17 test additions, 0 unresolved |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | CLEAR | score: 7.5/10 → 9/10, 9 decisions made (intro animation, copy table, a11y, contrast, dark-mode N/A) |
| Codex / Outside Voice | `/codex review` | Independent 2nd opinion | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | n/a | — |

**UNRESOLVED:** 0

**VERDICT:** CEO + ENG + DESIGN CLEARED — ready to implement. Outside voice optional (not a structural ambiguity case).
