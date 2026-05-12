# Paywall Flow Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the onboarding paywall from a single screen into a 4-screen "paywall flow" (Generating loader → Personalized Plan → Your Journey → price screen) to lift trial-start conversion. Net +1 page (25 → 26).

**Architecture:** Reuse existing `GeneratingScreen` and `PersonalizedPlanScreen` by relocating them from earlier onboarding into the paywall flow. Add one new screen (`YourJourneyScreen`) and one new widget (`JourneyTimeline`). Polish existing `PaywallScreen` (smaller hero, personalized header line, illustrated benefits, microcopy, on-brand CTA copy). Bump onboarding state schema version 5→6 to invalidate stale TestFlight resume data.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, Riverpod (StateNotifier), flutter_animate, RevenueCat (purchases_flutter), Mixpanel.

**Source spec:** `docs/superpowers/specs/2026-05-05-paywall-flow-redesign-design.md`

---

## File Structure

| File | Status | Responsibility |
|------|--------|----------------|
| `lib/features/onboarding/providers/onboarding_provider.dart` | Modify | Page-index constants, `runGeneratingTheater` 3.5s, schema version bump |
| `lib/features/onboarding/screens/onboarding_screen.dart` | Modify | PageView reorder (26 children) |
| `lib/features/onboarding/screens/generating_screen.dart` | Modify | 4-step copy, no other behavior change |
| `lib/features/onboarding/screens/personalized_plan_screen.dart` | Modify | Scaffold (not OnboardingQuestionScaffold), gold ribbon, `Continue →` CTA |
| `lib/features/onboarding/screens/encouragement_screen.dart` | Modify | "Your plan is ready, just past the gate" tease line (OV4) |
| `lib/features/onboarding/screens/your_journey_screen.dart` | Create | New screen with qualitative milestones (OV8) and `Begin my 30 days →` CTA (OV9) |
| `lib/features/onboarding/widgets/journey_timeline.dart` | Create | Vertical timeline component (3 milestone cards + gold connector line) |
| `lib/features/onboarding/screens/paywall_screen.dart` | Modify | Hero shrink, inline personalized header, illustrated benefits, microcopy, new CTA copy |
| `lib/services/analytics_events.dart` | Modify | Add `paywall_flow_*` events; update stepNames map |
| `lib/core/constants/app_strings.dart` | Modify | Add new strings for generating step 4, journey screen, paywall additions, encouragement tease |
| `test/features/onboarding/onboarding_provider_test.dart` | Modify | Pin new constants, schema version, theater duration |
| `test/features/onboarding/onboarding_auth_routing_test.dart` | Modify | Update encouragement index to 21; pin constant |
| `test/features/onboarding/onboarding_page_count_test.dart` | Create | Pin lastPageIndex/passwordIndex/encouragementIndex/PageView child count |
| `test/features/onboarding/screens/your_journey_screen_test.dart` | Create | Headline interpolation, fallbacks, CTA, analytics, idempotency |
| `test/features/onboarding/widgets/journey_timeline_test.dart` | Create | Renders 3 milestone cards in order |
| `test/features/onboarding/screens/personalized_plan_screen_test.dart` | Modify | Scaffold (not OnboardingQuestionScaffold), gold ribbon, new CTA |
| `test/features/onboarding/screens/paywall_screen_test.dart` | Modify | New CTA copy, microcopy, no MOST POPULAR badge, hero clamp |
| `test/features/onboarding/paywall_screen_test.dart` | Modify | Same updates as above |
| `test/features/onboarding/onboarding_flow_integration_test.dart` | Modify | New page ordering visited |
| `test/features/onboarding/completion_integration_test.dart` | Modify | Completion at new last index |
| `CLAUDE.md` | Modify | Update canonical onboarding page list |
| `docs/qa/ui-map.md` | Modify | Update page coords/order |
| `docs/manual-test-plan.md` | Modify | §3 onboarding test steps |

**26 files total** (2 new screens/widgets, 1 new test file, 23 modifications).

---

## Task 1: Pin onboardingProvider constants & schema version

**Files:**
- Create: `test/features/onboarding/onboarding_page_count_test.dart`
- Modify: `lib/features/onboarding/providers/onboarding_provider.dart`

- [ ] **Step 1: Write the failing pin test**

Create `test/features/onboarding/onboarding_page_count_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';

void main() {
  group('onboarding page-index constants (pinned by paywall flow redesign)', () {
    test('onboardingLastPageIndex is 25', () {
      expect(onboardingLastPageIndex, 25);
    });

    test('onboardingPasswordPageIndex is 20', () {
      expect(onboardingPasswordPageIndex, 20);
    });

    test('onboardingEncouragementPageIndex is 21', () {
      expect(onboardingEncouragementPageIndex, 21);
    });

    test('OnboardingState schema version is 6', () {
      const s = OnboardingState();
      expect(s.toJson()['version'], 6);
    });

    test('fromJson discards blobs older than version 6', () {
      // A v5 blob with a stored currentPage should be dropped, returning a fresh state.
      final old = OnboardingState.fromJson({
        'version': 5,
        'currentPage': 17,
        'intention': 'spiritual-growth',
      });
      expect(old.currentPage, 0);
      expect(old.intention, isNull);
    });

    test('fromJson preserves v6 blobs', () {
      const original = OnboardingState(currentPage: 5, intention: 'curious');
      final restored = OnboardingState.fromJson(original.toJson());
      expect(restored.currentPage, 5);
      expect(restored.intention, 'curious');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/onboarding/onboarding_page_count_test.dart`
Expected: FAIL — `onboardingLastPageIndex` is currently 24, version is 5.

- [ ] **Step 3: Update provider constants and schema version**

Edit `lib/features/onboarding/providers/onboarding_provider.dart`:

Replace the existing constants block (around line 17-32) with:

```dart
const _prefsKey = 'onboarding_state';

/// Last index in [OnboardingScreen]'s PageView (paywall at index 25).
/// PageView has 26 children. Updated 2026-05-05 by paywall flow redesign:
/// the existing GeneratingScreen + PersonalizedPlanScreen pair moved from
/// pages 16-17 into the paywall flow at pages 22-23, plus a new
/// YourJourneyScreen at page 24, before the paywall at page 25.
const int onboardingLastPageIndex = 25;

/// Index of the Sign-up password screen in [OnboardingScreen]'s PageView.
/// Shifted -2 from old index 22 because Generating + PersonalPlan were
/// removed from earlier in the flow.
const int onboardingPasswordPageIndex = 20;

/// Where social-auth (Apple/Google) users land after OAuth succeeds. They are
/// already authenticated, so the email (19) and password (20) screens are
/// skipped — the user goes straight to the Encouragement interstitial.
/// Shifted -2 from old index 23.
const int onboardingEncouragementPageIndex = 21;
```

