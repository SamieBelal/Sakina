import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

/// Sets a phone-sized test viewport so onboarding screens (which target real
/// device heights, ~800+ logical px) don't overflow the default 800x600
/// test surface. Call in `setUp` / at the top of a widget test. The reset
/// is registered via `addTearDown` on the tester.
void useOnboardingViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
