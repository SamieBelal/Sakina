import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/aspiration_screen_reel.dart';
import 'package:sakina/features/onboarding/screens/carrying_duration_screen.dart';
import 'package:sakina/features/onboarding/screens/hook_problem_screen.dart';
import 'package:sakina/features/onboarding/screens/name_input_screen.dart';
import 'package:sakina/features/onboarding/screens/notification_screen.dart';
import 'package:sakina/features/onboarding/screens/onboarding_reveal_screen.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/queue_plan_screen.dart';
import 'package:sakina/features/onboarding/screens/reminder_time_screen.dart';
import 'package:sakina/features/onboarding/screens/save_progress_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_email_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_password_screen.dart';
import 'package:sakina/features/onboarding/screens/source_question_screen.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/app_config_service.dart';

import 'screens/_test_utils.dart';

/// One Ship W2-E1 — the reel flow's PageView assembly.
///
/// This file pins the ORDER and the structural rules that order encodes:
/// nothing goes back past the reveal, and the bar is hidden on exactly four
/// pages. The individual screens have their own tests; what can only be
/// verified here is that they are wired together in the sequence the plan
/// specifies, with the right index at each slot.
void main() {
  /// The canonical order (see the index constants in onboarding_provider.dart).
  const reelOrder = <int, Type>{
    0: HookProblemScreen,
    1: OnboardingRevealScreen,
    2: SourceQuestionScreen,
    3: CarryingDurationScreen,
    4: AspirationScreenReel,
    5: ReminderTimeScreen,
    6: NotificationScreen,
    7: QueuePlanScreen,
    8: NameInputScreen,
    9: SaveProgressScreen,
    10: SignUpEmailScreen,
    11: SignUpPasswordScreen,
    12: OnboardingFinalGate,
  };

  Future<List<Widget>> pumpReel(WidgetTester tester, {int? atPage}) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider.overrideWithValue(FlowStubAppConfig.reel()),
          appSessionProvider.overrideWithValue(buildTestAppSession()),
          if (atPage != null)
            cachedOnboardingStateProvider
                .overrideWithValue(OnboardingState(currentPage: atPage)),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final pageView = tester.widget<PageView>(find.byType(PageView));
    return (pageView.childrenDelegate as SliverChildListDelegate).children;
  }

  testWidgets("the 13 pages are in the plan's order", (tester) async {
    final children = await pumpReel(tester);
    expect(children, hasLength(reelOrder.length));
    reelOrder.forEach((index, type) {
      expect(
        children[index].runtimeType,
        type,
        reason: 'reel page $index must be $type',
      );
    });
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the named index constants point at the right screens',
      (tester) async {
    final children = await pumpReel(tester);
    expect(children[onboardingReelHookPageIndex], isA<HookProblemScreen>());
    expect(
      children[onboardingReelRevealPageIndex],
      isA<OnboardingRevealScreen>(),
    );
    expect(children[onboardingReelEmailPageIndex], isA<SignUpEmailScreen>());
    expect(
      children[onboardingReelPasswordPageIndex],
      isA<SignUpPasswordScreen>(),
    );
    expect(children[onboardingReelLastPageIndex], isA<OnboardingFinalGate>());
    // Social auth lands on the final gate: the reveal and the plan both ran
    // pre-signup, so there is no interstitial left to show (W2-E2).
    expect(onboardingReelPostSignupPageIndex, onboardingReelLastPageIndex);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the page after the reveal has NO back affordance',
      (tester) async {
    // The one visible expression of the no-back-past-the-reveal rule.
    // `canNavigateOnboarding` (pinned exhaustively in onboarding_tri_flow_test)
    // is the enforcement behind it; this is what stops us shipping a back
    // button that silently does nothing.
    final children = await pumpReel(tester);
    final source =
        children[onboardingReelNoBackBeforeIndex] as SourceQuestionScreen;
    expect(source.onBack, isNull);

    // Everything after it CAN go back — only the reveal is sealed off.
    expect((children[3] as CarryingDurationScreen).onBack, isNotNull);
    expect((children[8] as NameInputScreen).onBack, isNotNull);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the hook is the first page, so it has no back affordance either',
      (tester) async {
    final children = await pumpReel(tester);
    expect(
      (children[onboardingReelHookPageIndex] as HookProblemScreen).onBack,
      isNull,
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the reveal gets ONE latch for the whole run', (tester) async {
    // Its own doc comment: the flags cannot live in the reveal's State, or a
    // re-mount re-awards the card and re-emits the deck telemetry.
    final children = await pumpReel(tester);
    final reveal = children[1] as OnboardingRevealScreen;
    expect(reveal.latch, isNotNull);

    // Same instance across rebuilds of the same run.
    await tester.pump();
    final again = ((tester.widget<PageView>(find.byType(PageView)).
                childrenDelegate as SliverChildListDelegate)
            .children[1] as OnboardingRevealScreen)
        .latch;
    expect(identical(reveal.latch, again), isTrue);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the progress bar is hidden on the hook, reveal, plan and gate',
      (tester) async {
    final children = await pumpReel(tester);
    // Hook and reveal are bare full-screen surfaces; the plan is a payoff with
    // its own header; the gate is the paywall. The other nine fill segments
    // 0..8 so the bar COMPLETES on the password screen.
    expect((children[2] as SourceQuestionScreen).progressSegment, 0);
    expect((children[3] as CarryingDurationScreen).progressSegment, 1);
    expect((children[4] as AspirationScreenReel).progressSegment, 2);
    expect((children[5] as ReminderTimeScreen).progressSegment, 3);
    expect((children[6] as NotificationScreen).progressSegment, 4);
    expect((children[8] as NameInputScreen).progressSegment, 5);
    expect((children[9] as SaveProgressScreen).progressSegment, 6);
    expect((children[10] as SignUpEmailScreen).progressSegment, 7);
    expect((children[11] as SignUpPasswordScreen).progressSegment, 8);
    expect(onboardingReelTotalSegments, 9);
    expect(
      (children[11] as SignUpPasswordScreen).progressSegment,
      onboardingReelTotalSegments - 1,
      reason: 'the bar must complete on the last bar-visible page, not vanish '
          'part-full the way the pre-fix 25-segment bar did',
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('every bar-visible reel page is told the SHORT bar length',
      (tester) async {
    // Without this the reused legacy screens would light segment 5 of 23 and
    // the reel bar would look barely started at the finish line.
    final children = await pumpReel(tester);
    expect((children[5] as ReminderTimeScreen).totalSegments,
        onboardingReelTotalSegments);
    expect((children[6] as NotificationScreen).totalSegments,
        onboardingReelTotalSegments);
    expect((children[8] as NameInputScreen).totalSegments,
        onboardingReelTotalSegments);
    expect((children[9] as SaveProgressScreen).totalSegments,
        onboardingReelTotalSegments);
    expect((children[10] as SignUpEmailScreen).totalSegments,
        onboardingReelTotalSegments);
    expect((children[11] as SignUpPasswordScreen).totalSegments,
        onboardingReelTotalSegments);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
      'the reused legacy screens are told their REEL page index, not their '
      'kill-switch one', (tester) async {
    // These three gate autofocus on "am I the page on display". Left at their
    // trimmed-flow constants they would autofocus on the wrong reel page (or
    // never), which is the class of bug the pageIndex param removes.
    final children = await pumpReel(tester);
    expect((children[8] as NameInputScreen).pageIndex, 8);
    expect((children[10] as SignUpEmailScreen).pageIndex,
        onboardingReelEmailPageIndex);
    expect((children[11] as SignUpPasswordScreen).pageIndex,
        onboardingReelPasswordPageIndex);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the reel step-name map covers every page with a stable id',
      (tester) async {
    final children = await pumpReel(tester);
    for (var i = 0; i < children.length; i++) {
      expect(
        AnalyticsEvents.reelStepNames[i],
        isNotNull,
        reason: 'reel page $i has no step_name, so its funnel step would '
            'report as "unknown"',
      );
    }
    expect(AnalyticsEvents.reelStepNames, hasLength(children.length));
    expect(
      AnalyticsEvents.stepNamesFor(trimmed: true, reel: true),
      same(AnalyticsEvents.reelStepNames),
      reason: 'reel must win over trimmed — it is its own page order',
    );
    await tester.pump(const Duration(seconds: 2));
  });

  test('the reused screens keep their existing step_names across flows', () {
    // A funnel keyed on step_name has to join the same step in all three
    // flows; only the reel-only screens carry the `reel_` prefix.
    for (final shared in [
      'reminder_time',
      'notifications',
      'name_input',
      'save_progress',
      'signup_email',
      'signup_password',
      'paywall',
    ]) {
      expect(
        AnalyticsEvents.reelStepNames.values,
        contains(shared),
        reason: '$shared must keep the name the trimmed flow uses',
      );
      expect(AnalyticsEvents.trimmedStepNames.values, contains(shared));
    }
    expect(AnalyticsEvents.reelStepNames[0], 'reel_hook');
    expect(AnalyticsEvents.reelStepNames[1], 'reel_reveal');
    expect(AnalyticsEvents.reelStepNames[2], 'reel_source');
  });
}
