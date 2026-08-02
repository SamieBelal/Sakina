// W6 Wave 0 — the guard on the guard.
//
// `AnalyticsService.track()` is `_mixpanel?.track(...)`. If `Mixpanel.init`
// throws, or the token is empty, `_mixpanel` stays null and EVERY event for the
// rest of the process is a silent no-op — no exception, no log, no partial
// data, just nothing. `env.json` is a compile-time define, so a build made
// without `--dart-define-from-file` produces an empty token and therefore a
// totally silent app that looks healthy.
//
// That is the single highest-leverage failure in the whole pipeline: it does
// not degrade the numbers, it deletes them, and the first symptom is an empty
// dashboard at the T0+6wk keep read.
//
// This file pins that the failure becomes KNOWABLE. It does not pin that
// analytics works — it pins that we can tell when it doesn't.
//
// See docs/superpowers/plans/2026-08-01-one-ship-06-instrumentation.md §8e#19.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_service.dart';

void main() {
  group('initialize reports its outcome instead of failing silently', () {
    test('a fresh service has not attempted initialization', () {
      expect(AnalyticsService().initStatus, AnalyticsInitStatus.notAttempted);
    });

    test('an EMPTY token is a distinct, nameable state — not "fine"', () async {
      // The env.json footgun. Previously `if (token.isEmpty) return;` made a
      // misconfigured build indistinguishable from a healthy one.
      final service = AnalyticsService();
      await service.initialize('');

      expect(service.initStatus, AnalyticsInitStatus.missingToken);
      expect(service.isHealthy, isFalse,
          reason: 'a build with no Mixpanel token is not healthy, and the app '
              'must be able to say so rather than discovering it at the read');
    });

    test('a THROWING init is caught, recorded, and does not propagate',
        () async {
      // Under flutter_test there is no Mixpanel platform channel, so
      // `Mixpanel.init` throws MissingPluginException — which is exactly the
      // shape of the production failure (a platform-channel error during a
      // plugin-registration race). Before the guard this threw out of
      // `initialize`, and `main.dart:300` awaits it unguarded, so it took cold
      // launch with it.
      final service = AnalyticsService();

      await expectLater(service.initialize('a-token'), completes);
      expect(service.initStatus, AnalyticsInitStatus.failed);
      expect(service.isHealthy, isFalse);
      expect(service.initError, isNotNull,
          reason: 'the cause must be retained — "it failed" without "why" is '
              'not actionable at 3am');
    });

    test('a failure notifies the static hook, so the app can surface it',
        () async {
      // Same static-hook indirection the services layer already uses for
      // analytics (no Riverpod in lib/services/). This is what lets main.dart
      // report the failure without AnalyticsService importing anything.
      Object? reported;
      AnalyticsService.onInitFailure = (error, status) => reported = error;
      addTearDown(() => AnalyticsService.onInitFailure = null);

      await AnalyticsService().initialize('a-token');

      expect(reported, isNotNull);
    });

    test('the empty-token path notifies the hook too', () async {
      AnalyticsInitStatus? status;
      AnalyticsService.onInitFailure = (_, s) => status = s;
      addTearDown(() => AnalyticsService.onInitFailure = null);

      await AnalyticsService().initialize('');

      expect(status, AnalyticsInitStatus.missingToken,
          reason: 'a missing token is the MORE likely of the two failures and '
              'the easier to miss — it must not be the quiet one');
    });

    test('a null hook cannot break initialization', () async {
      AnalyticsService.onInitFailure = null;
      await expectLater(AnalyticsService().initialize(''), completes);
    });

    test('a THROWING hook cannot break initialization either', () async {
      // The guard must not become the thing that crashes cold launch.
      AnalyticsService.onInitFailure = (_, __) => throw StateError('reporter');
      addTearDown(() => AnalyticsService.onInitFailure = null);

      await expectLater(AnalyticsService().initialize(''), completes);
    });
  });
}
