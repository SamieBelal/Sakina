import 'package:flutter/material.dart';

import 'warmup_exhausted_sheet.dart' show PaywallSheetScaffold;

/// Bottom sheet shown on the first app open after a 3-day RevenueCat trial
/// has lapsed without conversion. References the user's actual trial-period
/// activity to make the upgrade prompt feel earned, not punitive.
///
/// Falls back to generic copy if [momentsDuringTrial] is 0 (we couldn't
/// resolve trial activity) so the sheet always renders sensible copy.
///
/// **Invariant (plan 2026-05-23 line 307):** the lapsed-trialer Day-1 moment
/// is the strongest sub-upsell window in the entire app. It intentionally
/// does NOT offer the AI-bypass CTA — token spend would compete with the
/// subscription ask and dilute conversion. Days 2+ for lapsed trialers
/// fall through to DailyCapSheet (States A/B/C) where the bypass IS shown.
class LapsedTrialSheet extends StatelessWidget {
  /// Total spiritual actions the user took during their trial — reflects,
  /// built duas, and discovered names summed together. The rendered copy
  /// ("you showed up N times") is intentionally action-agnostic so the
  /// number stays honest regardless of which features the user used.
  final int momentsDuringTrial;
  final int daysActiveDuringTrial;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  const LapsedTrialSheet({
    super.key,
    required this.momentsDuringTrial,
    required this.daysActiveDuringTrial,
    required this.onUpgrade,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required int momentsDuringTrial,
    required int daysActiveDuringTrial,
    required VoidCallback onUpgrade,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      routeSettings: const RouteSettings(name: 'LapsedTrialSheet'),
      builder: (sheetContext) {
        return LapsedTrialSheet(
          momentsDuringTrial: momentsDuringTrial,
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
    // Fallback: zero moments means we couldn't resolve trial activity (or
    // the user really did nothing during their trial — either way, generic
    // copy reads better than "you showed up 0 times across 0 days").
    if (momentsDuringTrial <= 0) {
      return "You've explored what Premium feels like. One reflection a day "
          'is yours forever — or unlock unlimited again.';
    }
    final timesWord = momentsDuringTrial == 1 ? 'time' : 'times';
    final daysWord = daysActiveDuringTrial == 1 ? 'day' : 'days';
    return 'In your 3-day trial, you showed up $momentsDuringTrial $timesWord '
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
