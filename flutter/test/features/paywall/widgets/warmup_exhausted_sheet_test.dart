import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/features/tour/providers/tour_route_observer.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('WarmupExhaustedSheet', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WarmupExhaustedSheet(
            feature: GatedFeature.reflect,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.byType(WarmupExhaustedSheet), findsOneWidget);
    });

    final cases = <GatedFeature, String>{
      GatedFeature.reflect: "You've completed your free reflections",
      GatedFeature.builtDua: "You've built your free duas",
      GatedFeature.discoverName: "You've discovered your free Names",
    };

    for (final entry in cases.entries) {
      testWidgets('renders correct headline for ${entry.key}', (tester) async {
        await tester.pumpWidget(
          _wrap(
            WarmupExhaustedSheet(
              feature: entry.key,
              onUpgrade: () {},
              onDismiss: () {},
            ),
          ),
        );
        expect(find.text(entry.value), findsOneWidget);
        expect(
          find.text("From tomorrow you'll get one a day. Or unlock unlimited now."),
          findsOneWidget,
        );
      });
    }

    testWidgets('renders primary and secondary CTAs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          WarmupExhaustedSheet(
            feature: GatedFeature.reflect,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.text('Unlock unlimited'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });

    testWidgets('tapping primary invokes onUpgrade', (tester) async {
      var upgraded = 0;
      await tester.pumpWidget(
        _wrap(
          WarmupExhaustedSheet(
            feature: GatedFeature.builtDua,
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
          WarmupExhaustedSheet(
            feature: GatedFeature.discoverName,
            onUpgrade: () {},
            onDismiss: () => dismissed++,
          ),
        ),
      );
      await tester.tap(find.text('Maybe later'));
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('show names its route so the guided tour is suppressed',
        (tester) async {
      // Regression for the latent navigator bug: the sheet must push on the
      // ROOT navigator with a named route so the singleton tourRouteObserver
      // (wired to the root GoRouter) registers it and the tour overlay
      // suppresses itself. Without useRootNavigator + routeSettings name the
      // sheet pushes on the nested shell navigator, the root observer never
      // sees it, and an in-flight guided tour overlaps it AND steals its taps.
      final observer = TourRouteObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => WarmupExhaustedSheet.show(
                context,
                feature: GatedFeature.reflect,
                onUpgrade: () {},
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show sheet'));
      await tester.pumpAndSettle();

      expect(observer.topRouteName.value, 'WarmupExhaustedSheet');
      expect(observer.isBlockingRouteOnTop, true);
    });
  });
}