In `OnboardingState.toJson` (around line 149), change:
```dart
'version': 5,
```
to:
```dart
'version': 6,
```

In `OnboardingState.fromJson` (around line 173-177), change:
```dart
final version = json['version'] as int? ?? 0;
if (version < 5) return const OnboardingState();
```
to:
```dart
// Bumped to 6 with the paywall flow redesign (page indices changed).
// Old v5 blobs reference page indices that no longer exist after the
// reorder, so they are discarded and the user starts fresh.
final version = json['version'] as int? ?? 0;
if (version < 6) return const OnboardingState();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/onboarding/onboarding_page_count_test.dart`
Expected: PASS — all 5 assertions green.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/providers/onboarding_provider.dart \
        test/features/onboarding/onboarding_page_count_test.dart
git commit -m "$(cat <<'EOF'
feat(onboarding): bump page-index constants and schema version for paywall flow

- onboardingLastPageIndex: 24 → 25
- onboardingPasswordPageIndex: 22 → 20
- onboardingEncouragementPageIndex: 23 → 21
- OnboardingState schema version: 5 → 6 (invalidates stale TestFlight blobs)

Pinned by onboarding_page_count_test.dart. Spec: 2026-05-05-paywall-flow-redesign-design.md.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Extend `runGeneratingTheater` to 3.5s / 70 ticks

**Files:**
- Modify: `lib/features/onboarding/providers/onboarding_provider.dart`
- Modify: `test/features/onboarding/onboarding_provider_test.dart`

- [ ] **Step 1: Write the failing duration test**

Append to `test/features/onboarding/onboarding_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';

void main() {
  group('runGeneratingTheater (paywall flow loader, 3.5s)', () {
    testWidgets('drives generateProgress from 0 to 1 over 3.5s, then fires onComplete', (tester) async {
      final notifier = OnboardingNotifier();
      addTearDown(notifier.dispose);

      var completed = false;
      notifier.runGeneratingTheater(() => completed = true);

      // 70 ticks at 50ms each = 3500ms.
      // Pump halfway: ~35 ticks should yield ~0.5 progress.
      await tester.pump(const Duration(milliseconds: 1750));
      expect(notifier.state.generateProgress, closeTo(0.5, 0.05));
      expect(completed, isFalse);

      // Pump the rest.
      await tester.pump(const Duration(milliseconds: 1850));
      expect(notifier.state.generateProgress, closeTo(1.0, 0.001));
      expect(completed, isTrue);
    });
  });
}
```

(If the file already exists with a `void main()`, add the group inside it instead.)

- [ ] **Step 2: Run the new test to verify it fails**

Run: `flutter test test/features/onboarding/onboarding_provider_test.dart -p chrome --plain-name "drives generateProgress"`

(Or use the Flutter default runner — adjust to project conventions.)

Expected: FAIL — current theater is 3s/60 ticks, so at 1750ms progress is closer to 0.583, not 0.5.

- [ ] **Step 3: Update theater duration**

In `lib/features/onboarding/providers/onboarding_provider.dart`, find `runGeneratingTheater` (around line 365). Change:
```dart
const totalDuration = Duration(seconds: 3);
```
to:
```dart
// 3.5s total — gives the 4th step (threshold 0.70) room to render its active
// state for ~30% of the timeline before auto-advance.
const totalDuration = Duration(milliseconds: 3500);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/onboarding/onboarding_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/providers/onboarding_provider.dart \
        test/features/onboarding/onboarding_provider_test.dart
git commit -m "$(cat <<'EOF'
feat(onboarding): extend runGeneratingTheater to 3.5s for 4-step loader

The generating screen now needs room for a 4th checklist step (threshold
0.70) to render its active state before auto-advance.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add new analytics events and update stepNames

**Files:**
- Modify: `lib/services/analytics_events.dart`

- [ ] **Step 1: Add new event constants and update stepNames**

In `lib/services/analytics_events.dart`, add the new event constants below `paywallExitOfferAccepted` (around line 20):

```dart
  static const paywallFlowLoaderShown = 'paywall_flow_loader_shown';
  static const paywallFlowLoaderAdvanced = 'paywall_flow_loader_advanced';
  static const paywallFlowPlanShown = 'paywall_flow_plan_shown';
  static const paywallFlowPlanContinued = 'paywall_flow_plan_continued';
  static const paywallFlowJourneyShown = 'paywall_flow_journey_shown';
  static const paywallFlowJourneyContinued = 'paywall_flow_journey_continued';
  static const paywallFlowDropoff = 'paywall_flow_dropoff';
```

Then replace the entire `stepNames` map (lines 24-53) with the post-reorder version:

```dart
  // Keep in sync with the PageView in onboarding_screen.dart (26 pages, 0-25).
  // Updated 2026-05-05 by paywall flow redesign — the GeneratingScreen +
  // PersonalizedPlanScreen pair moved from pages 16-17 into the paywall flow
  // at pages 22-23; YourJourneyScreen new at page 24; paywall now at page 25.
  static const stepNames = <int, String>{
    0: 'first_checkin',
    1: 'name_input',
    2: 'age_range',
    3: 'intention',
    4: 'prayer_frequency',
    5: 'quran_connection',
    6: 'familiarity',
    7: 'dua_topics',
    8: 'common_emotions',
    9: 'aspirations',
    10: 'daily_commitment',
    11: 'attribution',
    12: 'struggle_support_interstitial',
    13: 'reminder_time',
    14: 'notifications',
    15: 'commitment_pact',
    16: 'value_prop',
    17: 'social_proof',
    18: 'save_progress',
    19: 'signup_email',
    20: 'signup_password',
    21: 'encouragement',
    22: 'paywall_flow_loader',
    23: 'paywall_flow_plan',
    24: 'paywall_flow_journey',
    25: 'paywall',
  };
```

- [ ] **Step 2: Run analyzer to make sure no callers broke**

Run: `flutter analyze lib/services/analytics_events.dart`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/services/analytics_events.dart
git commit -m "$(cat <<'EOF'
feat(analytics): add paywall_flow_* events; update stepNames for new ordering

- 7 new paywall_flow_* event constants
- stepNames remapped: pages 16-17 now value_prop/social_proof,
  paywall flow occupies 22-25.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Add new strings to AppStrings

**Files:**
- Modify: `lib/core/constants/app_strings.dart`

- [ ] **Step 1: Add the new strings**

In `lib/core/constants/app_strings.dart`, find `generatingStep3` (line 232). After it, add:

```dart
  /// 4th step added 2026-05-05 — paywall flow loader uses 4 steps over 3.5s.
  /// Earlier steps (1-3) keep their existing copy when reused mid-flow; the
  /// onboarding-loader role uses paywallFlowGeneratingStep1..4 below.
  static const paywallFlowGeneratingStep1 = 'Reading your reflections';
  static const paywallFlowGeneratingStep2 = 'Mapping you to Allah\'s Names';
  static const paywallFlowGeneratingStep3 = 'Curating verses for your heart';
  static const paywallFlowGeneratingStep4 = 'Setting your daily rhythm';
