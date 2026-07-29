import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/aspiration_screen_reel.dart';
import 'package:sakina/features/onboarding/screens/carrying_duration_screen.dart';
import 'package:sakina/features/onboarding/screens/heaviest_time_screen.dart';
import 'package:sakina/features/onboarding/screens/told_anyone_screen.dart';
import 'package:sakina/features/onboarding/screens/names_known_screen.dart';
import 'package:sakina/features/onboarding/screens/help_chips_screen.dart';
import 'package:sakina/features/onboarding/screens/daily_time_screen.dart';
import 'package:sakina/features/onboarding/screens/intake_note_screen.dart';
import 'package:sakina/features/onboarding/screens/rating_gate_screen.dart';
import 'package:sakina/features/onboarding/screens/hook_problem_screen.dart';
import 'package:sakina/features/onboarding/screens/name_input_screen.dart';
import 'package:sakina/features/onboarding/screens/notification_screen.dart';
import 'package:sakina/features/onboarding/screens/onboarding_reveal_screen.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/queue_plan_screen.dart';
import 'package:sakina/features/onboarding/screens/widget_offer_screen.dart';
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
    // Wave H — the intake block (7 questions), then the payoff, then the asks.
    2: CarryingDurationScreen,
    3: HeaviestTimeScreen,
    4: ToldAnyoneScreen,
    5: NamesKnownScreen,
    6: HelpChipsScreen,
    7: DailyTimeScreen,
    8: IntakeNoteScreen,
    9: QueuePlanScreen,
    10: RatingGateScreen,
    11: NotificationScreen,
    12: WidgetOfferScreen,
    13: SourceQuestionScreen,
    14: NameInputScreen,
    15: SaveProgressScreen,
    16: SignUpEmailScreen,
    17: SignUpPasswordScreen,
    18: OnboardingFinalGate,
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

  testWidgets("the 19 pages are in the plan's order", (tester) async {
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
    final firstAfterReveal =
        children[onboardingReelNoBackBeforeIndex] as CarryingDurationScreen;
    expect(firstAfterReveal.onBack, isNull);

    // Everything after it CAN go back — only the reveal is sealed off.
    expect((children[3] as HeaviestTimeScreen).onBack, isNotNull);
    expect((children[14] as NameInputScreen).onBack, isNotNull);
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

  testWidgets('the progress bar is hidden on the hook, reveal and gate',
      (tester) async {
    final children = await pumpReel(tester);
    // Hook and reveal are bare full-screen surfaces; the rating gate is a gate
    // with its own identity; the paywall is the paywall. The other fifteen fill
    // segments 0..14 so the bar COMPLETES on the password screen.
    //
    // The queue plan (index 9) joined the run on 2026-07-29 at
    // `onboardingReelPlanSegment`, which is why everything from notifications
    // on is one higher than it was. It is asserted through the constant rather
    // than a literal because the screen reads that same constant internally —
    // a literal here would let the two drift and still pass.
    expect((children[2] as CarryingDurationScreen).progressSegment, 0);
    expect((children[3] as HeaviestTimeScreen).progressSegment, 1);
    expect((children[4] as ToldAnyoneScreen).progressSegment, 2);
    expect((children[5] as NamesKnownScreen).progressSegment, 3);
    expect((children[6] as HelpChipsScreen).progressSegment, 4);
    expect((children[7] as DailyTimeScreen).progressSegment, 5);
    expect((children[8] as IntakeNoteScreen).progressSegment, 6);
    expect(children[9], isA<QueuePlanScreen>());
    expect(onboardingReelPlanSegment, 7);
    expect((children[11] as NotificationScreen).progressSegment, 8);
    expect((children[12] as WidgetOfferScreen).progressSegment, 9);
    expect((children[13] as SourceQuestionScreen).progressSegment, 10);
    expect((children[14] as NameInputScreen).progressSegment, 11);
    expect((children[15] as SaveProgressScreen).progressSegment, 12);
    expect((children[16] as SignUpEmailScreen).progressSegment, 13);
    expect((children[17] as SignUpPasswordScreen).progressSegment, 14);
    expect(onboardingReelTotalSegments, 15);
    expect(
      (children[17] as SignUpPasswordScreen).progressSegment,
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
    for (final i in [2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14, 15, 16, 17]) {
      final w = children[i] as dynamic;
      expect(w.totalSegments, onboardingReelTotalSegments,
          reason: 'reel page $i must be told the short bar length');
    }
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
      'the reused legacy screens are told their REEL page index, not their '
      'kill-switch one', (tester) async {
    // These three gate autofocus on "am I the page on display". Left at their
    // trimmed-flow constants they would autofocus on the wrong reel page (or
    // never), which is the class of bug the pageIndex param removes.
    final children = await pumpReel(tester);
    expect((children[14] as NameInputScreen).pageIndex, 14);
    expect((children[16] as SignUpEmailScreen).pageIndex,
        onboardingReelEmailPageIndex);
    expect((children[17] as SignUpPasswordScreen).pageIndex,
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
    //
    // `reminder_time` is deliberately NOT in this list. Wave H deleted that
    // page from the reel order — "When is it heaviest?" derives the reminder in
    // the same state mutation, so the answer IS the schedule. The kill-switch
    // flows still have the screen and still emit the name, so the two orders
    // legitimately diverge here; a funnel joining on it now compares the reel
    // flow's absence against the trimmed flow's step, which is the truth.
    for (final shared in [
      'notifications',
      'name_input',
      'save_progress',
      'signup_email',
      'signup_password',
      'rating_gate',
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
    expect(AnalyticsEvents.reelStepNames[2], 'reel_carrying_duration');
    // Wave H moved the source question off the emotional peak to page 13. The
    // step_id is unchanged on purpose — it is the funnel's join key across
    // page-order changes, so only the index moves.
    expect(AnalyticsEvents.reelStepNames[13], 'reel_source');
  });
}
