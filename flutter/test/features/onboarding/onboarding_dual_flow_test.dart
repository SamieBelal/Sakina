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
}
