import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';
import 'screens/_test_utils.dart';

/// THREE flows now coexist (One Ship W2-E1, plan review 4):
///   * `reel_first_onboarding_enabled` ON  → the 19-page reel flow (default).
///   * OFF → the EXISTING decision, unchanged: `onboarding_trim_enabled`
///     picks trimmed (20) vs legacy (27).
///
/// The kill switch has to reproduce the CURRENT prod experience, which is the
/// TRIMMED flow — not the 27-page one. That is the load-bearing assertion
/// below; a fallback to legacy would be a silent 7-page regression for every
/// user the switch is thrown for.
///
/// Grew out of onboarding_dual_flow_test.dart (2026-05-25, Option α).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // A clamp test lands on the final gate, which renders the real
    // PaywallScreen; these are the same seams onboarding_no_double_paywall_test
    // uses to render it without StoreKit or a live Supabase.
    debugDisablePaywallAnimations = true;
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
  });

  tearDown(() {
    debugDisablePaywallAnimations = false;
    SupabaseSyncService.debugReset();
  });

  /// Pumps a fresh onboarding screen on [config]'s flow.
  ///
  /// The key is load-bearing: `_flowFuture` is `late final` per State, so a
  /// second `pumpWidget` of an UNKEYED `OnboardingScreen` in the same test
  /// reuses the first State and silently keeps the first flow. Keying on the
  /// flow forces a new Element, and therefore a real re-resolution.
  Future<List<Widget>> pumpFlow(
    WidgetTester tester,
    FlowStubAppConfig config, {
    OnboardingState? restored,
    bool wideViewport = false,
  }) async {
    if (wideViewport) {
      // The paywall's plan Row overflows a 390pt-wide test surface because
      // `flutter_test` renders every glyph as a full em square (same artifact
      // documented in hook_problem_screen_test). A test that lands ON the
      // paywall needs the room; it is not a device-side layout bug.
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    } else {
      useOnboardingViewport(tester);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider.overrideWithValue(config),
          appSessionProvider.overrideWithValue(buildTestAppSession()),
          if (restored != null)
            cachedOnboardingStateProvider.overrideWithValue(restored),
        ],
        child: MaterialApp(home: OnboardingScreen(key: ValueKey(config.flow))),
      ),
    );
    // Three pumps: the reel flag future, the trim flag future (non-reel flows
    // await both), then the `.then` → setState rebuild.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    // Drain flutter_animate + the paywall's close-button reveal timer so
    // nothing is pending at teardown. Every assertion below reads constructor
    // properties, so settling first cannot mask anything.
    await tester.pump(const Duration(seconds: 4));
    final pageView = tester.widget<PageView>(find.byType(PageView));
    return (pageView.childrenDelegate as SliverChildListDelegate).children;
  }

  group('flow selection', () {
    testWidgets('reel flag ON renders 19 children', (tester) async {
      final children = await pumpFlow(tester, FlowStubAppConfig.reel());
      expect(children.length, 19);
      expect(children.length - 1, onboardingReelLastPageIndex);
    });

    testWidgets(
        'reel flag OFF falls back to TRIMMED (20) — the current prod flow, '
        'not the 27-page legacy one', (tester) async {
      final children = await pumpFlow(tester, FlowStubAppConfig.trimmed());
      expect(children.length, 20);
      expect(children.length - 1, onboardingLastPageIndex);
    });

    testWidgets('reel OFF + trim OFF renders the 27-page legacy flow',
        (tester) async {
      final children = await pumpFlow(tester, FlowStubAppConfig.legacy());
      expect(children.length, 27);
      expect(children.length - 1, onboardingLegacyLastPageIndex);
    });

    testWidgets('every flow ends on the OnboardingFinalGate', (tester) async {
      for (final config in [
        FlowStubAppConfig.reel(),
        FlowStubAppConfig.trimmed(),
        FlowStubAppConfig.legacy(),
      ]) {
        final children = await pumpFlow(tester, config);
        expect(
          children.last,
          isA<OnboardingFinalGate>(),
          reason: '${config.flow} must have a reachable terminal page',
        );
      }
    });

    testWidgets(
        'the reel flow forces the soft onboarding paywall on its final page',
        (tester) async {
      // Plan §F1.2: a reel user never takes the tour, so the hard-flag branch
      // (complete-and-hand-off-to-the-router) would leave them with no paywall
      // surface anywhere. The other two flows keep the flag-driven behaviour.
      final reel = await pumpFlow(tester, FlowStubAppConfig.reel());
      expect((reel.last as OnboardingFinalGate).alwaysShowPaywall, isTrue);

      final trimmed = await pumpFlow(tester, FlowStubAppConfig.trimmed());
      expect((trimmed.last as OnboardingFinalGate).alwaysShowPaywall, isFalse);
    });

    testWidgets('entry latches the flow into OnboardingState', (tester) async {
      // It rides every `saveOnboardingData` persist (including the final one
      // the freeze trigger locks), and `completeOnboarding` branches on it to
      // pick the post-onboarding gate — so it has to be set at ENTRY, not at
      // completion.
      await pumpFlow(tester, FlowStubAppConfig.reel());
      var container = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingScreen)),
      );
      expect(container.read(onboardingProvider).onboardingFlow,
          onboardingFlowReel);

      await pumpFlow(tester, FlowStubAppConfig.trimmed());
      container = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingScreen)),
      );
      expect(container.read(onboardingProvider).onboardingFlow,
          onboardingFlowLegacy);
    });
  });

  group('activeOnboardingLastPageIndex (three-flow bound)', () {
    test('resolves each flow to its own terminal index', () {
      expect(activeOnboardingLastPageIndex(OnboardingFlowKind.reel), 18);
      expect(activeOnboardingLastPageIndex(OnboardingFlowKind.trimmed), 19);
      expect(activeOnboardingLastPageIndex(OnboardingFlowKind.legacy), 26);
    });

    test(
        'H1 REGRESSION: the bound tracks the flow, so `_next` can reach every '
        "flow's real paywall", () {
      // The original bug: `_next` used the trimmed index unconditionally,
      // stranding legacy users one page short of their paywall.
      expect(
        activeOnboardingLastPageIndex(OnboardingFlowKind.legacy),
        greaterThan(activeOnboardingLastPageIndex(OnboardingFlowKind.trimmed)),
      );
      expect(
        activeOnboardingLastPageIndex(OnboardingFlowKind.reel),
        lessThan(activeOnboardingLastPageIndex(OnboardingFlowKind.trimmed)),
      );
    });

    test('lastPageIndexForFlow is the same function', () {
      for (final kind in OnboardingFlowKind.values) {
        expect(activeOnboardingLastPageIndex(kind), lastPageIndexForFlow(kind));
      }
    });
  });

  group('canNavigateOnboarding (reel back-nav latch, W2-E1)', () {
    test('reel: nothing past the reveal may go back to the hook or reveal', () {
      for (var from = onboardingReelNoBackBeforeIndex;
          from <= onboardingReelLastPageIndex;
          from++) {
        for (final to in [
          onboardingReelHookPageIndex,
          onboardingReelRevealPageIndex,
        ]) {
          expect(
            canNavigateOnboarding(
              flow: OnboardingFlowKind.reel,
              from: from,
              to: to,
            ),
            isFalse,
            reason: 'page $from must not return to $to — the reveal already '
                'awarded its card and burnt its latch',
          );
        }
      }
    });

    test('reel: the reveal itself may still go back to the hook', () {
      expect(
        canNavigateOnboarding(
          flow: OnboardingFlowKind.reel,
          from: onboardingReelRevealPageIndex,
          to: onboardingReelHookPageIndex,
        ),
        isTrue,
      );
    });

    test('reel: ordinary back-nav between later pages is allowed', () {
      expect(
        canNavigateOnboarding(flow: OnboardingFlowKind.reel, from: 7, to: 6),
        isTrue,
      );
      expect(
        canNavigateOnboarding(flow: OnboardingFlowKind.reel, from: 3, to: 2),
        isTrue,
      );
    });

    test('reel: forward nav is never blocked', () {
      for (var i = 0; i < onboardingReelLastPageIndex; i++) {
        expect(
          canNavigateOnboarding(
            flow: OnboardingFlowKind.reel,
            from: i,
            to: i + 1,
          ),
          isTrue,
        );
      }
    });

    test('the kill-switch flows are unrestricted (their 0/1 are just pages)',
        () {
      for (final flow in [
        OnboardingFlowKind.trimmed,
        OnboardingFlowKind.legacy,
      ]) {
        expect(canNavigateOnboarding(flow: flow, from: 8, to: 0), isTrue);
        expect(canNavigateOnboarding(flow: flow, from: 2, to: 1), isTrue);
      }
    });
  });

  testWidgets(
      "REGRESSION: a restored page past the active flow's end is clamped, "
      'not rendered out of range', (tester) async {
    // Kill switch flips between launches: a user saved on trimmed page 19 comes
    // back into the reel flow, whose max is 12.
    await pumpFlow(
      tester,
      FlowStubAppConfig.reel(),
      restored: const OnboardingState(currentPage: 19),
      wideViewport: true,
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(OnboardingScreen)),
    );
    expect(
      container.read(onboardingProvider).currentPage,
      onboardingReelLastPageIndex,
    );
  });

  test(
      'persisted v8 state preserves pages beyond the reel max so a kill-switch '
      'rollback can still restore them', () {
    final restored = OnboardingState.fromJson({
      'version': 8,
      'currentPage': onboardingLegacyLastPageIndex,
    });

    expect(restored.currentPage, onboardingLegacyLastPageIndex);
    expect(restored.currentPage, greaterThan(onboardingReelLastPageIndex));
  });
}
