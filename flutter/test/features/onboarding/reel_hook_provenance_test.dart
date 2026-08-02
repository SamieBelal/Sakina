import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/source_question_screen.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:sakina/services/reel_deep_link_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/_test_utils.dart';

/// W6 Wave A / D2 — provenance of the `reel_hook` / `reel_hook_source` pair:
/// `unknown` at onboarding entry → `deep_link` once a `sakina://reel/<id>`
/// arrival drains → `self_report` once the source screen is answered. The two
/// properties must always move together — a caller that upgrades one without
/// the other produces a reading that looks authoritative and is not (the
/// docstring on `AnalyticsEvents.propReelHook`).
///
/// **MUTATION THAT MUST FAIL THESE TESTS:** in either call site (the deep-link
/// drain in `onboarding_screen.dart`, or the `onAnswer` handler in
/// `source_question_screen.dart`), register `propReelHook` without
/// `propReelHookSource` (or vice versa). Verified by hand on the source-screen
/// call site: dropping the `propReelHookSource` line from the map made the
/// "both keys present together" assertion below fail while the
/// `propReelHook` assertion kept passing — exactly the silent half-upgrade the
/// pairing rule exists to catch.
class _SuperPropSpy extends AnalyticsService {
  final List<Map<String, dynamic>> calls = [];

  @override
  void setSuperProperties(Map<String, dynamic> props) {
    calls.add(Map<String, dynamic>.from(props));
  }

  @override
  void track(String event, {Map<String, dynamic>? properties}) {}

