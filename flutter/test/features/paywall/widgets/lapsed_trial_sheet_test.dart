import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/lapsed_trial_sheet.dart';
import 'package:sakina/features/tour/providers/tour_route_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  // `show()` awaits the free-tier cohort, which reads SharedPreferences.
  // Without a mock store `getInstance()` HANGS under flutter_test rather than
  // throwing — the sheet would simply never appear and every show() test would
  // fail on a missing widget with no hint as to why.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LapsedTrialSheet', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 7,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.byType(LapsedTrialSheet), findsOneWidget);
    });

    testWidgets('legacy headline is Welcome back to one a day', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 7,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.text('Welcome back to one a day'), findsOneWidget);
    });

    testWidgets('reel_v1 headline does not promise a daily reflection',
        (tester) async {
      // On `reel_v1` reflections come from a 3-per-week Monday pool; only the
      // Name discovery is daily. The legacy headline names the wrong thing.
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 7,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
            isNewCohort: true,
          ),
        ),
      );
      expect(find.text('Welcome back to your daily Name'), findsOneWidget);
      expect(find.text('Welcome back to one a day'), findsNothing);
    });

    testWidgets('reel_v1 fallback names the Monday reset, not a daily one',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 0,
            daysActiveDuringTrial: 0,
            onUpgrade: () {},
            onDismiss: () {},
            isNewCohort: true,
          ),
        ),
      );
      expect(
        find.text(
          "You've explored what Premium feels like. One Name a day stays "
          'free, and your free reflections and duʿās return together '
          'each Monday — or unlock unlimited again.',
        ),
        findsOneWidget,
      );
      // The legacy promise must never reach a reel_v1 user: they do not get
      // a reflection a day, so "yours forever" would be a false promise on a
      // surface that is asking for money.
      expect(find.textContaining('One reflection a day'), findsNothing);
    });

    testWidgets('no cohort names a trial LENGTH', (tester) async {
      // Regression for W5 Wave B.5. The store can change the trial from 3
      // days to 7 without a release; any hardcoded duration here silently
      // becomes a lie at that moment.
      for (final newCohort in [false, true]) {
        for (final moments in [0, 1, 5]) {
          await tester.pumpWidget(
            _wrap(
              LapsedTrialSheet(
                momentsDuringTrial: moments,
                daysActiveDuringTrial: 2,
                onUpgrade: () {},
                onDismiss: () {},
                isNewCohort: newCohort,
              ),
            ),
          );
          for (final needle in ['3-day', '7-day', '3 day', '7 day']) {
            expect(
              find.textContaining(needle),
              findsNothing,
              reason: 'trial length "$needle" leaked '
                  '(isNewCohort=$newCohort, moments=$moments)',
            );
          }
        }
      }
    });

    testWidgets('falls back to generic copy when momentsDuringTrial is 0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 0,
            daysActiveDuringTrial: 0,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(
        find.text(
          "You've explored what Premium feels like. One reflection a day "
          'is yours forever — or unlock unlimited again.',
        ),
        findsOneWidget,
      );
      // The interpolation form must NOT show in the fallback case.
      expect(find.textContaining('In your trial'), findsNothing);
    });

    testWidgets('falls back when moments is 0 but days is non-zero',
        (tester) async {
      // Even if days happens to be non-zero, zero moments means we
      // couldn't resolve activity meaningfully — still fall back.
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 0,
            daysActiveDuringTrial: 3,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.textContaining("You've explored what Premium feels like"),
          findsOneWidget);
    });

    testWidgets('singular grammar at moments=1, days=1 (1 time, 1 day)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 1,
            daysActiveDuringTrial: 1,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(
        find.text(
          'In your trial, you showed up 1 time across 1 day. '
          'Premium keeps that pace going.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('plural grammar at moments=5, days=2 (5 times, 2 days)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 5,
            daysActiveDuringTrial: 2,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(
        find.text(
          'In your trial, you showed up 5 times across 2 days. '
          'Premium keeps that pace going.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'body never contains the word "reflected" '
        '(regression — was the bug)', (tester) async {
      // Pump several representative cases — fallback, singular, plural —
      // and assert no rendered Text contains "reflected". Locks in the
      // fix for the P3 bug where building duas / discovering names was
      // reported as "you reflected N times" in the lapsed-trial copy.
      final cases = <(int, int)>[
        (0, 0),
        (1, 1),
        (5, 2),
        (12, 3),
      ];
      for (final (moments, days) in cases) {
        await tester.pumpWidget(
          _wrap(
            LapsedTrialSheet(
              momentsDuringTrial: moments,
              daysActiveDuringTrial: days,
              onUpgrade: () {},
              onDismiss: () {},
            ),
          ),
        );
        expect(
          find.textContaining('reflected'),
          findsNothing,
          reason:
              'moments=$moments days=$days: copy must not say "reflected" — '
              'the displayed count includes built duas + discovered names too',
        );
      }
    });

    testWidgets('tapping primary invokes onUpgrade', (tester) async {
      var upgraded = 0;
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 4,
            daysActiveDuringTrial: 2,
            onUpgrade: () => upgraded++,
            onDismiss: () {},
          ),
        ),
      );
      await tester.tap(find.text('Unlock unlimited'));
      await tester.pump();
      expect(upgraded, 1);
    });

    testWidgets('tapping secondary invokes onDismiss', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        _wrap(
          LapsedTrialSheet(
            momentsDuringTrial: 4,
            daysActiveDuringTrial: 2,
            onUpgrade: () {},
            onDismiss: () => dismissed++,
          ),
        ),
      );
      await tester.tap(find.text('Maybe later'));
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('show() forwards onDismiss to the caller AND pops the sheet',
        (tester) async {
      // Pins the reverse-trial fix: the static show() now accepts an onDismiss
      // hook (so the caller can fire soft_gate_dismissed) and still closes the
      // modal. Regression for F2 — the sheet must dismiss on "Maybe later".
      var dismissed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => LapsedTrialSheet.show(
                context,
                momentsDuringTrial: 4,
                daysActiveDuringTrial: 2,
                onUpgrade: () {},
                onDismiss: () => dismissed++,
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show sheet'));
      await tester.pumpAndSettle();
      expect(find.byType(LapsedTrialSheet), findsOneWidget);

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();
      expect(dismissed, 1, reason: 'caller onDismiss must fire');
      expect(find.byType(LapsedTrialSheet), findsNothing,
          reason: 'sheet must be popped after dismiss');
    });

    testWidgets(
        'show() fires onDismiss exactly once when dismissed via a NON-button '
        'path (barrier tap / swipe-down / Android back)', (tester) async {
      // F2 regression: a showModalBottomSheet can be dismissed by tapping the
      // scrim, swiping down, or pressing Android back — none of which run the
      // widget's "Maybe later" secondary button. The impression already fired
      // (trial_paywall_surfaced), so soft_gate_dismissed MUST still fire on
      // these paths or the loss metric undercounts.
      var dismissed = 0;
      late BuildContext rootContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              rootContext = context;
              return TextButton(
                onPressed: () => LapsedTrialSheet.show(
                  context,
                  momentsDuringTrial: 4,
                  daysActiveDuringTrial: 2,
                  onUpgrade: () {},
                  onDismiss: () => dismissed++,
                ),
                child: const Text('Show sheet'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Show sheet'));
      await tester.pumpAndSettle();
      expect(find.byType(LapsedTrialSheet), findsOneWidget);

      // Simulate a barrier/swipe/back dismissal: pop the route WITHOUT
      // touching either of the sheet's buttons.
      Navigator.of(rootContext, rootNavigator: true).maybePop();
      await tester.pumpAndSettle();

      expect(find.byType(LapsedTrialSheet), findsNothing,
          reason: 'sheet must be gone after a non-button dismissal');
      expect(dismissed, 1,
          reason: 'onDismiss must fire on barrier/swipe/back dismissal too');
    });

    testWidgets('show() does NOT fire onDismiss when onUpgrade is taken',
        (tester) async {
      var dismissed = 0;
      var upgraded = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => LapsedTrialSheet.show(
                context,
                momentsDuringTrial: 4,
                daysActiveDuringTrial: 2,
                onUpgrade: () => upgraded++,
                onDismiss: () => dismissed++,
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unlock unlimited'));
      await tester.pumpAndSettle();

      expect(upgraded, 1, reason: 'caller onUpgrade must fire');
      expect(dismissed, 0,
          reason: 'taking the upgrade path must never fire onDismiss');
    });

    testWidgets(
        'show() fires onDismiss exactly once on the button path '
        '(no double-fire with the route-completion future)', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => LapsedTrialSheet.show(
                context,
                momentsDuringTrial: 4,
                daysActiveDuringTrial: 2,
                onUpgrade: () {},
                onDismiss: () => dismissed++,
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();

      expect(dismissed, 1,
          reason: 'button + future completion must not double-fire onDismiss');
    });

    testWidgets('show names its route so the guided tour is suppressed',
        (tester) async {
      final observer = TourRouteObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => LapsedTrialSheet.show(
                context,
                momentsDuringTrial: 4,
                daysActiveDuringTrial: 2,
                onUpgrade: () {},
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show sheet'));
      await tester.pumpAndSettle();

      expect(observer.topRouteName.value, 'LapsedTrialSheet');
      expect(observer.isBlockingRouteOnTop, true);
    });
  });
}
