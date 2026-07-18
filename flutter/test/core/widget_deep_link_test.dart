import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/widget_deep_link.dart';

void main() {
  group('parseWidgetDeepLink', () {
    test('muhasabah link → /muhasabah', () {
      expect(parseWidgetDeepLink(Uri.parse('sakina://widget/muhasabah?homeWidget')),
          '/muhasabah');
    });

    test('build-dua link → /duas (need-based, no Name seed)', () {
      expect(parseWidgetDeepLink(Uri.parse('sakina://widget/build-dua?homeWidget')),
          '/duas');
      // Any stray name_key is ignored — build-a-dua is not Name-based.
      expect(
        parseWidgetDeepLink(
            Uri.parse('sakina://widget/build-dua?name_key=al-wakil&homeWidget')),
        '/duas',
      );
    });

    test('Live Activity link (host=widget, no homeWidget marker) → /duas', () {
      // The LA `Link` uses `?source=live_activity` (NOT the home_widget
      // `?homeWidget` marker) and is delivered raw to the router. It must still
      // resolve so the router redirect can map it — else "no routes for
      // sakina://widget/build-dua?source=live_activity" (the observed 404).
      expect(
        parseWidgetDeepLink(
            Uri.parse('sakina://widget/build-dua?source=live_activity')),
        '/duas',
      );
    });

    test('non-widget link → null (ignored)', () {
      expect(parseWidgetDeepLink(Uri.parse('https://sakina.app/referral/abc')),
          isNull);
      expect(parseWidgetDeepLink(null), isNull);
    });

    test('unknown widget target → null', () {
      expect(parseWidgetDeepLink(Uri.parse('sakina://widget/unknown?homeWidget')),
          isNull);
    });
  });

  group('WidgetDeepLinkHandler', () {
    test('cold-launch URI is replayed (after first frame) to navigate', () async {
      final navigated = <String>[];
      final handler = WidgetDeepLinkHandler(
        navigate: navigated.add,
        initialUri: () async => Uri.parse('sakina://widget/muhasabah?homeWidget'),
        clicks: const Stream<Uri?>.empty(),
        postFrame: (cb) => cb(), // fire synchronously in the test
      );
      await handler.start();
      expect(navigated, ['/muhasabah']);
    });

    test('warm tap navigates immediately', () async {
      final navigated = <String>[];
      final controller = StreamController<Uri?>();
      final handler = WidgetDeepLinkHandler(
        navigate: navigated.add,
        initialUri: () async => null,
        clicks: controller.stream,
      );
      await handler.start();
      controller.add(Uri.parse('sakina://widget/build-dua?homeWidget'));
      await Future<void>.delayed(Duration.zero);
      expect(navigated, ['/duas']);
      await controller.close();
      handler.dispose();
    });

    test('fires widget_opened with target + launch + source (home widget)',
        () async {
      final events = <Map<String, dynamic>>[];
      WidgetDeepLinkHandler.onAnalyticsEvent =
          (event, props) => events.add({'event': event, ...props});
      addTearDown(() => WidgetDeepLinkHandler.onAnalyticsEvent = null);

      final controller = StreamController<Uri?>();
      final handler = WidgetDeepLinkHandler(
        navigate: (_) {},
        initialUri: () async => Uri.parse('sakina://widget/muhasabah?homeWidget'),
        clicks: controller.stream,
        postFrame: (cb) => cb(),
      );
      await handler.start(); // cold replay → muhasabah
      controller.add(Uri.parse('sakina://widget/build-dua?homeWidget')); // warm
      await Future<void>.delayed(Duration.zero);

      // No `source` param on the daily-Name widget links → default home_widget.
      expect(events, [
        {
          'event': 'widget_opened',
          'target': 'muhasabah',
          'launch': 'cold',
          'source': 'home_widget'
        },
        {
          'event': 'widget_opened',
          'target': 'build_dua',
          'launch': 'warm',
          'source': 'home_widget'
        },
      ]);
      await controller.close();
      handler.dispose();
    });

    test('duʿā-times widget tap carries source=dua_times_widget (disambiguation)',
        () async {
      final events = <Map<String, dynamic>>[];
      WidgetDeepLinkHandler.onAnalyticsEvent =
          (event, props) => events.add({'event': event, ...props});
      addTearDown(() => WidgetDeepLinkHandler.onAnalyticsEvent = null);

      final controller = StreamController<Uri?>();
      final handler = WidgetDeepLinkHandler(
        navigate: (_) {},
        initialUri: () async => null,
        clicks: controller.stream,
        postFrame: (cb) => cb(),
      );
      await handler.start();
      // The duʿā-times widget's link (SakinaDuaTimesWidget.duaDeepLinkURL).
      controller.add(
          Uri.parse('sakina://widget/build-dua?homeWidget&source=dua_times_widget'));
      await Future<void>.delayed(Duration.zero);

      expect(events.single['source'], 'dua_times_widget');
      expect(events.single['target'], 'build_dua');
      await controller.close();
      handler.dispose();
    });
  });
}
