import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart'
    show GatedFeature;
import 'package:sakina/features/tour/providers/tour_route_observer.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('DailyCapSheet', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.reflect,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.byType(DailyCapSheet), findsOneWidget);
    });

    final headlineCases = <GatedFeature, String>{
      GatedFeature.reflect: "You've reflected today",
      GatedFeature.builtDua: "You've built today's dua",
      GatedFeature.discoverName: "You've discovered today's Name",
    };

    final bodyCases = <GatedFeature, String>{
      GatedFeature.reflect:
          "Tomorrow's reflection is on us. Or unlock unlimited now.",
      GatedFeature.builtDua:
          "Tomorrow's dua is on us. Or unlock unlimited now.",
      GatedFeature.discoverName:
          "Tomorrow's discovery is on us. Or unlock unlimited now.",
    };

    for (final entry in headlineCases.entries) {
      testWidgets('renders default copy for ${entry.key}', (tester) async {
        await tester.pumpWidget(
          _wrap(
            DailyCapSheet(
              feature: entry.key,
              onUpgrade: () {},
              onDismiss: () {},
            ),
          ),
        );
        expect(find.text(entry.value), findsOneWidget);
        expect(find.text(bodyCases[entry.key]!), findsOneWidget);
      });
    }

    testWidgets('uses headlineOverride when provided', (tester) async {
      const override = 'Beautiful work on your streak';
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
            feature: GatedFeature.reflect,
            headlineOverride: override,
            onUpgrade: () {},
            onDismiss: () {},
          ),
        ),
      );
      expect(find.text(override), findsOneWidget);
      // Default headline must NOT appear when override is provided.
      expect(find.text("You've reflected today"), findsNothing);
      // Body still uses feature-default copy per spec.
      expect(
        find.text("Tomorrow's reflection is on us. Or unlock unlimited now."),
        findsOneWidget,
      );
    });

    testWidgets('tapping primary invokes onUpgrade', (tester) async {
      var upgraded = 0;
      await tester.pumpWidget(
        _wrap(
          DailyCapSheet(
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
          DailyCapSheet(
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
              onPressed: () => DailyCapSheet.show(
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

      expect(observer.topRouteName.value, 'DailyCapSheet');
      expect(observer.isBlockingRouteOnTop, true);
    });
  });
}
