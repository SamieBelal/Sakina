import 'package:flutter/material.dart';

import '../../../services/analytics_event_names.dart';
import 'warmup_exhausted_sheet.dart' show PaywallSheetScaffold;

/// Day-3 soft gate shown to the reverse-trial **treatment** arm once the 3-day
/// trial lapses. Reuses [LapsedTrialSheet]'s [PaywallSheetScaffold] copy/CTA
/// shape but is a distinct surface: it fires `trial_paywall_surfaced`
/// (placement `post_tour_soft`, `hard_gate:false`) on show and
/// `soft_gate_dismissed` on the secondary CTA, so the treatment funnel's Day-3
/// view is separable from the onboarding / in-app paywall placements.
///
/// Dismissible by design — the genuine gating is the limited free tier (1/day)
/// the user drops to, NOT a navigation block (no "pay-to-pray" hard wall on a
/// faith app, see the ADR). The `arm` segments via the `paywall_exp_arm`
/// Mixpanel super-property, so it isn't re-stamped on these events.
///
/// [onAnalyticsEvent] mirrors the service-layer static-hook pattern (no
/// Riverpod in the widget): the host wires it to `AnalyticsService.track`, and
/// tests inject a spy.
class ReverseTrialExpiredSheet extends StatefulWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;
  final void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  const ReverseTrialExpiredSheet({
    super.key,
    required this.onUpgrade,
    required this.onDismiss,
    this.onAnalyticsEvent,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUpgrade,
    void Function(String event, Map<String, dynamic> props)? onAnalyticsEvent,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      routeSettings: const RouteSettings(name: 'ReverseTrialExpiredSheet'),
      builder: (sheetContext) {
        return ReverseTrialExpiredSheet(
          onUpgrade: () {
            Navigator.of(sheetContext).pop();
            onUpgrade();
          },
          onDismiss: () => Navigator.of(sheetContext).pop(),
          onAnalyticsEvent: onAnalyticsEvent,
        );
      },
    );
  }

  @override
  State<ReverseTrialExpiredSheet> createState() =>
      _ReverseTrialExpiredSheetState();
}

class _ReverseTrialExpiredSheetState extends State<ReverseTrialExpiredSheet> {
  @override
  void initState() {
    super.initState();
    // Fire once on first build of the Day-3 gate view.
    widget.onAnalyticsEvent?.call(AnalyticsEvents.trialPaywallSurfaced, {
      AnalyticsEvents.propPlacement: AnalyticsEvents.placementPostTourSoft,
      AnalyticsEvents.propHardGate: false,
    });
  }

  void _handleDismiss() {
    widget.onAnalyticsEvent?.call(AnalyticsEvents.softGateDismissed, {
      AnalyticsEvents.propPlacement: AnalyticsEvents.placementPostTourSoft,
    });
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return PaywallSheetScaffold(
      icon: Icons.auto_awesome_outlined,
      headline: 'Your trial has ended',
      body: "You've felt what Sakina Premium offers. One reflection a day is "
          'yours forever — or keep unlimited access going.',
      primaryLabel: 'Unlock unlimited',
      secondaryLabel: 'Maybe later',
      onPrimary: widget.onUpgrade,
      onSecondary: _handleDismiss,
    );
  }
}
