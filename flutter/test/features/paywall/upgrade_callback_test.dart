import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/upgrade_callback.dart';
import 'package:sakina/services/gating_service.dart';

void main() {
  group('buildPaywallUpgradeCallback', () {
    test('GateReason.premiumFairUse → no-op (does NOT push paywall)', () async {
      var pushed = 0;
      final cb = buildPaywallUpgradeCallback(
        reason: GateReason.premiumFairUse,
        pushPaywall: () => pushed++,
      );
      await cb();
      expect(pushed, 0,
          reason:
              'premium users at the fair-use ceiling are already paying — '
              'routing them to /paywall is wrong');
    });

    // Every other reason a DailyCapSheet can fire under should route to /paywall.
    final routingReasons = <GateReason>[
      GateReason.dailyCap,
      GateReason.hadTrialNoBudget,
      GateReason.warmupRemaining,
      GateReason.ok,
    ];

    for (final reason in routingReasons) {
      test('GateReason.${reason.name} → pushes paywall', () async {
        var pushed = 0;
        final cb = buildPaywallUpgradeCallback(
          reason: reason,
          pushPaywall: () => pushed++,
        );
        await cb();
        expect(pushed, 1);
      });
    }
  });
}
