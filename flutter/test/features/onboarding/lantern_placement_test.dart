import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/notification_screen.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/queue_plan_screen.dart';
import 'package:sakina/features/onboarding/screens/widget_offer_screen.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/services/app_config_service.dart';

import 'screens/_test_utils.dart';

/// Where the lantern is allowed to appear in onboarding (Wave G, spec §4).
///
/// This file exists because the placement map is a set of PRODUCT decisions
/// that nothing else in the codebase enforces. The most important is a
/// prohibition, and prohibitions do not survive on convention alone:
///
/// **The lantern must never appear on the paywall.** A dim lamp beside a price
/// reads as "pay to light it" — it turns the companion into a hostage and the
/// streak into something purchasable. The lantern's brightness is earned by
/// returning, and nothing about that may look negotiable at the moment money is
/// on screen.
///
/// The absences elsewhere matter almost as much. Screen 0 lost its basmala
/// ornament on 2026-07-27 for being decoration in the place that most needed
/// air; putting a lantern there is the same mistake with better taste. And the
/// signup trio has no companion because nobody wants one watching them type a
/// password.
void main() {
  Future<List<Widget>> reelPages(WidgetTester tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider.overrideWithValue(FlowStubAppConfig.reel()),
          appSessionProvider.overrideWithValue(buildTestAppSession()),
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

  testWidgets('the paywall page carries no lantern — a lamp beside a price '
      'reads as "pay to light it"', (tester) async {
    final pages = await reelPages(tester);
    final gate = pages[onboardingReelLastPageIndex];

    // Asserted on the WIDGET TREE the page is built from rather than on a
    // rendered frame: the gate's contents are replaced wholesale in W4, and a
    // find-by-type on the live tree would silently start passing for the wrong
    // reason once the page renders something else.
    expect(
      gate,
      isNot(isA<QueuePlanScreen>()),
      reason: 'sanity: the last page is the gate, not the plan',
    );
    expect(
      find.descendant(
        of: find.byWidget(gate),
        matching: find.byType(CompanionMedallion),
        skipOffstage: false,
      ),
      findsNothing,
      reason: 'the lantern is banned from the paywall (Wave G decision 3)',
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the lantern-bearing pages are exactly the ones the spec names',
      (tester) async {
    final pages = await reelPages(tester);

    // Present: the notification ask (pendingUnlit), the widget carousel, and
    // the queue plan (endowedDim).
    expect((pages[11] as NotificationScreen).lanternVariant, isTrue,
        reason: 'the notification ask is the flow\'s highest-value placement');
    expect(pages[12], isA<WidgetOfferScreen>());
    expect(pages[9], isA<QueuePlanScreen>());

    // Absent: the hook keeps its air, the whole Wave H intake block stays
    // uncluttered, and the signup trio goes unwatched.
    for (final index in [0, 2, 3, 4, 5, 6, 7, 8, 10, 13, 14, 15, 16, 17]) {
      expect(
        find.descendant(
          of: find.byWidget(pages[index]),
          matching: find.byType(CompanionMedallion),
          skipOffstage: false,
        ),
        findsNothing,
        reason: 'reel page $index must carry no lantern',
      );
    }
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the kill-switch flows keep the untouched notification screen',
      (tester) async {
    // The reel flow is the only one that gets the lantern variant: the kill
    // switch must reproduce today's production experience exactly, and swapping
    // its illustration would make the fallback a third design rather than a
    // rollback.
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider
              .overrideWithValue(FlowStubAppConfig.trimmed()),
          appSessionProvider.overrideWithValue(buildTestAppSession()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final pages =
        ((tester.widget<PageView>(find.byType(PageView)).childrenDelegate)
                as SliverChildListDelegate)
            .children;
    final notification =
        pages.whereType<NotificationScreen>().single;
    expect(notification.lanternVariant, isFalse);
    await tester.pump(const Duration(seconds: 2));
  });
}
