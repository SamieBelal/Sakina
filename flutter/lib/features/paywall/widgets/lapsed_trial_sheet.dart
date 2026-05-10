import 'package:flutter/material.dart';

import 'warmup_exhausted_sheet.dart' show PaywallSheetScaffold;

/// Bottom sheet shown on the first app open after a 3-day RevenueCat trial
/// has lapsed without conversion. References the user's actual trial-period
/// activity to make the upgrade prompt feel earned, not punitive.
///
/// Falls back to generic copy if [reflectsDuringTrial] is 0 (we couldn't
/// resolve trial activity) so the sheet always renders sensible copy.
class LapsedTrialSheet extends StatelessWidget {
  final int reflectsDuringTrial;
  final int daysActiveDuringTrial;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  const LapsedTrialSheet({
    super.key,
    required this.reflectsDuringTrial,
    required this.daysActiveDuringTrial,
    required this.onUpgrade,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required int reflectsDuringTrial,
    required int daysActiveDuringTrial,
    required VoidCallback onUpgrade,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return LapsedTrialSheet(
          reflectsDuringTrial: reflectsDuringTrial,
          daysActiveDuringTrial: daysActiveDuringTrial,
          onUpgrade: () {
            Navigator.of(sheetContext).pop();
            onUpgrade();
          },
          onDismiss: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  String get _body {
    // Fallback: zero reflects means we couldn't resolve trial activity (or
    // the user really did nothing during their trial — either way, generic
    // copy reads better than "you reflected 0 times across 0 days").
    if (reflectsDuringTrial <= 0) {
      return "You've explored what Premium feels like. One reflection a day "
          'is yours forever — or unlock unlimited again.';
    }
    final timesWord = reflectsDuringTrial == 1 ? 'time' : 'times';
    final daysWord = daysActiveDuringTrial == 1 ? 'day' : 'days';
    return 'In your 3-day trial, you reflected $reflectsDuringTrial $timesWord '
        'across $daysActiveDuringTrial $daysWord. Premium keeps that pace going.';
  }

  @override
  Widget build(BuildContext context) {
    return PaywallSheetScaffold(
      icon: Icons.local_fire_department_outlined,
      headline: 'Welcome back to one a day',
      body: _body,
      primaryLabel: 'Unlock unlimited',
      secondaryLabel: 'Maybe later',
      onPrimary: onUpgrade,
      onSecondary: onDismiss,
    );
  }
}
