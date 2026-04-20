import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';

void main() {
  testWidgets('PageView has 27 children and lastIndex is 26', (tester) async {
    // Use a tall surface so FirstCheckinScreen's keyboard-aware layout fits
    // without overflow errors during the structural assertion.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: const OnboardingScreen()),
      ),
    );

    final pv = tester.widget<PageView>(find.byType(PageView));
    expect(
      (pv.childrenDelegate as SliverChildListDelegate).children.length,
      27,
    );
    expect(onboardingLastPageIndex, 26);

    // Drain pending animation timers from flutter_animate so the test can
    // tear down cleanly.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
