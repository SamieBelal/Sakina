import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/services/app_config_service.dart';

import 'screens/_test_utils.dart';

// T8/T9/T10 dual-flow tests for the trimmed onboarding refactor
// (2026-05-25, Option α). Verifies the `onboarding_trim_enabled`
// app_config flag picks between the 20-child trimmed PageView and the
// 27-child legacy PageView at runtime.
class _StubAppConfig extends AppConfigService {
  _StubAppConfig({required this.trimmed}) : super.forTest();
  final bool trimmed;
  @override
  Future<bool> getBool(String key, {required bool fallback}) async => trimmed;
  @override
  Future<void> primeCache(List<String> keys) async {}
}

void main() {
  testWidgets('T8: onboarding_trim_enabled=true renders 20 children',
      (tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider
              .overrideWithValue(_StubAppConfig(trimmed: true)),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(
      (pageView.childrenDelegate as SliverChildListDelegate).children.length,
      20,
    );
  });

  testWidgets('T9: onboarding_trim_enabled=false renders 27 children',
      (tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider
              .overrideWithValue(_StubAppConfig(trimmed: false)),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(
      (pageView.childrenDelegate as SliverChildListDelegate).children.length,
      27,
    );
  });

  testWidgets(
      'T10 REGRESSION: trimmed→legacy mid-flow clamps to valid legacy page',
      (tester) async {
    // User is on trimmed page 8 (AttributionScreen). Kill switch flips. App
    // restarts. With legacy flow active, the same `currentPage=8` lands on
    // CommonEmotionsScreen — different screen but still a valid index.
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider
              .overrideWithValue(_StubAppConfig(trimmed: false)),
          cachedOnboardingStateProvider.overrideWithValue(
            const OnboardingState(currentPage: 8),
          ),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
  });

  test(
      'T11 REGRESSION: persisted v7 state preserves pages beyond the trimmed '
      'max for legacy rollback', () {
    final restored = OnboardingState.fromJson({
      'version': 7,
      'currentPage': onboardingLegacyLastPageIndex,
    });

    expect(restored.currentPage, onboardingLegacyLastPageIndex);
    expect(restored.currentPage, greaterThan(onboardingLastPageIndex));
  });

  group('activeOnboardingLastPageIndex (H1/M2 dual-flow bound)', () {
    test('trimmed flow returns the trimmed last index', () {
      expect(
        activeOnboardingLastPageIndex(trimmed: true),
        onboardingLastPageIndex,
      );
      // Sanity: trimmed paywall is at index 19 (rating gate always on).
      expect(onboardingLastPageIndex, 19);
    });

    test('legacy flow returns the legacy last index (26 with rating gate)', () {
      expect(
        activeOnboardingLastPageIndex(trimmed: false),
        onboardingLegacyLastPageIndex,
      );
      expect(onboardingLegacyLastPageIndex, 26);
    });

    test(
        'H1: legacy bound is past the trimmed index so _next can reach the '
        'legacy paywall (regression — was capped at trimmed 19)', () {
      // The bug: _next used onboardingLastPageIndex (19) unconditionally,
      // stranding legacy users. The active bound must exceed 19 for legacy.
      expect(
        activeOnboardingLastPageIndex(trimmed: false),
        greaterThan(activeOnboardingLastPageIndex(trimmed: true)),
      );
      expect(activeOnboardingLastPageIndex(trimmed: false), 26);
    });
  });

  testWidgets(
      'H1: legacy PageView last child is the final gate at the legacy '
      'last index (reachable end of flow)', (tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider
              .overrideWithValue(_StubAppConfig(trimmed: false)),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final pageView = tester.widget<PageView>(find.byType(PageView));
    final children =
        (pageView.childrenDelegate as SliverChildListDelegate).children;
    // The legacy flow's terminal page (index 26 with rating gate) is the
    // OnboardingFinalGate wrapper — _next's bound must allow reaching it. The
    // wrapper renders the soft PaywallScreen when the hard-paywall-after-tour
    // flag is OFF (rollback) and skips it (completes onboarding) when ON. Either
    // way it is the reachable end of the flow at the legacy last index.
    expect(children.length - 1, onboardingLegacyLastPageIndex);
    expect(children.last, isA<OnboardingFinalGate>());
  });
}