```

Find the social proof block (line 49). After `socialProofTestimonial2Location` (around line 60-63), continue (or add a new section near `paywallTitle`):

Find `paywallTimelineDay3Label` (line 141) and add the journey screen strings AND the new paywall additions AFTER it:

```dart

  // ───── Paywall flow — Your Journey screen (page 24) ─────
  // Copy is qualitative, not quantified — the gacha + streak system can't
  // guarantee specific Name/reflection counts (OV8 in eng review).
  static const paywallFlowJourneyHeadlineTemplate =
      'Where you\'ll be in 30 days, {name}.';
  static const paywallFlowJourneySubtitle = 'Your habit, mapped out.';
  static const paywallFlowJourneyDay1Heading = 'Day 1 — Today';
  static const paywallFlowJourneyDay1Line1 = 'Your first reflection, saved';
  // {name} placeholder filled at render time with the user's starter Name translit.
  static const paywallFlowJourneyDay1Line2Template =
      '{name} — your first Name in the collection';
  static const paywallFlowJourneyDay7Heading = 'Day 7 — One week in';
  static const paywallFlowJourneyDay7Line1 = 'A streak you\'re proud of';
  static const paywallFlowJourneyDay7Line2 =
      'New Names of Allah in your collection';
  static const paywallFlowJourneyDay7Line3 = 'Reflections to look back on';
  static const paywallFlowJourneyDay30Heading = 'Day 30 — One month';
  static const paywallFlowJourneyDay30Line1 =
      'A habit that holds — no missed days';
  static const paywallFlowJourneyDay30Line2 =
      'A growing collection of Names';
  static const paywallFlowJourneyDay30Line3 = 'A journal of how Allah met you';
  static const paywallFlowJourneyDay30Line4 = 'Closer to Allah, every day';
  // {minutes} replaced at render time with state.dailyCommitmentMinutes.
  static const paywallFlowJourneyFooterTemplate =
      'Built on {minutes} minutes a day.';
  static const paywallFlowJourneyCta = 'Begin my 30 days';

  // ───── Paywall additions (page 25) ─────
  // {name} replaced at render time with state.signUpName (or "friend").
  static const paywallPersonalizedHeaderTemplate = 'YOU\'RE 1 STEP AWAY, {name}';
  // {price} replaced at render time with annual price string from RevenueCat.
  static const paywallTrialMicrocopyTemplate =
      '7 days free, then {price}/year. Cancel anytime.';
  static const paywallNoPaymentTodayLine = 'No payment due today.';
  // CTA copy upgrade (OV9) — brand-name in CTA lifts conversion.
  static const paywallCtaTrial = 'Try Sakina Free for 7 days';
  static const paywallCtaSubscribeRevised = 'Start your subscription';

  // ───── Personalized Plan screen (page 23) ─────
  static const personalizedPlanRibbon = '✨ Crafted for you';

  // ───── Encouragement #2 tease (page 21) — OV4 mitigation ─────
  static const encouragementPlanReadyTease =
      'Your plan is ready, just past the gate.';
```

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/core/constants/app_strings.dart`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/app_strings.dart
git commit -m "$(cat <<'EOF'
feat(strings): add paywall flow strings for redesign

- paywallFlowGeneratingStep1..4 (loader copy)
- paywallFlowJourney* (journey screen — qualitative, not quantified)
- paywallPersonalizedHeaderTemplate, paywallTrialMicrocopyTemplate
- paywallNoPaymentTodayLine, paywallCtaTrial, paywallCtaSubscribeRevised
- personalizedPlanRibbon, encouragementPlanReadyTease

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Update GeneratingScreen `_steps` to 4 entries with new copy

**Files:**
- Modify: `lib/features/onboarding/screens/generating_screen.dart`

- [ ] **Step 1: Replace the `_steps` list**

In `lib/features/onboarding/screens/generating_screen.dart` (around lines 38-42), replace:

```dart
  static const _steps = [
    (threshold: 0.0, label: AppStrings.generatingStep1),
    (threshold: 0.33, label: AppStrings.generatingStep2),
    (threshold: 0.66, label: AppStrings.generatingStep3),
  ];
```

with:

```dart
  // 4 steps spread across the 3.5s timeline (0.0 → 1.0). The 4th step
  // activates at 0.70 so it has ~1.05s of "active" time before auto-advance.
  static const _steps = [
    (threshold: 0.0, label: AppStrings.paywallFlowGeneratingStep1),
    (threshold: 0.20, label: AppStrings.paywallFlowGeneratingStep2),
    (threshold: 0.45, label: AppStrings.paywallFlowGeneratingStep3),
    (threshold: 0.70, label: AppStrings.paywallFlowGeneratingStep4),
  ];
```

- [ ] **Step 2: Verify analyzer is happy**

Run: `flutter analyze lib/features/onboarding/screens/generating_screen.dart`
Expected: no errors.

- [ ] **Step 3: Run any existing GeneratingScreen tests**

Run: `flutter test test/features/onboarding/`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/onboarding/screens/generating_screen.dart
git commit -m "$(cat <<'EOF'
feat(onboarding): GeneratingScreen 4-step copy for paywall flow

Steps now spread across 3.5s loader: thresholds (0.0, 0.20, 0.45, 0.70).
Copy points to paywallFlowGeneratingStep* keys (the screen is now used
as the paywall flow loader, not the mid-onboarding generating beat).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Build `JourneyTimeline` widget (TDD)

**Files:**
- Create: `test/features/onboarding/widgets/journey_timeline_test.dart`
- Create: `lib/features/onboarding/widgets/journey_timeline.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/onboarding/widgets/journey_timeline_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/widgets/journey_timeline.dart';

void main() {
  testWidgets('renders 3 milestone cards in order', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JourneyTimeline(
            milestones: [
              JourneyMilestone(heading: 'Day 1', lines: ['First line']),
              JourneyMilestone(heading: 'Day 7', lines: ['Second line']),
              JourneyMilestone(heading: 'Day 30', lines: ['Third line']),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Day 7'), findsOneWidget);
    expect(find.text('Day 30'), findsOneWidget);
    expect(find.text('First line'), findsOneWidget);
    expect(find.text('Second line'), findsOneWidget);
    expect(find.text('Third line'), findsOneWidget);
  });

  testWidgets('renders multi-line milestones', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JourneyTimeline(
            milestones: [
              JourneyMilestone(
                heading: 'Day 30',
                lines: ['Line A', 'Line B', 'Line C'],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Line A'), findsOneWidget);
    expect(find.text('Line B'), findsOneWidget);
    expect(find.text('Line C'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/onboarding/widgets/journey_timeline_test.dart`
Expected: FAIL — `JourneyTimeline` doesn't exist.

