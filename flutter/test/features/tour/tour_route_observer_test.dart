import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tour/providers/tour_route_observer.dart';

void main() {
  group('TourRouteObserver', () {
    test('didPush updates topRouteName', () {
      final obs = TourRouteObserver();
      final route = _FakeRoute('Foo');
      obs.didPush(route, null);
      expect(obs.topRouteName.value, 'Foo');
    });

    test('didPop reverts to previous route name', () {
      final obs = TourRouteObserver();
      final r1 = _FakeRoute('Foo');
      final r2 = _FakeRoute('Bar');
      obs.didPush(r1, null);
      obs.didPush(r2, r1);
      expect(obs.topRouteName.value, 'Bar');
      obs.didPop(r2, r1);
      expect(obs.topRouteName.value, 'Foo');
    });

    test('isBlockingRouteOnTop true for NameRevealOverlay', () {
      final obs = TourRouteObserver();
      obs.didPush(_FakeRoute('NameRevealOverlay'), null);
      expect(obs.isBlockingRouteOnTop, true);
    });

    test('isBlockingRouteOnTop false for unknown route', () {
      final obs = TourRouteObserver();
      obs.didPush(_FakeRoute('SomeRandomRoute'), null);
      expect(obs.isBlockingRouteOnTop, false);
    });

    test('blockingRouteNames matches expected set', () {
      expect(TourRouteObserver.blockingRouteNames, {
        'NameRevealOverlay',
        'LevelUpOverlay',
        'LapsedTrialSheet',
        'FirstStepsOverlay',
        'DailyLaunchOverlay',
      });
    });

    test('onPop callback fires with route + previous', () {
      final obs = TourRouteObserver();
      Route<dynamic>? capturedRoute;
      Route<dynamic>? capturedPrev;
      obs.onPop = (r, p) {
        capturedRoute = r;
        capturedPrev = p;
      };
      final r1 = _FakeRoute('Home');
      final r2 = _FakeRoute('DuaDetailPage');
      obs.didPush(r1, null);
      obs.didPush(r2, r1);
      obs.didPop(r2, r1);
      expect(capturedRoute, r2);
      expect(capturedPrev, r1);
    });
  });
}

class _FakeRoute extends Route<void> {
  _FakeRoute(String name) : super(settings: RouteSettings(name: name));
}
