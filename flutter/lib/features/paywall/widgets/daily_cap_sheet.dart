import 'package:flutter/material.dart';

import 'warmup_exhausted_sheet.dart' show GatedFeature, PaywallSheetScaffold;

/// Bottom sheet shown to a free user who has already used their 1/day Reflect
/// / Built Dua / Discover Name allotment, OR for narrative high-point
/// triggers (post-streak-milestone, post-card-collected) — in which case the
/// caller passes [headlineOverride] for context-specific copy.
///
/// Body copy stays the same regardless of headline override per spec.
class DailyCapSheet extends StatelessWidget {
  final GatedFeature feature;
  final String? headlineOverride;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  const DailyCapSheet({
    super.key,
    required this.feature,
    required this.onUpgrade,
    required this.onDismiss,
    this.headlineOverride,
  });

  static Future<void> show(
    BuildContext context, {
    required GatedFeature feature,
    required VoidCallback onUpgrade,
    String? headlineOverride,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return DailyCapSheet(
          feature: feature,
          headlineOverride: headlineOverride,
          onUpgrade: () {
            Navigator.of(sheetContext).pop();
            onUpgrade();
          },
          onDismiss: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  String get _defaultHeadline {
    switch (feature) {
      case GatedFeature.reflect:
        return "You've reflected today";
      case GatedFeature.builtDua:
        return "You've built today's dua";
      case GatedFeature.discoverName:
        return "You've discovered today's Name";
    }
  }

  String get _body {
    switch (feature) {
      case GatedFeature.reflect:
        return "Tomorrow's reflection is on us. Or unlock unlimited now.";
      case GatedFeature.builtDua:
        return "Tomorrow's dua is on us. Or unlock unlimited now.";
      case GatedFeature.discoverName:
        return "Tomorrow's discovery is on us. Or unlock unlimited now.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaywallSheetScaffold(
      icon: Icons.wb_sunny_outlined,
      headline: headlineOverride ?? _defaultHeadline,
      body: _body,
      primaryLabel: 'Unlock unlimited',
      secondaryLabel: 'Maybe later',
      onPrimary: onUpgrade,
      onSecondary: onDismiss,
    );
  }
}