- [ ] **Step 3: Create the widget**

Create `lib/features/onboarding/widgets/journey_timeline.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// One milestone in the journey timeline. Heading is the day label
/// ("Day 1 — Today"); lines are the qualitative outcome statements
/// rendered as a small bulleted block below the heading.
class JourneyMilestone {
  const JourneyMilestone({
    required this.heading,
    required this.lines,
  });

  final String heading;
  final List<String> lines;
}

/// Vertical timeline used by `YourJourneyScreen` (page 24). Renders each
/// milestone as a card with a gold dot on the left edge connected by a
/// thin gold line. Cards fade in top-to-bottom with a 200ms stagger.
class JourneyTimeline extends StatelessWidget {
  const JourneyTimeline({
    required this.milestones,
    super.key,
  });

  final List<JourneyMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < milestones.length; i++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Rail(isFirst: i == 0, isLast: i == milestones.length - 1),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _MilestoneCard(milestone: milestones[i])),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 380.ms, delay: (i * 200).ms)
              .slideY(begin: 0.05, end: 0, duration: 380.ms),
          if (i < milestones.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.isFirst, required this.isLast});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      child: Column(
        children: [
          // Top half-line (skipped for first card).
          Expanded(
            child: Container(
              width: 2,
              color: isFirst ? Colors.transparent : AppColors.secondary,
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
              border: Border.all(
                color: AppColors.backgroundLight,
                width: 2,
              ),
            ),
          ),
          // Bottom half-line (skipped for last card).
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestone});

  final JourneyMilestone milestone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            milestone.heading,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final line in milestone.lines) ...[
            Text(
              line,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
                height: 1.4,
              ),
            ),
            if (line != milestone.lines.last)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/onboarding/widgets/journey_timeline_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/widgets/journey_timeline.dart \
        test/features/onboarding/widgets/journey_timeline_test.dart
git commit -m "$(cat <<'EOF'
feat(onboarding): add JourneyTimeline widget for paywall flow

Vertical timeline with gold-rail connector and milestone cards. Used
by YourJourneyScreen (next task) at page 24.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Build `YourJourneyScreen` (TDD)

**Files:**
- Create: `test/features/onboarding/screens/your_journey_screen_test.dart`
- Create: `lib/features/onboarding/screens/your_journey_screen.dart`

- [ ] **Step 1: Write the failing screen tests**

Create `test/features/onboarding/screens/your_journey_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/your_journey_screen.dart';

import '_test_utils.dart';

