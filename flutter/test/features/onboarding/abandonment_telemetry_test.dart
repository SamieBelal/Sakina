import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';

// T11/T12: abandonment telemetry threshold logic (Task A10, 2026-05-25).
// The `onboarding_abandoned_at_page` event must fire ONLY when the app
// was paused mid-onboarding for >24 hours. Tests target the extracted
// `shouldFireAbandonment` helper for deterministic coverage without
// having to drive AppLifecycleState through the framework.
void main() {
  group('shouldFireAbandonment threshold helper', () {
    test('T11: pause > 24h returns true', () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt = pausedAt.add(const Duration(hours: 25));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isTrue,
      );
    });

    test('T11: pause = 7 days returns true', () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt = pausedAt.add(const Duration(days: 7));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isTrue,
      );
    });

    test('T12: pause < 24h returns false (1h)', () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt = pausedAt.add(const Duration(hours: 1));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isFalse,
      );
    });

    test('T12: pause exactly 24h returns false (must be strictly greater)',
        () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt = pausedAt.add(const Duration(hours: 24));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isFalse,
      );
    });

    test('pause 24h + 1 minute returns true (just over threshold)', () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt =
          pausedAt.add(const Duration(hours: 24, minutes: 1));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isTrue,
      );
    });
  });
}
