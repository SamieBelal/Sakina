import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tour/providers/tour_route_observer.dart';
import 'package:sakina/widgets/upgrade_required_sheet.dart';

void main() {
  group('UpgradeRequiredSheet', () {
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
              onPressed: () => UpgradeRequiredSheet.show(
                context,
                currentCount: 5,
                featureLabel: 'reflection',
              ),
              child: const Text('Show sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show sheet'));
      await tester.pumpAndSettle();

      expect(observer.topRouteName.value, 'UpgradeRequiredSheet');
      expect(observer.isBlockingRouteOnTop, true);
    });
  });

  group('blocking-route linkage', () {
    // Defense against regression: every blocking modal that root-pushes a
    // named route MUST also appear in TourRouteObserver.blockingRouteNames,
    // otherwise the tour won't suppress itself and will steal the sheet's
    // taps. A future sheet root-pushed but omitted from the set is the exact
    // class of bug this whole change fixes — pin it here.
    const requiredBlockingNames = <String>[
      'DailyCapSheet',
      'WarmupExhaustedSheet',
      'UpgradeRequiredSheet',
      'LapsedTrialSheet',
    ];

    for (final name in requiredBlockingNames) {
      test('$name is a member of TourRouteObserver.blockingRouteNames', () {
        expect(TourRouteObserver.blockingRouteNames, contains(name));
      });
    }
  });
}
