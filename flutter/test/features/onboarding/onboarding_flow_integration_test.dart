import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';
import 'package:sakina/services/app_config_service.dart';

// Trimmed-flow refactor (2026-05-25, Option α): trimmed PageView has 20
// children. T8/T9 in onboarding_dual_flow_test verify both branches —
// this file only exercises the trimmed (default) path.
class _StubAppConfig extends AppConfigService {
  _StubAppConfig({this.trimmed = true}) : super.forTest();
  final bool trimmed;
  @override
  Future<bool> getBool(String key, {required bool fallback}) async => trimmed;
  @override
  Future<void> primeCache(List<String> keys) async {}
}

void main() {
  testWidgets('trimmed PageView has 20 children and lastIndex is 19',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider.overrideWithValue(_StubAppConfig()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final pv = tester.widget<PageView>(find.byType(PageView));
    expect(
      (pv.childrenDelegate as SliverChildListDelegate).children.length,
      20,
    );
    expect(onboardingLastPageIndex, 19);
    expect(onboardingPasswordPageIndex, 15);
    expect(onboardingPostSignupPageIndex, 16);

    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('first check-in Reflect button is not lifted by keyboard insets',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigServiceProvider.overrideWithValue(_StubAppConfig()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    final reflectButton = find.widgetWithText(ElevatedButton, 'Reflect');
    expect(reflectButton, findsOneWidget);
    final closedKeyboardPosition = tester.getTopLeft(reflectButton);

    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pump();

    expect(tester.getTopLeft(reflectButton), closedKeyboardPosition);

    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