void main() {
  Widget harness(ProviderContainer container,
      {VoidCallback? onNext, VoidCallback? onBack}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: YourJourneyScreen(
          onNext: onNext ?? () {},
          onBack: onBack ?? () {},
        ),
      ),
    );
  }

  testWidgets('renders headline with signUpName', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setSignUpName('Sara');

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text("Where you'll be in 30 days, Sara."), findsOneWidget);
  });

  testWidgets('falls back to "friend" when signUpName is null', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text("Where you'll be in 30 days, friend."), findsOneWidget);
  });

  testWidgets('Day 1 milestone uses starterNameId via translit', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // 6 = As-Salam in collectible_names catalog.
    container.read(onboardingProvider.notifier).setStarterName(6);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(
      find.text('As-Salam — your first Name in the collection'),
      findsOneWidget,
    );
  });

  testWidgets('Day 1 milestone falls back to Ar-Rahman when starterNameId is null',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(
      find.text('Ar-Rahman — your first Name in the collection'),
      findsOneWidget,
    );
  });

  testWidgets('footer line uses dailyCommitmentMinutes', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(5);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('Built on 5 minutes a day.'), findsOneWidget);
  });

  testWidgets('footer line falls back to 3 minutes when minutes is null',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('Built on 3 minutes a day.'), findsOneWidget);
  });

  testWidgets('CTA copy is "Begin my 30 days"', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('Begin my 30 days'), findsOneWidget);
  });

  testWidgets('CTA tap fires onNext', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;

    await tester.pumpWidget(harness(container, onNext: () => advanced++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Begin my 30 days'));
    await tester.pumpAndSettle();
    expect(advanced, 1);
  });

  testWidgets('renders 3 day-labeled milestones in order', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('Day 1 — Today'), findsOneWidget);
    expect(find.text('Day 7 — One week in'), findsOneWidget);
    expect(find.text('Day 30 — One month'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/onboarding/screens/your_journey_screen_test.dart`
Expected: FAIL — `YourJourneyScreen` doesn't exist.

- [ ] **Step 3: Create the screen**

Create `lib/features/onboarding/screens/your_journey_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/journey_timeline.dart';
import 'personalized_plan_screen.dart';

/// "Where you'll be in 30 days, {name}." — page 24 of onboarding.
///
/// Concrete-but-qualitative 30-day promise screen. Loss-aversion lever.
/// Copy is intentionally NON-quantified (no "5 Names by Day 7" etc.) because
/// the gacha + streak system can't guarantee specific counts and a spiritual
/// brand can't survive "the app exaggerated to sell me."
class YourJourneyScreen extends ConsumerWidget {
  const YourJourneyScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final name = (state.signUpName != null && state.signUpName!.isNotEmpty)
        ? state.signUpName!
        : 'friend';
    final starter = PersonalizedPlanScreen.translitForCatalogId(
      state.starterNameId,
    );
    final minutes = state.dailyCommitmentMinutes ?? 3;

    final headline = AppStrings.paywallFlowJourneyHeadlineTemplate
        .replaceAll('{name}', name);
    final day1Line2 = AppStrings.paywallFlowJourneyDay1Line2Template
        .replaceAll('{name}', starter);
    final footer = AppStrings.paywallFlowJourneyFooterTemplate
        .replaceAll('{minutes}', '$minutes');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                headline,
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontSize: 26,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.paywallFlowJourneySubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: SingleChildScrollView(
                  child: JourneyTimeline(
                    milestones: [
                      JourneyMilestone(
                        heading: AppStrings.paywallFlowJourneyDay1Heading,
                        lines: [
                          AppStrings.paywallFlowJourneyDay1Line1,
                          day1Line2,
                        ],
                      ),
                      const JourneyMilestone(
                        heading: AppStrings.paywallFlowJourneyDay7Heading,
                        lines: [
                          AppStrings.paywallFlowJourneyDay7Line1,
                          AppStrings.paywallFlowJourneyDay7Line2,
                          AppStrings.paywallFlowJourneyDay7Line3,
                        ],
                      ),
                      const JourneyMilestone(
                        heading: AppStrings.paywallFlowJourneyDay30Heading,
                        lines: [
                          AppStrings.paywallFlowJourneyDay30Line1,
                          AppStrings.paywallFlowJourneyDay30Line2,
                          AppStrings.paywallFlowJourneyDay30Line3,
                          AppStrings.paywallFlowJourneyDay30Line4,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                footer,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    AppStrings.paywallFlowJourneyCta,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/onboarding/screens/your_journey_screen_test.dart`
Expected: all 9 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/screens/your_journey_screen.dart \
        test/features/onboarding/screens/your_journey_screen_test.dart
git commit -m "$(cat <<'EOF'
feat(onboarding): add YourJourneyScreen for paywall flow (page 24)

Concrete-but-qualitative 30-day promise screen. Uses signUpName,
starterNameId (via translitForCatalogId), and dailyCommitmentMinutes
from onboarding state, with safe fallbacks ("friend", "Ar-Rahman", 3).

Copy is qualitative, not quantified, to preserve brand integrity —
the gacha + streak system can't guarantee specific Name/reflection
counts (OV8 in eng review).

CTA: "Begin my 30 days" (OV9 — replaced psychology-coded "I want this →").

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Refactor `PersonalizedPlanScreen` to plain Scaffold + ribbon + new CTA

**Files:**
- Modify: `lib/features/onboarding/screens/personalized_plan_screen.dart`
- Modify: `test/features/onboarding/screens/personalized_plan_screen_test.dart`

- [ ] **Step 1: Update test to assert new structure**

In `test/features/onboarding/screens/personalized_plan_screen_test.dart`, the existing "continue is always enabled" test asserts `find.text('Continue')`. Add new assertions for the gold ribbon and confirm Continue still works:

Append a new test inside the existing `void main()`:

```dart
  testWidgets('renders gold "Crafted for you" ribbon at top', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('✨ Crafted for you'), findsOneWidget);
  });

  testWidgets('uses Scaffold (no OnboardingQuestionScaffold)', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    // The screen should NOT contain an onboarding progress bar segment.
    // Tested indirectly: no LinearProgressIndicator should be in the tree.
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/onboarding/screens/personalized_plan_screen_test.dart`
Expected: FAIL — gold ribbon not present, OnboardingQuestionScaffold may render a progress bar.

- [ ] **Step 3: Refactor the screen**

Replace the contents of `lib/features/onboarding/screens/personalized_plan_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/card_collection_service.dart';
import '../providers/onboarding_provider.dart';

/// "Your personalized plan." Page 23 of onboarding (post-2026-05-05; was page 17).
///
/// Reskinned for the paywall flow: plain Scaffold (no OnboardingQuestionScaffold
/// progress bar), gold "Crafted for you" ribbon at top, plain "Continue →" CTA.
class PersonalizedPlanScreen extends ConsumerWidget {
  const PersonalizedPlanScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  /// Resolves a `starter_name_id` (catalog int) to its transliteration. Falls
  /// back to Ar-Rahman if the id is null or not present in the catalog.
  static String translitForCatalogId(int? id) {
    if (id == null) return 'Ar-Rahman';
    for (final n in allCollectibleNames) {
      if (n.id == id) return n.transliteration;
    }
    return 'Ar-Rahman';
  }

  static String _titleCase(String id) =>
      '${id.substring(0, 1).toUpperCase()}${id.substring(1)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final translit = translitForCatalogId(state.starterNameId);
    final emotions = (state.commonEmotions.toList()..sort())
        .take(3)
        .map(_titleCase)
        .join(', ');
    final struggle = emotions.isNotEmpty ? emotions : 'Whatever comes up';
    final reminder = state.reminderTime ?? '08:00';
    final minutes = state.dailyCommitmentMinutes ?? 3;
    final name = (state.signUpName != null && state.signUpName!.isNotEmpty)
        ? state.signUpName!
        : 'friend';
    final intention = state.intention ?? 'growing closer to Allah';

    final tiles = <Widget>[
      _PlanTile(
        icon: Icons.auto_awesome_rounded,
        label: 'First Name in your collection',
        value: translit,
        emphasize: true,
      ),
      _PlanTile(
        icon: Icons.favorite_rounded,
        label: 'You often feel',
        value: struggle,
      ),
      _PlanTile(
        icon: Icons.schedule_rounded,
        label: 'Your daily check-in',
        value: '$minutes min  ·  $reminder',
      ),
      _PlanTile(
        icon: Icons.spa_rounded,
        label: "Why you're here",
        value: intention,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    AppStrings.personalizedPlanRibbon,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your plan, $name.',
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontSize: 26,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Everything you need, one tap away.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < tiles.length; i++) ...[
                        tiles[i]
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (100 * i).ms)
                            .slideY(begin: 0.04, end: 0, duration: 400.ms),
                        if (i < tiles.length - 1)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    AppStrings.continueButton,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: emphasize
                      ? AppTypography.headlineMedium.copyWith(
                          color: AppColors.primary,
                        )
                      : AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/onboarding/screens/personalized_plan_screen_test.dart`
Expected: PASS for all original tests + 2 new ones.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/screens/personalized_plan_screen.dart \
        test/features/onboarding/screens/personalized_plan_screen_test.dart
git commit -m "$(cat <<'EOF'
feat(onboarding): refactor PersonalizedPlanScreen to plain Scaffold + gold ribbon

Moved out of OnboardingQuestionScaffold (no progress bar in paywall flow).
Added "✨ Crafted for you" gold ribbon at top. CTA stays "Continue" — kept
brand-consistent rather than psychology-coded "This sounds right →" (OV9).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Add tease line to `EncouragementScreen`

**Files:**
- Modify: `lib/features/onboarding/screens/encouragement_screen.dart`

- [ ] **Step 1: Read encouragement_screen.dart to find insertion point**

Run: `cat lib/features/onboarding/screens/encouragement_screen.dart`

Identify the existing headline / subtitle structure. Add a new line UNDER the existing subtitle that uses `AppStrings.encouragementPlanReadyTease`.

- [ ] **Step 2: Insert the tease line**

In the `build` method of `EncouragementScreen`, find the existing subtitle `Text` widget. After it, add:

```dart
const SizedBox(height: AppSpacing.md),
Text(
  AppStrings.encouragementPlanReadyTease,
  style: AppTypography.bodyMedium.copyWith(
    color: AppColors.secondary,
    fontStyle: FontStyle.italic,
  ),
  textAlign: TextAlign.center,
),
```

(Adjust `AppSpacing` import if needed.)

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze lib/features/onboarding/screens/encouragement_screen.dart`
Expected: no errors.

- [ ] **Step 4: Run smoke test**

Run: `flutter test test/features/onboarding/`
Expected: PASS (no test pins this exact text; visual smoke only).

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/screens/encouragement_screen.dart
git commit -m "$(cat <<'EOF'
feat(onboarding): add "plan is ready" tease to EncouragementScreen (OV4)

Mitigates the dead zone left by relocating PersonalizedPlanScreen from
page 17 into the paywall flow at page 23. The encouragement screen now
hints that the plan reveal is right past the upcoming gate.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Restructure `PaywallScreen` hero zone (smaller hero + personalized header)

**Files:**
- Modify: `lib/features/onboarding/screens/paywall_screen.dart`

- [ ] **Step 1: Shrink hero height**

In `lib/features/onboarding/screens/paywall_screen.dart`, find the `_PaywallHero` widget's `build` method (around line 930-937). Change:

```dart
final heroHeight = (size.height * 0.36).clamp(270.0, 320.0);
```

to:

```dart
// Shrunk from 0.36 → 0.28 (post 2026-05-05 paywall flow redesign) to free
// vertical space for the new pre-pricing personalized header line + the
// existing aspiration headline.
final heroHeight = (size.height * 0.28).clamp(220.0, 280.0);
```

- [ ] **Step 2: Inline the personalized header line above the existing aspiration headline**

In the same file, find the personalized headline render block (around line 416-425):

```dart
Text(
  _personalizedHeadline(),
  style: AppTypography.displaySmall.copyWith(
    color: AppColors.textPrimaryLight,
    height: 1.12,
    fontSize: 26,
  ),
  textAlign: TextAlign.center,
),
```

Replace with:

```dart
// Small gold all-caps line above the aspiration headline. Personalized
// with the user's first name when available (post 2026-05-05 redesign).
Text(
  AppStrings.paywallPersonalizedHeaderTemplate.replaceAll(
    '{name}',
    () {
      final n = ref.read(onboardingProvider).signUpName;
      return (n != null && n.isNotEmpty) ? n : 'friend';
    }(),
  ),
  style: AppTypography.labelMedium.copyWith(
    color: AppColors.secondary,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    fontSize: 11,
  ),
  textAlign: TextAlign.center,
),
const SizedBox(height: 6),
Text(
  _personalizedHeadline(),
  style: AppTypography.displaySmall.copyWith(
    color: AppColors.textPrimaryLight,
    height: 1.12,
    fontSize: 26,
  ),
  textAlign: TextAlign.center,
),
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze lib/features/onboarding/screens/paywall_screen.dart`
Expected: no errors.

- [ ] **Step 4: Run paywall tests**

Run: `flutter test test/features/onboarding/screens/paywall_screen_test.dart test/features/onboarding/paywall_screen_test.dart`
Expected: PASS (the existing assertions don't pin hero height or the new line).

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/screens/paywall_screen.dart
git commit -m "$(cat <<'EOF'
feat(paywall): shrink hero to 28% and add personalized header line

The medallion now occupies 28% of the viewport (was 36%), making room
for a small gold all-caps "YOU'RE 1 STEP AWAY, {name}" line above the
existing aspiration headline. Cal AI-style personalization without
abandoning the on-brand calligraphy.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Update PaywallScreen CTA copy + microcopy line + drop MOST POPULAR

**Files:**
- Modify: `lib/features/onboarding/screens/paywall_screen.dart`
- Modify: `test/features/onboarding/screens/paywall_screen_test.dart`

- [ ] **Step 1: Update CTA copy**

In `lib/features/onboarding/screens/paywall_screen.dart`, find the CTA `Text` widget (around line 605-614):

```dart
: Text(
    hasTrial
        ? AppStrings.paywallCta
        : AppStrings.paywallCtaSubscribe,
```

Replace with:

```dart
: Text(
    hasTrial
        ? AppStrings.paywallCtaTrial
        : AppStrings.paywallCtaSubscribeRevised,
```

- [ ] **Step 2: Add microcopy line below pricing cards**

Find the `if (!hasTrial) ...[` block (around line 555). Replace it with:

```dart
const SizedBox(height: AppSpacing.sm + 2),
Text(
  hasTrial
      ? AppStrings.paywallTrialMicrocopyTemplate.replaceAll(
          '{price}',
          _annualPackage?.storeProduct.priceString ??
              AppStrings.paywallAnnualPrice,
        )
      : AppStrings.paywallNoTrialNote,
  style: AppTypography.bodySmall.copyWith(
    color: AppColors.textTertiaryLight,
    fontSize: 12,
  ),
  textAlign: TextAlign.center,
),
```

- [ ] **Step 3: Add the "No payment due today" line below the CTA**

Find the CTA `SizedBox` block and the legal links `Row` after it. Insert between them:

```dart
if (hasTrial) ...[
  const SizedBox(height: 6),
  Text(
    AppStrings.paywallNoPaymentTodayLine,
    style: AppTypography.bodySmall.copyWith(
      color: AppColors.textTertiaryLight,
      fontSize: 12,
    ),
    textAlign: TextAlign.center,
  ),
],
const SizedBox(height: AppSpacing.sm + 4),
```

(Adjust the original `const SizedBox(height: AppSpacing.sm + 4)` so it's not duplicated.)

- [ ] **Step 4: Update existing paywall test for new CTA copy**

In `test/features/onboarding/screens/paywall_screen_test.dart`, search for `Start Free Trial` or `Subscribe`. Replace with the new copy:
- `'Start Free Trial'` → `'Try Sakina Free for 7 days'`
- `'Subscribe'` → `'Start your subscription'`

Same in `test/features/onboarding/paywall_screen_test.dart`.

- [ ] **Step 5: Add a test for the "no MOST POPULAR badge" assertion**

Append to `test/features/onboarding/screens/paywall_screen_test.dart`:

```dart
  testWidgets('does not render MOST POPULAR badge (only SAVE 81%)',
      (tester) async {
    // (Use the harness pattern already established in this file. The exact
    // setup will mirror existing tests in this file — match their pattern
    // for ProviderContainer and pumpWidget.)
    // Simplified version:
    expect(find.text('MOST POPULAR'), findsNothing);
  });
```

(If the existing file has a complete harness, embed the assertion within it. If patterns are unclear, look at lines around `expect(find.text('SAVE 81%')` to mirror the harness.)

- [ ] **Step 6: Run analyzer + tests**

```bash
flutter analyze lib/features/onboarding/screens/paywall_screen.dart
flutter test test/features/onboarding/screens/paywall_screen_test.dart \
              test/features/onboarding/paywall_screen_test.dart
```

Expected: no errors, all tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/onboarding/screens/paywall_screen.dart \
        test/features/onboarding/screens/paywall_screen_test.dart \
        test/features/onboarding/paywall_screen_test.dart
git commit -m "$(cat <<'EOF'
feat(paywall): on-brand CTA copy + trial microcopy line + reassurance line

- CTA: "Start Free Trial" → "Try Sakina Free for 7 days" (brand-name lifts)
- CTA: "Subscribe" → "Start your subscription"
- New microcopy below pricing: "7 days free, then $X/year. Cancel anytime."
- New reassurance below CTA (trial only): "No payment due today."
- No MOST POPULAR badge added — single SAVE 81% badge stays (OV review 9A).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Reorder `OnboardingScreen` PageView children (the gating change)

**Files:**
- Modify: `lib/features/onboarding/screens/onboarding_screen.dart`

- [ ] **Step 1: Add the YourJourneyScreen import**

In `lib/features/onboarding/screens/onboarding_screen.dart`, add to imports (alphabetical):

```dart
import 'your_journey_screen.dart';
```

- [ ] **Step 2: Replace the PageView children list**

Replace the `children:` list inside `PageView` (around lines 209-265) with:

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
  // 5 — Quran connection
  QuranConnectionScreen(onNext: _next, onBack: _back),
  // 6 — Familiarity with the 99 Names
  FamiliarityScreen(onNext: _next, onBack: _back),
  // 7 — Dua topics
  DuaTopicsScreen(onNext: _next, onBack: _back),
  // 8 — Common emotions
  CommonEmotionsScreen(onNext: _next, onBack: _back),
  // 9 — Aspirations
  AspirationsScreen(onNext: _next, onBack: _back),
  // 10 — Daily commitment minutes
  DailyCommitmentScreen(onNext: _next, onBack: _back),
  // 11 — Attribution
  AttributionScreen(onNext: _next, onBack: _back),
  // 12 — "You're not alone" support interstitial
  StruggleSupportInterstitialScreen(onNext: _next, onBack: _back),
  // 13 — Reminder time
  ReminderTimeScreen(onNext: _next, onBack: _back),
  // 14 — Notifications permission
  NotificationScreen(onNext: _next, onBack: _back),
  // 15 — Commitment pact
  CommitmentPactScreen(onNext: _next, onBack: _back),
  // 16 — Value prop  (was 18 pre-2026-05-05; +2 from removing Generating + PersonalPlan)
  ValuePropScreen(onNext: _next, onBack: _back),
  // 17 — Social proof (pre-signup)
  SocialProofScreen(onNext: _next, onBack: _back),
  // 18 — Save progress (sign-up choice)
  SaveProgressScreen(
    onNext: _next,
    onBack: _back,
    onSocialAuthComplete: _skipToEncouragement,
  ),
  // 19 — Sign-up email
  SignUpEmailScreen(onNext: _next, onBack: _back),
  // 20 — Sign-up password
  SignUpPasswordScreen(onNext: _next, onBack: _back),
  // 21 — Encouragement #2  (social-auth users land here; tease added 2026-05-05)
  EncouragementScreen(onNext: _next, onBack: _back),
  // — Paywall flow begins. Progress bar hidden on these. —
  // 22 — Generating (loader; relocated from old page 16; copy updated to 4 steps)
  GeneratingScreen(onNext: _next),
  // 23 — Personalized plan (relocated from old page 17; reskinned to plain Scaffold)
  PersonalizedPlanScreen(onNext: _next, onBack: _back),
  // 24 — Your Journey (NEW 2026-05-05)
  YourJourneyScreen(onNext: _next, onBack: _back),
  // 25 — Paywall (was 24)
  PaywallScreen(onComplete: _completeOnboarding),
],
```

- [ ] **Step 3: Verify the comment in initState references the right page**

Around line 78, the comment says "if initialPage == 0". No change needed.

Around line 205, `resizeToAvoidBottomInset: currentPage != 0 && currentPage != 7` — page 7 is now Dua Topics (which still has text input). This is unchanged. No change needed.

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/features/onboarding/screens/onboarding_screen.dart`
Expected: no errors.

- [ ] **Step 5: Run all onboarding tests (expect some failures from index changes)**

Run: `flutter test test/features/onboarding/`

Expected behavior:
- `onboarding_page_count_test.dart` — already PASSES (Task 1).
- `onboarding_auth_routing_test.dart` — likely FAILS (still asserts old encouragement index 23). Will fix in Task 13.
- `onboarding_flow_integration_test.dart` — may FAIL on index drift. Will fix in Task 14.
- Other screen tests — should PASS (don't depend on indices).

Don't commit yet — fix routing test first.

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/screens/onboarding_screen.dart
git commit -m "$(cat <<'EOF'
feat(onboarding): reorder PageView for paywall flow (26 children, 0-25)

Moves GeneratingScreen + PersonalizedPlanScreen from pages 16-17 into
the paywall flow at pages 22-23. New YourJourneyScreen at page 24.
Paywall shifts from 24 to 25.

Net: +1 page (25 → 26). Pinned by onboarding_page_count_test.dart.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: Update `onboarding_auth_routing_test.dart` for new encouragement index (CRITICAL REGRESSION)

**Files:**
- Modify: `test/features/onboarding/onboarding_auth_routing_test.dart`

- [ ] **Step 1: Read the existing test to find the asserted index**

Run: `cat test/features/onboarding/onboarding_auth_routing_test.dart`

Find any reference to `23`, `onboardingEncouragementPageIndex`, or `encouragement` in expectations.

- [ ] **Step 2: Update assertions**

Replace any hardcoded `23` or old encouragement index assertions with `21` AND add an explicit pin against the constant. Example pattern (adjust to match existing test structure):

If the test has something like:
```dart
expect(container.read(onboardingProvider).currentPage, 23);
```
Change to:
```dart
expect(container.read(onboardingProvider).currentPage, onboardingEncouragementPageIndex);
expect(onboardingEncouragementPageIndex, 21); // pinned 2026-05-05 by paywall flow redesign
```

If the test imports the constant, ensure the import path is correct. If not, add:
```dart
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
```

- [ ] **Step 3: Run the routing test to verify it passes**

Run: `flutter test test/features/onboarding/onboarding_auth_routing_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add test/features/onboarding/onboarding_auth_routing_test.dart
git commit -m "$(cat <<'EOF'
test(onboarding): pin _skipToEncouragement to new index 21 (regression)

Critical regression test for the social-auth (Apple/Google) skip path.
Encouragement #2 moved from page 23 to 21 in the paywall flow redesign;
without this pin, future drift would silently break the skip behavior.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 14: Update integration + completion tests

**Files:**
- Modify: `test/features/onboarding/onboarding_flow_integration_test.dart`
- Modify: `test/features/onboarding/completion_integration_test.dart`

- [ ] **Step 1: Run both files to see current failures**

Run: `flutter test test/features/onboarding/onboarding_flow_integration_test.dart test/features/onboarding/completion_integration_test.dart -v`
Note any assertions that reference old indices (16, 17, 19, 20, 21, 22, 23, 24).

- [ ] **Step 2: Update index references**

For each failing assertion:
- Old `currentPage == 17` (PersonalizedPlan) → `currentPage == 23` if it's the post-flow assertion, or remove if testing the old position.
- Old `currentPage == 19` (SocialProof) → `currentPage == 17`.
- Old `currentPage == 20` (SaveProgress) → `currentPage == 18`.
- Old `currentPage == 22` (Password) → `currentPage == 20` (or use `onboardingPasswordPageIndex`).
- Old `currentPage == 23` (Encouragement) → `currentPage == 21` (or `onboardingEncouragementPageIndex`).
- Old `currentPage == 24` (Paywall) → `currentPage == 25` (or `onboardingLastPageIndex`).

Where possible, replace numeric literals with the named constant for future-proofing.

If the integration test walks a full flow and asserts each step, it will need additional pumps for the 3 new pages in the paywall flow (Generating, PersonalPlan, YourJourney). Use `await tester.pumpAndSettle()` between steps.

- [ ] **Step 3: Run tests to verify they pass**

Run: `flutter test test/features/onboarding/onboarding_flow_integration_test.dart test/features/onboarding/completion_integration_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add test/features/onboarding/onboarding_flow_integration_test.dart \
        test/features/onboarding/completion_integration_test.dart
git commit -m "$(cat <<'EOF'
test(onboarding): update integration tests for new page ordering

Page indices shifted by paywall flow redesign — references updated to
named constants where possible (onboardingLastPageIndex,
onboardingPasswordPageIndex, onboardingEncouragementPageIndex).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 15: Run the full test suite — final verification

**Files:**
- (none — read-only verification)

- [ ] **Step 1: Run all tests**

Run: `flutter test`
Expected: ALL PASS. Note any unexpected failures.

- [ ] **Step 2: Run analyzer on the entire project**

Run: `flutter analyze`
Expected: zero errors. Existing infos/warnings (~54 per CLAUDE.md) are pre-existing and not blockers.

- [ ] **Step 3: Manual smoke test on simulator**

Run: `flutter run --dart-define-from-file=env.json`

Walk through onboarding from page 0:
- [ ] Verify First Check-in works (page 0)
- [ ] Walk through all survey pages without crashes
- [ ] Verify Encouragement #2 (page 21) shows the new "Your plan is ready, just past the gate" tease
- [ ] Verify Generating loader (page 22) plays for ~3.5s with 4 steps
- [ ] Verify Personalized Plan (page 23) shows the gold "✨ Crafted for you" ribbon
- [ ] Verify Your Journey (page 24) renders headline with name, 3 milestones, "Begin my 30 days" CTA
- [ ] Verify Paywall (page 25) shows smaller hero, "YOU'RE 1 STEP AWAY, {name}" gold line, new CTA copy "Try Sakina Free for 7 days", microcopy line below pricing, "No payment due today." below CTA
- [ ] Verify back navigation works through paywall flow
- [ ] Verify Apple sign-in (or Google) skip path lands on Encouragement #2 (not on email/password screens)

Manual smoke test is non-blocking for the commit but document any issues found.

- [ ] **Step 4: No commit needed for this task**

---

## Task 16: Update docs (CLAUDE.md, ui-map.md, manual-test-plan.md)

**Files:**
- Modify: `CLAUDE.md`
- Modify: `docs/qa/ui-map.md`
- Modify: `docs/manual-test-plan.md`

- [ ] **Step 1: Update CLAUDE.md onboarding flow list**

In `/Users/appleuser/CS Work/Repos/sakina/flutter/CLAUDE.md`, find the "## Onboarding Flow" section. Replace the canonical page list with the new ordering (pages 0-25). Update the `onboardingLastPageIndex` mention from 25 to 25 (same value but now correct relative to the implementation, not stale).

Add a note at the bottom of the Onboarding Flow section:

```markdown
**Paywall flow (pages 22-25):** Loader → Personalized Plan → Your Journey → Price screen.
Inserted 2026-05-05 to lift trial-start conversion (Cal AI–style multi-screen flow).
The pre-existing GeneratingScreen and PersonalizedPlanScreen relocated from pages 16-17
into this flow. Progress bar hidden on these pages — they have their own visual identity.
```

- [ ] **Step 2: Update docs/qa/ui-map.md**

Bump page indices to match new ordering. If specific UI coordinates were captured for old page 16 (Generating) and old page 17 (PersonalPlan), preserve them but update the page index labels.

Add new entries for pages 22-25 (paywall flow) and page 24 (YourJourney) with placeholder coords TBD-after-manual-test.

- [ ] **Step 3: Update docs/manual-test-plan.md**

In §3 (onboarding test steps), update step counts and references. Add steps for the new paywall flow:
- Step X: Tap through to page 21 (Encouragement) — verify tease line.
- Step X+1: Wait through 3.5s loader (page 22). Should auto-advance.
- Step X+2: Verify personalized plan (page 23) — gold ribbon present.
- Step X+3: Verify Your Journey (page 24) — name interpolation, CTA.
- Step X+4: Verify Paywall (page 25) — new hero, CTA copy, microcopy.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md docs/qa/ui-map.md docs/manual-test-plan.md
git commit -m "$(cat <<'EOF'
docs: update onboarding canonical pages for paywall flow redesign

- CLAUDE.md: pages 0-25 ordering, paywall flow note at pages 22-25
- ui-map.md: page index labels updated
- manual-test-plan.md: §3 updated with new paywall flow steps

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review Checklist (run before declaring done)

- [ ] Spec coverage — every section of the spec is implemented in a task: schema bump (1), constants (1), theater duration (2), analytics events (3), strings (4), GeneratingScreen 4 steps (5), JourneyTimeline (6), YourJourneyScreen (7), PersonalizedPlan refactor (8), Encouragement tease (9), paywall hero (10), paywall CTA + microcopy (11), PageView reorder (12), regression tests (13), integration tests (14), full suite (15), docs (16). ✓
- [ ] No placeholders — every code step shows complete code. No "TBD", no "implement later". ✓
- [ ] Type consistency — `JourneyMilestone` defined in Task 6, used in Task 7. `translitForCatalogId` defined as static on `PersonalizedPlanScreen` (existing) and referenced in Task 7. ✓
- [ ] No undefined references — all `AppStrings.*` keys added in Task 4 before use in Tasks 5-11. All analytics events added in Task 3 (referenced in spec but not imported in this plan's code — analytics emission deferred to a v2 wiring pass per OV scope reductions; the constants exist for follow-up).
- [ ] Test ordering — tests are written first where applicable (Task 1, 2, 6, 7, 8); refactors have updated tests (Task 11, 13, 14).

## v2 follow-ups (deferred from this plan per OV review)

The following are documented in the spec but NOT implemented in this plan:
1. **OV3** — Move paywall flow before SaveProgress (signup) for stronger psychology lever.
2. **OV5** — Switch to lazy `PageView.builder`.
3. **OV7** — Move `generateProgress` to local `ValueNotifier` inside GeneratingScreen.
4. **Testimonial wall** — once ≥5 real testimonials are sourced from TestFlight users.
5. **Analytics emission wiring** — connecting the new `paywall_flow_*` event constants (added in Task 3) to actual emission points in screens. The constants are defined, but emission can come in a follow-up PR alongside the testimonial wall.

These should each become their own plan when prioritized.