  @override
  void timeEvent(String event) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('onboarding entry → deep-link upgrade (OnboardingScreen)', () {
    testWidgets('unknown at entry, then upgraded together to the deep link',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        pendingReelArrivalPrefsKey: jsonEncode({'reel_id': 'r-1234'}),
      });
      final analytics = _SuperPropSpy();
      useOnboardingViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigServiceProvider
                .overrideWithValue(FlowStubAppConfig.reel()),
            appSessionProvider.overrideWithValue(buildTestAppSession()),
            analyticsProvider.overrideWithValue(analytics),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      // Flow resolution, then the deep-link drain — both async, same wait
      // shape as hook_deep_link_prefill_test.dart.
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 700));

      expect(analytics.calls, isNotEmpty);
      // First registration (entry): both unknown.
      final entry = analytics.calls.first;
      expect(entry[AnalyticsEvents.propReelHook],
          AnalyticsEvents.reelHookSourceUnknown);
      expect(entry[AnalyticsEvents.propReelHookSource],
          AnalyticsEvents.reelHookSourceUnknown);

      // A later registration upgrades BOTH to the confirmed deep link, in the
      // SAME call.
      final upgrade = analytics.calls.firstWhere(
        (c) => c[AnalyticsEvents.propReelHook] == 'r-1234',
        orElse: () => const {},
      );
      expect(upgrade, isNotEmpty,
          reason: 'the deep-link drain never upgraded reel_hook');
      expect(upgrade[AnalyticsEvents.propReelHookSource],
          AnalyticsEvents.reelHookSourceDeepLink,
          reason: 'reel_hook and reel_hook_source must upgrade in the SAME '
              'call — a value without its provenance looks authoritative and '
              'is not');

      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('no pending arrival: stays unknown, never upgraded',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final analytics = _SuperPropSpy();
      useOnboardingViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigServiceProvider
                .overrideWithValue(FlowStubAppConfig.reel()),
            appSessionProvider.overrideWithValue(buildTestAppSession()),
            analyticsProvider.overrideWithValue(analytics),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        analytics.calls
            .any((c) => c[AnalyticsEvents.propReelHookSource] !=
                AnalyticsEvents.reelHookSourceUnknown),
        isFalse,
        reason: 'with no arrival to drain, the pair must never move off '
            'unknown',
      );

      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('the source screen upgrades the pair to self_report', () {
    testWidgets('tapping an option upgrades reel_hook / reel_hook_source '
        'TOGETHER, at the same call site as reel_source_selected',
        (tester) async {
      final analytics = _SuperPropSpy();
      final trackedEvents = <(String, Map<String, Object?>)>[];
      SourceQuestionScreen.onAnalyticsEvent =
          (event, props) => trackedEvents.add((event, props));
      addTearDown(() => SourceQuestionScreen.onAnalyticsEvent = null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [analyticsProvider.overrideWithValue(analytics)],
          child: MaterialApp(
            home: SourceQuestionScreen(
              onNext: () {},
              commitBeat: Duration.zero,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('TikTok'));
      await tester.pump();

      expect(analytics.calls, isNotEmpty,
          reason: 'the tap never registered a super-property upgrade');
      final upgrade = analytics.calls.last;
      expect(upgrade[AnalyticsEvents.propReelHook], 'tiktok');
      expect(upgrade[AnalyticsEvents.propReelHookSource],
          AnalyticsEvents.reelHookSourceSelfReport,
          reason: 'reel_hook and reel_hook_source must upgrade together');

      // Same call site as the existing reel_source_selected emit — never one
      // without the other.
      expect(trackedEvents, hasLength(1));
      expect(trackedEvents.single.$1, AnalyticsEvents.reelSourceSelected);
      expect(trackedEvents.single.$2[AnalyticsEvents.propSource], 'tiktok');

      // Flushes the options' staggered fade-in timers before the test ends.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('"Rather not say" registers nothing — the decline behaviour '
        'is unchanged', (tester) async {
      final analytics = _SuperPropSpy();
      final trackedEvents = <String>[];
      SourceQuestionScreen.onAnalyticsEvent =
          (event, props) => trackedEvents.add(event);
      addTearDown(() => SourceQuestionScreen.onAnalyticsEvent = null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [analyticsProvider.overrideWithValue(analytics)],
          child: MaterialApp(
            home: SourceQuestionScreen(
              onNext: () {},
              commitBeat: Duration.zero,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(SourceQuestionScreen.skipLabel));
      await tester.pump();

      expect(analytics.calls, isEmpty);
      expect(trackedEvents, isEmpty);

      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('provenance never DOWNGRADES', () {
    // A deep link is CONFIRMED — the OS handed us the reel id on arrival. A
    // self-report is RECALLED — the user picked from a list at index 13, after
    // the payoff and every ask, from memory. They are not the same evidence,
    // and D2 exists precisely because "a super property that silently mixes a
    // confirmed deep link with a half-remembered tap looks authoritative and is
    // not."
    //
    // D2's wording is "upgrading `unknown` in place" — UNKNOWN, not deep_link.
    // Overwriting a confirmed arrival with a recollection throws away the
    // better datum AND relabels its provenance as the weaker one, which is the
    // exact failure the two-property design was built to prevent.
    //
    // MUTATION: make the source-screen write unconditional again → this fails.
    testWidgets('a confirmed deep_link survives a later self-report',
        (tester) async {
      final analytics = _SuperPropSpy();
      final container = ProviderContainer(
        overrides: [analyticsProvider.overrideWithValue(analytics)],
      );
      addTearDown(container.dispose);

      // The arrival already happened: the drain stamped the reel id on state.
      container
          .read(onboardingProvider.notifier)
          .setReelArrival(reelId: 'reel-42');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: SourceQuestionScreen(onNext: () {}, commitBeat: Duration.zero),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(SourceQuestionScreen.options.first.label));
      await tester.pump();

      expect(
        analytics.calls
            .any((c) => c.containsKey(AnalyticsEvents.propReelHookSource)),
        isFalse,
        reason: 'a confirmed deep_link must not be relabelled as a '
            'self-report. That is a provenance downgrade: every chart built on '
            'reel_hook_source would over-report self-report coverage while '
            'under-reporting the one signal we actually confirmed.',
      );

      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('with NO deep link, the self-report still upgrades unknown',
        (tester) async {
      // The guard must not become a blanket suppression — an organic arrival
      // has nothing better than the self-report, and that is the whole reason
      // the screen exists.
      final analytics = _SuperPropSpy();
      final container = ProviderContainer(
        overrides: [analyticsProvider.overrideWithValue(analytics)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: SourceQuestionScreen(onNext: () {}, commitBeat: Duration.zero),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(SourceQuestionScreen.options.first.label));
      await tester.pump();

      final wrote = analytics.calls.firstWhere(
        (c) => c.containsKey(AnalyticsEvents.propReelHookSource),
        orElse: () => <String, dynamic>{},
      );
      expect(wrote[AnalyticsEvents.propReelHookSource],
          AnalyticsEvents.reelHookSourceSelfReport);

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
